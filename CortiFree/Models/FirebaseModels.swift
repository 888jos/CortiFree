//
//  FirebaseModels.swift
//  CortiFree
//
//  Created by Claude on 09/11/2025.
//  Firebase Firestore data models
//

import Foundation
import FirebaseFirestore

// MARK: - User Model

struct UserProfile: Codable, Identifiable {
    @DocumentID var id: String?
    var uid: String
    var email: String
    var displayName: String?
    var photoURL: String?
    var createdAt: Timestamp
    var lastLogin: Timestamp
    var onboardingCompleted: Bool
    var onboardingCompletedAt: Timestamp?
    var selectedRoutineId: String?
    var currentWeek: Int
    var currentDay: Int
    var totalXP: Int
    var level: Int
    var currentStreakDays: Int
    var longestStreakDays: Int
    var preferredMoments: [String]
    var notificationSettings: NotificationSettings
    var mixpanelDistinctId: String?

    init(
        uid: String,
        email: String,
        displayName: String? = nil,
        photoURL: String? = nil
    ) {
        self.uid = uid
        self.email = email
        self.displayName = displayName
        self.photoURL = photoURL
        self.createdAt = Timestamp()
        self.lastLogin = Timestamp()
        self.onboardingCompleted = false
        self.currentWeek = 1
        self.currentDay = 1
        self.totalXP = 0
        self.level = 1
        self.currentStreakDays = 0
        self.longestStreakDays = 0
        self.preferredMoments = ["morning", "evening"]
        self.notificationSettings = NotificationSettings()
    }
}

struct NotificationSettings: Codable {
    var morningTime: String
    var eveningTime: String
    var enabled: Bool

    init() {
        self.morningTime = "08:00"
        self.eveningTime = "21:00"
        self.enabled = true
    }
}

// MARK: - Routine Models

struct RoutineModel: Codable, Identifiable {
    @DocumentID var id: String?
    var routineId: String
    var title: String
    var description: String
    var objective: String
    var durationWeeks: Int
    var icon: String
    var category: String
    var difficultyLevel: Int
    var tags: [String]
    var createdAt: Timestamp
    var updatedAt: Timestamp
    var isActive: Bool
}

struct RoutineWeek: Codable, Identifiable {
    @DocumentID var id: String?
    var weekNumber: Int
    var theme: String
}

struct DailyTask: Codable, Identifiable {
    @DocumentID var id: String?
    var dayNumber: Int
}

struct TaskModel: Codable, Identifiable {
    @DocumentID var id: String?
    var taskId: String
    var exerciseRef: String // Reference to exercise document
    var moment: String // "morning", "afternoon", "evening"
    var order: Int
    var isMandatory: Bool
    var unlockCondition: String?
    var estimatedDurationMinutes: Int
}

// MARK: - Exercise Models

struct ExerciseModel: Codable, Identifiable {
    @DocumentID var id: String?
    var exerciseId: String
    var type: String // "breathing", "meditation", "journaling", "grounding", "sound", "visualization"
    var title: String
    var description: String
    var instructions: [String]
    var durationMinutes: Int
    var difficulty: Int
    var benefits: [String]
    var icon: String
    var audioURL: String?
    var animationType: String?
    var parameters: [String: Any]?
    var tags: [String]
    var xpReward: Int
    var createdAt: Timestamp
    var isActive: Bool

    enum CodingKeys: String, CodingKey {
        case id, exerciseId, type, title, description, instructions
        case durationMinutes, difficulty, benefits, icon, audioURL
        case animationType, parameters, tags, xpReward, createdAt, isActive
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        exerciseId = try container.decode(String.self, forKey: .exerciseId)
        type = try container.decode(String.self, forKey: .type)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decode(String.self, forKey: .description)
        instructions = try container.decode([String].self, forKey: .instructions)
        durationMinutes = try container.decode(Int.self, forKey: .durationMinutes)
        difficulty = try container.decode(Int.self, forKey: .difficulty)
        benefits = try container.decode([String].self, forKey: .benefits)
        icon = try container.decode(String.self, forKey: .icon)
        audioURL = try container.decodeIfPresent(String.self, forKey: .audioURL)
        animationType = try container.decodeIfPresent(String.self, forKey: .animationType)
        tags = try container.decode([String].self, forKey: .tags)
        xpReward = try container.decode(Int.self, forKey: .xpReward)
        createdAt = try container.decode(Timestamp.self, forKey: .createdAt)
        isActive = try container.decode(Bool.self, forKey: .isActive)

