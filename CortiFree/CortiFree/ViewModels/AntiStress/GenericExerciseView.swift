//
//  GenericExerciseView.swift
//  CortiFree
//
//  Created by Claude on 22/10/2025.
//  Generic exercise view for not-yet-implemented exercises
//

import SwiftUI

struct GenericExerciseView: View {
    let exerciseType: AntiStressExerciseType
    let situation: StressSituation
    @ObservedObject var viewModel: AntiStressViewModel
    @Environment(\.dismiss) var dismiss

    @State private var timeRemaining: Int
    @State private var showCompletion = false
    @State private var showConfetti = false

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    init(exerciseType: AntiStressExerciseType, situation: StressSituation, viewModel: AntiStressViewModel) {
        self.exerciseType = exerciseType
        self.situation = situation
        self.viewModel = viewModel
        _timeRemaining = State(initialValue: exerciseType.duration)
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

            VStack(spacing: 40) {
                // Close button
                HStack {
                    Button(action: {
                        HapticManager.light()
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white.opacity(0.85))
                            .frame(width: 40, height: 40)
                            .contentShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .glassCircle(interactive: true)
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)

                Spacer()

                // Exercise info
                VStack(spacing: 24) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 80))
                        .foregroundColor(Color.appTheme)

                    VStack(spacing: 12) {
                        Text(exerciseType.displayName)
                            .font(.faroSemiBold(28))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(exerciseType.description)
                            .font(.custom("Poppins-Regular", size: 18))
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                }

                Spacer()

                // Timer
                VStack(spacing: 16) {
                    Text(formatTime(timeRemaining))
                        .font(.faroBold(60))
                        .foregroundColor(.white)
                        .monospacedDigit()

                    Text(LanguageManager.shared.localizedString(for: "exercise.generic.enjoy_time"))
                        .font(.custom("Poppins-Regular", size: 16))
                        .foregroundColor(.white.opacity(0.6))
                }

                Spacer()

                // Skip button
                Button(action: {
                    HapticManager.medium()
                    completeExercise()
                }) {
                    Text(LanguageManager.shared.localizedString(for: "exercise.generic.finish_now"))
                        .font(.custom("Poppins-Medium", size: 16))
                        .foregroundColor(.white.opacity(0.75))
                        .padding(.horizontal, 22)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.glassSecondary)
                .padding(.bottom, 40)
            }

            // Completion overlay
            if showCompletion {
                CompletionOverlay(
                    content: RatedContent(type: .exercise, id: exerciseType.rawValue, title: exerciseType.displayName),
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
            UIApplication.shared.isIdleTimerDisabled = true
            viewModel.startExercise(exerciseType)
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
        }
        .onReceive(timer) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                completeExercise()
            }
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

    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
}

// MARK: - Placeholder Views

struct Anchoring54321View: View {
    let situation: StressSituation
    @ObservedObject var viewModel: AntiStressViewModel

    var body: some View {
        GenericExerciseView(
            exerciseType: .anchoring54321,
            situation: situation,
            viewModel: viewModel
        )
    }
}

struct BodyScanExerciseView: View {
    let situation: StressSituation
    @ObservedObject var viewModel: AntiStressViewModel

    var body: some View {
        GenericExerciseView(
            exerciseType: .bodyScan,
            situation: situation,
            viewModel: viewModel
        )
    }
}

struct MeditationExerciseView: View {
    let situation: StressSituation
    @ObservedObject var viewModel: AntiStressViewModel

    var body: some View {
        GenericExerciseView(
            exerciseType: .meditation2Min,
            situation: situation,
            viewModel: viewModel
        )
    }
}
