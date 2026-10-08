import Foundation

@MainActor
final class ProgressAnalyticsService {
    static let shared = ProgressAnalyticsService()

    private let calendar = Calendar.current
    private var dashboardCache: [String: (loadedAt: Date, value: ProgressDashboardData)] = [:]
    private let dashboardCacheLock = NSLock()
    private let dashboardCacheInterval: TimeInterval = 30

    private init() {}

    /// Stores the task completion details used by Progress when the task flow
    /// does not create a legacy CompletedTask model.
    func recordTaskCompletion(
        taskID: String,
        habitID: String,
        programDay: Int,
        durationSeconds: Int,
        completedAt: Date = Date()
    ) async throws {
        let userID = Auth.auth().currentUser?.uid ?? UserPersistence.localUserID

        LocalProgressStore.recordCompletion(
            taskID: taskID,
            habitID: habitID,
            programDay: programDay,
            durationSeconds: durationSeconds,
            completedAt: completedAt,
            userID: userID
        )

        guard Auth.auth().currentUser != nil else { return }

        let data: [String: Any] = [
            "taskId": taskID,
            "habitId": habitID,
            "programDay": programDay,
            "completedAt": completedAt.timeIntervalSince1970 * 1000,
            "durationActualSeconds": max(0, durationSeconds),
            "source": "tasks_v2"
        ]
        let _: String = try await ConvexBackend.shared.call(
            .mutation, path: "tasks:recordCompletion", args: data
        )

        invalidateDashboardCache()
    }

    /// Undoes `recordTaskCompletion` locally and in Convex.
    func removeTaskCompletion(taskID: String, programDay: Int) async throws {
        let userID = Auth.auth().currentUser?.uid ?? UserPersistence.localUserID
        LocalProgressStore.removeCompletion(taskID: taskID, programDay: programDay, userID: userID)
        invalidateDashboardCache()

        guard Auth.auth().currentUser != nil else { return }
        let _: JSONValue = try await ConvexBackend.shared.call(
            .mutation,
            path: "tasks:removeCompletion",
            args: ["taskId": taskID, "programDay": programDay]
        )
        invalidateDashboardCache()
    }

    /// Call after any local write that Progress reads (completions, sessions, check-ins).
    func invalidateDashboardCache() {
        dashboardCacheLock.lock()
        dashboardCache.removeAll()
        dashboardCacheLock.unlock()
    }

    private func cachedDashboard(for userID: String, now: Date) -> ProgressDashboardData? {
        dashboardCacheLock.lock()
        defer { dashboardCacheLock.unlock() }
        guard let cached = dashboardCache[userID],
              now.timeIntervalSince(cached.loadedAt) < dashboardCacheInterval else { return nil }
        return cached.value
    }

    private func storeDashboard(_ dashboard: ProgressDashboardData, for userID: String, now: Date) {
        dashboardCacheLock.lock()
        dashboardCache[userID] = (now, dashboard)
        dashboardCacheLock.unlock()
    }

