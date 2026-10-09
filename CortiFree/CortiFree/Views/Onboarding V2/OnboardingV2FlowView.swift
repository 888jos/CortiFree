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
import UserNotifications

#if DEBUG
@MainActor
enum OnboardingDebugNavigation {
    static func goHome() {
        let defaults = UserDefaults.standard
        defaults.set(false, forKey: "onboarding_session_active")
        defaults.set(true, forKey: "debugSkipOnboardingToHome")
        OnboardingLiveActivityManager.shared.end()
    }
}

struct OnboardingDebugHomeButton: View {
    let beforeNavigation: () -> Void

    init(beforeNavigation: @escaping () -> Void = {}) {
        self.beforeNavigation = beforeNavigation
    }

    var body: some View {
        Button {
            HapticManager.medium()
            beforeNavigation()
            OnboardingDebugNavigation.goHome()
        } label: {
            Image(systemName: "house.fill")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 46, height: 46)
                .background(Color.red.opacity(0.94))
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.28), radius: 8, y: 3)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("DEBUG: Skip to Home")
    }
}

extension View {
    func onboardingDebugHomeButton() -> some View {
        overlay(alignment: .topTrailing) {
            VStack(spacing: 10) {
                OnboardingDebugHomeButton()
                RecoveryDebugButton()
            }
                .padding(.top, 54)
                .padding(.trailing, 12)
                .zIndex(10_000)
        }
    }
}
#endif

struct OnboardingV2FlowView: View {
    @Environment(\.scenePhase) private var scenePhase

    private let enablesLiveActivityWhenAlreadyCompleted: Bool

