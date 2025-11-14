//
//  ProfileViewModel.swift
//  CortiFree
//
//  Created by Claude on 22/10/2025.
//

import Foundation

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var user: User?
    @Published var stats: UserStats?
    @Published var isLoading: Bool = true
    @Published var selectedPeriod: StatsPeriod = .week

    private let firebaseService = FirebaseService.shared

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
        isLoading = true

        do {
            user = try await firebaseService.fetchUser()
            stats = try await firebaseService.fetchStats()
            isLoading = false
        } catch {
            // Gestion silencieuse si pas de données (première utilisation)
            print("👤 Profile: Initializing with default values")
            isLoading = false
        }
    }

    func selectPeriod(_ period: StatsPeriod) {
        selectedPeriod = period
    }
}
