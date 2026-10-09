//
//  PlanCycle.swift
//  CortiFree
//
//  What happens after the first 28 days (docs/app-notes/RETENTION_POST_28_DAYS_PLAN.md):
//  every cycle has a meaning (Apaiser → Ancrer → Autonomie → Entretien, endless), the end
//  of a cycle is reviewed (« Ton bilan des 28 jours ») and the next cycle starts on its own.
//
//  Everything here is pure (no store, no UI) so it can be unit-tested.
//

import Foundation

// MARK: - Cycle themes

enum PlanCycleTheme: String, Codable, CaseIterable {
    case soothe       // Cycle 1 – Apaiser (the original plan)
    case anchor       // Cycle 2 – Ancrer: slightly longer sessions, new breathing techniques
    case autonomy     // Cycle 3 – Autonomie: the user picks more, fewer imposed items
    case maintenance  // Cycle 4+ – Entretien: ~10 min/day, rotating weekly themes, endless

    static func forCycle(_ cycle: Int) -> PlanCycleTheme {
        switch cycle {
        case ...1: return .soothe
        case 2: return .anchor
        case 3: return .autonomy
        default: return .maintenance
        }
    }

    var localizedTitle: String { "plan.cycle_theme.\(rawValue).title".localized }
    var localizedSubtitle: String { "plan.cycle_theme.\(rawValue).subtitle".localized }
    /// Three short lines « what changes in this cycle ».
    var localizedChanges: [String] { (1...3).map { "plan.cycle_theme.\(rawValue).change\($0)".localized } }

    var symbol: String {
        switch self {
        case .soothe: return "leaf.fill"
        case .anchor: return "figure.mind.and.body"
        case .autonomy: return "hand.point.up.left.fill"
        case .maintenance: return "infinity"
        }
    }
}

/// Weekly themes of the maintenance cycles (4+), rotating forever.
enum PlanMaintenanceTheme: String, CaseIterable {
    case sleep, focus, relations, energy

    var goal: PlanGoal {
        switch self {
        case .sleep: return .sleep
        case .focus: return .focus
        case .relations: return .emotional
        case .energy: return .energy
        }
    }

    /// Theme of a week (1...4) of a maintenance cycle: keeps rotating from one cycle to the next.
    static func forWeek(_ week: Int, cycle: Int) -> PlanMaintenanceTheme {
        let index = (max(0, cycle - 4) * 4 + max(1, week) - 1) % allCases.count
        return allCases[index]
    }

    var localizedTitle: String { "plan.maintenance.\(rawValue).title".localized }
    var localizedSubtitle: String { "plan.maintenance.\(rawValue).subtitle".localized }
}

/// Generation options that come from the previous cycles (kept in PlanPreferences so a
/// rebuild inside the cycle keeps them).
struct PlanCycleOptions: Equatable {
    /// Content used in the previous cycle: proposed again only when nothing else fits.
    var avoidRefIDs: Set<String> = []
    /// Habits the user acquired: they leave the plan to make room for a new one.
    var retiredHabits: Set<String> = []
    /// Little progress in the previous cycle: gentler ramp.
    var gentle = false
}

// MARK: - Cycle review (bilan)

struct PlanHabitRate: Equatable {
    let habitID: String
    let scheduled: Int
    let done: Int
    var rate: Double { scheduled > 0 ? Double(done) / Double(scheduled) : 0 }
}

/// Felt stress from the daily check-in (1 = calm … 5 = very stressed), averaged per plan week.
struct PlanStressTrend: Equatable {
    /// Weeks 1…4; nil when the week has too few check-ins to mean something.
    var weeks: [Double?] = Array(repeating: nil, count: 4)

    var start: Double? { weeks.first ?? nil }
    var end: Double? { weeks.last ?? nil }

    /// Relative change week 1 → week 4, in percent (negative = less stress). Nil without both ends.
    var changePercent: Int? {
        guard let start, let end, start > 0 else { return nil }
        return Int(((end - start) / start * 100).rounded())
    }
}

struct PlanCycleStats: Equatable {
    let cycle: Int
    let goal: PlanGoal
    /// Plan days with at least one validated item.
    let activeDays: Int
    /// Breathing exercises and guided sessions done.
    let sessionsCompleted: Int
    let minutesPracticed: Int
    /// Longest run of consecutive active plan days.
    let bestStreak: Int
    /// Habits of the plan, best kept first.
    let habits: [PlanHabitRate]
    /// Most completed kind of practice: "breathing" or an AudioSessionCategory raw value.
    let topPractice: String?
    let stress: PlanStressTrend
}

/// What to do next, from the cycle's results.
struct PlanNextCycleSuggestion: Equatable {
    enum Reason: String { case bigProgress = "big_progress", progress, littleProgress = "little_progress", noData = "no_data" }
    let goal: PlanGoal
    let gentle: Bool
    let reason: Reason
}

enum PlanCycleReview {
    /// A habit kept at least this often over a cycle is « acquired ».
    static let acquiredThreshold = 0.8
    /// …and it must have been proposed often enough for that to mean something.
    static let acquiredMinimumScheduled = 8
    /// Stress drop (percent) above which we suggest moving on to another goal.
    static let bigProgressDrop = -25
    /// Below this drop (or less than `lowActivityDays` active days), the next cycle is gentler.
    static let littleProgressDrop = -10
    static let lowActivityDays = 10

