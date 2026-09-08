//
//  HabitBadgeService.swift
//  CortiFree
//
//  Service centralisé pour la gestion des badges d'habitudes
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
class HabitBadgeService: ObservableObject {

    static let shared = HabitBadgeService()

    @Published var habitBadges: [HabitBadge] = []
    @Published var newlyUnlockedBadge: HabitBadge?
    @Published var showBadgePopup: Bool = false

    private let db = Firestore.firestore()
    private var loadedUserID: String?

    private init() {}

    // MARK: - Load Badges

    /// Charge tous les badges d'habitudes depuis Firebase
    func loadHabitBadges() async {
        let userId = Auth.auth().currentUser?.uid
        if loadedUserID != userId {
            habitBadges = []
            loadedUserID = userId
        }
        guard habitBadges.isEmpty else { return }

        do {
            let snapshot: QuerySnapshot?
            if let userId {
                snapshot = try await db.collection("users").document(userId)
                    .collection("habit_badges")
                    .getDocuments()
            } else {
                snapshot = nil
            }

            var loadedBadges: [HabitBadge] = []

            for document in snapshot?.documents ?? [] {
                if let badge = try? document.data(as: HabitBadge.self) {
                    loadedBadges.append(badge)
                }
            }

            if loadedBadges.isEmpty {
                habitBadges = HabitBadge.allHabitIds.flatMap(HabitBadge.badgesForHabit)
                if userId != nil {
                    await initializeAllBadges()
                }
            } else {
                habitBadges = loadedBadges
                print("✅ HabitBadgeService: Loaded \(loadedBadges.count) badges")
            }

            applyLocalProgress(userID: userId)

        } catch {
            print("❌ HabitBadgeService: Failed to load badges - \(error.localizedDescription)")
            habitBadges = HabitBadge.allHabitIds.flatMap(HabitBadge.badgesForHabit)
            applyLocalProgress(userID: userId)
        }
    }

    // MARK: - Initialize Badges

    /// Initialise tous les badges (32 badges = 8 habitudes × 4 niveaux)
    private func initializeAllBadges() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        var allBadges: [HabitBadge] = []

        for habitId in HabitBadge.allHabitIds {
            let badges = HabitBadge.badgesForHabit(habitId)
            allBadges.append(contentsOf: badges)
        }

        // Sauvegarder dans Firebase
        for badge in allBadges {
            do {
                try db.collection("users").document(userId)
                    .collection("habit_badges")
                    .document(badge.id ?? "\(badge.habitId)_\(badge.level.rawValue)")
                    .setData(from: badge)
            } catch {
                print("❌ Failed to save badge \(badge.id ?? "unknown")")
            }
        }

        habitBadges = allBadges
        print("✅ HabitBadgeService: Initialized \(allBadges.count) badges")
    }

    // MARK: - Check Badges

    /// Vérifie et débloque les badges pour une habitude donnée
    func checkHabitBadges(habitId: String, tasksCompleted: Int) async {
        print("🔍 HabitBadgeService: Checking badges for \(habitId) with \(tasksCompleted) tasks completed")

        if habitBadges.isEmpty {
            habitBadges = HabitBadge.allHabitIds.flatMap(HabitBadge.badgesForHabit)
        }
        let userId = Auth.auth().currentUser?.uid

        // Récupérer tous les badges pour cette habitude
        let habitBadgesForCheck = habitBadges.filter { $0.habitId == habitId }

        for var badge in habitBadgesForCheck {
            // Mettre à jour la progression
            badge.progress = tasksCompleted
            let wasUnlocked = badge.isUnlocked

            // Vérifier si le badge doit être débloqué
            if !wasUnlocked && tasksCompleted >= badge.requirement {
                badge.unlockedAt = Date()
            }

            if let userId {
                do {
                    try db.collection("users").document(userId)
                        .collection("habit_badges")
                        .document(badge.id ?? "\(badge.habitId)_\(badge.level.rawValue)")
                        .setData(from: badge)

                } catch {
                    print("⚠️ HabitBadgeService: Failed to sync badge - \(error.localizedDescription)")
                }
            }

            if let index = habitBadges.firstIndex(where: { $0.id == badge.id }) {
                habitBadges[index] = badge
            }

            if !wasUnlocked && badge.isUnlocked {
                newlyUnlockedBadge = badge
                showBadgePopup = true
                print("🎉 HabitBadgeService: Badge unlocked - \(HabitBadge.habitDisplayName(habitId)) \(badge.level.displayName)")
            }
        }
    }

    private func applyLocalProgress(userID: String?) {
        guard let userID else { return }
        var counts: [String: Int] = [:]
        for completion in LocalProgressStore.load(for: userID) {
            counts[completion.habitID, default: 0] += 1
        }

        for index in habitBadges.indices {
            let count = counts[habitBadges[index].habitId, default: 0]
            habitBadges[index].progress = max(habitBadges[index].progress, count)
            if habitBadges[index].unlockedAt == nil,
               habitBadges[index].progress >= habitBadges[index].requirement {
                habitBadges[index].unlockedAt = Date()
            }
        }
    }

    // MARK: - Helpers

    /// Retourne tous les badges pour une habitude
    func badges(for habitId: String) -> [HabitBadge] {
        let storedBadges = habitBadges
            .filter { $0.habitId == habitId }
            .sorted { $0.level.percentage < $1.level.percentage }

        // Keep the gallery meaningful while the remote badge document is loading.
        return storedBadges.isEmpty ? HabitBadge.badgesForHabit(habitId) : storedBadges
    }

    /// Retourne le nombre total de badges débloqués
    var unlockedBadgesCount: Int {
        return habitBadges.filter { $0.isUnlocked }.count
    }

    /// Retourne le nombre total de badges
    var totalBadgesCount: Int {
        return 32 // 8 habitudes × 4 niveaux
    }

    /// Retourne le pourcentage de badges débloqués
    var completionPercentage: Double {
        guard totalBadgesCount > 0 else { return 0 }
        return Double(unlockedBadgesCount) / Double(totalBadgesCount)
    }

    #if DEBUG
    /// Debug-only gallery control. It stays in memory and is never synced remotely.
    func setAllUnlockedForDebug(_ unlocked: Bool) {
        habitBadges = habitBadges.map { badge in
            var updated = badge
            updated.progress = unlocked ? badge.requirement : 0
            updated.unlockedAt = unlocked ? (badge.unlockedAt ?? Date()) : nil
            return updated
        }
    }
    #endif
}
