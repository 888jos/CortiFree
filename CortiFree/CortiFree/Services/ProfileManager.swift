//
//  ProfileManager.swift
//  CortiFree
//
//  Created by Claude on 18/11/2025.
//  Manager pour la gestion du profil utilisateur et des objectifs d'habitudes
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
class ProfileManager: ObservableObject {
    static let shared = ProfileManager()

    private let db = Firestore.firestore()
    @Published var currentGoals: [String: HabitGoal] = [:]
    @Published var currentPerformance: [String: HabitPerformance] = [:]
    @Published var isLoading = false

    private init() {}

    // MARK: - Personal Info Management

    func updatePersonalInfo(
        uid: String,
        firstName: String?,
        bedTime: String?,
        wakeTime: String?
    ) async throws {
        var updates: [String: Any] = [:]

        if let firstName = firstName {
            updates["displayName"] = firstName
        }

        // Update UserSettings in Firestore
        var settingsUpdates: [String: Any] = [:]

        if let bedTime = bedTime {
            settingsUpdates["bedTime"] = bedTime
        }

        if let wakeTime = wakeTime {
            settingsUpdates["wakeUpTime"] = wakeTime
        }

        // Update main user document if needed
        if !updates.isEmpty {
            try await db.collection("users").document(uid).updateData(updates)
        }

        // Update settings document
        if !settingsUpdates.isEmpty {
            try await db.collection("users").document(uid)
                .collection("settings").document("preferences")
                .setData(settingsUpdates, merge: true)
        }

        print("✅ Personal info updated successfully")
    }

    // MARK: - Goals Management

    /// Récupère les objectifs actuels de l'utilisateur
    func fetchCurrentGoals(uid: String) async throws -> [String: HabitGoal] {
        DispatchQueue.main.async {
            self.isLoading = true
        }

        defer {
            DispatchQueue.main.async {
                self.isLoading = false
            }
        }

        let snapshot = try await db.collection("users").document(uid)
            .collection("habit_goals")
            .whereField("isActive", isEqualTo: true)
            .getDocuments()

        var goals: [String: HabitGoal] = [:]

        for document in snapshot.documents {
            if let goal = HabitGoal.from(document: document) {
                goals[goal.habitId] = goal
            }
        }

        // Si aucun objectif n'existe, initialiser avec les valeurs par défaut (semaine 10)
        if goals.isEmpty {
            goals = try await initializeDefaultGoals(uid: uid)
        }

        DispatchQueue.main.async {
            self.currentGoals = goals
        }

        return goals
    }

    /// Initialise les objectifs par défaut basés sur la progression semaine 10
    private func initializeDefaultGoals(uid: String) async throws -> [String: HabitGoal] {
        let defaultGoals = HabitGoal.defaultGoals()
        var goalsDict: [String: HabitGoal] = [:]

        let batch = db.batch()

        for goal in defaultGoals {
            let docRef = db.collection("users").document(uid)
                .collection("habit_goals").document(goal.habitId)

            batch.setData(goal.toFirestore(), forDocument: docRef)
            goalsDict[goal.habitId] = goal
        }

        try await batch.commit()
        print("✅ Default goals initialized for user \(uid)")

        return goalsDict
    }

    /// Met à jour les objectifs (appliqués à partir de la semaine suivante)
    func updateGoals(uid: String, goals: [HabitGoal]) async throws {
        let batch = db.batch()

        // Calculer la date de début de la semaine suivante (lundi prochain)
        let nextMonday = getNextMonday()

        for var goal in goals {
            // Les nouveaux objectifs prennent effet à partir du lundi suivant
            goal.effectiveFrom = nextMonday

            let docRef = db.collection("users").document(uid)
                .collection("habit_goals").document(goal.habitId)

            batch.setData(goal.toFirestore(), forDocument: docRef, merge: true)
        }

        try await batch.commit()

        // Refresh current goals
        _ = try await fetchCurrentGoals(uid: uid)

        print("✅ Goals updated successfully, effective from \(nextMonday)")
    }

    // MARK: - Performance Tracking

