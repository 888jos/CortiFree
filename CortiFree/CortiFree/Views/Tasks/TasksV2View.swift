//
//  TasksV2View.swift
//  CortiFree
//
//  Created by Claude on 14/11/2025.
//  Vue principale des tâches d'habitudes avec header et liste
//

import SwiftUI

struct TasksV2View: View {
    @State private var selectedTask: HabitTask?
    @State private var selectedTab: TaskTab = .todos
    @State private var taskStatuses: [String: [String: TaskStatus]] = [:] // [day: [taskTitle: status]]
    @State private var currentDay: Int = 1 // Day 1 to 66
    @State private var showAddTask = false
    @State private var globalScore: Int = 45 // Starts at initial score from onboarding
    @State private var taskStreaks: [String: Int] = [:] // Track individual task streaks
    @State private var globalStreak: Int = 0 // Global streak (consecutive days with at least 1 task validated)
    @State private var showConfetti: Bool = false // Confetti animation trigger
    @State private var isRefreshing: Bool = false // Pull to refresh state

    // Mock initial global score from onboarding (day 1)
    private let initialGlobalScore: Int = 45 // This would come from CortiFreeRatingView

    // Actual day the user is on (today's real day)
    private let actualDay: Int = 1 // This would be calculated from actual date

    // Computed score increase since day 1
    private var globalScoreIncrease: Int {
        return globalScore - initialGlobalScore
    }

    enum TaskTab {
        case todos
        case done
        case skipped
    }

    enum TaskStatus {
        case todo
        case done
        case skipped
    }

    // Mock data for 8 habits
    private let tasks: [HabitTask] = [
        HabitTask(
            title: "Se réveiller à 7h",
            frequency: "Tous les jours",
            difficulty: 2,
            streak: 10,
            imageName: "habit_sport",
            totalCompletions: 24,
            last7Days: [true, true, false, true, true, true, true],
            impactAreas: HabitTask.getImpactAreas(for: "habit_sleep")
        ),
        HabitTask(
            title: "Exercices de respiration",
            frequency: "2x/jour",
            difficulty: 1,
            streak: 15,
            imageName: "habit_breathe",
            totalCompletions: 30,
            last7Days: [true, true, true, true, false, true, true],
            impactAreas: HabitTask.getImpactAreas(for: "habit_breathe")
        ),
        HabitTask(
            title: "Méditer 10 minutes",
            frequency: "1x/jour",
            difficulty: 3,
            streak: 24,
            imageName: "habit_meditate",
            totalCompletions: 24,
            last7Days: [true, false, true, true, true, true, true],
            impactAreas: HabitTask.getImpactAreas(for: "habit_meditate")
        ),
        HabitTask(
            title: "Tenir un journal",
            frequency: "1x/jour",
            difficulty: 2,
            streak: 8,
            imageName: "habit_water",
            totalCompletions: 18,
            last7Days: [false, true, true, true, false, true, true],
            impactAreas: HabitTask.getImpactAreas(for: "habit_journal")
        ),
        HabitTask(
            title: "Faire du sport",
            frequency: "3x/semaine",
            difficulty: 3,
            streak: 12,
            imageName: "habit_nature",
            totalCompletions: 14,
            last7Days: [true, false, true, false, true, true, false],
            impactAreas: HabitTask.getImpactAreas(for: "habit_sport")
        ),
        HabitTask(
            title: "Boire 2.5l d'eau",
            frequency: "1x/jour",
            difficulty: 1,
            streak: 17,
            imageName: "habit_journal",
            totalCompletions: 24,
            last7Days: [true, true, false, true, true, true, true],
            impactAreas: HabitTask.getImpactAreas(for: "habit_water")
        ),
        HabitTask(
            title: "Temps dans la nature",
            frequency: "2x/semaine",
            difficulty: 2,
            streak: 6,
            imageName: "habit_sleep",
            totalCompletions: 8,
            last7Days: [false, true, false, false, true, false, true],
            impactAreas: HabitTask.getImpactAreas(for: "habit_nature")
        ),
        HabitTask(
            title: "Interactions sociales",
            frequency: "3x/semaine",
            difficulty: 2,
            streak: 9,
            imageName: "habit_social",
            totalCompletions: 12,
            last7Days: [true, false, true, true, false, true, false],
            impactAreas: HabitTask.getImpactAreas(for: "habit_social")
        )
    ]

