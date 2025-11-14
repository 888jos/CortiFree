//
//  TasksViewModel.swift
//  CortiFree
//
//  Created by Claude on 22/10/2025.
//

import Foundation
import SwiftUI

@MainActor
class TasksViewModel: ObservableObject {
    @Published var tasks: [TaskItem] = []
    @Published var isLoading: Bool = true
    @Published var showConfetti: Bool = false
    @Published var expandedSections: Set<TaskCategory> = Set(TaskCategory.allCases)
    @Published var showTaskDetail: Bool = false
    @Published var selectedTask: TaskItem? = nil

    private let firebaseService = FirebaseService.shared

    var morningTasks: [TaskItem] {
        tasks.filter { task in
            guard let timeString = task.recommendedTime else {
                return task.category == .morning
            }
            let hour = hourFromTimeString(timeString)
            return hour >= 5 && hour < 12
        }.sorted { task1, task2 in
            guard let time1 = task1.recommendedTime,
                  let time2 = task2.recommendedTime else {
                return false
            }
            return time1 < time2
        }
    }

    var dayTasks: [TaskItem] {
        tasks.filter { task in
            guard let timeString = task.recommendedTime else {
                return task.category == .day
            }
            let hour = hourFromTimeString(timeString)
            return hour >= 12 && hour < 19
        }.sorted { task1, task2 in
            guard let time1 = task1.recommendedTime,
                  let time2 = task2.recommendedTime else {
                return false
            }
            return time1 < time2
        }
    }

    var nightTasks: [TaskItem] {
        tasks.filter { task in
            guard let timeString = task.recommendedTime else {
                return task.category == .night
            }
            let hour = hourFromTimeString(timeString)
            return hour >= 19 || hour < 5
        }.sorted { task1, task2 in
            guard let time1 = task1.recommendedTime,
                  let time2 = task2.recommendedTime else {
                return false
            }
            return time1 < time2
        }
    }

    // Helper function to extract hour from time string (e.g., "07:00" -> 7)
    private func hourFromTimeString(_ timeString: String) -> Int {
        let components = timeString.split(separator: ":")
        if let hourString = components.first,
           let hour = Int(hourString) {
            return hour
        }
        return 0
    }

    var customTasks: [TaskItem] {
        tasks.filter { $0.isCustomTask }
    }

    var defaultTasks: [TaskItem] {
        tasks.filter { !$0.isCustomTask }
    }

    var completionPercentage: Double {
        guard !tasks.isEmpty else { return 0 }
        let completedCount = tasks.filter { $0.completed }.count
        return Double(completedCount) / Double(tasks.count)
    }

    var completedCount: Int {
        tasks.filter { $0.completed }.count
    }

    var totalCount: Int {
        tasks.count
    }

    init() {
        Task {
            await loadTasks()
        }
    }

    func loadTasks() async {
        isLoading = true

        do {
            tasks = try await firebaseService.fetchTasks()

            // Check if we need to migrate/update default tasks
            await migrateDefaultTasksIfNeeded()

            // If no default (non-custom) tasks exist, create them
            let hasDefaultTasks = tasks.contains { !$0.isCustomTask }
            if !hasDefaultTasks {
                await createDefaultTasks()
            } else {
                // Reset completed status for daily tasks at start of new day
                await resetDailyTasksIfNeeded()
            }

            isLoading = false
        } catch {
            print("Error loading tasks: \(error.localizedDescription)")
            isLoading = false
        }
    }

    // Migrate existing default tasks to add missing properties (sfSymbol, recommendedTime, etc.)
    private func migrateDefaultTasksIfNeeded() async {
        let defaultTasksInDB = tasks.filter { !$0.isCustomTask }

        // Check if any default task is missing required properties
        let needsMigration = defaultTasksInDB.contains { task in
            task.sfSymbol == nil || task.recommendedTime == nil
        }

        if needsMigration {
            print("🔄 Migrating default tasks with missing properties...")

            // Delete all old default tasks
            for task in defaultTasksInDB {
                if let taskId = task.id {
                    try? await firebaseService.deleteTask(taskId)
                }
            }

            // Recreate with proper data
            await createDefaultTasks()
        }
    }

