//
//  RoutinePlayerView.swift
//  CortiFree
//
//  Created on 19/01/2026.
//

import SwiftUI

struct RoutinePlayerView: View {
    let routine: Routine
    @Environment(\.dismiss) var dismiss

    @State private var currentStepIndex = 0
    @State private var showCompletion = false
    @State private var pulseAnimation = false

    // Exercise presentation states
    @State private var showBreathingExercise = false
    @State private var showMeditationExercise = false
    @State private var showJournalView = false
    @State private var currentBreathingPattern: BreathingPattern?
    @State private var currentMeditationSupport: MeditationSupport?
    @State private var currentStepDuration: TimeInterval = 180

    // Sound playback for ambient sounds
    @ObservedObject private var soundPlayer = SoundPlayer.shared

    private var currentStep: RoutineStep {
        routine.steps[currentStepIndex]
    }

    private var progress: Double {
        Double(currentStepIndex) / Double(routine.steps.count)
    }

    var body: some View {
        ZStack {
            GalaxyBackgroundView(intensity: 1.0)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header with progress
                playerHeader

                Spacer()

                // Current step display
                stepContent

                Spacer()

                // Controls
                playerControls
            }

            // Completion overlay
            if showCompletion {
                RoutineCompletionOverlay(routine: routine) {
                    dismiss()
                }
                .transition(.opacity)
            }
        }
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
            withAnimation(Animation.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                pulseAnimation = true
            }
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
            // Stop any playing sound when leaving
            if soundPlayer.isPlaying {
                soundPlayer.stop()
            }
        }
        .onChange(of: currentBreathingPattern) { _, newValue in
            if newValue != nil {
                showBreathingExercise = true
            }
        }
        .onChange(of: currentMeditationSupport) { _, newValue in
            if newValue != nil {
                showMeditationExercise = true
            }
        }
        .fullScreenCover(isPresented: $showBreathingExercise) {
            if let pattern = currentBreathingPattern {
                BreathingDetailFlowView(
                    pattern: pattern,
                    duration: currentStepDuration,
                    onComplete: {
                        // Exercise completed - auto advance
                        advanceToNextStep()
                    }
                )
            }
        }
        .fullScreenCover(isPresented: $showMeditationExercise) {
            if let support = currentMeditationSupport {
                MeditationSessionSlideView(support: support)
            }
        }
        .fullScreenCover(isPresented: $showJournalView) {
            JournalHomeView()
        }
    }

    // MARK: - Player Header
    private var playerHeader: some View {
        VStack(spacing: 20) {
            HStack {
                Button(action: {
                    HapticManager.light()
                    if soundPlayer.isPlaying {
                        soundPlayer.stop()
                    }
                    dismiss()
                }) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: "1A1B3A").opacity(0.9))
                            .frame(width: 44, height: 44)

                        Image(systemName: "xmark")
                            .font(.custom("Poppins-SemiBold", size: 16))
                            .foregroundColor(.white)
                    }
                }

                Spacer()

                // Routine name badge
                HStack(spacing: 6) {
                    Image(systemName: routine.icon)
                        .font(.system(size: 12))
                    Text(routine.localizedName)
                        .font(.custom("Poppins-Bold", size: 11))
                        .lineLimit(1)
                }
                .foregroundColor(Color(hex: routine.color))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color(hex: routine.color).opacity(0.15))
                )

                Spacer()

                // Placeholder
                Color.clear.frame(width: 44, height: 44)
            }
            .padding(.horizontal, 24)
            .padding(.top, 60)

            // Progress indicator
            progressBar
        }
    }

    private var progressBar: some View {
        VStack(spacing: 12) {
            Text("\(currentStepIndex + 1) / \(routine.steps.count)")
                .font(.custom("Poppins-Medium", size: 13))
                .foregroundColor(.white.opacity(0.7))

            HStack(spacing: 0) {
                ForEach(0..<routine.steps.count, id: \.self) { index in
                    HStack(spacing: 0) {
                        ZStack {
                            Circle()
                                .fill(index <= currentStepIndex ? Color(hex: routine.color) : Color.white.opacity(0.15))
                                .frame(width: 12, height: 12)

                            if index < currentStepIndex {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 6, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }

                        if index < routine.steps.count - 1 {
                            Rectangle()
                                .fill(index < currentStepIndex ? Color(hex: routine.color) : Color.white.opacity(0.15))
                                .frame(height: 2)
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: currentStepIndex)
        }
    }

    // MARK: - Step Content
    private var stepContent: some View {
        VStack(spacing: 40) {
            // Animated icon
            ZStack {
                Circle()
                    .fill(Color(hex: routine.color).opacity(0.2))
                    .frame(width: 180, height: 180)
                    .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                    .opacity(pulseAnimation ? 0.3 : 0.6)

                Circle()
                    .fill(Color(hex: routine.color).opacity(0.3))
                    .frame(width: 140, height: 140)
                    .scaleEffect(pulseAnimation ? 1.1 : 1.0)

                Image(systemName: currentStep.icon)
                    .font(.system(size: 50, weight: .regular))
                    .foregroundColor(.white)
                    .shadow(color: Color(hex: routine.color).opacity(0.5), radius: 20)
            }

            VStack(spacing: 16) {
                // Step label
                HStack(spacing: 12) {
                    Text("\(NSLocalizedString("routines.step", comment: "")) \(currentStepIndex + 1)")
                        .font(.custom("Poppins-Bold", size: 14))
                        .tracking(2)
                        .foregroundColor(Color(hex: routine.color))
                        .textCase(.uppercase)

                    // Step type badge
                    stepTypeBadge
                }

                // Instruction
                Text(currentStep.localizedInstruction)
                    .font(.faroSemiBold(24))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(8)
                    .padding(.horizontal, 32)

                // Duration info
                if currentStep.duration > 0 {
                    HStack(spacing: 6) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 14))
                        Text(formatDuration(currentStep.duration))
                            .font(.custom("Poppins-Medium", size: 14))
                    }
                    .foregroundColor(.white.opacity(0.7))
                }
            }
            .id(currentStepIndex)
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))
        }
    }

    private var stepTypeBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: stepTypeIcon)
                .font(.system(size: 10))
            Text(stepTypeText)
                .font(.custom("Poppins-Medium", size: 11))
        }
        .foregroundColor(.white.opacity(0.9))
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(Color(hex: routine.color).opacity(0.25))
        )
    }

    private var stepTypeIcon: String {
        switch currentStep.type {
        case .breathing: return "wind"
        case .meditation: return "brain.head.profile"
        case .sound: return "speaker.wave.2.fill"
        case .journaling: return "book.fill"
        case .pause: return "pause.circle.fill"
        }
    }

    private var stepTypeText: String {
        switch currentStep.type {
        case .breathing: return NSLocalizedString("routines.type.breathing", comment: "")
        case .meditation: return NSLocalizedString("routines.type.meditation", comment: "")
        case .sound: return NSLocalizedString("routines.type.sound", comment: "")
        case .journaling: return NSLocalizedString("routines.type.journal", comment: "")
        case .pause: return NSLocalizedString("routines.type.pause", comment: "")
        }
    }

    private var hasLaunchableExercise: Bool {
        switch currentStep.type {
        case .breathing, .meditation, .journaling:
            return true
        case .sound, .pause:
            return false
        }
    }

    // MARK: - Player Controls
    private var playerControls: some View {
        HStack(spacing: 12) {
            // Previous button (only if not first step)
            if currentStepIndex > 0 {
                Button(action: previousStep) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                        .frame(width: 56, height: 56)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.1))
                        )
                }
                .buttonStyle(ScaleButtonStyle())
            }

            // Start Exercise button (long, takes remaining space) - only for breathing/meditation/journal
            if hasLaunchableExercise {
                Button(action: launchCurrentExercise) {
                    HStack(spacing: 10) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 16, weight: .semibold))

                        Text(NSLocalizedString("routines.launch.start", comment: ""))
                            .font(.custom("Poppins-Bold", size: 16))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 28)
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: routine.color), Color(hex: routine.color).opacity(0.7)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                }
                .buttonStyle(ScaleButtonStyle())
            }

            // Next/Complete button (circle with chevron or checkmark)
            Button(action: {
                if currentStepIndex < routine.steps.count - 1 {
                    advanceToNextStep()
                } else {
                    completeRoutine()
                }
            }) {
                ZStack {
                    if currentStepIndex < routine.steps.count - 1 {
                        // Next step - circle with chevron
                        Circle()
                            .fill(hasLaunchableExercise ? Color.white.opacity(0.15) : Color(hex: routine.color))
                            .frame(width: 56, height: 56)

                        Image(systemName: "chevron.right")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                    } else {
                        // Complete - circle with checkmark
                        Circle()
                            .fill(Color(hex: routine.color))
                            .frame(width: 56, height: 56)

                        Image(systemName: "checkmark")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 32)
    }

    // MARK: - Actions
    private func launchCurrentExercise() {
        HapticManager.light()

        switch currentStep.type {
        case .breathing:
            launchBreathingExercise()

        case .meditation:
            launchMeditationExercise()

        case .journaling:
            showJournalView = true

        case .sound, .pause:
            break
        }
    }

    private func launchBreathingExercise() {
        // Map referenceId to BreathingPattern
        guard let refId = currentStep.referenceId else { return }

        let pattern: BreathingPattern?
        switch refId {
        case "deepAbdominal":
            pattern = .deepAbdominal
        case "fourSevenEight":
            pattern = .fourSevenEight
        case "coherence":
            pattern = .coherence
        case "slow66":
            pattern = .slow66
        case "triangle":
            pattern = .triangle
        case "boxBreathing":
            pattern = .boxBreathing
        case "kapalabhati":
            pattern = .kapalabhati
        case "bhastrika":
            pattern = .bhastrika
        default:
            pattern = .coherence // Fallback
        }

        if let p = pattern {
            currentStepDuration = TimeInterval(currentStep.duration)
            currentBreathingPattern = p
        }
    }

    private func launchMeditationExercise() {
        // Map referenceId to MeditationSupport
        guard let refId = currentStep.referenceId else { return }

        if let support = MeditationSupport.support(for: refId) {
            currentMeditationSupport = support
        }
    }

    private func advanceToNextStep() {
        // Stop sound if playing
        if soundPlayer.isPlaying {
            soundPlayer.stop()
        }

        if currentStepIndex < routine.steps.count - 1 {
            HapticManager.light()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                currentStepIndex += 1
            }
        } else {
            completeRoutine()
        }
    }

    private func previousStep() {
        // Stop sound if playing
        if soundPlayer.isPlaying {
            soundPlayer.stop()
        }

        if currentStepIndex > 0 {
            HapticManager.light()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                currentStepIndex -= 1
            }
        }
    }

    private func completeRoutine() {
        // Stop sound if playing
        if soundPlayer.isPlaying {
            soundPlayer.stop()
        }

        HapticManager.success()

        // Track routine completion for rating request
        AppRatingService.shared.trackRoutineCompletion()

        withAnimation {
            showCompletion = true
        }
    }

    private func formatDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        if minutes > 0 && secs > 0 {
            return "\(minutes) min \(secs) sec"
        } else if minutes > 0 {
            return "\(minutes) min"
        } else {
            return "\(secs) sec"
        }
    }
}

