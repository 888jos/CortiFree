//
//  AchievementService.swift
//  CortiFree
//
//  Service for managing achievements and milestones
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine

@MainActor
class AchievementService: ObservableObject {
    static let shared = AchievementService()

    @Published var achievements: [Achievement] = Achievement.allAchievements
    @Published var milestones: [Milestone] = Milestone.allMilestones
    @Published var newlyUnlockedAchievement: Achievement?
    @Published var showAchievementPopup: Bool = false
    @Published var newlyCompletedMilestone: Milestone?
    @Published var showMilestonePopup: Bool = false

    private let db = Firestore.firestore()

    private init() {
        Task {
            await loadAchievements()
            await loadMilestones()
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

            achievements = userAchievements
            print("✅ Loaded \(achievements.filter(\.isUnlocked).count)/\(achievements.count) achievements")
        } catch {
            print("❌ Error loading achievements: \(error)")
        }
    }

    func loadMilestones() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        do {
            let snapshot = try await db.collection("users")
                .document(userId)
                .collection("milestones")
                .getDocuments()

            var userMilestones = Milestone.allMilestones

            for document in snapshot.documents {
                let data = document.data()
                if let milestone = Milestone.fromFirestore(data) {
                    if let index = userMilestones.firstIndex(where: { $0.id == milestone.id }) {
                        userMilestones[index] = milestone
                    }
                }
            }

            milestones = userMilestones
            print("✅ Loaded \(milestones.filter(\.isCompleted).count)/\(milestones.count) milestones")
        } catch {
            print("❌ Error loading milestones: \(error)")
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

    private func saveMilestone(_ milestone: Milestone) async {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        do {
            try await db.collection("users")
                .document(userId)
                .collection("milestones")
                .document(milestone.id)
                .setData(milestone.toFirestore, merge: true)
        } catch {
            print("❌ Error saving milestone: \(error)")
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

            case "week_warrior":
                achievement.progress = currentStreak

            case "two_week_champion":
                achievement.progress = currentStreak

            case "month_master":
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

    // MARK: - Check and Complete Milestones

    func checkMilestones(currentDay: Int) async -> Milestone? {
        for (index, var milestone) in milestones.enumerated() {
            guard !milestone.isCompleted else { continue }

            if currentDay >= milestone.day {
                milestone.completedAt = Date()
                milestones[index] = milestone
                await saveMilestone(milestone)

                // Unlock associated badge if exists
                if let badgeId = milestone.badgeId {
                    if let badgeIndex = achievements.firstIndex(where: { $0.id == badgeId }) {
                        achievements[badgeIndex].unlockedAt = Date()
                        achievements[badgeIndex].progress = achievements[badgeIndex].requirement
                        await saveAchievement(achievements[badgeIndex])
                    }
                }

                newlyCompletedMilestone = milestone
                showMilestonePopup = true
                HapticManager.success()

                print("🎉 Milestone completed: \(milestone.title)")
                return milestone
            }
        }

        return nil
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
