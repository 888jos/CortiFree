//
//  OnboardingV2FlowView.swift
//  CortiFree
//
//  Created by Claude on 11/11/2025.
//  Complete onboarding flow orchestration for V2
//  Enhanced with Firebase integration for data persistence
//  Includes checkpoint system for resuming onboarding
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct OnboardingV2FlowView: View {
    @State private var currentStep: OnboardingStep = .welcome
    @AppStorage("onboardingV2Completed") private var isOnboardingComplete: Bool = false
    @AppStorage("onboardingCheckpoint") private var savedCheckpoint: String = ""
    @AppStorage("hasSeenPaywall") private var hasSeenPaywall: Bool = false
    @AppStorage("onboardingLanguage") private var onboardingLanguage: String = "en" // Track language used
    @State private var overallQuizData: OverallQuizData?
    @State private var habitsQuizResult: HabitsQuizResult?
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var onboardingStartTime: Date?

    private let firebaseManager = FirebaseManager.shared

    // MARK: - Onboarding Steps

    enum OnboardingStep: String, CaseIterable {
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

        // Define logical checkpoints where user can resume
        // These are steps that make sense to restart from
        var checkpoint: OnboardingStep {
            switch self {
            case .welcome, .overall:
                return .welcome
            case .reassurance, .habitsQuiz:
                return .reassurance
            case .sixtyDayExplanation, .scientificPlan:
                return .sixtyDayExplanation
            case .authentication, .loading:
                return .authentication
            case .cortiFreeRating, .eightHabitsIntro, .weekProgress:
                return .cortiFreeRating
            case .eightHabits, .notificationPermissions, .habitsProgress:
                return .eightHabits
            case .socialProof, .complete:
                return .socialProof
            }
        }
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

            // Detect and save language on first load
            if onboardingLanguage.isEmpty || onboardingLanguage == "en" {
                let systemLanguage = Locale.current.language.languageCode?.identifier ?? "en"
                onboardingLanguage = systemLanguage.hasPrefix("fr") ? "fr" : "en"
                print("🌍 Detected onboarding language: \(onboardingLanguage)")
            }

            // Resume from checkpoint or paywall if applicable
            resumeFromCheckpoint()
        }
        .onChange(of: currentStep) { _, newStep in
            // Save checkpoint when step changes
            saveCheckpoint(newStep)
        }
    }

    // MARK: - Checkpoint Management

    private func resumeFromCheckpoint() {
        // If user has seen paywall but not completed onboarding, go directly to paywall
        if hasSeenPaywall && !isOnboardingComplete {
            #if DEBUG
            print("📍 Resuming: User has seen paywall - going to complete (paywall)")
            #endif
            currentStep = .complete
            return
        }

        // If we have a saved checkpoint, resume from there
        if !savedCheckpoint.isEmpty,
           let step = OnboardingStep(rawValue: savedCheckpoint) {
            #if DEBUG
            print("📍 Resuming from checkpoint: \(step.rawValue)")
            #endif
            currentStep = step.checkpoint
        }
    }

    private func saveCheckpoint(_ step: OnboardingStep) {
        savedCheckpoint = step.rawValue

        // Save checkpoint for re-engagement notifications
        UserDefaults.standard.set(step.rawValue, forKey: "last_onboarding_checkpoint")

        // Mark paywall as seen when reaching complete step
        if step == .complete {
            hasSeenPaywall = true
            UserDefaults.standard.set(true, forKey: "saw_paywall_without_accepting")
        }

        #if DEBUG
        print("💾 Saved checkpoint: \(step.rawValue)")
        #endif
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
                onStartQuiz: {
                    // Request App Store rating after reassurance
                    AppRatingService.shared.requestRating()
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
                onComplete: {
                    // Mark user as authenticated for re-engagement tracking
                    UserDefaults.standard.set(true, forKey: "user_is_authenticated")
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
                language: onboardingLanguage, // Pass detected language
                onViewPlan: {
                    // After paywall acceptance (trial started), complete onboarding
                    completeOnboarding()

                    // Schedule trial notifications
                    NotificationService.shared.scheduleTrialNotifications()
                }
            )
        }
    }

    private func completeOnboarding() {
        // Clear checkpoint data since onboarding is complete
        savedCheckpoint = ""
        hasSeenPaywall = false // Reset for potential future use

        // Clear re-engagement tracking
        UserDefaults.standard.set("completed", forKey: "last_onboarding_checkpoint")
        UserDefaults.standard.set(false, forKey: "saw_paywall_without_accepting")

        // Cancel all re-engagement notifications
        NotificationService.shared.cancelReengagementNotifications()

        // Set routine start date for program progress tracking
        UserDefaults.standard.set(Date(), forKey: "routineStartDate")

        // Update Firestore onboardingCompleted field
        if let userId = Auth.auth().currentUser?.uid {
            Task {
                do {
                    try await Firestore.firestore()
                        .collection("users")
                        .document(userId)
                        .setData(["onboardingCompleted": true], merge: true)
                    #if DEBUG
                    print("✅ Firestore onboardingCompleted set to true")
                    #endif
                } catch {
                    #if DEBUG
                    print("⚠️ Failed to update Firestore onboardingCompleted: \(error.localizedDescription)")
                    #endif
                }
            }
        }

        // Using @AppStorage, this will automatically trigger view update
        isOnboardingComplete = true

        #if DEBUG
        print("✅ Onboarding completed - checkpoints cleared, routineStartDate set")
        #endif
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
