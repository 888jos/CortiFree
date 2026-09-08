//
//  ProfileViewModel.swift
//  CortiFree
//
//  Created by Claude on 22/10/2025.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var user: User?
    @Published var stats: UserStats?
    @Published var isLoading: Bool = true
    @Published var selectedPeriod: StatsPeriod = .week
    @Published var domainScores: [Double] = [0.0, 0.0, 0.0, 0.0, 0.0] // Sérénité, Sommeil, Énergie, Focus, Équilibre
    @Published var potentialScores: [Double] = [0.0, 0.0, 0.0, 0.0, 0.0]
    @Published var onboardingGlobalScore: Int = 0 // Score global calculé pendant l'onboarding
    @Published var onboardingDomainScores: [Double] = [0.0, 0.0, 0.0, 0.0, 0.0] // Scores onboarding par domaine
    @Published var habitProgress: [String: (completed: Int, total: Int)] = [:] // Progress par habitude

    private let firebaseService = FirebaseService.shared
    private var lastLoadedAt: Date? = nil
    private let cacheInterval: TimeInterval = 60 // 60 seconds

    enum StatsPeriod: String, CaseIterable {
        case week = "7j"
        case month = "30j"
        case threeMonths = "90j"

        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            case .threeMonths: return 90
            }
        }
    }

    var chartData: [(date: Date, rate: Double)] {
        guard let stats = stats else { return [] }
        return stats.historyFor(days: selectedPeriod.days)
    }

    var completionRate: Double {
        guard !chartData.isEmpty else { return 0 }
        let total = chartData.reduce(0) { $0 + $1.rate }
        return total / Double(chartData.count)
    }

    init() {
        Task {
            await loadProfile()
        }
    }

    func loadProfile() async {
        if let last = lastLoadedAt, Date().timeIntervalSince(last) < cacheInterval {
            return
        }
        isLoading = true

        if let baseline = LocalScoreStore.baseline() {
            onboardingGlobalScore = Int(baseline.global.rounded())
            onboardingDomainScores = [baseline.serenity, baseline.sleep, baseline.energy, baseline.focus, baseline.balance]
        }
        if let potential = LocalScoreStore.potential() {
            potentialScores = [potential.serenity, potential.sleep, potential.energy, potential.focus, potential.balance]
        }

        // Try to fetch user, but don't fail if it doesn't exist
        user = try? await firebaseService.fetchUser()
        stats = try? await firebaseService.fetchStats()

        do {
            // Load domain scores using ImpactScoringService
            let currentScores = try await ImpactScoringService.shared.fetchCurrentScores()

            domainScores = [
                currentScores.serenity,
                currentScores.sleep,
                currentScores.energy,
                currentScores.focus,
                currentScores.balance
            ]

            #if DEBUG
            print("📊 Profile scores loaded: Sérénité=\(currentScores.serenity), Sommeil=\(currentScores.sleep), Énergie=\(currentScores.energy), Focus=\(currentScores.focus), Équilibre=\(currentScores.balance)")
            #endif
        } catch {
            #if DEBUG
            print("⚠️ Failed to load domain scores: \(error)")
            #endif
        }

        do {
            // Load potential scores from Firebase
            if let userId = Auth.auth().currentUser?.uid {
                let userDoc = try await Firestore.firestore()
                    .collection("users")
                    .document(userId)
                    .getDocument()

                if let data = userDoc.data() {
                    // Firestore may decode numeric fields as Int, Int64, Double, or NSNumber.
                    if let scores = data["potentialScores"] as? [String: Any] {
                        let parsed = UserDomainScores.from(scores)
                        potentialScores = [parsed.serenity, parsed.sleep, parsed.energy, parsed.focus, parsed.balance]
                    }

                    // Load onboarding global score
                    if let onboardingScore = Self.numericValue(data["onboardingScore"]) {
                        onboardingGlobalScore = Int(onboardingScore.rounded())
                        #if DEBUG
                        print("📊 Onboarding score loaded: \(onboardingGlobalScore)")
                        #endif
                    }

                    // Load onboarding domain scores
                    if let domainScoresData = data["domainScores"] as? [String: Any] {
                        let parsed = UserDomainScores.from(domainScoresData)
                        onboardingDomainScores = [
                            parsed.serenity,
                            parsed.sleep,
                            parsed.energy,
                            parsed.focus,
                            parsed.balance
                        ]
                        #if DEBUG
                        print("📊 Onboarding domain scores loaded")
                        #endif
                    }
                }
            }
        } catch {
            #if DEBUG
            print("⚠️ Failed to load potential scores: \(error)")
            #endif
        }

        do {
            // Load habit progress statistics
            let progress = try await TaskStatusService.shared.calculateHabitProgress()
            habitProgress = progress

            #if DEBUG
            print("📊 Habit progress loaded: Méditation=\(progress["meditation"]?.completed ?? 0)/\(progress["meditation"]?.total ?? 0), Respiration=\(progress["breathing"]?.completed ?? 0)/\(progress["breathing"]?.total ?? 0)")
            #endif
        } catch {
            #if DEBUG
            print("❌ Failed to load habit progress: \(error)")
            #endif
        }

        isLoading = false
        lastLoadedAt = Date()
    }

    private static func numericValue(_ value: Any?) -> Double? {
        if let value = value as? Double { return value }
        if let value = value as? Int { return Double(value) }
        if let value = value as? Int64 { return Double(value) }
        if let value = value as? Float { return Double(value) }
        if let value = value as? NSNumber { return value.doubleValue }
        return nil
    }

    func selectPeriod(_ period: StatsPeriod) {
        selectedPeriod = period
    }

    /// Refresh profile data (called when returning to profile view)
    func refreshProfile() async {
        lastLoadedAt = nil
        await loadProfile()
    }
}
