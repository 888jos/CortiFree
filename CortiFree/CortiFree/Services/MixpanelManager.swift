//
//  MixpanelManager.swift
//  CortiFree
//
//  Mixpanel analytics manager - Complete implementation
//  Token: 54821f0aa53aa5ce3804237815f94332 (EU server)
//

import Foundation
import UIKit
import Mixpanel

class MixpanelManager {
    static let shared = MixpanelManager()

    private var isInitialized = false

    private init() {
        // Initialize will be called explicitly from AppDelegate/App
    }

    // MARK: - Initialization

    func initialize() {
        guard !isInitialized else { return }

        Mixpanel.initialize(
            token: "54821f0aa53aa5ce3804237815f94332",
            trackAutomaticEvents: true,
            serverURL: "https://api-eu.mixpanel.com"
        )

        #if DEBUG
        // Set flush interval to 5 seconds in DEBUG mode
        Mixpanel.mainInstance().flushInterval = 5
        print("[Mixpanel] 🔧 DEBUG mode: Flush interval set to 5 seconds")
        #endif

        // Set super properties (sent with every event)
        registerSuperProperties()

        isInitialized = true
        #if DEBUG
        print("[Mixpanel] ✅ Initialized successfully with EU server")
        #endif

        // Send a test event to verify connection
        track(event: "app_opened")

        // Force flush immediately for testing
        Mixpanel.mainInstance().flush()
    }

    private func registerSuperProperties() {
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        let osVersion = UIDevice.current.systemVersion
        let deviceType = UIDevice.current.model
        let language = Locale.current.language.languageCode?.identifier ?? "unknown"

        Mixpanel.mainInstance().registerSuperProperties([
            "app_version": appVersion,
            "os_version": osVersion,
            "device_type": deviceType,
            "language": language,
            "platform": "iOS"
        ])
    }

    // MARK: - User Identification & Properties

    func identify(userId: String) {
        Mixpanel.mainInstance().identify(distinctId: userId)
    }

    func setUserProfile(
        firstName: String?,
        email: String?,
        age: Int?,
        gender: String?,
        globalScore: Int?,
        primaryGoal: String?
    ) {
        var properties: [String: MixpanelType] = [:]

        if let firstName = firstName {
            properties["$name"] = firstName
            properties["first_name"] = firstName
        }
        if let email = email {
            properties["$email"] = email
        }
        if let age = age {
            properties["age"] = age
        }
        if let gender = gender {
            properties["gender"] = gender
        }
        if let globalScore = globalScore {
            properties["global_score"] = globalScore
        }
        if let primaryGoal = primaryGoal {
            properties["primary_goal"] = primaryGoal
        }

        properties["onboarding_completion_date"] = Date()

        Mixpanel.mainInstance().people.set(properties: properties)
    }

    func updateUserProgress(
        currentDay: Int?,
        currentStreak: Int?,
        totalTasksCompleted: Int?,
        globalScore: Int?,
        totalAchievements: Int?
    ) {
        var properties: [String: MixpanelType] = [:]

        if let currentDay = currentDay {
            properties["current_program_day"] = currentDay
        }
        if let currentStreak = currentStreak {
            properties["current_streak"] = currentStreak
        }
        if let totalTasksCompleted = totalTasksCompleted {
            properties["total_tasks_completed"] = totalTasksCompleted
        }
        if let globalScore = globalScore {
            properties["global_score"] = globalScore
        }
        if let totalAchievements = totalAchievements {
            properties["total_achievements"] = totalAchievements
        }

        Mixpanel.mainInstance().people.set(properties: properties)
    }

    func incrementProperty(property: String, by amount: Double = 1) {
        Mixpanel.mainInstance().people.increment(property: property, by: amount)
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
        baselineWakeTime: String?,
        baselineSleepDuration: Double?,
        baselineWaterIntake: Double?,
        baselineExerciseFrequency: Int?,
        baselineMeditationFrequency: Int?,
        baselineAvailableTime: String?,
        hasPhysicalLimitations: Bool?,
        primaryGoal: String?
    ) {
        track(event: "onboarding_habits_quiz_clicked")
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

        var properties: [String: MixpanelType] = [
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

    private func track(event: String, properties: [String: any MixpanelType]? = nil) {
        Mixpanel.mainInstance().track(event: event, properties: properties)

        #if DEBUG
        if let props = properties, !props.isEmpty {
            print("[Mixpanel] 📊 Event: \(event) | Properties: \(props)")
        } else {
            print("[Mixpanel] 📊 Event: \(event)")
        }

        // Force immediate flush in DEBUG mode for testing
        Mixpanel.mainInstance().flush()
        print("[Mixpanel] 💾 Flush executed for event: \(event)")
        #endif
    }

    func flush() {
        Mixpanel.mainInstance().flush()
    }

    func reset() {
        Mixpanel.mainInstance().reset()
    }

    // MARK: - Purchase Tracking

    func trackPurchase(productId: String, price: Decimal, currency: String) {
        let properties: [String: any MixpanelType] = [
            "product_id": productId,
            "price": NSDecimalNumber(decimal: price).doubleValue,
            "currency": currency,
            "timestamp": Date().timeIntervalSince1970
        ]

        track(event: "subscription_purchased", properties: properties)
    }

    func trackRestorePurchases(success: Bool, productIds: [String]?) {
        var properties: [String: any MixpanelType] = [
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
