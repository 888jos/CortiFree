//
//  HabitGoal.swift
//  CortiFree
//
//  Created by Claude on 18/11/2025.
//  Modèles pour les objectifs d'habitudes personnalisables
//

import Foundation
import FirebaseFirestore

// MARK: - Habit Goal Model

struct HabitGoal: Codable {
    let habitId: String
    var frequencyPerWeek: Int // Nombre de fois par semaine
    var durationMinutes: Int? // Durée en minutes (optionnel pour certaines habitudes)
    var dailyQuantity: Float? // Quantité journalière (ex: litres d'eau, heures de sommeil)
    var effectiveFrom: Date // Date à partir de laquelle cet objectif s'applique
    var isActive: Bool

    init(
        habitId: String,
        frequencyPerWeek: Int,
        durationMinutes: Int? = nil,
        dailyQuantity: Float? = nil,
        effectiveFrom: Date = Date(),
        isActive: Bool = true
    ) {
        self.habitId = habitId
        self.frequencyPerWeek = frequencyPerWeek
        self.durationMinutes = durationMinutes
        self.dailyQuantity = dailyQuantity
        self.effectiveFrom = effectiveFrom
        self.isActive = isActive
    }

    // MARK: - Firestore Conversion

    func toFirestore() -> [String: Any] {
        var data: [String: Any] = [
            "habitId": habitId,
            "frequencyPerWeek": frequencyPerWeek,
            "effectiveFrom": Timestamp(date: effectiveFrom),
            "isActive": isActive
        ]

        if let duration = durationMinutes {
            data["durationMinutes"] = duration
        }

        if let quantity = dailyQuantity {
            data["dailyQuantity"] = quantity
        }

        return data
    }

    static func from(document: DocumentSnapshot) -> HabitGoal? {
        guard let data = document.data(),
              let habitId = data["habitId"] as? String,
              let frequencyPerWeek = data["frequencyPerWeek"] as? Int else {
            return nil
        }

        let effectiveFrom = (data["effectiveFrom"] as? Timestamp)?.dateValue() ?? Date()
        let isActive = data["isActive"] as? Bool ?? true
        let durationMinutes = data["durationMinutes"] as? Int
        let dailyQuantity = data["dailyQuantity"] as? Float

        return HabitGoal(
            habitId: habitId,
            frequencyPerWeek: frequencyPerWeek,
            durationMinutes: durationMinutes,
            dailyQuantity: dailyQuantity,
            effectiveFrom: effectiveFrom,
            isActive: isActive
        )
    }

    // MARK: - Display Helpers

    var formattedFrequency: String {
        if frequencyPerWeek >= 7 {
            return NSLocalizedString("profile.habit.frequency.daily", comment: "")
        } else {
            return "\(frequencyPerWeek)x/\(NSLocalizedString("profile.habit.frequency.week", comment: ""))"
        }
    }

    var formattedDuration: String? {
        guard let duration = durationMinutes else { return nil }
        return "\(duration) min"
    }

    var formattedQuantity: String? {
        guard let quantity = dailyQuantity else { return nil }

        // Format selon le type d'habitude
        switch habitId {
        case "water":
            return String(format: "%.1fL", quantity).replacingOccurrences(of: ".0L", with: "L")
        case "sleep":
            return String(format: "%.1fh", quantity).replacingOccurrences(of: ".0h", with: "h")
        default:
            return String(format: "%.1f", quantity)
        }
    }
}

// MARK: - Habit Performance (Current Reality)

struct HabitPerformance: Codable {
    let habitId: String
    let last7Days: [Bool] // Historique des 7 derniers jours (true = complété ce jour-là)
    let currentStreak: Int
    let averageCompletionsPerWeek: Float // Moyenne de completions sur les 7 derniers jours
    let averageDurationMinutes: Float? // Durée moyenne (si applicable)
    let averageDailyQuantity: Float? // Quantité moyenne (si applicable)

    // MARK: - Display Helpers

    var completionRate: Float {
        let completedDays = last7Days.filter { $0 }.count
        return Float(completedDays) / 7.0
    }

    var formattedCompletionRate: String {
        let percentage = Int(completionRate * 100)
        return "\(percentage)%"
    }

    var formattedAverageFrequency: String {
        let avgPerWeek = Int(round(averageCompletionsPerWeek))
        if avgPerWeek >= 7 {
            return NSLocalizedString("profile.habit.frequency.daily", comment: "")
        } else {
            return "\(avgPerWeek)x/\(NSLocalizedString("profile.habit.frequency.week", comment: ""))"
        }
    }

    var formattedAverageDuration: String? {
        guard let duration = averageDurationMinutes else { return nil }
        // Arrondir au multiple de 5 le plus proche
        let roundedDuration = Int(round(duration / 5.0) * 5.0)
        return "\(roundedDuration) min"
    }

    var formattedAverageQuantity: String? {
        guard let quantity = averageDailyQuantity else { return nil }

        switch habitId {
        case "water":
            return String(format: "%.1fL", quantity).replacingOccurrences(of: ".0L", with: "L")
        case "sleep":
            return String(format: "%.1fh", quantity).replacingOccurrences(of: ".0h", with: "h")
        default:
            return String(format: "%.1f", quantity)
        }
    }
}

// MARK: - Default Goals (based on Week 10 progression)

extension HabitGoal {
    static func defaultGoals() -> [HabitGoal] {
        return [
            // Méditation: Semaine 10 = 7x/sem, 15 min (arrondi de 13)
            HabitGoal(habitId: "meditation", frequencyPerWeek: 7, durationMinutes: 15),

            // Respiration: Semaine 10 = 7x/sem, 10 min
            HabitGoal(habitId: "breathing", frequencyPerWeek: 7, durationMinutes: 10),

            // Journal: Semaine 10 = 7x/sem, 10 min
            HabitGoal(habitId: "journal", frequencyPerWeek: 7, durationMinutes: 10),

            // Sport: Semaine 10 = 4x/sem, 55 min (arrondi de 53)
            HabitGoal(habitId: "sport", frequencyPerWeek: 4, durationMinutes: 55),

            // Eau: Semaine 10 = 2.5L/jour
            HabitGoal(habitId: "water", frequencyPerWeek: 7, dailyQuantity: 2.5),

            // Nature: Semaine 10 = 3x/sem, 70 min
            HabitGoal(habitId: "nature", frequencyPerWeek: 3, durationMinutes: 70),

            // Social: Semaine 10 = 4x/sem, 60 min
            HabitGoal(habitId: "social", frequencyPerWeek: 4, durationMinutes: 60),

            // Sommeil: Semaine 10 = routine 20 min, 8h sommeil
            HabitGoal(habitId: "sleep", frequencyPerWeek: 7, durationMinutes: 20, dailyQuantity: 8.0)
        ]
    }
}
