//
//  UserSettings.swift
//  CortiFree
//
//  Created by Claude on 16/11/2025.
//  Stockage des préférences utilisateur et configuration personnalisée
//

import Foundation
import FirebaseFirestore

struct UserSettings: Codable {
    // MARK: - Program Settings
    var programStartDate: Date // Date de début du programme (jour 1)
    var onboardingScore: Int // Score initial du quiz (0-100)

    // MARK: - Sleep Settings
    var wakeUpTime: String // Format "HH:mm" ex: "07:00"
    var bedTime: String // Format "HH:mm" ex: "23:00"

    // MARK: - Habit Preferences
    var preferredSportActivities: [String] // IDs des activités sportives préférées
    var preferredNatureActivities: [String] // IDs des activités nature préférées
    var preferredSocialActivities: [String] // IDs des activités sociales préférées

    // MARK: - Notification Settings
    var notificationsEnabled: Bool
    var morningReminderTime: String? // Format "HH:mm"
    var eveningReminderTime: String? // Format "HH:mm"

    // MARK: - Computed Properties

    /// Calcule le jour actuel du programme (1-66+)
    var currentProgramDay: Int {
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: programStartDate, to: Date()).day ?? 0
        return max(1, days + 1) // Jour 1 = jour de début
    }

    /// Calcule la semaine actuelle (1-10)
    var currentWeek: Int {
        return WeeklyHabitProgression.currentWeek(for: currentProgramDay)
    }

    /// Vérifie si on est dans les 66 premiers jours
    var isInInitialProgram: Bool {
        return currentProgramDay <= 66
    }

    // MARK: - Initialization

    init(
        programStartDate: Date = UserSettings.calculateProgramStartDate(),
        onboardingScore: Int = 50,
        wakeUpTime: String = "07:00",
        bedTime: String = "23:00",
        preferredSportActivities: [String] = [],
        preferredNatureActivities: [String] = [],
        preferredSocialActivities: [String] = [],
        notificationsEnabled: Bool = true,
        morningReminderTime: String? = "08:00",
        eveningReminderTime: String? = "20:00"
    ) {
        self.programStartDate = programStartDate
        self.onboardingScore = onboardingScore
        self.wakeUpTime = wakeUpTime
        self.bedTime = bedTime
        self.preferredSportActivities = preferredSportActivities
        self.preferredNatureActivities = preferredNatureActivities
        self.preferredSocialActivities = preferredSocialActivities
        self.notificationsEnabled = notificationsEnabled
        self.morningReminderTime = morningReminderTime
        self.eveningReminderTime = eveningReminderTime
    }

    // MARK: - Program Start Date Calculation

    /// Calcule la date de début du programme
    /// Le programme commence toujours aujourd'hui à minuit (jour 1)
    /// Le passage au jour suivant se fait à minuit fuseau horaire utilisateur
    static func calculateProgramStartDate() -> Date {
        let todayMidnight = Calendar.current.startOfDay(for: Date())
        #if DEBUG
        print("📅 Program starts today at midnight - Day 1/66")
        #endif
        return todayMidnight
    }

    // MARK: - Firestore Conversion

    func toFirestore() -> [String: Any] {
        return [
            "programStartDate": Timestamp(date: programStartDate),
            "onboardingScore": onboardingScore,
            "wakeUpTime": wakeUpTime,
            "bedTime": bedTime,
            "preferredSportActivities": preferredSportActivities,
            "preferredNatureActivities": preferredNatureActivities,
            "preferredSocialActivities": preferredSocialActivities,
            "notificationsEnabled": notificationsEnabled,
            "morningReminderTime": morningReminderTime as Any,
            "eveningReminderTime": eveningReminderTime as Any
        ]
    }

    static func from(document: DocumentSnapshot) -> UserSettings? {
        guard let data = document.data() else { return nil }

        let programStartDate = (data["programStartDate"] as? Timestamp)?.dateValue() ?? Date()
        let onboardingScore = data["onboardingScore"] as? Int ?? 50
        let wakeUpTime = data["wakeUpTime"] as? String ?? "07:00"
        let bedTime = data["bedTime"] as? String ?? "23:00"
        let preferredSportActivities = data["preferredSportActivities"] as? [String] ?? []
        let preferredNatureActivities = data["preferredNatureActivities"] as? [String] ?? []
        let preferredSocialActivities = data["preferredSocialActivities"] as? [String] ?? []
        let notificationsEnabled = data["notificationsEnabled"] as? Bool ?? true
        let morningReminderTime = data["morningReminderTime"] as? String
        let eveningReminderTime = data["eveningReminderTime"] as? String

        return UserSettings(
            programStartDate: programStartDate,
            onboardingScore: onboardingScore,
            wakeUpTime: wakeUpTime,
            bedTime: bedTime,
            preferredSportActivities: preferredSportActivities,
            preferredNatureActivities: preferredNatureActivities,
            preferredSocialActivities: preferredSocialActivities,
            notificationsEnabled: notificationsEnabled,
            morningReminderTime: morningReminderTime,
            eveningReminderTime: eveningReminderTime
        )
    }

    // MARK: - UserDefaults Storage (for offline access)

    private static let userDefaultsKey = "UserSettings"

    func saveToUserDefaults() {
        if let encoded = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(encoded, forKey: Self.userDefaultsKey)
        }
    }

    static func loadFromUserDefaults() -> UserSettings? {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let settings = try? JSONDecoder().decode(UserSettings.self, from: data) else {
            return nil
        }
        return settings
    }
}

