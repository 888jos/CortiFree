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
                return .eightHabitsIntro
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
            trackOnboardingScreen(currentStep)
        }
        .onChange(of: currentStep) { _, newStep in
            // Save checkpoint when step changes
            saveCheckpoint(newStep)
            persistLiveActivityProgress(newStep)
            trackOnboardingScreen(newStep)
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

    private func trackOnboardingScreen(_ step: OnboardingStep) {
        let stepNumber = (OnboardingStep.allCases.firstIndex(of: step) ?? 0) + 1
        MixpanelManager.shared.trackOnboardingScreenViewed(
            screenName: step.rawValue,
            stepNumber: stepNumber,
            totalSteps: OnboardingStep.allCases.count
        )
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
        UserDefaults.standard.set(true, forKey: "onboardingV2Completed")
        OnboardingLiveActivityManager.shared.end()
        isOnboardingComplete = true
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
                overallData: overallQuizData,
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
            LoadingAnalysisView(
                habitsQuizResult: habitsQuizResult,
                selectedSymptoms: selectedSymptoms,
                onComplete: {
                    currentStep = .eightHabitsIntro
                }
            )

        case .cortiFreeRating:
            // Legacy checkpoint compatibility: skip the deprecated rating screen.
            EightHabitsIntroView(onContinue: {
                currentStep = .weekProgress
            })

        case .glowScan:
            GlowScanFlowView(
                context: GlowOnboardingContext(
                    primaryGoal: habitsQuizResult?.primaryGoal ?? "balance",
                    appearanceConcern: habitsQuizResult?.appearanceConcern ?? "",
                    symptoms: Array(selectedSymptoms),
                    reasons: overallQuizData?.reasons ?? [],
                    domainScore: habitsQuizResult?.cortiFreeScore
                ),
                onComplete: {
                    currentStep = .stressPatternValidation
                },
                onExit: {
                    currentStep = .stressPatternValidation
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
            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                DispatchQueue.main.async {
                    currentStep = .habitsProgress
                }
            case .notDetermined:
                DispatchQueue.main.async {
                    currentStep = .notificationPermissions
                }
            case .denied:
                // A previous denial is handled later in the main app, not by
                // repeatedly interrupting the onboarding flow.
                UserDefaults.standard.set(false, forKey: "notificationsEnabled")
                DispatchQueue.main.async {
                    currentStep = .habitsProgress
                }
            @unknown default:
                DispatchQueue.main.async {
                    currentStep = .habitsProgress
                }
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

// MARK: - Breathing introduction

/// A short, skippable first exercise that lets users experience the core loop
/// before answering the onboarding questions.
struct OnboardingBreathingIntroView: View {
    let onContinue: () -> Void
    let onBack: () -> Void

    @StateObject private var planetSettings = PlanetSettings.shared
    @State private var isStarted = false
    @State private var hasSeenIntro = false
    @State private var isComplete = false
    @State private var elapsedSeconds = 0
    @State private var circleScale: CGFloat = 0.82
    @State private var breathGeneration = 0
    @State private var hasExited = false

    private let duration = 30
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            GalaxyBackgroundView(intensity: 0.9)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header

                if hasSeenIntro {
                    exerciseContent
                } else {
                    introductionContent
                }

                VStack(spacing: 12) {
                    if !isStarted || isComplete {
                        Button(action: primaryAction) {
                            Text(primaryTitle)
                                .font(.poppinsSemiBold(17))
                                .foregroundStyle(Color(hex: "1A1A4E"))
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 24)
                    }

                    if !isComplete {
                        Button("Skip") {
                            HapticManager.light()
                            exitToNextStep()
                        }
                        .font(.poppinsMedium(14))
                        .foregroundStyle(.white.opacity(0.62))
                        .buttonStyle(.plain)
                    }
                }
                .padding(.bottom, 34)
            }
        }
        .onReceive(timer) { _ in
            guard isStarted, !isComplete else { return }
            elapsedSeconds += 1
            if elapsedSeconds >= duration {
                isComplete = true
                circleScale = 1.0
                HapticManager.medium()
            }
        }
        .onChange(of: isStarted) { _, started in
            guard started else { return }
            startBreathingCycle()
        }
    }

    private var introductionContent: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 30)

            LottieView(filename: "sloth_intro.json", loopMode: .loop)
                .frame(width: 132, height: 132)
                .accessibilityHidden(true)

            Text("Take a calmer moment")
                .font(.faroBold(29))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.top, 18)

            Text("Take a slow breath with me. We’ll begin with one simple step.")
                .font(.poppinsRegular(16))
                .foregroundStyle(.white.opacity(0.72))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 30)
                .padding(.top, 10)

            Spacer()
        }
    }

    private var exerciseContent: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 20)

            VStack(spacing: 8) {
                Text(isComplete ? "Nice work" : "Take a breath")
                    .font(.faroBold(30))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text(isComplete ? "You just created a calm moment." : "Follow the circle: breathe in for 4 seconds, then out for 6.")
                    .font(.poppinsRegular(16))
                    .foregroundStyle(.white.opacity(0.72))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
            }

            Spacer(minLength: 18)

            ZStack {
                BreathingCircle(
                    planet: planetSettings.selectedPlanet,
                    size: 270,
                    haloOpacity: isStarted ? 0.5 : 0.3
                )
                .scaleEffect(circleScale)

                VStack(spacing: 5) {
                    Text(isStarted ? phaseTitle : "Ready?")
                        .font(.faroBold(25))
                        .foregroundStyle(.white)

                    Text(isStarted ? timeText : "4 in / 6 out")
                        .font(.poppinsMedium(16))
                        .foregroundStyle(.white.opacity(0.78))
                        .monospacedDigit()
                }
            }
            // The breathing animation is contained inside a fixed frame, so
            // the header and CTA never move when the circle expands.
            .frame(width: 300, height: 300)

            Spacer()
        }
    }

    private var header: some View {
        HStack {
            Button {
                HapticManager.light()
                onBack()
            } label: {
                Image(systemName: "arrow.left")
                    .font(.system(size: 21, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back")

            Spacer()

            if !isStarted {
                Button("Skip") {
                    HapticManager.light()
                    exitToNextStep()
                }
                .font(.poppinsMedium(14))
                .foregroundStyle(.white.opacity(0.72))
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 14)
    }

    private var primaryTitle: String {
        if isComplete { return "Continue" }
        return "Begin breathing (30s)"
    }

    private func exitToNextStep() {
        guard !hasExited else { return }
        hasExited = true
        onContinue()
    }

    private var phaseTitle: String {
        elapsedSeconds % 10 < 4 ? "Inhale" : "Exhale"
    }

    private var timeText: String {
        String(format: "00:%02d", max(duration - elapsedSeconds, 0))
    }

    private func primaryAction() {
        HapticManager.light()
        if isComplete {
            onContinue()
        } else if !hasSeenIntro {
            withAnimation(.easeInOut(duration: 0.3)) {
                hasSeenIntro = true
            }
        } else if !isStarted {
            isStarted = true
        }
    }

    private func startBreathingCycle() {
        breathGeneration += 1
        animateInhale(generation: breathGeneration)
    }

    private func animateInhale(generation: Int) {
        guard isStarted, !isComplete, generation == breathGeneration else { return }
        withAnimation(.easeInOut(duration: 4)) {
            circleScale = 1.0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            animateExhale(generation: generation)
        }
    }

    private func animateExhale(generation: Int) {
        guard isStarted, !isComplete, generation == breathGeneration else { return }
        withAnimation(.easeInOut(duration: 6)) {
            circleScale = 0.82
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
            animateInhale(generation: generation)
        }
    }
}