        // Handle parameters as dictionary
        if let params = try container.decodeIfPresent([String: String].self, forKey: .parameters) {
            parameters = params
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(exerciseId, forKey: .exerciseId)
        try container.encode(type, forKey: .type)
        try container.encode(title, forKey: .title)
        try container.encode(description, forKey: .description)
        try container.encode(instructions, forKey: .instructions)
        try container.encode(durationMinutes, forKey: .durationMinutes)
        try container.encode(difficulty, forKey: .difficulty)
        try container.encode(benefits, forKey: .benefits)
        try container.encode(icon, forKey: .icon)
        try container.encodeIfPresent(audioURL, forKey: .audioURL)
        try container.encodeIfPresent(animationType, forKey: .animationType)
        try container.encode(tags, forKey: .tags)
        try container.encode(xpReward, forKey: .xpReward)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(isActive, forKey: .isActive)
    }
}

// MARK: - User Progress Models

struct RoutineProgress: Codable, Identifiable {
    @DocumentID var id: String?
    var routineId: String
    var startedAt: Timestamp
    var currentWeek: Int
    var currentDay: Int
    var completionPercentage: Double
    var isActive: Bool
    var completedAt: Timestamp?
    var totalTasksCompleted: Int
    var totalTasks: Int
    var adherenceScore: Double
}

struct DailyProgress: Codable, Identifiable {
    @DocumentID var id: String?
    var date: String // "2025-11-09"
    var weekNumber: Int
    var dayNumber: Int
    var completedTasks: Int
    var totalTasks: Int
    var completionRate: Double
    var xpEarned: Int
    var moodMorning: String?
    var moodEvening: String?
    var energyLevel: Int?
    var stressLevel: Int?
    var notes: String?
    var createdAt: Timestamp
}

struct CompletedTask: Codable, Identifiable {
    @DocumentID var id: String?
    var taskId: String
    var exerciseId: String
    var routineId: String
    var weekNumber: Int
    var dayNumber: Int
    var moment: String
    var completedAt: Timestamp
    var durationActualSeconds: Int
    var xpEarned: Int
    var feedbackMood: String?
    var feedbackNote: String?
    var wasManual: Bool
    var deviceInfo: DeviceInfo?
}

struct DeviceInfo: Codable {
    var platform: String
    var version: String
}

struct CustomTask: Codable, Identifiable {
    @DocumentID var id: String?
    var exerciseId: String
    var title: String
    var moment: String
    var reminderTime: String?
    var isActive: Bool
    var createdAt: Timestamp
    var recurrence: String // "daily", "weekly", "custom"
}

struct FeedbackModel: Codable, Identifiable {
    @DocumentID var id: String?
    var type: String // "exercise_completion", "general", "bug_report"
    var exerciseId: String?
    var mood: String
    var rating: Int?
    var note: String?
    var timestamp: Timestamp
    var context: FeedbackContext?
}

struct FeedbackContext: Codable {
    var routineId: String?
    var week: Int?
    var day: Int?
}

// MARK: - AI Insights Models

struct AIInsight: Codable, Identifiable {
    @DocumentID var id: String?
    var generatedAt: Timestamp
    var insightType: String // "routine_adjustment", "recommendation", "warning"
    var trigger: String
    var dataAnalyzed: AnalyzedData
    var recommendation: String
    var suggestedExercises: [String]
    var priority: String // "low", "medium", "high"
    var isApplied: Bool
    var appliedAt: Timestamp?
}

struct AnalyzedData: Codable {
    var period: String
    var completionRate: Double?
    var avgMood: String?
    var fatigueSignals: Int?
    var negativeSignals: Int?
}

// MARK: - Stats Models

struct WeeklySummary: Codable {
    var weekStart: String
    var totalTasksCompleted: Int
    var totalXPEarned: Int
    var avgCompletionRate: Double
    var dominantMood: String
    var mostActiveMoment: String
    var generatedAt: Timestamp
}

// MARK: - Onboarding Models

struct OnboardingQuestion: Codable, Identifiable {
    @DocumentID var id: String?
    var questionId: String
    var screenNumber: Int
    var category: String
    var questionText: String
    var type: String // "scale", "multiple_choice", "text", "multi_select"
    var options: [String]?
    var scaleMin: Int?
    var scaleMax: Int?
    var isRequired: Bool
    var affectsRoutineSelection: Bool
    var weightInAlgorithm: Double?
    var order: Int
}

struct OnboardingResponse: Codable, Identifiable {
    @DocumentID var id: String?
    var questionId: String
    var response: String
    var score: Int?
    var answeredAt: Timestamp
}
