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

    let steps = [
        GroundingStep(
            sense: "Vue",
            icon: "eye.fill",
            instruction: "Nomme 5 choses que tu vois",
            subtitle: "Regarde autour de toi",
            count: 5,
            color: "73DE85"
        ),
        GroundingStep(
            sense: "Toucher",
            icon: "hand.raised.fill",
            instruction: "Nomme 4 choses que tu touches",
            subtitle: "Ressens les textures",
            count: 4,
            color: "appThemeSecondary"
        ),
        GroundingStep(
            sense: "Ouïe",
            icon: "ear.fill",
            instruction: "Nomme 3 sons que tu entends",
            subtitle: "Écoute attentivement",
            count: 3,
            color: "00FF88"
        ),
        GroundingStep(
            sense: "Odorat",
            icon: "nose.fill",
            instruction: "Nomme 2 odeurs que tu sens",
            subtitle: "Respire profondément",
            count: 2,
            color: "9B7BF1"
        ),
        GroundingStep(
            sense: "Goût",
            icon: "mouth.fill",
            instruction: "Nomme 1 goût",
            subtitle: "Concentre-toi sur ta bouche",
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
                            .font(.custom("Poppins-SemiBold", size: 24))
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
                    Text(currentStep < steps.count - 1 ? "Suivant" : "Terminer")
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
                    xpEarned: 5,
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
