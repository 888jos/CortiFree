//
//  FirebaseManager.swift
//  CortiFree
//
//  Created by Claude on 09/11/2025.
//  Centralized Firebase Firestore manager
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

class FirebaseManager: ObservableObject {
    static let shared = FirebaseManager()

    private let db = Firestore.firestore()
    @Published var currentUser: UserProfile?
    @Published var isLoading = false

    private init() {
        // DO NOT configure Firestore settings - causes crash
    }

    // MARK: - User Management

    func createUserProfile(uid: String, email: String, displayName: String? = nil) async throws {
        let userProfile = UserProfile(
            uid: uid,
            email: email,
            displayName: displayName
        )

        try db.collection("users").document(uid).setData(from: userProfile)

        DispatchQueue.main.async {
            self.currentUser = userProfile
        }
    }

    func fetchUserProfile(uid: String) async throws -> UserProfile {
        let document = try await db.collection("users").document(uid).getDocument()

        guard let user = try? document.data(as: UserProfile.self) else {
            throw NSError(domain: "FirebaseManager", code: 404, userInfo: [NSLocalizedDescriptionKey: "User not found"])
        }

        DispatchQueue.main.async {
            self.currentUser = user
        }

        return user
    }

    func updateUserProfile(uid: String, updates: [String: Any]) async throws {
        try await db.collection("users").document(uid).updateData(updates)

        // Refresh current user
        if let updatedUser = try? await fetchUserProfile(uid: uid) {
            DispatchQueue.main.async {
                self.currentUser = updatedUser
            }
        }
    }

    func updateLastLogin(uid: String) async throws {
        try await db.collection("users").document(uid).updateData([
            "lastLogin": Timestamp()
        ])
    }

    // MARK: - Onboarding

    func saveOnboardingResponse(uid: String, questionId: String, response: OnboardingResponse) async throws {
        try db.collection("users")
            .document(uid)
            .collection("onboarding_responses")
            .document(questionId)
            .setData(from: response)
    }

    func completeOnboarding(uid: String, selectedRoutineId: String) async throws {
        try await db.collection("users").document(uid).updateData([
            "onboardingCompleted": true,
            "onboardingCompletedAt": Timestamp(),
            "selectedRoutineId": selectedRoutineId
        ])

        // Mixpanel tracking handled separately
    }

    // MARK: - Routines

    func fetchAllRoutines() async throws -> [RoutineModel] {
        let snapshot = try await db.collection("routines")
            .whereField("isActive", isEqualTo: true)
            .getDocuments()

        return snapshot.documents.compactMap { try? $0.data(as: RoutineModel.self) }
    }

    func fetchRoutine(routineId: String) async throws -> RoutineModel {
        let document = try await db.collection("routines").document(routineId).getDocument()

        guard let routine = try? document.data(as: RoutineModel.self) else {
            throw NSError(domain: "FirebaseManager", code: 404, userInfo: [NSLocalizedDescriptionKey: "Routine not found"])
        }

        return routine
    }

    func startRoutine(uid: String, routineId: String) async throws {
        let progress = RoutineProgress(
            routineId: routineId,
            startedAt: Timestamp(),
            currentWeek: 1,
            currentDay: 1,
            completionPercentage: 0.0,
            isActive: true,
            totalTasksCompleted: 0,
            totalTasks: 0,
            adherenceScore: 1.0
        )

        try db.collection("users")
            .document(uid)
            .collection("routine_progress")
            .document(routineId)
            .setData(from: progress)

        // Update user's selected routine
        try await updateUserProfile(uid: uid, updates: [
            "selectedRoutineId": routineId,
            "currentWeek": 1,
            "currentDay": 1
        ])

        // Mixpanel tracking handled separately
    }

    // MARK: - Exercises

    func fetchAllExercises() async throws -> [ExerciseModel] {
        let snapshot = try await db.collection("exercises")
            .whereField("isActive", isEqualTo: true)
            .getDocuments()

        return snapshot.documents.compactMap { try? $0.data(as: ExerciseModel.self) }
    }

    func fetchExercise(exerciseId: String) async throws -> ExerciseModel {
        let document = try await db.collection("exercises").document(exerciseId).getDocument()

        guard let exercise = try? document.data(as: ExerciseModel.self) else {
            throw NSError(domain: "FirebaseManager", code: 404, userInfo: [NSLocalizedDescriptionKey: "Exercise not found"])
        }

        return exercise
    }

    func fetchExercisesByType(type: String) async throws -> [ExerciseModel] {
        let snapshot = try await db.collection("exercises")
            .whereField("type", isEqualTo: type)
            .whereField("isActive", isEqualTo: true)
            .getDocuments()

        return snapshot.documents.compactMap { try? $0.data(as: ExerciseModel.self) }
    }

