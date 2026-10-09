//
//  PlanCompletionLoader.swift
//  CortiFree
//
//  Validated plan items per plan day, outside the Plan tab (cycle review, automatic next
//  cycle). Same sources as TasksV2View: Convex task statuses (keyed by absolute program day)
//  plus this device's completions; a status stored remotely always wins.
//

import Foundation

@MainActor
enum PlanCompletionLoader {
    /// Done status keys ("plan_breathing", "plan_habit_water"…) per plan day (1...28).
    static func doneKeys(for plan: PersonalPlan) async -> [Int: Set<String>] {
        let uid = Auth.auth().currentUser?.uid
        var settings = UserSettings.loadFromUserDefaults()
        var statuses: [String: [String: String]] = [:]
        if let uid {
            if let remote = try? await FirebaseManager.shared.fetchUserSettings(uid: uid) { settings = remote }
            statuses = (try? await TaskStatusService.shared.loadAllTaskStatuses()) ?? [:]
        }
        for completion in LocalProgressStore.load(for: uid ?? UserPersistence.localUserID) {
            let key = "day_\(completion.programDay)"
            if statuses[key]?[completion.taskID] == nil {
                statuses[key, default: [:]][completion.taskID] = "done"
            }
        }
        let absoluteToday = settings?.currentProgramDay ?? 1
        return doneKeys(for: plan, statuses: statuses, absoluteToday: absoluteToday)
    }

    /// Plan day d was absolute program day `absoluteToday - (planToday - d)` (like TasksV2View).
    nonisolated static func doneKeys(for plan: PersonalPlan, statuses: [String: [String: String]],
                                     absoluteToday: Int, now: Date = Date()) -> [Int: Set<String>] {
        let planToday = plan.dayIndex(on: now)
        var result: [Int: Set<String>] = [:]
        for day in 1...PersonalPlan.length {
            let absolute = absoluteToday - (planToday - day)
            guard absolute >= 1, let tasks = statuses["day_\(absolute)"] else { continue }
            let done = Set(tasks.filter { $0.value == "done" }.keys)
            if !done.isEmpty { result[day] = done }
        }
        return result
    }
}