    var body: some View {
        ZStack {
            // Galaxy background
            GalaxyBackgroundView(intensity: 1.0)

            VStack(spacing: 0) {
                // Header section
                VStack(spacing: 8) {
                    // Top row: Streak and Global Score
                    HStack(spacing: 16) {
                        // Flame streak
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 14))
                                .foregroundColor(Color(hex: "FF8800"))

                            Text("\(globalStreak)")
                                .font(.custom("HankenGrotesk-Bold", size: 16))
                                .foregroundColor(.white)
                        }

                        Spacer()

                        // Global Score (from CortiFreeRatingView for day 1)
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.white)

                            Text("\(globalScore)")
                                .font(.custom("HankenGrotesk-Bold", size: 16))
                                .foregroundColor(.white)

                            Text("(+\(globalScoreIncrease))")
                                .font(.custom("Poppins-Regular", size: 12))
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)

                    // Day counter
                    HStack {
                        Text("Jour \(currentDay)/66")
                            .font(.custom("HankenGrotesk-Bold", size: 48))
                            .foregroundColor(.white)

                        Spacer()

                        // Navigation arrows
                        HStack(spacing: 12) {
                            Button(action: {
                                HapticManager.light()
                                if currentDay > 1 {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        currentDay -= 1
                                    }
                                }
                            }) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(currentDay > 1 ? .white : .white.opacity(0.3))
                            }
                            .disabled(currentDay <= 1)

