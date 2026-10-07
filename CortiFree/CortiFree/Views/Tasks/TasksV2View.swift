//
//  TasksV2View.swift
//  CortiFree
//
//  Plan tab: the user's personalized 28-day plan (PersonalPlanStore).
//  Each day = 1 breathing exercise + 1 guided audio session (+ short version)
//  + 2–3 goal-weighted habits (+ evening wind-down for sleep goals).
//
//  Completion history stays keyed by the absolute program day (UserSettings.programStartDate)
//  in task_statuses, so streaks and history survive plan changes.
//

import SwiftUI
import FirebaseAuth

struct TasksV2View: View {
    enum TaskStatus {
        case todo
        case done
        case skipped
    }

    private struct BreathingLaunch: Identifiable {
        let id = UUID()
        let item: PlanItem
        let pattern: BreathingPattern
        let minutes: Int
    }

    private struct HabitSelection: Identifiable {
        var id: String { item.id }
        let item: PlanItem
        let task: HabitTask
    }

    /// Hides the tab bar (and Milo) while scrolling down, like the Home tab.
    @Binding var isScrolling: Bool

    @ObservedObject private var store = PersonalPlanStore.shared
    @ObservedObject private var player = GuidedSessionPlayer.shared
    @ObservedObject private var achievementService = AchievementService.shared
    @ObservedObject private var habitBadgeService = HabitBadgeService.shared

    @State private var userSettings: UserSettings?
    @State private var habitTracking: [String: HabitTracking] = [:]
    @State private var taskStatuses: [String: [String: TaskStatus]] = [:]
    @State private var viewedPlanDay: Int?
    @State private var globalStreak: Int = 0
    @State private var hasLoadedData = false

    @State private var breathingLaunch: BreathingLaunch?
    @State private var habitSelection: HabitSelection?
    @State private var showWhy = false
    @State private var goalPickerMode: PlanGoalPickerSheet.Mode?
    @State private var showConfetti = false
    @State private var showSuccessCheckmark = false
    @State private var showFlameAnimation = false
    /// Audio item waiting for the player to finish (marks it done automatically).
    @State private var pendingAudioItem: PlanItem?

    /// "yyyy-MM-dd" of the day the short mode was enabled (auto-resets the next day).
    @AppStorage("plan.shortModeDay") private var shortModeDay: String = ""

    // MARK: - Day math

    private var plan: PersonalPlan? { store.plan }
    private var todayIndex: Int { plan?.dayIndex() ?? 1 }
    private var displayedDay: Int { min(viewedPlanDay ?? todayIndex, PersonalPlan.length) }
    /// True when today's plan day is shown (false once the 28 days are over).
    private var isViewingToday: Bool { displayedDay == todayIndex }
    private var isShowingCurrentDay: Bool { viewedPlanDay == nil || viewedPlanDay == todayIndex }

    /// Absolute program day (history key) for today.
    private var actualAbsoluteDay: Int {
        userSettings?.currentProgramDay ?? UserSettings.loadFromUserDefaults()?.currentProgramDay ?? 1
    }

    private func absoluteDay(forPlanDay day: Int) -> Int {
        max(1, actualAbsoluteDay - (todayIndex - day))
    }

    private var todayKey: String {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }

    private var isShortMode: Bool { shortModeDay == todayKey }

    private var shortBinding: Binding<Bool> {
        Binding(
            get: { isShortMode },
            set: { newValue in
                HapticManager.light()
                shortModeDay = newValue ? todayKey : ""
            }
        )
    }

    private var currentItems: [PlanItem] {
        plan?.day(displayedDay)?.items ?? []
    }

    private func status(_ item: PlanItem, planDay: Int? = nil) -> TaskStatus {
        let day = absoluteDay(forPlanDay: planDay ?? displayedDay)
        return taskStatuses[dayKey(day)]?[item.statusKey] ?? .todo
    }

