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

    // Get user name from UserDefaults
    private var userName: String {
        UserDefaults.standard.string(forKey: "userFirstName") ?? "toi"
    }

    // Calculate scores from quiz result
    private var baselineScores: [Double] {
        guard let result = habitsQuizResult else {
            return [0.4, 0.35, 0.45, 0.5, 0.4]
        }
        return [
            Double(result.serenityScore) / 100.0,
            Double(result.sleepScore) / 100.0,
            Double(result.energyScore) / 100.0,
            Double(result.focusScore) / 100.0,
            Double(result.balanceScore) / 100.0
        ]
    }

    private var potentialScores: [Double] {
        [0.85, 0.80, 0.90, 0.88, 0.82]
    }

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
                    },
                    userName: userName,
                    baselineScores: baselineScores,
                    potentialScores: potentialScores
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

        // Track complete onboarding with all data
        MixpanelManager.shared.trackOnboardingCompleted(
            totalTime: totalTime,
            quizGlobalScore: result.globalScore,
            selectedGoalsCount: 1, // Derived from quiz
            notificationsEnabled: notificationsEnabled,
            userId: Auth.auth().currentUser?.uid,
            firstName: userName,
            age: nil,
            gender: nil
        )

        // Set user profile if authenticated
        if let userId = Auth.auth().currentUser?.uid {
            MixpanelManager.shared.identify(userId: userId)

            // Set user profile with quiz data
            MixpanelManager.shared.setUserProfile(
                firstName: userName,
                email: Auth.auth().currentUser?.email,
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
