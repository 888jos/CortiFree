//
//  ExerciseDetailView.swift
//  CortiFree
//
//  Created by Claude on 10/11/2025.
//  Detail view for breathing and meditation exercises
//

import SwiftUI

struct ExerciseDetailView: View {
    let exercise: Exercise
    @Environment(\.dismiss) var dismiss
    @State private var showExerciseTimer = false
    @State private var pulseAnimation = false

    var body: some View {
        ZStack {
            // Galaxy background
            GalaxyBackgroundView(intensity: 0.8)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Custom animated header
                animatedHeader

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Hero section
                        heroSection

                        // Description
                        descriptionSection

                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 140)
                }

                // Fixed bottom button
                fixedBottomSection
            }
        }
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                pulseAnimation = true
            }
        }
        .fullScreenCover(isPresented: $showExerciseTimer) {
            ExerciseTimerView(exercise: exercise) {
                showExerciseTimer = false
                dismiss()
            }
        }
    }

    // MARK: - Animated Header

    private var animatedHeader: some View {
        ZStack(alignment: .topLeading) {
            // Gradient header background
            LinearGradient(
                colors: [
                    Color(hex: "49288C").opacity(0.3),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 120)
            .ignoresSafeArea(edges: .top)

            HStack {
                Button(action: {
                    HapticManager.light()
                    dismiss()
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.15))
                            .frame(width: 40, height: 40)
                            .blur(radius: 8)

                        Circle()
                            .fill(Color(hex: "1A1B3A").opacity(0.8))
                            .frame(width: 40, height: 40)

                        Image(systemName: "chevron.left")
                            .font(.custom("Poppins-SemiBold", size: 16))
                            .foregroundColor(.white)
                    }
                }

                Spacer()

                // Category badge
                HStack(spacing: 6) {
                    Image(systemName: exercise.icon)
                        .font(.system(size: 12))
                    Text(exercise.type.displayName.uppercased())
                        .font(.custom("Poppins-Bold", size: 11))
                }
                .foregroundColor(Color.appTheme)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.appTheme.opacity(0.2))
                        .overlay(
                            Capsule()
                                .stroke(Color.appTheme.opacity(0.5), lineWidth: 1)
                        )
                )
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(spacing: 20) {
            // Animated icon
            ZStack {
                // Glow circles
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.appTheme.opacity(0.3),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 40,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)
                    .scaleEffect(pulseAnimation ? 1.2 : 1.0)

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: "49288C"),
                                Color(hex: "2A2B5A")
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.appTheme.opacity(0.6),
                                        Color.appThemeSecondary.opacity(0.6)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                    .shadow(color: Color.appTheme.opacity(0.3), radius: 20, y: 10)

                Image(systemName: exercise.icon)
                    .font(.system(size: 50))
                    .foregroundColor(.white)
            }
            .padding(.top, 20)

            // Title
            Text(exercise.title)
                .font(.faroBold(32))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .shadow(color: Color.black.opacity(0.3), radius: 10, y: 5)

            // Description
            Text(exercise.description)
                .font(.custom("Poppins-Regular", size: 16))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .padding(.horizontal, 20)

            // Duration badge
            HStack(spacing: 8) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 16))
                    .foregroundColor(Color.appTheme)

                Text(formatDuration(exercise.duration))
                    .font(.faroSemiBold(18))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.1))
                    .overlay(
                        Capsule()
                            .stroke(Color.appTheme.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }

    // MARK: - Description Section

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Color.appTheme)

                Text(NSLocalizedString("exercise.about", comment: ""))
                    .font(.faroSemiBold(18))
                    .foregroundColor(.white)
            }

            Text(String(format: NSLocalizedString("exercise.about_description", comment: ""), exercise.type.displayName.lowercased()))
                .font(.custom("Poppins-Regular", size: 15))
                .foregroundColor(Color(hex: "E5E5E5"))
                .lineSpacing(8)
        }
        .padding(20)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: "1A1B3A").opacity(0.8),
                                Color(hex: "2A2B5A").opacity(0.6)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.appTheme.opacity(0.3),
                                Color.appThemeSecondary.opacity(0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
        )
    }

    // MARK: - Fixed Bottom Section

    private var fixedBottomSection: some View {
        VStack(spacing: 16) {
            // Launch Button
            Button(action: {
                HapticManager.success()
                showExerciseTimer = true
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 24))

                    Text(NSLocalizedString("exercise.start_exercise", comment: ""))
                        .font(.faroBold(18))
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
                                    colors: [
                                        Color.appTheme,
                                        Color.appThemeSecondary
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .blur(radius: 20)
                            .offset(y: 8)

                        // Main button
                        RoundedRectangle(cornerRadius: 32)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.appTheme,
                                        Color.appThemeSecondary
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
                )
            }
            .buttonStyle(ScaleButtonStyleSimple())
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(
            ZStack {
                LinearGradient(
                    colors: [
                        Color(hex: "01000C"),
                        Color(hex: "01000C").opacity(0.95)
                    ],
                    startPoint: .bottom,
                    endPoint: .top
                )
                .ignoresSafeArea(edges: .bottom)
            }
        )
    }

    private func formatDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        return "\(minutes) min"
    }
}

