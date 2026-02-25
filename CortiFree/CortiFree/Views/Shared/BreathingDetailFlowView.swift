//
//  BreathingDetailFlowView.swift
//  CortiFree
//
//  Created by Claude on 30/11/2025.
//  Vue unifiée pour tous les exercices de respiration
//

import SwiftUI

struct BreathingDetailFlowView: View {
    let pattern: BreathingPattern
    let duration: TimeInterval
    let onComplete: () -> Void

    @Environment(\.dismiss) var dismiss
    @ObservedObject private var planetSettings = PlanetSettings.shared
    @ObservedObject private var voiceOverManager = VoiceOverManager.shared

    // Timer
    @State private var timeRemaining: TimeInterval
    @State private var isExerciseActive = true

    // Animation du cercle (seul élément qui bouge)
    @State private var circleSize: CGFloat = 160  // 160 (petit/exhale) ↔ 260 (grand/inhale)
    @State private var haloOpacity: Double = 0.3

    // Phases
    @State private var currentPhase: BreathingPhase = .inhale
    @State private var cycleCount = 0

    // Completion
    @State private var showCompletion = false

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    init(pattern: BreathingPattern, duration: TimeInterval = 180, onComplete: @escaping () -> Void = {}) {
        self.pattern = pattern
        self.duration = duration
        self.onComplete = onComplete
        _timeRemaining = State(initialValue: duration)
    }

