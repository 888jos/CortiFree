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
import UserNotifications

struct OnboardingV2FlowView: View {
    @Environment(\.scenePhase) private var scenePhase

    private let enablesLiveActivityWhenAlreadyCompleted: Bool

    @State private var currentStep: OnboardingStep = .welcome
    @AppStorage("onboardingV2Completed") private var isOnboardingComplete: Bool = false
    @AppStorage("onboardingCheckpoint") private var savedCheckpoint: String = ""
    @AppStorage("hasSeenPaywall") private var hasSeenPaywall: Bool = false
    @AppStorage("onboardingLanguage") private var onboardingLanguage: String = "en" // Track language used
    #if DEBUG
    @AppStorage("debugSkipOnboardingToHome") private var debugSkipOnboardingToHome: Bool = false
    #endif
    @State private var overallQuizData: OverallQuizData?
    @State private var habitsQuizResult: HabitsQuizResult?
    @State private var selectedSymptoms: Set<String> = []
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var onboardingStartTime: Date?
    @State private var suppressDropOffLiveActivity = false

    private let firebaseManager = FirebaseManager.shared

    init(enablesLiveActivityWhenAlreadyCompleted: Bool = false) {
        self.enablesLiveActivityWhenAlreadyCompleted = enablesLiveActivityWhenAlreadyCompleted
    }

    // MARK: - Onboarding Steps

    enum OnboardingStep: String, CaseIterable {
        case welcome
        case overall
        case reassurance
        case habitsQuiz
        case stressPatternValidation
        case symptomChecker
        case cortisolScienceHook
        case sixtyDayExplanation
        case scientificPlan
        case authentication
        case loading
        case cortiFreeRating
        case glowScan
        case eightHabitsIntro
        case weekProgress
        case eightHabits
        case habitsProgress
        case notificationPermissions
        case commitmentPledge
        case socialProof
        case complete

        // Define logical checkpoints where user can resume
        // These are steps that make sense to restart from
        var checkpoint: OnboardingStep {
            switch self {
            case .welcome, .overall:
                return .welcome
            case .reassurance, .habitsQuiz, .stressPatternValidation, .symptomChecker:
                return .reassurance
            case .cortisolScienceHook, .sixtyDayExplanation, .scientificPlan:
                return .sixtyDayExplanation
            case .authentication, .loading:
                return .authentication
            case .cortiFreeRating, .glowScan, .eightHabitsIntro, .weekProgress:
                return .cortiFreeRating
            case .eightHabits, .notificationPermissions, .habitsProgress, .commitmentPledge:
                return .eightHabits
            case .socialProof, .complete:
                return .complete
            }
        }
    }

