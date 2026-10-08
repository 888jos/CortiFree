import Foundation

/// Transitional API kept while views are renamed; all persistence is Convex-backed.
@MainActor
final class FirebaseManager: ObservableObject {
    static let shared = FirebaseManager()
    private let backend = ConvexBackend.shared
    private init() {}

    var currentUser: ConvexUser? { UnifiedFirebaseService.shared.auth.currentUser }

    func updateUserProfile(uid: String, updates: [String: Any]) async throws {
        var args: [String: Any] = [:]
        for key in ["firstName", "displayName", "language"] {
            if let value = updates[key] as? String { args[key] = value }
        }
        if !args.isEmpty {
            let _: JSONValue = try await backend.call(.mutation, path: "profile:updateProfile", args: args)
        }
        if let base64 = updates["profilePhotoBase64"] as? String,
           let data = Data(base64Encoded: base64) {
            let uploadURL: String = try await backend.call(.mutation, path: "profile:generateAvatarUploadUrl")
            let storageId = try await backend.upload(data, to: uploadURL)
            let _: JSONValue = try await backend.call(
                .mutation, path: "profile:setAvatar", args: ["storageId": storageId]
            )
        }
    }

    func saveUserSettings(uid: String, settings: UserSettings) async throws {
        var args: [String: Any] = [
            "programStartDate": settings.programStartDate.timeIntervalSince1970 * 1000,
            "wakeUpTime": settings.wakeUpTime,
            "bedTime": settings.bedTime,
            "preferredSportActivities": settings.preferredSportActivities,
            "preferredNatureActivities": settings.preferredNatureActivities,
            "preferredSocialActivities": settings.preferredSocialActivities,
            "notificationsEnabled": settings.notificationsEnabled,
        ]
        args["morningReminderTime"] = settings.morningReminderTime ?? NSNull()
        args["eveningReminderTime"] = settings.eveningReminderTime ?? NSNull()
        let _: String = try await backend.call(.mutation, path: "settings:save", args: args)
        settings.saveToUserDefaults()
    }

    func fetchUserSettings(uid: String) async throws -> UserSettings? {
        let row: SettingsRow? = try await backend.call(.query, path: "settings:get")
        guard let row else { return nil }
        let settings = UserSettings(
            programStartDate: Date(timeIntervalSince1970: row.programStartDate / 1000),
            wakeUpTime: row.wakeUpTime ?? "07:00",
            bedTime: row.bedTime ?? "23:00",
            preferredSportActivities: row.preferredSportActivities ?? [],
            preferredNatureActivities: row.preferredNatureActivities ?? [],
            preferredSocialActivities: row.preferredSocialActivities ?? [],
            notificationsEnabled: row.notificationsEnabled ?? true,
            morningReminderTime: row.morningReminderTime,
            eveningReminderTime: row.eveningReminderTime
        )
        settings.saveToUserDefaults()
        return settings
    }

    func initializeHabitTracking(uid: String) async throws {
        let _: InitializeResult = try await backend.call(.mutation, path: "habits:initializeTracking")
    }

    func fetchHabitTracking(uid: String, habitId: String) async throws -> HabitTracking? {
        let row: HabitRow? = try await backend.call(
            .query, path: "habits:getTrackingByHabit", args: ["habitId": habitId]
        )
        return row?.model
    }

    func fetchAllHabitTracking(uid: String) async throws -> [String: HabitTracking] {
        let rows: [HabitRow] = try await backend.call(.query, path: "habits:listTracking")
        return Dictionary(uniqueKeysWithValues: rows.map { ($0.habitId, $0.model) })
    }

    func resetProgramDayData(uid: String) async throws {
        let _: JSONValue = try await backend.call(.mutation, path: "tasks:resetProgramData")
    }

    func markHabitCompleted(uid: String, habitId: String, programDay: Int, date: Date = Date()) async throws {
        let _: HabitRow = try await backend.call(.mutation, path: "habits:markCompleted", args: [
            "habitId": habitId,
            "programDay": programDay,
            "date": Self.dayKey(date),
            "completedAt": date.timeIntervalSince1970 * 1000,
        ])
    }