    var body: some View {
        ZStack {
            // Galaxy background - FIXE
            GalaxyBackgroundView(intensity: 0.8)
                .ignoresSafeArea()

            // Contenu principal - Layout fixe
            VStack(spacing: 0) {
                // Header avec bouton retour, titre centré et VoiceOver - FIXE
                headerSection

                Spacer()
                    .frame(height: 12)

                // Sous-titre/description - FIXE
                subtitleSection

                Spacer()

                // Cercle animé - SEUL ÉLÉMENT QUI BOUGE (taille)
                circleSection

                Spacer()

                // Phase text - FIXE (seul le texte change, pas la position)
                phaseTextSection

                Spacer()
                    .frame(height: 16) // Réduit pour rapprocher du timer

                // Timer et Cycle - FIXE
                timerSection

                Spacer()
                    .frame(height: 60)
            }

            // Completion overlay
            if showCompletion {
                BreathingCompletionOverlay(
                    onDismiss: {
                        dismiss()
                        onComplete()
                    }
                )
                .transition(.opacity)
            }
        }
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
            startBreathingAnimation()
            // Animation du halo
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                haloOpacity = 0.5
            }
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
        }
        .onReceive(timer) { _ in
            if isExerciseActive && timeRemaining > 0 {
                timeRemaining -= 1
            } else if isExerciseActive && timeRemaining == 0 {
                completeExercise()
            }
        }
    }

    // MARK: - Header Section (FIXE) - Titre centré entre flèche et VoiceOver

    private var headerSection: some View {
        HStack {
            // Bouton retour - juste une flèche
            Button(action: {
                HapticManager.light()
                isExerciseActive = false
                voiceOverManager.stop()
                dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color.white.opacity(0.1)))
            }

            Spacer()

            // Titre centré entre les deux boutons
            Text(pattern.displayName)
                .font(.custom("Poppins-SemiBold", size: 20))
                .foregroundColor(.white)

            Spacer()

            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, 24)
        .padding(.top, 60)
    }

    // MARK: - Subtitle Section (FIXE) - Description courte

    private var subtitleSection: some View {
        Text(pattern.shortDescription)
            .font(.custom("Poppins-Regular", size: 16))
            .foregroundColor(.white.opacity(0.7))
            .multilineTextAlignment(.center)
            .padding(.horizontal, 40)
    }

    // MARK: - Circle Section (ANIMÉ - taille uniquement)

    private var circleSection: some View {
        BreathingCircle(
            planet: planetSettings.selectedPlanet,
            size: circleSize,
            haloOpacity: haloOpacity
        )
        .frame(width: 280, height: 280)
        .animation(.easeInOut(duration: getCurrentPhaseDuration()), value: circleSize)
    }

    // MARK: - Phase Text Section (FIXE - seul le texte change)

    private var phaseTextSection: some View {
        Text(currentPhase.displayText)
            .font(.faroBold(28))
            .foregroundColor(.white)
            .frame(height: 40) // Hauteur fixe pour éviter les sauts
    }

    // MARK: - Timer Section (FIXE, monté plus haut)

    private var timerSection: some View {
        VStack(spacing: 12) {
            Text(formatTime(timeRemaining))
                .font(.faroBold(48))
                .foregroundColor(.white)
                .monospacedDigit()

            Text("Cycle \(cycleCount + 1)")
                .font(.custom("Poppins-Regular", size: 16))
                .foregroundColor(.white.opacity(0.6))
        }
    }

    // MARK: - Breathing Animation

    private func startBreathingAnimation() {
        animateBreathingCycle()
    }

    private func animateBreathingCycle() {
        guard isExerciseActive else { return }

        // Phase 1: Inhale - le cercle grandit
        currentPhase = .inhale
        voiceOverManager.announceBreathingPhase(currentPhase.displayText)
        withAnimation(.easeInOut(duration: pattern.inhaleDuration)) {
            circleSize = 260
        }

        // Phase 2: Hold (si applicable)
        if pattern.holdDuration > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + pattern.inhaleDuration) {
                guard self.isExerciseActive else { return }
                currentPhase = .hold
                self.voiceOverManager.announceBreathingPhase(self.currentPhase.displayText)
            }
        }

        // Phase 3: Exhale - le cercle rétrécit
        DispatchQueue.main.asyncAfter(deadline: .now() + pattern.inhaleDuration + pattern.holdDuration) {
            guard self.isExerciseActive else { return }
            currentPhase = .exhale
            self.voiceOverManager.announceBreathingPhase(self.currentPhase.displayText)
            withAnimation(.easeInOut(duration: pattern.exhaleDuration)) {
                circleSize = 160
            }
        }

        // Phase 4: Hold Out (si applicable - pour box breathing)
        let holdOutDuration = pattern.holdOutDuration
        if holdOutDuration > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + pattern.inhaleDuration + pattern.holdDuration + pattern.exhaleDuration) {
                guard self.isExerciseActive else { return }
                currentPhase = .hold
                self.voiceOverManager.announceBreathingPhase(self.currentPhase.displayText)
            }
        }

        // Prochain cycle
        let totalCycleDuration = pattern.inhaleDuration + pattern.holdDuration + pattern.exhaleDuration + holdOutDuration
        DispatchQueue.main.asyncAfter(deadline: .now() + totalCycleDuration) {
            guard self.isExerciseActive && self.timeRemaining > 0 else { return }
            cycleCount += 1
            animateBreathingCycle()
        }
    }

    private func getCurrentPhaseDuration() -> Double {
        switch currentPhase {
        case .inhale:
            return pattern.inhaleDuration
        case .hold:
            return pattern.holdDuration > 0 ? pattern.holdDuration : pattern.holdOutDuration
        case .exhale:
            return pattern.exhaleDuration
        }
    }

    // MARK: - Completion

    private func completeExercise() {
        isExerciseActive = false
        voiceOverManager.stop()
        HapticManager.success()

        withAnimation(.easeInOut(duration: 0.5)) {
            showCompletion = true
        }
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let remainingSeconds = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
}

// MARK: - Completion Overlay

struct BreathingCompletionOverlay: View {
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // Success icon
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(Color.appTheme)

                // Message
                Text(NSLocalizedString("breathing.completion.title", comment: "Tu as repris le contrôle"))
                    .font(.faroSemiBold(28))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Image(systemName: "figure.mind.and.body")
                    .font(.system(size: 60))
                    .foregroundColor(Color.appTheme)

                // Continue button
                Button(action: {
                    HapticManager.light()
                    onDismiss()
                }) {
                    Text(NSLocalizedString("common.continue", comment: "Continuer"))
                        .font(.custom("Poppins-SemiBold", size: 18))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color.appTheme,
                                    Color.appThemeSecondary
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 40)
                .padding(.top, 8)
            }
            .padding(40)
        }
    }
}

#Preview {
    BreathingDetailFlowView(
        pattern: .fourSevenEight,
        duration: 60
    ) {
        print("Exercise completed!")
    }
}