// MARK: - Completion Overlay
struct RoutineCompletionOverlay: View {
    let routine: Routine
    let onDismiss: () -> Void
    @State private var showContent = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.85)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // Success icon
                ZStack {
                    Circle()
                        .fill(Color(hex: routine.color).opacity(0.2))
                        .frame(width: 120, height: 120)

                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(Color(hex: routine.color))
                }
                .scaleEffect(showContent ? 1.0 : 0.5)
                .opacity(showContent ? 1.0 : 0.0)

                VStack(spacing: 8) {
                    Text(NSLocalizedString("routines.completed.title", comment: ""))
                        .font(.faroBold(28))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    Text(routine.localizedName)
                        .font(.custom("Poppins-Medium", size: 18))
                        .foregroundColor(Color(hex: routine.color))
                }
                .opacity(showContent ? 1.0 : 0.0)

                // Stats
                HStack(spacing: 24) {
                    VStack(spacing: 4) {
                        Text(routine.formattedDuration)
                            .font(.faroBold(20))
                            .foregroundColor(.white)
                        Text(NSLocalizedString("routines.completed.duration", comment: ""))
                            .font(.custom("Poppins-Regular", size: 12))
                            .foregroundColor(.white.opacity(0.6))
                    }

                    Rectangle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 1, height: 40)

                    VStack(spacing: 4) {
                        Text("\(routine.steps.count)")
                            .font(.faroBold(20))
                            .foregroundColor(.white)
                        Text(NSLocalizedString("routines.completed.steps", comment: ""))
                            .font(.custom("Poppins-Regular", size: 12))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 32)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.1))
                )
                .opacity(showContent ? 1.0 : 0.0)

                // Continue button
                Button(action: onDismiss) {
                    Text(NSLocalizedString("routines.completed.continue", comment: ""))
                        .font(.custom("Poppins-Bold", size: 18))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(
                            RoundedRectangle(cornerRadius: 30)
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: routine.color), Color(hex: routine.color).opacity(0.7)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                }
                .buttonStyle(ScaleButtonStyle())
                .padding(.horizontal, 40)
                .padding(.top, 8)
                .opacity(showContent ? 1.0 : 0.0)
            }
            .padding(40)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) {
                showContent = true
            }
        }
    }
}

#Preview {
    RoutinePlayerView(routine: Routine.morningBeginner)
}