    /// - Parameters:
    ///   - done: validated status keys ("plan_breathing", "plan_habit_water"…) per plan day.
    ///   - stress: daily check-in stress (1…5) per plan day.
    static func stats(plan: PersonalPlan, done: [Int: Set<String>], stress: [Int: Int]) -> PlanCycleStats {
        var sessions = 0
        var minutes = 0
        var practice: [String: Int] = [:]
        var scheduled: [String: Int] = [:]
        var habitDone: [String: Int] = [:]
        var activeDays = Set<Int>()

        for day in plan.days {
            let keys = done[day.dayNumber] ?? []
            if !keys.isEmpty { activeDays.insert(day.dayNumber) }
            for item in day.items {
                let isDone = keys.contains(item.statusKey)
                switch item.kind {
                case .habit:
                    scheduled[item.refID, default: 0] += 1
                    if isDone { habitDone[item.refID, default: 0] += 1 }
                case .breathing:
                    guard isDone else { continue }
                    sessions += 1
                    minutes += item.minutes
                    practice["breathing", default: 0] += 1
                case .audio, .evening:
                    guard isDone else { continue }
                    sessions += 1
                    minutes += item.minutes
                    let category = GuidedSessionCatalog.session(id: item.refID)?.category.rawValue ?? "audio"
                    practice[category, default: 0] += 1
                }
            }
        }

        var best = 0, run = 0
        for day in 1...PersonalPlan.length {
            run = activeDays.contains(day) ? run + 1 : 0
            best = max(best, run)
        }

        let rates: [PlanHabitRate] = scheduled.keys.map { id in
            PlanHabitRate(habitID: id, scheduled: scheduled[id] ?? 0, done: habitDone[id] ?? 0)
        }
        let habits = rates.sorted(by: Self.habitOrder)
        let top: String? = practice.max { (a: (key: String, value: Int), b: (key: String, value: Int)) -> Bool in
            if a.value != b.value { return a.value < b.value }
            return a.key > b.key
        }?.key

        return PlanCycleStats(
            cycle: plan.cycle, goal: plan.goal, activeDays: activeDays.count,
            sessionsCompleted: sessions, minutesPracticed: minutes, bestStreak: best,
            habits: habits, topPractice: top,
            stress: stressTrend(stress)
        )
    }

    /// Best kept first (rate, then count, then id for a stable order).
    private static func habitOrder(_ a: PlanHabitRate, _ b: PlanHabitRate) -> Bool {
        if a.rate != b.rate { return a.rate > b.rate }
        if a.done != b.done { return a.done > b.done }
        return a.habitID < b.habitID
    }

    /// A week needs this many daily check-ins for its average to count.
    static let minimumCheckInsPerWeek = 2

    /// Average felt stress of each plan week (days 1–7, 8–14, 15–21, 22–28).
    static func stressTrend(_ stress: [Int: Int]) -> PlanStressTrend {
        let weeks: [Double?] = (0..<4).map { week in
            let values = (week * 7 + 1...week * 7 + 7).compactMap { stress[$0] }
            guard values.count >= minimumCheckInsPerWeek else { return nil }
            return Double(values.reduce(0, +)) / Double(values.count)
        }
        return PlanStressTrend(weeks: weeks)
    }

    /// Habits kept ≥ 80 % over the cycle (and proposed at least `acquiredMinimumScheduled` times).
    static func acquiredHabits(_ stats: PlanCycleStats) -> [String] {
        stats.habits
            .filter { $0.scheduled >= acquiredMinimumScheduled && $0.rate >= acquiredThreshold }
            .map(\.habitID)
    }

    /// Big stress drop → another goal (sleep or focus); little progress → same goal, gentler.
    static func suggestion(for stats: PlanCycleStats, secondaryGoal: PlanGoal) -> PlanNextCycleSuggestion {
        if let change = stats.stress.changePercent {
            if change <= bigProgressDrop {
                return PlanNextCycleSuggestion(goal: nextGoal(after: stats.goal, secondary: secondaryGoal), gentle: false, reason: .bigProgress)
            }
            if change > littleProgressDrop || stats.activeDays < lowActivityDays {
                return PlanNextCycleSuggestion(goal: stats.goal, gentle: true, reason: .littleProgress)
            }
            return PlanNextCycleSuggestion(goal: stats.goal, gentle: false, reason: .progress)
        }
        if stats.activeDays < lowActivityDays {
            return PlanNextCycleSuggestion(goal: stats.goal, gentle: true, reason: .littleProgress)
        }
        return PlanNextCycleSuggestion(goal: stats.goal, gentle: false, reason: .noData)
    }

    private static func nextGoal(after goal: PlanGoal, secondary: PlanGoal) -> PlanGoal {
        switch goal {
        case .sleep: return .focus
        case .focus: return .sleep
        default: return secondary == .focus ? .focus : .sleep
        }
    }

    /// Every content id of a plan (to avoid repeating it in the next cycle).
    static func usedRefIDs(_ plan: PersonalPlan) -> Set<String> {
        Set(plan.days.flatMap { day in
            day.items.filter { $0.kind != .habit }.flatMap { [$0.refID, $0.shortRefID].compactMap { $0 } }
        })
    }
}
