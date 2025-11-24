//
//  HabitConfiguration.swift
//  CortiFree
//
//  Created by Claude on 21/11/2025.
//  Configuration centralisée pour les habitudes et la logique métier
//

import Foundation

enum HabitConfiguration {
    // MARK: - Habit ID Mapping

    /// Map image asset name to habit ID
    /// - Parameter imageName: The image asset name used in the UI
    /// - Returns: The standardized habit ID, or nil if unknown
    static func habitID(from imageName: String) -> String? {
        switch imageName {
        case "habit_sleep":
            return AppConstants.Habits.ID.sleep
        case "habit_breathing":
            return AppConstants.Habits.ID.breathing
        case "habit_meditation":
            return AppConstants.Habits.ID.meditation
        case "habit_water":
            return AppConstants.Habits.ID.water
        case "habit_sport":
            return AppConstants.Habits.ID.sport
        case "habit_nature":
            return AppConstants.Habits.ID.nature
        case "habit_social":
            return AppConstants.Habits.ID.social
        case "habit_journal":
            return AppConstants.Habits.ID.journal
        default:
            return nil
        }
    }

    // MARK: - Frequency Distribution Logic

    /// Determine if a task should be shown on a specific day based on frequency
    /// - Parameters:
    ///   - dayOfWeek: The day of the week (1 = Monday, 7 = Sunday)
    ///   - frequencyPerWeek: Number of times per week the task should appear
    /// - Returns: True if the task should be displayed on this day
    static func shouldShowTask(dayOfWeek: Int, frequencyPerWeek: Int) -> Bool {
        switch frequencyPerWeek {
        case 7: // Daily
            return true
        case 5: // 5x per week (Monday to Friday)
            return dayOfWeek <= 5
        case 4: // 4x per week (Monday, Wednesday, Friday, Sunday)
            return [1, 3, 5, 7].contains(dayOfWeek)
        case 3: // 3x per week (Monday, Wednesday, Friday)
            return [1, 3, 5].contains(dayOfWeek)
        case 2: // 2x per week (Wednesday, Saturday)
            return [3, 6].contains(dayOfWeek)
        case 1: // 1x per week (Sunday)
            return dayOfWeek == 7
        default:
            return false
        }
    }

    // MARK: - Firebase Key Formatting

    /// Generate standardized Firebase day key
    /// - Parameter day: The program day number (1-66+)
    /// - Returns: Formatted key string (e.g., "day_01", "day_66")
    static func dayKey(_ day: Int) -> String {
        return String(format: "day_%02d", day)
    }

    // MARK: - Habit Display Information

    /// Get display information for a habit
    /// - Parameter habitId: The habit ID
    /// - Returns: A tuple with image name and SF Symbol icon, or nil if unknown
    static func displayInfo(for habitId: String) -> (imageName: String, iconName: String)? {
        switch habitId {
        case AppConstants.Habits.ID.sleep:
            return ("habit_sleep", "moon.zzz.fill")
        case AppConstants.Habits.ID.breathing:
            return ("habit_breathing", "wind")
        case AppConstants.Habits.ID.meditation:
            return ("habit_meditation", "sparkles")
        case AppConstants.Habits.ID.water:
            return ("habit_water", "drop.fill")
        case AppConstants.Habits.ID.sport:
            return ("habit_sport", "figure.run")
        case AppConstants.Habits.ID.nature:
            return ("habit_nature", "leaf.fill")
        case AppConstants.Habits.ID.social:
            return ("habit_social", "person.2.fill")
        case AppConstants.Habits.ID.journal:
            return ("habit_journal", "book.fill")
        default:
            return nil
        }
    }

    // MARK: - Week Calculation

    /// Calculate current week from program day
    /// - Parameter programDay: The day number in the program (1-66+)
    /// - Returns: The week number (1-10+)
    static func weekNumber(for programDay: Int) -> Int {
        return min(((programDay - 1) / AppConstants.Program.daysPerWeek) + 1, AppConstants.Program.totalWeeks)
    }

    // MARK: - Frequency String Helpers

    /// Get frequency count from frequency string
    /// - Parameter frequency: The frequency string (e.g., "daily", "5x/week")
    /// - Returns: The number of times per week
    static func frequencyCount(from frequency: String) -> Int {
        switch frequency.lowercased() {
        case "daily", "quotidien":
            return 7
        case "5x/week", "5x/semaine":
            return 5
        case "4x/week", "4x/semaine":
            return 4
        case "3x/week", "3x/semaine":
            return 3
        case "2x/week", "2x/semaine":
            return 2
        case "1x/week", "1x/semaine":
            return 1
        default:
            // Try to extract number from string like "5x/week"
            if let match = frequency.range(of: #"\d+"#, options: .regularExpression),
               let count = Int(frequency[match]) {
                return count
            }
            return 7 // Default to daily
        }
    }
}
