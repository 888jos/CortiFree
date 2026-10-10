//
//  AnalyticsICP.swift
//  CortiFree
//
//  Who the users are (ideal customer profile): the onboarding answers as Amplitude user
//  properties (« icp_* ») and one event per quiz, so the dashboard can show the profile of
//  the users and how each segment converts (paywall, trial, purchase). Codes, not
//  translated texts, for the overall quiz; English answer texts for the habits quiz.
//

import Foundation

enum AnalyticsICP {
    /// Overall quiz: age range, gender, why they came, for how long.
    static func overallCompleted(_ data: OverallQuizData) {
        let properties: [String: Any] = [
            "icp_age": data.ageCode,
            "icp_gender": data.genderCode,
            "icp_stress_reasons": data.reasonCodes,
            "icp_main_reason": data.reasonCodes.first ?? "none",
            "icp_reason_count": data.reasonCodes.count,
            "icp_stress_duration": data.durationCode
        ]
        send("onboarding_profile_completed", properties)
    }

    /// Habits quiz: each answer (English) and the domain scores.
    static func habitsCompleted(_ result: HabitsQuizResult) {
        let questions = getAllHabitsQuestions()
        var properties: [String: Any] = [
            "icp_global_score": result.globalScore,
            "icp_stress_score": result.stressScore,
            "icp_sleep_score": result.sleepScore,
            "icp_energy_score": result.energyScore,
            "icp_focus_score": result.focusScore,
            "icp_primary_goal": result.primaryGoal,
            "icp_available_minutes": result.availableTime
        ]
        for (index, answer) in result.answers.enumerated() {
            guard let question = questions[safe: index], let option = question.options[safe: answer] else { continue }
            properties["icp_habit_q\(index + 1)"] = LanguageManager.shared.englishText(forDisplayed: option)
        }
        send("onboarding_habits_profile_completed", properties)
    }

    /// Symptom checker: which symptoms were ticked.
    static func symptomsSelected(_ symptoms: Set<String>) {
        send("onboarding_symptoms_profile_completed", [
            // The checker hands back the texts shown on screen: English for every language.
            "icp_symptoms": symptoms.map(LanguageManager.shared.englishText(forDisplayed:)).sorted(),
            "icp_symptom_count": symptoms.count
        ])
    }

    private static func send(_ event: String, _ properties: [String: Any]) {
        AmplitudeManager.shared.setUserProperties(properties)
        var eventProperties = properties
        eventProperties["onboarding_version"] = OnboardingV2FlowView.analyticsVersion
        AnalyticsManager.shared.track(event: event, properties: eventProperties)
    }
}
