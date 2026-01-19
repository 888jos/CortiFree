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
    @State private var stepTimeRemaining: Int = 0
    @State private var isPlaying = true
    @State private var timer: Timer?
    @State private var showCompletion = false
    @State private var pulseAnimation = false

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
            startStep()
            withAnimation(Animation.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                pulseAnimation = true
            }
        }
        .onDisappear {
            timer?.invalidate()
        }
    }

    // MARK: - Player Header
    private var playerHeader: some View {
        VStack(spacing: 20) {
            HStack {
                Button(action: {
                    HapticManager.light()
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

            VStack(spacing: 20) {
                // Step label with timer
                HStack(spacing: 12) {
                    Text("\(NSLocalizedString("routines.step", comment: "")) \(currentStepIndex + 1)")
                        .font(.custom("Poppins-Bold", size: 14))
                        .tracking(2)
                        .foregroundColor(Color(hex: routine.color))
                        .textCase(.uppercase)

                    if stepTimeRemaining > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 10))
                            Text(formatTime(stepTimeRemaining))
                                .font(.custom("Poppins-Bold", size: 11))
                        }
                        .foregroundColor(.white.opacity(0.9))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(Color(hex: routine.color).opacity(0.25))
                        )
                    }
                }

                // Instruction
                Text(currentStep.localizedInstruction)
                    .font(.custom("Poppins-SemiBold", size: 24))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(8)
                    .padding(.horizontal, 32)

                // Step type indicator
                stepTypeIndicator
            }
            .id(currentStepIndex)
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))
        }
    }

    private var stepTypeIndicator: some View {
        Group {
            switch currentStep.type {
            case .breathing:
                Text(NSLocalizedString("routines.type.breathing", comment: ""))
                    .font(.custom("Poppins-Regular", size: 14))
                    .foregroundColor(.white.opacity(0.6))

            case .meditation:
                Text(NSLocalizedString("routines.type.meditation", comment: ""))
                    .font(.custom("Poppins-Regular", size: 14))
                    .foregroundColor(.white.opacity(0.6))

            case .sound:
                Text(NSLocalizedString("routines.type.sound", comment: ""))
                    .font(.custom("Poppins-Regular", size: 14))
                    .foregroundColor(.white.opacity(0.6))

            case .journaling:
                Text(NSLocalizedString("routines.type.journal", comment: ""))
                    .font(.custom("Poppins-Regular", size: 14))
                    .foregroundColor(.white.opacity(0.6))

            case .pause:
                Text(NSLocalizedString("routines.type.pause", comment: ""))
                    .font(.custom("Poppins-Regular", size: 14))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
    }

    // MARK: - Player Controls
    private var playerControls: some View {
        HStack(spacing: 16) {
            // Previous button
            if currentStepIndex > 0 {
                Button(action: previousStep) {
                    Image(systemName: "chevron.left")
                        .font(.custom("Poppins-SemiBold", size: 18))
                        .foregroundColor(.white.opacity(0.8))
                        .frame(width: 56, height: 56)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.1))
                        )
                }
                .buttonStyle(ScaleButtonStyle())
            }

            // Next/Complete button
            Button(action: {
                if currentStepIndex < routine.steps.count - 1 {
                    advanceToNextStep()
                } else {
                    completeRoutine()
                }
            }) {
                HStack(spacing: 12) {
                    Text(currentStepIndex < routine.steps.count - 1 ?
                         NSLocalizedString("routines.next", comment: "") :
                         NSLocalizedString("routines.complete", comment: ""))
                        .font(.custom("Poppins-Bold", size: 18))
                    Image(systemName: currentStepIndex < routine.steps.count - 1 ? "chevron.right" : "checkmark.circle.fill")
                        .font(.system(size: 18))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 64)
                .background(
                    RoundedRectangle(cornerRadius: 32)
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
        .padding(.horizontal, 24)
        .padding(.bottom, 32)
    }

    // MARK: - Helper Methods
    private func startStep() {
        stepTimeRemaining = currentStep.duration
        timer?.invalidate()

        // Start countdown timer
        if stepTimeRemaining > 0 {
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                if stepTimeRemaining > 0 {
                    stepTimeRemaining -= 1
                }
                // Don't auto-advance - let user control the flow
            }
        }
    }

    private func advanceToNextStep() {
        timer?.invalidate()

        if currentStepIndex < routine.steps.count - 1 {
            HapticManager.light()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                currentStepIndex += 1
            }
            startStep()
        } else {
            completeRoutine()
        }
    }

    private func previousStep() {
        timer?.invalidate()

        if currentStepIndex > 0 {
            HapticManager.light()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                currentStepIndex -= 1
            }
            startStep()
        }
    }

    private func completeRoutine() {
        timer?.invalidate()
        HapticManager.success()

        withAnimation {
            showCompletion = true
        }
    }

    private func formatTime(_ seconds: Int) -> String {
        if seconds >= 60 {
            let mins = seconds / 60
            let secs = seconds % 60
            return secs == 0 ? "\(mins)'" : "\(mins)'\(String(format: "%02d", secs))''"
        } else {
            return "\(seconds)''"
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
                        .font(.custom("Poppins-Bold", size: 28))
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
                            .font(.custom("Poppins-Bold", size: 20))
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
                            .font(.custom("Poppins-Bold", size: 20))
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
    RoutinePlayerView(routine: Routine.morningRoutine)
}
