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

    private init() {}

    // MARK: - Load Badges

    /// Charge tous les badges d'habitudes depuis Firebase
    func loadHabitBadges() async {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("❌ HabitBadgeService: No user logged in")
            return
        }

        do {
            let snapshot = try await db.collection("users").document(userId)
                .collection("habit_badges")
                .getDocuments()

            var loadedBadges: [HabitBadge] = []

            for document in snapshot.documents {
                if let badge = try? document.data(as: HabitBadge.self) {
                    loadedBadges.append(badge)
                }
            }

            // Si aucun badge n'existe, initialiser tous les badges
            if loadedBadges.isEmpty {
                await initializeAllBadges()
            } else {
                habitBadges = loadedBadges
                print("✅ HabitBadgeService: Loaded \(loadedBadges.count) badges")
            }

        } catch {
            print("❌ HabitBadgeService: Failed to load badges - \(error.localizedDescription)")
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
        guard let userId = Auth.auth().currentUser?.uid else { return }

        print("🔍 HabitBadgeService: Checking badges for \(habitId) with \(tasksCompleted) tasks completed")

        // Récupérer tous les badges pour cette habitude
        let habitBadgesForCheck = habitBadges.filter { $0.habitId == habitId }

        for var badge in habitBadgesForCheck {
            // Mettre à jour la progression
            badge.progress = tasksCompleted

            // Vérifier si le badge doit être débloqué
            if !badge.isUnlocked && tasksCompleted >= badge.requirement {
                // Débloquer le badge
                badge.unlockedAt = Date()

                // Sauvegarder dans Firebase
                do {
                    try db.collection("users").document(userId)
                        .collection("habit_badges")
                        .document(badge.id ?? "\(badge.habitId)_\(badge.level.rawValue)")
                        .setData(from: badge)

                    // Mettre à jour localement
                    if let index = habitBadges.firstIndex(where: { $0.id == badge.id }) {
                        habitBadges[index] = badge
                    }

                    // Déclencher la célébration
                    newlyUnlockedBadge = badge
                    showBadgePopup = true

                    print("🎉 HabitBadgeService: Badge unlocked - \(HabitBadge.habitDisplayName(habitId)) \(badge.level.displayName)")

                } catch {
                    print("❌ HabitBadgeService: Failed to unlock badge - \(error.localizedDescription)")
                }

            } else if !badge.isUnlocked {
                // Juste mettre à jour la progression
                do {
                    try db.collection("users").document(userId)
                        .collection("habit_badges")
                        .document(badge.id ?? "\(badge.habitId)_\(badge.level.rawValue)")
                        .setData(from: badge)

                    // Mettre à jour localement
                    if let index = habitBadges.firstIndex(where: { $0.id == badge.id }) {
                        habitBadges[index] = badge
                    }

                } catch {
                    print("❌ HabitBadgeService: Failed to update badge progress")
                }
            }
        }
    }

    // MARK: - Helpers

    /// Retourne tous les badges pour une habitude
    func badges(for habitId: String) -> [HabitBadge] {
        return habitBadges
            .filter { $0.habitId == habitId }
            .sorted { $0.level.percentage < $1.level.percentage }
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
}
