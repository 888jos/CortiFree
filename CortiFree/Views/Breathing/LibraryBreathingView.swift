//
//  LibraryBreathingView.swift
//  CortiFree
//
//  Created by Claude on 22/10/2025.
//  Breathing exercise with smooth sphere animation for Library section
//

import SwiftUI
import Combine

struct LibraryBreathingView: View {
    let pattern: BreathingPattern
    let totalDuration: TimeInterval // Total exercise duration in seconds
    let onComplete: () -> Void

    @Environment(\.dismiss) var dismiss
    @StateObject private var planetSettings = PlanetSettings.shared

    @State private var currentPhase: BreathingPhase = .inhale
    @State private var cyclesCompleted: Int = 0
    @State private var timeRemaining: TimeInterval
    @State private var showCompletion: Bool = false
    @State private var phaseOpacity: Double = 1.0

    // Animation de la planète
    @State private var ballYPosition: CGFloat = 80 // Petite (exhale) = 80, Grande (inhale) = -80
    @State private var haloOpacity: Double = 0.3

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    init(pattern: BreathingPattern, totalDuration: TimeInterval = 180, onComplete: @escaping () -> Void = {}) {
        self.pattern = pattern
        self.totalDuration = totalDuration
        self.onComplete = onComplete
        _timeRemaining = State(initialValue: totalDuration)
    }

    var body: some View {
        ZStack {
            // Galaxy background
            GalaxyBackgroundView(intensity: 0.8)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Close button
                HStack {
                    Button(action: {
                        HapticManager.light()
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)

                Spacer()

                // Exercise title
                VStack(spacing: 8) {
                    Text(pattern.displayName)
                        .font(.custom("Poppins-SemiBold", size: 24))
                        .foregroundColor(.white)

                    Text(pattern.description)
                        .font(.custom("Poppins-Regular", size: 16))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.bottom, 40)

                // Orb respiratoire avec cercle animé
                BreathingCircle(
                    planet: planetSettings.selectedPlanet,
                    size: ballYPosition == 80 ? 160 : 260,
                    haloOpacity: haloOpacity
                )
                .frame(maxWidth: .infinity)
                .frame(height: 450)

                // Phase label
                Text(currentPhase.displayText)
                    .font(.custom("Poppins-Bold", size: 32))
                    .foregroundColor(.white)
                    .opacity(phaseOpacity)
                    .padding(.top, 40)

                Spacer()

                // Timer and cycle count
                VStack(spacing: 12) {
                    Text(formatTime(timeRemaining))
                        .font(.custom("Poppins-Medium", size: 48))
                        .foregroundColor(.white)
                        .monospacedDigit()

                    Text("Cycle \(cyclesCompleted + 1)")
                        .font(.custom("Poppins-Regular", size: 16))
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.bottom, 60)
            }

            // Completion overlay
            if showCompletion {
                CompletionCelebration(
                    cyclesCompleted: cyclesCompleted,
                    onDismiss: {
                        dismiss()
                        onComplete()
                    }
                )
                .transition(.opacity)
            }
        }
        .onAppear {
            startBreathingCycle()
            // Animation du halo avec opacité
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                haloOpacity = 0.5
            }
        }
        .onReceive(timer) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                completeExercise()
            }
        }
    }

    // MARK: - Breathing Cycle

    private func startBreathingCycle() {
        animateInhale()
    }

    private func animateInhale() {
        currentPhase = .inhale

        // Haptic feedback
        HapticManager.light()

        // Fade in phase label
        withAnimation(.easeInOut(duration: 0.3)) {
            phaseOpacity = 1.0
        }

        // La bille monte - ballYPosition diminue
        withAnimation(.easeInOut(duration: pattern.inhaleDuration)) {
            ballYPosition = -80
        }

        // Schedule next phase
        DispatchQueue.main.asyncAfter(deadline: .now() + pattern.inhaleDuration) {
            if pattern.holdDuration > 0 {
                animateHold()
            } else {
                animateExhale()
            }
        }
    }

    private func animateHold() {
        currentPhase = .hold

        // Haptic feedback
        HapticManager.light()

        // Fade transition
        withAnimation(.easeInOut(duration: 0.3)) {
            phaseOpacity = 0.0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeInOut(duration: 0.3)) {
                phaseOpacity = 1.0
            }
        }

        // Sphere stays at top (yOffset = -200)

        // Schedule exhale
        DispatchQueue.main.asyncAfter(deadline: .now() + pattern.holdDuration) {
            animateExhale()
        }
    }

    private func animateExhale() {
        currentPhase = .exhale

        // Haptic feedback
        HapticManager.light()

        // Fade transition
        withAnimation(.easeInOut(duration: 0.3)) {
            phaseOpacity = 0.0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeInOut(duration: 0.3)) {
                phaseOpacity = 1.0
            }
        }

        // La bille descend - ballYPosition augmente
        withAnimation(.easeInOut(duration: pattern.exhaleDuration)) {
            ballYPosition = 80
        }

        // Schedule next cycle
        DispatchQueue.main.asyncAfter(deadline: .now() + pattern.exhaleDuration) {
            if timeRemaining > 0 {
                cyclesCompleted += 1
                startBreathingCycle()
            } else {
                completeExercise()
            }
        }
    }

    // MARK: - Completion

    private func completeExercise() {
        HapticManager.success()

        // Award XP for completing breathing exercise
        if totalDuration >= 60 { // At least 1 minute
            ProgressionManager.shared.addXP(.breathingComplete)
        }

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

// MARK: - Completion Celebration

struct CompletionCelebration: View {
    let cyclesCompleted: Int
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
                Text("Bravo, tu as retrouvé ton calme")
                    .font(.custom("Poppins-SemiBold", size: 28))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text("✨")
                    .font(.system(size: 60))

                // Cycles info
                VStack(spacing: 8) {
                    Text("\(cyclesCompleted) cycles")
                        .font(.custom("Poppins-Medium", size: 20))
                        .foregroundColor(.white.opacity(0.8))

                    Text("Tu mérites une pause bien méritée")
                        .font(.custom("Poppins-Regular", size: 16))
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 8)

                // Continue button
                Button(action: {
                    HapticManager.light()
                    onDismiss()
                }) {
                    Text("Continuer")
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
                .padding(.top, 16)
            }
            .padding(40)
        }
    }
}

// MARK: - Preview

#Preview {
    LibraryBreathingView(
        pattern: .fourSevenEight,
        totalDuration: 60
    ) {
        print("Exercise completed!")
    }
}
