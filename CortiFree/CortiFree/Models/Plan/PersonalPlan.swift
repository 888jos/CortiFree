//
//  PersonalPlan.swift
//  CortiFree
//
//  Personalized 28-day plan (replaces the universal 66-day program).
//  The plan is generated once from the onboarding answers (see PersonalPlanGenerator),
//  stored locally (Codable) and mirrored to Firestore users/{uid}/personalized_plan/current.
//  Only identifiers are stored; every title is resolved at render time so the plan
//  follows the app language.
//

import SwiftUI

// MARK: - Goal tracks

enum PlanGoal: String, Codable, CaseIterable, Identifiable {
    case stress      // Stress & anxiety calm
    case sleep       // Better sleep
    case energy      // Energy
    case focus       // Focus
    case emotional   // Emotional balance (difficult period / self-compassion)

    var id: String { rawValue }

    /// Short goal name ("Sommeil").
    var localizedName: String { "plan.goal.\(rawValue).name".localized }
    /// Plan name ("Ton plan Sommeil apaisé").
    var localizedPlanTitle: String { "plan.goal.\(rawValue).plan_title".localized }
    /// One-line promise shown in the goal picker.
    var localizedPromise: String { "plan.goal.\(rawValue).promise".localized }

    var symbol: String {
        switch self {
        case .stress: return "leaf.fill"
        case .sleep: return "moon.stars.fill"
        case .energy: return "sun.max.fill"
        case .focus: return "scope"
        case .emotional: return "heart.fill"
        }
    }

    /// Every goal shares the brand gradient: the goal is told apart by its symbol and
    /// name, so the Plan tab keeps a single, consistent colour identity.
    var colors: [Color] { [PlanPalette.accentDeep, PlanPalette.accent] }
}

// MARK: - Weekly themes

enum PlanWeekTheme: String, Codable, CaseIterable {
    case soothe      // Week 1 – Apaiser
    case rituals     // Week 2 – Installer tes rituels
    case deepen      // Week 3 – Approfondir
    case anchor      // Week 4 – Ancrer

    static func forWeek(_ week: Int) -> PlanWeekTheme {
        switch week {
        case ...1: return .soothe
        case 2: return .rituals
        case 3: return .deepen
        default: return .anchor
        }
    }

    var localizedTitle: String { "plan.week.\(rawValue).title".localized }
    var localizedSubtitle: String { "plan.week.\(rawValue).subtitle".localized }
}

// MARK: - Items

enum PlanItemKind: String, Codable {
    case breathing   // refID = BreathingPattern.key
    case audio       // refID = GuidedSession.id
    case evening     // refID = GuidedSession.id (sleep wind-down)
    case habit       // refID = habit id (sleep, water, sport, nature, social, journal)
}

struct PlanItem: Codable, Identifiable, Hashable {
    /// Stable key inside a day ("breathing", "meditation", "meditation_evening", "habit_water").
    /// Keys are chosen so TaskStatusService.getHabitIdFromTaskTitle maps them to the right habit.
    let id: String
    let kind: PlanItemKind
    let refID: String
    let minutes: Int
    /// Alternative for "Peu de temps aujourd'hui ?" (nil = same item, or hidden for evening).
    let shortRefID: String?
    let shortMinutes: Int?
    /// Habit variant index (sport/nature/social rotation).
    let variant: Int?

    /// Key used in task_statuses (no dots: Firestore field name).
    var statusKey: String { "plan_\(id)" }

    /// Habit id credited when this item is completed (feeds streaks & badges).
    var habitID: String {
        switch kind {
        case .breathing: return "breathing"
        case .audio, .evening: return "meditation"
        case .habit: return refID
        }
    }

    func resolvedRefID(short: Bool) -> String { short ? (shortRefID ?? refID) : refID }
    func resolvedMinutes(short: Bool) -> Int { short ? (shortMinutes ?? minutes) : minutes }
}

struct PlanDay: Codable, Hashable {
    let dayNumber: Int   // 1...28
    let week: Int        // 1...4
    let items: [PlanItem]

    var theme: PlanWeekTheme { .forWeek(week) }
}

// MARK: - Inputs