    var body: some View {
        ZStack {
            currentStepView
                .id(currentStep)
                .transition(.opacity)

            if mascotMessage != nil {
                VStack {
                    OnboardingMascotDialogueView(message: mascotMessage ?? "")
                        .padding(.horizontal, 18)
                        .padding(.top, 8)
                    Spacer()
                }
                .allowsHitTesting(false)
                .zIndex(20)
            }
        }
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
            markOnboardingSessionActive()
        }
        .onChange(of: currentStep) { _, newStep in
            // Save checkpoint when step changes
            saveCheckpoint(newStep)
            persistLiveActivityProgress(newStep)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .inactive || newPhase == .background {
                startDropOffLiveActivity()
            }
        }
        .onDisappear {
            startDropOffLiveActivity()
            UserDefaults.standard.set(false, forKey: "onboarding_session_active")
        }
        #if DEBUG
        .overlay(alignment: .leading) {
            Button(action: skipOnboardingToHome) {
                Image(systemName: "house.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 54, height: 54)
                    .background(Color.red.opacity(0.94))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("DEBUG: Skip to Home")
            .padding(.leading, 12)
            .zIndex(1_000)
        }
        #endif
    }

    private var mascotMessage: String? {
        switch currentStep {
        case .overall, .habitsQuiz:
            return nil
        case .stressPatternValidation:
            return "onboarding.mascot.pattern".localized
        case .symptomChecker:
            return nil
        case .cortisolScienceHook, .sixtyDayExplanation, .scientificPlan:
            return "onboarding.mascot.plan".localized
        default:
            return nil
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

        #if DEBUG
        print("💾 Saved checkpoint: \(step.rawValue)")
        #endif
    }

    private func markOnboardingSessionActive() {
        UserDefaults.standard.set(true, forKey: "onboarding_session_active")
        persistLiveActivityProgress(currentStep)
    }

    private func persistLiveActivityProgress(_ step: OnboardingStep) {
        let stepIndex = (OnboardingStep.allCases.firstIndex(of: step) ?? 0) + 1
        UserDefaults.standard.set(stepIndex, forKey: "onboarding_live_activity_step")
        UserDefaults.standard.set(OnboardingStep.allCases.count, forKey: "onboarding_live_activity_total_steps")
    }

    private func startDropOffLiveActivity() {
        guard !suppressDropOffLiveActivity else { return }
        guard !isOnboardingComplete || enablesLiveActivityWhenAlreadyCompleted else { return }

        let revenueCat = RevenueCatManager.shared
        if hasSeenPaywall {
            guard revenueCat.isPremiumStatusReady else { return }
            guard !revenueCat.hasPremiumEntitlement else {
                OnboardingLiveActivityManager.shared.clearLiveGiftOffer()
                return
            }
        }

        let stepIndex = (OnboardingStep.allCases.firstIndex(of: currentStep) ?? 0) + 1
        OnboardingLiveActivityManager.shared.startForOnboardingDropOff(
            currentStep: stepIndex,
            totalSteps: OnboardingStep.allCases.count,
            hasSeenPaywall: hasSeenPaywall
        )
    }

    #if DEBUG
    private func skipOnboardingToHome() {
        suppressDropOffLiveActivity = true
        UserDefaults.standard.set(false, forKey: "onboarding_session_active")
        OnboardingLiveActivityManager.shared.end()
        debugSkipOnboardingToHome = true
    }
    #endif

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
                gender: overallQuizData?.genderCode,
                onStartQuiz: {
                    currentStep = .habitsQuiz
                }
            )

        case .habitsQuiz:
            HabitsQuizView(onComplete: { result in
                habitsQuizResult = result
                currentStep = .stressPatternValidation

                // Save in background without blocking UI
                OptimizedFirebaseService.shared.saveQuizDataInBackground(
                    result,
                    overallData: overallQuizData
                )
            })

        case .stressPatternValidation:
            if let result = habitsQuizResult {
                StressPatternValidationView(
                    habitsQuizResult: result,
                    onContinue: {
                        currentStep = .symptomChecker
                    }
                )
            } else {
                StressPatternValidationView(
                    habitsQuizResult: HabitsQuizResult(answers: Array(repeating: 0, count: 12)),
                    onContinue: {
                        currentStep = .symptomChecker
                    }
                )
            }

        case .symptomChecker:
            SymptomCheckerView(onContinue: { symptoms in
                selectedSymptoms = symptoms
                currentStep = .cortisolScienceHook
            })

        case .cortisolScienceHook:
            CortisolScienceHookView(onContinue: {
                currentStep = .sixtyDayExplanation
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
                },
                onSkip: {
                    UserDefaults.standard.set(false, forKey: "user_is_authenticated")
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
                    currentStep = .glowScan
                }
            )

        case .glowScan:
            GlowScanFlowView(
                context: GlowOnboardingContext(
                    primaryGoal: habitsQuizResult?.primaryGoal ?? "balance",
                    appearanceConcern: habitsQuizResult?.appearanceConcern ?? "",
                    symptoms: Array(selectedSymptoms),
                    reasons: overallQuizData?.reasons ?? []
                ),
                onComplete: {
                    currentStep = .eightHabitsIntro
                },
                onExit: {
                    currentStep = .cortiFreeRating
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
                print("✅ OnboardingV2FlowView: Checking notification permission")
                #endif
                continueAfterNotificationPermissionCheck()
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
                #if DEBUG
                print("✅ OnboardingV2FlowView: Transition .habitsProgress → .commitmentPledge")
                #endif
                // Generate personalized plan based on quiz results
                if let habitsResult = habitsQuizResult {
                    saveDataAndGeneratePlan(result: habitsResult)
                }
                currentStep = .commitmentPledge
            })

        case .commitmentPledge:
            CommitmentPledgeView(onContinue: {
                currentStep = .complete
            })

        case .socialProof, .complete:
            OnboardingCompletionView(
                habitsQuizResult: habitsQuizResult,
                selectedSymptoms: selectedSymptoms,
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

    private func continueAfterNotificationPermissionCheck() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            let permissionIsGranted: Bool
            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                permissionIsGranted = true
            case .denied, .notDetermined:
                permissionIsGranted = false
            @unknown default:
                permissionIsGranted = false
            }

            DispatchQueue.main.async {
                currentStep = permissionIsGranted ? .habitsProgress : .notificationPermissions
            }
        }
    }

    private func completeOnboarding() {
        // Clear checkpoint data since onboarding is complete
        savedCheckpoint = ""
        let isPremium = RevenueCatManager.shared.hasPremiumEntitlement
        if isPremium {
            hasSeenPaywall = false
        }

        // Clear re-engagement tracking
        UserDefaults.standard.set("completed", forKey: "last_onboarding_checkpoint")
        if isPremium {
            UserDefaults.standard.set(false, forKey: "saw_paywall_without_accepting")
        }
        UserDefaults.standard.set(false, forKey: "onboarding_session_active")

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
        if isPremium {
            OnboardingLiveActivityManager.shared.clearLiveGiftOffer()
        } else if hasSeenPaywall {
            OnboardingLiveActivityManager.shared.showLiveGiftOffer()
        }

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
            "genderCode": data.genderCode,
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