    func fetchDashboard(userID: String, now: Date = Date()) async throws -> ProgressDashboardData {
        if let cached = cachedDashboard(for: userID, now: now) {
            return cached
        }
        guard Auth.auth().currentUser != nil else {
            return fetchLocalDashboard(userID: userID, now: now)
        }

        let today = calendar.startOfDay(for: now)
        let snapshot: JSONValue = try await ConvexBackend.shared.call(
            .query, path: "progress:analyticsSnapshot"
        )
        guard case .object(let root) = snapshot else { throw ConvexBackendError.invalidResponse }
        let startMilliseconds = root["programStartDate"]?.doubleValue
            ?? root["onboardingCompletedAt"]?.doubleValue
            ?? root["createdAt"]?.doubleValue
            ?? now.timeIntervalSince1970 * 1000
        let programStartDate = min(Date(timeIntervalSince1970: startMilliseconds / 1000), today)
        let elapsedDays = max(
            1,
            (calendar.dateComponents([.day], from: calendar.startOfDay(for: programStartDate), to: today).day ?? 0) + 1
        )
        let taskStatuses = statusSnapshots(root["taskStatuses"])
        let completedTasks = snapshots(root["completedTasks"], timestampKeys: ["completedAt"])
        let habitTracking = snapshots(root["habitTracking"], timestampKeys: ["lastCompletedAt", "updatedAt"])
        let exercises = snapshots(root["exerciseSessions"], timestampKeys: ["completedAt"])
        let moods = snapshots(root["moods"], dateKeys: ["date"])
        let checkIns = snapshots(root["checkins"], dateKeys: ["date"])

        let taskCompletions = parseTaskCompletions(
            taskStatuses,
            programStartDate: programStartDate,
            startDate: programStartDate,
            metricStartDate: programStartDate,
            now: now
        )
        var completedTaskData = parseCompletedTasks(completedTasks)
        completedTaskData.merge(
            parseLocalCompletions(
                LocalProgressStore.load(for: userID),
                since: programStartDate
            )
        )
        let habitTrackingData = parseHabitTracking(habitTracking)
        let mergedTaskCompletions = mergeTaskData(
            taskCompletions,
            completedTaskData,
            habitTrackingData,
            programStartDate: programStartDate
        )
        let exerciseRecords = mergeExerciseRecords(
            parseExercises(exercises),
            parseLocalSessions(LocalActivitySessionStore.load(for: userID))
        )
        let moodScores = parseMoods(moods)
        let days = ProgressAggregation.days(
            programStartDate: programStartDate,
            taskCompletionsByProgramDay: mergedTaskCompletions.byDay,
            exerciseDates: exerciseRecords.map(\.date),
            moodScoresByDate: moodScores,
            checkInDates: parseCheckInDates(checkIns),
            range: elapsedDays,
            now: now,
            calendar: calendar
        )
        let streaks = ProgressAggregation.streaks(from: days)
        let storedBest = UserPersistence.bestStreak
        let storedCurrent = UserPersistence.streakDays
        let visibleContinuityLimit = days.last?.isActive == false
            ? max(0, days.count - 1)
            : days.count
        let currentStreak = streaks.current == visibleContinuityLimit
            ? max(storedCurrent, streaks.current)
            : streaks.current
        let activityMetrics = buildActivityMetrics(
            taskCounts: mergedTaskCompletions.byCategory,
            exerciseRecords: exerciseRecords,
            taskDurations: completedTaskData.durationSecondsByCategory
        )
        let topActivity = activityMetrics
            .filter { $0.sessionCount > 0 }
            .max(by: { $0.sessionCount < $1.sessionCount })?
            .category

        let lastSevenDaysStart = calendar.date(byAdding: .day, value: -6, to: today) ?? today
        let previousSevenDaysStart = calendar.date(byAdding: .day, value: -13, to: today) ?? today
        let checkInTrends = parseCheckInTrends(
            checkIns,
            currentStartDate: lastSevenDaysStart,
            previousStartDate: previousSevenDaysStart
        )

        let dashboard = ProgressDashboardData(
            generatedAt: now,
            programStartDate: programStartDate,
            days: days,
            currentStreak: currentStreak,
            bestStreak: max(storedBest, streaks.best),
            activities: activityMetrics,
            domainTrends: checkInTrends,
            topActivity: topActivity
        )
        storeDashboard(dashboard, for: userID, now: now)
        return dashboard
    }

