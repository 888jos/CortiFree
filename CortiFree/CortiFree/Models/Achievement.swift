//
//  Achievement.swift
//  CortiFree
//
//  Achievement badge system - gamification
//

import Foundation
import FirebaseFirestore

struct Achievement: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    let description: String
    let icon: String // SF Symbol name
    let category: AchievementCategory
    let requirement: Int // Number needed to unlock
    var progress: Int = 0
    var unlockedAt: Date?

    var isUnlocked: Bool {
        unlockedAt != nil
    }

    var progressPercentage: Double {
        guard requirement > 0 else { return 0 }
        return min(Double(progress) / Double(requirement), 1.0)
    }

    enum AchievementCategory: String, Codable {
        case streak
        case completion
        case habit
        case special
    }

    // MARK: - Predefined Achievements

    static let allAchievements: [Achievement] = [
        // Streak achievements (9 badges: 3j, 7j, 14j, 21j, 30j, 40j, 50j, 60j, 66j)
        Achievement(
            id: "streak_3",
            title: "Débutant",
            description: "Maintiens un streak de 3 jours",
            icon: "flame.fill",
            category: .streak,
            requirement: 3
        ),
        Achievement(
            id: "streak_7",
            title: "Motivé",
            description: "Maintiens un streak de 7 jours",
            icon: "flame.fill",
            category: .streak,
            requirement: 7
        ),
        Achievement(
            id: "streak_14",
            title: "Déterminé",
            description: "Maintiens un streak de 14 jours",
            icon: "flame.fill",
            category: .streak,
            requirement: 14
        ),
        Achievement(
            id: "streak_21",
            title: "Engagé",
            description: "Maintiens un streak de 21 jours",
            icon: "flame.fill",
            category: .streak,
            requirement: 21
        ),
        Achievement(
            id: "streak_30",
            title: "Assidu",
            description: "Maintiens un streak de 30 jours",
            icon: "flame.fill",
            category: .streak,
            requirement: 30
        ),
        Achievement(
            id: "streak_40",
            title: "Champion",
            description: "Maintiens un streak de 40 jours",
            icon: "flame.fill",
            category: .streak,
            requirement: 40
        ),
        Achievement(
            id: "streak_50",
            title: "Invincible",
            description: "Maintiens un streak de 50 jours",
            icon: "flame.fill",
            category: .streak,
            requirement: 50
        ),
        Achievement(
            id: "streak_60",
            title: "Légende",
            description: "Maintiens un streak de 60 jours",
            icon: "flame.fill",
            category: .streak,
            requirement: 60
        ),
        Achievement(
            id: "streak_66",
            title: "Maître",
            description: "Maintiens un streak de 66 jours - Programme complet!",
            icon: "flame.fill",
            category: .streak,
            requirement: 66
        )
    ]

    // MARK: - Firebase Conversion

    var toFirestore: [String: Any] {
        var data: [String: Any] = [
            "id": id,
            "progress": progress
        ]

        if let unlocked = unlockedAt {
            data["unlockedAt"] = Timestamp(date: unlocked)
        }

        return data
    }

    static func fromFirestore(_ data: [String: Any], id: String) -> Achievement? {
        // Find achievement template
        guard var achievement = allAchievements.first(where: { $0.id == id }) else {
            return nil
        }

        // Update with user data
        achievement.progress = data["progress"] as? Int ?? 0

        if let timestamp = data["unlockedAt"] as? Timestamp {
            achievement.unlockedAt = timestamp.dateValue()
        }

        return achievement
    }
}
