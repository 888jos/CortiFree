//
//  MixpanelManager.swift (now using Firebase Analytics)
//  CortiFree
//
//  Analytics manager - Migrated from Mixpanel to Firebase Analytics
//  Sends to both Firebase Analytics AND Firestore for dashboard
//

import Foundation
import UIKit
import FirebaseAnalytics
import FirebaseFirestore
import FirebaseAuth

class MixpanelManager {
    static let shared = MixpanelManager()

    private var isInitialized = false
    private let db = Firestore.firestore()

    private init() {
        // Initialize will be called explicitly from AppDelegate/App
    }

    // MARK: - Initialization

    func initialize() {
        guard !isInitialized else { return }

        // Firebase Analytics is auto-initialized with Firebase SDK
        // Just set user properties
        registerSuperProperties()

        isInitialized = true
        #if DEBUG
        print("[Analytics] ✅ Initialized successfully with Firebase")
        #endif

        // Send a test event to verify connection
        track(event: "app_opened")
    }

    private func registerSuperProperties() {
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        let osVersion = UIDevice.current.systemVersion
        let deviceType = UIDevice.current.model
        let language = Locale.current.language.languageCode?.identifier ?? "unknown"

        // Set Firebase user properties (sent with every event)
        Analytics.setUserProperty(appVersion, forName: "app_version")
        Analytics.setUserProperty(osVersion, forName: "os_version")
        Analytics.setUserProperty(deviceType, forName: "device_type")
        Analytics.setUserProperty(language, forName: "language")
        Analytics.setUserProperty("iOS", forName: "platform")
    }

    // MARK: - User Identification & Properties

    func identify(userId: String) {
        // Set Firebase user ID
        Analytics.setUserID(userId)
    }

    func setUserProfile(
        firstName: String?,
        email: String?,
        age: Int?,
        gender: String?,
        globalScore: Int?,
        primaryGoal: String?
    ) {
        // Set Firebase user properties
        if let firstName = firstName {
            Analytics.setUserProperty(firstName, forName: "first_name")
        }
        if let age = age {
            Analytics.setUserProperty(String(age), forName: "age")
        }
        if let gender = gender {
            Analytics.setUserProperty(gender, forName: "gender")
        }
        if let globalScore = globalScore {
            Analytics.setUserProperty(String(globalScore), forName: "global_score")
        }
        if let primaryGoal = primaryGoal {
            Analytics.setUserProperty(primaryGoal, forName: "primary_goal")
        }
    }

    func updateUserProgress(
        currentDay: Int?,
        currentStreak: Int?,
        totalTasksCompleted: Int?,
        globalScore: Int?,
        totalAchievements: Int?
    ) {
        // Set Firebase user properties
        if let currentDay = currentDay {
            Analytics.setUserProperty(String(currentDay), forName: "current_program_day")
        }
        if let currentStreak = currentStreak {
            Analytics.setUserProperty(String(currentStreak), forName: "current_streak")
        }
        if let totalTasksCompleted = totalTasksCompleted {
            Analytics.setUserProperty(String(totalTasksCompleted), forName: "total_tasks_completed")
        }
        if let globalScore = globalScore {
            Analytics.setUserProperty(String(globalScore), forName: "global_score")
        }
        if let totalAchievements = totalAchievements {
            Analytics.setUserProperty(String(totalAchievements), forName: "total_achievements")
        }
    }

    func incrementProperty(property: String, by amount: Double = 1) {
        // Firebase doesn't have direct increment - track as event instead
        track(event: "property_incremented", properties: [
            "property": property,
            "amount": amount
        ])
    }

    // MARK: - 💳 SUBSCRIPTION STATUS TRACKING

    enum SubscriptionStatus: String {
        case trial = "trial"
        case active = "active"
        case expired = "expired"
        case cancelled = "cancelled"
        case none = "none"
    }

    enum SubscriptionType: String {
        case monthly = "monthly"
        case yearly = "yearly"
    }

