//
//  TasksV2View.swift
//  CortiFree
//
//  Created by Claude on 14/11/2025.
//  Vue principale des tâches d'habitudes avec header et liste
//

import SwiftUI
import FirebaseAuth

struct TasksV2View: View {
    @StateObject private var achievementService = AchievementService.shared
    @StateObject private var habitBadgeService = HabitBadgeService.shared
    @State private var selectedTask: HabitTask?
    @State private var selectedTab: TaskTab = .todos
    @State private var taskStatuses: [String: [String: TaskStatus]] = [:] // [day: [taskTitle: status]]
    @State private var currentDay: Int = 1 // Day 1 to 66
    @State private var showAddTask = false
    @State private var globalScore: Int = 45 // Current global score (average of 5 domains, rounded)
    @State private var initialGlobalScore: Int = 45 // Initial score from onboarding
    @State private var taskStreaks: [String: Int] = [:] // Track individual task streaks
    @State private var globalStreak: Int = 0 // Global streak (consecutive days with at least 1 task validated)
    @State private var showConfetti: Bool = false // Confetti animation trigger
    @State private var showSuccessCheckmark: Bool = false // Success checkmark animation trigger
    @State private var isRefreshing: Bool = false // Pull to refresh state
    @State private var showFutureWeekAlert: Bool = false // Show blocking screen for future weeks

    // Firebase data
    @State private var userSettings: UserSettings?
    @State private var habitTracking: [String: HabitTracking] = [:]
    @State private var isLoadingData: Bool = true

    // Actual day the user is on (calculated from start date)
    private var actualDay: Int {
        return userSettings?.currentProgramDay ?? 1
    }

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

