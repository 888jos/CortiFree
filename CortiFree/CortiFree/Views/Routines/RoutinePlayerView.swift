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
            GalaxyBackgroundView(intensity: 0.75)
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
            }
        }
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
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
                    Image(systemName: "xmark")
                        .font(.custom("Poppins-SemiBold", size: 16))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .glassCircle(interactive: true)

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
                .glassCapsule(tint: Color(hex: routine.color))

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
                    .opacity(0.6)

                Circle()
                    .fill(Color(hex: routine.color).opacity(0.3))
                    .frame(width: 140, height: 140)

                Image(systemName: currentStep.icon)
                    .font(.system(size: 50, weight: .regular))
                    .foregroundColor(.white)
                    .shadow(color: Color(hex: routine.color).opacity(0.5), radius: 20)
            }

            VStack(spacing: 16) {
                // Step label
                HStack(spacing: 12) {
                    Text("\(LanguageManager.shared.localizedString(for: "routines.step")) \(currentStepIndex + 1)")
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
        .glassCapsule(tint: Color(hex: routine.color))
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
        case .breathing: return LanguageManager.shared.localizedString(for: "routines.type.breathing")
        case .meditation: return LanguageManager.shared.localizedString(for: "routines.type.meditation")
        case .sound: return LanguageManager.shared.localizedString(for: "routines.type.sound")
        case .journaling: return LanguageManager.shared.localizedString(for: "routines.type.journal")
        case .pause: return LanguageManager.shared.localizedString(for: "routines.type.pause")
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
        GlassGroup(spacing: 12) {
        HStack(spacing: 12) {
            // Previous button (only if not first step)
            if currentStepIndex > 0 {
                Button(action: previousStep) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                        .frame(width: 56, height: 56)
                        .contentShape(Circle())
                        .glassCircle(interactive: true)
                }
                .buttonStyle(ScaleButtonStyle())
            }

            // Start Exercise button (long, takes remaining space) - only for breathing/meditation/journal
            if hasLaunchableExercise {
                Button(action: launchCurrentExercise) {
                    HStack(spacing: 10) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 16, weight: .semibold))

                        Text(LanguageManager.shared.localizedString(for: "routines.launch.start"))
                            .font(.custom("Poppins-Bold", size: 16))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .contentShape(Capsule())
                }
                .buttonStyle(.glassPrimary(tint: Color(hex: routine.color)))
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
                        Image(systemName: "chevron.right")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 56, height: 56)
                            .contentShape(Circle())
                            .glassCircle(tint: hasLaunchableExercise ? nil : Color(hex: routine.color),
                                         interactive: true)
                    } else {
                        // Complete - circle with checkmark
                        Image(systemName: "checkmark")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 56, height: 56)
                            .contentShape(Circle())
                            .glassCircle(tint: Color(hex: routine.color), interactive: true)
                    }
                }
            }
            .buttonStyle(ScaleButtonStyle())
        }
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
            currentStepIndex += 1
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
            currentStepIndex -= 1
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

        showCompletion = true
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

                VStack(spacing: 8) {
                    Text(LanguageManager.shared.localizedString(for: "routines.completed.title"))
                        .font(.faroBold(28))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    Text(routine.localizedName)
                        .font(.custom("Poppins-Medium", size: 18))
                        .foregroundColor(Color(hex: routine.color))
                }

                // Stats
                HStack(spacing: 24) {
                    VStack(spacing: 4) {
                        Text(routine.formattedDuration)
                            .font(.faroBold(20))
                            .foregroundColor(.white)
                        Text(LanguageManager.shared.localizedString(for: "routines.completed.duration"))
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
                        Text(LanguageManager.shared.localizedString(for: "routines.completed.steps"))
                            .font(.custom("Poppins-Regular", size: 12))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 32)
                .glassCard(cornerRadius: 18)

                // Continue button
                Button(action: onDismiss) {
                    Text(LanguageManager.shared.localizedString(for: "routines.completed.continue"))
                        .font(.custom("Poppins-Bold", size: 18))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .contentShape(Capsule())
                }
                .buttonStyle(.glassPrimary(tint: Color(hex: routine.color)))
                .padding(.horizontal, 40)
                .padding(.top, 8)
            }
            .padding(40)
        }
    }
}

#Preview {
    RoutinePlayerView(routine: Routine.morningBeginner)
}
