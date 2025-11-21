//
//  OnboardingCompletionView.swift
//  CortiFree
//
//  Created by Claude on 18/11/2025.
//  Completion screen with paywall placeholder and plan preview
//

import SwiftUI
import FirebaseAuth

struct OnboardingCompletionView: View {
    let habitsQuizResult: HabitsQuizResult?
    let onboardingStartTime: Date?
    let onViewPlan: () -> Void

    @State private var showContent = false
    @State private var hasTrackedCompletion = false
    @State private var hasTrackedViewPlan = false

    var body: some View {
        ZStack {
            // Galaxy background
            GalaxyBackgroundView()
                .ignoresSafeArea()

            // Dark overlay
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                if showContent {
                    // Success icon
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color(hex: "B794F6").opacity(0.3),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 20,
                                    endRadius: 100
                                )
                            )
                            .frame(width: 200, height: 200)

                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 100))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(hex: "B794F6"), Color(hex: "D4B4FF")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: Color(hex: "B794F6").opacity(0.5), radius: 30)
                    }
                    .padding(.bottom, 40)
                    .transition(.scale.combined(with: .opacity))

                    // Title
                    Text("Félicitations !")
                        .font(.custom("Faro-BoldLucky", size: 36))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, Color(hex: "B794F6")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 16)
                        .transition(.opacity)

                    // Subtitle
                    Text("Ton diagnostic est prêt")
                        .font(.custom("Poppins-Regular", size: 18))
                        .foregroundColor(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .padding(.bottom, 40)
                        .transition(.opacity)

                    // Paywall Placeholder
                    VStack(spacing: 16) {
                        Text("📍 EMPLACEMENT PAYWALL")
                            .font(.custom("Poppins-Bold", size: 16))
                            .foregroundColor(Color(hex: "FFD700"))
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color(hex: "FFD700").opacity(0.5), lineWidth: 2)
                                    )
                            )

                        // Debug info if quiz result exists
                        if let result = habitsQuizResult {
                            VStack(spacing: 8) {
                                Text("Données collectées:")
                                    .font(.custom("Poppins-Medium", size: 14))
                                    .foregroundColor(.white.opacity(0.7))

                                Text("\(result.answers.count) réponses enregistrées")
                                    .font(.custom("Poppins-Regular", size: 12))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                            .padding(.top, 8)
                        }
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 32)
                    .transition(.opacity)
                }

                Spacer()

                if showContent {
                    // View Plan button
                    Button(action: {
                        // Prevent double tracking
                        guard !hasTrackedViewPlan else {
                            onViewPlan()
                            return
                        }
                        hasTrackedViewPlan = true

                        HapticManager.medium()

                        // Track view plan button click (once)
                        MixpanelManager.shared.trackOnboardingViewPlanClicked()

                        onViewPlan()
                    }) {
                        HStack(spacing: 12) {
                            Text("Voir mon plan personnalisé")
                                .font(.custom("Poppins-SemiBold", size: 16))
                                .foregroundColor(Color(hex: "1A1A4E"))

                            ZStack {
                                Circle()
                                    .fill(Color(hex: "1A1A4E"))
                                    .frame(width: 32, height: 32)

                                Image(systemName: "arrow.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.vertical, 12)
                        .padding(.leading, 24)
                        .padding(.trailing, 12)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 40))
                        .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 50)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
                showContent = true
            }

            // Track onboarding completion (once)
            trackOnboardingCompletion()
        }
    }

    // MARK: - Track Onboarding Completion

    private func trackOnboardingCompletion() {
        // Prevent duplicate tracking
        guard !hasTrackedCompletion else { return }
        hasTrackedCompletion = true

        // Get quiz result data if available
        guard let result = habitsQuizResult else {
            // No quiz data - track basic completion
            MixpanelManager.shared.trackOnboardingCompleted(
                totalTime: nil,
                quizGlobalScore: nil,
                selectedGoalsCount: nil,
                notificationsEnabled: nil,
                userId: Auth.auth().currentUser?.uid,
                firstName: nil,
                age: nil,
                gender: nil
            )
            return
        }

        // Calculate total onboarding time from start to completion
        var totalTime: Double? = nil
        if let startTime = onboardingStartTime {
            totalTime = Date().timeIntervalSince(startTime)
        }

        // TODO: Get actual notifications permission status
        let notificationsEnabled = false // Placeholder

        // TODO: Get user data from overall quiz
        let firstName: String? = nil
        let age: Int? = nil
        let gender: String? = nil

        // Track complete onboarding with all data
        MixpanelManager.shared.trackOnboardingCompleted(
            totalTime: totalTime,
            quizGlobalScore: result.globalScore,
            selectedGoalsCount: 1, // Derived from quiz
            notificationsEnabled: notificationsEnabled,
            userId: Auth.auth().currentUser?.uid,
            firstName: firstName,
            age: age,
            gender: gender
        )

        // Set user profile if authenticated
        if let userId = Auth.auth().currentUser?.uid {
            MixpanelManager.shared.identify(userId: userId)

            // Set user profile with quiz data
            MixpanelManager.shared.setUserProfile(
                firstName: firstName,
                email: Auth.auth().currentUser?.email,
                age: age,
                gender: gender,
                globalScore: result.globalScore,
                primaryGoal: result.primaryGoal
            )
        }
    }
}

#Preview {
    OnboardingCompletionView(
        habitsQuizResult: HabitsQuizResult(answers: [1, 2, 3, 4, 5]),
        onboardingStartTime: Date().addingTimeInterval(-60), // 60 seconds ago for preview
        onViewPlan: {}
    )
}