    private func fetchLocalDashboard(userID: String, now: Date) -> ProgressDashboardData {
        let today = calendar.startOfDay(for: now)
        let localCompletions = LocalProgressStore.load(for: userID)
        let localSessions = LocalActivitySessionStore.load(for: userID)
        let programStartDate = min(
            UserSettings.loadFromUserDefaults()?.programStartDate
                ?? localCompletions.map(\.completedAt).min()
                ?? localSessions.map(\.completedAt).min()
                ?? today,
            today
        )
        let elapsedDays = max(
            1,
            (calendar.dateComponents([.day], from: calendar.startOfDay(for: programStartDate), to: today).day ?? 0) + 1
        )
        let completedTaskData = parseLocalCompletions(localCompletions, since: programStartDate)
        let exerciseRecords = parseLocalSessions(localSessions)
        let days = ProgressAggregation.days(
            programStartDate: programStartDate,
            taskCompletionsByProgramDay: completedTaskData.byProgramDay,
            exerciseDates: exerciseRecords.map(\.date),
            moodScoresByDate: [:],
            range: elapsedDays,
            now: now,
            calendar: calendar
        )
        let streaks = ProgressAggregation.streaks(from: days)
        let activityMetrics = buildActivityMetrics(
            taskCounts: completedTaskData.byCategory,
            exerciseRecords: exerciseRecords,
            taskDurations: completedTaskData.durationSecondsByCategory
        )
        return ProgressDashboardData(
            generatedAt: now,
            programStartDate: programStartDate,
            days: days,
            currentStreak: max(streaks.current, UserPersistence.streakDays),
            bestStreak: max(streaks.best, UserPersistence.bestStreak),
            activities: activityMetrics,
            domainTrends: [],
            topActivity: activityMetrics
                .filter { $0.sessionCount > 0 }
                .max(by: { $0.sessionCount < $1.sessionCount })?.category
        )
    }

    private func snapshots(
        _ value: JSONValue?,
        timestampKeys: Set<String> = [],
        dateKeys: Set<String> = []
    ) -> [QueryDocumentSnapshot] {
        (value?.arrayValue ?? []).compactMap { row in
            guard case .object(let object) = row else { return nil }
            var fields = object.mapValues(\.foundationValue)
            for key in timestampKeys {
                if let milliseconds = object[key]?.doubleValue {
                    fields[key] = Timestamp(date: Date(timeIntervalSince1970: milliseconds / 1000))
                }
            }
            for key in dateKeys {
                if case .string(let value) = object[key],
                   let date = Self.dateKeyFormatter.date(from: value) {
                    fields[key] = Timestamp(date: date)
                }
            }
            let id = (fields["_id"] as? String) ?? UUID().uuidString
            return QueryDocumentSnapshot(documentID: id, fields: fields)
        }
    }

    private func statusSnapshots(_ value: JSONValue?) -> [QueryDocumentSnapshot] {
        (value?.arrayValue ?? []).compactMap { row in
            guard case .object(let object) = row,
                  let day = object["programDay"]?.doubleValue.map(Int.init) else { return nil }
            var fields: [String: Any] = [:]
            if case .object(let statuses) = object["statuses"] {
                for (key, status) in statuses { fields[key] = status.foundationValue }
            }
            if let milliseconds = object["updatedAt"]?.doubleValue {
                fields["lastUpdated"] = Timestamp(date: Date(timeIntervalSince1970: milliseconds / 1000))
            }
            return QueryDocumentSnapshot(documentID: "day_\(day)", fields: fields)
        }
    }

    private static let dateKeyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private func resolveProgramStartDate(
        from document: DocumentSnapshot,
        userData: [String: Any],
        now: Date
    ) -> Date {
        if let timestamp = document.data()["programStartDate"] as? Timestamp {
            return timestamp.dateValue()
        }
        if let settings = UserSettings.loadFromUserDefaults() {
            return settings.programStartDate
        }
        if let routineStartDate = UserPersistence.routineStartDate {
            return routineStartDate
        }
        if let onboardingDate = userData["onboardingCompletedAt"] as? Timestamp {
            return onboardingDate.dateValue()
        }
        if let createdAt = userData["createdAt"] as? Timestamp {
            return createdAt.dateValue()
        }
        return now
    }

