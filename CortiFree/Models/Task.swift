//
//  Task.swift
//  CortiFree
//
//  Created by Claude on 22/10/2025.
//

import Foundation
import FirebaseFirestore

enum TaskCategory: String, Codable, CaseIterable {
    case morning = "morning"
    case day = "day"
    case night = "night"

    var displayName: String {
        switch self {
        case .morning: return "Dès le réveil"
        case .day: return "Durant la journée"
        case .night: return "Avant de se coucher"
        }
    }

    var icon: String {
        switch self {
        case .morning: return "sunrise.fill"
        case .day: return "sun.max.fill"
        case .night: return "moon.stars.fill"
        }
    }
}

enum TaskFrequency: String, Codable, CaseIterable {
    case once = "once"
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"

    var displayName: String {
        switch self {
        case .once: return "Aujourd'hui seulement"
        case .daily: return "Tous les jours"
        case .weekly: return "Une fois par semaine"
        case .monthly: return "Une fois par mois"
        }
    }
}

enum CustomTaskCategory: String, Codable, CaseIterable {
    case breathing = "breathing"
    case movement = "movement"
    case nutrition = "nutrition"
    case mental = "mental"
    case environment = "environment"
    case creativity = "creativity"
    case digital = "digital"
    case sleep = "sleep"
    case sensory = "sensory"

    var displayName: String {
        switch self {
        case .breathing: return "Respiration"
        case .movement: return "Mouvement"
        case .nutrition: return "Nutrition"
        case .mental: return "Mental"
        case .environment: return "Environnement"
        case .creativity: return "Créativité"
        case .digital: return "Digital"
        case .sleep: return "Sommeil"
        case .sensory: return "Sensoriel"
        }
    }

    var icon: String {
        switch self {
        case .breathing: return "wind"
        case .movement: return "figure.walk"
        case .nutrition: return "leaf.fill"
        case .mental: return "brain.head.profile"
        case .environment: return "house.fill"
        case .creativity: return "paintbrush.fill"
        case .digital: return "iphone"
        case .sleep: return "moon.stars.fill"
        case .sensory: return "eye.fill"
        }
    }
}

struct TaskItem: Codable, Identifiable {
    @DocumentID var id: String?
    var title: String
    var category: TaskCategory
    var completed: Bool
    var frequency: Int // Times per day/week (legacy)
    var goalType: String
    var createdAt: Timestamp
    var completedAt: Timestamp?

    // New properties for custom tasks
    var taskFrequency: TaskFrequency?
    var customCategory: CustomTaskCategory?
    var durationInMinutes: Int?
    var isCustomTask: Bool
    var icon: String? // Emoji or SF Symbol for task
    var sfSymbol: String? // SF Symbol icon name (e.g., "wind", "figure.meditation")
    var recommendedTime: String? // Recommended time for task (e.g., "07:00", "14:30")
    var taskDescription: String? // Description of benefits/why to do this task

    init(id: String? = nil,
         title: String,
         category: TaskCategory,
         completed: Bool = false,
         frequency: Int = 1,
         goalType: String = "equilibre",
         createdAt: Timestamp = Timestamp(),
         completedAt: Timestamp? = nil,
         taskFrequency: TaskFrequency? = nil,
         customCategory: CustomTaskCategory? = nil,
         durationInMinutes: Int? = nil,
         isCustomTask: Bool = false,
         icon: String? = nil,
         sfSymbol: String? = nil,
         recommendedTime: String? = nil,
         taskDescription: String? = nil) {
        self.id = id
        self.title = title
        self.category = category
        self.completed = completed
        self.frequency = frequency
        self.goalType = goalType
        self.createdAt = createdAt
        self.completedAt = completedAt
        self.taskFrequency = taskFrequency
        self.customCategory = customCategory
        self.durationInMinutes = durationInMinutes
        self.isCustomTask = isCustomTask
        self.icon = icon
        self.sfSymbol = sfSymbol
        self.recommendedTime = recommendedTime
        self.taskDescription = taskDescription
    }

    // Default tasks that appear on app launch
    static let defaultTasks: [TaskItem] = [
        TaskItem(
            title: "Respiration 4-7-8",
            category: .morning,
            taskFrequency: .once,
            customCategory: .breathing,
            durationInMinutes: 5,
            icon: "🌬️"
        ),
        TaskItem(
            title: "Méditer 5 minutes",
            category: .morning,
            taskFrequency: .once,
            customCategory: .mental,
            durationInMinutes: 5,
            icon: "🧘"
        ),
        TaskItem(
            title: "S'étirer doucement",
            category: .day,
            taskFrequency: .once,
            customCategory: .movement,
            durationInMinutes: 10,
            icon: "🤸"
        ),
        TaskItem(
            title: "Boire un verre d'eau",
            category: .day,
            taskFrequency: .once,
            customCategory: .nutrition,
            durationInMinutes: 2,
            icon: "💧"
        ),
        TaskItem(
            title: "Éteindre les écrans",
            category: .night,
            taskFrequency: .once,
            customCategory: .digital,
            durationInMinutes: 5,
            icon: "📵"
        )
    ]
}