    func updateSubscriptionStatus(status: SubscriptionStatus, type: SubscriptionType?, expiryDate: Date?) {
        var properties: [String: any Any] = [
            "subscription_status": status.rawValue,
            "subscription_type": type?.rawValue ?? "none",
            "is_trial": status == .trial,
            "is_paying": status == .active
        ]

        if let expiryDate = expiryDate {
            properties["subscription_expiry_date"] = ISO8601DateFormatter().string(from: expiryDate)
        } else {
            properties["subscription_expiry_date"] = ""
        }

        // Calculate days subscribed
        if let firstSubDate = UserDefaults.standard.object(forKey: "first_subscription_date") as? Date {
            let daysSubscribed = Calendar.current.dateComponents([.day], from: firstSubDate, to: Date()).day ?? 0
            properties["days_subscribed"] = daysSubscribed
        } else {
            properties["days_subscribed"] = 0
        }

        // Set Firebase user properties (persists across sessions)
        Analytics.setUserProperty(status.rawValue, forName: "subscription_status")
        Analytics.setUserProperty(type?.rawValue ?? "none", forName: "subscription_type")

        // Also track as event for timeline analysis
        track(event: "subscription_status_changed", properties: properties)

        // Save to UserDefaults for quick access
        UserDefaults.standard.set(status.rawValue, forKey: "current_subscription_status")

        print("✅ Subscription status updated: \(status.rawValue)")
    }

    // MARK: - 🎯 ONBOARDING - SIMPLIFIÉ (viewed + clicked pour chaque écran)

    // 1. Welcome Screen
    func trackOnboardingWelcomeViewed() {
        track(event: "onboarding_welcome_viewed")
    }

    func trackOnboardingWelcomeContinue(timeSpent: Double = 0) {
        track(event: "onboarding_welcome_clicked")
    }

    // 2. Overall Quiz (5 questions: genre, âge, découverte, raisons stress, durée stress)
    func trackOnboardingOverallQuizViewed() {
        track(event: "onboarding_overall_quiz_viewed")
    }

    func trackOnboardingOverallQuizQuestionViewed(questionNumber: Int) {
        track(event: "onboarding_overall_quiz_question_viewed", properties: [
            "question_number": questionNumber
        ])
    }

    func trackOnboardingOverallQuizQuestionClicked(questionNumber: Int) {
        track(event: "onboarding_overall_quiz_question_clicked", properties: [
            "question_number": questionNumber
        ])
    }

    func trackOnboardingOverallQuizCompleted(
        firstName: String,
        age: Int,
        gender: String,
        stressReasons: [String],
        stressDuration: String,
        timeToComplete: Double
    ) {
        track(event: "onboarding_overall_quiz_clicked")
    }

    // Legacy support - redirects to new format
    func trackOnboardingQuizQuestionViewed(questionNumber: Int, questionText: String, quizType: String = "habits") {
        if quizType == "overall" {
            trackOnboardingOverallQuizQuestionViewed(questionNumber: questionNumber)
        } else {
            trackOnboardingHabitsQuizQuestionViewed(questionNumber: questionNumber)
        }
    }

    func trackOnboardingQuizQuestionAnswered(
        questionNumber: Int,
        questionText: String,
        answerIndex: Int,
        answerText: String,
        timeToAnswer: Double,
        quizType: String = "habits"
    ) {
        if quizType == "overall" {
            trackOnboardingOverallQuizQuestionClicked(questionNumber: questionNumber)
        } else {
            trackOnboardingHabitsQuizQuestionClicked(questionNumber: questionNumber)
        }
    }

    // 3. Reassurance View
    func trackOnboardingReassuranceViewed(userName: String = "") {
        track(event: "onboarding_reassurance_viewed")
    }

    func trackOnboardingReassuranceStartQuiz(timeSpent: Double = 0) {
        track(event: "onboarding_reassurance_clicked")
    }