    private func parseTaskCompletions(
        _ documents: [QueryDocumentSnapshot],
        programStartDate: Date,
        startDate: Date,
        metricStartDate: Date,
        now: Date
    ) -> (
        byDay: [Int: Int],
        byCategory: [ProgressActivityCategory: Int]
    ) {
        var byDay: [Int: Int] = [:]
        var byCategory: [ProgressActivityCategory: Int] = [:]

        for document in documents {
            guard let day = Int(document.documentID.replacingOccurrences(of: "day_", with: "")) else { continue }
            guard let completionDate = calendar.date(byAdding: .day, value: day - 1, to: calendar.startOfDay(for: programStartDate)),
                  completionDate >= calendar.startOfDay(for: startDate),
                  completionDate <= calendar.startOfDay(for: now) else { continue }
            // Left over from before a program restart (same day key, older program).
            if let lastUpdated = (document.data()["lastUpdated"] as? Timestamp)?.dateValue(),
               lastUpdated < calendar.startOfDay(for: programStartDate) { continue }
            var doneCount = 0

            for (title, value) in document.data() where title != "lastUpdated" {
                guard value as? String == "done" else { continue }
                doneCount += 1
                if completionDate >= calendar.startOfDay(for: metricStartDate) {
                    byCategory[category(for: title), default: 0] += 1
                }
            }
            byDay[day] = doneCount
        }

        return (byDay, byCategory)
    }

    private struct ExerciseRecord {
        let id: String
        let exerciseID: String
        let date: Date
        let category: ProgressActivityCategory
        let durationSeconds: Int
    }

    private struct CompletedTaskData {
        var byProgramDay: [Int: Int] = [:]
        var byDate: [Date: Int] = [:]
        var byCategory: [ProgressActivityCategory: Int] = [:]
        var durationSecondsByCategory: [ProgressActivityCategory: Int] = [:]

        mutating func merge(_ other: CompletedTaskData) {
            for (day, count) in other.byProgramDay {
                byProgramDay[day] = max(byProgramDay[day, default: 0], count)
            }
            for (date, count) in other.byDate {
                byDate[date] = max(byDate[date, default: 0], count)
            }
            for (category, count) in other.byCategory {
                byCategory[category] = max(byCategory[category, default: 0], count)
            }
            for (category, duration) in other.durationSecondsByCategory {
                durationSecondsByCategory[category] = max(
                    durationSecondsByCategory[category, default: 0],
                    duration
                )
            }
        }
    }

    private struct HabitTrackingData {
        var byProgramDay: [Int: Int] = [:]
        var byCategory: [ProgressActivityCategory: Int] = [:]
    }

    private func parseExercises(_ documents: [QueryDocumentSnapshot]) -> [ExerciseRecord] {
        documents.compactMap { document in
            let data = document.data()
            guard let timestamp = data["completedAt"] as? Timestamp else { return nil }
            let type = (data["exerciseType"] as? String) ?? (data["exerciseId"] as? String) ?? ""
            let exerciseID = (data["exerciseId"] as? String) ?? type
            let duration = (data["duration"] as? Int)
                ?? (data["durationActualSeconds"] as? Int)
                ?? Int(data["duration"] as? Double ?? 0)
            return ExerciseRecord(
                id: (data["localSessionId"] as? String) ?? document.documentID,
                exerciseID: exerciseID,
                date: timestamp.dateValue(),
                category: category(for: type),
                durationSeconds: max(0, duration)
            )
        }
    }

    private func parseLocalSessions(
        _ sessions: [LocalActivitySessionStore.Session]
    ) -> [ExerciseRecord] {
        sessions.map {
            ExerciseRecord(
                id: $0.id,
                exerciseID: $0.exerciseID,
                date: $0.completedAt,
                category: $0.category,
                durationSeconds: $0.durationSeconds
            )
        }
    }

    private func mergeExerciseRecords(
        _ remote: [ExerciseRecord],
        _ local: [ExerciseRecord]
    ) -> [ExerciseRecord] {
        var merged = remote
        let remoteIDs = Set(remote.map(\.id))
        merged.append(contentsOf: local.filter { !remoteIDs.contains($0.id) })
        return merged
    }

