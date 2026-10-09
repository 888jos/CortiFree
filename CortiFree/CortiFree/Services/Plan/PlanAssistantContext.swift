//
//  PlanAssistantContext.swift
//  CortiFree
//
//  Plain-text snapshot of the user's personalized plan for Milo (the assistant).
//  Built from PersonalPlanStore (the plan shown in the Plan tab) and today's local
//  completions, so Milo always talks about the plan the user actually sees.
//

import Foundation

enum PlanAssistantContext {

    @MainActor
    static func current() -> String {
        guard let plan = PersonalPlanStore.shared.plan else {
            return "The user's personalized CortiFree plan is not loaded yet. Do not invent its content."
        }

        let todayIndex = plan.dayIndex()
        let dayNumber = min(todayIndex, PersonalPlan.length)
        let week = (dayNumber - 1) / 7 + 1
        let theme = PlanWeekTheme.forWeek(week)

        let userID = Auth.auth().currentUser?.uid ?? UserPersistence.localUserID
        let doneToday = Set(
            LocalProgressStore.load(for: userID)
                .filter { Calendar.current.isDateInToday($0.completedAt) }
                .map(\.taskID)
        )

        let items = plan.day(dayNumber)?.items ?? []
        let itemLines = items.map { item -> String in
            let display = item.display(week: week, short: false)
            let duration = display.minutes > 0 ? ", \(display.minutes) min" : ""
            let status = doneToday.contains(item.statusKey) ? "done" : "to do"
            return "- [\(PlanDaySlot.slot(for: item).rawValue)] id=\(item.id) \(display.kindLabel): \(display.title)\(duration) (\(status))"
        }.joined(separator: "\n")

        var lines = [
            "User's current CortiFree plan (this is exactly what the Plan tab shows):",
            "Plan: \(plan.localizedTitle). Main goal: \(plan.goal.localizedName). Secondary goal: \(plan.secondaryGoal.localizedName).",
            "Day \(dayNumber) of \(PersonalPlan.length), week \(week) (\(theme.localizedTitle): \(theme.localizedSubtitle)). Cycle \(plan.cycle).",
            "Adjustments: \(plan.gentle ? "gentle pace" : "standard pace")\(plan.compact ? ", compact sessions" : "").",
            "Today's items:",
            itemLines.isEmpty ? "- none" : itemLines
        ]
        // The days ahead, so Milo can point at one when proposing a change.
        let upcoming = stride(from: dayNumber + 1, through: min(dayNumber + 6, PersonalPlan.length), by: 1).compactMap { number -> String? in
            guard let day = plan.day(number) else { return nil }
            let entries = day.items.map { "id=\($0.id) \($0.display(week: day.week, short: false).title)" }
            return "- Day \(number): " + entries.joined(separator: "; ")
        }
        if !upcoming.isEmpty {
            lines.append("Next days:")
            lines.append(contentsOf: upcoming)
        }
        if plan.isFinished {
            lines.append("The 28 days are over: the user can continue with a new cycle or change goal from the Plan tab.")
        }
        lines.append("Use this when the user asks about their plan. Do not invent progress beyond the statuses above.")
        return lines.joined(separator: "\n")
    }
}
