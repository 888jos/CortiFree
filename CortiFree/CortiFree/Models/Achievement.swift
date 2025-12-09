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
    let titleKey: String
    let descriptionKey: String
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

    /// Localized title
    var title: String {
        NSLocalizedString(titleKey, comment: "")
    }

    /// Localized description
    var description: String {
        NSLocalizedString(descriptionKey, comment: "")
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
            titleKey: "achievement.streak_3.title",
            descriptionKey: "achievement.streak_3.description",
            icon: "flame.fill",
            category: .streak,
            requirement: 3
        ),
        Achievement(
            id: "streak_7",
            titleKey: "achievement.streak_7.title",
            descriptionKey: "achievement.streak_7.description",
            icon: "flame.fill",
            category: .streak,
            requirement: 7
        ),
        Achievement(
            id: "streak_14",
            titleKey: "achievement.streak_14.title",
            descriptionKey: "achievement.streak_14.description",
            icon: "flame.fill",
            category: .streak,
            requirement: 14
        ),
        Achievement(
            id: "streak_21",
            titleKey: "achievement.streak_21.title",
            descriptionKey: "achievement.streak_21.description",
            icon: "flame.fill",
            category: .streak,
            requirement: 21
        ),
        Achievement(
            id: "streak_30",
            titleKey: "achievement.streak_30.title",
            descriptionKey: "achievement.streak_30.description",
            icon: "flame.fill",
            category: .streak,
            requirement: 30
        ),
        Achievement(
            id: "streak_40",
            titleKey: "achievement.streak_40.title",
            descriptionKey: "achievement.streak_40.description",
            icon: "flame.fill",
            category: .streak,
            requirement: 40
        ),
        Achievement(
            id: "streak_50",
            titleKey: "achievement.streak_50.title",
            descriptionKey: "achievement.streak_50.description",
            icon: "flame.fill",
            category: .streak,
            requirement: 50
        ),
        Achievement(
            id: "streak_60",
            titleKey: "achievement.streak_60.title",
            descriptionKey: "achievement.streak_60.description",
            icon: "flame.fill",
            category: .streak,
            requirement: 60
        ),
        Achievement(
            id: "streak_66",
            titleKey: "achievement.streak_66.title",
            descriptionKey: "achievement.streak_66.description",
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
