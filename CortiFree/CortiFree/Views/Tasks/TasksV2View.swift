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
    @ObservedObject private var achievementService = AchievementService.shared
    @ObservedObject private var habitBadgeService = HabitBadgeService.shared
    @State private var selectedTask: HabitTask?
    @State private var selectedTab: TaskTab = .todos
    @State private var taskStatuses: [String: [String: TaskStatus]] = [:] // [day: [taskTitle: status]]
    @State private var currentDay: Int = 1 // Day 1 to 66
    @State private var showAddTask = false
    @State private var globalScore: Int = AppConstants.Program.defaultInitialScore // Current global score (average of 5 domains, rounded)
    @State private var initialGlobalScore: Int = AppConstants.Program.defaultInitialScore // Initial score from onboarding
    @State private var taskStreaks: [String: Int] = [:] // Track individual task streaks
    @State private var globalStreak: Int = 0 // Global streak (consecutive days with at least 1 task validated)
    @State private var showConfetti: Bool = false // Confetti animation trigger
    @State private var showSuccessCheckmark: Bool = false // Success checkmark animation trigger
    @State private var isRefreshing: Bool = false // Pull to refresh state
    @State private var showFutureWeekAlert: Bool = false // Show blocking screen for future weeks

    // Undo functionality for skip action
    @State private var showUndoToast: Bool = false
    @State private var skippedTask: HabitTask?
    @State private var undoWorkItem: DispatchWorkItem?

    // Firebase data
    @State private var userSettings: UserSettings?
    @State private var habitTracking: [String: HabitTracking] = [:]
    @State private var isLoadingData: Bool = true
    @State private var loadingError: String? = nil

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

        // 1. SE LEVER (matin) - titre dynamique selon la semaine
        let sleepVariants = HabitVariantConfig.getSleepVariants(forDay: currentDay)

        // Ajouter "Se lever avant 7h"
        if sleepVariants.count > 0 {
            let sleepData = habitTracking[AppConstants.Habits.ID.sleep]
            dailyTasks.append(HabitTask(
                title: sleepVariants[0].title,
                frequency: "", // For compatibility
                duration: "", // Pas de durée pour le sommeil
                frequencyText: StringKeys.Frequency.daily,
                difficulty: AppConstants.Habits.Difficulty.medium,
                streak: sleepData?.currentStreak ?? 0,
                imageName: sleepVariants[0].imageName,
                totalCompletions: sleepData?.totalCompletions ?? 0,
                last7Days: sleepData?.last7Days ?? [false, false, false, false, false, false, false],
                completedDays: sleepData?.completedDays ?? [],
                impactAreas: HabitTask.getImpactAreas(for: "habit_sleep")
            ))
        }

        // 2. RESPIRATION (matin)
        let breathingProgression = WeeklyHabitProgression.breathingProgression(week: week)
        let breathingDuration = WeeklyHabitProgression.formatProgressionDisplay(breathingProgression)
        let breathingVariant = HabitVariantConfig.getBreathingVariant()
        // Afficher seulement certains jours selon fréquence
        let showBreathing = shouldShowTask(dayOfWeek: dayOfWeek, frequencyPerWeek: breathingProgression.frequencyPerWeek)

        if showBreathing {
            let breathingData = habitTracking[AppConstants.Habits.ID.breathing]
            dailyTasks.append(HabitTask(
                title: breathingVariant.title,
                frequency: breathingDuration, // For compatibility
                duration: breathingDuration,
                frequencyText: breathingProgression.formattedFrequency,
                difficulty: AppConstants.Habits.Difficulty.easy,
                streak: breathingData?.currentStreak ?? 0,
                imageName: "habit_breathe",
                totalCompletions: breathingData?.totalCompletions ?? 0,
                last7Days: breathingData?.last7Days ?? [false, false, false, false, false, false, false],
                completedDays: breathingData?.completedDays ?? [],
                impactAreas: HabitTask.getImpactAreas(for: "habit_breathe")
            ))
        }

        // 3. MÉDITATION (matin)
        let meditationProgression = WeeklyHabitProgression.meditationProgression(week: week)
        let meditationDuration = WeeklyHabitProgression.formatProgressionDisplay(meditationProgression)
        let meditationVariant = HabitVariantConfig.getMeditationVariant()
        let showMeditation = shouldShowTask(dayOfWeek: dayOfWeek, frequencyPerWeek: meditationProgression.frequencyPerWeek)

        if showMeditation {
            let meditationData = habitTracking[AppConstants.Habits.ID.meditation]
            dailyTasks.append(HabitTask(
                title: meditationVariant.title,
                frequency: meditationDuration,
                duration: meditationDuration,
                frequencyText: meditationProgression.formattedFrequency,
                difficulty: AppConstants.Habits.Difficulty.hard,
                streak: meditationData?.currentStreak ?? 0,
                imageName: "habit_meditate",
                totalCompletions: meditationData?.totalCompletions ?? 0,
                last7Days: meditationData?.last7Days ?? [false, false, false, false, false, false, false],
                completedDays: meditationData?.completedDays ?? [],
                impactAreas: HabitTask.getImpactAreas(for: "habit_meditate")
            ))
        }

        // 4. HYDRATATION (toute la journée) - titre dynamique selon la semaine
        let waterVariant = HabitVariantConfig.getWaterVariant(forDay: currentDay)
        let waterData = habitTracking[AppConstants.Habits.ID.water]

        dailyTasks.append(HabitTask(
            title: waterVariant.title,
            frequency: "", // For compatibility
            duration: "", // Pas de durée pour l'eau
            frequencyText: StringKeys.Frequency.daily,
            difficulty: AppConstants.Habits.Difficulty.easy,
            streak: waterData?.currentStreak ?? 0,
            imageName: waterVariant.imageName,
            totalCompletions: waterData?.totalCompletions ?? 0,
            last7Days: waterData?.last7Days ?? [false, false, false, false, false, false, false],
            completedDays: waterData?.completedDays ?? [],
            impactAreas: HabitTask.getImpactAreas(for: "habit_water")
        ))

        // 5. SPORT (journée) - Variante selon le jour
        let sportProgression = WeeklyHabitProgression.sportProgression(week: week)
        let sportDuration = WeeklyHabitProgression.formatProgressionDisplay(sportProgression)
        let showSport = shouldShowTask(dayOfWeek: dayOfWeek, frequencyPerWeek: sportProgression.frequencyPerWeek)

        if showSport, let sportVariant = HabitVariantConfig.variantForDay(currentDay, habitType: AppConstants.Habits.ID.sport) {
            let sportData = habitTracking[AppConstants.Habits.ID.sport]
            dailyTasks.append(HabitTask(
                title: sportVariant.title,
                frequency: sportDuration,
                duration: sportDuration,
                frequencyText: sportProgression.formattedFrequency,
                difficulty: AppConstants.Habits.Difficulty.hard,
                streak: sportData?.currentStreak ?? 0,
                imageName: sportVariant.imageName,
                totalCompletions: sportData?.totalCompletions ?? 0,
                last7Days: sportData?.last7Days ?? [false, false, false, false, false, false, false],
                completedDays: sportData?.completedDays ?? [],
                impactAreas: HabitTask.getImpactAreas(for: "habit_sport")
            ))
        }

        // 6. NATURE (après-midi)
        let natureProgression = WeeklyHabitProgression.natureProgression(week: week)
        let natureDuration = WeeklyHabitProgression.formatProgressionDisplay(natureProgression)
        let showNature = shouldShowTask(dayOfWeek: dayOfWeek, frequencyPerWeek: natureProgression.frequencyPerWeek)

        if showNature, let natureVariant = HabitVariantConfig.variantForDay(currentDay, habitType: AppConstants.Habits.ID.nature) {
            let natureData = habitTracking[AppConstants.Habits.ID.nature]
            dailyTasks.append(HabitTask(
                title: natureVariant.title,
                frequency: natureDuration,
                duration: natureDuration,
                frequencyText: natureProgression.formattedFrequency,
                difficulty: AppConstants.Habits.Difficulty.medium,
                streak: natureData?.currentStreak ?? 0,
                imageName: natureVariant.imageName,
                totalCompletions: natureData?.totalCompletions ?? 0,
                last7Days: natureData?.last7Days ?? [false, false, false, false, false, false, false],
                completedDays: natureData?.completedDays ?? [],
                impactAreas: HabitTask.getImpactAreas(for: "habit_nature")
            ))
        }

        // 7. SOCIAL (soirée)
        let socialProgression = WeeklyHabitProgression.socialProgression(week: week)
        let showSocial = shouldShowTask(dayOfWeek: dayOfWeek, frequencyPerWeek: socialProgression.frequencyPerWeek)

        if showSocial, let socialVariant = HabitVariantConfig.variantForDay(currentDay, habitType: AppConstants.Habits.ID.social) {
            let socialData = habitTracking[AppConstants.Habits.ID.social]
            dailyTasks.append(HabitTask(
                title: socialVariant.title,
                frequency: "", // For compatibility
                duration: "", // Pas de durée pour le social
                frequencyText: socialProgression.formattedFrequency,
                difficulty: AppConstants.Habits.Difficulty.medium,
                streak: socialData?.currentStreak ?? 0,
                imageName: socialVariant.imageName,
                totalCompletions: socialData?.totalCompletions ?? 0,
                last7Days: socialData?.last7Days ?? [false, false, false, false, false, false, false],
                completedDays: socialData?.completedDays ?? [],
                impactAreas: HabitTask.getImpactAreas(for: "habit_social")
            ))
        }

        // 8. JOURNAL (soir)
        let journalProgression = WeeklyHabitProgression.journalProgression(week: week)
        let journalDuration = WeeklyHabitProgression.formatProgressionDisplay(journalProgression)
        let journalVariant = HabitVariantConfig.getJournalVariant()
        let showJournal = shouldShowTask(dayOfWeek: dayOfWeek, frequencyPerWeek: journalProgression.frequencyPerWeek)

        if showJournal {
            let journalData = habitTracking[AppConstants.Habits.ID.journal]
            dailyTasks.append(HabitTask(
                title: journalVariant.title,
                frequency: journalDuration,
                duration: journalDuration,
                frequencyText: journalProgression.formattedFrequency,
                difficulty: AppConstants.Habits.Difficulty.medium,
                streak: journalData?.currentStreak ?? 0,
                imageName: journalVariant.imageName,
                totalCompletions: journalData?.totalCompletions ?? 0,
                last7Days: journalData?.last7Days ?? [false, false, false, false, false, false, false],
                completedDays: journalData?.completedDays ?? [],
                impactAreas: HabitTask.getImpactAreas(for: "habit_journal")
            ))
        }

        // 9. SE COUCHER AVANT 23H (soir)
        if sleepVariants.count > 1 {
            let sleepData = habitTracking[AppConstants.Habits.ID.sleep]
            dailyTasks.append(HabitTask(
                title: sleepVariants[1].title,
                frequency: "", // For compatibility
                duration: "", // Pas de durée pour le sommeil
                frequencyText: StringKeys.Frequency.daily,
                difficulty: AppConstants.Habits.Difficulty.medium,
                streak: sleepData?.currentStreak ?? 0,
                imageName: sleepVariants[1].imageName,
                totalCompletions: sleepData?.totalCompletions ?? 0,
                last7Days: sleepData?.last7Days ?? [false, false, false, false, false, false, false],
                completedDays: sleepData?.completedDays ?? [],
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
                                .font(Font.Poppins.custom(.bold, size: 16))
                                .foregroundColor(.white)
                        }

                        Spacer()

                        // Global Score display
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.white)

                            Text("\(globalScore)")
                                .font(Font.Poppins.custom(.bold, size: 16))
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
                            .font(Font.Poppins.custom(.bold, size: 48))
                            .foregroundColor(.white)

                        Spacer()

                        // Navigation arrows
                        HStack(spacing: 12) {
                            Button(action: {
                                HapticManager.light()
                                if currentDay > 1 {
                                    withAnimation(.easeInOut(duration: AppConstants.Animation.standardDuration)) {
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
                                let currentWeek = WeeklyHabitProgression.currentWeek(for: actualDay)
                                let targetWeek = WeeklyHabitProgression.currentWeek(for: targetDay)

                                // TESTING: Week lock disabled for testing
                                // if targetWeek <= currentWeek {
                                withAnimation(.easeInOut(duration: AppConstants.Animation.standardDuration)) {
                                    currentDay = targetDay
                                }
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
                                    .font(Font.Poppins.custom(.bold, size: 12))
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
                                    .font(Font.Poppins.custom(.bold, size: 12))
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
                                    .font(Font.Poppins.custom(.bold, size: 12))
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
                        if let error = loadingError {
                            // Show error state with retry button
                            VStack(spacing: 24) {
                                Spacer()

                                // Error icon
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(.orange)

                                // Error message
                                VStack(spacing: 8) {
                                    Text("Erreur de chargement")
                                        .font(Font.Poppins.custom(.semiBold, size: 20))
                                        .foregroundColor(.white)

                                    Text(error)
                                        .font(Font.Poppins.custom(.regular, size: 14))
                                        .foregroundColor(.white.opacity(0.7))
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 32)
                                }

                                // Retry button
                                Button(action: {
                                    HapticManager.medium()
                                    loadingError = nil
                                    loadFirebaseData()
                                }) {
                                    Text("Réessayer")
                                        .font(Font.Poppins.custom(.semiBold, size: 16))
                                        .foregroundColor(.black)
                                        .padding(.horizontal, 32)
                                        .padding(.vertical, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: AppConstants.Layout.cornerRadius)
                                                .fill(.white)
                                        )
                                }
                                .minimumTouchTarget()

                                Spacer()
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 100)
                        } else if isLoadingData {
                            // Show skeleton loaders while loading
                            ForEach(0..<5, id: \.self) { index in
                                SkeletonTaskCard()
                                    .cascadeAppear(index: index, totalCount: 5, baseDelay: 0.05)
                            }
                        } else if filteredTasks.isEmpty {
                            // Show empty state when no tasks
                            VStack(spacing: 24) {
                                Spacer()

                                // Empty state icon
                                Image(systemName: selectedTab == .done ? "checkmark.circle" : selectedTab == .skipped ? "xmark.circle" : "tray")
                                    .font(.system(size: 60))
                                    .foregroundColor(.white.opacity(0.3))

                                // Empty state message
                                VStack(spacing: 8) {
                                    Text(emptyStateTitle)
                                        .font(Font.Poppins.custom(.semiBold, size: 18))
                                        .foregroundColor(.white)

                                    Text(emptyStateMessage)
                                        .font(Font.Poppins.custom(.regular, size: 14))
                                        .foregroundColor(.white.opacity(0.6))
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 32)
                                }

                                Spacer()
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 100)
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
                                        skipTaskWithUndo(task)
                                    }
                                )
                                .bouncePress()
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        guard currentDay == actualDay else { return }
                                        HapticManager.medium()
                                        skipTaskWithUndo(task)
                                    } label: {
                                        Label("Passer", systemImage: "xmark.circle")
                                    }
                                    .tint(currentDay == actualDay ? .red : .gray)
                                }
                                .swipeActions(edge: .leading, allowsFullSwipe: currentDay == actualDay) {
                                    Button {
                                        guard currentDay == actualDay else { return }
                                        HapticManager.success()
                                        validateTask(task)
                                    } label: {
                                        Label("Valider", systemImage: "checkmark.circle")
                                    }
                                    .tint(currentDay == actualDay ? .green : .gray)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, AppConstants.Layout.paddingLarge)
                    .padding(.bottom, 100)
                }

                // Undo Toast
                if showUndoToast {
                    UndoToast(
                        message: "Tâche passée",
                        duration: 5.0,
                        undoAction: restoreSkippedTask
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(1000)
                }
            }
        }
        .fullScreenCover(item: $selectedTask) { task in
            // Create task with correct streak (from getTaskStreak, not the stored value)
            let taskWithCorrectStreak = HabitTask(
                title: task.title,
                frequency: task.frequency,
                duration: task.duration,
                frequencyText: task.frequencyText,
                difficulty: task.difficulty,
                streak: getTaskStreak(task),
                imageName: task.imageName,
                totalCompletions: task.totalCompletions,
                last7Days: task.last7Days,
                completedDays: task.completedDays,
                impactAreas: task.impactAreas
            )
            HabitTaskDetailView(
                task: taskWithCorrectStreak,
                onValidate: {
                    validateTask(task)
                    selectedTask = nil
                },
                onSkip: {
                    skipTask(task)
                    selectedTask = nil
                },
                isCurrentDay: currentDay == actualDay
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
            loadingError = nil // Clear any previous error
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
                #if DEBUG
                print("Error loading Firebase data: \(error)")
                #endif
                // Set error state for UI display
                await MainActor.run {
                    self.loadingError = error.localizedDescription
                    // Use default values if Firebase fails
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

    // Empty state properties
    private var emptyStateTitle: String {
        switch selectedTab {
        case .todos:
            return "Aucune tâche à faire"
        case .done:
            return "Aucune tâche complétée"
        case .skipped:
            return "Aucune tâche ignorée"
        }
    }

    private var emptyStateMessage: String {
        switch selectedTab {
        case .todos:
            return "Toutes vos tâches sont complétées ou ignorées pour aujourd'hui"
        case .done:
            return "Complétez des tâches pour les voir ici"
        case .skipped:
            return "Les tâches ignorées apparaîtront ici"
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

        // Save to UserDefaults to sync with other views (AvatarProgressCard, SettingsView)
        UserDefaults.standard.set(streak, forKey: "streakDays")

        // Also update best streak if current streak is higher
        let currentBestStreak = UserDefaults.standard.integer(forKey: "bestStreak")
        if streak > currentBestStreak {
            UserDefaults.standard.set(streak, forKey: "bestStreak")
        }

        // Notify other views to refresh streak display
        NotificationCenter.default.post(name: NSNotification.Name("StreakUpdated"), object: nil)
    }

    private func validateTask(_ task: HabitTask) {
        guard currentDay == actualDay else {
            HapticManager.error()
            return
        }

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

        // Toujours recalculer les streaks normalement
        // Skip = "pas encore fait", donc valider après un skip continue le streak normalement
        updateTaskStreak(task)
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
                try await FirebaseManager.shared.markHabitCompleted(uid: userId, habitId: habitId, programDay: currentDay)

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


                // Check habit badges
                let habitProgress = try? await TaskStatusService.shared.calculateHabitProgress()
                if let progress = habitProgress, let stats = progress[habitId] {
                    await habitBadgeService.checkHabitBadges(habitId: habitId, tasksCompleted: stats.completed)
                }
            } catch {
                #if DEBUG
                print("Error saving task validation: \(error)")
                #endif
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
            #if DEBUG
            print("⚠️ Unknown habit image: \(task.imageName)")
            #endif
            return "unknown"
        }
    }

    private func skipTask(_ task: HabitTask) {
        // Only allow skipping on the current day
        guard currentDay == actualDay else {
            HapticManager.error()
            return
        }

        HapticManager.medium()

        // Check if task was previously validated
        let previousStatus = taskStatuses[dayKey(currentDay)]?[taskKey(task)]
        let wasValidated = previousStatus == .done

        // Initialize day dictionary if needed
        if taskStatuses[dayKey(currentDay)] == nil {
            taskStatuses[dayKey(currentDay)] = [:]
        }

        taskStatuses[dayKey(currentDay)]?[taskKey(task)] = .skipped

        // NE PAS toucher aux streaks - skip = "pas encore fait"
        // Les streaks seront recalculés correctement quand on valide
        // Ou au début du jour suivant si jamais validé

        // Save skip status to Firebase and reverse points if task was previously validated
        Task {
            guard let userId = Auth.auth().currentUser?.uid else { return }
            let habitId = getHabitId(for: task)

            do {
                try await TaskStatusService.shared.saveTaskStatus(
                    day: currentDay,
                    taskTitle: taskKey(task),
                    status: "skipped"
                )

                // If task was previously validated, reverse the impact on scores
                if wasValidated {
                    // Remove habit completion from tracking
                    try await FirebaseManager.shared.removeHabitCompletion(uid: userId, habitId: habitId, programDay: currentDay)

                    // Reverse the impact on domain scores (negative impact)
                    let updatedScores = try await ImpactScoringService.shared.reverseTaskImpact(habitId: habitId)

                    // Reload habit tracking data
                    let updatedTracking = try await FirebaseManager.shared.fetchAllHabitTracking(uid: userId)
                    await MainActor.run {
                        self.habitTracking = updatedTracking
                        // Update global score with reversed scores
                        self.globalScore = updatedScores.roundedScores.global

                        // Notify ProfileView to refresh habit progress
                        NotificationCenter.default.post(name: NSNotification.Name("TaskSkippedAfterValidation"), object: nil)
                    }
                }
            } catch {
                #if DEBUG
                print("Error saving skip status: \(error)")
                #endif
            }
        }
    }

    private func skipTaskWithUndo(_ task: HabitTask) {
        HapticManager.medium()

        // Cancel any pending permanent skip
        undoWorkItem?.cancel()

        // Store the task for potential restoration
        skippedTask = task

        // Soft skip (mark as skipped but keep reference)
        skipTask(task)

        // Show undo toast
        withAnimation(.appSpring) {
            showUndoToast = true
        }

        // Schedule permanent skip after 5 seconds
        let workItem = DispatchWorkItem {
            withAnimation(.appSpring) {
                showUndoToast = false
            }
            skippedTask = nil
        }

        undoWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0, execute: workItem)
    }

    private func restoreSkippedTask() {
        HapticManager.light()

        // Cancel permanent skip
        undoWorkItem?.cancel()

        // Restore task if it exists
        if let task = skippedTask {
            // Initialize day dictionary if needed
            if taskStatuses[dayKey(currentDay)] == nil {
                taskStatuses[dayKey(currentDay)] = [:]
            }

            // Set task back to todo status
            taskStatuses[dayKey(currentDay)]?[taskKey(task)] = .todo

            // Recalculate streaks
            updateTaskStreak(task)
            updateGlobalStreak()

            // Save todo status to Firebase
            Task {
                do {
                    try await TaskStatusService.shared.saveTaskStatus(
                        day: currentDay,
                        taskTitle: taskKey(task),
                        status: "todo"
                    )
                } catch {
                    #if DEBUG
                    print("Error restoring task status: \(error)")
                    #endif
                }
            }
        }

        // Hide toast
        withAnimation(.appSpring) {
            showUndoToast = false
        }

        skippedTask = nil
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
                    .font(Font.Poppins.custom(.bold, size: 24))
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
