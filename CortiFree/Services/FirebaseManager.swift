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
        setupFirestore()
    }

    private func setupFirestore() {
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        settings.cacheSizeBytes = FirestoreCacheSizeUnlimited
        db.settings = settings
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

        // Track with Mixpanel
        MixpanelManager.shared.trackOnboardingCompleted(selectedRoutine: selectedRoutineId)
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

        // Track with Mixpanel
        if let routine = try? await fetchRoutine(routineId: routineId) {
            MixpanelManager.shared.trackRoutineStarted(
                routineId: routineId,
                routineName: routine.title
            )
        }
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

        // Update daily progress
        try await updateDailyProgress(
            uid: uid,
            date: getCurrentDate(),
            xpEarned: task.xpEarned
        )

        // Update user's total XP
        if let user = currentUser {
            let newTotalXP = user.totalXP + task.xpEarned
            let newLevel = calculateLevel(xp: newTotalXP)

            try await updateUserProfile(uid: uid, updates: [
                "totalXP": newTotalXP,
                "level": newLevel
            ])

            // Check for level up
            if newLevel > user.level {
                MixpanelManager.shared.trackLevelUp(newLevel: newLevel, totalXP: newTotalXP)
            }
        }

        // Track with Mixpanel
        MixpanelManager.shared.trackExerciseCompleted(
            exerciseId: task.exerciseId,
            exerciseType: task.moment,
            durationSeconds: task.durationActualSeconds,
            feedbackMood: task.feedbackMood,
            xpEarned: task.xpEarned
        )
    }

    private func updateDailyProgress(uid: String, date: String, xpEarned: Int) async throws {
        let docRef = db.collection("users")
            .document(uid)
            .collection("routine_progress")
            .document(currentUser?.selectedRoutineId ?? "default")
            .collection("daily_progress")
            .document(date)

        let document = try await docRef.getDocument()

        if document.exists {
            // Update existing progress
            try await docRef.updateData([
                "completedTasks": FieldValue.increment(Int64(1)),
                "xpEarned": FieldValue.increment(Int64(xpEarned))
            ])
        } else {
            // Create new daily progress
            let progress = DailyProgress(
                date: date,
                weekNumber: currentUser?.currentWeek ?? 1,
                dayNumber: currentUser?.currentDay ?? 1,
                completedTasks: 1,
                totalTasks: 20,
                completionRate: 1.0 / 20.0,
                xpEarned: xpEarned,
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

        // Track with Mixpanel
        if let mood = feedback.mood as String? {
            MixpanelManager.shared.trackFeedbackSubmitted(
                mood: mood,
                exerciseId: feedback.exerciseId ?? "unknown",
                hasNote: feedback.note != nil
            )
        }
    }

    // MARK: - Custom Tasks

    func addCustomTask(uid: String, task: CustomTask) async throws {
        try db.collection("users")
            .document(uid)
            .collection("custom_tasks")
            .document()
            .setData(from: task)

        MixpanelManager.shared.trackCustomTaskAdded(
            exerciseType: task.exerciseId,
            moment: task.moment
        )
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
        guard let user = currentUser else { return }

        let today = getCurrentDate()
        let lastCompletedTasks = try await fetchCompletedTasksForToday(uid: uid, date: today)

        if !lastCompletedTasks.isEmpty {
            let newStreak = user.currentStreakDays + 1
            let longestStreak = max(newStreak, user.longestStreakDays)

            try await updateUserProfile(uid: uid, updates: [
                "currentStreakDays": newStreak,
                "longestStreakDays": longestStreak
            ])

            // Track milestone streaks
            if newStreak % 7 == 0 {
                MixpanelManager.shared.trackStreakMilestone(streakDays: newStreak)
            }
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

    // MARK: - Utility Functions

    private func getCurrentDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
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
}
