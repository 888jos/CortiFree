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

    private struct AnxietyCheckLaunch: Identifiable {
        var id: Int { checkpoint }
        let checkpoint: Int
    }

    private struct HabitSelection: Identifiable {
        var id: String { item.id }
        let item: PlanItem
        let task: HabitTask
    }

    /// Hides the tab bar (and Milo) while scrolling down, like the Home tab.
    @Binding var isScrolling: Bool
    /// True while the plan is in edit mode (hides Milo, which would cover the edit controls).
    @Binding var isEditingPlan: Bool

    @ObservedObject private var store = PersonalPlanStore.shared
    @ObservedObject private var player = GuidedSessionPlayer.shared
    @ObservedObject private var achievementService = AchievementService.shared
    @ObservedObject private var habitBadgeService = HabitBadgeService.shared
    @ObservedObject private var anxietyChecks = AnxietyCheckStore.shared

    @State private var userSettings: UserSettings?
    @State private var habitTracking: [String: HabitTracking] = [:]
    @State private var taskStatuses: [String: [String: TaskStatus]] = [:]
    @State private var viewedPlanDay: Int?
    @State private var globalStreak: Int = 0
    @State private var hasLoadedData = false
    /// False after a failed status load (offline): the streak isn't persisted from partial data.
    @State private var statusesReliable = true

    @State private var isEditing = false
    @State private var swapTarget: PlanItem?
    @State private var showAddSheet = false
    @State private var showUndo = false
    @State private var undoHideTask: Task<Void, Never>?

    @State private var breathingLaunch: BreathingLaunch?
    @State private var habitSelection: HabitSelection?
    @State private var anxietyCheckLaunch: AnxietyCheckLaunch?
    @State private var showWhy = false
    @State private var goalPickerMode: PlanGoalPickerSheet.Mode?

    /// "yyyy-MM-dd" of the day the short mode was enabled (auto-resets the next day).
    @AppStorage("plan.shortModeDay") private var shortModeDay: String = ""
    /// "yyyy-MM-dd" of the last day the streak banner was shown.
    @AppStorage("celebration.streak.lastDay") private var streakCelebratedDay: String = ""

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
                                    isEditing = false
                                }
                            }
                        )

                        if isShowingCurrentDay, let checkpoint = anxietyChecks.dueCheckpoint(for: plan) {
                            PlanAnxietyCheckCard(
                                checkpoint: checkpoint,
                                onStart: { anxietyCheckLaunch = AnxietyCheckLaunch(checkpoint: checkpoint) },
                                onLater: {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { anxietyChecks.snoozeForToday() }
                                }
                            )
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }

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
                recordsSession: !isViewingToday,
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
        .sheet(item: $anxietyCheckLaunch) { launch in
            AnxietyCheckSheet(checkpoint: launch.checkpoint) { result in
                AnalyticsManager.shared.track(event: "anxiety_check_completed", properties: [
                    "checkpoint": launch.checkpoint,
                    "source": result.source.rawValue
                ])
                if launch.checkpoint == 1 { store.applyAnxietyCheck() }
            }
        }
        .sheet(item: $swapTarget) { item in
            PlanSwapSheet(
                item: item,
                week: (displayedDay - 1) / 7 + 1,
                alternatives: store.alternatives(dayNumber: displayedDay, itemID: item.id)
            ) { replacement, excludeOld in
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    if store.swapItem(dayNumber: displayedDay, itemID: item.id, with: replacement, excludeOld: excludeOld) { didEdit() }
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            PlanAddSheet(
                week: (displayedDay - 1) / 7 + 1,
                suggestions: store.additions(dayNumber: displayedDay)
            ) { item in
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    if store.addItem(item, dayNumber: displayedDay) { didEdit() }
                }
            }
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
                    guard store.regenerate(goal: goal) else { return }
                    viewedPlanDay = nil
                    didEdit()
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
                // A GAD-7 taken in the Health app also tunes a day-1 plan.
                if await AnxietyCheckStore.shared.importFromHealth() { store.applyAnxietyCheck() }
            }
        }
        .onDisappear {
            isScrolling = false
            isEditing = false
        }
        .onChange(of: isEditing) { _, editing in isEditingPlan = editing }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ProgramRestarted"))) { _ in
            viewedPlanDay = nil
            Task { await reloadData() }
        }
        // New day while the app stays open (midnight) or on return to the app: show the right day.
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged).receive(on: RunLoop.main)) { _ in
            viewedPlanDay = nil
            Task { await reloadData() }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            Task {
                await store.ensurePlan()
                await reloadData()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .personalPlanDidChange)) { _ in
            syncWidgetCache()
        }
        // Item done elsewhere: plan audio finished (mini player, other tab) or journal written.
        .onReceive(store.$completedItemID.compactMap { $0 }) { itemID in
            store.consumeCompletedItem()
            guard let item = plan?.day(min(todayIndex, PersonalPlan.length))?.items.first(where: { $0.id == itemID }) else { return }
            viewedPlanDay = nil
            markDone(item)
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
                            Button {
                                // nil keeps the user's goal choice and proposes new content for the days ahead.
                                if store.regenerate(goal: nil) { viewedPlanDay = nil; didEdit() }
                            } label: {
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
                if store.isEditable(dayNumber: displayedDay) {
                    Button {
                        HapticManager.light()
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { isEditing.toggle() }
                    } label: {
                        Text((isEditing ? "plan.edit.done" : "plan.edit.button").localized)
                            .font(Font.Poppins.custom(.semiBold, size: 13))
                            .foregroundStyle(isEditing ? PlanPalette.deep : .white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(isEditing ? PlanPalette.accent : .white.opacity(0.12)))
                    }
                    .buttonStyle(.plain)
                    .padding(.leading, 6)
                }
            }

            if showUndo {
                PlanUndoBanner {
                    store.undoLastEdit()
                    withAnimation { showUndo = false }
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            if !isViewingToday && !(plan.isFinished && isShowingCurrentDay) {
                Label("plan.past_day".localized, systemImage: "clock.arrow.circlepath")
                    .font(Font.Poppins.custom(.regular, size: 12))
                    .foregroundStyle(PlanPalette.secondaryText)
            }

            if let nextItem, !isEditing {
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

            if isViewingToday && !(plan.isFinished) && !isEditing {
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

            if isEditing {
                Button {
                    HapticManager.light()
                    showAddSheet = true
                } label: {
                    Label("plan.edit.add".localized, systemImage: "plus")
                        .font(Font.Poppins.custom(.semiBold, size: 15))
                        .foregroundStyle(PlanPalette.accent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .strokeBorder(PlanPalette.accent.opacity(0.45), style: StrokeStyle(lineWidth: 1.5, dash: [6, 5]))
                        )
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
        }
    }

    private func card(_ item: PlanItem, week: Int, short: Bool) -> some View {
        let editable = store.isEditable(dayNumber: displayedDay)
        let canRemove = currentItems.count > 1
        return PlanItemCard(
            item: item,
            display: item.display(week: week, short: short),
            status: status(item),
            isShort: short,
            isEditable: isViewingToday,
            onOpen: { open(item, short: short) },
            onToggleDone: { toggleDone(item) },
            onSkip: { skip(item) },
            isEditing: isEditing,
            onSwap: editable ? { swapTarget = item } : nil,
            onRemove: editable && canRemove ? { removeFromPlan(item) } : nil
        )
    }

    // MARK: - Editing

    private func removeFromPlan(_ item: PlanItem) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            if store.removeItem(dayNumber: displayedDay, itemID: item.id) { didEdit() }
        }
    }

    private func didEdit() {
        HapticManager.success()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { showUndo = true }
        undoHideTask?.cancel()
        undoHideTask = Task {
            try? await Task.sleep(for: .seconds(6))
            guard !Task.isCancelled else { return }
            withAnimation { showUndo = false }
        }
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
            if isViewingToday { store.setPendingAudio(item) }
            // Today's item is credited by markDone when the session finishes.
            PlanPlaybackRouter.play(sessionID: sessionID, recordsSession: !isViewingToday)
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
            completedDays: tracking?.completedDays ?? [],
            planDays: habitPlanDays(for: item)
        )
    }

    private func habitPlanDays(for item: PlanItem) -> [HabitPlanDay] {
        (1...PersonalPlan.length).map { number in
            guard let scheduled = plan?.day(number)?.items.first(where: { $0.kind == .habit && $0.refID == item.refID }) else {
                return .off
            }
            let done = status(scheduled, planDay: number) == .done
            if number < todayIndex { return done ? .done : .missed }
            if number == todayIndex { return done ? .done : .today }
            return .upcoming
        }
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
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            taskStatuses[key, default: [:]][item.statusKey] = .done
        }
        let allDone = currentItems.allSatisfy { status($0) == .done }

        LocalProgressStore.recordCompletion(taskID: item.statusKey, habitID: item.habitID, programDay: day,
                                            durationSeconds: seconds, userID: userID)
        ProgressAnalyticsService.shared.invalidateDashboardCache()
        updateGlobalStreak()
        // Micro (the card's checkbox) is enough for a single item; moments go through the queue.
        // Once a day: undoing then redoing the first item must not celebrate again.
        if isFirstToday && streakCelebratedDay != todayKey {
            streakCelebratedDay = todayKey
            CelebrationCenter.shared.enqueue(.streak(days: globalStreak))
        }
        if allDone {
            let minutes = currentItems.reduce(0) { $0 + $1.resolvedMinutes(short: isShortMode) }
            CelebrationCenter.shared.enqueue(.dayComplete(items: currentItems.count, minutes: minutes))
        }
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
        ProgressAnalyticsService.shared.invalidateDashboardCache()
        // Keep the habit credited if another item of the same habit is still done today.
        let habitStillDone = currentItems.contains { $0.id != item.id && $0.habitID == item.habitID && status($0) == .done }
        updateGlobalStreak()
        syncWidgetCache()

        Task {
            guard let uid = Auth.auth().currentUser?.uid else { return }
            try? await TaskStatusService.shared.saveTaskStatus(day: day, taskTitle: item.statusKey, status: "todo")
            try? await ProgressAnalyticsService.shared.removeTaskCompletion(taskID: item.statusKey, programDay: day)
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
            // Without an account, everything lives on the device: keep the program start date
            // (saved once) and rebuild statuses from the local completions.
            if let saved = UserSettings.loadFromUserDefaults() {
                userSettings = saved
            } else {
                let fresh = UserSettings()
                fresh.saveToUserDefaults()
                userSettings = fresh
            }
            mergeLocalCompletions()
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
            statusesReliable = true
        } catch {
            statusesReliable = false
            #if DEBUG
            print("⚠️ Plan: error loading data: \(error)")
            #endif
            if userSettings == nil { userSettings = UserSettings.loadFromUserDefaults() ?? UserSettings() }
        }
        // Offline / not synced yet: completions saved on this device still count.
        mergeLocalCompletions()
        updateGlobalStreak()
        syncWidgetCache()
    }

    /// Adds this device's completions (LocalProgressStore) for keys the server doesn't know yet.
    /// A status already stored remotely (done / skipped / undone) always wins.
    private func mergeLocalCompletions() {
        let userID = Auth.auth().currentUser?.uid ?? UserPersistence.localUserID
        for completion in LocalProgressStore.load(for: userID) {
            let key = dayKey(completion.programDay)
            if taskStatuses[key]?[completion.taskID] == nil {
                taskStatuses[key, default: [:]][completion.taskID] = .done
            }
        }
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
        // Statuses failed to load: keep the stored streak instead of writing a wrong 0.
        guard statusesReliable else { return }
        StreakService.store(streak)
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
        // The widget shows the plan day ("Day X/28"), like the home card.
        WidgetDataStore.saveTasks(widgetTasks, programDay: min(todayIndex, PersonalPlan.length), startDate: plan.startDate)
    }
}

#Preview {
    TasksV2View(isScrolling: .constant(false), isEditingPlan: .constant(false))
        .environment(\.locale, Locale(identifier: "en"))
}