/// Onboarding answers used to personalize the plan. Every field is optional so
/// missing data (older users, skipped steps) never blocks generation.
struct PlanProfile: Codable, Equatable {
    /// OverallQuiz reasons: sleep / anxiety / energy / focus / mental / difficult / habits.
    var reasonCodes: [String] = []
    /// OverallQuiz duration: weeks / 2_6_months / 6_12_months / 1_year_plus / years.
    var durationCode: String?
    var ageCode: String?
    var genderCode: String?
    /// HabitsQuiz raw answers (12 indexes). Scores are derived internally only.
    var quizAnswers: [Int]?
    /// Symptom ids ("mental.1", "physical.4", "social.2", ...).
    var symptomIDs: [String] = []
    /// Explicit improvement goal when raw answers are unavailable (sleep/stress/energy/focus/balance).
    var improvementGoal: String?
    /// Daily time available (minutes) when raw answers are unavailable.
    var availableMinutes: Int?
    /// Where the data came from: onboarding / migrated / default.
    var source: String = "default"

    var isEmpty: Bool { reasonCodes.isEmpty && quizAnswers == nil && symptomIDs.isEmpty && durationCode == nil && improvementGoal == nil }
}

// MARK: - Edits

/// Who changed the plan after it was generated.
enum PlanEditSource: String, Codable {
    case user        // edited in the Plan tab
    case assistant   // proposed by Milo and accepted by the user
    case adaptation  // automatic adjustment (feedback, anxiety check)
}

enum PlanEditKind: String, Codable {
    case swap, remove, add, goalChange, regenerate
}

/// One change applied to the plan, kept so the plan's history stays explainable
/// ("Milo replaced X by Y on day 4 because…").
struct PlanEdit: Codable, Identifiable, Hashable {
    var id = UUID()
    let date: Date
    let source: PlanEditSource
    let kind: PlanEditKind
    let dayNumber: Int
    let itemID: String?
    let fromRefID: String?
    let toRefID: String?
    let reason: String?
}

/// Choices that survive regeneration (goal change, new cycle).
struct PlanPreferences: Codable, Equatable {
    /// Content ids (breathing keys, session ids, habit ids) the user doesn't want proposed again.
    var excludedRefIDs: Set<String> = []
}

// MARK: - Plan

struct PersonalPlan: Codable, Equatable {
    static let currentVersion = 1
    static let length = 28

    var version: Int = PersonalPlan.currentVersion
    let goal: PlanGoal
    let secondaryGoal: PlanGoal
    /// Long-lasting stress → gentler ramp, more SOS & self-compassion.
    let gentle: Bool
    /// Less than 15 min/day available → compact sessions.
    let compact: Bool
    let startDate: Date
    /// 1 for the first plan, +1 for each follow-up cycle.
    let cycle: Int
    var days: [PlanDay]
    let profile: PlanProfile
    /// Plain-language explanation codes (see PlanInsight).
    let insights: [String]
    let generatedAt: Date
    /// True when the user picked the goal manually.
    let goalChosenByUser: Bool
    /// Changes applied after generation (optional: older stored plans have none).
    var edits: [PlanEdit]?
    var preferences: PlanPreferences?
    /// Last edit date (nil = never edited).
    var updatedAt: Date?

    static func == (lhs: PersonalPlan, rhs: PersonalPlan) -> Bool {
        lhs.startDate == rhs.startDate && lhs.goal == rhs.goal && lhs.cycle == rhs.cycle
            && lhs.generatedAt == rhs.generatedAt && lhs.updatedAt == rhs.updatedAt
    }

    var excludedRefIDs: Set<String> { preferences?.excludedRefIDs ?? [] }

    /// Day index (1-based, not clamped) for a given date.
    func dayIndex(on date: Date = Date()) -> Int {
        let cal = Calendar.current
        let elapsed = cal.dateComponents([.day], from: cal.startOfDay(for: startDate), to: cal.startOfDay(for: date)).day ?? 0
        return max(1, elapsed + 1)
    }

    var isFinished: Bool { dayIndex() > PersonalPlan.length }

    func day(_ number: Int) -> PlanDay? {
        days.first { $0.dayNumber == min(max(1, number), PersonalPlan.length) }
    }

    var localizedTitle: String { goal.localizedPlanTitle }
}
