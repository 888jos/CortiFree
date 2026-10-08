//
//  HabitBadgeService.swift
//  CortiFree
//
//  Service centralisé pour la gestion des badges d'habitudes
//

import Foundation

@MainActor
class HabitBadgeService: ObservableObject {

    static let shared = HabitBadgeService()

    @Published var habitBadges: [HabitBadge] = []
    @Published var newlyUnlockedBadge: HabitBadge?
    @Published var showBadgePopup: Bool = false

    private var loadedUserID: String?

    private struct BadgeRow: Decodable {
        let habitId: String
        let level: HabitBadge.BadgeLevel
        let requirement: Int
        let progress: Int
        let unlockedAt: Double?
    }

    private init() {}

    // MARK: - Load Badges

    /// Charge tous les badges d'habitudes depuis Convex.
    func loadHabitBadges() async {
        let userId = Auth.auth().currentUser?.uid
        if loadedUserID != userId {
            habitBadges = []
            loadedUserID = userId
        }
        guard habitBadges.isEmpty else { return }

        do {
            let rows: [BadgeRow] = userId == nil ? [] : try await ConvexBackend.shared.call(
                .query, path: "achievements:listBadges"
            )
            let loadedBadges = rows.map { row in
                HabitBadge(
                    id: "\(row.habitId)_\(row.level.rawValue)",
                    habitId: row.habitId,
                    level: row.level,
                    requirement: row.requirement,
                    progress: row.progress,
                    unlockedAt: row.unlockedAt.map { Date(timeIntervalSince1970: $0 / 1000) }
                )
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
        guard Auth.auth().currentUser != nil else { return }

        var allBadges: [HabitBadge] = []

        for habitId in HabitBadge.allHabitIds {
            let badges = HabitBadge.badgesForHabit(habitId)
            allBadges.append(contentsOf: badges)
        }

        do {
            try await syncBadges(allBadges)
        } catch {
            print("❌ Failed to initialize badges: \(error.localizedDescription)")
        }

        habitBadges = allBadges
        print("✅ HabitBadgeService: Initialized \(allBadges.count) badges")
    }

    // MARK: - Check Badges

    /// Vérifie et débloque les badges pour une habitude donnée
    func checkHabitBadges(habitId: String, tasksCompleted: Int) async {
        print("🔍 HabitBadgeService: Checking badges for \(habitId) with \(tasksCompleted) tasks completed")

        // Load this account's real badge states first (no-op once loaded for the same uid):
        // starting from the default catalog re-celebrated badges already earned.
        await loadHabitBadges()
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

            if userId != nil {
                do {
                    try await syncBadges([badge])
                } catch {
                    print("⚠️ HabitBadgeService: Failed to sync badge - \(error.localizedDescription)")
                }
            }

            if let index = habitBadges.firstIndex(where: { $0.id == badge.id }) {
                habitBadges[index] = badge
            }

            if !wasUnlocked && badge.isUnlocked {
                newlyUnlockedBadge = badge
                CelebrationCenter.shared.enqueue(.badge(badge))
                print("🎉 HabitBadgeService: Badge unlocked - \(HabitBadge.habitDisplayName(habitId)) \(badge.level.displayName)")
            }
        }
    }

    private func syncBadges(_ badges: [HabitBadge]) async throws {
        let payload: [[String: Any]] = badges.map { badge in
            var value: [String: Any] = [
                "habitId": badge.habitId,
                "level": badge.level.rawValue,
                "requirement": badge.requirement,
                "progress": badge.progress,
            ]
            if let date = badge.unlockedAt {
                value["unlockedAt"] = date.timeIntervalSince1970 * 1000
            }
            return value
        }
        let _: JSONValue = try await ConvexBackend.shared.call(
            .mutation, path: "achievements:upsertBadges", args: ["badges": payload]
        )
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