// MARK: - Exercise Timer View

struct ExerciseTimerView: View {
    let exercise: Exercise
    let onComplete: () -> Void

    @State private var timeRemaining: Int
    @State private var isRunning = true
    @State private var showCompletion = false
    @State private var scale: CGFloat = 1.0

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    init(exercise: Exercise, onComplete: @escaping () -> Void) {
        self.exercise = exercise
        self.onComplete = onComplete
        _timeRemaining = State(initialValue: exercise.duration)
    }

    var body: some View {
        ZStack {
            // Galaxy background
            GalaxyBackgroundView(intensity: 0.8)
                .ignoresSafeArea()

            if showCompletion {
                completionView
            } else {
                timerView
            }
        }
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
        }
        .onReceive(timer) { _ in
            if isRunning && timeRemaining > 0 {
                timeRemaining -= 1
            } else if timeRemaining == 0 && !showCompletion {
                completeExercise()
            }
        }
    }

    private var timerView: some View {
        VStack(spacing: 60) {
            VStack(spacing: 8) {
                Text(exercise.title)
                    .font(.faroSemiBold(24))
                    .foregroundColor(.white)

                Text(exercise.description)
                    .font(.custom("Poppins-Regular", size: 16))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 80)
            .padding(.horizontal, 40)

            // Breathing orb
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.appTheme,
                            Color.appThemeSecondary,
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 120
                        )
                )
                .frame(width: 240, height: 240)
                .blur(radius: 20)
                .scaleEffect(scale)
                .onAppear {
                    withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                        scale = 1.2
                    }
                }

            // Timer
            Text(formatTime(timeRemaining))
                .font(.faroBold(56))
                .foregroundColor(.white)
                .monospacedDigit()

            Spacer()

            // Close button
            Button(action: {
                HapticManager.light()
                onComplete()
            }) {
                Text(NSLocalizedString("exercise.stop", comment: ""))
                    .font(.custom("Poppins-Medium", size: 16))
                    .foregroundColor(Color.appTheme)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 30)
                            .stroke(Color.appTheme, lineWidth: 2)
                    )
            }
            .padding(.bottom, 60)
        }
    }

    private var completionView: some View {
        VStack(spacing: 32) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(Color.appTheme)

            Text(NSLocalizedString("exercise.congrats", comment: ""))
                .font(.faroSemiBold(32))
                .foregroundColor(.white)

            Text(NSLocalizedString("exercise.completed_message", comment: ""))
                .font(.custom("Poppins-Regular", size: 18))
                .foregroundColor(.white.opacity(0.8))

            Button(action: {
                HapticManager.success()
                onComplete()
            }) {
                Text(NSLocalizedString("exercise.finish", comment: ""))
                    .font(.faroSemiBold(18))
                    .foregroundColor(.white)
                    .frame(maxWidth: 200)
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
            .padding(.top, 16)
        }
        .padding(40)
    }

    private func completeExercise() {
        HapticManager.success()
        withAnimation {
            showCompletion = true
        }
    }

    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
}

struct ScaleButtonStyleSimple: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

#Preview {
    ExerciseDetailView(exercise: Exercise.breathingExercises[0])
}
