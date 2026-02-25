//
//  GroundingExerciseView.swift
//  CortiFree
//
//  Created by Claude on 22/10/2025.
//  5 Senses Grounding Exercise
//

import SwiftUI

struct GroundingExerciseView: View {
    let situation: StressSituation
    @ObservedObject var viewModel: AntiStressViewModel
    @Environment(\.dismiss) var dismiss

    @State private var currentStep = 0
    @State private var showCompletion = false
    @State private var showConfetti = false
    @ObservedObject private var voiceOverManager = VoiceOverManager.shared

    let steps = [
        GroundingStep(
            sense: NSLocalizedString("exercise.grounding_basic.step_1.sense", comment: ""),
            icon: "eye.fill",
            instruction: NSLocalizedString("exercise.grounding_basic.step_1.instruction", comment: ""),
            subtitle: NSLocalizedString("exercise.grounding_basic.step_1.subtitle", comment: ""),
            count: 5,
            color: "73DE85"
        ),
        GroundingStep(
            sense: NSLocalizedString("exercise.grounding_basic.step_2.sense", comment: ""),
            icon: "hand.raised.fill",
            instruction: NSLocalizedString("exercise.grounding_basic.step_2.instruction", comment: ""),
            subtitle: NSLocalizedString("exercise.grounding_basic.step_2.subtitle", comment: ""),
            count: 4,
            color: "66BB6A"
        ),
        GroundingStep(
            sense: NSLocalizedString("exercise.grounding_basic.step_3.sense", comment: ""),
            icon: "ear.fill",
            instruction: NSLocalizedString("exercise.grounding_basic.step_3.instruction", comment: ""),
            subtitle: NSLocalizedString("exercise.grounding_basic.step_3.subtitle", comment: ""),
            count: 3,
            color: "00FF88"
        ),
        GroundingStep(
            sense: NSLocalizedString("exercise.grounding_basic.step_4.sense", comment: ""),
            icon: "nose.fill",
            instruction: NSLocalizedString("exercise.grounding_basic.step_4.instruction", comment: ""),
            subtitle: NSLocalizedString("exercise.grounding_basic.step_4.subtitle", comment: ""),
            count: 2,
            color: "9B7BF1"
        ),
        GroundingStep(
            sense: NSLocalizedString("exercise.grounding_basic.step_5.sense", comment: ""),
            icon: "mouth.fill",
            instruction: NSLocalizedString("exercise.grounding_basic.step_5.instruction", comment: ""),
            subtitle: NSLocalizedString("exercise.grounding_basic.step_5.subtitle", comment: ""),
            count: 1,
            color: "FF6B9D"
        )
    ]

    var currentGroundingStep: GroundingStep {
        steps[currentStep]
    }