    // MARK: - Task Completion

    func saveCompletedTask(uid: String, task: CompletedTask) async throws {
        let docRef = db.collection("users")
            .document(uid)
            .collection("completed_tasks")
            .document()

        try docRef.setData(from: task)

        // Update daily progress (without XP)
        try await updateDailyProgress(uid: uid, date: getCurrentDate())

        // Mixpanel tracking handled separately
    }

    private func updateDailyProgress(uid: String, date: String) async throws {
        let docRef = db.collection("users")
            .document(uid)
            .collection("routine_progress")
            .document(currentUser?.selectedRoutineId ?? "default")
            .collection("daily_progress")
            .document(date)

        let document = try await docRef.getDocument()

        if document.exists {
            // Update existing progress (XP removed)
            try await docRef.updateData([
                "completedTasks": FieldValue.increment(Int64(1))
            ])
        } else {
            // Create new daily progress (XP set to 0 by default)
            let progress = DailyProgress(
                date: date,
                weekNumber: currentUser?.currentWeek ?? 1,
                dayNumber: currentUser?.currentDay ?? 1,
                completedTasks: 1,
                totalTasks: 20,
                completionRate: 1.0 / 20.0,
                createdAt: Timestamp()
            )

            try docRef.setData(from: progress)
        }
    }

    // MARK: - Feedback

    func saveFeedback(uid: String, feedback: FeedbackModel) async throws {
        try db.collection("users")
            .document(uid)
            .collection("feedback")
            .document()
            .setData(from: feedback)

        // Mixpanel tracking for feedback handled separately
    }

    // MARK: - Custom Tasks

    func addCustomTask(uid: String, task: CustomTask) async throws {
        try db.collection("users")
            .document(uid)
            .collection("custom_tasks")
            .document()
            .setData(from: task)

        // Mixpanel tracking handled separately
    }

    func fetchCustomTasks(uid: String) async throws -> [CustomTask] {
        let snapshot = try await db.collection("users")
            .document(uid)
            .collection("custom_tasks")
            .whereField("isActive", isEqualTo: true)
            .getDocuments()

        return snapshot.documents.compactMap { try? $0.data(as: CustomTask.self) }
    }

    // MARK: - Stats & Progress

    func fetchWeeklySummary(uid: String) async throws -> WeeklySummary? {
        let document = try await db.collection("users")
            .document(uid)
            .collection("stats")
            .document("weekly_summary")
            .getDocument()

        return try? document.data(as: WeeklySummary.self)
    }

    func fetchCompletedTasks(uid: String, limit: Int = 50) async throws -> [CompletedTask] {
        let snapshot = try await db.collection("users")
            .document(uid)
            .collection("completed_tasks")
            .order(by: "completedAt", descending: true)
            .limit(to: limit)
            .getDocuments()

        return snapshot.documents.compactMap { try? $0.data(as: CompletedTask.self) }
    }

    func fetchDailyProgress(uid: String, routineId: String, days: Int = 7) async throws -> [DailyProgress] {
        let snapshot = try await db.collection("users")
            .document(uid)
            .collection("routine_progress")
            .document(routineId)
            .collection("daily_progress")
            .order(by: "date", descending: true)
            .limit(to: days)
            .getDocuments()

        return snapshot.documents.compactMap { try? $0.data(as: DailyProgress.self) }
    }

    // MARK: - AI Insights

    func fetchAIInsights(uid: String) async throws -> [AIInsight] {
        let snapshot = try await db.collection("users")
            .document(uid)
            .collection("ai_insights")
            .whereField("isApplied", isEqualTo: false)
            .order(by: "generatedAt", descending: true)
            .limit(to: 5)
            .getDocuments()

        return snapshot.documents.compactMap { try? $0.data(as: AIInsight.self) }
    }

    func applyAIInsight(uid: String, insightId: String) async throws {
        try await db.collection("users")
            .document(uid)
            .collection("ai_insights")
            .document(insightId)
            .updateData([
                "isApplied": true,
                "appliedAt": Timestamp()
            ])
    }

    // MARK: - Streak Management

    func updateStreak(uid: String) async throws {
        // Fix race condition: capture user values atomically at start
        guard let userSnapshot = currentUser else { return }
        let currentStreakDays = userSnapshot.currentStreakDays
        let currentLongestStreak = userSnapshot.longestStreakDays

        let today = getCurrentDate()
        let lastCompletedTasks = try await fetchCompletedTasksForToday(uid: uid, date: today)

        // Global streak criteria: at least 1 task completed today
        if !lastCompletedTasks.isEmpty {
            let newStreak = currentStreakDays + 1
            let longestStreak = max(newStreak, currentLongestStreak)

            try await updateUserProfile(uid: uid, updates: [
                "currentStreakDays": newStreak,
                "longestStreakDays": longestStreak
            ])

            // Request rating on 7-day streak
            if newStreak == 7 {
                AppRatingService.shared.trackSevenDayStreak()
            }

            // Streak milestone tracking handled in TasksV2View
        }
    }

