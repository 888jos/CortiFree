//
//  ImpactScoringService.swift
//  CortiFree
//
//  Created by Claude on 19/11/2025.
//  Service pour gérer le scoring basé sur les impacts des habitudes
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

class ImpactScoringService {
    static let shared = ImpactScoringService()

    private let db = Firestore.firestore()

    private init() {}

    // MARK: - Score Management

    /// Récupère les scores actuels de l'utilisateur
    func fetchCurrentScores() async throws -> UserDomainScores {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "ImpactScoringService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }

        let document = try await db.collection("users")
            .document(userId)
            .getDocument()

        if let data = document.data(),
           let currentScoresData = data["currentDomainScores"] as? [String: Any] {
            return UserDomainScores.from(currentScoresData)
        } else {
            // Si pas de scores actuels, récupérer les scores d'onboarding comme point de départ
            if let data = document.data(),
               let domainScoresData = data["domainScores"] as? [String: Any] {
                var scores = UserDomainScores()
                scores.global = domainScoresData["global"] as? Double ?? 0.0
                scores.serenity = domainScoresData["serenity"] as? Double ?? 0.0
                scores.sleep = domainScoresData["sleep"] as? Double ?? 0.0
                scores.energy = domainScoresData["energy"] as? Double ?? 0.0
                scores.focus = domainScoresData["focus"] as? Double ?? 0.0
                scores.balance = domainScoresData["balance"] as? Double ?? 0.0

                // Sauvegarder comme scores actuels
                try await saveCurrentScores(scores)
                return scores
            }

            // Aucun score trouvé, créer nouveau
            return UserDomainScores()
        }
    }

    /// Sauvegarde les scores actuels
    func saveCurrentScores(_ scores: UserDomainScores) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "ImpactScoringService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }

        try await db.collection("users")
            .document(userId)
            .setData([
                "currentDomainScores": scores.toFirestore(),
                "lastScoreUpdate": Timestamp()
            ], merge: true)
    }

    /// Applique les points d'impact lorsqu'une tâche est complétée
    func applyTaskImpact(habitId: String) async throws -> UserDomainScores {
        // Récupérer l'impact de cette habitude
        let impact = HabitImpactWeights.impactForHabit(habitId)

        // Récupérer les scores actuels
        var currentScores = try await fetchCurrentScores()

        // Appliquer les points
        currentScores.serenity += impact.serenity
        currentScores.sleep += impact.sleep
        currentScores.energy += impact.energy
        currentScores.focus += impact.focus
        currentScores.balance += impact.balance

        // Recalculer le score global (moyenne)
        currentScores.updateGlobalScore()

        // Sauvegarder
        try await saveCurrentScores(currentScores)

        print("✅ Impact appliqué pour \(habitId): +\(impact.serenity) Sérénité, +\(impact.sleep) Sommeil, +\(impact.energy) Énergie, +\(impact.focus) Focus, +\(impact.balance) Équilibre")

        return currentScores
    }

    /// Retire les points d'impact lorsqu'une tâche est décomplétée
    func removeTaskImpact(habitId: String) async throws -> UserDomainScores {
        // Récupérer l'impact de cette habitude
        let impact = HabitImpactWeights.impactForHabit(habitId)

        // Récupérer les scores actuels
        var currentScores = try await fetchCurrentScores()

        // Retirer les points (ne pas descendre en dessous de 0)
        currentScores.serenity = max(0, currentScores.serenity - impact.serenity)
        currentScores.sleep = max(0, currentScores.sleep - impact.sleep)
        currentScores.energy = max(0, currentScores.energy - impact.energy)
        currentScores.focus = max(0, currentScores.focus - impact.focus)
        currentScores.balance = max(0, currentScores.balance - impact.balance)

        // Recalculer le score global (moyenne)
        currentScores.updateGlobalScore()

        // Sauvegarder
        try await saveCurrentScores(currentScores)

        print("⚠️ Impact retiré pour \(habitId)")

        return currentScores
    }

    // MARK: - Score Display Helpers

    /// Retourne les scores arrondis pour l'affichage
    func getRoundedScores() async throws -> (global: Int, serenity: Int, sleep: Int, energy: Int, focus: Int, balance: Int) {
        let scores = try await fetchCurrentScores()
        return scores.roundedScores
    }
}