    var body: some View {
        ZStack {
            // Dark gradient background
            LinearGradient(
                colors: [
                    Color(hex: "1F0140"),
                    Color(hex: "0B011B"),
                    Color(hex: "01000C")
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        HapticManager.light()
                        voiceOverManager.stop()
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white.opacity(0.6))
                    }

                    Spacer()

                    // Progress indicator
                    HStack(spacing: 8) {
                        ForEach(0..<steps.count, id: \.self) { index in
                            Circle()
                                .fill(index <= currentStep ? Color.appTheme : Color.white.opacity(0.3))
                                .frame(width: 8, height: 8)
                        }
                    }

                    Spacer()

                    // VoiceOver toggle button
                    Button(action: {
                        HapticManager.light()
                        voiceOverManager.toggle()
                        if voiceOverManager.isEnabled {
                            speakCurrentStep()
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(voiceOverManager.isEnabled ? Color(hex: "B388FF").opacity(0.2) : Color.white.opacity(0.1))
                                .frame(width: 44, height: 44)
                                .blur(radius: 8)

                            Circle()
                                .fill(voiceOverManager.isEnabled ? Color(hex: "B388FF").opacity(0.3) : Color(hex: "1A1B3A").opacity(0.9))
                                .frame(width: 44, height: 44)

                            Image(systemName: voiceOverManager.isEnabled ? "speaker.wave.3.fill" : "speaker.slash.fill")
                                .font(.custom("Poppins-SemiBold", size: 16))
                                .foregroundColor(voiceOverManager.isEnabled ? Color(hex: "B388FF") : .white.opacity(0.7))
                                .scaleEffect(voiceOverManager.isSpeaking ? 1.1 : 1.0)
                                .animation(.easeInOut(duration: 0.3).repeatForever(autoreverses: true), value: voiceOverManager.isSpeaking)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 40)

                Spacer()

                // Main content
                VStack(spacing: 40) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color(hex: currentGroundingStep.color).opacity(0.3),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 100
                                )
                            )
                            .frame(width: 200, height: 200)

                        Image(systemName: currentGroundingStep.icon)
                            .font(.system(size: 80))
                            .foregroundColor(Color(hex: currentGroundingStep.color))
                    }

                    // Step info
                    VStack(spacing: 16) {
                        Text(currentGroundingStep.sense)
                            .font(.faroSemiBold(24))
                            .foregroundColor(.white)

                        Text(currentGroundingStep.instruction)
                            .font(.custom("Poppins-Medium", size: 20))
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)

                        Text(currentGroundingStep.subtitle)
                            .font(.custom("Poppins-Regular", size: 16))
                            .foregroundColor(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 40)

                    // Count indicator
                    HStack(spacing: 12) {
                        ForEach(0..<currentGroundingStep.count, id: \.self) { index in
                            Circle()
                                .strokeBorder(Color(hex: currentGroundingStep.color), lineWidth: 2)
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Text("\(index + 1)")
                                        .font(.custom("Poppins-SemiBold", size: 18))
                                        .foregroundColor(.white)
                                )
                        }
                    }
                }

                Spacer()

                // Next button
                Button(action: {
                    HapticManager.light()
                    nextStep()
                }) {
                    Text(currentStep < steps.count - 1 ? NSLocalizedString("exercise.button.next", comment: "") : NSLocalizedString("exercise.button.finish", comment: ""))
                        .font(.custom("Poppins-SemiBold", size: 18))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
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
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }

            // Completion overlay
            if showCompletion {
                CompletionOverlay(
                    onDismiss: {
                        dismiss()
                    }
                )
                .transition(.opacity)
            }

            // Confetti
            if showConfetti {
                ConfettiView()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
        }
        .onAppear {
            viewModel.startExercise(.grounding5Senses)
            speakCurrentStep()
        }
        .onChange(of: currentStep) { _ in
            speakCurrentStep()
        }
    }

    // MARK: - VoiceOver

    private func speakCurrentStep() {
        guard voiceOverManager.isEnabled else { return }

        let step = steps[currentStep]
        voiceOverManager.announceStep(current: currentStep + 1, total: steps.count)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let text = "\(step.sense). \(step.instruction). \(step.subtitle)"
            self.voiceOverManager.speak(text)
        }
    }

    // MARK: - Navigation

    private func nextStep() {
        if currentStep < steps.count - 1 {
            withAnimation(.spring(response: 0.3)) {
                currentStep += 1
            }
        } else {
            completeExercise()
        }
    }

    private func completeExercise() {
        voiceOverManager.announceCompletion()

        Task {
            await viewModel.completeExercise()
            HapticManager.success()

            withAnimation {
                showConfetti = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation {
                    showCompletion = true
                }
            }
        }
    }
}

// MARK: - Grounding Step Model

struct GroundingStep {
    let sense: String
    let icon: String
    let instruction: String
    let subtitle: String
    let count: Int
    let color: String
}

#Preview {
    GroundingExerciseView(
        situation: .overwhelmed,
        viewModel: AntiStressViewModel()
    )
}