    private var completedPlanDays: Set<Int> {
        guard plan != nil else { return [] }
        var days = Set<Int>()
        for day in 1...min(todayIndex, PersonalPlan.length) {
            let statuses = taskStatuses[dayKey(absoluteDay(forPlanDay: day))] ?? [:]
            if statuses.values.contains(.done) { days.insert(day) }
        }
        return days
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            PlanBackground(goal: plan?.goal)

            if let plan {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        header(plan)

                        PlanProgressCard(
                            plan: plan,
                            displayedDay: displayedDay,
                            todayIndex: todayIndex,
                            completedDays: completedPlanDays,
                            onSelectDay: { day in
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                    viewedPlanDay = day == todayIndex ? nil : day
                                }
                            }
                        )

                        if plan.isFinished && isShowingCurrentDay {
                            PlanFinishedCard(
                                plan: plan,
                                onContinue: { startNextCycle(goal: nil) },
                                onChangeGoal: { goalPickerMode = .nextCycle }
                            )
                        }

                        daySection(plan)

                        whyButton
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    // Clears the tab bar, the mini player and Milo.
                    .padding(.bottom, player.currentSession == nil ? 150 : 230)
                }
                .scrollIndicators(.hidden)
                .onScrollGeometryChange(for: CGFloat.self) { $0.contentOffset.y } action: { old, new in
                    updateScrolling(old: old, new: new)
                }
                .refreshable { await reloadData() }
            } else {
                VStack(spacing: 14) {
                    ProgressView().tint(.white)
                    Text("plan.loading".localized)
                        .font(Font.Poppins.custom(.regular, size: 14))
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
        }
        .fullScreenCover(item: $breathingLaunch) { launch in
            BreathingDetailFlowView(
                pattern: launch.pattern,
                duration: TimeInterval(max(1, launch.minutes) * 60),
                onComplete: { markDone(launch.item) }
            )
        }
        .fullScreenCover(item: $habitSelection) { selection in
            HabitTaskDetailView(
                task: selection.task,
                onValidate: {
                    markDone(selection.item)
                    habitSelection = nil
                },
                onSkip: {
                    skip(selection.item)
                    habitSelection = nil
                },
                isCurrentDay: isViewingToday
            )
        }
        .sheet(isPresented: $showWhy) {
            if let plan {
                PlanWhySheet(plan: plan, onChangeGoal: { goalPickerMode = .change })
            }
        }
        .sheet(item: Binding(
            get: { goalPickerMode.map { GoalPickerToken(mode: $0) } },
            set: { goalPickerMode = $0?.mode }
        )) { token in
            PlanGoalPickerSheet(currentGoal: plan?.goal, mode: token.mode) { goal in
                if token.mode == .nextCycle {
                    startNextCycle(goal: goal)
                } else {
                    store.regenerate(goal: goal)
                    viewedPlanDay = nil
                    AnalyticsManager.shared.track(event: "plan_goal_changed", properties: ["goal": goal.rawValue])
                }
            }
        }
        .onAppear {
            guard !hasLoadedData else { return }
            hasLoadedData = true
            Task {
                await store.ensurePlan()
                await reloadData()
            }
        }
        .onDisappear { isScrolling = false }
        .onReceive(NotificationCenter.default.publisher(for: .personalPlanDidChange)) { _ in
            syncWidgetCache()
        }
        .onChange(of: player.didFinish) { _, finished in
            guard finished, let item = pendingAudioItem,
                  let current = player.currentSession?.id,
                  current == item.refID || current == item.shortRefID else { return }
            pendingAudioItem = nil
            markDone(item)
        }
        .confetti(isActive: showConfetti)
        .overlay {
            ZStack {
                if achievementService.showAchievementPopup, let achievement = achievementService.newlyUnlockedAchievement {
                    AchievementUnlockView(achievement: achievement) {
                        achievementService.showAchievementPopup = false
                    }
                    .transition(.opacity)
                }
                if showSuccessCheckmark {
                    SuccessCheckmarkView { showSuccessCheckmark = false }
                        .transition(.scale.combined(with: .opacity))
                }
                if showFlameAnimation {
                    FlameStreakAnimation(isShowing: $showFlameAnimation)
                        .transition(.scale.combined(with: .opacity))
                }
                if habitBadgeService.showBadgePopup, let badge = habitBadgeService.newlyUnlockedBadge {
                    BadgeEvolutionView(badge: badge, isPresented: $habitBadgeService.showBadgePopup)
                        .transition(.opacity)
                }
            }
        }
    }

    private struct GoalPickerToken: Identifiable {
        let mode: PlanGoalPickerSheet.Mode
        var id: String { mode == .change ? "change" : "next" }
    }

    // MARK: - Sections

    private func header(_ plan: PersonalPlan) -> some View {
        let theme = PlanWeekTheme.forWeek((displayedDay - 1) / 7 + 1)
        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                HStack(spacing: 5) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(AppConstants.Colors.streakOrange)
                    Text("\(globalStreak)")
                        .font(Font.Poppins.custom(.bold, size: 15))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .planGlassCapsule(interactive: false)
                .accessibilityElement(children: .combine)

                Spacer()

                PlanGlassGroup(spacing: 8) {
                    HStack(spacing: 8) {
                        PlanIconButton(systemName: "sparkles", label: "plan.why.button".localized) { showWhy = true }
                        Menu {
                            Button { goalPickerMode = .change } label: {
                                Label("plan.change.button".localized, systemImage: "target")
                            }
                            Button { store.regenerate(goal: plan.goalChosenByUser ? plan.goal : nil); viewedPlanDay = nil } label: {
                                Label("plan.regenerate".localized, systemImage: "arrow.triangle.2.circlepath")
                            }
                        } label: {
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(width: 42, height: 42)
                                .contentShape(Circle())
                        }
                        .planGlassCapsule()
                        .accessibilityLabel("plan.change.button".localized)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(String(format: "plan.header.week".localized, (displayedDay - 1) / 7 + 1) + " · " + theme.localizedTitle)
                    .font(Font.Poppins.custom(.semiBold, size: 12))
                    .foregroundStyle(PlanPalette.accent)
                    .textCase(.uppercase)
                    .tracking(0.6)
                Text(plan.localizedTitle)
                    .font(.faroBold(32))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                Text(theme.localizedSubtitle)
                    .font(Font.Poppins.custom(.regular, size: 14))
                    .foregroundStyle(PlanPalette.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    @ViewBuilder
    private func daySection(_ plan: PersonalPlan) -> some View {
        let items = currentItems
        let doneCount = items.filter { status($0) == .done }.count
        let week = (displayedDay - 1) / 7 + 1
        let short = isViewingToday && isShortMode
        let nextItem = isViewingToday && !plan.isFinished ? items.first { status($0) == .todo } : nil

        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(isViewingToday ? "plan.today".localized : String(format: "plan.day_title".localized, displayedDay))
                    .font(.faroSemiBold(22))
                    .foregroundStyle(.white)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                Text(String(format: "plan.done_count".localized, doneCount, items.count))
                    .font(Font.Poppins.custom(.medium, size: 13))
                    .foregroundStyle(PlanPalette.secondaryText)
            }

            if !isViewingToday && !(plan.isFinished && isShowingCurrentDay) {
                Label("plan.past_day".localized, systemImage: "clock.arrow.circlepath")
                    .font(Font.Poppins.custom(.regular, size: 12))
                    .foregroundStyle(PlanPalette.secondaryText)
            }

            if let nextItem {
                PlanNextStepCard(
                    item: nextItem,
                    display: nextItem.display(week: week, short: short && nextItem.kind != .evening),
                    onStart: { open(nextItem, short: short && nextItem.kind != .evening) }
                )
            } else if isViewingToday && !items.isEmpty && doneCount == items.count {
                Label("plan.next.all_done".localized, systemImage: "checkmark.seal.fill")
                    .font(Font.Poppins.custom(.semiBold, size: 15))
                    .foregroundStyle(PlanPalette.done)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .planGlass(cornerRadius: 22, tint: PlanPalette.done)
            }

            if isViewingToday && !(plan.isFinished) {
                PlanShortToggle(isOn: shortBinding)
            }

            ForEach(PlanDaySlot.allCases) { slot in
                let slotItems = items.filter { PlanDaySlot.slot(for: $0) == slot }
                if !slotItems.isEmpty {
                    PlanSlotHeader(slot: slot)
                    PlanGlassGroup {
                        VStack(spacing: 10) {
                            ForEach(slotItems) { item in
                                card(item, week: week, short: short && item.kind != .evening)
                            }
                        }
                    }
                }
            }
        }
    }

    private func card(_ item: PlanItem, week: Int, short: Bool) -> some View {
        PlanItemCard(
            item: item,
            display: item.display(week: week, short: short),
            status: status(item),
            isShort: short,
            isEditable: isViewingToday,
            onOpen: { open(item, short: short) },
            onToggleDone: { toggleDone(item) },
            onSkip: { skip(item) }
        )
    }

    private var whyButton: some View {
        Button {
            HapticManager.light()
            showWhy = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(PlanPalette.accent)
                VStack(alignment: .leading, spacing: 2) {
                    Text("plan.why.button".localized)
                        .font(Font.Poppins.custom(.semiBold, size: 15))
                        .foregroundStyle(.white)
                    Text("plan.why.subtitle".localized)
                        .font(Font.Poppins.custom(.regular, size: 12))
                        .foregroundStyle(.white.opacity(0.6))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.4))
            }
            .padding(16)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .planGlass(cornerRadius: 20, interactive: true)
        .padding(.top, 6)
    }

    // MARK: - Scroll

    private func updateScrolling(old: CGFloat, new: CGFloat) {
        let delta = new - old
        if new < 40 {
            if isScrolling { withAnimation(.easeInOut(duration: 0.25)) { isScrolling = false } }
        } else if delta > 6, !isScrolling {
            withAnimation(.easeOut(duration: 0.2)) { isScrolling = true }
        } else if delta < -6, isScrolling {
            withAnimation(.easeInOut(duration: 0.25)) { isScrolling = false }
        }
    }

    // MARK: - Actions

    private func open(_ item: PlanItem, short: Bool) {
        switch item.kind {
        case .breathing:
            breathingLaunch = BreathingLaunch(item: item, pattern: item.breathingPattern(short: short), minutes: item.resolvedMinutes(short: short))
        case .audio, .evening:
            let sessionID = item.resolvedRefID(short: short)
            if isViewingToday { pendingAudioItem = item }
            PlanPlaybackRouter.play(sessionID: sessionID)
        case .habit:
            habitSelection = HabitSelection(item: item, task: habitTask(for: item))
        }
        AnalyticsManager.shared.track(event: "plan_item_opened", properties: [
            "kind": item.kind.rawValue, "ref": item.resolvedRefID(short: short), "plan_day": displayedDay, "short": short
        ])
    }

    private func habitTask(for item: PlanItem) -> HabitTask {
        let week = (displayedDay - 1) / 7 + 1
        let info = item.habitVariantInfo(week: week)
        let tracking = habitTracking[item.refID]
        return HabitTask(
            title: info.title,
            frequency: "",
            duration: "",
            frequencyText: "frequency.daily".localized,
            difficulty: AppConstants.Habits.Difficulty.easy,
            streak: tracking?.currentStreak ?? 0,
            imageName: info.imageName,
            totalCompletions: tracking?.totalCompletions ?? 0,
            last7Days: tracking?.last7Days ?? Array(repeating: false, count: 7),
            completedDays: tracking?.completedDays ?? []
        )
    }

    private func toggleDone(_ item: PlanItem) {
        if status(item) == .done { undo(item) } else { markDone(item) }
    }

    private func markDone(_ item: PlanItem) {
        guard isViewingToday, status(item) != .done else { return }
        let day = absoluteDay(forPlanDay: displayedDay)
        let key = dayKey(day)
        let isFirstToday = !(taskStatuses[key]?.values.contains(.done) ?? false)
        let seconds = item.resolvedMinutes(short: isShortMode) * 60
        let userID = Auth.auth().currentUser?.uid ?? UserPersistence.localUserID

        HapticManager.success()
        taskStatuses[key, default: [:]][item.statusKey] = .done
        withAnimation { showSuccessCheckmark = true }
        if isFirstToday { showFlameAnimation = true }
        let allDone = currentItems.allSatisfy { status($0) == .done }
        if allDone {
            showConfetti = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { showConfetti = false }
        }

        LocalProgressStore.recordCompletion(taskID: item.statusKey, habitID: item.habitID, programDay: day,
                                            durationSeconds: seconds, userID: userID)
        updateGlobalStreak()
        syncWidgetCache()
        AnalyticsManager.shared.track(event: "plan_item_completed", properties: [
            "kind": item.kind.rawValue, "habit": item.habitID, "plan_day": displayedDay, "goal": plan?.goal.rawValue ?? ""
        ])

        let tasksDoneToday = taskStatuses[key]?.values.filter { $0 == .done }.count ?? 0
        let streak = globalStreak
        Task {
            NotificationCenter.default.post(name: NSNotification.Name("TaskValidated"), object: nil)
            if let uid = Auth.auth().currentUser?.uid {
                do {
                    try await TaskStatusService.shared.saveTaskStatus(day: day, taskTitle: item.statusKey, status: "done")
                    try await FirebaseManager.shared.markHabitCompleted(uid: uid, habitId: item.habitID, programDay: day)
                    try? await ProgressAnalyticsService.shared.recordTaskCompletion(
                        taskID: item.statusKey, habitID: item.habitID, programDay: day, durationSeconds: seconds)
                    habitTracking = try await FirebaseManager.shared.fetchAllHabitTracking(uid: uid)
                    await achievementService.checkAchievements(taskCompleted: item.habitID, currentDay: day,
                                                               currentStreak: streak, tasksCompletedToday: tasksDoneToday)
                } catch {
                    #if DEBUG
                    print("⚠️ Plan: error saving completion: \(error)")
                    #endif
                }
            }
            if let stats = (try? await TaskStatusService.shared.calculateHabitProgress())?[item.habitID] {
                await habitBadgeService.checkHabitBadges(habitId: item.habitID, tasksCompleted: stats.completed)
            }
        }
    }

    private func undo(_ item: PlanItem) {
        guard isViewingToday else { return }
        let day = absoluteDay(forPlanDay: displayedDay)
        let key = dayKey(day)
        HapticManager.light()
        taskStatuses[key, default: [:]][item.statusKey] = .todo
        let userID = Auth.auth().currentUser?.uid ?? UserPersistence.localUserID
        LocalProgressStore.removeCompletion(taskID: item.statusKey, programDay: day, userID: userID)
        // Keep the habit credited if another item of the same habit is still done today.
        let habitStillDone = currentItems.contains { $0.id != item.id && $0.habitID == item.habitID && status($0) == .done }
        updateGlobalStreak()
        syncWidgetCache()

        Task {
            guard let uid = Auth.auth().currentUser?.uid else { return }
            try? await TaskStatusService.shared.saveTaskStatus(day: day, taskTitle: item.statusKey, status: "todo")
            if !habitStillDone {
                try? await FirebaseManager.shared.removeHabitCompletion(uid: uid, habitId: item.habitID, programDay: day)
            }
            NotificationCenter.default.post(name: NSNotification.Name("TaskSkippedAfterValidation"), object: nil)
            if let tracking = try? await FirebaseManager.shared.fetchAllHabitTracking(uid: uid) { habitTracking = tracking }
        }
    }

    private func skip(_ item: PlanItem) {
        guard isViewingToday else { return }
        if status(item) == .done { undo(item) }
        let day = absoluteDay(forPlanDay: displayedDay)
        HapticManager.medium()
        taskStatuses[dayKey(day), default: [:]][item.statusKey] = .skipped
        syncWidgetCache()
        Task {
            try? await TaskStatusService.shared.saveTaskStatus(day: day, taskTitle: item.statusKey, status: "skipped")
        }
    }

    private func startNextCycle(goal: PlanGoal?) {
        store.startNextCycle(goal: goal)
        viewedPlanDay = nil
        AnalyticsManager.shared.track(event: "plan_next_cycle", properties: ["goal": (goal ?? plan?.goal)?.rawValue ?? ""])
    }

    // MARK: - Data

    private func reloadData() async {
        guard let uid = Auth.auth().currentUser?.uid else {
            userSettings = UserSettings.loadFromUserDefaults() ?? UserSettings()
            updateGlobalStreak()
            syncWidgetCache()
            return
        }
        do {
            if let settings = try await FirebaseManager.shared.fetchUserSettings(uid: uid) {
                userSettings = settings
            } else {
                let defaults = UserSettings()
                try? await FirebaseManager.shared.saveUserSettings(uid: uid, settings: defaults)
                userSettings = defaults
            }

            var tracking = try await FirebaseManager.shared.fetchAllHabitTracking(uid: uid)
            if tracking.isEmpty {
                try? await FirebaseManager.shared.initializeHabitTracking(uid: uid)
                tracking = (try? await FirebaseManager.shared.fetchAllHabitTracking(uid: uid)) ?? [:]
            }
            habitTracking = tracking

            let statuses = try await TaskStatusService.shared.loadAllTaskStatuses()
            var converted: [String: [String: TaskStatus]] = [:]
            for (day, tasks) in statuses {
                converted[day] = tasks.mapValues { value in
                    switch value {
                    case "done": return .done
                    case "skipped": return .skipped
                    default: return .todo
                    }
                }
            }
            taskStatuses = converted
        } catch {
            #if DEBUG
            print("⚠️ Plan: error loading data: \(error)")
            #endif
            if userSettings == nil { userSettings = UserSettings.loadFromUserDefaults() ?? UserSettings() }
        }
        updateGlobalStreak()
        syncWidgetCache()
    }

    private func dayKey(_ day: Int) -> String { "day_\(day)" }

    /// Consecutive days (absolute program days) with at least one validated item.
    /// A day without validation yet (today) doesn't break the streak.
    private func updateGlobalStreak() {
        var streak = 0
        let today = actualAbsoluteDay
        let todayDone = taskStatuses[dayKey(today)]?.values.contains(.done) ?? false
        var day = todayDone ? today : today - 1
        while day >= 1, taskStatuses[dayKey(day)]?.values.contains(.done) ?? false {
            streak += 1
            day -= 1
        }
        globalStreak = streak
        UserDefaults.standard.set(streak, forKey: "streakDays")
        if streak > UserDefaults.standard.integer(forKey: "bestStreak") {
            UserDefaults.standard.set(streak, forKey: "bestStreak")
        }
        NotificationCenter.default.post(name: NSNotification.Name("StreakUpdated"), object: nil)
    }

    // MARK: - Widget

    private func syncWidgetCache() {
        guard let plan, let day = plan.day(min(todayIndex, PersonalPlan.length)) else { return }
        let statuses = taskStatuses[dayKey(actualAbsoluteDay)] ?? [:]
        let week = day.week
        let widgetTasks = day.items.map { item -> WidgetTask in
            let display = item.display(week: week, short: isShortMode)
            let status = statuses[item.statusKey] ?? .todo
            return WidgetTask(
                id: item.statusKey,
                title: display.title,
                emoji: "",
                sfSymbol: item.kind == .habit ? PlanItem.habitSymbol(item.refID) : (item.kind == .breathing ? "wind" : "headphones"),
                completed: status == .done,
                cancelled: status == .skipped,
                recommendedTime: nil,
                habitId: item.habitID
            )
        }
        WidgetDataStore.saveTasks(widgetTasks, programDay: actualAbsoluteDay)
    }
}

#Preview {
    TasksV2View(isScrolling: .constant(false))
        .environment(\.locale, Locale(identifier: "en"))
}
