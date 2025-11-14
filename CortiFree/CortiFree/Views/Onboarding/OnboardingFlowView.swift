//
//  OnboardingFlowView.swift
//  CortiFree
//
//  Created by Claude on 31/10/2025.
//  Container managing the complete onboarding flow
//

import SwiftUI

struct OnboardingFlowView: View {
    @StateObject private var quizState = QuizState()
    @State private var currentScreen: OnboardingScreen = .welcome
    @State private var cortisolDifference: Int = 38 // Will be calculated from quiz answers

    enum OnboardingScreen {
        case welcome
        case quiz
        case authentication
        case loading
        case diagnostic
        case riseRating
        case symptoms
        case consequences
        case recoveryBenefits
        case sixtyDaysExplanation
        case scientificPlan
        case weekProgress
        case eightHabits
        case habitsProgress
        case socialProof
        case paywall
    }

    var body: some View {
        ZStack {
            switch currentScreen {
            case .welcome:
                WelcomeView(onContinue: {
                    currentScreen = .quiz
                })

            case .quiz:
                OnboardingQuizView(
                    quizState: quizState,
                    onComplete: {
                        // After quiz completion, go to authentication
                        currentScreen = .authentication
                    }
                )
            case .authentication:
                AuthenticationView(
                    firstName: quizState.userFirstName.isEmpty ? "Utilisateur" : quizState.userFirstName,
                    onComplete: {
                        // Calculate cortisol difference from answers
                        cortisolDifference = calculateCortisolDifference()
                        currentScreen = .loading
                    }
                )

            case .loading:
                LoadingAnalysisView(onComplete: {
                    currentScreen = .diagnostic
                })

            case .diagnostic:
                DiagnosticResultView(
                    cortisolDifference: cortisolDifference,
                    onContinue: {
                        currentScreen = .riseRating
                    }
                )

            case .riseRating:
                CortiFreeRatingView(
                    habitsQuizResult: HabitsQuizResult(answers: Array(repeating: 0, count: 15)),
                    onContinue: {
                        currentScreen = .symptoms
                    }
                )

            case .symptoms:
                SymptomsSelectionView(onContinue: { selectedSymptoms in
                    // Save symptoms and continue to consequences flow
                    UserDefaults.standard.set(Array(selectedSymptoms), forKey: "selectedSymptoms")
                    currentScreen = .consequences
                })

            case .consequences:
                ConsequencesFlowView(onComplete: {
                    currentScreen = .recoveryBenefits
                })

            case .recoveryBenefits:
                RecoveryBenefitsFlowView(onComplete: {
                    currentScreen = .sixtyDaysExplanation
                })

            case .sixtyDaysExplanation:
                SixtyDaysExplanationView(onContinue: {
                    currentScreen = .scientificPlan
                })

            case .scientificPlan:
                ScientificPlanView(onContinue: {
                    currentScreen = .weekProgress
                })

            case .weekProgress:
                WeekProgressView(onContinue: {
                    currentScreen = .eightHabits
                })

            case .eightHabits:
                EightHabitsFlowView(onComplete: {
                    currentScreen = .habitsProgress
                })

            case .habitsProgress:
                HabitsProgressFlowView(onComplete: {
                    currentScreen = .socialProof
                })

            case .socialProof:
                SocialProofFlowView(onComplete: {
                    currentScreen = .paywall
                })

            case .paywall:
                // TODO: Integrate Superwall paywall
                Text("Paywall - À intégrer avec Superwall")
                    .font(.custom("Poppins-Bold", size: 24))
                    .foregroundColor(.white)
            }
        }
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
        .animation(.easeInOut(duration: 0.3), value: currentScreen)
    }

    // MARK: - Calculate Cortisol Difference

    private func calculateCortisolDifference() -> Int {
        // Simple calculation based on answers (higher score = higher cortisol)
        // Each question scored 0-3 (4 answers)
        let totalScore = quizState.answers.values.reduce(0, +)
        let maxScore = quizState.questions.count * 3 // 20 questions × 3 max points

        // Convert to percentage difference (0-60% range)
        let percentage = Double(totalScore) / Double(maxScore)
        return Int(percentage * 60) + 10 // Range: 10% to 70%
    }
}

#Preview {
    OnboardingFlowView()
}
