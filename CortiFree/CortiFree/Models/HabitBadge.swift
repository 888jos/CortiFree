//
//  HabitBadge.swift
//  CortiFree
//
//  Système de badges à 4 niveaux par habitude
//  Bronze (25%), Argent (50%), Or (75%), Diamant (100%)
//

import Foundation
import FirebaseFirestore

struct HabitBadge: Identifiable, Codable {
    @DocumentID var id: String?
    var habitId: String // "meditation", "breathing", "journal", "sport", "water", "nature", "social", "sleep"
    var level: BadgeLevel
    var requirement: Int // Nombre de tâches requis pour débloquer
    var progress: Int // Nombre de tâches actuellement complétées
    var unlockedAt: Date?

    var isUnlocked: Bool {
        return unlockedAt != nil
    }

    var progressPercentage: Double {
        guard requirement > 0 else { return 0 }
        return min(Double(progress) / Double(requirement), 1.0)
    }

    enum BadgeLevel: String, Codable, CaseIterable {
        case bronze
        case silver
        case gold
        case diamond

        var emoji: String {
            switch self {
            case .bronze: return "🥉"
            case .silver: return "🥈"
            case .gold: return "🥇"
            case .diamond: return "💎"
            }
        }

        var displayName: String {
            switch self {
            case .bronze: return "Bronze"
            case .silver: return "Argent"
            case .gold: return "Or"
            case .diamond: return "Diamant"
            }
        }

        var color: String {
            switch self {
            case .bronze: return "#CD7F32"
            case .silver: return "#C0C0C0"
            case .gold: return "#FFD700"
            case .diamond: return "#B9F2FF"
            }
        }

        var percentage: Int {
            switch self {
            case .bronze: return 25
            case .silver: return 50
            case .gold: return 75
            case .diamond: return 100
            }
        }

        var starCount: Int {
            switch self {
            case .bronze: return 1
            case .silver: return 2
            case .gold: return 3
            case .diamond: return 4
            }
        }
    }
}

// MARK: - Habit Badge Requirements

extension HabitBadge {

    /// Retourne tous les badges pour une habitude donnée
    static func badgesForHabit(_ habitId: String) -> [HabitBadge] {
        let requirements = getRequirements(for: habitId)

        return BadgeLevel.allCases.map { level in
            HabitBadge(
                id: "\(habitId)_\(level.rawValue)",
                habitId: habitId,
                level: level,
                requirement: requirements[level] ?? 0,
                progress: 0,
                unlockedAt: nil
            )
        }
    }

    /// Retourne les paliers de déblocage pour chaque habitude
    static func getRequirements(for habitId: String) -> [BadgeLevel: Int] {
        switch habitId {
        case "meditation":
            return [
                .bronze: 12,    // 25% de 47
                .silver: 24,    // 50% de 47
                .gold: 36,      // 75% de 47
                .diamond: 47    // 100%
            ]

        case "breathing":
            return [
                .bronze: 12,
                .silver: 24,
                .gold: 36,
                .diamond: 47
            ]

        case "journal":
            return [
                .bronze: 17,    // 25% de 66 (16.5 → 17)
                .silver: 33,    // 50% de 66
                .gold: 50,      // 75% de 66 (49.5 → 50)
                .diamond: 66    // 100%
            ]

        case "sport":
            return [
                .bronze: 7,     // 25% de 28
                .silver: 14,    // 50% de 28
                .gold: 21,      // 75% de 28
                .diamond: 28    // 100%
            ]

        case "water":
            return [
                .bronze: 17,
                .silver: 33,
                .gold: 50,
                .diamond: 66
            ]

        case "nature":
            return [
                .bronze: 7,
                .silver: 14,
                .gold: 21,
                .diamond: 28
            ]

        case "social":
            return [
                .bronze: 7,
                .silver: 14,
                .gold: 21,
                .diamond: 28
            ]

        case "sleep":
            return [
                .bronze: 33,    // 25% de 132
                .silver: 66,    // 50% de 132
                .gold: 99,      // 75% de 132
                .diamond: 132   // 100%
            ]

        default:
            return [:]
        }
    }

    /// Nom affiché de l'habitude
    static func habitDisplayName(_ habitId: String) -> String {
        switch habitId {
        case "meditation": return "Méditation"
        case "breathing": return "Respiration"
        case "journal": return "Journal"
        case "sport": return "Sport"
        case "water": return "Eau"
        case "nature": return "Nature"
        case "social": return "Social"
        case "sleep": return "Sommeil"
        default: return habitId.capitalized
        }
    }

    /// Icône SF Symbol de l'habitude
    static func habitIcon(_ habitId: String) -> String {
        switch habitId {
        case "meditation": return "brain.head.profile"
        case "breathing": return "wind"
        case "journal": return "book.fill"
        case "sport": return "figure.run"
        case "water": return "drop.fill"
        case "nature": return "leaf.fill"
        case "social": return "person.2.fill"
        case "sleep": return "moon.stars.fill"
        default: return "star.fill"
        }
    }
}

// MARK: - All Habit IDs

extension HabitBadge {
    static let allHabitIds = [
        "meditation",
        "breathing",
        "journal",
        "sport",
        "water",
        "nature",
        "social",
        "sleep"
    ]
}
