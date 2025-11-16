//
//  HabitProgressionModel.swift
//  CortiFree
//
//  Created by Claude on 15/11/2025.
//  Système de progression des habitudes sur 10 semaines (66 jours)
//

import Foundation

struct HabitProgression {
    let frequencyPerWeek: Int // Nombre de fois par semaine
    let duration: Int? // En minutes (optionnel pour certaines habitudes)
    let quantity: Float? // Ex: 2.5 pour l'eau en litres

    // Format display string
    var formattedFrequency: String {
        if frequencyPerWeek >= 7 {
            return "Quotidien"
        } else {
            return "\(frequencyPerWeek)x/sem"
        }
    }

    var formattedQuantity: String? {
        guard let quantity = quantity else { return nil }
        // Format for water in liters
        if quantity >= 1 {
            return String(format: "%.1fL", quantity).replacingOccurrences(of: ".0L", with: "L")
        } else {
            return "\(Int(quantity * 1000))ml"
        }
    }
}

struct WeeklyHabitProgression {

    // MARK: - Calcul de la semaine actuelle
    static func currentWeek(for day: Int) -> Int {
        if day <= 7 { return 1 }
        else if day <= 14 { return 2 }
        else if day <= 21 { return 3 }
        else if day <= 28 { return 4 }
        else if day <= 35 { return 5 }
        else if day <= 42 { return 6 }
        else if day <= 49 { return 7 }
        else if day <= 56 { return 8 }
        else if day <= 63 { return 9 }
        else { return 10 }
    }

    // MARK: - Progressions par habitude (avec progression CHAQUE semaine)

    // Respiration: 3x/sem 5min → 7x/sem 10min (1h total par semaine)
    static func breathingProgression(week: Int) -> HabitProgression {
        let clampedWeek = min(max(week, 1), 10)

        // Frequency: 3 → 7 times per week (linear progression)
        let frequency = 3 + (4 * (clampedWeek - 1)) / 9

        // Duration: 5 → 10 minutes (linear progression)
        let duration = 5 + (5 * (clampedWeek - 1)) / 9

        return HabitProgression(
            frequencyPerWeek: frequency,
            duration: duration,
            quantity: nil
        )
    }

    // Méditation: 2x/sem 5min → 7x/sem 13min (1h30 total par semaine)
    static func meditationProgression(week: Int) -> HabitProgression {
        let clampedWeek = min(max(week, 1), 10)

        // Frequency: 2 → 7 times per week
        let frequency = 2 + (5 * (clampedWeek - 1)) / 9

        // Duration: 5 → 13 minutes
        let duration = 5 + (8 * (clampedWeek - 1)) / 9

        return HabitProgression(
            frequencyPerWeek: frequency,
            duration: duration,
            quantity: nil
        )
    }

    // Journal: 2x/sem 5min → 7x/sem 10min
    static func journalProgression(week: Int) -> HabitProgression {
        let clampedWeek = min(max(week, 1), 10)

        // Frequency: 2 → 7 times per week
        let frequency = 2 + (5 * (clampedWeek - 1)) / 9

        // Duration: 5 → 10 minutes
        let duration = 5 + (5 * (clampedWeek - 1)) / 9

        return HabitProgression(
            frequencyPerWeek: frequency,
            duration: duration,
            quantity: nil
        )
    }

    // Sport: 2x/sem 20min → 4x/sem 53min (3h30 total par semaine)
    static func sportProgression(week: Int) -> HabitProgression {
        let clampedWeek = min(max(week, 1), 10)

        // Frequency: 2 → 4 times per week
        let frequency = 2 + (2 * (clampedWeek - 1)) / 9

        // Duration: 20 → 53 minutes
        let duration = 20 + (33 * (clampedWeek - 1)) / 9

        return HabitProgression(
            frequencyPerWeek: frequency,
            duration: duration,
            quantity: nil
        )
    }

    // Eau: 1L/jour → 2.5L/jour
    static func waterProgression(week: Int) -> HabitProgression {
        let clampedWeek = min(max(week, 1), 10)

        // Water: 1.0 → 2.5 liters
        let water = 1.0 + (1.5 * Float(clampedWeek - 1)) / 9.0

        return HabitProgression(
            frequencyPerWeek: 7, // Daily
            duration: nil,
            quantity: water
        )
    }

    // Nature: 1x/sem 30min → 3x/sem 70min (3h30 total par semaine)
    static func natureProgression(week: Int) -> HabitProgression {
        let clampedWeek = min(max(week, 1), 10)

        // Frequency: 1 → 3 times per week
        let frequency = 1 + (2 * (clampedWeek - 1)) / 9

        // Duration: 30 → 70 minutes
        let duration = 30 + (40 * (clampedWeek - 1)) / 9

        return HabitProgression(
            frequencyPerWeek: frequency,
            duration: duration,
            quantity: nil
        )
    }

    // Sommeil: Routine 10min → 20min + 7h → 8h sommeil
    static func sleepProgression(week: Int) -> HabitProgression {
        let clampedWeek = min(max(week, 1), 10)

        // Routine duration: 10 → 20 minutes
        let duration = 10 + (10 * (clampedWeek - 1)) / 9

        // Sleep hours: 7.0 → 8.0 hours
        let sleepHours = 7.0 + (1.0 * Float(clampedWeek - 1)) / 9.0

        return HabitProgression(
            frequencyPerWeek: 7, // Daily
            duration: duration,
            quantity: sleepHours
        )
    }

    // Social: 2x/sem 30min → 4x/sem 60min
    static func socialProgression(week: Int) -> HabitProgression {
        let clampedWeek = min(max(week, 1), 10)

        // Frequency: 2 → 4 times per week
        let frequency = 2 + (2 * (clampedWeek - 1)) / 9

        // Duration: 30 → 60 minutes
        let duration = 30 + (30 * (clampedWeek - 1)) / 9

        return HabitProgression(
            frequencyPerWeek: frequency,
            duration: duration,
            quantity: nil
        )
    }

    // MARK: - Format display strings

    static func formatProgressionDisplay(_ progression: HabitProgression) -> String {
        // For water habit - special case
        if let quantity = progression.quantity {
            return "\(progression.formattedQuantity ?? "")"
        }

        // For other habits with duration
        if let duration = progression.duration {
            return "\(duration) min"
        }

        return ""
    }

    // Special formatting for sleep
    static func formatSleepProgressionDisplay(_ progression: HabitProgression) -> String {
        if let duration = progression.duration {
            return "\(duration) min"
        }
        return ""
    }
}