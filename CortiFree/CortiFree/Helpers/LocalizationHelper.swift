//
//  LocalizationHelper.swift
//  CortiFree
//
//  Created by Claude on 15/11/2025.
//  Helper for string localization
//

import Foundation

extension String {
    /// Retourne la chaîne localisée correspondant à la clé en utilisant la langue courante du LanguageManager
    var localized: String {
        return LanguageManager.shared.localizedString(for: self)
    }

    /// Retourne la chaîne localisée avec des arguments
    func localized(_ arguments: CVarArg...) -> String {
        let localizedString = LanguageManager.shared.localizedString(for: self)
        return String(format: localizedString, arguments: arguments)
    }
}

// MARK: - Localization Keys

enum LocalizationKey {
    // Onboarding
    static let onboardingWelcomeTitle = "onboarding.welcome.title"
    static let onboardingContinue = "onboarding.continue"
    static let onboarding8HabitsTitle = "onboarding.8habits.title"

    // Tab Bar
    static let tabHome = "tab.home"
    static let tabRoutine = "tab.routine"
    static let tabTasks = "tab.tasks"
    static let tabProfile = "tab.profile"

    // Home
    static let homeGreetingMorning = "home.greeting.morning"
    static let homeGreetingAfternoon = "home.greeting.afternoon"
    static let homeGreetingEvening = "home.greeting.evening"
    static let homeStreak = "home.streak"
    static let homeCortiFreeScore = "home.cortifree_score"

    // Tasks
    static let tasksDay = "tasks.day"
    static let tasksEncouragement = "tasks.encouragement"
    static let tasksTodo = "tasks.todo"
    static let tasksDone = "tasks.done"
    static let tasksSkipped = "tasks.skipped"

    // Habits
    static let habitBreathe = "habit.breathe"
    static let habitMeditate = "habit.meditate"
    static let habitJournal = "habit.journal"
    static let habitSport = "habit.sport"
    static let habitWater = "habit.water"
    static let habitNature = "habit.nature"
    static let habitSleep = "habit.sleep"
    static let habitSocial = "habit.social"

    // Meditation
    static let meditationTitle = "meditation.title"
    static let meditationHowItWorks = "meditation.how_it_works"
    static let meditationScientificData = "meditation.scientific_data"
    static let meditationBenefits = "meditation.benefits"
    static let meditationStartSession = "meditation.start_session"

    // Breathing
    static let breathingTitle = "breathing.title"
    static let breathingStartExercise = "breathing.start_exercise"

    // Common
    static let commonValidate = "common.validate"
    static let commonSkip = "common.skip"
    static let commonNext = "common.next"
    static let commonPrevious = "common.previous"
    static let commonFinish = "common.finish"
    static let commonClose = "common.close"

    // Loading
    static let loadingCalculating = "loading.calculating"
    static let loadingView66DayPlan = "loading.view_66day_plan"
}
