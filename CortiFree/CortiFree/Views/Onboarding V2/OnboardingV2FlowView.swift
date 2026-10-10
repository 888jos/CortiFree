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
    @State private var hasGeneratedPlanThisSession = false
    @ObservedObject private var planStore = PersonalPlanStore.shared

    private let firebaseManager = FirebaseManager.shared

    init(enablesLiveActivityWhenAlreadyCompleted: Bool = false) {
        self.enablesLiveActivityWhenAlreadyCompleted = enablesLiveActivityWhenAlreadyCompleted
    }

    // MARK: - Onboarding Steps

    enum OnboardingStep: String, CaseIterable {
        case welcome
        case firstName
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
        case planReady
        case planDay      // 4-week calendar: week 1 day by day, editable
        case notificationPermissions
        case commitmentPledge
        case complete
        /// Auth was skipped before the analysis: an account is mandatory once the trial/payment started.
        case accountRequired

        // Define logical checkpoints where user can resume
        // These are steps that make sense to restart from
        var checkpoint: OnboardingStep {
            switch self {
            case .welcome, .firstName, .overall:
                return .welcome
            case .reassurance, .habitsQuiz, .stressPatternValidation, .symptomChecker:
                return .reassurance
            case .cortisolScienceHook, .sixtyDayExplanation, .scientificPlan:
                return .cortisolScienceHook
            case .authentication, .loading:
                return .authentication
            case .notificationPermissions, .planReady, .planDay, .commitmentPledge:
                return .planReady
            case .complete:
                return .complete
            case .accountRequired:
                return .accountRequired
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

        // Paid / trial started without an account: still owes the sign-up.
        if savedCheckpoint == OnboardingStep.accountRequired.rawValue && !isOnboardingComplete {
            currentStep = .accountRequired
            return
        }

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
        } else if ["eightHabitsIntro", "weekProgress", "eightHabits", "habitsProgress", "planWeeks"].contains(savedCheckpoint) {
            // The 8-habits screens were replaced by the plan screens.
            savedCheckpoint = OnboardingStep.planReady.rawValue
        }

        // If we have a saved checkpoint, resume from there
        if !savedCheckpoint.isEmpty,
           let step = OnboardingStep(rawValue: savedCheckpoint) {
            #if DEBUG
            print("📍 Resuming from checkpoint: \(step.rawValue)")
            #endif
            currentStep = step.checkpoint
            // Already signed in (killed during the analysis): don't ask to sign up again.
            if currentStep == .authentication, Auth.auth().currentUser != nil {
                currentStep = .loading
            }
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

    /// Bump whenever the onboarding screens change: the analytics dashboard shows the funnel
    /// of the latest version (older versions stay selectable).
    nonisolated static let analyticsVersion = "2026-10-10"

    /// The screens a user really goes through, in order. Steps that only redirect
    /// (sixtyDayExplanation, notificationPermissions) and the fallback sign-up after the
    /// paywall (accountRequired) are not funnel steps.
    static let funnelSteps: [OnboardingStep] = [
        .welcome, .firstName, .overall, .reassurance, .habitsQuiz, .stressPatternValidation,
        .symptomChecker, .cortisolScienceHook, .scientificPlan, .authentication, .loading,
        .planReady, .planDay, .commitmentPledge, .complete
    ]

    private func trackOnboardingScreen(_ step: OnboardingStep) {
        guard let index = Self.funnelSteps.firstIndex(of: step) else { return }
        AnalyticsManager.shared.trackOnboardingScreenViewed(
            screenName: step.rawValue,
            stepNumber: index + 1,
            totalSteps: Self.funnelSteps.count,
            version: Self.analyticsVersion
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
                onContinue: { currentStep = .firstName },
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

        case .firstName:
            OnboardingFirstNameView(onContinue: { currentStep = .overall })

        case .overall:
            OverallQuizView(onComplete: { data in
                overallQuizData = data
                AnalyticsICP.overallCompleted(data)
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
                AnalyticsICP.habitsCompleted(result)
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
                    AnalyticsICP.symptomsSelected(symptoms)
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
                onSkip: {
                    // The account is asked again (mandatory) right after the trial starts.
                    currentStep = .loading
                },
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
                    // The analysis ends on the real plan: generate it now so the next
                    // screens show the user's own plan.
                    generatePlanIfNeeded()
                    currentStep = .planReady
                }
            )

        case .notificationPermissions:
            // Screen removed (notifications are asked after the trial starts, in TrialKickoffView):
            // a checkpoint saved on it resumes at the commitment.
            Color.clear.onAppear { currentStep = .commitmentPledge }

        case .planReady, .planDay:
            if let plan = planStore.plan {
                planScreen(currentStep, plan: plan)
            } else {
                // No plan could be built (no answers at all): straight to the commitment.
                Color.clear.onAppear {
                    generatePlanIfNeeded()
                    if PersonalPlanStore.shared.plan == nil { currentStep = .commitmentPledge }
                }
            }

        case .commitmentPledge:
            CommitmentPledgeView(
                onBack: { currentStep = .planDay },
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
                    if Auth.auth().currentUser == nil {
                        currentStep = .accountRequired
                    } else {
                        completeOnboarding()
                    }
                }
            )

        case .accountRequired:
            if Auth.auth().currentUser != nil {
                Color.clear.onAppear(perform: completeOnboardingAfterSignUp)
            } else {
                AuthenticationView(
                    showsBack: false,
                    titleKey: "onboarding_v2.auth.required_title",
                    subtitleKey: "onboarding_v2.auth.required_subtitle",
                    onComplete: {
                        UserDefaults.standard.set(true, forKey: "user_is_authenticated")
                        completeOnboardingAfterSignUp()
                    }
                )
            }
        }
    }

    /// Signed up after the trial started: what was saved as a guest goes to the account first.
    private func completeOnboardingAfterSignUp() {
        PersonalPlanStore.shared.claimGuestPlan()
        OnboardingSync.flush()
        if let overallData = overallQuizData {
            Task { await saveOverallDataToFirebase(overallData) }
        }
        completeOnboarding()
    }

    private func completeOnboarding() {
        // Clear checkpoint data since onboarding is complete
        savedCheckpoint = ""
        let isPremium = RevenueCatManager.shared.hasPremiumEntitlement
        if isPremium {
            hasSeenPaywall = false
            // Trial just started: first session + plan + reminder before Home (TrialKickoffView).
            if RevenueCatManager.shared.startedSubscriptionRecently { TrialKickoff.markPending() }
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

        // Persist completion in Convex (retried until the server has it, see OnboardingSync).
        OnboardingSync.queueCompleted()

        // Using @AppStorage, this will automatically trigger view update
        isOnboardingComplete = true
        // The daily reminders wait for the end of the onboarding (time chosen on the permissions step).
        NotificationService.shared.syncDailyNotificationsWithPreference()
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

    @ViewBuilder
    private func planScreen(_ step: OnboardingStep, plan: PersonalPlan) -> some View {
        switch step {
        case .planReady:
            OnboardingPlanReadyView(plan: plan, habitsQuizResult: habitsQuizResult,
                                    onContinue: { currentStep = .planDay })
        default:
            OnboardingPlanCalendarView(plan: plan, onBack: { currentStep = .planReady },
                                       onContinue: { currentStep = .commitmentPledge })
        }
    }

    // MARK: - Firebase Integration

    /// Builds the personal plan from the answers, once (resuming the flow keeps the plan).
    private func generatePlanIfNeeded() {
        guard PersonalPlanStore.shared.plan == nil || !hasGeneratedPlanThisSession else { return }
        hasGeneratedPlanThisSession = true
        if let habitsResult = habitsQuizResult {
            saveDataAndGeneratePlan(result: habitsResult)
        } else if let draft = PersonalPlanStore.shared.storedOnboardingProfile(), !draft.isEmpty {
            // Answers not in memory (should not happen after restoreAnswersFromDraft):
            // still build the plan from what each quiz step saved.
            PersonalPlanStore.shared.createPlanFromOnboarding(draft)
        }
    }

    private func saveDataAndGeneratePlan(result: HabitsQuizResult) {
        // Plan personnalisé (28 jours) généré à partir des réponses : raison + durée du stress,
        // âge, réponses du quiz habitudes (domaines les plus fragiles, objectif, temps dispo)
        // et symptômes. Sauvegardé en local + Convex.
        PlanGenerationService.shared.generatePersonalizedPlan(
            quizResult: result,
            overallData: overallQuizData,
            symptoms: selectedSymptoms
        )

        // The user is signed in now: send the baseline queued at the habits quiz (if it failed).
        OnboardingSync.flush()

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
/// before answering the onboarding questions. It opens on the heart-rate instructions:
/// measure, breathe (starts right away), measure again, compare.
struct OnboardingBreathingIntroView: View {
    let onContinue: () -> Void
    let onBack: () -> Void

    @StateObject private var planetSettings = PlanetSettings.shared
    @State private var isStarted = false
    @State private var isComplete = false
    @State private var elapsedSeconds = 0
    @State private var breathStartDate: Date?
    @State private var hasExited = false
    @StateObject private var pulseMeter = PulseCameraMeter()
    @State private var pulseStage: PulseStage? = .before
    @State private var pulseBefore: PulseCameraMeter.Reading?
    @State private var pulseAfter: PulseCameraMeter.Reading?
    /// The user measured but the reading was unclear: the after-measure and the result screen still follow.
    @State private var pulseAttempted = false
    private var measuresPulse: Bool { pulseBefore != nil || pulseAttempted }

    /// Heart rate with the flash before and after the breathing (each step can be skipped).
    private enum PulseStage { case before, after, comparison }
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

    /// One minute when the heart rate is measured around it, so the effect has time to show.
    private var duration: Int { measuresPulse ? 60 : 30 }
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            GalaxyBackgroundView(intensity: 0.9)
                .ignoresSafeArea()

            if let pulseStage {
                pulseContent(pulseStage)
                    .transition(.opacity)
            } else {
            VStack(spacing: 0) {
                header

                exerciseContent

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
        }
        .animation(.easeInOut(duration: 0.3), value: pulseStage)
        // A result from an earlier onboarding must not be shown for this one.
        .onAppear { OnboardingPulseResult.clear() }
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

    @ViewBuilder
    private func pulseContent(_ stage: PulseStage) -> some View {
        switch stage {
        case .before:
            OnboardingPulseMeasureView(
                meter: pulseMeter,
                isAfter: false,
                onFinish: { reading in
                    pulseBefore = reading
                    // Not skipped: it is the day-1 weekly pulse, not asked again in the check-in.
                    if let reading { WeeklyPulseStore.recordOnboardingPulse(reading.bpm) }
                    pulseStage = nil
                    // "Start breathing" was the button of the result: the breathing starts now.
                    // Skipped: the ready screen still says how long it lasts.
                    if reading != nil { isStarted = true }
                },
                onBack: {
                    pulseMeter.stop()
                    onBack()
                },
                onUnclear: {
                    pulseBefore = nil
                    pulseAttempted = true
                    pulseStage = nil
                }
            )
        case .after:
            measureAfterView
        case .comparison:
            OnboardingPulseComparisonView(
                before: pulseBefore,
                after: pulseAfter,
                onRemeasure: { pulseStage = .after },
                onContinue: exitToNextStep
            )
        }
    }

    private var measureAfterView: some View {
        #if targetEnvironment(simulator)
        OnboardingPulseMeasureView(
            meter: pulseMeter,
            isAfter: true,
            onFinish: finishAfterMeasure,
            onUnclear: unclearAfterMeasure,
            simulatedBPM: Double(max(58, (pulseBefore?.bpm ?? 80) - 9))
        )
        #else
        OnboardingPulseMeasureView(meter: pulseMeter, isAfter: true, onFinish: finishAfterMeasure, onUnclear: unclearAfterMeasure)
        #endif
    }

    private func finishAfterMeasure(_ reading: PulseCameraMeter.Reading?) {
        guard let reading else { return exitToNextStep() }
        pulseAfter = reading
        pulseStage = .comparison
    }

    private func unclearAfterMeasure() {
        pulseAfter = nil
        pulseStage = .comparison
    }

    private var exerciseContent: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 20)

            VStack(spacing: 8) {
                Text(isComplete ? "onboarding_v2.breath_demo.nice_work".localized : "onboarding_v2.breath_demo.take_a_breath".localized)
                    .font(.faroBold(30))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .balancedLines()

                Text(isComplete
                     ? (measuresPulse ? "onboarding_v2.pulse.done_subtitle" : "onboarding_v2.breath_demo.done_subtitle").localized
                     : "onboarding_v2.breath_demo.instructions".localized)
                    .font(.poppinsRegular(16))
                    .foregroundStyle(.white.opacity(0.72))
                    .multilineTextAlignment(.center)
                    .balancedLines()
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
        if isComplete {
            return (measuresPulse ? "onboarding_v2.pulse.cta_after" : "onboarding_v2.breath_demo.continue").localized
        }
        return (measuresPulse ? "onboarding_v2.pulse.begin_long" : "onboarding_v2.breath_demo.begin").localized
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
        let remaining = max(duration - elapsedSeconds, 0)
        return String(format: "%02d:%02d", remaining / 60, remaining % 60)
    }

    private func primaryAction() {
        HapticManager.light()
        if isComplete {
            if measuresPulse { pulseStage = .after } else { exitToNextStep() }
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
