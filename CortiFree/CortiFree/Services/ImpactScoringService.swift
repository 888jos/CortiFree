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
            return LocalScoreStore.current() ?? LocalScoreStore.baseline() ?? UserDomainScores()
        }

        do {
            let document = try await db.collection("users")
                .document(userId)
                .getDocument()

            let data = document.data() ?? [:]

            if let currentScoresData = data["currentDomainScores"] as? [String: Any] {
                let scores = UserDomainScores.from(currentScoresData)
                if scores.global == 0,
                   let baseline = LocalScoreStore.baseline(),
                   baseline.global > 0 {
                    return LocalScoreStore.current() ?? baseline
                }
                if scores.global == 0,
                   let remoteBaseline = await fetchRemoteBaselineScores(userID: userId, userData: data),
                   remoteBaseline.global > 0 {
                    LocalScoreStore.saveCurrent(remoteBaseline)
                    return remoteBaseline
                }
                LocalScoreStore.saveCurrent(scores)
                return scores
            } else if let scores = await fetchRemoteBaselineScores(userID: userId, userData: data) {
                // If no current snapshot exists, initialize it from the onboarding baseline.
                try await saveCurrentScores(scores)
                return scores
            }

            return LocalScoreStore.current() ?? LocalScoreStore.baseline() ?? UserDomainScores()
        } catch {
            return LocalScoreStore.current() ?? LocalScoreStore.baseline() ?? UserDomainScores()
        }
    }

    private func fetchRemoteBaselineScores(userID: String, userData: [String: Any]) async -> UserDomainScores? {
        if let domainScoresData = userData["domainScores"] as? [String: Any] {
            return UserDomainScores.from(domainScoresData)
        }

        guard let snapshot = try? await db.collection("users")
            .document(userID)
            .collection("baseline")
            .document("initial")
            .getDocument(),
              let baselineData = snapshot.data(),
              let domainScoresData = baselineData["domainScores"] as? [String: Any] else {
            return nil
        }

        return UserDomainScores.from(domainScoresData)
    }

    /// Sauvegarde les scores actuels
    func saveCurrentScores(_ scores: UserDomainScores) async throws {
        LocalScoreStore.saveCurrent(scores)
        guard let userId = Auth.auth().currentUser?.uid else { return }

        let userReference = db.collection("users").document(userId)
        try await userReference.setData([
                "currentDomainScores": scores.toFirestore(),
                "lastScoreUpdate": Timestamp()
            ], merge: true)

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        let dayKey = formatter.string(from: Date())
        do {
            try await userReference.updateData([
                "domainScoreHistory.\(dayKey)": scores.toFirestore()
            ])
        } catch {
            #if DEBUG
            print("Domain score history snapshot failed: \(error.localizedDescription)")
            #endif
        }
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

        #if DEBUG
        print("✅ Impact appliqué pour \(habitId): +\(impact.serenity) Sérénité, +\(impact.sleep) Sommeil, +\(impact.energy) Énergie, +\(impact.focus) Focus, +\(impact.balance) Équilibre")
        #endif

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

        #if DEBUG
        print("⚠️ Impact retiré pour \(habitId)")
        #endif

        return currentScores
    }

    /// Alias pour reverseTaskImpact (utilisé lors d'un skip après validation)
    func reverseTaskImpact(habitId: String) async throws -> UserDomainScores {
        return try await removeTaskImpact(habitId: habitId)
    }

    // MARK: - Score Display Helpers

    /// Retourne les scores arrondis pour l'affichage
    func getRoundedScores() async throws -> (global: Int, serenity: Int, sleep: Int, energy: Int, focus: Int, balance: Int) {
        let scores = try await fetchCurrentScores()
        return scores.roundedScores
    }
}
