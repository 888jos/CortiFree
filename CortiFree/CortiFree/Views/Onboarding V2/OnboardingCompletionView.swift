//
//  OnboardingCompletionView.swift
//  CortiFree
//
//  Created by Claude on 18/11/2025.
//  Final onboarding screen with paywall (Native StoreKit 2)
//

import SwiftUI
import FirebaseAuth

struct OnboardingCompletionView: View {
    let habitsQuizResult: HabitsQuizResult?
    var selectedSymptoms: Set<String> = []
    let onboardingStartTime: Date?
    let language: String // Language detected during onboarding ("en" or "fr")
    let onViewPlan: () -> Void

    @State private var hasTrackedCompletion = false
    @State private var hasCompletedOnboarding = false // Prevent double completion

    // DEBUG: Set to true to bypass paywall during development
    // Change to false before shipping to App Store!
    #if DEBUG
    private let bypassPaywallForTesting = false // DISABLED FOR PRODUCTION
    #else
    private let bypassPaywallForTesting = false
    #endif

    var body: some View {
        // PRODUCTION: Show CustomPaywallView BUT bypass actual paywall
        // When "Start my program" is clicked, go directly to app
        CustomPaywallView(
            onComplete: {
                // Guard against double completion
                guard !hasCompletedOnboarding else {
                    print("⚠️ OnboardingCompletionView: Already completed, ignoring duplicate call")
                    return
                }
                hasCompletedOnboarding = true

                // Track completion and go to app
                trackOnboardingCompletion()
                onViewPlan()
            },
            onPurchase: { _ in
                // Not used - no purchase functionality
            },
            onRestore: {
                // Not used - no restore functionality
            },
            habitsQuizResult: habitsQuizResult,
            selectedSymptoms: selectedSymptoms
        )
        .onAppear {
            // Track completion screen viewed
            MixpanelManager.shared.trackOnboardingCompletionViewed(
                quizAnswersCount: habitsQuizResult?.answers.count ?? 0,
                hasQuizData: habitsQuizResult != nil
            )
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

        // Get user name from Auth
        let currentUser = Auth.auth().currentUser
        let firstName: String? = {
            if let displayName = currentUser?.displayName, !displayName.isEmpty {
                return displayName.components(separatedBy: " ").first
            }
            return UserDefaults.standard.string(forKey: "userFirstName")
        }()

        // Track complete onboarding with all data
        MixpanelManager.shared.trackOnboardingCompleted(
            totalTime: totalTime,
            quizGlobalScore: result.globalScore,
            selectedGoalsCount: 1, // Derived from quiz
            notificationsEnabled: notificationsEnabled,
            userId: currentUser?.uid,
            firstName: firstName,
            age: nil,
            gender: nil
        )

        // Set user profile if authenticated
        if let userId = currentUser?.uid {
            MixpanelManager.shared.identify(userId: userId)

            // Set user profile with quiz data
            MixpanelManager.shared.setUserProfile(
                firstName: firstName,
                email: currentUser?.email,
                age: nil,
                gender: nil,
                globalScore: result.globalScore,
                primaryGoal: result.primaryGoal
            )
        }
    }
}

// Superwall delegate handler removed - using native StoreKit 2 paywall now

#Preview {
    OnboardingCompletionView(
        habitsQuizResult: HabitsQuizResult(answers: Array(repeating: 2, count: 12)),
        onboardingStartTime: Date().addingTimeInterval(-300),
        language: "en",
        onViewPlan: {}
    )
}
