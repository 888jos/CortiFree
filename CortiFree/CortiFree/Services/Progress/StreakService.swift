//
//  StreakService.swift
//  CortiFree
//
//  Single source for the streak shown everywhere (Home, Plan, Profile, Progress).
//  Recomputed at launch and on every return to the app, so it never stays stale until the
//  Plan tab is opened. Rule: consecutive program days with at least one validated item;
//  today without a validation yet doesn't break the streak.
//

import Foundation

@MainActor
final class StreakService {
    static let shared = StreakService()
    private init() {}

    private var refreshTask: Task<Void, Never>?

    func refresh() {
        guard refreshTask == nil else { return }
        refreshTask = Task {
            defer { refreshTask = nil }
            let uid = Auth.auth().currentUser?.uid
            var settings = UserSettings.loadFromUserDefaults()
            var doneDays = Set<Int>()

            if let uid {
                if let remote = try? await FirebaseManager.shared.fetchUserSettings(uid: uid) { settings = remote }
                if let statuses = try? await TaskStatusService.shared.loadAllTaskStatuses() {
                    for (key, tasks) in statuses where tasks.values.contains("done") {
                        if let day = Int(key.replacingOccurrences(of: "day_", with: "")) { doneDays.insert(day) }
                    }
                } else {
                    // Offline: don't overwrite a good value with a guess from partial data.
                    return
                }
            }
            for completion in LocalProgressStore.load(for: uid ?? UserPersistence.localUserID) {
                doneDays.insert(completion.programDay)
            }

            guard let today = settings?.currentProgramDay else { return }
            Self.store(Self.streak(doneDays: doneDays, today: today))
        }
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
        if streak > defaults.integer(forKey: "bestStreak") {
            defaults.set(streak, forKey: "bestStreak")
        }
        NotificationCenter.default.post(name: NSNotification.Name("StreakUpdated"), object: nil)
    }
}