    // Computed property: Tasks for current DAY only
    private var tasks: [HabitTask] {
        var dailyTasks: [HabitTask] = []
        let week = WeeklyHabitProgression.currentWeek(for: currentDay)
        let dayOfWeek = (currentDay - 1) % 7 // 0 = lundi, 6 = dimanche

        // 1. SE LEVER AVANT 7H (matin)
        let sleepProgression = WeeklyHabitProgression.sleepProgression(week: week)
        let sleepVariants = HabitVariantConfig.getSleepVariants()

        // Ajouter "Se lever avant 7h"
        if sleepVariants.count > 0 {
            let sleepData = habitTracking["sleep"]
            dailyTasks.append(HabitTask(
                title: sleepVariants[0].title,
                frequency: "", // For compatibility
                duration: "", // Pas de durée pour le sommeil
                frequencyText: "Quotidien",
                difficulty: 2,
                streak: sleepData?.currentStreak ?? 0,
                imageName: sleepVariants[0].imageName,
                totalCompletions: sleepData?.totalCompletions ?? 0,
                last7Days: sleepData?.last7Days ?? [false, false, false, false, false, false, false],
                impactAreas: HabitTask.getImpactAreas(for: "habit_sleep")
            ))
        }

        // 2. RESPIRATION (matin)
        let breathingProgression = WeeklyHabitProgression.breathingProgression(week: week)
        let breathingDuration = WeeklyHabitProgression.formatProgressionDisplay(breathingProgression)
        // Afficher seulement certains jours selon fréquence
        let showBreathing = shouldShowTask(dayOfWeek: dayOfWeek, frequencyPerWeek: breathingProgression.frequencyPerWeek)

        if showBreathing {
            let breathingData = habitTracking["breathing"]
            dailyTasks.append(HabitTask(
                title: "Respirer en conscience",
                frequency: breathingDuration, // For compatibility
                duration: breathingDuration,
                frequencyText: breathingProgression.formattedFrequency,
                difficulty: 1,
                streak: breathingData?.currentStreak ?? 0,
                imageName: "habit_breathe",
                totalCompletions: breathingData?.totalCompletions ?? 0,
                last7Days: breathingData?.last7Days ?? [false, false, false, false, false, false, false],
                impactAreas: HabitTask.getImpactAreas(for: "habit_breathe")
            ))
        }

        // 3. MÉDITATION (matin)
        let meditationProgression = WeeklyHabitProgression.meditationProgression(week: week)
        let meditationDuration = WeeklyHabitProgression.formatProgressionDisplay(meditationProgression)
        let showMeditation = shouldShowTask(dayOfWeek: dayOfWeek, frequencyPerWeek: meditationProgression.frequencyPerWeek)

        if showMeditation {
            let meditationData = habitTracking["meditation"]
            dailyTasks.append(HabitTask(
                title: "Méditer en pleine conscience",
                frequency: meditationDuration,
                duration: meditationDuration,
                frequencyText: meditationProgression.formattedFrequency,
                difficulty: 3,
                streak: meditationData?.currentStreak ?? 0,
                imageName: "habit_meditate",
                totalCompletions: meditationData?.totalCompletions ?? 0,
                last7Days: meditationData?.last7Days ?? [false, false, false, false, false, false, false],
                impactAreas: HabitTask.getImpactAreas(for: "habit_meditate")
            ))
        }

        // 4. HYDRATATION (toute la journée)
        let waterProgression = WeeklyHabitProgression.waterProgression(week: week)
        let waterQuantity = waterProgression.formattedQuantity ?? "2L"
        let waterData = habitTracking["water"]

        dailyTasks.append(HabitTask(
            title: "Boire au minimum \(waterQuantity) d'eau",
            frequency: "", // For compatibility
            duration: "", // Pas de durée pour l'eau
            frequencyText: "Quotidien",
            difficulty: 1,
            streak: waterData?.currentStreak ?? 0,
            imageName: "habit_water",
            totalCompletions: waterData?.totalCompletions ?? 0,
            last7Days: waterData?.last7Days ?? [false, false, false, false, false, false, false],
            impactAreas: HabitTask.getImpactAreas(for: "habit_water")
        ))

        // 5. SPORT (journée) - Variante selon le jour
        let sportProgression = WeeklyHabitProgression.sportProgression(week: week)
        let sportDuration = WeeklyHabitProgression.formatProgressionDisplay(sportProgression)
        let showSport = shouldShowTask(dayOfWeek: dayOfWeek, frequencyPerWeek: sportProgression.frequencyPerWeek)

        if showSport, let sportVariant = HabitVariantConfig.variantForDay(currentDay, habitType: "sport") {
            let sportData = habitTracking["sport"]
            dailyTasks.append(HabitTask(
                title: sportVariant.title,
                frequency: sportDuration,
                duration: sportDuration,
                frequencyText: sportProgression.formattedFrequency,
                difficulty: 3,
                streak: sportData?.currentStreak ?? 0,
                imageName: sportVariant.imageName,
                totalCompletions: sportData?.totalCompletions ?? 0,
                last7Days: sportData?.last7Days ?? [false, false, false, false, false, false, false],
                impactAreas: HabitTask.getImpactAreas(for: "habit_sport")
            ))
        }

        // 6. NATURE (après-midi)
        let natureProgression = WeeklyHabitProgression.natureProgression(week: week)
        let natureDuration = WeeklyHabitProgression.formatProgressionDisplay(natureProgression)
        let showNature = shouldShowTask(dayOfWeek: dayOfWeek, frequencyPerWeek: natureProgression.frequencyPerWeek)

        if showNature, let natureVariant = HabitVariantConfig.variantForDay(currentDay, habitType: "nature") {
            let natureData = habitTracking["nature"]
            dailyTasks.append(HabitTask(
                title: natureVariant.title,
                frequency: natureDuration,
                duration: natureDuration,
                frequencyText: natureProgression.formattedFrequency,
                difficulty: 2,
                streak: natureData?.currentStreak ?? 0,
                imageName: natureVariant.imageName,
                totalCompletions: natureData?.totalCompletions ?? 0,
                last7Days: natureData?.last7Days ?? [false, false, false, false, false, false, false],
                impactAreas: HabitTask.getImpactAreas(for: "habit_nature")
            ))
        }

        // 7. SOCIAL (soirée)
        let socialProgression = WeeklyHabitProgression.socialProgression(week: week)
        let showSocial = shouldShowTask(dayOfWeek: dayOfWeek, frequencyPerWeek: socialProgression.frequencyPerWeek)

        if showSocial, let socialVariant = HabitVariantConfig.variantForDay(currentDay, habitType: "social") {
            let socialData = habitTracking["social"]
            dailyTasks.append(HabitTask(
                title: socialVariant.title,
                frequency: "", // For compatibility
                duration: "", // Pas de durée pour le social
                frequencyText: socialProgression.formattedFrequency,
                difficulty: 2,
                streak: socialData?.currentStreak ?? 0,
                imageName: socialVariant.imageName,
                totalCompletions: socialData?.totalCompletions ?? 0,
                last7Days: socialData?.last7Days ?? [false, false, false, false, false, false, false],
                impactAreas: HabitTask.getImpactAreas(for: "habit_social")
            ))
        }

        // 8. JOURNAL (soir)
        let journalProgression = WeeklyHabitProgression.journalProgression(week: week)
        let journalDuration = WeeklyHabitProgression.formatProgressionDisplay(journalProgression)
        let showJournal = shouldShowTask(dayOfWeek: dayOfWeek, frequencyPerWeek: journalProgression.frequencyPerWeek)

        if showJournal {
            let journalData = habitTracking["journal"]
            dailyTasks.append(HabitTask(
                title: "Écrire ses pensées",
                frequency: journalDuration,
                duration: journalDuration,
                frequencyText: journalProgression.formattedFrequency,
                difficulty: 2,
                streak: journalData?.currentStreak ?? 0,
                imageName: "habit_journal",
                totalCompletions: journalData?.totalCompletions ?? 0,
                last7Days: journalData?.last7Days ?? [false, false, false, false, false, false, false],
                impactAreas: HabitTask.getImpactAreas(for: "habit_journal")
            ))
        }

        // 9. SE COUCHER AVANT 23H (soir)
        if sleepVariants.count > 1 {
            let sleepData = habitTracking["sleep"]
            dailyTasks.append(HabitTask(
                title: sleepVariants[1].title,
                frequency: "", // For compatibility
                duration: "", // Pas de durée pour le sommeil
                frequencyText: "Quotidien",
                difficulty: 2,
                streak: sleepData?.currentStreak ?? 0,
                imageName: sleepVariants[1].imageName,
                totalCompletions: sleepData?.totalCompletions ?? 0,
                last7Days: sleepData?.last7Days ?? [false, false, false, false, false, false, false],
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
            // Simple gradient background for better performance
            LinearGradient(
                colors: [
                    Color(hex: "0A0515"),
                    Color(hex: "1a0a2e"),
                    Color(hex: "0A0515")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

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
                                let targetDay = currentDay + 1
                                // TEMPORARY: Disabled future week restriction for testing
                                // TODO: Re-enable this validation check after testing
                                // let currentWeek = WeeklyHabitProgression.currentWeek(for: actualDay)
                                // let targetWeek = WeeklyHabitProgression.currentWeek(for: targetDay)

                                // Allow navigation to any day (testing mode)
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    currentDay = targetDay
                                }

                                // ORIGINAL CODE (commented for testing):
                                // if targetWeek <= currentWeek {
                                //     withAnimation(.easeInOut(duration: 0.2)) {
                                //         currentDay = targetDay
                                //     }
                                // } else {
                                //     showFutureWeekAlert = true
                                // }
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
                        if isLoadingData {
                            // Show skeleton loaders while loading
                            ForEach(0..<5, id: \.self) { index in
                                SkeletonTaskCard()
                                    .cascadeAppear(index: index, totalCount: 5, baseDelay: 0.05)
                            }
                        } else {
                            // Show actual tasks when loaded
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
                                .bouncePress()
                                .cascadeAppear(index: index, totalCount: filteredTasks.count, baseDelay: 0.05)
                            }
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
            // Delay Firebase loading to prevent freeze
            Task {
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second delay
                loadFirebaseData()
                checkAndResetStreaksIfNeeded()
            }
        }
        .confetti(isActive: showConfetti)
        .overlay(
            Group {
                if showFutureWeekAlert {
                    FutureWeekBlockingView(
                        currentWeek: WeeklyHabitProgression.currentWeek(for: actualDay),
                        onDismiss: {
                            showFutureWeekAlert = false
                        }
                    )
                }

                // Achievement unlock popup
                if achievementService.showAchievementPopup, let achievement = achievementService.newlyUnlockedAchievement {
                    AchievementUnlockView(achievement: achievement) {
                        achievementService.showAchievementPopup = false
                    }
                    .transition(.opacity)
                }

                // Milestone celebration popup
                if achievementService.showMilestonePopup, let milestone = achievementService.newlyCompletedMilestone {
                    MilestoneCelebrationView(milestone: milestone) {
                        achievementService.showMilestonePopup = false
                    }
                    .transition(.opacity)
                }

                // Success checkmark animation
                if showSuccessCheckmark {
                    SuccessCheckmarkView {
                        showSuccessCheckmark = false
                    }
                    .transition(.scale.combined(with: .opacity))
                }

                // Habit badge unlock popup
                if habitBadgeService.showBadgePopup, let badge = habitBadgeService.newlyUnlockedBadge {
                    BadgeEvolutionView(badge: badge, isPresented: $habitBadgeService.showBadgePopup)
                        .transition(.opacity)
                }
            }
        )
    }

    // Load data from Firebase
    private func loadFirebaseData() {
        Task {
            isLoadingData = true
            defer { isLoadingData = false }

            guard let userId = Auth.auth().currentUser?.uid else { return }

            do {
                // Load user settings
                if let settings = try await FirebaseManager.shared.fetchUserSettings(uid: userId) {
                    await MainActor.run {
                        self.userSettings = settings
                        self.currentDay = settings.currentProgramDay
                        self.initialGlobalScore = settings.onboardingScore
                    }
                } else {
                    // Create default settings if not found
                    let defaultSettings = UserSettings()
                    try await FirebaseManager.shared.saveUserSettings(uid: userId, settings: defaultSettings)
                    await MainActor.run {
                        self.userSettings = defaultSettings
                        self.initialGlobalScore = defaultSettings.onboardingScore
                    }
                }

                // Load current global score from domain scores
                let currentScores = try await ImpactScoringService.shared.fetchCurrentScores()
                await MainActor.run {
                    // Global score = rounded average of 5 domains
                    self.globalScore = currentScores.roundedScores.global
                }

                // Load habit tracking data
                let tracking = try await FirebaseManager.shared.fetchAllHabitTracking(uid: userId)
                await MainActor.run {
                    self.habitTracking = tracking
                }

                // Load task statuses from Firebase
                let statuses = try await TaskStatusService.shared.loadAllTaskStatuses()
                await MainActor.run {
                    // Convert String status to TaskStatus enum
                    var convertedStatuses: [String: [String: TaskStatus]] = [:]
                    for (dayKey, dayTasks) in statuses {
                        var taskDict: [String: TaskStatus] = [:]
                        for (taskTitle, statusString) in dayTasks {
                            switch statusString {
                            case "done":
                                taskDict[taskTitle] = .done
                            case "skipped":
                                taskDict[taskTitle] = .skipped
                            default:
                                taskDict[taskTitle] = .todo
                            }
                        }
                        convertedStatuses[dayKey] = taskDict
                    }
                    self.taskStatuses = convertedStatuses
                }

                // If no habit tracking exists, initialize it
                if tracking.isEmpty {
                    try await FirebaseManager.shared.initializeHabitTracking(uid: userId)
                    // Reload after initialization
                    let newTracking = try await FirebaseManager.shared.fetchAllHabitTracking(uid: userId)
                    await MainActor.run {
                        self.habitTracking = newTracking
                    }
                }

                // Calculate global streak from all habits
                await MainActor.run {
                    updateGlobalStreak()
                }
            } catch {
                print("Error loading Firebase data: \(error)")
                // Use default values if Firebase fails
                await MainActor.run {
                    self.userSettings = UserSettings.loadFromUserDefaults() ?? UserSettings()
                }
            }
        }
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
        // TEMPORARY: Disabled validation restriction for testing
        // TODO: Re-enable this validation check after testing
        // guard currentDay == actualDay else {
        //     HapticManager.error()
        //     return
        // }

        HapticManager.success()

        // Show success checkmark animation
        withAnimation {
            showSuccessCheckmark = true
        }

        // Initialize day dictionary if needed
        if taskStatuses[dayKey(currentDay)] == nil {
            taskStatuses[dayKey(currentDay)] = [:]
        }

        taskStatuses[dayKey(currentDay)]?[taskKey(task)] = .done

        // Update task streak
        updateTaskStreak(task)

        // Update global streak
        updateGlobalStreak()

        // Save to Firebase and apply impact scoring
        Task {
            guard let userId = Auth.auth().currentUser?.uid else { return }

            // Determine habit ID from task title
            let habitId = getHabitId(for: task)

            do {
                // Save task status to Firebase
                try await TaskStatusService.shared.saveTaskStatus(
                    day: currentDay,
                    taskTitle: taskKey(task),
                    status: "done"
                )

                // Mark habit completed (for streaks and tracking)
                try await FirebaseManager.shared.markHabitCompleted(uid: userId, habitId: habitId)

                // Apply impact to domain scores
                let updatedScores = try await ImpactScoringService.shared.applyTaskImpact(habitId: habitId)

                // Reload habit tracking data
                let updatedTracking = try await FirebaseManager.shared.fetchAllHabitTracking(uid: userId)
                await MainActor.run {
                    self.habitTracking = updatedTracking
                    // Update global score with rounded average of 5 domains
                    self.globalScore = updatedScores.roundedScores.global

                    // Notify ProfileView to refresh habit progress
                    NotificationCenter.default.post(name: NSNotification.Name("TaskValidated"), object: nil)
                }

                // Check achievements and milestones
                let tasksCompletedToday = taskStatuses[dayKey(currentDay)]?.values.filter { $0 == .done }.count ?? 0
                await achievementService.checkAchievements(
                    taskCompleted: habitId,
                    currentDay: currentDay,
                    currentStreak: globalStreak,
                    tasksCompletedToday: tasksCompletedToday
                )

                // Check milestones
                _ = await achievementService.checkMilestones(currentDay: currentDay)

                // Check habit badges
                let habitProgress = try? await TaskStatusService.shared.calculateHabitProgress()
                if let progress = habitProgress, let stats = progress[habitId] {
                    await habitBadgeService.checkHabitBadges(habitId: habitId, tasksCompleted: stats.completed)
                }
            } catch {
                print("Error saving task validation: \(error)")
            }
        }

        // Trigger confetti animation
        showConfetti = true
        // Reset confetti after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            showConfetti = false
        }
    }

    private func getHabitId(for task: HabitTask) -> String {
        // Map task image names to habit IDs
        switch task.imageName {
        case "habit_sleep", "habit_sleep_wake", "habit_sleep_bed", "habit_sleep_morning", "habit_sleep_evening", "habit_sleep_night":
            return "sleep"
        case "habit_breathe":
            return "breathing"
        case "habit_meditate":
            return "meditation"
        case "habit_water":
            return "water"
        case _ where task.imageName.contains("sport"):
            return "sport"
        case _ where task.imageName.contains("nature"):
            return "nature"
        case _ where task.imageName.contains("social"):
            return "social"
        case "habit_journal":
            return "journal"
        default:
            print("⚠️ Unknown habit image: \(task.imageName)")
            return "unknown"
        }
    }

    private func skipTask(_ task: HabitTask) {
        // TEMPORARY: Disabled skip restriction for testing
        // TODO: Re-enable this validation check after testing
        // guard currentDay == actualDay else {
        //     HapticManager.error()
        //     return
        // }

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

        // Save skip status to Firebase
        Task {
            do {
                try await TaskStatusService.shared.saveTaskStatus(
                    day: currentDay,
                    taskTitle: taskKey(task),
                    status: "skipped"
                )
            } catch {
                print("Error saving skip status: \(error)")
            }
        }
    }
}

// MARK: - Future Week Blocking View
struct FutureWeekBlockingView: View {
    let currentWeek: Int
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.8)
                .ignoresSafeArea()
                .onTapGesture {
                    HapticManager.light()
                    onDismiss()
                }

            // Card with explanation
            VStack(spacing: 24) {
                // Icon
                Image(systemName: "lock.fill")
                    .font(.system(size: 60))
                    .foregroundColor(Color(hex: "B794F6"))

                // Title
                Text("Semaine \(currentWeek + 1) verrouillée")
                    .font(.custom("HankenGrotesk-Bold", size: 24))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                // Explanation
                VStack(spacing: 12) {
                    Text("Tu es actuellement à la semaine \(currentWeek) de ton programme.")
                        .font(.custom("Poppins-Regular", size: 16))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)

                    Text("Les tâches de la semaine \(currentWeek + 1) se déverrouilleront automatiquement quand tu atteindras cette semaine.")
                        .font(.custom("Poppins-Regular", size: 14))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)

                    Text("Continue ton excellent travail ! 💪")
                        .font(.custom("Poppins-SemiBold", size: 15))
                        .foregroundColor(Color(hex: "B794F6"))
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                }

                // Dismiss button
                Button(action: {
                    HapticManager.medium()
                    onDismiss()
                }) {
                    Text("Compris")
                        .font(.custom("Poppins-SemiBold", size: 16))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(hex: "B794F6"))
                        )
                }
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(hex: "1a0a2e"))
            )
            .padding(.horizontal, 32)
        }
    }
}

#Preview {
    TasksV2View()
}