    func trackOnboardingReassuranceContinue(timeSpent: Double = 0) {
        track(event: "onboarding_reassurance_clicked")
    }

    // 4. Habits Quiz (11 questions)
    func trackOnboardingHabitsQuizViewed() {
        track(event: "onboarding_habits_quiz_viewed")
    }

    func trackOnboardingHabitsQuizQuestionViewed(questionNumber: Int) {
        track(event: "onboarding_habits_quiz_question_viewed", properties: [
            "question_number": questionNumber
        ])
    }

    func trackOnboardingHabitsQuizQuestionClicked(questionNumber: Int) {
        track(event: "onboarding_habits_quiz_question_clicked", properties: [
            "question_number": questionNumber
        ])
    }

    func trackOnboardingQuizBackClicked(fromQuestionNumber: Int) {
        // Pas nécessaire pour le funnel basique
    }

    func trackOnboardingHabitsQuizCompleted(
        totalTime: Double,
        serenityScore: Int,
        sleepScore: Int,
        energyScore: Int,
        focusScore: Int,
        habitsScore: Int,
        balanceScore: Int,
        globalScore: Int,
        appearanceConcern: String,
        baselineWakeTime: String?,
        baselineSleepDuration: Double?,
        baselineWaterIntake: Double?,
        baselineExerciseFrequency: Int?,
        baselineMeditationFrequency: Int?,
        baselineAvailableTime: String?,
        hasPhysicalLimitations: Bool?,
        primaryGoal: String?
    ) {
        track(event: "onboarding_habits_quiz_clicked", properties: [
            "total_time": totalTime,
            "serenity_score": serenityScore,
            "sleep_score": sleepScore,
            "energy_score": energyScore,
            "focus_score": focusScore,
            "habits_score": habitsScore,
            "balance_score": balanceScore,
            "global_score": globalScore,
            "appearance_concern": appearanceConcern,
            "baseline_wake_time": baselineWakeTime ?? "",
            "baseline_sleep_duration": baselineSleepDuration ?? 0.0,
            "baseline_water_intake": baselineWaterIntake ?? 0.0,
            "baseline_exercise_frequency": baselineExerciseFrequency ?? 0,
            "baseline_meditation_frequency": baselineMeditationFrequency ?? 0,
            "baseline_available_time": baselineAvailableTime ?? "",
            "has_physical_limitations": hasPhysicalLimitations ?? false,
            "primary_goal": primaryGoal ?? ""
        ])
    }

    func trackOnboardingMarketingData(acquisitionChannel: String?, previousAppExperience: String?) {
        // Gardé pour compatibilité mais simplifié
    }

    // 5. Sixty Days Explanation
    func trackOnboardingSixtyDaysExplanationViewed() {
        track(event: "onboarding_sixty_days_viewed")
    }

    func trackOnboardingSixtyDaysContinue() {
        track(event: "onboarding_sixty_days_clicked")
    }

    func trackOnboardingSixtyDaysExplanationContinue(timeSpent: Double = 0) {
        track(event: "onboarding_sixty_days_clicked")
    }

    // 6. Scientific Plan
    func trackOnboardingScientificPlanViewed() {
        track(event: "onboarding_scientific_plan_viewed")
    }

    func trackOnboardingScientificPlanContinue() {
        track(event: "onboarding_scientific_plan_clicked")
    }

    func trackOnboardingScientificPlanContinue(timeSpent: Double) {
        track(event: "onboarding_scientific_plan_clicked")
    }

    // 7. Authentication
    func trackOnboardingAuthenticationViewed(firstName: String = "") {
        track(event: "onboarding_authentication_viewed")
    }

    func trackOnboardingAuthenticationCompleted(authMethod: String, userId: String) {
        track(event: "onboarding_authentication_clicked", properties: [
            "auth_method": authMethod
        ])
        // TikTok: CompleteRegistration
        TikTokManager.shared.trackCompleteRegistration(method: authMethod)
        // PostHog
        PostHogManager.shared.trackRegistration(method: authMethod)
    }

