//
//  OnboardingHabitTargets.swift
//  CortiFree
//
//  Week-4 targets of the eight habits shown in the onboarding (habits progress
//  screen and paywall chart). They scale with the daily time the user chose in the
//  habits quiz, so someone with "less than 15 minutes" is never promised hours.
//

import Foundation

struct OnboardingHabitTarget {
    let icon: String
    /// Habit id, used to build the localization keys.
    let id: String
    /// Four y-axis ticks, lowest first; the last one is the week-4 target.
    let yAxisValues: [String]
    /// "pratiqueras la respiration consciente 35 min par semaine."
    let statMessage: String
    let curveStyle: Int

    var currentValue: String { yAxisValues.last ?? "" }
}

enum OnboardingHabitTargets {
    /// Length of the personal plan, in weeks (PersonalPlan.length = 28 days).
    static let planWeeks = 4

    /// - Parameter availableMinutes: daily minutes from the habits quiz (10, 22, 37, 52 or 75).
    static func targets(availableMinutes: Int?) -> [OnboardingHabitTarget] {
        let budget = availableMinutes ?? 22

        // Daily minutes, then weekly totals for the minute-based habits.
        let breathingPerDay = budget <= 10 ? 3 : (budget <= 22 ? 5 : 8)
        let meditationPerDay = budget <= 10 ? 5 : (budget <= 22 ? 10 : (budget <= 37 ? 15 : 20))
        let sportPerWeek = budget <= 10 ? 45 : (budget <= 22 ? 90 : 150)
        let naturePerWeek = budget <= 10 ? 30 : (budget <= 22 ? 60 : 120)

        return [
            minutesTarget(id: "breathing", icon: "wind", weekly: breathingPerDay * 7, curve: 0),
            minutesTarget(id: "meditation", icon: "figure.mind.and.body", weekly: meditationPerDay * 7, curve: 1),
            countTarget(id: "journal", icon: "book.pages", weeklyTimes: budget <= 10 ? 3 : 5, curve: 2),
            minutesTarget(id: "sport", icon: "figure.walk", weekly: sportPerWeek, curve: 3),
            OnboardingHabitTarget(
                icon: "drop.fill",
                id: "water",
                yAxisValues: ["1.25 L", "1.5 L", "1.75 L", "2 L"],
                statMessage: "onboarding_v2.habits_progress.water_stat".localized,
                curveStyle: 4
            ),
            minutesTarget(id: "nature", icon: "tree.fill", weekly: naturePerWeek, curve: 5),
            OnboardingHabitTarget(
                icon: "moon.zzz.fill",
                id: "sleep",
                yAxisValues: ["6h", "6h30", "7h", "7h30"],
                statMessage: "onboarding_v2.habits_progress.sleep_stat".localized,
                curveStyle: 6
            ),
            countTarget(id: "social", icon: "person.2.fill", weeklyTimes: 3, curve: 7)
        ]
    }

    private static func minutesTarget(id: String, icon: String, weekly: Int, curve: Int) -> OnboardingHabitTarget {
        let ticks = (1...4).map { formatMinutes(weekly * $0 / 4) }
        return OnboardingHabitTarget(
            icon: icon,
            id: id,
            yAxisValues: ticks,
            statMessage: String(format: "onboarding_v2.habits_progress.\(id)_stat_fmt".localized, formatMinutes(weekly)),
            curveStyle: curve
        )
    }

    private static func countTarget(id: String, icon: String, weeklyTimes: Int, curve: Int) -> OnboardingHabitTarget {
        let ticks = (1...4).map { "\(max(1, weeklyTimes * $0 / 4))x" }
        return OnboardingHabitTarget(
            icon: icon,
            id: id,
            yAxisValues: ticks,
            statMessage: String(format: "onboarding_v2.habits_progress.\(id)_stat_fmt".localized, weeklyTimes),
            curveStyle: curve
        )
    }

    /// 35 → "35 min", 90 → "1h30", 120 → "2h".
    static func formatMinutes(_ minutes: Int) -> String {
        guard minutes >= 60 else { return "\(minutes) min" }
        let hours = minutes / 60, rest = minutes % 60
        return rest == 0 ? "\(hours)h" : String(format: "%dh%02d", hours, rest)
    }
}
