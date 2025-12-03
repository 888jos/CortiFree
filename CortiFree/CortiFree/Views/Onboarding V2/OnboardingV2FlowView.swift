//
//  OnboardingV2FlowView.swift
//  CortiFree
//
//  Created by Claude on 11/11/2025.
//  Complete onboarding flow orchestration for V2
//  Enhanced with Firebase integration for data persistence
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct OnboardingV2FlowView: View {
    @State private var currentStep: OnboardingStep = .welcome
    @AppStorage("onboardingV2Completed") private var isOnboardingComplete: Bool = false
    @State private var overallQuizData: OverallQuizData?
    @State private var habitsQuizResult: HabitsQuizResult?
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var onboardingStartTime: Date?

    private let firebaseManager = FirebaseManager.shared

    enum OnboardingStep {
        case welcome
        case overall
        case reassurance
        case habitsQuiz
        case sixtyDayExplanation
        case scientificPlan
        case authentication
        case loading
        case cortiFreeRating
        case eightHabitsIntro
        case weekProgress
        case eightHabits
        case habitsProgress
        case notificationPermissions
        case socialProof
        case complete
    }

    var body: some View {
        ZStack {
            currentStepView
        }
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.3), value: currentStep)
        .onAppear {
            // Track onboarding start time
            if onboardingStartTime == nil {
                onboardingStartTime = Date()
            }
        }
    }

    @ViewBuilder
    private var currentStepView: some View {
        switch currentStep {
        case .welcome:
            FirstLaunchWelcomeView {
                currentStep = .overall
            }

        case .overall:
            OverallQuizView(onComplete: { data in
                overallQuizData = data
                currentStep = .reassurance
            })

        case .reassurance:
            ReassuranceView(
                userName: overallQuizData?.firstName ?? "common.user_fallback".localized,
                onStartQuiz: {
                    currentStep = .habitsQuiz
                }
            )

        case .habitsQuiz:
            HabitsQuizView(onComplete: { result in
                habitsQuizResult = result
                currentStep = .sixtyDayExplanation

                // Save in background without blocking UI
                OptimizedFirebaseService.shared.saveQuizDataInBackground(
                    result,
                    overallData: overallQuizData
                )
            })

        case .sixtyDayExplanation:
            SixtyDaysExplanationView(onContinue: {
                currentStep = .scientificPlan
            })

        case .scientificPlan:
            ScientificPlanView(onContinue: {
                currentStep = .authentication
            })

        case .authentication:
            AuthenticationView(
                firstName: overallQuizData?.firstName ?? "common.user_fallback".localized,
                onComplete: {
                    currentStep = .loading
                }
            )

        case .loading:
            LoadingAnalysisView(onComplete: {
                currentStep = .cortiFreeRating
            })

        case .cortiFreeRating:
            CortiFreeRatingView(
                habitsQuizResult: habitsQuizResult ?? HabitsQuizResult(answers: Array(repeating: 0, count: 12)),
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
                #if DEBUG
                print("✅ OnboardingV2FlowView: Transition .eightHabits → .notificationPermissions")
                #endif
                currentStep = .notificationPermissions
            })

        case .notificationPermissions:
            NotificationPermissionsView(onContinue: {
                #if DEBUG
                print("✅ OnboardingV2FlowView: Transition .notificationPermissions → .habitsProgress")
                #endif
                currentStep = .habitsProgress
            })

        case .habitsProgress:
            HabitsProgressFlowView(onComplete: {
                currentStep = .socialProof
            })

        case .socialProof:
            SocialProofFlowView(onComplete: {
                #if DEBUG
                print("✅ OnboardingV2FlowView: Transition .socialProof → .complete")
                #endif
                // Generate personalized plan based on quiz results
                if let habitsResult = habitsQuizResult {
                    saveDataAndGeneratePlan(result: habitsResult)
                }
                currentStep = .complete
            })

        case .complete:
            OnboardingCompletionView(
                habitsQuizResult: habitsQuizResult,
                onboardingStartTime: onboardingStartTime,
                onViewPlan: {
                    completeOnboarding()
                }
            )
        }
    }

    private func completeOnboarding() {
        // Using @AppStorage, this will automatically trigger view update
        isOnboardingComplete = true
    }

    // MARK: - Firebase Integration

    private func saveDataAndGeneratePlan(result: HabitsQuizResult) {
        Task {
            // Save quiz responses to Firebase
            // Le plan est le même pour tous les utilisateurs (SimplifiedRoutineProgram)
            if let overallData = overallQuizData {
                await saveOverallDataToFirebase(overallData)
            }
            #if DEBUG
            print("✅ User data saved - using universal program for all users")
            #endif
        }
    }

    private func saveOverallDataToFirebase(_ data: OverallQuizData) async {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        // Save user profile
        let userData: [String: Any] = [
            "firstName": data.firstName,
            "age": data.age,
            "gender": data.gender,
            "stressReasons": data.reasons,
            "stressDuration": data.duration,
            "onboardingCompletedAt": Date()
        ]

        // Save directly to Firestore
        do {
            try await Firestore.firestore()
                .collection("users")
                .document(userId)
                .setData(userData, merge: true)
            #if DEBUG
            print("✅ User profile updated")
            #endif
        } catch {
            #if DEBUG
            print("❌ Error updating user profile: \(error)")
            #endif
        }
    }
}

#Preview {
    OnboardingV2FlowView()
}