    private func fetchCompletedTasksForToday(uid: String, date: String) async throws -> [CompletedTask] {
        let startOfDay = getStartOfDayTimestamp(date: date)
        let endOfDay = getEndOfDayTimestamp(date: date)

        let snapshot = try await db.collection("users")
            .document(uid)
            .collection("completed_tasks")
            .whereField("completedAt", isGreaterThanOrEqualTo: startOfDay)
            .whereField("completedAt", isLessThan: endOfDay)
            .getDocuments()

        return snapshot.documents.compactMap { try? $0.data(as: CompletedTask.self) }
    }

    // MARK: - User Settings & Habit Tracking

    func saveUserSettings(uid: String, settings: UserSettings) async throws {
        try await db.collection("users").document(uid)
            .collection("settings").document("preferences")
            .setData(settings.toFirestore())

        // Also save to UserDefaults for offline access
        settings.saveToUserDefaults()
    }

    func fetchUserSettings(uid: String) async throws -> UserSettings? {
        let document = try await db.collection("users").document(uid)
            .collection("settings").document("preferences")
            .getDocument()

        let settings = UserSettings.from(document: document)

        // Cache in UserDefaults
        settings?.saveToUserDefaults()

        return settings
    }

    func initializeHabitTracking(uid: String) async throws {
        let habits = [
            ("breathing", "Respirer en conscience"),
            ("meditation", "Méditer en pleine conscience"),
            ("journal", "Tenir un journal"),
            ("water", "S'hydrater régulièrement"),
            ("sport", "Faire du sport"),
            ("nature", "Sortir dans la nature"),
            ("social", "Moments sociaux"),
            ("sleep", "Routine de sommeil")
        ]

        for (habitId, title) in habits {
            let tracking = HabitTracking(habitId: habitId, habitTitle: title)
            try await db.collection("users").document(uid)
                .collection("habit_tracking").document(habitId)
                .setData(tracking.toFirestore())
        }
    }

    func fetchHabitTracking(uid: String, habitId: String) async throws -> HabitTracking? {
        let document = try await db.collection("users").document(uid)
            .collection("habit_tracking").document(habitId)
            .getDocument()

        return HabitTracking.from(document: document)
    }

    func fetchAllHabitTracking(uid: String) async throws -> [String: HabitTracking] {
        let snapshot = try await db.collection("users").document(uid)
            .collection("habit_tracking")
            .getDocuments()

        var trackingDict: [String: HabitTracking] = [:]
        for document in snapshot.documents {
            if let tracking = HabitTracking.from(document: document) {
                trackingDict[tracking.habitId] = tracking
            }
        }

        return trackingDict
    }

    func markHabitCompleted(uid: String, habitId: String, programDay: Int, date: Date = Date()) async throws {
        let dateString = getCurrentDateString(from: date)

        // Save daily completion
        try await db.collection("users").document(uid)
            .collection("habit_tracking").document(habitId)
            .collection("daily_completion").document(dateString)
            .setData([
                "completed": true,
                "completedAt": Timestamp(date: date),
                "date": dateString
            ])

        // Update habit tracking stats
        if var tracking = try await fetchHabitTracking(uid: uid, habitId: habitId) {
            tracking.markCompleted(on: date)

            // Add program day to completedDays array if not already present
            if !tracking.completedDays.contains(programDay) {
                tracking.completedDays.append(programDay)
                tracking.completedDays.sort() // Keep array sorted
            }

            try await db.collection("users").document(uid)
                .collection("habit_tracking").document(habitId)
                .setData(tracking.toFirestore())
        }
    }

    func removeHabitCompletion(uid: String, habitId: String, programDay: Int, date: Date = Date()) async throws {
        let dateString = getCurrentDateString(from: date)

        // Remove daily completion
        try await db.collection("users").document(uid)
            .collection("habit_tracking").document(habitId)
            .collection("daily_completion").document(dateString)
            .delete()

        // Update habit tracking stats
        if var tracking = try await fetchHabitTracking(uid: uid, habitId: habitId) {
            // Remove program day from completedDays array
            tracking.completedDays.removeAll { $0 == programDay }

            // Decrement total completions
            tracking.totalCompletions = max(0, tracking.totalCompletions - 1)

            // Reset last completed date to nil (will be recalculated on next fetch)
            tracking.lastCompletedDate = nil

            // Recalculate streak from remaining completed days
            tracking.currentStreak = calculateStreakFromCompletedDays(tracking.completedDays)

            try await db.collection("users").document(uid)
                .collection("habit_tracking").document(habitId)
                .setData(tracking.toFirestore())
        }
    }