    func trackOnboardingAuthenticationFailed(error: String, authMethod: String) {
        // Gardé pour debug
    }

    // 8. Loading Analysis
    func trackOnboardingLoadingAnalysisViewed() {
        track(event: "onboarding_loading_analysis_viewed")
    }

    func trackOnboardingLoadingAnalysisCompleted(loadingDuration: Double = 0) {
        track(event: "onboarding_loading_analysis_clicked")
    }

    func trackOnboardingLoadingAnalysisComplete(timeSpent: Double = 0) {
        track(event: "onboarding_loading_analysis_clicked")
    }

    // 9. CortiFree Rating
    func trackOnboardingCortiFreeRatingViewed(
        serenityScore: Int = 0,
        sleepScore: Int = 0,
        energyScore: Int = 0,
        focusScore: Int = 0,
        habitsScore: Int = 0
    ) {
        track(event: "onboarding_cortifree_rating_viewed")
    }

    func trackOnboardingRatingDomainViewed(domainName: String, domainScore: Int) {
        // Pas nécessaire pour le funnel basique
    }

    func trackOnboardingRatingContinue(timeSpent: Double = 0) {
        track(event: "onboarding_cortifree_rating_clicked")
    }

    // 10. Eight Habits Intro
    func trackOnboardingEightHabitsIntroViewed() {
        track(event: "onboarding_eight_habits_intro_viewed")
    }

    func trackOnboardingEightHabitsIntroContinue() {
        track(event: "onboarding_eight_habits_intro_clicked")
    }

    // 11. Week Progress
    func trackOnboardingWeekProgressViewed() {
        track(event: "onboarding_week_progress_viewed")
    }

    func trackOnboardingWeekProgressContinue() {
        track(event: "onboarding_week_progress_clicked")
    }

    // 12. Eight Habits Flow
    func trackOnboardingEightHabitsFlowViewed() {
        track(event: "onboarding_eight_habits_flow_viewed")
    }

    func trackOnboardingHabitCarouselChanged(habitIndex: Int, habitTitle: String, navigationMethod: String) {
        // Pas nécessaire pour le funnel basique
    }

    func trackOnboardingEightHabitsContinue(habitsViewedCount: Int = 0, timeSpent: Double = 0) {
        track(event: "onboarding_eight_habits_flow_clicked")
    }

    // 13. Notification Permissions
    func trackOnboardingNotificationPermissionsViewed() {
        track(event: "onboarding_notifications_viewed")
    }

    func trackOnboardingNotificationPermissionViewed() {
        track(event: "onboarding_notifications_viewed")
    }

    func trackOnboardingNotificationToggleChanged(notificationType: String, enabled: Bool) {
        // Pas nécessaire pour le funnel basique
    }

    func trackOnboardingNotificationPermissionRequested(
        streakEnabled: Bool,
        dailyRitualEnabled: Bool,
        weeklyReportEnabled: Bool
    ) {
        // Pas nécessaire pour le funnel basique
    }

    func trackOnboardingNotificationPermissionsContinue(
        streakEnabled: Bool = false,
        dailyRitualEnabled: Bool = false,
        weeklyReportEnabled: Bool = false
    ) {
        track(event: "onboarding_notifications_clicked")
    }

    func trackOnboardingNotificationPermissionsGranted(granted: Bool) {
        // Pas nécessaire pour le funnel basique
    }

    // 14. Habits Progress Flow
    func trackOnboardingHabitsProgressViewed() {
        track(event: "onboarding_habits_progress_viewed")
    }

    func trackOnboardingProgressHabitSelected(habitIndex: Int, habitTitle: String) {
        // Pas nécessaire pour le funnel basique
    }

    func trackOnboardingProgressChartInteracted(habitIndex: Int, weekNumber: Int, habitTitle: String) {
        // Pas nécessaire pour le funnel basique
    }

