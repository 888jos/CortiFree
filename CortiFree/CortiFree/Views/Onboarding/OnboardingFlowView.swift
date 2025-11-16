//
//  OnboardingFlowView.swift
//  CortiFree
//
//  Created by Claude on 31/10/2025.
//  Container managing the complete onboarding flow
//

import SwiftUI

struct OnboardingFlowView: View {
    @State private var currentScreen: OnboardingScreen = .overallQuiz
    @State private var overallQuizData: OverallQuizData?
    @State private var habitsQuizResult: HabitsQuizResult?

    enum OnboardingScreen {
        case overallQuiz
        case reassurance
        case habitsQuiz
        case sixtyDaysExplanation
        case scientificPlan
        case authentication
        case loading
        case riseRating
        case eightHabitsIntro
        case weekProgress
        case eightHabitsFlow
        case habitsProgress
        case socialProof
        case paywall
    }

    var body: some View {
        ZStack {
            switch currentScreen {
            case .overallQuiz:
                OverallQuizView(onComplete: { quizData in
                    overallQuizData = quizData
                    currentScreen = .reassurance
                })

            case .reassurance:
                ReassuranceView(
                    userName: overallQuizData?.firstName ?? "Utilisateur",
                    onStartQuiz: {
                        currentScreen = .habitsQuiz
                    }
                )

            case .habitsQuiz:
                HabitsQuizView(onComplete: { result in
                    habitsQuizResult = result
                    currentScreen = .sixtyDaysExplanation
                })

            case .sixtyDaysExplanation:
                SixtyDaysExplanationView(onContinue: {
                    currentScreen = .scientificPlan
                })

            case .scientificPlan:
                ScientificPlanView(onContinue: {
                    currentScreen = .authentication
                })

            case .authentication:
                AuthenticationView(
                    firstName: overallQuizData?.firstName ?? "Utilisateur",
                    onComplete: {
                        currentScreen = .loading
                    }
                )

            case .loading:
                LoadingAnalysisView(onComplete: {
                    currentScreen = .riseRating
                })

            case .riseRating:
                CortiFreeRatingView(
                    habitsQuizResult: habitsQuizResult ?? HabitsQuizResult(answers: Array(repeating: 0, count: 15)),
                    onContinue: {
                        currentScreen = .eightHabitsIntro
                    }
                )

            case .eightHabitsIntro:
                EightHabitsIntroView(onContinue: {
                    currentScreen = .weekProgress
                })

            case .weekProgress:
                WeekProgressView(onContinue: {
                    currentScreen = .eightHabitsFlow
                })

            case .eightHabitsFlow:
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
                    .font(.custom(AppConstants.Fonts.bold, size: AppConstants.FontSize.title2))
                    .foregroundColor(.white)
            }
        }
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
        .animation(.easeInOut(duration: AppConstants.Animation.standardDuration), value: currentScreen)
    }
}

#Preview {
    OnboardingFlowView()
}
