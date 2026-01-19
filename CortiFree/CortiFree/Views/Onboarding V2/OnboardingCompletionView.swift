//
//  OnboardingCompletionView.swift
//  CortiFree
//
//  Created by Claude on 18/11/2025.
//  Final onboarding screen with paywall
//

import SwiftUI
import FirebaseAuth
import SuperwallKit

struct OnboardingCompletionView: View {
    let habitsQuizResult: HabitsQuizResult?
    let onboardingStartTime: Date?
    let language: String // Language detected during onboarding ("en" or "fr")
    let onViewPlan: () -> Void

    @StateObject private var storeKit = StoreKitManager.shared
    @StateObject private var superwallDelegate = SuperwallDelegateHandler()
    @State private var hasTrackedCompletion = false
    @State private var isPurchasing = false
    @State private var purchaseError: String?

    // DEBUG: Set to true to bypass paywall during development
    // Change to false before shipping to App Store!
    #if DEBUG
    private let bypassPaywallForTesting = false // DISABLED FOR PRODUCTION
    #else
    private let bypassPaywallForTesting = false
    #endif


    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(hex: "0A0515"),
                    Color(hex: "1a0a2e")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        }
        .onAppear {
            if bypassPaywallForTesting {
                // DEBUG: Skip paywall and go directly to app
                trackOnboardingCompletion()
                onViewPlan()
            } else {
                // Track paywall/completion screen viewed
                MixpanelManager.shared.trackOnboardingCompletionViewed(
                    quizAnswersCount: habitsQuizResult?.answers.count ?? 0,
                    hasQuizData: habitsQuizResult != nil
                )
                // Track onboarding completion (once)
                trackOnboardingCompletion()

                // Setup Superwall delegate callback
                superwallDelegate.onComplete = onViewPlan
                Superwall.shared.delegate = superwallDelegate

                // Show Superwall paywall with language-specific placement
                let placement = language == "fr" ? "trigger_fr" : "trigger"
                print("🌍 Showing Superwall paywall with placement: \(placement) (language: \(language))")
                Superwall.shared.register(placement: placement)
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

// MARK: - Superwall Delegate Handler

class SuperwallDelegateHandler: SuperwallDelegate, ObservableObject {
    var onComplete: (() -> Void)?

    func handleSuperwallEvent(withInfo eventInfo: SuperwallEventInfo) {
        switch eventInfo.event {
        case .paywallClose:
            print("⚠️ Superwall paywall closed")
            DispatchQueue.main.async {
                self.onComplete?()
            }
        case .paywallDecline:
            print("⚠️ Superwall paywall declined")
            DispatchQueue.main.async {
                self.onComplete?()
            }
        case .transactionComplete:
            print("✅ Superwall transaction complete")
            DispatchQueue.main.async {
                self.onComplete?()
            }
        case .transactionRestore:
            print("✅ Superwall transaction restored")
            DispatchQueue.main.async {
                self.onComplete?()
            }
        default:
            break
        }
    }
}

#Preview {
    OnboardingCompletionView(
        habitsQuizResult: HabitsQuizResult(answers: Array(repeating: 2, count: 12)),
        onboardingStartTime: Date().addingTimeInterval(-300),
        language: "en",
        onViewPlan: {}
    )
}
