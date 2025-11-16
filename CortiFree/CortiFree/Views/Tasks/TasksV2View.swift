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

    // Computed property: Tasks for current day (ordre chronologique)
    private var tasks: [HabitTask] {
        var dailyTasks: [HabitTask] = []
        let week = WeeklyHabitProgression.currentWeek(for: currentDay)
        let dayOfWeek = (currentDay - 1) % 7 // 0 = lundi, 6 = dimanche

        // 1. SE LEVER AVANT 7H (matin)
        let sleepProgression = WeeklyHabitProgression.sleepProgression(week: week)
        let sleepVariants = HabitVariantConfig.getSleepVariants()

        // Ajouter "Se lever avant 7h"
        if sleepVariants.count > 0 {
            dailyTasks.append(HabitTask(
                title: sleepVariants[0].title,
                frequency: "", // For compatibility
                duration: "", // Pas de durée pour le sommeil
                frequencyText: "Quotidien",
                difficulty: 2,
                streak: 10,
                imageName: sleepVariants[0].imageName,
                totalCompletions: 24,
                last7Days: [true, true, false, true, true, true, true],
                impactAreas: HabitTask.getImpactAreas(for: "habit_sleep")
            ))
        }

        // 2. RESPIRATION (matin)
        let breathingProgression = WeeklyHabitProgression.breathingProgression(week: week)
        let breathingDuration = WeeklyHabitProgression.formatProgressionDisplay(breathingProgression)
        // Afficher seulement certains jours selon fréquence
        let showBreathing = shouldShowTask(dayOfWeek: dayOfWeek, frequencyPerWeek: breathingProgression.frequencyPerWeek)

        if showBreathing {
            dailyTasks.append(HabitTask(
                title: "Respirer en conscience",
                frequency: breathingDuration, // For compatibility
                duration: breathingDuration,
                frequencyText: breathingProgression.formattedFrequency,
                difficulty: 1,
                streak: 15,
                imageName: "habit_breathe",
                totalCompletions: 30,
                last7Days: [true, true, true, true, false, true, true],
                impactAreas: HabitTask.getImpactAreas(for: "habit_breathe")
            ))
        }

        // 3. MÉDITATION (matin)
        let meditationProgression = WeeklyHabitProgression.meditationProgression(week: week)
        let meditationDuration = WeeklyHabitProgression.formatProgressionDisplay(meditationProgression)
        let showMeditation = shouldShowTask(dayOfWeek: dayOfWeek, frequencyPerWeek: meditationProgression.frequencyPerWeek)

        if showMeditation {
            dailyTasks.append(HabitTask(
                title: "Méditer en pleine conscience",
                frequency: meditationDuration,
                duration: meditationDuration,
                frequencyText: meditationProgression.formattedFrequency,
                difficulty: 3,
                streak: 24,
                imageName: "habit_meditate",
                totalCompletions: 24,
                last7Days: [true, false, true, true, true, true, true],
                impactAreas: HabitTask.getImpactAreas(for: "habit_meditate")
            ))
        }

        // 4. HYDRATATION (toute la journée)
        let waterProgression = WeeklyHabitProgression.waterProgression(week: week)
        let waterQuantity = waterProgression.formattedQuantity ?? "2L"

        dailyTasks.append(HabitTask(
            title: "Boire au minimum \(waterQuantity) d'eau",
            frequency: "", // For compatibility
            duration: "", // Pas de durée pour l'eau
            frequencyText: "Quotidien",
            difficulty: 1,
            streak: 17,
            imageName: "habit_water",
            totalCompletions: 24,
            last7Days: [true, true, false, true, true, true, true],
            impactAreas: HabitTask.getImpactAreas(for: "habit_water")
        ))

        // 5. SPORT (journée) - Variante selon le jour
        let sportProgression = WeeklyHabitProgression.sportProgression(week: week)
        let sportDuration = WeeklyHabitProgression.formatProgressionDisplay(sportProgression)
        let showSport = shouldShowTask(dayOfWeek: dayOfWeek, frequencyPerWeek: sportProgression.frequencyPerWeek)

        if showSport, let sportVariant = HabitVariantConfig.variantForDay(currentDay, habitType: "sport") {
            dailyTasks.append(HabitTask(
                title: sportVariant.title,
                frequency: sportDuration,
                duration: sportDuration,
                frequencyText: sportProgression.formattedFrequency,
                difficulty: 3,
                streak: 12,
                imageName: sportVariant.imageName,
                totalCompletions: 14,
                last7Days: [true, false, true, false, true, true, false],
                impactAreas: HabitTask.getImpactAreas(for: "habit_sport")
            ))
        }

        // 6. NATURE (après-midi)
        let natureProgression = WeeklyHabitProgression.natureProgression(week: week)
        let natureDuration = WeeklyHabitProgression.formatProgressionDisplay(natureProgression)
        let showNature = shouldShowTask(dayOfWeek: dayOfWeek, frequencyPerWeek: natureProgression.frequencyPerWeek)

        if showNature, let natureVariant = HabitVariantConfig.variantForDay(currentDay, habitType: "nature") {
            dailyTasks.append(HabitTask(
                title: natureVariant.title,
                frequency: natureDuration,
                duration: natureDuration,
                frequencyText: natureProgression.formattedFrequency,
                difficulty: 2,
                streak: 6,
                imageName: natureVariant.imageName,
                totalCompletions: 8,
                last7Days: [false, true, false, false, true, false, true],
                impactAreas: HabitTask.getImpactAreas(for: "habit_nature")
            ))
        }

        // 7. SOCIAL (soirée)
        let socialProgression = WeeklyHabitProgression.socialProgression(week: week)
        let showSocial = shouldShowTask(dayOfWeek: dayOfWeek, frequencyPerWeek: socialProgression.frequencyPerWeek)

        if showSocial, let socialVariant = HabitVariantConfig.variantForDay(currentDay, habitType: "social") {
            dailyTasks.append(HabitTask(
                title: socialVariant.title,
                frequency: "", // For compatibility
                duration: "", // Pas de durée pour le social
                frequencyText: socialProgression.formattedFrequency,
                difficulty: 2,
                streak: 9,
                imageName: socialVariant.imageName,
                totalCompletions: 12,
                last7Days: [true, false, true, true, false, true, false],
                impactAreas: HabitTask.getImpactAreas(for: "habit_social")
            ))
        }

        // 8. JOURNAL (soir)
        let journalProgression = WeeklyHabitProgression.journalProgression(week: week)
        let journalDuration = WeeklyHabitProgression.formatProgressionDisplay(journalProgression)
        let showJournal = shouldShowTask(dayOfWeek: dayOfWeek, frequencyPerWeek: journalProgression.frequencyPerWeek)

        if showJournal {
            dailyTasks.append(HabitTask(
                title: "Écrire ses pensées",
                frequency: journalDuration,
                duration: journalDuration,
                frequencyText: journalProgression.formattedFrequency,
                difficulty: 2,
                streak: 8,
                imageName: "habit_journal",
                totalCompletions: 18,
                last7Days: [false, true, true, true, false, true, true],
                impactAreas: HabitTask.getImpactAreas(for: "habit_journal")
            ))
        }

        // 9. SE COUCHER AVANT 23H (soir)
        if sleepVariants.count > 1 {
            dailyTasks.append(HabitTask(
                title: sleepVariants[1].title,
                frequency: "", // For compatibility
                duration: "", // Pas de durée pour le sommeil
                frequencyText: "Quotidien",
                difficulty: 2,
                streak: 10,
                imageName: sleepVariants[1].imageName,
                totalCompletions: 24,
                last7Days: [true, true, false, true, true, true, true],
                impactAreas: HabitTask.getImpactAreas(for: "habit_sleep")
            ))
        }

        return dailyTasks
    }

    // Helper function to determine if a task should be shown on a given day
    private func shouldShowTask(dayOfWeek: Int, frequencyPerWeek: Int) -> Bool {
        if frequencyPerWeek >= 7 { return true } // Daily

        // Distribuer les tâches de manière équilibrée dans la semaine
        switch frequencyPerWeek {
        case 1: return dayOfWeek == 3 // Mercredi seulement
        case 2: return dayOfWeek == 1 || dayOfWeek == 4 // Mardi et vendredi
        case 3: return dayOfWeek == 0 || dayOfWeek == 2 || dayOfWeek == 5 // Lundi, mercredi, samedi
        case 4: return dayOfWeek != 2 && dayOfWeek != 5 // Tous sauf mercredi et samedi
        case 5: return dayOfWeek != 6 && dayOfWeek != 3 // Tous sauf dimanche et jeudi
        case 6: return dayOfWeek != 0 // Tous sauf lundi
        default: return true
        }
    }

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
                                .foregroundColor(AppConstants.Colors.streakOrange)

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
                    .padding(.horizontal, AppConstants.Layout.paddingLarge)
                    .padding(.top, 16)

                    // Day counter
                    HStack {
                        Text(currentDay <= 66 ? "Jour \(currentDay)/66" : "Jour \(currentDay)")
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
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    currentDay += 1
                                }
                            }) {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .padding(.horizontal, AppConstants.Layout.paddingLarge)

                    // Encouragement text
                    Text("Tu fais du super boulot. Continue !")
                        .font(.custom("Poppins-Regular", size: 14))
                        .foregroundColor(.white.opacity(0.6))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, AppConstants.Layout.paddingLarge)
                        .padding(.bottom, 8)

                    // Tabs: À faire, Fait, Passé
                    HStack(spacing: 12) {
                        // À faire tab
                        Button(action: {
                            HapticManager.light()
                            selectedTab = .todos
                        }) {
                            HStack(spacing: 4) {
                                Text(NSLocalizedString("tasks.todo", comment: ""))
                                    .font(.custom(selectedTab == .todos ? "Poppins-SemiBold" : "Poppins-Regular", size: 14))
                                    .foregroundColor(selectedTab == .todos ? .black : .white.opacity(0.6))

                                Text("\(todoCount)")
                                    .font(.custom("HankenGrotesk-Bold", size: 12))
                                    .foregroundColor(selectedTab == .todos ? .black.opacity(0.6) : .white.opacity(0.4))
                            }
                            .padding(.horizontal, AppConstants.Layout.paddingMedium)
                            .padding(.vertical, AppConstants.Layout.paddingSmall)
                            .background(
                                RoundedRectangle(cornerRadius: AppConstants.Layout.paddingSmall)
                                    .fill(selectedTab == .todos ? .white : Color.clear)
                            )
                        }

                        // Done tab
                        Button(action: {
                            HapticManager.light()
                            selectedTab = .done
                        }) {
                            HStack(spacing: 4) {
                                Text(NSLocalizedString("tasks.done", comment: ""))
                                    .font(.custom(selectedTab == .done ? "Poppins-SemiBold" : "Poppins-Regular", size: 14))
                                    .foregroundColor(selectedTab == .done ? .black : .white.opacity(0.6))

                                Text("\(doneCount)")
                                    .font(.custom("HankenGrotesk-Bold", size: 12))
                                    .foregroundColor(selectedTab == .done ? .black.opacity(0.6) : .white.opacity(0.4))
                            }
                            .padding(.horizontal, AppConstants.Layout.paddingMedium)
                            .padding(.vertical, AppConstants.Layout.paddingSmall)
                            .background(
                                RoundedRectangle(cornerRadius: AppConstants.Layout.paddingSmall)
                                    .fill(selectedTab == .done ? .white : Color.clear)
                            )
                        }

                        // Skipped tab
                        Button(action: {
                            HapticManager.light()
                            selectedTab = .skipped
                        }) {
                            HStack(spacing: 4) {
                                Text(NSLocalizedString("tasks.skipped", comment: ""))
                                    .font(.custom(selectedTab == .skipped ? "Poppins-SemiBold" : "Poppins-Regular", size: 14))
                                    .foregroundColor(selectedTab == .skipped ? .black : .white.opacity(0.6))

                                Text("\(skippedCount)")
                                    .font(.custom("HankenGrotesk-Bold", size: 12))
                                    .foregroundColor(selectedTab == .skipped ? .black.opacity(0.6) : .white.opacity(0.4))
                            }
                            .padding(.horizontal, AppConstants.Layout.paddingMedium)
                            .padding(.vertical, AppConstants.Layout.paddingSmall)
                            .background(
                                RoundedRectangle(cornerRadius: AppConstants.Layout.paddingSmall)
                                    .fill(selectedTab == .skipped ? .white : Color.clear)
                            )
                        }

                        Spacer()
                    }
                    .padding(.horizontal, AppConstants.Layout.paddingLarge)
                    .padding(.bottom, 16)
                }

                // Tasks list with pull to refresh
                RefreshableScrollView(
                    isRefreshing: $isRefreshing,
                    action: {
                        // Simulate refresh
                        try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
                        // Here you could reload tasks from Firebase
                        HapticManager.success()
                    }
                ) {
                    VStack(spacing: 20) {
                        ForEach(Array(filteredTasks.enumerated()), id: \.offset) { index, task in
                            HabitTaskCard(
                                title: task.title,
                                duration: task.duration,
                                frequencyText: task.frequencyText,
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
                    .padding(.horizontal, AppConstants.Layout.paddingLarge)
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
