//
//  TaskDetail.swift
//  CortiFree
//
//  Created by Claude on 10/11/2025.
//  Detailed task information from local JSON database
//

import Foundation
import SwiftUI

// MARK: - Task Database Structure

struct TaskDatabase: Codable {
    let metadata: TaskMetadata
    let progressionSystem: ProgressionSystem
    let categories: [TaskCategoryInfo]

    enum CodingKeys: String, CodingKey {
        case metadata
        case progressionSystem = "progression_system"
        case categories
    }
}

struct TaskMetadata: Codable {
    let version: String
    let totalTasks: Int
    let categories: Int
    let created: String
    let description: String

    enum CodingKeys: String, CodingKey {
        case version
        case totalTasks = "total_tasks"
        case categories
        case created
        case description
    }
}

struct ProgressionSystem: Codable {
    let description: String
    let week1_2: ProgressionWeek
    let week3_4: ProgressionWeek
    let week5_6: ProgressionWeek
    let week7_9: ProgressionWeek

    enum CodingKeys: String, CodingKey {
        case description
        case week1_2 = "week_1_2"
        case week3_4 = "week_3_4"
        case week5_6 = "week_5_6"
        case week7_9 = "week_7_9"
    }
}

struct ProgressionWeek: Codable {
    let difficulty: String
    let duration: String
    let focus: String
}

// MARK: - Task Category Info

struct TaskCategoryInfo: Codable, Identifiable {
    let id: String
    let name: String
    let icon: String
    let color: String
    let description: String
    let tasks: [TaskDetail]

    var colorValue: Color {
        Color(hex: color)
    }
}

// MARK: - Task Detail (Complete information)

struct TaskDetail: Codable, Identifiable {
    let id: String
    let title: String
    let icon: String
    let category: String
    let difficulty: String
    let durationMinutes: Int
    let xp: Int
    let tags: [String]
    let bestFor: [String]
    let whenToUse: String
    let description: String
    let whyItWorks: String
    let instructions: [String]
    let scientificReference: String?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case icon
        case category
        case difficulty
        case durationMinutes = "duration_minutes"
        case xp
        case tags
        case bestFor = "best_for"
        case whenToUse = "when_to_use"
        case description
        case whyItWorks = "why_it_works"
        case instructions
        case scientificReference = "scientific_reference"
    }

    // Difficulty level as enum
    var difficultyLevel: TaskDifficultyLevel {
        switch difficulty.lowercased() {
        case "débutant", "accessible":
            return .beginner
        case "intermédiaire", "tous niveaux":
            return .intermediate
        case "avancé", "expert":
            return .advanced
        default:
            return .beginner
        }
    }

    // Category as enum
    var categoryType: TaskCategoryType {
        TaskCategoryType(rawValue: category) ?? .breathing
    }
}

// MARK: - Enums

enum TaskDifficultyLevel: String, Codable {
    case beginner = "Débutant"
    case intermediate = "Intermédiaire"
    case advanced = "Avancé"

    var color: Color {
        switch self {
        case .beginner: return .green
        case .intermediate: return .orange
        case .advanced: return .red
        }
    }

    var icon: String {
        switch self {
        case .beginner: return "leaf.fill"
        case .intermediate: return "flame.fill"
        case .advanced: return "bolt.fill"
        }
    }
}

enum TaskCategoryType: String, Codable, CaseIterable {
    case breathing = "breathing"
    case meditation = "meditation"
    case journal = "journal"
    case movement = "movement"
    case education = "education"
    case screenLimit = "screen_limit"
    case creativity = "creativity"
    case nature = "nature"

    var displayName: String {
        switch self {
        case .breathing: return "Respiration"
        case .meditation: return "Méditation"
        case .journal: return "Journal"
        case .movement: return "Mouvement"
        case .education: return "Éducation"
        case .screenLimit: return "Limite Écran"
        case .creativity: return "Créativité"
        case .nature: return "Nature"
        }
    }

    var icon: String {
        switch self {
        case .breathing: return "wind"
        case .meditation: return "brain.head.profile"
        case .journal: return "book.closed.fill"
        case .movement: return "figure.run"
        case .education: return "graduationcap.fill"
        case .screenLimit: return "iphone.slash"
        case .creativity: return "paintpalette.fill"
        case .nature: return "leaf.fill"
        }
    }

    var color: Color {
        switch self {
        case .breathing: return Color(hex: "3498DB")
        case .meditation: return Color(hex: "9B59B6")
        case .journal: return Color(hex: "E67E22")
        case .movement: return Color(hex: "E74C3C")
        case .education: return Color(hex: "3498DB")
        case .screenLimit: return Color(hex: "34495E")
        case .creativity: return Color(hex: "F39C12")
        case .nature: return Color(hex: "27AE60")
        }
    }
}

// MARK: - Lightweight Task (for Firestore)

struct TaskReference: Codable, Identifiable {
    var id: String  // Task ID from JSON
    var completed: Bool = false
    var completedAt: Date?

    init(id: String, completed: Bool = false, completedAt: Date? = nil) {
        self.id = id
        self.completed = completed
        self.completedAt = completedAt
    }
}

// MARK: - User Daily Program (Firestore)

struct UserDailyProgram: Codable, Identifiable {
    var id: String?  // Firestore document ID
    var userId: String
    var routineId: String  // "master-mind", "recover-sleep", etc.
    var dayNumber: Int  // 1-66
    var taskIds: [String]  // References to tasks in JSON
    var date: Date
    var completedTaskIds: [String] = []

    var allTasksCompleted: Bool {
        Set(taskIds).isSubset(of: Set(completedTaskIds))
    }

    var progress: Double {
        guard !taskIds.isEmpty else { return 0 }
        return Double(completedTaskIds.count) / Double(taskIds.count)
    }
}