    func removeHabitCompletion(uid: String, habitId: String, programDay: Int, date: Date = Date()) async throws {
        let _: HabitRow? = try await backend.call(.mutation, path: "habits:removeCompletion", args: [
            "habitId": habitId,
            "programDay": programDay,
            "date": Self.dayKey(date),
        ])
    }

    func fetchHabitCompletionHistory(uid: String, habitId: String, days: Int = 7) async throws -> [Bool] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let start = calendar.date(byAdding: .day, value: -(max(1, days) - 1), to: today) ?? today
        let rows: [CompletionRow] = try await backend.call(.query, path: "habits:listCompletions", args: [
            "habitId": habitId, "fromDate": Self.dayKey(start), "toDate": Self.dayKey(today), "limit": days,
        ])
        let completed = Set(rows.filter(\.completed).map(\.date))
        return (0..<days).map { offset in
            let date = calendar.date(byAdding: .day, value: offset, to: start) ?? start
            return completed.contains(Self.dayKey(date))
        }
    }

    func saveDailyMood(userId: String, mood: DailyMood) {
        Task {
            let _: JSONValue? = try? await backend.call(.mutation, path: "checkins:setMood", args: [
                "date": Self.dayKey(mood.date),
                "dayStartAt": Calendar.current.startOfDay(for: mood.date).timeIntervalSince1970 * 1000,
                "mood": mood.mood.rawValue,
            ])
        }
    }

    func fetchTodaysMood(userId: String, completion: @escaping (Mood?) -> Void) {
        Task {
            let rows: [MoodRow] = (try? await backend.call(
                .query, path: "checkins:listMoods", args: ["fromDate": Self.dayKey(Date()), "limit": 1]
            )) ?? []
            let row = rows.first
            await MainActor.run { completion(row.flatMap { Mood(rawValue: $0.mood) }) }
        }
    }

    func fetchRecentMoods(userId: String, days: Int, completion: @escaping ([DailyMood]) -> Void) {
        Task {
            let start = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
            let rows: [MoodRow] = (try? await backend.call(.query, path: "checkins:listMoods", args: [
                "fromDate": Self.dayKey(start), "limit": days,
            ])) ?? []
            let values = rows.compactMap { row -> DailyMood? in
                guard let mood = Mood(rawValue: row.mood) else { return nil }
                return DailyMood(date: Self.date(from: row.date) ?? Date(), mood: mood)
            }
            await MainActor.run { completion(values) }
        }
    }

    private static func dayKey(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private static func date(from key: String) -> Date? {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: key)
    }
}

private struct InitializeResult: Decodable { let created: Int }

private struct SettingsRow: Decodable {
    let programStartDate: Double
    let wakeUpTime: String?
    let bedTime: String?
    let preferredSportActivities: [String]?
    let preferredNatureActivities: [String]?
    let preferredSocialActivities: [String]?
    let notificationsEnabled: Bool?
    let morningReminderTime: String?
    let eveningReminderTime: String?
}

private struct HabitRow: Decodable {
    let habitId: String
    let habitTitle: String
    let currentStreak: Int
    let longestStreak: Int
    let totalCompletions: Int
    let firstCompletedAt: Double?
    let lastCompletedAt: Double?
    let last7Days: [Bool]
    let completedDays: [Int]

    var model: HabitTracking {
        var value = HabitTracking(habitId: habitId, habitTitle: habitTitle)
        value.currentStreak = currentStreak
        value.longestStreak = longestStreak
        value.totalCompletions = totalCompletions
        value.firstCompletedDate = firstCompletedAt.map { Date(timeIntervalSince1970: $0 / 1000) }
        value.lastCompletedDate = lastCompletedAt.map { Date(timeIntervalSince1970: $0 / 1000) }
        value.last7Days = last7Days
        value.completedDays = completedDays
        return value
    }
}

private struct CompletionRow: Decodable { let date: String; let completed: Bool }
private struct MoodRow: Decodable { let date: String; let mood: String }