    /// Calculate the current streak from an array of completed program days
    /// The streak counts consecutive days ending with the most recent completion
    private func calculateStreakFromCompletedDays(_ days: [Int]) -> Int {
        guard !days.isEmpty else { return 0 }

        // Sort days in descending order (most recent first)
        let sortedDays = days.sorted(by: >)
        var streak = 1

        // Count consecutive days from the most recent
        for i in 0..<(sortedDays.count - 1) {
            if sortedDays[i] - sortedDays[i + 1] == 1 {
                streak += 1
            } else {
                break // Streak broken, stop counting
            }
        }

        return streak
    }

    func fetchHabitCompletionHistory(uid: String, habitId: String, days: Int = 7) async throws -> [Bool] {
        let calendar = Calendar.current
        let today = Date()

        // Build date strings for the period
        var dateStrings: [String] = []
        for dayOffset in (0..<days).reversed() {
            if let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) {
                dateStrings.append(getCurrentDateString(from: date))
            }
        }

        // Single query: fetch all daily_completion docs at once (1 read instead of 7)
        let snapshot = try await db.collection("users").document(uid)
            .collection("habit_tracking").document(habitId)
            .collection("daily_completion")
            .getDocuments()

        // Build a lookup map from the fetched docs
        var completionMap: [String: Bool] = [:]
        for doc in snapshot.documents {
            completionMap[doc.documentID] = doc.data()["completed"] as? Bool ?? false
        }

        // Map date strings to completion status
        return dateStrings.map { completionMap[$0] ?? false }
    }

    func saveOnboardingScore(uid: String, score: Int) async throws {
        try await db.collection("users").document(uid).updateData([
            "onboardingScore": score,
            "onboardingScoreSavedAt": Timestamp()
        ])
    }

    // MARK: - Utility Functions

    private func getCurrentDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    private func getCurrentDateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private func getStartOfDayTimestamp(date: String) -> Timestamp {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let startDate = formatter.date(from: date) else {
            return Timestamp()
        }
        return Timestamp(date: startDate)
    }

    private func getEndOfDayTimestamp(date: String) -> Timestamp {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let startDate = formatter.date(from: date) else {
            return Timestamp()
        }
        let endDate = Calendar.current.date(byAdding: .day, value: 1, to: startDate) ?? startDate
        return Timestamp(date: endDate)
    }

    private func calculateLevel(xp: Int) -> Int {
        // XP formula: level = floor(sqrt(xp / 100))
        // Level 1: 0-99 XP
        // Level 2: 100-399 XP
        // Level 3: 400-899 XP
        // etc.
        return Int(floor(sqrt(Double(xp) / 100.0))) + 1
    }

    // MARK: - Daily Mood

    func saveDailyMood(userId: String, mood: DailyMood) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateKey = dateFormatter.string(from: mood.date)

        do {
            try db.collection("users")
                .document(userId)
                .collection("daily_moods")
                .document(dateKey)
                .setData(from: mood)
        } catch {
            #if DEBUG
            print("Error saving daily mood: \(error)")
            #endif
        }
    }

    func fetchTodaysMood(userId: String, completion: @escaping (Mood?) -> Void) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let todayKey = dateFormatter.string(from: Date())

        db.collection("users")
            .document(userId)
            .collection("daily_moods")
            .document(todayKey)
            .getDocument { snapshot, error in
                if let error = error {
                    #if DEBUG
                    print("Error fetching today's mood: \(error)")
                    #endif
                    completion(nil)
                    return
                }

                guard let data = snapshot?.data(),
                      let dailyMood = DailyMood(from: data) else {
                    completion(nil)
                    return
                }

                completion(dailyMood.mood)
            }
    }

    func fetchRecentMoods(userId: String, days: Int, completion: @escaping ([DailyMood]) -> Void) {
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()

        db.collection("users")
            .document(userId)
            .collection("daily_moods")
            .whereField("date", isGreaterThanOrEqualTo: startDate)
            .order(by: "date", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    #if DEBUG
                    print("Error fetching recent moods: \(error)")
                    #endif
                    completion([])
                    return
                }

                let moods = snapshot?.documents.compactMap { doc -> DailyMood? in
                    return DailyMood(from: doc.data())
                } ?? []

                completion(moods)
            }
    }
}
