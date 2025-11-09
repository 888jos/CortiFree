//
//  HomeViewModel.swift
//  CortiFree
//
//  Created by Claude on 22/10/2025.
//

import Foundation
import Combine
import UIKit
import FirebaseFirestore

@MainActor
class HomeViewModel: ObservableObject {
    @Published var user: User?
    @Published var tasksCompletedToday: Int = 0
    @Published var weekProgress: [Bool] = Array(repeating: false, count: 7)
    @Published var isLoading: Bool = true
    @Published var showAntiStressView: Bool = false

    private let firebaseService = FirebaseService.shared
    private var cancellables = Set<AnyCancellable>()

    init() {
        setupListeners()
        Task {
            await loadData()
        }
    }

    func loadData() async {
        isLoading = true

        do {
            // Load user data
            user = try await firebaseService.fetchUser()

            // Load tasks to calculate today's progress
            let tasks = try await firebaseService.fetchTasks()
            tasksCompletedToday = tasks.filter { $0.completed && isToday($0.completedAt) }.count

            // Calculate week progress
            await calculateWeekProgress(tasks: tasks)

            isLoading = false
        } catch {
            // Gestion silencieuse si pas de données (première utilisation)
            print("📊 Home: Initializing with default values")
            isLoading = false
        }
    }

    private func setupListeners() {
        // Listen for level up notifications
        NotificationCenter.default.publisher(for: .userLeveledUp)
            .sink { [weak self] notification in
                if let level = notification.object as? Int {
                    self?.handleLevelUp(level: level)
                }
            }
            .store(in: &cancellables)
    }

    private func handleLevelUp(level: Int) {
        triggerHaptic(.heavy)
        // TODO: Show confetti animation
        print("🎉 Level Up! Now at level \(level)")
    }

    private func calculateWeekProgress(tasks: [TaskItem]) async {
        let calendar = Calendar.current
        let today = Date()

        weekProgress = (0..<7).map { dayOffset in
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else {
                return false
            }

            let tasksForDay = tasks.filter { task in
                guard let completedAt = task.completedAt else { return false }
                return calendar.isDate(completedAt.dateValue(), inSameDayAs: date)
            }

            return !tasksForDay.isEmpty
        }.reversed()
    }

    private func isToday(_ timestamp: Timestamp?) -> Bool {
        guard let timestamp = timestamp else { return false }
        return Calendar.current.isDateInToday(timestamp.dateValue())
    }

    func triggerAntiStress() {
        triggerHaptic(.heavy)
        showAntiStressView = true
    }

    func toggleDayCompletion(at index: Int) {
        guard index >= 0 && index < weekProgress.count else { return }
        weekProgress[index].toggle()
        triggerHaptic(.light)
    }

    private func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
}
