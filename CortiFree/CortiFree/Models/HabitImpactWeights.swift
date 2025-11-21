//
//  HabitImpactWeights.swift
//  CortiFree
//
//  Created by Claude on 19/11/2025.
//  Poids des habitudes sur les 5 impacts (Sérénité, Sommeil, Énergie, Focus, Équilibre)
//

import Foundation

/// Structure représentant l'impact d'une habitude sur les 5 domaines
struct HabitImpactScore {
    let serenity: Double    // Sérénité
    let sleep: Double       // Sommeil
    let energy: Double      // Énergie
    let focus: Double       // Focus
    let balance: Double     // Équilibre
}

/// Poids normalisés des habitudes sur les impacts (sur 66 jours)
/// Calculés pour que si toutes les tâches sont complétées, l'utilisateur gagne +65 points par impact
struct HabitImpactWeights {

    // MARK: - Impact Weights per Habit (Points par tâche complétée)

    static let meditation = HabitImpactScore(
        serenity: 0.248,
        sleep: 0.141,
        energy: 0.091,
        focus: 0.215,
        balance: 0.175
    )

    static let breathing = HabitImpactScore(
        serenity: 0.248,
        sleep: 0.177,
        energy: 0.121,
        focus: 0.154,
        balance: 0.175
    )

    static let journal = HabitImpactScore(
        serenity: 0.198,
        sleep: 0.106,
        energy: 0.061,
        focus: 0.123,
        balance: 0.204
    )

    static let sport = HabitImpactScore(
        serenity: 0.149,
        sleep: 0.247,
        energy: 0.303,
        focus: 0.154,
        balance: 0.146
    )

    static let water = HabitImpactScore(
        serenity: 0.050,
        sleep: 0.106,
        energy: 0.212,
        focus: 0.184,
        balance: 0.087
    )

    static let nature = HabitImpactScore(
        serenity: 0.223,
        sleep: 0.141,
        energy: 0.182,
        focus: 0.154,
        balance: 0.204
    )

    static let social = HabitImpactScore(
        serenity: 0.124,
        sleep: 0.071,
        energy: 0.121,
        focus: 0.092,
        balance: 0.291
    )

    static let sleep = HabitImpactScore(
        serenity: 0.087,  // Divisé par 2 car 2 tâches/jour au lieu de 1
        sleep: 0.177,     // Divisé par 2 car 2 tâches/jour au lieu de 1
        energy: 0.152,    // Divisé par 2 car 2 tâches/jour au lieu de 1
        focus: 0.123,     // Divisé par 2 car 2 tâches/jour au lieu de 1
        balance: 0.088    // Divisé par 2 car 2 tâches/jour au lieu de 1
    )

    // MARK: - Helper Methods

    /// Retourne l'impact pour un habitId donné
    static func impactForHabit(_ habitId: String) -> HabitImpactScore {
        switch habitId {
        case "meditation":
            return meditation
        case "breathing":
            return breathing
        case "journal":
            return journal
        case "sport":
            return sport
        case "water":
            return water
        case "nature":
            return nature
        case "social":
            return social
        case "sleep":
            return sleep
        default:
            // Default: no impact
            return HabitImpactScore(serenity: 0, sleep: 0, energy: 0, focus: 0, balance: 0)
        }
    }
}

/// Structure pour stocker les scores actuels de l'utilisateur
struct UserDomainScores: Codable {
    var global: Double = 0.0        // Moyenne des 5 domaines
    var serenity: Double = 0.0      // Sérénité
    var sleep: Double = 0.0         // Sommeil
    var energy: Double = 0.0        // Énergie
    var focus: Double = 0.0         // Focus
    var balance: Double = 0.0       // Équilibre

    /// Calcule le score global (moyenne des 5 domaines, arrondie)
    mutating func updateGlobalScore() {
        let average = (serenity + sleep + energy + focus + balance) / 5.0
        global = average
    }

    /// Retourne les scores arrondis pour l'affichage (ex: 34.9 → 34, 35.5 → 35)
    var roundedScores: (global: Int, serenity: Int, sleep: Int, energy: Int, focus: Int, balance: Int) {
        return (
            global: Int(global.rounded(.toNearestOrAwayFromZero)),
            serenity: Int(serenity.rounded(.toNearestOrAwayFromZero)),
            sleep: Int(sleep.rounded(.toNearestOrAwayFromZero)),
            energy: Int(energy.rounded(.toNearestOrAwayFromZero)),
            focus: Int(focus.rounded(.toNearestOrAwayFromZero)),
            balance: Int(balance.rounded(.toNearestOrAwayFromZero))
        )
    }

    /// Convertit vers dictionnaire pour Firestore
    func toFirestore() -> [String: Any] {
        return [
            "global": global,
            "serenity": serenity,
            "sleep": sleep,
            "energy": energy,
            "focus": focus,
            "balance": balance
        ]
    }

    /// Crée depuis dictionnaire Firestore
    static func from(_ data: [String: Any]) -> UserDomainScores {
        var scores = UserDomainScores()
        scores.global = data["global"] as? Double ?? 0.0
        scores.serenity = data["serenity"] as? Double ?? 0.0
        scores.sleep = data["sleep"] as? Double ?? 0.0
        scores.energy = data["energy"] as? Double ?? 0.0
        scores.focus = data["focus"] as? Double ?? 0.0
        scores.balance = data["balance"] as? Double ?? 0.0
        return scores
    }
}