    private func parseCompletedTasks(
        _ documents: [QueryDocumentSnapshot]
    ) -> CompletedTaskData {
        var result = CompletedTaskData()

        for document in documents {
            let data = document.data()
            guard let timestamp = data["completedAt"] as? Timestamp else { continue }
            let date = calendar.startOfDay(for: timestamp.dateValue())
            if let programDay = data["programDay"] as? Int, programDay > 0 {
                result.byProgramDay[programDay, default: 0] += 1
            }
            result.byDate[date, default: 0] += 1

            let rawType = (data["exerciseId"] as? String)
                ?? (data["habitId"] as? String)
                ?? (data["taskId"] as? String)
                ?? ""
            let taskCategory = category(for: rawType)
            result.byCategory[taskCategory, default: 0] += 1

            let duration = (data["durationActualSeconds"] as? Int)
                ?? (data["duration"] as? Int)
                ?? 0
            if duration > 0 {
                result.durationSecondsByCategory[taskCategory, default: 0] += duration
            }
        }

        return result
    }

    private func parseLocalCompletions(
        _ completions: [LocalProgressStore.Completion],
        since programStartDate: Date
    ) -> CompletedTaskData {
        var result = CompletedTaskData()
        // Program days restart at 1 after a program restart: older completions would land on the new days.
        let programStart = calendar.startOfDay(for: programStartDate)

        for completion in completions where completion.programDay > 0 && completion.completedAt >= programStart {
            result.byProgramDay[completion.programDay, default: 0] += 1
            let date = calendar.startOfDay(for: completion.completedAt)
            result.byDate[date, default: 0] += 1
            let taskCategory = category(for: completion.habitID)
            result.byCategory[taskCategory, default: 0] += 1
            result.durationSecondsByCategory[taskCategory, default: 0] += completion.durationSeconds
        }

        return result
    }

    private func parseHabitTracking(
        _ documents: [QueryDocumentSnapshot]
    ) -> HabitTrackingData {
        var result = HabitTrackingData()

        for document in documents {
            let data = document.data()
            let habitID = (data["habitId"] as? String) ?? document.documentID
            let taskCategory = category(for: habitID)
            let completedDays = data["completedDays"] as? [Int] ?? []

            for programDay in completedDays where programDay > 0 {
                result.byProgramDay[programDay, default: 0] += 1
                result.byCategory[taskCategory, default: 0] += 1
            }
        }

        return result
    }

    private func mergeTaskData(
        _ statusData: (byDay: [Int: Int], byCategory: [ProgressActivityCategory: Int]),
        _ completedTaskData: CompletedTaskData,
        _ habitTrackingData: HabitTrackingData,
        programStartDate: Date
    ) -> (byDay: [Int: Int], byCategory: [ProgressActivityCategory: Int]) {
        var byDay = statusData.byDay
        var byCategory = statusData.byCategory

        let programStart = calendar.startOfDay(for: programStartDate)
        for (day, count) in completedTaskData.byProgramDay {
            byDay[day] = max(byDay[day, default: 0], count)
        }
        for (date, count) in completedTaskData.byDate {
            let day = (calendar.dateComponents([.day], from: programStart, to: date).day ?? -1) + 1
            guard day > 0 else { continue }
            byDay[day] = max(byDay[day, default: 0], count)
        }
        for (day, count) in habitTrackingData.byProgramDay {
            byDay[day] = max(byDay[day, default: 0], count)
        }
        for (category, count) in completedTaskData.byCategory {
            byCategory[category] = max(byCategory[category, default: 0], count)
        }
        for (category, count) in habitTrackingData.byCategory {
            byCategory[category] = max(byCategory[category, default: 0], count)
        }

        return (byDay, byCategory)
    }

