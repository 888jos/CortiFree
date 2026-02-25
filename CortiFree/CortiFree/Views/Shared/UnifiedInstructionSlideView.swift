//
//  UnifiedInstructionSlideView.swift
//  CortiFree
//
//  Created by Claude on 23/11/2025.
//  Vue unifiée pour toutes les instructions (anti-stress + méditation)
//

import SwiftUI
import Lottie

// MARK: - Unified Instruction Step Model

struct UnifiedInstructionStep {
    let title: String
    let subtitle: String?
    let icon: String
    let color: String
    let estimatedDuration: String?

    init(title: String, subtitle: String? = nil, icon: String, color: String, estimatedDuration: String? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.color = color
        self.estimatedDuration = estimatedDuration
    }
}

// MARK: - Unified Instruction Slide View

struct UnifiedInstructionSlideView: View {
    let steps: [UnifiedInstructionStep]
    let exerciseTitle: String
    let onComplete: () -> Void

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var voiceOverManager = VoiceOverManager.shared
    @State private var currentSlide = 0
    @State private var pulseAnimation = false
    @State private var showConfetti = false
    @State private var showCompletion = false
    @State private var dragOffset: CGFloat = 0
    @State private var remainingSeconds: Int = 0
    @State private var timer: Timer?

    private var totalSlides: Int {
        return steps.count
    }

    private func parseDuration(_ duration: String?) -> Int {
        guard let duration = duration else { return 0 }

        // Parse "30 sec", "1 min", "2 min 30 sec", etc.
        let components = duration.lowercased().components(separatedBy: " ")
        var totalSeconds = 0

        var i = 0
        while i < components.count {
            if let value = Int(components[i]) {
                if i + 1 < components.count {
                    let unit = components[i + 1]
                    if unit.hasPrefix("min") {
                        totalSeconds += value * 60
                    } else if unit.hasPrefix("sec") {
                        totalSeconds += value
                    }
                }
            }
            i += 1
        }

        return totalSeconds
    }