    private func createDefaultTasks() async {
        // Create default tasks templates with proper Firebase structure
        // Categories are assigned based on time ranges:
        // Morning: 5h00-11h59, Day: 12h00-18h59, Night: 19h00-4h59
        let defaultTasks: [TaskItem] = [
            TaskItem(
                title: "Respiration 4-7-8",
                category: .morning,
                taskFrequency: .daily,
                customCategory: .breathing,
                durationInMinutes: 5,
                isCustomTask: false,
                sfSymbol: "wind",
                recommendedTime: "07:00",
                taskDescription: "La technique de respiration 4-7-8 active le système nerveux parasympathique, réduisant instantanément les niveaux de cortisol. En inspirant 4 secondes, retenant 7 secondes et expirant 8 secondes, vous signalez à votre corps qu'il est en sécurité. Cette pratique matinale programme votre journée en mode calme plutôt qu'en mode stress."
            ),
            TaskItem(
                title: "Méditer 5 minutes",
                category: .morning,
                taskFrequency: .daily,
                customCategory: .mental,
                durationInMinutes: 5,
                isCustomTask: false,
                sfSymbol: "figure.mind.and.body",
                recommendedTime: "08:00",
                taskDescription: "La méditation matinale réduit le cortisol jusqu'à 20% selon des études scientifiques. Elle renforce votre capacité à gérer le stress tout au long de la journée en créant un espace mental de recul. Même 5 minutes suffisent pour recalibrer votre système nerveux et améliorer votre régulation émotionnelle face aux défis quotidiens."
            ),
            TaskItem(
                title: "Boire un verre d'eau",
                category: .day,
                taskFrequency: .daily,
                customCategory: .nutrition,
                durationInMinutes: 2,
                isCustomTask: false,
                sfSymbol: "drop.fill",
                recommendedTime: "12:00",
                taskDescription: "La déshydratation, même légère, augmente la production de cortisol et amplifie la perception du stress. Votre cerveau est composé de 75% d'eau - le maintenir hydraté optimise vos fonctions cognitives et votre capacité à gérer l'anxiété. Un simple verre d'eau peut réduire les symptômes de stress en quelques minutes."
            ),
            TaskItem(
                title: "S'étirer doucement",
                category: .day,
                taskFrequency: .daily,
                customCategory: .movement,
                durationInMinutes: 10,
                isCustomTask: false,
                sfSymbol: "figure.flexibility",
                recommendedTime: "15:00",
                taskDescription: "Les étirements doux libèrent les tensions musculaires accumulées par le stress et favorisent la circulation sanguine. Cette pratique envoie des signaux de détente au cerveau, réduisant la production de cortisol. En milieu d'après-midi, elle prévient l'accumulation de stress et maintient votre corps dans un état de relaxation active."
            ),
            TaskItem(
                title: "Éteindre les écrans",
                category: .night,
                taskFrequency: .daily,
                customCategory: .sleep,
                durationInMinutes: 5,
                isCustomTask: false,
                sfSymbol: "moonphase.waning.crescent",
                recommendedTime: "21:00",
                taskDescription: "La lumière bleue des écrans inhibe la mélatonine et stimule la production de cortisol, perturbant votre rythme circadien. Éteindre les écrans 1h avant le coucher permet à votre cerveau de se préparer naturellement au sommeil. Un sommeil de qualité est votre meilleure défense contre le stress chronique et l'anxiété."
            )
        ]

        for task in defaultTasks {
            try? await firebaseService.saveTask(task)
        }

        // Reload tasks from Firebase (without calling loadTasks() to avoid recursion)
        if let updatedTasks = try? await firebaseService.fetchTasks() {
            tasks = updatedTasks
        }
    }

    private func resetDailyTasksIfNeeded() async {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Check if we need to reset daily tasks
        for task in tasks where task.taskFrequency == .daily && task.completed {
            // If task was completed on a previous day, reset it
            if let completedAt = task.completedAt?.dateValue(),
               !calendar.isDate(completedAt, inSameDayAs: today) {
                try? await firebaseService.uncompleteTask(task.id ?? "")
            }
        }

        // Reload to get updated state
        if let updatedTasks = try? await firebaseService.fetchTasks() {
            tasks = updatedTasks
        }
    }

    func toggleTask(_ task: TaskItem) async {
        triggerHaptic(.light)

        do {
            if task.completed {
                try await firebaseService.uncompleteTask(task.id ?? "")
            } else {
                try await firebaseService.completeTask(task.id ?? "")
            }

            // Update local state
            if let index = tasks.firstIndex(where: { $0.id == task.id }) {
                let wasCompleted = tasks[index].completed
                tasks[index].completed.toggle()

                // Award XP when completing a task (not when uncompleting)
                if !wasCompleted && tasks[index].completed {
                    ProgressionManager.shared.addXP(.dailyMissionComplete)
                }

                // Check if all tasks completed
                if completionPercentage == 1.0 {
                    showConfetti = true
                    triggerHaptic(.heavy)

                    // Hide confetti after 3 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        self.showConfetti = false
                    }
                }
            }

            // Update daily progress in stats
            try await firebaseService.updateDailyProgress(completionRate: completionPercentage)

        } catch {
            print("Error toggling task: \(error.localizedDescription)")
        }
    }

    func deleteTask(_ task: TaskItem) async {
        triggerHaptic(.medium)

        do {
            try await firebaseService.deleteTask(task.id ?? "")

            // Update local state
            withAnimation {
                tasks.removeAll { $0.id == task.id }
            }
        } catch {
            print("Error deleting task: \(error.localizedDescription)")
        }
    }

    func toggleSection(_ category: TaskCategory) {
        withAnimation {
            if expandedSections.contains(category) {
                expandedSections.remove(category)
            } else {
                expandedSections.insert(category)
            }
        }
    }

    func isSectionExpanded(_ category: TaskCategory) -> Bool {
        expandedSections.contains(category)
    }

    func addCustomTask(_ task: TaskItem) {
        Task {
            do {
                // Save to Firebase
                try await firebaseService.saveTask(task)

                // Reload tasks from Firebase to get the new task with its ID
                await loadTasks()

                // If frequency is recurring, handle recurrence logic
                if let frequency = task.taskFrequency, frequency != .once {
                    // Future: implement recurring task logic
                    print("Recurring task created: \(frequency.displayName)")
                }

            } catch {
                print("Error adding custom task: \(error.localizedDescription)")
            }
        }
    }

    private func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
}