                            Button(action: {
                                HapticManager.light()
                                if currentDay < 66 {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        currentDay += 1
                                    }
                                }
                            }) {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(currentDay < 66 ? .white : .white.opacity(0.3))
                            }
                            .disabled(currentDay >= 66)
                        }
                    }
                    .padding(.horizontal, 24)

                    // Encouragement text
                    Text("Tu fais du super boulot. Continue !")
                        .font(.custom("Poppins-Regular", size: 14))
                        .foregroundColor(.white.opacity(0.6))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 8)

                    // Tabs: À faire, Fait, Passé
                    HStack(spacing: 12) {
                        // À faire tab
                        Button(action: {
                            HapticManager.light()
                            selectedTab = .todos
                        }) {
                            HStack(spacing: 4) {
                                Text("À faire")
                                    .font(.custom(selectedTab == .todos ? "Poppins-SemiBold" : "Poppins-Regular", size: 14))
                                    .foregroundColor(selectedTab == .todos ? .black : .white.opacity(0.6))

                                Text("\(todoCount)")
                                    .font(.custom("HankenGrotesk-Bold", size: 12))
                                    .foregroundColor(selectedTab == .todos ? .black.opacity(0.6) : .white.opacity(0.4))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(selectedTab == .todos ? .white : Color.clear)
                            )
                        }

                        // Done tab
                        Button(action: {
                            HapticManager.light()
                            selectedTab = .done
                        }) {
                            HStack(spacing: 4) {
                                Text("Fait")
                                    .font(.custom(selectedTab == .done ? "Poppins-SemiBold" : "Poppins-Regular", size: 14))
                                    .foregroundColor(selectedTab == .done ? .black : .white.opacity(0.6))

                                Text("\(doneCount)")
                                    .font(.custom("HankenGrotesk-Bold", size: 12))
                                    .foregroundColor(selectedTab == .done ? .black.opacity(0.6) : .white.opacity(0.4))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(selectedTab == .done ? .white : Color.clear)
                            )
                        }

                        // Skipped tab
                        Button(action: {
                            HapticManager.light()
                            selectedTab = .skipped
                        }) {
                            HStack(spacing: 4) {
                                Text("Passé")
                                    .font(.custom(selectedTab == .skipped ? "Poppins-SemiBold" : "Poppins-Regular", size: 14))
                                    .foregroundColor(selectedTab == .skipped ? .black : .white.opacity(0.6))

                                Text("\(skippedCount)")
                                    .font(.custom("HankenGrotesk-Bold", size: 12))
                                    .foregroundColor(selectedTab == .skipped ? .black.opacity(0.6) : .white.opacity(0.4))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(selectedTab == .skipped ? .white : Color.clear)
                            )
                        }

                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
                }

                // Tasks list with pull to refresh
                RefreshableScrollView(
                    isRefreshing: $isRefreshing,
                    action: {
                        // Simulate refresh
                        await Task.sleep(1_500_000_000) // 1.5 seconds
                        // Here you could reload tasks from Firebase
                        HapticManager.success()
                    }
                ) {
                    VStack(spacing: 20) {
                        ForEach(Array(filteredTasks.enumerated()), id: \.offset) { index, task in
                            HabitTaskCard(
                                title: task.title,
                                frequency: task.frequency,
                                difficulty: task.difficulty,
                                streak: getTaskStreak(task),
                                imageName: task.imageName,
                                action: {
                                    HapticManager.light()
                                    selectedTask = task
                                },
                                onValidate: {
                                    validateTask(task)
                                },
                                onSkip: {
                                    skipTask(task)
                                }
                            )
                            .cascadeAppear(index: index, totalCount: filteredTasks.count)
                            .bouncePress()
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 100)
                }
            }
        }
        .fullScreenCover(item: $selectedTask) { task in
            HabitTaskDetailView(
                task: task,
                onValidate: {
                    validateTask(task)
                    selectedTask = nil
                },
                onSkip: {
                    skipTask(task)
                    selectedTask = nil
                }
            )
        }
        .sheet(isPresented: $showAddTask) {
            AddTaskManuallyView(onDismiss: {
                showAddTask = false
            })
        }
        .onAppear {
            // Check and update global streak on view load
            checkAndResetStreaksIfNeeded()
        }
        .confetti(isActive: showConfetti)
    }

    // Check if previous days were missed (no validation) and reset streaks accordingly
    private func checkAndResetStreaksIfNeeded() {
        // Check if the previous day had at least one validation
        if actualDay > 1 {
            let previousDay = actualDay - 1
            let previousDayStatuses = taskStatuses[dayKey(previousDay)] ?? [:]
            let hadValidation = previousDayStatuses.values.contains(.done)

            if !hadValidation {
                // Previous day had no validations, reset global streak
                globalStreak = 0

                // Also reset all task streaks
                for task in tasks {
                    let key = taskKey(task)
                    taskStreaks[key] = 0
                }
            } else {
                // Previous day had validations, update streaks normally
                updateGlobalStreak()
                for task in tasks {
                    updateTaskStreak(task)
                }
            }
        }
    }

    // Computed properties for counts
    private var todoCount: Int {
        tasks.filter { getTaskStatus($0) == .todo }.count
    }

    private var doneCount: Int {
        tasks.filter { getTaskStatus($0) == .done }.count
    }

    private var skippedCount: Int {
        tasks.filter { getTaskStatus($0) == .skipped }.count
    }

    // Filtered tasks based on selected tab
    private var filteredTasks: [HabitTask] {
        switch selectedTab {
        case .todos:
            return tasks.filter { getTaskStatus($0) == .todo }
        case .done:
            return tasks.filter { getTaskStatus($0) == .done }
        case .skipped:
            return tasks.filter { getTaskStatus($0) == .skipped }
        }
    }

    // Helper functions
    private func dayKey(_ day: Int) -> String {
        return "day_\(day)"
    }

    private func taskKey(_ task: HabitTask) -> String {
        return task.title
    }

    private func getTaskStatus(_ task: HabitTask) -> TaskStatus {
        return taskStatuses[dayKey(currentDay)]?[taskKey(task)] ?? .todo
    }

    private func getTaskStreak(_ task: HabitTask) -> Int {
        return taskStreaks[taskKey(task)] ?? 0
    }

    private func updateTaskStreak(_ task: HabitTask) {
        let key = taskKey(task)
        var streak = 0

        // Count consecutive days with validation, starting from actualDay going backwards
        for day in stride(from: actualDay, through: 1, by: -1) {
            let status = taskStatuses[dayKey(day)]?[key]
            if status == .done {
                streak += 1
            } else {
                break
            }
        }

        taskStreaks[key] = streak
    }

    private func updateGlobalStreak() {
        var streak = 0

        // Count consecutive days with at least 1 validated task, starting from actualDay going backwards
        for day in stride(from: actualDay, through: 1, by: -1) {
            let dayStatuses = taskStatuses[dayKey(day)] ?? [:]
            let hasValidation = dayStatuses.values.contains(.done)

            if hasValidation {
                streak += 1
            } else {
                break
            }
        }

        globalStreak = streak
    }

    private func validateTask(_ task: HabitTask) {
        // Only allow validation for the actual current day
        guard currentDay == actualDay else {
            HapticManager.error()
            return
        }

        HapticManager.success()

        // Initialize day dictionary if needed
        if taskStatuses[dayKey(currentDay)] == nil {
            taskStatuses[dayKey(currentDay)] = [:]
        }

        taskStatuses[dayKey(currentDay)]?[taskKey(task)] = .done

        // Increase global score by 1 point per validated task
        globalScore = min(globalScore + 1, 98)

        // Update task streak
        updateTaskStreak(task)

        // Update global streak
        updateGlobalStreak()

        // Trigger confetti animation
        showConfetti = true
        // Reset confetti after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            showConfetti = false
        }
    }

    private func skipTask(_ task: HabitTask) {
        // Only allow skip for the actual current day
        guard currentDay == actualDay else {
            HapticManager.error()
            return
        }

        HapticManager.medium()

        // Initialize day dictionary if needed
        if taskStatuses[dayKey(currentDay)] == nil {
            taskStatuses[dayKey(currentDay)] = [:]
        }

        taskStatuses[dayKey(currentDay)]?[taskKey(task)] = .skipped

        // Reset task streak to 0
        taskStreaks[taskKey(task)] = 0

        // Update global streak (in case this was the only task keeping the streak alive)
        updateGlobalStreak()
    }
}

#Preview {
    TasksV2View()
}