    private func parseCheckInDates(_ documents: [QueryDocumentSnapshot]) -> [Date] {
        documents.compactMap { document in
            guard let timestamp = document.data()["date"] as? Timestamp else { return nil }
            return timestamp.dateValue()
        }
    }

    private func parseMoods(_ documents: [QueryDocumentSnapshot]) -> [Date: Double] {
        var moods: [Date: Double] = [:]
        for document in documents {
            let data = document.data()
            let date = (data["date"] as? Timestamp)?.dateValue() ?? data["date"] as? Date
            guard let date, let rawMood = data["mood"] as? String, let mood = Mood(rawValue: rawMood) else { continue }
            moods[calendar.startOfDay(for: date)] = moodScore(mood)
        }
        return moods
    }

    private func moodScore(_ mood: Mood) -> Double {
        switch mood {
        case .awful: return 1
        case .angry: return 2
        case .low: return 3
        case .okay: return 4
        case .good: return 5
        case .amazing: return 6
        }
    }

    private func buildActivityMetrics(
        taskCounts: [ProgressActivityCategory: Int],
        exerciseRecords: [ExerciseRecord],
        taskDurations: [ProgressActivityCategory: Int]
    ) -> [ProgressActivityMetric] {
        ProgressActivityCategory.allCases.map { category in
            let records = exerciseRecords.filter { $0.category == category }
            return ProgressActivityMetric(
                category: category,
                durationSeconds: records.reduce(0) { $0 + $1.durationSeconds }
                    + taskDurations[category, default: 0],
                sessionCount: taskCounts[category, default: 0] + records.count
            )
        }
    }

    private func parseCheckInTrends(
        _ documents: [QueryDocumentSnapshot],
        currentStartDate: Date,
        previousStartDate: Date
    ) -> [ProgressDomainTrend] {
        struct Scores {
            let date: Date
            let serenity: Double
            let sleep: Double
            let energy: Double
        }

        let scores = documents.compactMap { document -> Scores? in
            let data = document.data()
            guard let date = (data["date"] as? Timestamp)?.dateValue(),
                  let stress = number(data["stress"]),
                  let sleep = number(data["sleep"]),
                  let energy = number(data["energy"]) else { return nil }
            return Scores(
                date: date,
                serenity: min(100, max(0, (6 - stress) * 20)),
                sleep: min(100, max(0, sleep * 20)),
                energy: min(100, max(0, energy * 20))
            )
        }

        guard !scores.isEmpty else { return [] }
        let current = scores.filter { $0.date >= currentStartDate }
        let previous = scores.filter {
            $0.date >= previousStartDate && $0.date < currentStartDate
        }

        func average(_ values: [Double]) -> Double? {
            guard !values.isEmpty else { return nil }
            return values.reduce(0, +) / Double(values.count)
        }

        let values: [(ProgressDomainTrend.Domain, [Double], [Double])] = [
            (.serenity, current.map(\.serenity), previous.map(\.serenity)),
            (.sleep, current.map(\.sleep), previous.map(\.sleep)),
            (.energy, current.map(\.energy), previous.map(\.energy))
        ]

        return values.compactMap { domain, currentValues, previousValues in
            guard let currentAverage = average(currentValues) else { return nil }
            return ProgressDomainTrend(
                domain: domain,
                currentValue: currentAverage,
                previousValue: average(previousValues)
            )
        }
    }

    private func number(_ value: Any?) -> Double? {
        if let value = value as? Double { return value }
        if let value = value as? Int { return Double(value) }
        if let value = value as? NSNumber { return value.doubleValue }
        return nil
    }

    private func category(for rawValue: String) -> ProgressActivityCategory {
        let value = rawValue.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
        if value.contains("respir") || value.contains("breath") || value.contains("cardiac") {
            return .breathing
        }
        if value.contains("medit") || value.contains("body_scan") || value.contains("mindful") {
            return .meditation
        }
        if value.contains("sound") || value.contains("audio") || value.contains("noise") || value.contains("son") {
            return .sounds
        }
        return .other
    }
}
