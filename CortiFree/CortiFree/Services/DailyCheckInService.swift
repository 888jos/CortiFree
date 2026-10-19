import Foundation

@MainActor
final class DailyCheckInService {
    static let shared = DailyCheckInService()
    private let promptedDayKey = "daily_check_in_last_prompted_day"
    private let completedDayKey = "daily_check_in_last_completed_day"
    private let completedDaysKey = "daily_check_in_completed_days"
    private init() {}

    /// The check-in is the recap of one day, in the user's own time zone (Calendar.current):
    /// from 21:00 it asks about today; before 21:00 (from midnight) it asks about yesterday,
    /// when yesterday's was not done. Each recap opens once by itself (first app open in its
    /// window); after « Not now » it stays on Home until done or until the next window.
    static let eveningHour = 21

    /// The day the check-in is about right now, or nil when there is nothing to fill in.
    func pendingDay(now: Date = Date()) -> Date? {
        guard UserPersistence.hasCompletedOnboarding,
              UnifiedFirebaseService.shared.auth.currentUser != nil else { return nil }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)
        let day: Date
        if calendar.component(.hour, from: now) >= Self.eveningHour {
            // Not on the evening of the day the program starts: the onboarding just ended.
            guard !isProgramFirstDay(today) else { return nil }
            day = today
        } else {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today) else { return nil }
            day = yesterday
        }
        guard !hasCompleted(on: day), !isBeforeProgram(day) else { return nil }
        return day
    }

    /// Opens by itself once per recap day.
    func shouldPresent(now: Date = Date()) -> Bool {
        guard let day = pendingDay(now: now) else { return false }
        return UserDefaults.standard.string(forKey: promptedDayKey) != dayKey(for: day)
    }

    /// The drawer already opened for this day and was left: Home shows the reminder card.
    func shouldShowHomeCard(now: Date = Date()) -> Bool {
        guard let day = pendingDay(now: now) else { return false }
        return UserDefaults.standard.string(forKey: promptedDayKey) == dayKey(for: day)
    }

    func hasCompleted(on date: Date) -> Bool {
        let key = dayKey(for: date)
        return completedDays.contains(key) || UserDefaults.standard.string(forKey: completedDayKey) == key
    }

    func markPrompted(for day: Date) {
        UserDefaults.standard.set(dayKey(for: day), forKey: promptedDayKey)
        NotificationCenter.default.post(name: Self.stateChanged, object: nil)
    }

    static let stateChanged = NSNotification.Name("DailyCheckInStateChanged")

    private var completedDays: [String] { UserDefaults.standard.stringArray(forKey: completedDaysKey) ?? [] }

    private func markCompleted(_ day: Date) {
        let key = dayKey(for: day)
        UserDefaults.standard.set(key, forKey: completedDayKey)
        UserDefaults.standard.set(Array((completedDays.filter { $0 != key } + [key]).suffix(14)), forKey: completedDaysKey)
    }

    private func isBeforeProgram(_ day: Date) -> Bool {
        guard let settings = UserSettings.loadFromUserDefaults() else { return false }
        return Calendar.current.startOfDay(for: day) < Calendar.current.startOfDay(for: settings.programStartDate)
    }

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
        markCompleted(start)
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
