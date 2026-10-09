//
//  MiloWeeklyCheckIn.swift
//  CortiFree
//
//  A light weekly check-in: at the end of each plan week (or on Sunday), the Plan tab offers
//  to talk the week over with Milo, who opens the conversation with a reflection question.
//

import Foundation

@MainActor
final class MiloWeeklyCheckIn: ObservableObject {
    static let shared = MiloWeeklyCheckIn()

    static let questionCount = 4

    /// Bumped when the card is answered or closed, so the Plan tab hides it.
    @Published private(set) var lastHandled: Date?
    /// Question Milo asks first, consumed by AssistantChatView when it appears.
    private var pendingOpener: String?

    private let defaults = UserDefaults.standard
    private var userKey: String { Auth.auth().currentUser?.uid ?? UserPersistence.localUserID }
    private var handledKey: String { "milo.weeklyCheckIn.handled.v1.\(userKey)" }

    private init() {
        lastHandled = defaults.object(forKey: handledKey) as? Date
    }

    func isDue(planDay: Int, now: Date = Date()) -> Bool {
        Self.isDue(planDay: planDay, now: now, lastHandled: defaults.object(forKey: handledKey) as? Date)
    }

    /// From the end of the first plan week, once a week: on the last day of a plan week or on
    /// Sunday, and never twice within 6 days.
    nonisolated static func isDue(planDay: Int, now: Date, lastHandled: Date?, calendar: Calendar = .current) -> Bool {
        guard planDay >= 7 else { return false }
        if let lastHandled, now.timeIntervalSince(lastHandled) < 6 * 86_400 { return false }
        return planDay % 7 == 0 || calendar.component(.weekday, from: now) == 1
    }

    /// Reflection question of a plan week (rotates).
    nonisolated static func questionKey(week: Int) -> String {
        "milo.weekly.question.\((max(1, week) - 1) % questionCount + 1)"
    }

    /// Opens Milo with the question of the week.
    func start(planDay: Int, cycle: Int, source: String) {
        let week = (planDay - 1) / 7 + 1
        pendingOpener = Self.questionKey(week: week).localized
        markHandled()
        AnalyticsManager.shared.track(event: "milo_weekly_checkin_opened", properties: [
            "plan_day": planDay, "cycle": cycle, "source": source
        ])
        NotificationRouter.shared.pendingAppLink = URL(string: "cortifree://milo")
    }

    func dismiss(planDay: Int) {
        markHandled()
        AnalyticsManager.shared.track(event: "milo_weekly_checkin_dismissed", properties: ["plan_day": planDay])
    }

    func consumeOpener() -> String? {
        defer { pendingOpener = nil }
        return pendingOpener
    }

    private func markHandled() {
        let now = Date()
        defaults.set(now, forKey: handledKey)
        lastHandled = now
    }
}