    func trackOnboardingProgressContinue(timeSpent: Double = 0) {
        track(event: "onboarding_habits_progress_clicked")
    }

    // 15. Testimonials
    func trackOnboardingTestimonialsViewed() {
        track(event: "onboarding_testimonials_viewed")
    }

    func trackOnboardingTestimonialsScrolled(testimonialsViewed: Int, scrollDepth: Double) {
        // Pas nécessaire pour le funnel basique
    }

    func trackOnboardingTestimonialsContinue() {
        track(event: "onboarding_testimonials_clicked")
    }

    // 16. Goals Selection
    func trackOnboardingGoalsSelectionViewed() {
        track(event: "onboarding_goals_selection_viewed")
    }

    func trackOnboardingGoalToggled(goalText: String, selected: Bool) {
        // Pas nécessaire pour le funnel basique
    }

    func trackOnboardingGoalsSelectionCompleted(selectedGoals: [String]) {
        track(event: "onboarding_goals_selection_clicked")
    }

    // 17. Onboarding Completion (Paywall)
    func trackOnboardingCompletionViewed(quizAnswersCount: Int = 0, hasQuizData: Bool = false) {
        track(event: "onboarding_paywall_viewed")
        // TikTok: ViewContent (paywall seen)
        TikTokManager.shared.trackViewContent()
        // PostHog
        PostHogManager.shared.trackPaywallViewed(source: "onboarding")
    }

    func trackOnboardingViewPlanClicked() {
        track(event: "onboarding_paywall_clicked")
    }

    func trackOnboardingCompleted(
        totalTime: Double? = nil,
        quizGlobalScore: Int? = nil,
        selectedGoalsCount: Int? = nil,
        notificationsEnabled: Bool? = nil,
        userId: String? = nil,
        firstName: String? = nil,
        age: Int? = nil,
        gender: String? = nil
    ) {
        track(event: "onboarding_completed")
    }

    // Onboarding Drop-off (plus nécessaire avec les funnels viewed/clicked)
    func trackOnboardingDroppedOff(stepName: String, stepNumber: Int, timeSpentTotal: Double) {
        // Pas nécessaire - le drop-off se calcule automatiquement dans Mixpanel
    }

    // MARK: - 🏠 HOME VIEW

    func trackHomeViewed(programDay: Int, daysRemaining: Int, selectedRoutineTitle: String) {
        track(event: "home_viewed", properties: [
            "program_day": programDay,
            "days_remaining": daysRemaining,
            "selected_routine_title": selectedRoutineTitle
        ])
    }

    func trackHomeQuickActionClicked(actionType: String) {
        track(event: "home_quick_action_clicked", properties: [
            "action_type": actionType
        ])
    }

    func trackHomeAntiStressClicked() {
        track(event: "home_anti_stress_clicked")
    }

    func trackAntiStressSessionStarted() {
        track(event: "anti_stress_session_started")
    }

    func trackAntiStressSessionCompleted(duration: Int) {
        track(event: "anti_stress_session_completed", properties: [
            "duration": duration
        ])
    }

    func trackAntiStressSessionClosed(duration: Int) {
        track(event: "anti_stress_session_closed", properties: [
            "duration": duration
        ])
    }

    // MARK: - ✅ TASKS VIEW (Critical)

    func trackTasksViewed(
        currentDay: Int,
        actualDay: Int,
        todoCount: Int,
        doneCount: Int,
        skippedCount: Int,
        globalScore: Int,
        globalStreak: Int
    ) {
        track(event: "tasks_viewed", properties: [
            "current_day": currentDay,
            "actual_day": actualDay,
            "todo_count": todoCount,
            "done_count": doneCount,
            "skipped_count": skippedCount,
            "global_score": globalScore,
            "global_streak": globalStreak
        ])
    }

