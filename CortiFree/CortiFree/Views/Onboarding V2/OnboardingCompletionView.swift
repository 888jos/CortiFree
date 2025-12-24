//
//  OnboardingCompletionView.swift
//  CortiFree
//
//  Created by Claude on 18/11/2025.
//  Final onboarding screen with paywall
//

import SwiftUI
import FirebaseAuth

struct OnboardingCompletionView: View {
    let habitsQuizResult: HabitsQuizResult?
    let onboardingStartTime: Date?
    let onViewPlan: () -> Void

    @StateObject private var storeKit = StoreKitManager.shared
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
        Group {
            if bypassPaywallForTesting {
                // DEBUG: Skip paywall and go directly to app
                Color.clear
                    .onAppear {
                        trackOnboardingCompletion()
                        onViewPlan()
                    }
            } else {
                CustomPaywallView(
                    onComplete: {
                        // User skipped paywall - complete onboarding
                        onViewPlan()
                    },
                    onPurchase: { planType in
                        Task {
                            isPurchasing = true
                            purchaseError = nil

                            // Map plan type to product ID
                            let productID = planType == "yearly"
                                ? StoreKitManager.yearlyProductID
                                : StoreKitManager.monthlyProductID

                            let result = await storeKit.purchase(productID)

                            isPurchasing = false

                            switch result {
                            case .success:
                                // Purchase successful - complete onboarding
                                onViewPlan()
                            case .cancelled:
                                // User cancelled - no error message needed
                                break
                            case .pending:
                                // Ask to Buy or other pending state
                                purchaseError = "Achat en attente d'approbation"
                            case .failed(let error):
                                purchaseError = error.localizedDescription
                            }
                        }
                    },
                    onRestore: {
                        Task {
                            isPurchasing = true
                            purchaseError = nil

                            let success = await storeKit.restorePurchases()

                            isPurchasing = false

                            if success {
                                // Restore successful - complete onboarding
                                onViewPlan()
                            } else {
                                purchaseError = "Aucun achat à restaurer"
                            }
                        }
                    }
                )
                .onAppear {
                    // Track paywall/completion screen viewed
                    MixpanelManager.shared.trackOnboardingCompletionViewed(
                        quizAnswersCount: habitsQuizResult?.answers.count ?? 0,
                        hasQuizData: habitsQuizResult != nil
                    )
                    // Track onboarding completion (once)
                    trackOnboardingCompletion()
                }
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

#Preview {
    OnboardingCompletionView(
        habitsQuizResult: HabitsQuizResult(answers: Array(repeating: 2, count: 12)),
        onboardingStartTime: Date().addingTimeInterval(-300),
        onViewPlan: {}
    )
}
