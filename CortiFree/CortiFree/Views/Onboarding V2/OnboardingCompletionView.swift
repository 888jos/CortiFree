//
//  OnboardingCompletionView.swift
//  CortiFree
//
//  Created by Claude on 18/11/2025.
//  Final onboarding screen with paywall (Native StoreKit 2)
//

import SwiftUI
import UserNotifications

struct OnboardingCompletionView: View {
    let habitsQuizResult: HabitsQuizResult?
    var selectedSymptoms: Set<String> = []
    let onboardingStartTime: Date?
    let language: String // Language detected during onboarding ("en" or "fr")
    let onViewPlan: () -> Void

    @State private var hasTrackedCompletion = false
    @State private var hasCompletedOnboarding = false // Prevent double completion
    @State private var restoreMessage: String?
    @ObservedObject private var revenueCat = RevenueCatManager.shared

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
            onRestore: restorePurchases,
            habitsQuizResult: habitsQuizResult,
            selectedSymptoms: selectedSymptoms,
            requiresPurchaseToComplete: true
        )
        .alert(
            restoreMessage ?? "",
            isPresented: Binding(get: { restoreMessage != nil }, set: { if !$0 { restoreMessage = nil } })
        ) {
            Button("common.ok".localized, role: .cancel) {}
        }
        .onChange(of: revenueCat.hasPremiumEntitlement) { _, isPremium in
            // Trial started from a paywall opened elsewhere (recovery notification, Live Activity).
            guard isPremium, !hasCompletedOnboarding else { return }
            hasCompletedOnboarding = true
            trackOnboardingCompletion()
            onViewPlan()
        }
        .onAppear {
            // Track completion screen viewed
            AnalyticsManager.shared.trackOnboardingCompletionViewed(
                quizAnswersCount: habitsQuizResult?.answers.count ?? 0,
                hasQuizData: habitsQuizResult != nil
            )
        }
    }

    // MARK: - Restore

    /// Restores an existing subscription (reinstall, new device) and finishes the onboarding
    /// when the "pro" entitlement comes back.
    private func restorePurchases() {
        Task { @MainActor in
            do {
                _ = try await RevenueCatManager.shared.restorePurchases()
            } catch {
                restoreMessage = "settings.restore.nothing".localized
                return
            }
            if RevenueCatManager.shared.hasPremiumEntitlement {
                guard !hasCompletedOnboarding else { return }
                hasCompletedOnboarding = true
                trackOnboardingCompletion()
                onViewPlan()
            } else {
                restoreMessage = "settings.restore.nothing".localized
            }
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
            AnalyticsManager.shared.trackOnboardingCompleted(
                totalTime: nil,
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
        let totalTime = onboardingStartTime.map { Date().timeIntervalSince($0) }

        Task { @MainActor in
            let notificationsEnabled = await Self.notificationsAuthorized()
            trackOnboardingCompleted(result: result, totalTime: totalTime, notificationsEnabled: notificationsEnabled)
        }
    }

    private static func notificationsAuthorized() async -> Bool {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        default:
            return false
        }
    }

    private func trackOnboardingCompleted(result: HabitsQuizResult, totalTime: Double?, notificationsEnabled: Bool) {
        // Get user name from Auth
        let currentUser = Auth.auth().currentUser
        let firstName: String? = {
            if let displayName = currentUser?.displayName, !displayName.isEmpty {
                return displayName.components(separatedBy: " ").first
            }
            return UserDefaults.standard.string(forKey: "userFirstName")
        }()

        // Profile answers saved by the quiz steps (age bracket → its lower bound, e.g. "25_34" → 25).
        let draft = PersonalPlanStore.shared.storedOnboardingProfile()
        let age = draft?.ageCode.flatMap { code in
            code == "under_18" ? 17 : Int(code.split(separator: "_").first ?? "")
        }
        let gender = draft?.genderCode

        // Track complete onboarding with all data
        AnalyticsManager.shared.trackOnboardingCompleted(
            totalTime: totalTime,
            selectedGoalsCount: 1, // Derived from quiz
            notificationsEnabled: notificationsEnabled,
            userId: currentUser?.uid,
            firstName: firstName,
            age: age,
            gender: gender
        )

        // Set user profile if authenticated
        if let userId = currentUser?.uid {
            AnalyticsManager.shared.identify(userId: userId)

            // Set user profile with quiz data
            AnalyticsManager.shared.setUserProfile(
                firstName: firstName,
                email: currentUser?.email,
                age: age,
                gender: gender,
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