    private func startTimer(for step: UnifiedInstructionStep) {
        timer?.invalidate()
        remainingSeconds = parseDuration(step.estimatedDuration)

        if remainingSeconds > 0 {
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                if remainingSeconds > 0 {
                    remainingSeconds -= 1
                }
            }
        }
    }

    private func formatTime(_ seconds: Int) -> String {
        if seconds >= 60 {
            let mins = seconds / 60
            let secs = seconds % 60
            if secs == 0 {
                return "\(mins)'"
            } else {
                return "\(mins)'\(String(format: "%02d", secs))''"
            }
        } else {
            return "\(seconds)''"
        }
    }

    private func speakCurrentStep() {
        guard voiceOverManager.isEnabled else { return }

        // Announce step progression
        voiceOverManager.announceStep(current: currentSlide + 1, total: totalSlides)

        // Small delay then speak the instruction
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let step = steps[currentSlide]
            var text = step.title

            // Add subtitle if present
            if let subtitle = step.subtitle {
                text += ". \(subtitle)"
            }

            voiceOverManager.speak(text)
        }
    }

    var body: some View {
        ZStack {
            // Galaxy background
            GalaxyBackgroundView(intensity: 1.0)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header avec progress
                header

                Spacer()

                // Slide content
                slideContent

                Spacer()

                // Navigation controls
                navigationControls
            }

            // Confetti
            if showConfetti {
                LottieView(
                    filename: "confetti",
                    loopMode: .playOnce
                )
                .ignoresSafeArea()
                .allowsHitTesting(false)
            }

            // Completion overlay
            if showCompletion {
                CompletionOverlay(
                    onDismiss: {
                        onComplete()
                        dismiss()
                    }
                )
                .transition(.opacity)
            }
        }
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                pulseAnimation = true
            }
            startTimer(for: steps[currentSlide])
            speakCurrentStep()
        }
        .onChange(of: currentSlide) { _ in
            startTimer(for: steps[currentSlide])
            speakCurrentStep()
        }
        .onDisappear {
            timer?.invalidate()
            voiceOverManager.stop()
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 20) {
            HStack {
                Button(action: {
                    HapticManager.light()
                    dismiss()
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 44, height: 44)
                            .blur(radius: 8)

                        Circle()
                            .fill(Color(hex: "1A1B3A").opacity(0.9))
                            .frame(width: 44, height: 44)

                        Image(systemName: "xmark")
                            .font(.custom("Poppins-SemiBold", size: 16))
                            .foregroundColor(.white)
                    }
                }

                Spacer()

                // Badge exercice
                HStack(spacing: 6) {
                    Image(systemName: "brain.head.profile")
                        .font(.custom("Poppins-SemiBold", size: 12))
                    Text(exerciseTitle)
                        .font(.custom("Poppins-Bold", size: 11))
                        .lineLimit(1)
                }
                .foregroundColor(Color(hex: "B388FF"))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color(hex: "B388FF").opacity(0.15))
                        .overlay(
                            Capsule()
                                .stroke(Color(hex: "B388FF").opacity(0.4), lineWidth: 1)
                        )
                )

                Spacer()

                Color.clear.frame(width: 44, height: 44)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)

            // Progress bar
            progressBar
        }
    }

    private var progressBar: some View {
        VStack(spacing: 12) {
            // Slide counter
            Text("\(currentSlide + 1) / \(totalSlides)")
                .font(.custom("Poppins-Medium", size: 13))
                .foregroundColor(.white.opacity(0.7))

            // Progress steps avec cercles reliés
            HStack(spacing: 0) {
                ForEach(0..<totalSlides, id: \.self) { index in
                    HStack(spacing: 0) {
                        // Circle
                        ZStack {
                            Circle()
                                .fill(index <= currentSlide ? Color(hex: "B388FF") : Color.white.opacity(0.15))
                                .frame(width: 12, height: 12)

                            if index < currentSlide {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 6, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }

                        // Line connecting to next circle
                        if index < totalSlides - 1 {
                            Rectangle()
                                .fill(index < currentSlide ? Color(hex: "B388FF") : Color.white.opacity(0.15))
                                .frame(height: 2)
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: currentSlide)
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Slide Content

    private var slideContent: some View {
        VStack(spacing: 40) {
            // Animated icon
            ZStack {
                // Pulse circles
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: steps[currentSlide].color).opacity(0.2),
                                Color(hex: steps[currentSlide].color).opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 180, height: 180)
                    .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                    .opacity(pulseAnimation ? 0.3 : 0.6)

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: steps[currentSlide].color).opacity(0.3),
                                Color(hex: steps[currentSlide].color).opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 140, height: 140)
                    .scaleEffect(pulseAnimation ? 1.1 : 1.0)

                // Icon
                Image(systemName: steps[currentSlide].icon)
                    .font(.system(size: 50, weight: .regular))
                    .foregroundColor(.white)
                    .shadow(color: Color(hex: steps[currentSlide].color).opacity(0.5), radius: 20)
            }

            // Slide text avec style
            VStack(spacing: 20) {
                // Header avec numéro + durée
                HStack(spacing: 12) {
                    // Numéro du slide
                    Text("\(NSLocalizedString("exercise.slide.step_label", comment: "Step label")) \(currentSlide + 1)")
                        .font(.custom("Poppins-Bold", size: 14))
                        .tracking(2)
                        .foregroundColor(Color(hex: steps[currentSlide].color))
                        .textCase(.uppercase)

                    // Duration badge si disponible - affiche le timer décompte
                    if steps[currentSlide].estimatedDuration != nil && remainingSeconds > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .font(.custom("Poppins-SemiBold", size: 10))
                            Text(formatTime(remainingSeconds))
                                .font(.custom("Poppins-Bold", size: 11))
                        }
                        .foregroundColor(.white.opacity(0.9))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(Color(hex: steps[currentSlide].color).opacity(0.25))
                                .overlay(
                                    Capsule()
                                        .stroke(Color(hex: steps[currentSlide].color).opacity(0.5), lineWidth: 1)
                                )
                        )
                    }
                }

                // Instruction principale
                Text(steps[currentSlide].title)
                    .font(.custom("Poppins-SemiBold", size: 24))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(8)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 32)

                // Subtitle si disponible
                if let subtitle = steps[currentSlide].subtitle {
                    Text(subtitle)
                        .font(.custom("Poppins-Regular", size: 16))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 40)
                }
            }
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))
            .id(currentSlide) // Force re-render on slide change
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    dragOffset = value.translation.width
                }
                .onEnded { value in
                    let threshold: CGFloat = 50
                    if value.translation.width < -threshold && currentSlide < totalSlides - 1 {
                        // Swipe left - next slide
                        HapticManager.light()
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            currentSlide += 1
                        }
                    } else if value.translation.width > threshold && currentSlide > 0 {
                        // Swipe right - previous slide
                        HapticManager.light()
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            currentSlide -= 1
                        }
                    }
                    dragOffset = 0
                }
        )
    }

    // MARK: - Navigation Controls

    private var navigationControls: some View {
        HStack(spacing: 16) {
            // Bouton Précédent - Circle only
            if currentSlide > 0 {
                Button(action: {
                    HapticManager.light()
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        currentSlide -= 1
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .font(.custom("Poppins-SemiBold", size: 18))
                        .foregroundColor(.white.opacity(0.8))
                        .frame(width: 56, height: 56)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.1))
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                        )
                }
                .buttonStyle(ScaleButtonStyle())
            }

            // Bouton Suivant / Terminer
            Button(action: {
                HapticManager.medium()
                if currentSlide < totalSlides - 1 {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        currentSlide += 1
                    }
                } else {
                    // Dernière slide - terminer avec succès et confettis
                    HapticManager.success()
                    voiceOverManager.announceCompletion()
                    withAnimation {
                        showConfetti = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation {
                            showCompletion = true
                        }
                    }
                }
            }) {
                HStack(spacing: 12) {
                    Text(currentSlide < totalSlides - 1 ? NSLocalizedString("exercise.slide.next", comment: "Next button") : NSLocalizedString("exercise.slide.finish", comment: "Finish button"))
                        .font(.custom("Poppins-Bold", size: 18))
                    Image(systemName: currentSlide < totalSlides - 1 ? "chevron.right" : "checkmark.circle.fill")
                        .font(.custom("Poppins-SemiBold", size: 18))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 64)
                .background(
                    ZStack {
                        // Shadow layer
                        RoundedRectangle(cornerRadius: 32)
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "B388FF"), Color(hex: "8C9EFF")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .blur(radius: 10)
                            .offset(y: 8)

                        // Main button
                        RoundedRectangle(cornerRadius: 32)
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "B388FF"), Color(hex: "8C9EFF")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
                )
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 32)
    }
}

