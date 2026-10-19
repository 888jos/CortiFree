//
//  DailyMeditationService.swift
//  CortiFree
//
//  « Meditation of the day »: during the user's first week, the first app open of each day
//  recommends that day's session of the 7-day « First steps » course (day 1, day 2…).
//  Day 1 is the first day the drawer is shown; after day 7 it never shows again.
//

import Foundation

@MainActor
final class DailyMeditationService {
    static let shared = DailyMeditationService()
    static let length = 7

    private let startDayKey = "daily_meditation_start_day"
    private let shownDayKey = "daily_meditation_last_shown_day"
    private init() {}

    /// The 7 sessions of the course, in order (« Day 1 » … « Day 7 »).
    var sessions: [GuidedSession] {
        Array(GuidedSessionCatalog.sessions(in: .firstSteps)
            .filter { $0.id.hasPrefix("first-steps-day") }
            .prefix(Self.length))
    }

    /// 0…6 for today, nil once the first week is over. Before the first showing, today is day 1.
    var dayIndex: Int? {
        let today = Calendar.current.startOfDay(for: Date())
        guard let startKey = UserDefaults.standard.string(forKey: startDayKey),
              let start = Self.dayFormatter.date(from: startKey) else { return 0 }
        let days = Calendar.current.dateComponents([.day], from: start, to: today).day ?? 0
        return (0..<Self.length).contains(days) ? days : nil
    }

    func session(forDay day: Int) -> GuidedSession? {
        sessions.indices.contains(day) ? sessions[day] : nil
    }

    /// First app open of the day, during the first 7 days after onboarding.
    func shouldPresent() -> Bool {
        guard UserPersistence.hasCompletedOnboarding,
              UnifiedFirebaseService.shared.auth.currentUser != nil,
              let day = dayIndex, session(forDay: day) != nil else { return false }
        return UserDefaults.standard.string(forKey: shownDayKey) != Self.dayFormatter.string(from: Date())
    }

    func markShown() {
        let today = Self.dayFormatter.string(from: Date())
        if UserDefaults.standard.string(forKey: startDayKey) == nil {
            UserDefaults.standard.set(today, forKey: startDayKey)
        }
        UserDefaults.standard.set(today, forKey: shownDayKey)
    }

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter(); formatter.calendar = .current
        formatter.locale = Locale(identifier: "en_US_POSIX"); formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
