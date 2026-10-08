//
//  ProfileViewModel.swift
//  CortiFree
//
//  Created by Claude on 22/10/2025.
//

import Foundation
import UIKit

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var user: User?
    @Published var stats: UserStats?
    @Published var isLoading: Bool = true
    @Published var selectedPeriod: StatsPeriod = .week
    @Published var habitProgress: [String: (completed: Int, total: Int)] = [:] // Progress par habitude
    @Published var profilePhoto: UIImage? = ProfilePhotoStorage.load()

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
        // ProfileView.onAppear triggers refreshProfile(); AvatarProgressCard relies on this initial load.
        Task {
            await loadProfile()
        }
    }

    /// Local photo first; on a fresh install / new device, restore it from Convex storage.
    func loadProfilePhoto() async {
        if let local = ProfilePhotoStorage.load() {
            profilePhoto = local
            return
        }
        profilePhoto = nil
        guard let remoteURL = Auth.auth().currentUser?.photoURL,
              let (data, _) = try? await URLSession.shared.data(from: remoteURL),
              let image = UIImage(data: data) else { return }
        ProfilePhotoStorage.save(data)
        profilePhoto = image
    }

    func loadProfile() async {
        if let last = lastLoadedAt, Date().timeIntervalSince(last) < cacheInterval {
            return
        }
        isLoading = true

        // Try to fetch user, but don't fail if it doesn't exist
        user = try? await firebaseService.fetchUser()
        stats = try? await firebaseService.fetchStats()

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

    func selectPeriod(_ period: StatsPeriod) {
        selectedPeriod = period
    }

    /// Refresh profile data (called when returning to profile view)
    func refreshProfile() async {
        lastLoadedAt = nil
        await loadProfile()
    }
}
