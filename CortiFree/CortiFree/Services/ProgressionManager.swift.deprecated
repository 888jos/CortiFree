//
//  ProgressionManager.swift
//  CortiFree
//
//  Gestion de la progression XP et niveaux
//

import SwiftUI
import Combine

class ProgressionManager: ObservableObject {
    static let shared = ProgressionManager()

    // MARK: - Published Properties
    @Published var currentXP: Int = 0
    @Published var currentLevel: Level = Level.allLevels[0]
    @Published var showLevelUpPopup: Bool = false
    @Published var newlyUnlockedLevel: Level?
    @Published var streakDays: Int = 0
    @Published var lastActivityDate: Date?

    // UserDefaults keys
    private let xpKey = "userCurrentXP"
    private let streakKey = "userStreakDays"
    private let lastActivityKey = "userLastActivityDate"

    private init() {
        loadProgress()
        updateLevel()
    }

    // MARK: - Load & Save
    private func loadProgress() {
        currentXP = UserDefaults.standard.integer(forKey: xpKey)
        streakDays = UserDefaults.standard.integer(forKey: streakKey)

        if let lastActivityTimestamp = UserDefaults.standard.object(forKey: lastActivityKey) as? Date {
            lastActivityDate = lastActivityTimestamp
        }

        updateLevel()
    }

    private func saveProgress() {
        UserDefaults.standard.set(currentXP, forKey: xpKey)
        UserDefaults.standard.set(streakDays, forKey: streakKey)

        if let lastActivity = lastActivityDate {
            UserDefaults.standard.set(lastActivity, forKey: lastActivityKey)
        }
    }

    // MARK: - Add XP
    func addXP(_ action: XPAction) {
        let previousLevel = currentLevel

        currentXP += action.xpValue
        updateStreak()
        updateLevel()
        saveProgress()

        // Check for level up
        if currentLevel.id > previousLevel.id {
            newlyUnlockedLevel = currentLevel
            showLevelUpPopup = true
            HapticManager.success()
        } else {
            HapticManager.light()
        }

        print("✨ +\(action.xpValue) XP — \(action.rawValue)")
        print("📊 Total XP: \(currentXP) — Niveau \(currentLevel.id): \(currentLevel.name)")
    }

    // MARK: - Add Custom XP (for routine rewards)
    func addCustomXP(_ amount: Int, description: String = "Routine exercise") {
        let previousLevel = currentLevel

        currentXP += amount
        updateStreak()
        updateLevel()
        saveProgress()

        // Check for level up
        if currentLevel.id > previousLevel.id {
            newlyUnlockedLevel = currentLevel
            showLevelUpPopup = true
            HapticManager.success()
        } else {
            HapticManager.light()
        }

        print("✨ +\(amount) XP — \(description)")
        print("📊 Total XP: \(currentXP) — Niveau \(currentLevel.id): \(currentLevel.name)")
    }

    // MARK: - Level Management
    private func updateLevel() {
        currentLevel = Level.level(for: currentXP)
    }

    // MARK: - Streak Management
    private func updateStreak() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        if let lastActivity = lastActivityDate {
            let lastActivityDay = calendar.startOfDay(for: lastActivity)

            if calendar.dateComponents([.day], from: lastActivityDay, to: today).day == 1 {
                // Consecutive day
                streakDays += 1
                checkStreakBonuses()
            } else if calendar.dateComponents([.day], from: lastActivityDay, to: today).day ?? 0 > 1 {
                // Streak broken
                streakDays = 1
            }
            // Same day: no change
        } else {
            // First activity ever
            streakDays = 1
        }

        lastActivityDate = Date()
    }

    private func checkStreakBonuses() {
        if streakDays == 3 {
            addXP(.streak3Days)
        } else if streakDays == 7 {
            addXP(.streak7Days)
        }
    }

    // MARK: - Progress Info
    func progressInfo() -> (current: Int, required: Int, percentage: Double) {
        return Level.progressToNextLevel(currentXP: currentXP, currentLevel: currentLevel)
    }

    // MARK: - Reset (for debugging)
    func resetProgress() {
        currentXP = 0
        streakDays = 0
        lastActivityDate = nil
        updateLevel()
        saveProgress()
    }
}