    func trackTasksTabChanged(tab: String, fromTab: String) {
        track(event: "tasks_tab_changed", properties: [
            "tab": tab,
            "from_tab": fromTab
        ])
    }

    func trackTasksDayChanged(fromDay: Int, toDay: Int, direction: String) {
        track(event: "tasks_day_changed", properties: [
            "from_day": fromDay,
            "to_day": toDay,
            "direction": direction
        ])
    }

    func trackTaskCardViewed(
        taskTitle: String,
        taskFrequency: String,
        taskDuration: String,
        taskDifficulty: Int,
        taskStreak: Int,
        habitId: String
    ) {
        track(event: "task_card_viewed", properties: [
            "task_title": taskTitle,
            "task_frequency": taskFrequency,
            "task_duration": taskDuration,
            "task_difficulty": taskDifficulty,
            "task_streak": taskStreak,
            "habit_id": habitId
        ])
    }

    func trackTaskCardTapped(taskTitle: String, habitId: String) {
        track(event: "task_card_tapped", properties: [
            "task_title": taskTitle,
            "habit_id": habitId
        ])
    }

    // ⭐⭐ CRITICAL EVENT
    func trackTaskValidated(
        taskTitle: String,
        habitId: String,
        day: Int,
        currentStreak: Int,
        tasksCompletedToday: Int,
        globalScoreBefore: Int,
        globalScoreAfter: Int
    ) {
        track(event: "task_validated", properties: [
            "task_title": taskTitle,
            "habit_id": habitId,
            "day": day,
            "current_streak": currentStreak,
            "tasks_completed_today": tasksCompletedToday,
            "global_score_before": globalScoreBefore,
            "global_score_after": globalScoreAfter
        ])

        // Increment lifetime counter
        incrementProperty(property: "tasks_completed_lifetime")
    }

    func trackTaskSkipped(taskTitle: String, habitId: String, day: Int) {
        track(event: "task_skipped", properties: [
            "task_title": taskTitle,
            "habit_id": habitId,
            "day": day
        ])
    }

    func trackAchievementUnlocked(
        achievementId: String,
        achievementTitle: String,
        achievementCategory: String,
        achievementMilestone: Int
    ) {
        track(event: "achievement_unlocked", properties: [
            "achievement_id": achievementId,
            "achievement_title": achievementTitle,
            "achievement_category": achievementCategory,
            "achievement_milestone": achievementMilestone
        ])
    }


    func trackHabitBadgeUnlocked(habitId: String, badgeLevel: String, tasksCompleted: Int) {
        track(event: "habit_badge_unlocked", properties: [
            "habit_id": habitId,
            "badge_level": badgeLevel,
            "tasks_completed": tasksCompleted
        ])
    }

    // MARK: - 📚 LIBRARY VIEW

    func trackLibraryViewed() {
        track(event: "library_viewed")
    }

    func trackBreathingExerciseStarted(patternType: String) {
        track(event: "library_breathing_exercise_started", properties: [
            "pattern_type": patternType
        ])
    }

    func trackBreathingExerciseCompleted(
        patternType: String,
        totalCycles: Int,
        totalDuration: Int
    ) {
        track(event: "breathing_exercise_completed", properties: [
            "pattern_type": patternType,
            "total_cycles": totalCycles,
            "total_duration": totalDuration
        ])

        incrementProperty(property: "exercises_completed_lifetime")
    }

    func trackMeditationSessionStarted(meditationId: String, meditationTitle: String, duration: Int) {
        track(event: "library_meditation_started", properties: [
            "meditation_id": meditationId,
            "meditation_title": meditationTitle,
            "duration": duration
        ])
    }

    func trackMeditationSessionCompleted(meditationId: String, actualDuration: Int) {
        track(event: "meditation_session_completed", properties: [
            "meditation_id": meditationId,
            "actual_duration": actualDuration
        ])

        incrementProperty(property: "exercises_completed_lifetime")
    }

    // MARK: - 📝 JOURNAL VIEW

