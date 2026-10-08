//
//  AchievementService.swift
//  CortiFree
//
//  Service for managing achievements
//

import Foundation
import Combine

@MainActor
class AchievementService: ObservableObject {
    static let shared = AchievementService()

    @Published var achievements: [Achievement] = Achievement.allAchievements
    @Published var newlyUnlockedAchievement: Achievement?
    @Published var showAchievementPopup: Bool = false

    private var cancellables = Set<AnyCancellable>()

    private struct AchievementRow: Decodable {
        let achievementId: String
        let progress: Int
        let unlockedAt: Double?
    }

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

    // MARK: - Convex persistence

    func loadAchievements() async {
        guard Auth.auth().currentUser != nil else { return }

        do {
            let rows: [AchievementRow] = try await ConvexBackend.shared.call(
                .query, path: "achievements:list"
            )

            var userAchievements = Achievement.allAchievements

            for row in rows {
                if let index = userAchievements.firstIndex(where: { $0.id == row.achievementId }) {
                    userAchievements[index].progress = row.progress
                    userAchievements[index].unlockedAt = row.unlockedAt.map {
                        Date(timeIntervalSince1970: $0 / 1000)
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
            #if DEBUG
            print("✅ Loaded \(achievements.filter(\.isUnlocked).count)/\(achievements.count) achievements (streak: \(currentStreak))")
            #endif
        } catch {
            #if DEBUG
            print("❌ Error loading achievements: \(error)")
            #endif
        }
    }

    private func saveAchievement(_ achievement: Achievement) async {
        guard Auth.auth().currentUser != nil else { return }

        do {
            var item: [String: Any] = [
                "achievementId": achievement.id,
                "progress": achievement.progress,
            ]
            if let date = achievement.unlockedAt {
                item["unlockedAt"] = date.timeIntervalSince1970 * 1000
            }
            let _: JSONValue = try await ConvexBackend.shared.call(
                .mutation, path: "achievements:upsertMany", args: ["items": [item]]
            )
        } catch {
            #if DEBUG
            print("❌ Error saving achievement: \(error)")
            #endif
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
                #if DEBUG
                print("🏆 Achievement unlocked: \(achievement.title)")
                #endif
            }

            achievements[index] = achievement
            await saveAchievement(achievement)
        }

        // Every unlock is celebrated, one after the other (CelebrationCenter queue).
        for achievement in unlocked {
            CelebrationCenter.shared.enqueue(.achievement(achievement))
        }
        if let first = unlocked.first {
            newlyUnlockedAchievement = first

            // Request rating on achievement unlock
            AppRatingService.shared.trackAchievementUnlock()
        }
    }

    // MARK: - Special Achievements

    func unlockComebackAchievement() async {
        if let index = achievements.firstIndex(where: { $0.id == "comeback_kid" && !$0.isUnlocked }) {
            achievements[index].progress = 1
            achievements[index].unlockedAt = Date()
            await saveAchievement(achievements[index])

            newlyUnlockedAchievement = achievements[index]
            CelebrationCenter.shared.enqueue(.achievement(achievements[index]))

            // Request rating on achievement unlock
            AppRatingService.shared.trackAchievementUnlock()
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
                CelebrationCenter.shared.enqueue(.achievement(achievements[index]))

                // Request rating on achievement unlock
                AppRatingService.shared.trackAchievementUnlock()
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

    #if DEBUG
    /// Debug-only gallery control. It stays in memory and never changes real data.
    func setAllUnlockedForDebug(_ unlocked: Bool) {
        achievements = achievements.map { achievement in
            var updated = achievement
            updated.progress = unlocked ? achievement.requirement : 0
            updated.unlockedAt = unlocked ? (achievement.unlockedAt ?? Date()) : nil
            return updated
        }
    }
    #endif
}