// MARK: - Completion Overlay

struct CompletionOverlay: View {
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // Success icon
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(Color(hex: "B794F6"))

                // Message
                Text(NSLocalizedString("exercise.completion.title", comment: "Exercise completed title"))
                    .font(.custom("Poppins-SemiBold", size: 28))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Image(systemName: "figure.mind.and.body")
                    .font(.system(size: 60))
                    .foregroundColor(Color(hex: "B794F6"))

                // Continue button
                Button(action: {
                    HapticManager.light()
                    onDismiss()
                }) {
                    Text(NSLocalizedString("exercise.completion.continue", comment: "Continue button"))
                        .font(.custom("Poppins-SemiBold", size: 18))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color(hex: "B794F6"),
                                    Color(hex: "D4B4FF")
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
    UnifiedInstructionSlideView(
        steps: [
            UnifiedInstructionStep(
                title: "Installe-toi comme un chat",
                subtitle: "Trouve LA position parfaite (oui, bouge encore un peu)",
                icon: "figure.stand",
                color: "B388FF",
                estimatedDuration: "30 sec"
            ),
            UnifiedInstructionStep(
                title: "Ferme les yeux doucement",
                subtitle: "Pas besoin de forcer, laisse-les juste se reposer",
                icon: "eye.slash.fill",
                color: "8C9EFF",
                estimatedDuration: "10 sec"
            )
        ],
        exerciseTitle: "Test Exercice",
        onComplete: {}
    )
}