    func trackJournalEntryCreated(entryDate: String, hasMood: Bool, hasText: Bool, wordCount: Int) {
        track(event: "journal_entry_created", properties: [
            "entry_date": entryDate,
            "has_mood": hasMood,
            "has_text": hasText,
            "word_count": wordCount
        ])
    }

    func trackJournalMoodSelected(moodValue: Int, moodLabel: String) {
        track(event: "journal_mood_selected", properties: [
            "mood_value": moodValue,
            "mood_label": moodLabel
        ])
    }

    func trackJournalEntrySaved(entryId: String, entryDate: String, wordCount: Int) {
        track(event: "journal_entry_saved", properties: [
            "entry_id": entryId,
            "entry_date": entryDate,
            "word_count": wordCount
        ])
    }

    // MARK: - 👤 PROFILE VIEW

    func trackProfileViewed(selectedTab: String, userName: String, globalScore: Int) {
        track(event: "profile_viewed", properties: [
            "selected_tab": selectedTab,
            "user_name": userName,
            "global_score": globalScore
        ])
    }

    func trackProfileTabChanged(tab: String, fromTab: String) {
        track(event: "profile_tab_changed", properties: [
            "tab": tab,
            "from_tab": fromTab
        ])
    }

    func trackProfileAchievementBadgeTapped(achievementId: String, isUnlocked: Bool) {
        track(event: "profile_achievement_badge_tapped", properties: [
            "achievement_id": achievementId,
            "is_unlocked": isUnlocked
        ])
    }

    // MARK: - ⚙️ SETTINGS VIEW

    func trackSettingsViewed() {
        track(event: "settings_viewed")
    }

    func trackSettingsNotificationsToggled(notificationType: String, enabled: Bool) {
        track(event: "settings_notifications_toggled", properties: [
            "notification_type": notificationType,
            "enabled": enabled
        ])
    }

    func trackSettingsLogoutClicked() {
        track(event: "settings_logout_clicked")
    }

    // MARK: - 🎯 CONVERSION & RETENTION (Critical)

    func trackFirstAppLaunch(installSource: String, deviceType: String, osVersion: String) {
        track(event: "first_app_launch", properties: [
            "install_source": installSource,
            "device_type": deviceType,
            "os_version": osVersion
        ])
    }

    func trackFirstTaskCompleted(
        taskTitle: String,
        habitId: String,
        day: Int,
        timeSinceOnboarding: Double
    ) {
        track(event: "first_task_completed", properties: [
            "task_title": taskTitle,
            "habit_id": habitId,
            "day": day,
            "time_since_onboarding": timeSinceOnboarding
        ])
    }

    func trackDayActive(day: Int, tasksCompleted: Int, currentStreak: Int?, globalScoreChange: Int?) {
        let eventName: String
        switch day {
        case 1: eventName = "day_1_active"
        case 3: eventName = "day_3_active"
        case 7: eventName = "day_7_active"
        case 14: eventName = "day_14_active"
        case 30: eventName = "day_30_active"
        case 66: eventName = "day_66_completed"
        default: return
        }

        var properties: [String: Any] = [
            "tasks_completed": tasksCompleted
        ]

        if let streak = currentStreak {
            properties["current_streak"] = streak
        }
        if let scoreChange = globalScoreChange {
            properties["global_score_change"] = scoreChange
        }

        track(event: eventName, properties: properties)
    }

    // MARK: - 🔧 SESSION & ERRORS

    func trackSessionStarted() {
        track(event: "session_started")
    }

    func trackSessionEnded(durationSeconds: Int, screensViewed: Int, actionsCompleted: Int) {
        track(event: "session_ended", properties: [
            "duration": durationSeconds,
            "screens_viewed": screensViewed,
            "actions_completed": actionsCompleted
        ])
    }

