//
//  StreakService.swift
//  CortiFree
//
//  Single source for the streak shown everywhere (Home, Plan, Profile, Progress, widget,
//  reminders). Rule: consecutive program days with at least one validated plan item; today
//  without a validation yet doesn't break the streak. A status stored on the server (done,
//  skipped, undone) always wins over this device's local completions, exactly like the Plan tab.
//
//  Recomputed at launch, on every return to the app and at midnight. The stored value carries
//  the day it was computed, so a missed day reads as 0 even before the next recompute.
//

import Foundation

@MainActor
final class StreakService {
    static let shared = StreakService()

    private var refreshTask: Task<Void, Never>?

    private init() {
        NotificationCenter.default.addObserver(forName: .NSCalendarDayChanged, object: nil, queue: .main) { _ in
            Task { @MainActor in StreakService.shared.refresh() }
        }
    }

    private static let asOfKey = "streakDays.asOf"

    /// The streak to display: the stored one, or 0 once a whole day was missed since it was computed.
    static var current: Int {
        let defaults = UserDefaults.standard
        let streak = defaults.integer(forKey: "streakDays")
        guard streak > 0, let asOf = defaults.string(forKey: asOfKey) else { return streak }
        let calendar = Calendar.current
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: Date())) else { return streak }
        return asOf >= dayKey(yesterday) ? streak : 0
    }

    func refresh() {
        guard refreshTask == nil else { return }
        refreshTask = Task {
            defer { refreshTask = nil }
            let uid = Auth.auth().currentUser?.uid
            var settings = UserSettings.loadFromUserDefaults()
            var statuses: [String: [String: String]] = [:]

            if let uid {
                if let remote = try? await FirebaseManager.shared.fetchUserSettings(uid: uid) { settings = remote }
                guard let remote = try? await TaskStatusService.shared.loadAllTaskStatuses() else {
                    // Offline: don't overwrite a good value with a guess from partial data.
                    return
                }
                statuses = remote
            }
            let local = LocalProgressStore.load(for: uid ?? UserPersistence.localUserID)
            guard let today = settings?.currentProgramDay else { return }
            Self.store(Self.streak(doneDays: Self.doneDays(statuses: statuses, local: local), today: today))
        }
    }

    /// Program days with at least one item done. Local completions only fill keys the server
    /// doesn't know yet (an undo on another device stays an undo).
    static func doneDays(statuses: [String: [String: String]], local: [LocalProgressStore.Completion]) -> Set<Int> {
        var merged = statuses
        for completion in local {
            let key = "day_\(completion.programDay)"
            if merged[key]?[completion.taskID] == nil {
                merged[key, default: [:]][completion.taskID] = "done"
            }
        }
        var days = Set<Int>()
        for (key, tasks) in merged where tasks.values.contains("done") {
            if let day = Int(key.replacingOccurrences(of: "day_", with: "")) { days.insert(day) }
        }
        return days
    }

    static func streak(doneDays: Set<Int>, today: Int) -> Int {
        var day = doneDays.contains(today) ? today : today - 1
        var streak = 0
        while day >= 1, doneDays.contains(day) {
            streak += 1
            day -= 1
        }
        return streak
    }

    static func store(_ streak: Int) {
        let defaults = UserDefaults.standard
        defaults.set(streak, forKey: "streakDays")
        defaults.set(dayKey(Date()), forKey: asOfKey)
        if streak > defaults.integer(forKey: "bestStreak") {
            defaults.set(streak, forKey: "bestStreak")
        }
        WidgetInsightsStore.setStreak(streak, best: defaults.integer(forKey: "bestStreak"))
        NotificationCenter.default.post(name: NSNotification.Name("StreakUpdated"), object: nil)
    }

    /// Restart of the program: the streak and its local history start over.
    static func reset(userID: String) {
        LocalProgressStore.clear(for: userID)
        UserDefaults.standard.set(0, forKey: "bestStreak")
        store(0)
    }

    private static func dayKey(_ date: Date) -> String {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }
}
