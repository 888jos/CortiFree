import Foundation

@MainActor
final class DailyCheckInService {
    static let shared = DailyCheckInService()
    private let promptedDayKey = "daily_check_in_last_prompted_day"
    private let completedDayKey = "daily_check_in_last_completed_day"
    private init() {}

    /// Opens on the first app open of the day, until today's check-in is done.
    func shouldPresent(on date: Date = Date()) -> Bool {
        guard UserPersistence.hasCompletedOnboarding,
              UnifiedFirebaseService.shared.auth.currentUser != nil,
              !hasCompleted(on: date),
              !isProgramFirstDay(date) else { return false }
        return UserDefaults.standard.string(forKey: promptedDayKey) != dayKey(for: date)
    }

    func hasCompleted(on date: Date = Date()) -> Bool {
        UserDefaults.standard.string(forKey: completedDayKey) == dayKey(for: date)
    }

    func shouldShowHomeShortcut(on date: Date = Date()) -> Bool {
        UserPersistence.hasCompletedOnboarding && UnifiedFirebaseService.shared.auth.currentUser != nil
            && !hasCompleted(on: date)
    }

    func markPrompted(on date: Date = Date()) { UserDefaults.standard.set(dayKey(for: date), forKey: promptedDayKey) }

    func save(mood: Mood, stress: Int, sleep: Int, energy: Int, note: String, for date: Date) async throws {
        guard UnifiedFirebaseService.shared.auth.currentUser != nil else {
            throw ConvexBackendError.signedOut
        }
        let start = Calendar.current.startOfDay(for: date)
        let _: CheckInResult = try await ConvexBackend.shared.call(.mutation, path: "checkins:submit", args: [
            "date": dayKey(for: date),
            "dayStartAt": start.timeIntervalSince1970 * 1000,
            "mood": mood.rawValue,
            "stress": stress,
            "sleep": sleep,
            "energy": energy,
            "note": note.trimmingCharacters(in: .whitespacesAndNewlines),
            "journalPrompt": "daily_checkin.reflection_prompt".localized,
        ])
        let healthDate = Calendar.current.isDateInToday(start) ? Date() : start.addingTimeInterval(12 * 3600)
        await HealthKitService.shared.saveDailyMood(mood, date: healthDate)
        UserDefaults.standard.set(dayKey(for: start), forKey: completedDayKey)
        WidgetInsightsStore.recordCheckIn(moodRaw: mood.rawValue, stress: stress, for: start)
        ProgressAnalyticsService.shared.invalidateDashboardCache()
        NotificationCenter.default.post(name: NSNotification.Name("DailyCheckInSaved"), object: nil)
    }

    /// Not on the day the program starts: the user has just finished onboarding.
    func isProgramFirstDay(_ date: Date = Date()) -> Bool {
        guard let settings = UserSettings.loadFromUserDefaults() else { return false }
        return Calendar.current.startOfDay(for: settings.programStartDate) >= Calendar.current.startOfDay(for: date)
    }

    private func dayKey(for date: Date) -> String { Self.dayFormatter.string(from: date) }
    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter(); formatter.calendar = .current
        formatter.locale = Locale(identifier: "en_US_POSIX"); formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

private struct CheckInResult: Decodable { let journalEntryId: String? }
