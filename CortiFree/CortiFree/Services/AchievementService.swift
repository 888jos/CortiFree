//
//  AchievementService.swift
//  CortiFree
//
//  Service for managing achievements
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine

@MainActor
class AchievementService: ObservableObject {
    static let shared = AchievementService()

    @Published var achievements: [Achievement] = Achievement.allAchievements
    @Published var newlyUnlockedAchievement: Achievement?
    @Published var showAchievementPopup: Bool = false

    private let db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()

    private init() {
        Task {
            await loadAchievements()
        }

        // Listen for streak updates to refresh achievement progress
        NotificationCenter.default.publisher(for: NSNotification.Name("StreakUpdated"))
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.updateStreakAchievementsProgress()
                }
            }
            .store(in: &cancellables)
    }

    // Update streak achievements progress when streak changes
    private func updateStreakAchievementsProgress() {
        let currentStreak = UserDefaults.standard.integer(forKey: "streakDays")
        let streakAchievementIds = ["streak_3", "streak_7", "streak_14", "streak_21", "streak_30", "streak_40", "streak_50", "streak_60", "streak_66"]

        for (index, achievement) in achievements.enumerated() {
            if streakAchievementIds.contains(achievement.id) && !achievement.isUnlocked {
                achievements[index].progress = currentStreak
            }
        }
    }

    // MARK: - Load from Firebase

    func loadAchievements() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        do {
            let snapshot = try await db.collection("users")
                .document(userId)
                .collection("achievements")
                .getDocuments()

            var userAchievements = Achievement.allAchievements

            for document in snapshot.documents {
                let data = document.data()
                if let achievement = Achievement.fromFirestore(data, id: document.documentID) {
                    if let index = userAchievements.firstIndex(where: { $0.id == achievement.id }) {
                        userAchievements[index] = achievement
                    }
                }
            }

            // Update streak achievements with current streak from UserDefaults
            let currentStreak = UserDefaults.standard.integer(forKey: "streakDays")
            let streakAchievementIds = ["streak_3", "streak_7", "streak_14", "streak_21", "streak_30", "streak_40", "streak_50", "streak_60", "streak_66"]

            for (index, achievement) in userAchievements.enumerated() {
                if streakAchievementIds.contains(achievement.id) && !achievement.isUnlocked {
                    userAchievements[index].progress = currentStreak
                }
            }

            achievements = userAchievements
            print("✅ Loaded \(achievements.filter(\.isUnlocked).count)/\(achievements.count) achievements (streak: \(currentStreak))")
        } catch {
            print("❌ Error loading achievements: \(error)")
        }
    }

    // MARK: - Save to Firebase

    private func saveAchievement(_ achievement: Achievement) async {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        do {
            try await db.collection("users")
                .document(userId)
                .collection("achievements")
                .document(achievement.id)
                .setData(achievement.toFirestore, merge: true)
        } catch {
            print("❌ Error saving achievement: \(error)")
        }
    }

    // MARK: - Check and Unlock Achievements

    func checkAchievements(taskCompleted: String? = nil, currentDay: Int = 0, currentStreak: Int = 0, tasksCompletedToday: Int = 0) async {
        var unlocked: [Achievement] = []

        // Check each achievement
        for (index, var achievement) in achievements.enumerated() {
            guard !achievement.isUnlocked else { continue }

            switch achievement.id {
            case "first_task":
                achievement.progress = taskCompleted != nil ? 1 : 0

            // All streak achievements use globalStreak from TasksV2View
            case "streak_3", "streak_7", "streak_14", "streak_21", "streak_30", "streak_40", "streak_50", "streak_60", "streak_66",
                 "week_warrior", "two_week_champion", "month_master":
                achievement.progress = currentStreak

            case "triple_crown":
                if tasksCompletedToday >= 3 {
                    achievement.progress += 1
                }

            case "halfway_hero":
                achievement.progress = currentDay

            case "graduate":
                achievement.progress = currentDay

            default:
                break
            }

            // Check if unlocked
            if achievement.progress >= achievement.requirement {
                achievement.unlockedAt = Date()
                unlocked.append(achievement)
                print("🏆 Achievement unlocked: \(achievement.title)")
            }

            achievements[index] = achievement
            await saveAchievement(achievement)
        }

        // Show popup for first unlocked achievement
        if let first = unlocked.first {
            newlyUnlockedAchievement = first
            showAchievementPopup = true
            HapticManager.success()
        }
    }

    // MARK: - Special Achievements

    func unlockComebackAchievement() async {
        if let index = achievements.firstIndex(where: { $0.id == "comeback_kid" && !$0.isUnlocked }) {
            achievements[index].progress = 1
            achievements[index].unlockedAt = Date()
            await saveAchievement(achievements[index])

            newlyUnlockedAchievement = achievements[index]
            showAchievementPopup = true
            HapticManager.success()
        }
    }

    func checkPerfectWeek(daysCompleted: [Bool]) async {
        // Check if last 7 days are all completed
        let lastSevenDays = daysCompleted.suffix(7)
        if lastSevenDays.count == 7 && lastSevenDays.allSatisfy({ $0 }) {
            if let index = achievements.firstIndex(where: { $0.id == "perfectionist" && !$0.isUnlocked }) {
                achievements[index].progress = 1
                achievements[index].unlockedAt = Date()
                await saveAchievement(achievements[index])

                newlyUnlockedAchievement = achievements[index]
                showAchievementPopup = true
                HapticManager.success()
            }
        }
    }

    // MARK: - Stats

    var unlockedCount: Int {
        achievements.filter(\.isUnlocked).count
    }

    var totalCount: Int {
        achievements.count
    }

    var completionPercentage: Double {
        guard totalCount > 0 else { return 0 }
        return Double(unlockedCount) / Double(totalCount)
    }
}