    @State private var currentStep: OnboardingStep = .welcome
    @AppStorage("onboardingV2Completed") private var isOnboardingComplete: Bool = false
    @AppStorage("onboardingCheckpoint") private var savedCheckpoint: String = ""
    @AppStorage("hasSeenPaywall") private var hasSeenPaywall: Bool = false
    @AppStorage("onboardingLanguage") private var onboardingLanguage: String = "en" // Track language used
    @State private var overallQuizData: OverallQuizData?
    @State private var habitsQuizResult: HabitsQuizResult?
    @State private var selectedSymptoms: Set<String> = []
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var onboardingStartTime: Date?
    @State private var suppressDropOffLiveActivity = false
    @State private var showReturningUserSignIn = false

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
        case eightHabitsIntro
        case weekProgress
        case eightHabits
        case habitsProgress
        case notificationPermissions
        case commitmentPledge
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
                return .cortisolScienceHook
            case .authentication, .loading:
                return .authentication
            case .notificationPermissions, .eightHabitsIntro, .weekProgress:
                return .eightHabitsIntro
            case .eightHabits, .habitsProgress, .commitmentPledge:
                return .eightHabits
            case .complete:
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
                onboardingLanguage = LanguageManager.shared.currentLanguage.rawValue
                print("🌍 Detected onboarding language: \(onboardingLanguage)")
            }

            // Resume from checkpoint or paywall if applicable
            resumeFromCheckpoint()
            markOnboardingSessionActive()
            // Quiet notifications from the first screen, so early drop-offs can be reached.
            RecoveryScheduler.shared.requestProvisionalAuthorizationIfNeeded()
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
        .overlay(alignment: .topTrailing) {
            VStack(spacing: 10) {
                OnboardingDebugHomeButton {
                    suppressDropOffLiveActivity = true
                }
                RecoveryDebugButton()
            }
            .padding(.top, 54)
            .padding(.trailing, 12)
            .zIndex(10_000)
        }
        #endif
    }

    // MARK: - Checkpoint Management

    private func resumeFromCheckpoint() {
        #if DEBUG
        if UserDefaults.standard.bool(forKey: "debugStartOnboardingFromAuth") {
            UserDefaults.standard.removeObject(forKey: "debugStartOnboardingFromAuth")
            prepareDebugAuthFlow()
            currentStep = .authentication
            return
        }
        #endif

        restoreAnswersFromDraft()

        // If user has seen paywall but not completed onboarding, go directly to paywall
        if hasSeenPaywall && !isOnboardingComplete {
            #if DEBUG
            print("📍 Resuming: User has seen paywall - going to complete (paywall)")
            #endif
            currentStep = .complete
            return
        }

        // Legacy checkpoints from removed screens (Glow Scan / score, social proof)
        if savedCheckpoint == "glowScan" || savedCheckpoint == "glowScore" {
            savedCheckpoint = OnboardingStep.authentication.rawValue
        } else if savedCheckpoint == "socialProof" {
            savedCheckpoint = OnboardingStep.complete.rawValue
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

    /// The answers only live in memory during the flow; when it resumes from a checkpoint
    /// (app killed, re-engagement notification, Live Activity), rebuild them from the
    /// onboarding draft saved by each quiz step so the plan, the analysis and the paywall
    /// stay personalized.
    private func restoreAnswersFromDraft() {
        guard !savedCheckpoint.isEmpty || hasSeenPaywall,
              let draft = PersonalPlanStore.shared.storedOnboardingProfile() else { return }

        if overallQuizData == nil, !draft.reasonCodes.isEmpty || draft.durationCode != nil {
            overallQuizData = OverallQuizData(restoringFrom: draft)
        }
        if habitsQuizResult == nil, let answers = draft.quizAnswers, answers.count == 12 {
            habitsQuizResult = HabitsQuizResult(answers: answers)
        }
        if selectedSymptoms.isEmpty, !draft.symptomIDs.isEmpty {
            selectedSymptoms = Set(draft.symptomIDs.map { "symptom_checker.\($0)".localized })
        }
    }

    #if DEBUG
    /// Recreates the state that normally exists after the quiz so the Home
    /// debug shortcut exercises the current auth -> analysis flow.
    private func prepareDebugAuthFlow() {
        let quizResult = HabitsQuizResult(
            answers: [1, 1, 2, 1, 2, 1, 2, 1, 1, 0, 1, 1]
        )
        let symptoms = ["Difficulty focusing", "Restless sleep"]

        habitsQuizResult = quizResult
        selectedSymptoms = Set(symptoms)
    }
    #endif

    private func saveCheckpoint(_ step: OnboardingStep) {
        savedCheckpoint = step.rawValue

        // Save checkpoint for re-engagement notifications
        UserDefaults.standard.set(step.rawValue, forKey: "last_onboarding_checkpoint")
        RecoveryScheduler.shared.syncToServer()

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
        AnalyticsManager.shared.trackOnboardingScreenViewed(
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
    #endif

    @ViewBuilder
    private var currentStepView: some View {
        switch currentStep {
        case .welcome:
            FirstLaunchWelcomeView(
                onContinue: { currentStep = .overall },
                onSignIn: { showReturningUserSignIn = true }
            )
            .fullScreenCover(isPresented: $showReturningUserSignIn) {
                // Returning user: a finished onboarding on the account sets onboardingV2Completed
                // and the app root switches to the app. Otherwise the quiz starts as usual.
                EmailAuthView(startsWithSignIn: true) {
                    showReturningUserSignIn = false
                    UserDefaults.standard.set(true, forKey: "user_is_authenticated")
                    if !isOnboardingComplete {
                        currentStep = .overall
                    }
                }
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
            SymptomCheckerView(
                initialSelection: selectedSymptoms,
                onBack: { currentStep = .stressPatternValidation },
                onContinue: { symptoms in
                    selectedSymptoms = symptoms
                    currentStep = .cortisolScienceHook
                }
            )

        case .cortisolScienceHook:
            CortisolScienceHookView(
                onBack: { currentStep = .symptomChecker },
                onContinue: { currentStep = .scientificPlan }
            )

        case .sixtyDayExplanation:
            // The "66 days" screen is gone (plans run in 28-day cycles); a progress saved
            // on this step resumes on the next one.
            Color.clear.onAppear { currentStep = .scientificPlan }

        case .scientificPlan:
            ScientificPlanView(
                onBack: { currentStep = .cortisolScienceHook },
                onContinue: { currentStep = .authentication }
            )

        case .authentication:
            AuthenticationView(
                onBack: { currentStep = .scientificPlan },
                onComplete: {
                    // Mark user as authenticated for re-engagement tracking
                    UserDefaults.standard.set(true, forKey: "user_is_authenticated")
                    currentStep = .loading
                }
            )

        case .loading:
            LoadingAnalysisView(
                habitsQuizResult: habitsQuizResult,
                selectedSymptoms: selectedSymptoms,
                onComplete: {
                    // The plan is ready: best moment to ask for notifications.
                    continueAfterNotificationPermissionCheck()
                }
            )

        case .eightHabitsIntro:
            EightHabitsIntroView(onContinue: {
                currentStep = .weekProgress
            })

        case .weekProgress:
            WeekProgressView(
                habitsQuizResult: habitsQuizResult,
                onBack: { currentStep = .eightHabitsIntro },
                onContinue: { currentStep = .eightHabits }
            )

        case .eightHabits:
            EightHabitsFlowView(onBack: { currentStep = .weekProgress }, onComplete: {
                currentStep = .habitsProgress
            })

        case .notificationPermissions:
            NotificationPermissionsView(onContinue: {
                currentStep = .eightHabitsIntro
            })

        case .habitsProgress:
            HabitsProgressFlowView(
                availableMinutes: habitsQuizResult?.availableTime,
                onBack: { currentStep = .eightHabits },
                onComplete: {
                    #if DEBUG
                    print("✅ OnboardingV2FlowView: Transition .habitsProgress → .commitmentPledge")
                    #endif
                    // Generate personalized plan based on quiz results
                    if let habitsResult = habitsQuizResult {
                        saveDataAndGeneratePlan(result: habitsResult)
                    } else if let draft = PersonalPlanStore.shared.storedOnboardingProfile(), !draft.isEmpty {
                        // Answers not in memory (should not happen after restoreAnswersFromDraft):
                        // still build the plan from what each quiz step saved.
                        PersonalPlanStore.shared.createPlanFromOnboarding(draft)
                    }
                    currentStep = .commitmentPledge
                }
            )

        case .commitmentPledge:
            CommitmentPledgeView(
                onBack: { currentStep = .habitsProgress },
                onContinue: { currentStep = .complete }
            )

        case .complete:
            OnboardingCompletionView(
                habitsQuizResult: habitsQuizResult,
                selectedSymptoms: selectedSymptoms,
                onboardingStartTime: onboardingStartTime,
                language: onboardingLanguage, // Pass detected language
                onViewPlan: {
                    // After paywall acceptance (trial started), complete onboarding.
                    // Trial reminders are handled by Apple's own trial notification.
                    completeOnboarding()
                }
            )
        }
    }

    /// After the analysis: shows the notification screen unless iOS already has a definitive answer.
    /// Quiet (provisional) authorization still gets the screen, to ask for real alerts.
    private func continueAfterNotificationPermissionCheck() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            let next: OnboardingStep
            switch settings.authorizationStatus {
            case .notDetermined, .provisional:
                next = .notificationPermissions
            case .denied:
                // A previous denial is handled later in the main app, not by
                // repeatedly interrupting the onboarding flow.
                UserDefaults.standard.set(false, forKey: "notificationsEnabled")
                next = .eightHabitsIntro
            default:
                next = .eightHabitsIntro
            }
            DispatchQueue.main.async {
                currentStep = next
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

        // Persist completion in Convex.
        if Auth.auth().currentUser != nil {
            Task {
                do {
                    let _: JSONValue = try await ConvexBackend.shared.call(
                        .mutation,
                        path: "profile:saveOnboarding",
                        args: ["completed": true]
                    )
                    #if DEBUG
                    print("✅ Convex onboardingCompleted set to true")
                    #endif
                } catch {
                    #if DEBUG
                    print("⚠️ Failed to update onboardingCompleted: \(error.localizedDescription)")
                    #endif
                }
            }
        }

        // Using @AppStorage, this will automatically trigger view update
        isOnboardingComplete = true
        TikTokManager.shared.requestTrackingAuthorizationIfNeeded()
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
        // Plan personnalisé (28 jours) généré à partir des réponses : raison + durée du stress,
        // âge, réponses du quiz habitudes (domaines les plus fragiles, objectif, temps dispo)
        // et symptômes. Sauvegardé en local + Convex.
        PlanGenerationService.shared.generatePersonalizedPlan(
            quizResult: result,
            overallData: overallQuizData,
            symptoms: selectedSymptoms
        )

        Task {
            // Save quiz responses to Convex
            if let overallData = overallQuizData {
                await saveOverallDataToFirebase(overallData)
            }
            #if DEBUG
            print("✅ User data saved - personalized plan generated")
            #endif
        }
    }

    private func saveOverallDataToFirebase(_ data: OverallQuizData) async {
        guard Auth.auth().currentUser != nil else { return }
        do {
            let _: JSONValue = try await ConvexBackend.shared.call(
                .mutation,
                path: "profile:saveOnboarding",
                args: ["answers": OptimizedFirebaseService.profileAnswers(data)]
            )
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
    @State private var breathStartDate: Date?
    @State private var hasExited = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// 4 s inhale / 6 s exhale.
    private static let introTimeline = BreathingTimeline(pattern: BreathingPattern(
        key: "onboarding_intro",
        name: "onboarding_intro",
        displayName: "4-6",
        inhaleDuration: 4,
        exhaleDuration: 6,
        description: ""
    ))

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
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .contentShape(Capsule())
                        }
                        .buttonStyle(.glassPrimary)
                        .padding(.horizontal, 24)
                    }

                    // Before the exercise starts, "Skip" already sits in the header.
                    if isStarted && !isComplete {
                        Button("onboarding_v2.skip".localized) {
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

            Text("onboarding_v2.breathing_intro.title".localized)
                .font(.faroBold(29))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.top, 18)

            Text("onboarding_v2.breathing_intro.subtitle".localized)
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
                Text(isComplete ? "onboarding_v2.breath_demo.nice_work".localized : "onboarding_v2.breath_demo.take_a_breath".localized)
                    .font(.faroBold(30))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text(isComplete ? "onboarding_v2.breath_demo.done_subtitle".localized : "onboarding_v2.breath_demo.instructions".localized)
                    .font(.poppinsRegular(16))
                    .foregroundStyle(.white.opacity(0.72))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
            }

            Spacer(minLength: 18)

            // Same "roller coaster" curve as the breathing sessions: it rises on the
            // inhale, falls on the exhale and scrolls past the fixed marker.
            TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: !isStarted || isComplete)) { context in
                let elapsed = breathStartDate.map { context.date.timeIntervalSince($0) } ?? 0
                VStack(spacing: 18) {
                    VStack(spacing: 5) {
                        Text(isStarted ? phaseTitle(at: elapsed) : "onboarding_v2.breath_demo.ready".localized)
                            .font(.faroBold(25))
                            .foregroundStyle(.white)
                        Text(isStarted ? phaseCountdown(at: elapsed) : "onboarding_v2.breath_demo.rhythm".localized)
                            .font(.poppinsMedium(16))
                            .foregroundStyle(.white.opacity(0.78))
                            .monospacedDigit()
                    }

                    BreathingWaveView(
                        timeline: Self.introTimeline,
                        elapsed: isStarted ? elapsed : 0,
                        accent: AudioPalette.accent,
                        reduceMotion: reduceMotion
                    )
                    .frame(height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                    .padding(.horizontal, 20)

                    Text(timeText)
                        .font(.poppinsMedium(15))
                        .foregroundStyle(.white.opacity(0.6))
                        .monospacedDigit()
                        .opacity(isStarted ? 1 : 0)
                }
            }

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
            .accessibilityLabel("common.back".localized)

            Spacer()

            if !isStarted {
                Button("onboarding_v2.skip".localized) {
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
        if isComplete { return "onboarding_v2.breath_demo.continue".localized }
        return "onboarding_v2.breath_demo.begin".localized
    }

    private func exitToNextStep() {
        guard !hasExited else { return }
        hasExited = true
        onContinue()
    }

    private func phaseTitle(at elapsed: Double) -> String {
        elapsed.truncatingRemainder(dividingBy: 10) < 4 ? "onboarding_v2.breath_demo.inhale".localized : "onboarding_v2.breath_demo.exhale".localized
    }

    private func phaseCountdown(at elapsed: Double) -> String {
        let t = elapsed.truncatingRemainder(dividingBy: 10)
        let remaining = t < 4 ? 4 - t : 10 - t
        return "\(Int(ceil(remaining)))"
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
        breathStartDate = Date()
    }
}

// MARK: - Draft restore

extension OverallQuizData {
    /// Rebuilds the profile answers from the codes saved in the onboarding draft.
    init(restoringFrom draft: PlanProfile) {
        let genderCode = draft.genderCode ?? "other"
        let ageCode = draft.ageCode ?? "25_34"
        let durationCode = draft.durationCode ?? "weeks"
        let genderKey = ["male": "gender_male", "female": "gender_female"][genderCode] ?? "gender_other"
        self.init(
            gender: "onboarding_v2.overall.\(genderKey)".localized,
            genderCode: genderCode,
            age: "onboarding_v2.overall.age_\(ageCode)".localized,
            ageCode: ageCode,
            acquisitionChannel: nil,
            reasons: draft.reasonCodes.map { "onboarding_v2.overall.reason_\($0)".localized },
            reasonCodes: draft.reasonCodes,
            duration: "onboarding_v2.overall.duration_\(durationCode)".localized,
            durationCode: durationCode
        )
    }
}