    func trackError(errorType: String, errorMessage: String, screen: String, userAction: String?) {
        track(event: "error_occurred", properties: [
            "error_type": errorType,
            "error_message": errorMessage,
            "screen": screen,
            "user_action": userAction ?? "unknown"
        ])
    }

    // MARK: - Helper Methods

    func track(event: String, properties: [String: any Any]? = nil) {
        // 1. Send to Firebase Analytics (standard events)
        if let props = properties {
            // Convert properties to [String: Any] for Firebase
            var firebaseParams: [String: Any] = [:]
            for (key, value) in props {
                firebaseParams[key] = value
            }
            Analytics.logEvent(event, parameters: firebaseParams)
        } else {
            Analytics.logEvent(event, parameters: nil)
        }

        // 2. ALSO send to Firestore for dashboard (with full data)
        Task {
            await sendToFirestore(event: event, properties: properties)
        }

        #if DEBUG
        if let props = properties, !props.isEmpty {
            print("[Analytics] 📊 Event: \(event) | Properties: \(props)")
        } else {
            print("[Analytics] 📊 Event: \(event)")
        }
        #endif
    }

    private func sendToFirestore(event: String, properties: [String: any Any]?) async {
        // Send event to Firestore analytics_events collection for dashboard
        var eventData: [String: Any] = [
            "event_name": event,
            "timestamp": Timestamp(date: Date()),
            "user_id": Auth.auth().currentUser?.uid ?? "anonymous"
        ]

        // Add properties if available
        if let props = properties {
            var propsDict: [String: Any] = [:]
            for (key, value) in props {
                propsDict[key] = value
            }
            eventData["properties"] = propsDict
        }

        do {
            try await db.collection("analytics_events").addDocument(data: eventData)
            #if DEBUG
            print("[Analytics] 💾 Sent to Firestore: \(event)")
            #endif
        } catch {
            #if DEBUG
            print("[Analytics] ❌ Firestore error: \(error.localizedDescription)")
            #endif
        }
    }

    func flush() {
        // Firebase Analytics automatically flushes, no manual flush needed
        #if DEBUG
        print("[Analytics] ℹ️ Firebase Analytics auto-flushes, no manual flush needed")
        #endif
    }

    func reset() {
        // Reset Firebase Analytics user ID
        Analytics.setUserID(nil)
    }

    // MARK: - Purchase Tracking

    /// isTrial = l'entitlement actif est en période d'essai (RevenueCat: periodType == .trial)
    func trackPurchase(productId: String, price: Decimal, currency: String, isTrial: Bool = false) {
        let priceDouble = NSDecimalNumber(decimal: price).doubleValue

        let properties: [String: any Any] = [
            "product_id": productId,
            "price": priceDouble,
            "currency": currency,
            "is_trial": isTrial,
            "timestamp": Date().timeIntervalSince1970
        ]

        track(event: "subscription_purchased", properties: properties)

        if isTrial {
            // Trial gratuit commencé → StartTrial (valeur 0, pas de paiement réel)
            TikTokManager.shared.trackStartTrial(productId: productId)
            PostHogManager.shared.trackTrialStarted(productId: productId)
        } else {
            // Vrai paiement → Subscribe
            TikTokManager.shared.trackSubscribe(productId: productId, price: priceDouble, currency: currency)
            PostHogManager.shared.trackPurchase(productId: productId, price: priceDouble, currency: currency)
        }
    }

    func trackRestorePurchases(success: Bool, productIds: [String]?) {
        var properties: [String: any Any] = [
            "success": success
        ]

        if let ids = productIds {
            properties["restored_products"] = ids.joined(separator: ",")
        }

        track(event: "purchases_restored", properties: properties)
    }

    // MARK: - Auth View Tracking

    func trackAuthViewDisplayed() {
        track(event: "auth_view_displayed")
    }

    func trackLoginViewDisplayed() {
        track(event: "login_view_displayed")
    }

    func trackSignupViewDisplayed() {
        track(event: "signup_view_displayed")
    }
}
