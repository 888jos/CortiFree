//
//  TaskStatusService.swift
//  CortiFree
//
//  Service pour sauvegarder et charger les statuts des tâches
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

class TaskStatusService {
    static let shared = TaskStatusService()
    private let db = Firestore.firestore()

    private init() {}

    // MARK: - Save Task Status

    /// Sauvegarde le statut d'une tâche pour un jour donné
    func saveTaskStatus(day: Int, taskTitle: String, status: String) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "TaskStatusService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }

        let dayKey = "day_\(day)"

        try await db.collection("users").document(userId)
            .collection("task_statuses").document(dayKey)
            .setData([
                taskTitle: status,
                "lastUpdated": Timestamp()
            ], merge: true)
    }

    // MARK: - Load Task Statuses

    /// Charge tous les statuts de tâches pour tous les jours
    func loadAllTaskStatuses() async throws -> [String: [String: String]] {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "TaskStatusService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }

        let snapshot = try await db.collection("users").document(userId)
            .collection("task_statuses")
            .getDocuments()

        var statuses: [String: [String: String]] = [:]

        for document in snapshot.documents {
            let dayKey = document.documentID
            var dayStatuses: [String: String] = [:]

            for (key, value) in document.data() {
                if key != "lastUpdated", let statusString = value as? String {
                    dayStatuses[key] = statusString
                }
            }

            statuses[dayKey] = dayStatuses
        }

        return statuses
    }

    // MARK: - Delete Task Status

    /// Supprime le statut d'une tâche (quand on passe de done à todo par exemple)
    func deleteTaskStatus(day: Int, taskTitle: String) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "TaskStatusService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }

        let dayKey = "day_\(day)"

        try await db.collection("users").document(userId)
            .collection("task_statuses").document(dayKey)
            .updateData([
                taskTitle: FieldValue.delete()
            ])
    }

    // MARK: - Habit Progress Statistics

    /// Calcule les statistiques de progression par habitude
    func calculateHabitProgress() async throws -> [String: (completed: Int, total: Int)] {
        let statuses = try await loadAllTaskStatuses()

        print("📊 TaskStatusService: Loaded \(statuses.count) days with task statuses")

        // Dictionnaire pour compter les tâches par habitude
        var habitStats: [String: (completed: Int, total: Int)] = [
            "meditation": (0, 47),
            "breathing": (0, 47),
            "journal": (0, 66),
            "sport": (0, 28),
            "water": (0, 66),
            "nature": (0, 28),
            "social": (0, 28),
            "sleep": (0, 132)
        ]

        // Parcourir tous les statuts et compter les tâches complétées
        var totalTasksDone = 0
        for (_, dayTasks) in statuses {
            for (taskTitle, status) in dayTasks {
                guard status == "done" else { continue }
                totalTasksDone += 1

                // Déterminer l'habitude à partir du titre de la tâche
                let habitId = getHabitIdFromTaskTitle(taskTitle)

                if var stats = habitStats[habitId] {
                    stats.completed += 1
                    habitStats[habitId] = stats
                    print("📊 Task '\(taskTitle)' → \(habitId) (total: \(stats.completed))")
                } else {
                    print("⚠️ Unknown habit for task '\(taskTitle)' → \(habitId)")
                }
            }
        }

        print("📊 Total tasks done: \(totalTasksDone)")
        for (habitId, stats) in habitStats {
            if stats.completed > 0 {
                print("📊 \(habitId): \(stats.completed)/\(stats.total)")
            }
        }

        return habitStats
    }

    /// Map task title to habit ID
    private func getHabitIdFromTaskTitle(_ taskTitle: String) -> String {
        let lowercased = taskTitle.lowercased()

        // Sleep: lever, coucher, sommeil, routine
        if lowercased.contains("lever") || lowercased.contains("coucher") ||
           lowercased.contains("sommeil") || lowercased.contains("sleep") ||
           lowercased.contains("routine") {
            return "sleep"
        }

        // Breathing: respirer, respiration, breath
        else if lowercased.contains("respir") || lowercased.contains("breath") {
            return "breathing"
        }

        // Meditation: méditer, méditation, meditation
        else if lowercased.contains("médit") || lowercased.contains("medit") {
            return "meditation"
        }

        // Water: eau, water, boire, hydrat
        else if lowercased.contains("eau") || lowercased.contains("water") ||
                lowercased.contains("boire") || lowercased.contains("hydrat") {
            return "water"
        }

        // Sport: sport, exercice, nager, conquérir, défier, sauter, course, vélo
        else if lowercased.contains("sport") || lowercased.contains("exercice") ||
                lowercased.contains("nager") || lowercased.contains("conquérir") ||
                lowercased.contains("défier") || lowercased.contains("défis") ||
                lowercased.contains("sauter") || lowercased.contains("course") ||
                lowercased.contains("vélo") || lowercased.contains("sommet") {
            return "sport"
        }

        // Nature: nature, marche, balade, plein air
        else if lowercased.contains("nature") || lowercased.contains("marche") ||
                lowercased.contains("balade") || lowercased.contains("plein air") {
            return "nature"
        }

        // Social: social, ami, renouer, liens, appel, rencontre, moment, convivial
        else if lowercased.contains("social") || lowercased.contains("ami") ||
                lowercased.contains("renouer") || lowercased.contains("lien") ||
                lowercased.contains("appel") || lowercased.contains("rencontre") ||
                lowercased.contains("moment") || lowercased.contains("convivial") {
            return "social"
        }

        // Journal: journal, écrire, pensées, noter
        else if lowercased.contains("journal") || lowercased.contains("écrire") ||
                lowercased.contains("pensée") || lowercased.contains("noter") {
            return "journal"
        }

        return "unknown"
    }
}
