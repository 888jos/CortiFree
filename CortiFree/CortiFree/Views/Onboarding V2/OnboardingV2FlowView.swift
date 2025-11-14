//
//  OnboardingV2FlowView.swift
//  CortiFree
//
//  Created by Claude on 11/11/2025.
//  Complete onboarding flow orchestration for V2
//

import SwiftUI

struct OnboardingV2FlowView: View {
    @State private var currentStep: OnboardingStep = .overall
    @State private var isOnboardingComplete: Bool = false
    @State private var overallQuizData: OverallQuizData?
    @State private var habitsQuizResult: HabitsQuizResult?

    enum OnboardingStep {
        case overall
        case reassurance
        case habitsQuiz
        case sixtyDayExplanation
        case scientificPlan
        case loading
        case socialProof
        case cortiFreeRating
        case eightHabitsIntro
        case weekProgress
        case eightHabits
        case notificationPermissions
        case complete
    }

    var body: some View {
        ZStack {
            currentStepView
        }
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.3), value: currentStep)
    }

    @ViewBuilder
    private var currentStepView: some View {
        switch currentStep {
        case .overall:
            OverallQuizView(onComplete: { data in
                overallQuizData = data
                currentStep = .reassurance
            })

        case .reassurance:
            ReassuranceView(
                userName: overallQuizData?.firstName ?? "Utilisateur",
                onStartQuiz: {
                    currentStep = .habitsQuiz
                }
            )

        case .habitsQuiz:
            HabitsQuizView(onComplete: { result in
                habitsQuizResult = result
                currentStep = .sixtyDayExplanation
            })

        case .sixtyDayExplanation:
            SixtyDaysExplanationView(onContinue: {
                currentStep = .scientificPlan
            })

        case .scientificPlan:
            ScientificPlanView(onContinue: {
                currentStep = .loading
            })

        case .loading:
            LoadingAnalysisView(onComplete: {
                currentStep = .socialProof
            })

        case .socialProof:
            SocialProofFlowView(onComplete: {
                currentStep = .cortiFreeRating
            })

        case .cortiFreeRating:
            CortiFreeRatingView(
                habitsQuizResult: habitsQuizResult ?? HabitsQuizResult(answers: Array(repeating: 0, count: 15)),
                onContinue: {
                    currentStep = .eightHabitsIntro
                }
            )

        case .eightHabitsIntro:
            EightHabitsIntroView(onContinue: {
                currentStep = .weekProgress
            })

        case .weekProgress:
            WeekProgressView(onContinue: {
                currentStep = .eightHabits
            })

        case .eightHabits:
            EightHabitsFlowView(onComplete: {
                currentStep = .notificationPermissions
            })

        case .notificationPermissions:
            NotificationPermissionsView(onContinue: {
                currentStep = .complete
                completeOnboarding()
            })

        case .complete:
            // Placeholder for completion - could navigate to main app
            Text("Onboarding Complete!")
                .font(.custom("Poppins-Bold", size: 24))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(hex: "1a0a2e"))
        }
    }

    private func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "onboardingV2Completed")
        isOnboardingComplete = true
    }
}

#Preview {
    OnboardingV2FlowView()
}