// MARK: - Habit Tracking Model

struct HabitTracking: Codable {
    let habitId: String
    let habitTitle: String
    var currentStreak: Int
    var longestStreak: Int
    var totalCompletions: Int
    var firstCompletedDate: Date?
    var lastCompletedDate: Date?
    var last7Days: [Bool] // Historique des 7 derniers jours
    var completedDays: [Int] // Jours du programme complétés (1-66+)

    init(habitId: String, habitTitle: String) {
        self.habitId = habitId
        self.habitTitle = habitTitle
        self.currentStreak = 0
        self.longestStreak = 0
        self.totalCompletions = 0
        self.firstCompletedDate = nil
        self.lastCompletedDate = nil
        self.last7Days = [false, false, false, false, false, false, false]
        self.completedDays = []
    }

    // MARK: - Firestore Conversion

    func toFirestore() -> [String: Any] {
        var data: [String: Any] = [
            "habitId": habitId,
            "habitTitle": habitTitle,
            "currentStreak": currentStreak,
            "longestStreak": longestStreak,
            "totalCompletions": totalCompletions,
            "last7Days": last7Days,
            "completedDays": completedDays
        ]

        if let firstCompletedDate = firstCompletedDate {
            data["firstCompletedDate"] = Timestamp(date: firstCompletedDate)
        }

        if let lastCompletedDate = lastCompletedDate {
            data["lastCompletedDate"] = Timestamp(date: lastCompletedDate)
        }

        return data
    }

    static func from(document: DocumentSnapshot) -> HabitTracking? {
        guard let data = document.data() else { return nil }

        guard let habitId = data["habitId"] as? String,
              let habitTitle = data["habitTitle"] as? String else { return nil }

        var tracking = HabitTracking(habitId: habitId, habitTitle: habitTitle)
        tracking.currentStreak = data["currentStreak"] as? Int ?? 0
        tracking.longestStreak = data["longestStreak"] as? Int ?? 0
        tracking.totalCompletions = data["totalCompletions"] as? Int ?? 0
        tracking.last7Days = data["last7Days"] as? [Bool] ?? [false, false, false, false, false, false, false]
        tracking.completedDays = data["completedDays"] as? [Int] ?? []

        if let timestamp = data["firstCompletedDate"] as? Timestamp {
            tracking.firstCompletedDate = timestamp.dateValue()
        }

        if let timestamp = data["lastCompletedDate"] as? Timestamp {
            tracking.lastCompletedDate = timestamp.dateValue()
        }

        return tracking
    }

    // MARK: - Helper Methods

    mutating func markCompleted(on date: Date = Date()) {
        // Setup timezone-aware calendar
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current

        // Use startOfDay for proper day comparison
        let todayStart = calendar.startOfDay(for: date)

        // Calculate streak BEFORE updating lastCompletedDate
        if let lastDate = lastCompletedDate {
            let lastStart = calendar.startOfDay(for: lastDate)
            let daysDiff = calendar.dateComponents([.day], from: lastStart, to: todayStart).day ?? 0

            if daysDiff == 1 {
                // Yesterday completed -> continue streak
                currentStreak += 1
            } else if daysDiff > 1 {
                // Missed day(s) -> reset streak
                currentStreak = 1
            }
            // daysDiff == 0: same day, don't change streak
        } else {
            // First completion ever
            currentStreak = 1
        }

        // Update longest streak
        longestStreak = max(longestStreak, currentStreak)

        // Now update completion date
        lastCompletedDate = date
        if firstCompletedDate == nil {
            firstCompletedDate = date
        }

        // Update total completions
        totalCompletions += 1

        // Update last 7 days (shift array and add today as true)
        last7Days.removeFirst()
        last7Days.append(true)
    }

    mutating func updateLast7Days(from completions: [Date]) {
        let calendar = Calendar.current
        let today = Date()

        last7Days = (0..<7).reversed().map { daysAgo in
            guard let targetDate = calendar.date(byAdding: .day, value: -daysAgo, to: today) else {
                return false
            }

            return completions.contains { date in
                calendar.isDate(date, inSameDayAs: targetDate)
            }
        }
    }
}