    /// Récupère les performances actuelles (7 derniers jours)
    func fetchCurrentPerformance(uid: String, habitId: String) async throws -> HabitPerformance {
        // Récupérer l'historique des 7 derniers jours depuis habit_tracking
        let trackingData = try await FirebaseManager.shared.fetchHabitTracking(uid: uid, habitId: habitId)

        let last7Days = trackingData?.last7Days ?? [false, false, false, false, false, false, false]
        let currentStreak = trackingData?.currentStreak ?? 0

        // Calculer les moyennes depuis completed_tasks
        let (avgDuration, avgQuantity) = try await calculateAverages(uid: uid, habitId: habitId)

        // Calculer la fréquence moyenne (nombre de jours complétés sur 7)
        let completedDays = last7Days.filter { $0 }.count
        let avgCompletionsPerWeek = Float(completedDays)

        let performance = HabitPerformance(
            habitId: habitId,
            last7Days: last7Days,
            currentStreak: currentStreak,
            averageCompletionsPerWeek: avgCompletionsPerWeek,
            averageDurationMinutes: avgDuration,
            averageDailyQuantity: avgQuantity
        )

        DispatchQueue.main.async {
            self.currentPerformance[habitId] = performance
        }

        return performance
    }

    /// Récupère toutes les performances
    func fetchAllPerformances(uid: String) async throws -> [String: HabitPerformance] {
        let habitIds = ["meditation", "breathing", "journal", "sport", "water", "nature", "social", "sleep"]
        var performances: [String: HabitPerformance] = [:]

        for habitId in habitIds {
            if let performance = try? await fetchCurrentPerformance(uid: uid, habitId: habitId) {
                performances[habitId] = performance
            }
        }

        DispatchQueue.main.async {
            self.currentPerformance = performances
        }

        return performances
    }

    /// Calcule les moyennes de durée et quantité depuis les completed_tasks
    private func calculateAverages(uid: String, habitId: String) async throws -> (duration: Float?, quantity: Float?) {
        // Récupérer les tâches complétées des 7 derniers jours pour cette habitude
        let calendar = Calendar.current
        let today = Date()
        guard let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: today) else {
            return (nil, nil)
        }

        let snapshot = try await db.collection("users").document(uid)
            .collection("completed_tasks")
            .whereField("exerciseId", isEqualTo: habitId)
            .whereField("completedAt", isGreaterThanOrEqualTo: Timestamp(date: sevenDaysAgo))
            .getDocuments()

        guard !snapshot.documents.isEmpty else {
            return (nil, nil)
        }

        var totalDuration: Int = 0
        var totalQuantity: Float = 0.0
        var durationCount = 0
        var quantityCount = 0

        for document in snapshot.documents {
            let data = document.data()

            // Durée en secondes → minutes
            if let durationSeconds = data["durationActualSeconds"] as? Int {
                totalDuration += durationSeconds / 60
                durationCount += 1
            }

            // Quantité (eau, sommeil, etc.)
            if let quantity = data["quantity"] as? Float {
                totalQuantity += quantity
                quantityCount += 1
            }
        }

        let avgDuration = durationCount > 0 ? Float(totalDuration) / Float(durationCount) : nil
        let avgQuantity = quantityCount > 0 ? totalQuantity / Float(quantityCount) : nil

        return (avgDuration, avgQuantity)
    }

    // MARK: - Helper Methods

    /// Retourne la date du prochain lundi à 00:00
    private func getNextMonday() -> Date {
        let calendar = Calendar.current
        let today = Date()

        // Trouver le prochain lundi
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)
        components.weekday = 2 // Lundi = 2
        components.hour = 0
        components.minute = 0
        components.second = 0

        guard let nextMonday = calendar.date(from: components) else {
            return today
        }

        // Si on est déjà lundi, prendre le lundi suivant
        if calendar.isDateInToday(nextMonday) && calendar.component(.weekday, from: today) == 2 {
            return calendar.date(byAdding: .weekOfYear, value: 1, to: nextMonday) ?? nextMonday
        }

        // Si la date calculée est dans le passé, ajouter une semaine
        if nextMonday < today {
            return calendar.date(byAdding: .weekOfYear, value: 1, to: nextMonday) ?? nextMonday
        }

        return nextMonday
    }

    /// Formatte une date en string pour l'affichage
    func formatNextMondayDisplay() -> String {
        let nextMonday = getNextMonday()
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "d MMM yyyy"
        return formatter.string(from: nextMonday)
    }
}
