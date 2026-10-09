//
//  PersonalPlanStore.swift
//  CortiFree
//
//  Owns the current personalized plan: local Codable cache and Convex mirror,
//  onboarding profile persistence and migration
//  of existing users (built from their stored onboarding answers, starting today).
//

import Foundation
import Combine

@MainActor
final class PersonalPlanStore: ObservableObject {
    static let shared = PersonalPlanStore()

    @Published private(set) var plan: PersonalPlan?
    @Published private(set) var isLoading = false
    /// True while showing a memory-only plan because the cloud plan couldn't be read.
    private var isProvisional = false

    private let defaults = UserDefaults.standard
    /// Last onboarding answers (not per-user: onboarding can happen before sign-in).
    private let onboardingProfileKey = "personalPlan.onboardingProfile.v1"
    private var ensureTask: Task<Void, Never>?
    private var loadedForUser: String = ""

    private init() {
        loadedForUser = userKey
        plan = loadLocalPlan()
        observeAudioCompletion()
        observeJournal()
        #if DEBUG
        // Simulator checks of the end of a cycle: CORTIFREE_DEBUG_PLAN_DAY=29 moves the plan's start
        // date so that today is that plan day (same profile, goal and cycle).
        if let raw = ProcessInfo.processInfo.environment["CORTIFREE_DEBUG_PLAN_DAY"], let day = Int(raw) {
            debugMovePlan(toDay: day)
        }
        #endif
    }

    #if DEBUG
    func debugMovePlan(toDay day: Int) {
        let start = Calendar.current.date(byAdding: .day, value: -(day - 1), to: Calendar.current.startOfDay(for: Date())) ?? Date()
        let profile = plan?.profile ?? storedOnboardingProfile() ?? PlanProfile()
        var moved = PersonalPlanGenerator.generate(profile: profile, overrideGoal: plan?.goalChosenByUser == true ? plan?.goal : nil,
                                                   anxiety: anxiety, startDate: start, cycle: plan?.cycle ?? 1,
                                                   excluded: plan?.excludedRefIDs ?? [], options: plan?.cycleOptions ?? PlanCycleOptions())
        moved.preferences = plan?.preferences
        plan = moved
        saveLocal(moved)
    }
    #endif

    // MARK: - Plan audio completion

    /// A plan audio item started today. Persisted so it is credited even if the user leaves the
    /// Plan tab, resumes from the mini player, or the app is relaunched before the end.
    private struct PendingAudio: Codable {
        let itemID: String
        let sessionIDs: [String]
        let day: String
    }

    /// Plan item done outside the Plan tab (audio finished, journal written); the Plan tab marks it
    /// done (even later, when it next appears), then calls consume.
    @Published private(set) var completedItemID: String?
    private let pendingAudioKey = "plan.pendingAudio.v1"
    private var audioFinishObserver: AnyCancellable?

    func setPendingAudio(_ item: PlanItem) {
        let pending = PendingAudio(itemID: item.id, sessionIDs: [item.refID, item.shortRefID].compactMap { $0 },
                                   day: Self.dayString(Date()))
        if let data = try? JSONEncoder().encode(pending) { defaults.set(data, forKey: pendingAudioKey) }
    }

    func consumeCompletedItem() { completedItemID = nil }

    private var journalObserver: NSObjectProtocol?

    /// Writing in the journal validates today's "journal" habit if the plan has one.
    private func observeJournal() {
        journalObserver = NotificationCenter.default.addObserver(forName: .journalEntrySaved, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in
                guard let self, let plan = self.plan, !plan.isFinished,
                      let item = plan.day(plan.dayIndex())?.items.first(where: { $0.kind == .habit && $0.refID == "journal" }) else { return }
                self.completedItemID = item.id
            }
        }
    }

    private func observeAudioCompletion() {
        audioFinishObserver = GuidedSessionPlayer.shared.$didFinish
            .removeDuplicates()
            .filter { $0 }
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.handleAudioFinished() }
    }

    private func handleAudioFinished() {
        guard let data = defaults.data(forKey: pendingAudioKey),
              let pending = try? JSONDecoder().decode(PendingAudio.self, from: data) else { return }
        // Only today's item: a session finished on another day belongs to that day's plan.
        guard pending.day == Self.dayString(Date()) else {
            defaults.removeObject(forKey: pendingAudioKey)
            return
        }
        guard let current = GuidedSessionPlayer.shared.currentSession?.id, pending.sessionIDs.contains(current) else { return }
        defaults.removeObject(forKey: pendingAudioKey)
        completedItemID = pending.itemID
    }

    private static func dayString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private var userKey: String { Auth.auth().currentUser?.uid ?? UserPersistence.localUserID }
    private var planKey: String { "personalPlan.current.v1.\(userKey)" }

    // MARK: - Public API

    /// Today's plan day (1...28, can exceed 28 when the plan is finished).
    var todayIndex: Int { plan?.dayIndex() ?? 1 }

    /// Loads (or creates) the plan. Safe to call repeatedly; never throws.
    func ensurePlan() async {
        // Account switch: reload the cache for the signed-in user.
        if loadedForUser != userKey {
            loadedForUser = userKey
            plan = loadLocalPlan()
        }
        if plan == nil { plan = loadLocalPlan() }
        if plan != nil && !isProvisional {
            await autoContinueIfNeeded()
            return
        }

        if let ensureTask { await ensureTask.value; return }
        let task = Task { [weak self] in
            guard let self else { return }
            self.isLoading = true
            defer { self.isLoading = false }

            switch await self.fetchRemotePlan() {
            case .found(let remote):
                self.isProvisional = false
                self.plan = remote
                self.saveLocal(remote)
            case .absent:
                self.isProvisional = false
                let profile = await self.bestAvailableProfile()
                self.apply(PersonalPlanGenerator.generate(profile: profile, anxiety: self.anxiety, startDate: Date()))
            case .unavailable:
                // Offline or unreadable: never overwrite the cloud plan. Show a temporary plan
                // (memory only) and try the remote again on the next ensurePlan().
                guard self.plan == nil else { return }
                let profile = await self.bestAvailableProfile()
                self.isProvisional = true
                self.plan = PersonalPlanGenerator.generate(profile: profile, anxiety: self.anxiety, startDate: Date())
            }
        }
        ensureTask = task
        await task.value
        ensureTask = nil
        await autoContinueIfNeeded()
    }

    /// Called at the end of onboarding with the user's answers.
    func createPlanFromOnboarding(_ profile: PlanProfile) {
        var profile = profile
        profile.source = "onboarding"
        saveOnboardingProfile(profile)
        let newPlan = PersonalPlanGenerator.generate(profile: profile, anxiety: anxiety, startDate: Date())
        apply(newPlan)
    }

    /// Change goal (nil = keep the current goal choice and just rebuild). Past days and the
    /// day count are kept: only today and the days ahead are rebuilt.
    /// Returns false when nothing changed (no plan day left to rebuild).
    @discardableResult
    func regenerate(goal: PlanGoal?, source: PlanEditSource = .user, reason: String? = nil) -> Bool {
        guard let old = plan else {
            let profile = storedOnboardingProfile() ?? PlanProfile()
            apply(PersonalPlanGenerator.generate(profile: profile, overrideGoal: goal, anxiety: anxiety, startDate: Date()))
            return true
        }
        let today = old.dayIndex()
        guard today <= PersonalPlan.length, isEditable(dayNumber: today) else { return false }
        let override = goal ?? (old.goalChosenByUser ? old.goal : nil)
        // A plain "rebuild" must propose something new: vary the seed with each rebuild.
        let variation = goal == nil ? (old.edits ?? []).filter { $0.kind == .regenerate }.count + 1 : 0
        var rebuilt = PersonalPlanGenerator.generate(profile: old.profile, overrideGoal: override, anxiety: anxiety,
                                                     startDate: old.startDate, cycle: old.cycle, excluded: old.excludedRefIDs,
                                                     variation: variation, options: old.cycleOptions)
        rebuilt.days = old.days.filter { $0.dayNumber < today } + rebuilt.days.filter { $0.dayNumber >= today }
        rebuilt.preferences = old.preferences
        rebuilt.edits = (old.edits ?? []) + [PlanEdit(
            date: Date(), source: source, kind: goal != nil && goal != old.goal ? .goalChange : .regenerate,
            dayNumber: today, itemID: nil, fromRefID: old.goal.rawValue, toRefID: rebuilt.goal.rawValue, reason: reason
        )]
        rebuilt.updatedAt = Date()
        commitEdit(rebuilt, previous: old)
        return true
    }

    /// "Restart my program" (profile): a fresh plan starting today at day 1, same goal choice.
    /// Completion history is keyed by program day, which restarts at the same time.
    func restartFromDayOne() {
        let profile = plan?.profile ?? storedOnboardingProfile() ?? PlanProfile()
        let override: PlanGoal? = (plan?.goalChosenByUser ?? false) ? plan?.goal : nil
        var fresh = PersonalPlanGenerator.generate(profile: profile, overrideGoal: override, anxiety: anxiety,
                                                   startDate: Date(), cycle: 1, excluded: plan?.excludedRefIDs ?? [],
                                                   options: PlanCycleOptions(retiredHabits: plan?.preferences?.acquiredHabits ?? []))
        fresh.preferences = plan?.preferences
        undoSnapshot = nil
        apply(fresh)
    }

    /// After day 28: start a follow-up cycle with the same or a new goal. `auto` = started by the
    /// app because the user didn't choose (day 29 must never be empty).
    func startNextCycle(goal: PlanGoal?, auto: Bool = false, gentle: Bool = false, acquiredHabits: Set<String> = []) {
        let previous = plan
        let newPlan = nextCyclePlan(goal: goal, startDate: Date(), gentle: gentle, acquiredHabits: acquiredHabits)
        if let previous { savePreviousPlan(previous) }
        clearNextCycleChoice()
        undoSnapshot = nil
        apply(newPlan)
        AnalyticsManager.shared.track(event: "plan_cycle_started", properties: [
            "cycle": newPlan.cycle, "goal": newPlan.goal.rawValue, "auto": auto,
            "goal_changed": previous.map { $0.goal != newPlan.goal } ?? false,
            "theme": newPlan.cycleTheme.rawValue, "gentle": gentle,
            "acquired_habits": acquiredHabits.sorted().joined(separator: ",")
        ])
        let alreadyAcquired = previous?.preferences?.acquiredHabits ?? []
        for habit in acquiredHabits.subtracting(alreadyAcquired).sorted() {
            CelebrationCenter.shared.enqueue(.habitAcquired(habitID: habit))
            AnalyticsManager.shared.track(event: "plan_habit_acquired", properties: ["habit": habit, "cycle": previous?.cycle ?? 1])
        }
    }

    /// The plan the next cycle will be (deterministic: the day-29 notification can name its first session).
    func nextCyclePlan(goal: PlanGoal? = nil, startDate: Date, gentle: Bool = false, acquiredHabits: Set<String> = []) -> PersonalPlan {
        let profile = plan?.profile ?? storedOnboardingProfile() ?? PlanProfile()
        let keepGoal = goal ?? plan?.goal
        let override: PlanGoal? = (plan?.goalChosenByUser ?? false) || goal != nil ? keepGoal : nil
        // Acquired habits accumulate; « avoid » and « gentler » only concern the cycle that follows.
        var preferences = plan?.preferences ?? PlanPreferences()
        preferences.acquiredHabits = (preferences.acquiredHabits ?? []).union(acquiredHabits)
        preferences.previousCycleRefIDs = plan.map(PlanCycleReview.usedRefIDs)
        preferences.gentler = gentle ? true : nil
        var newPlan = PersonalPlanGenerator.generate(profile: profile, overrideGoal: override, anxiety: anxiety, startDate: startDate,
                                                     cycle: (plan?.cycle ?? 1) + 1, excluded: plan?.excludedRefIDs ?? [],
                                                     options: preferences.cycleOptions)
        newPlan.preferences = preferences
        return newPlan
    }

    // MARK: - Cycle continuity

    private var isAutoContinuing = false

    /// Day 29 and later without a new cycle: start it with the same goal (or the one picked at
    /// the cycle review), so there is always something to do today.
    func autoContinueIfNeeded() async {
        guard let current = plan, current.isFinished, !isProvisional, !isAutoContinuing else { return }
        isAutoContinuing = true
        defer { isAutoContinuing = false }
        // The finished cycle decides what changes: acquired habits leave, little progress → gentler.
        let done = await PlanCompletionLoader.doneKeys(for: current)
        guard plan == current, !isProvisional else { return }
        let stats = PlanCycleReview.stats(plan: current, done: done, anxietyResults: AnxietyCheckStore.shared.results)
        let suggestion = PlanCycleReview.suggestion(for: stats, secondaryGoal: current.secondaryGoal)
        let choice = nextCycleChoice(for: current)
        // Without a choice the goal stays the same; the gentler ramp follows the results then.
        startNextCycle(goal: choice?.goal, auto: choice == nil,
                       gentle: choice?.gentle ?? (suggestion.gentle && suggestion.goal == current.goal),
                       acquiredHabits: Set(PlanCycleReview.acquiredHabits(stats)))
    }

    /// Picked at the review once the next cycle already started: rebuilds it from today.
    func adjustCurrentCycle(goal: PlanGoal, gentle: Bool) {
        guard let current = plan else { return }
        if (current.preferences?.gentler ?? false) != gentle {
            var updated = current
            var preferences = current.preferences ?? PlanPreferences()
            preferences.gentler = gentle ? true : nil
            updated.preferences = preferences
            plan = updated
        }
        regenerate(goal: goal, reason: "plan_bilan")
    }

    /// Goal picked at the day-28 review, applied when the cycle ends.
    struct NextCycleChoice: Codable, Equatable {
        let goal: PlanGoal
        let gentle: Bool
        /// Start date of the plan the choice was made for (a choice never leaks to another cycle).
        let planStart: Date
    }

    private var nextChoiceKey: String { "personalPlan.nextCycleChoice.v1.\(userKey)" }
    private var previousPlanKey: String { "personalPlan.previous.v1.\(userKey)" }

    func setNextCycleChoice(goal: PlanGoal, gentle: Bool) {
        guard let plan else { return }
        let choice = NextCycleChoice(goal: goal, gentle: gentle, planStart: plan.startDate)
        if let data = try? JSONEncoder().encode(choice) { defaults.set(data, forKey: nextChoiceKey) }
    }

    func nextCycleChoice(for plan: PersonalPlan) -> NextCycleChoice? {
        guard let data = defaults.data(forKey: nextChoiceKey),
              let choice = try? JSONDecoder().decode(NextCycleChoice.self, from: data),
              choice.planStart == plan.startDate else { return nil }
        return choice
    }

    private func clearNextCycleChoice() { defaults.removeObject(forKey: nextChoiceKey) }

    /// The cycle that ended before the current one (for its review, on this device only).
    var previousPlan: PersonalPlan? {
        guard let data = defaults.data(forKey: previousPlanKey) else { return nil }
        return try? JSONDecoder().decode(PersonalPlan.self, from: data)
    }

    private func savePreviousPlan(_ plan: PersonalPlan) {
        if let data = try? JSONEncoder().encode(plan) { defaults.set(data, forKey: previousPlanKey) }
    }

    /// After the day-1 anxiety check: rebuild today's plan with it (same goal choice and cycle).
    /// Later checks only measure progress; they shape the next cycle.
    func applyAnxietyCheck() {
        guard let plan, plan.dayIndex() == 1 else { return }
        let newPlan = PersonalPlanGenerator.generate(
            profile: plan.profile,
            overrideGoal: plan.goalChosenByUser ? plan.goal : nil,
            anxiety: anxiety,
            startDate: plan.startDate,
            cycle: plan.cycle,
            excluded: plan.excludedRefIDs,
            options: plan.cycleOptions
        )
        var adjusted = newPlan
        adjusted.preferences = plan.preferences
        apply(adjusted)
    }

    /// Latest GAD-7 band, from the on-device history only.
    private var anxiety: AnxietySeverity? { AnxietyCheckStore.shared.currentSeverity }

    // MARK: - Editing

    /// The plan before the last edit, for a one-step undo (in memory only).
    @Published private(set) var undoSnapshot: PersonalPlan?

    /// Days that can still be edited: today and the days ahead.
    func isEditable(dayNumber: Int) -> Bool {
        // A temporary (offline) plan must not be edited: saving it would replace the cloud plan.
        guard let plan, !isProvisional else { return false }
        let today = plan.dayIndex()
        return today <= PersonalPlan.length && dayNumber >= today && dayNumber <= PersonalPlan.length
    }

    /// Replacement candidates for an item (same kind, suited to the goal), best first.
    func alternatives(dayNumber: Int, itemID: String) -> [PlanItem] {
        guard let plan, let item = plan.day(dayNumber)?.items.first(where: { $0.id == itemID }) else { return [] }
        return PersonalPlanGenerator.alternatives(for: item, in: plan, dayNumber: dayNumber, anxiety: anxiety)
    }

    /// Something to add to a day: one suggestion per kind (breathing, guided session, habit).
    func additions(dayNumber: Int) -> [PlanItem] {
        guard let plan, let day = plan.day(dayNumber) else { return [] }
        let probes = [
            PlanItem(id: "breathing", kind: .breathing, refID: "", minutes: 3, shortRefID: nil, shortMinutes: nil, variant: nil),
            PlanItem(id: "meditation", kind: .audio, refID: "", minutes: 5, shortRefID: nil, shortMinutes: nil, variant: nil),
            PlanItem(id: "habit", kind: .habit, refID: "", minutes: 0, shortRefID: nil, shortMinutes: nil, variant: nil)
        ]
        return probes.flatMap { probe in
            PersonalPlanGenerator.alternatives(for: probe, in: plan, dayNumber: day.dayNumber, anxiety: anxiety, limit: 2)
                .map { candidate in
                    PlanItem(id: uniqueID(for: candidate, in: day), kind: candidate.kind, refID: candidate.refID, minutes: candidate.minutes,
                             shortRefID: nil, shortMinutes: nil, variant: candidate.variant)
                }
        }
    }

    /// Replaces one item. `excludeOld` also stops proposing the old content in future rebuilds.
    @discardableResult
    func swapItem(dayNumber: Int, itemID: String, with replacement: PlanItem,
                  source: PlanEditSource = .user, reason: String? = nil, excludeOld: Bool = false) -> Bool {
        guard let old = plan, isEditable(dayNumber: dayNumber), Self.isValid(replacement),
              let dayIndex = old.days.firstIndex(where: { $0.dayNumber == dayNumber }),
              let itemIndex = old.days[dayIndex].items.firstIndex(where: { $0.id == itemID }) else { return false }
        let current = old.days[dayIndex].items[itemIndex]
        guard replacement.kind == current.kind || (current.kind == .evening && replacement.kind == .audio) else { return false }

        var updated = old
        var items = updated.days[dayIndex].items
        // Habits are keyed by habit id; other kinds keep their slot id so completion keys stay stable.
        let id = current.kind == .habit ? "habit_\(replacement.refID)" : current.id
        guard current.kind != .habit || !items.contains(where: { $0.id == id && $0.id != current.id }) else { return false }
        items[itemIndex] = PlanItem(id: id, kind: current.kind, refID: replacement.refID, minutes: replacement.minutes,
                                    shortRefID: replacement.shortRefID, shortMinutes: replacement.shortMinutes, variant: replacement.variant)
        updated.days[dayIndex] = PlanDay(dayNumber: dayNumber, week: old.days[dayIndex].week, items: items)
        if excludeOld { updated.preferences = (old.preferences ?? PlanPreferences()).adding(current.refID) }
        record(&updated, .swap, source: source, day: dayNumber, itemID: current.id, from: current.refID, to: replacement.refID, reason: reason)
        commitEdit(updated, previous: old)
        return true
    }

    /// Removes one item (a day always keeps at least one).
    @discardableResult
    func removeItem(dayNumber: Int, itemID: String, source: PlanEditSource = .user, reason: String? = nil, exclude: Bool = false) -> Bool {
        guard let old = plan, isEditable(dayNumber: dayNumber),
              let dayIndex = old.days.firstIndex(where: { $0.dayNumber == dayNumber }),
              let item = old.days[dayIndex].items.first(where: { $0.id == itemID }),
              old.days[dayIndex].items.count > 1 else { return false }
        var updated = old
        updated.days[dayIndex] = PlanDay(dayNumber: dayNumber, week: old.days[dayIndex].week,
                                         items: old.days[dayIndex].items.filter { $0.id != itemID })
        if exclude { updated.preferences = (old.preferences ?? PlanPreferences()).adding(item.refID) }
        record(&updated, .remove, source: source, day: dayNumber, itemID: itemID, from: item.refID, to: nil, reason: reason)
        commitEdit(updated, previous: old)
        return true
    }

    /// Adds an item to a day (at most 8 items per day).
    @discardableResult
    func addItem(_ item: PlanItem, dayNumber: Int, source: PlanEditSource = .user, reason: String? = nil) -> Bool {
        guard let old = plan, isEditable(dayNumber: dayNumber), Self.isValid(item),
              let dayIndex = old.days.firstIndex(where: { $0.dayNumber == dayNumber }),
              old.days[dayIndex].items.count < 8 else { return false }
        let day = old.days[dayIndex]
        guard !day.items.contains(where: { $0.refID == item.refID && $0.kind == item.kind }) else { return false }
        let added = PlanItem(id: uniqueID(for: item, in: day), kind: item.kind, refID: item.refID, minutes: item.minutes,
                             shortRefID: item.shortRefID, shortMinutes: item.shortMinutes, variant: item.variant)
        var updated = old
        var items = day.items
        // Keep the evening ritual last.
        if let eveningIndex = items.firstIndex(where: { $0.kind == .evening }), added.kind != .evening {
            items.insert(added, at: eveningIndex)
        } else {
            items.append(added)
        }
        updated.days[dayIndex] = PlanDay(dayNumber: dayNumber, week: day.week, items: items)
        record(&updated, .add, source: source, day: dayNumber, itemID: added.id, from: nil, to: added.refID, reason: reason)
        commitEdit(updated, previous: old)
        return true
    }

    /// Restores the plan as it was before the last edit.
    func undoLastEdit() {
        guard let snapshot = undoSnapshot else { return }
        undoSnapshot = nil
        apply(snapshot)
    }

    /// Content ids must exist in the catalogues (protects against stale or invented ids).
    static func isValid(_ item: PlanItem) -> Bool {
        switch item.kind {
        case .breathing: return BreathingPattern.pattern(named: item.refID) != nil
        case .audio, .evening: return GuidedSessionCatalog.session(id: item.refID) != nil
        case .habit: return PersonalPlanGenerator.habitIDs.contains(item.refID)
        }
    }

    /// Item ids double as completion keys: they must be unique in the day and keep a word
    /// TaskStatusService maps to the right habit ("breathing", "meditation", "habit_x").
    private func uniqueID(for item: PlanItem, in day: PlanDay) -> String {
        let base: String
        switch item.kind {
        case .breathing: base = "breathing"
        case .audio: base = "meditation"
        case .evening: base = "meditation_evening"
        case .habit: return "habit_\(item.refID)"
        }
        let existing = Set(day.items.map(\.id))
        guard existing.contains(base) else { return base }
        var n = 2
        while existing.contains("\(base)_\(n)") { n += 1 }
        return "\(base)_\(n)"
    }

    private func record(_ plan: inout PersonalPlan, _ kind: PlanEditKind, source: PlanEditSource, day: Int,
                        itemID: String?, from: String?, to: String?, reason: String?) {
        plan.edits = (plan.edits ?? []) + [PlanEdit(date: Date(), source: source, kind: kind, dayNumber: day,
                                                    itemID: itemID, fromRefID: from, toRefID: to, reason: reason)]
        plan.updatedAt = Date()
    }

    private func commitEdit(_ updated: PersonalPlan, previous: PersonalPlan) {
        undoSnapshot = previous
        apply(updated)
        if let edit = updated.edits?.last {
            AnalyticsManager.shared.track(event: "plan_edited", properties: [
                "kind": edit.kind.rawValue, "source": edit.source.rawValue, "plan_day": edit.dayNumber
            ])
        }
    }

    // MARK: - Onboarding profile

    func saveOnboardingProfile(_ profile: PlanProfile) {
        if let data = try? JSONEncoder().encode(profile) {
            defaults.set(data, forKey: onboardingProfileKey)
        }
    }

    /// Saves onboarding answers as soon as each quiz step is done, so a resumed onboarding
    /// (app killed mid-way: in-memory answers are gone) still builds a personalized plan.
    func updateOnboardingDraft(_ update: (inout PlanProfile) -> Void) {
        var profile = storedOnboardingProfile() ?? PlanProfile()
        update(&profile)
        profile.source = "onboarding"
        saveOnboardingProfile(profile)
    }

    func storedOnboardingProfile() -> PlanProfile? {
        guard let data = defaults.data(forKey: onboardingProfileKey) else { return nil }
        return try? JSONDecoder().decode(PlanProfile.self, from: data)
    }

    // MARK: - Persistence

    private func apply(_ newPlan: PersonalPlan) {
        isProvisional = false
        plan = newPlan
        saveLocal(newPlan)
        Task { await saveRemote(newPlan) }
        NotificationCenter.default.post(name: .personalPlanDidChange, object: nil)
    }

    private func loadLocalPlan() -> PersonalPlan? {
        guard let data = defaults.data(forKey: planKey),
              let decoded = try? JSONDecoder().decode(PersonalPlan.self, from: data),
              decoded.days.count == PersonalPlan.length else { return nil }
        return decoded
    }

    private func saveLocal(_ plan: PersonalPlan) {
        if let data = try? JSONEncoder().encode(plan) {
            defaults.set(data, forKey: planKey)
        }
    }

    private func saveRemote(_ plan: PersonalPlan) async {
        guard Auth.auth().currentUser != nil,
              let data = try? JSONEncoder().encode(plan),
              let json = String(data: data, encoding: .utf8) else { return }
        let doc: [String: Any] = [
            "version": plan.version,
            "goal": plan.goal.rawValue,
            "secondaryGoal": plan.secondaryGoal.rawValue,
            "gentle": plan.gentle,
            "compact": plan.compact,
            "cycle": plan.cycle,
            "lengthDays": PersonalPlan.length,
            "startDate": plan.startDate.timeIntervalSince1970 * 1000,
            "goalChosenByUser": plan.goalChosenByUser,
            "profileSource": plan.profile.source,
            "planJSON": json
        ]
        do {
            let _: String = try await ConvexBackend.shared.call(
                .mutation, path: "plan:saveCurrent", args: doc
            )
        } catch {
            #if DEBUG
            print("⚠️ PersonalPlanStore: remote save failed: \(error.localizedDescription)")
            #endif
        }
    }

    private enum RemotePlanResult {
        case found(PersonalPlan)
        /// Confirmed: no plan stored for this user (or signed out).
        case absent
        /// Network error or a stored plan this version can't read: must not be overwritten.
        case unavailable
    }

    private func fetchRemotePlan() async -> RemotePlanResult {
        guard Auth.auth().currentUser != nil else { return .absent }
        do {
            struct RemotePlan: Decodable { let planJSON: String }
            let remote: RemotePlan? = try await ConvexBackend.shared.call(
                .query, path: "plan:getCurrent"
            )
            guard let remote else { return .absent }
            guard let data = remote.planJSON.data(using: .utf8),
                  let decoded = try? JSONDecoder().decode(PersonalPlan.self, from: data),
                  decoded.days.count == PersonalPlan.length else { return .unavailable }
            return .found(decoded)
        } catch {
            return .unavailable
        }
    }

    // MARK: - Migration (existing users)

    /// Local onboarding answers, else Convex profile/baseline, else empty (→ stress track).
    private func bestAvailableProfile() async -> PlanProfile {
        if let local = storedOnboardingProfile(), !local.isEmpty { return local }
        var profile = PlanProfile()
        profile.genderCode = defaults.string(forKey: "onboarding_gender")

        guard Auth.auth().currentUser != nil else { return profile }
        struct Inputs: Decodable {
            struct Onboarding: Decodable {
                let age: String?
                let genderCode: String?
                let stressReasons: [String]?
                let stressDuration: String?
            }
            let onboarding: Onboarding?
            let quizAnswers: [Int]?
            let primaryGoal: String?
            let availableTime: Int?
        }
        guard let inputs: Inputs = try? await ConvexBackend.shared.call(.query, path: "plan:planInputs") else {
            return profile
        }
        if let user = inputs.onboarding {
            if let reasons = user.stressReasons {
                profile.reasonCodes = reasons.compactMap {
                    PlanLocalizationLookup.code(for: $0, prefix: "onboarding_v2.overall.reason_",
                                                codes: ["sleep", "anxiety", "energy", "focus", "mental", "difficult", "habits"])
                }
            }
            if let duration = user.stressDuration {
                profile.durationCode = PlanLocalizationLookup.code(for: duration, prefix: "onboarding_v2.overall.duration_",
                                                                   codes: ["weeks", "2_6_months", "6_12_months", "1_year_plus", "years"])
            }
            if let age = user.age {
                profile.ageCode = PlanLocalizationLookup.code(for: age, prefix: "onboarding_v2.overall.age_",
                                                              codes: ["under_18", "18_24", "25_34", "35_44", "45_54", "55_plus"])
            }
            if let gender = user.genderCode { profile.genderCode = gender }
        }
        if let answers = inputs.quizAnswers, answers.count >= 8 { profile.quizAnswers = answers }
        profile.improvementGoal = inputs.primaryGoal
        profile.availableMinutes = inputs.availableTime
        profile.source = profile.isEmpty ? "default" : "migrated"
        return profile
    }
}

extension Notification.Name {
    static let personalPlanDidChange = Notification.Name("PersonalPlanDidChange")
}

// MARK: - Reverse localization (stored answers are localized strings)

enum PlanLocalizationLookup {
    private static let bundles: [Bundle] = LanguageManager.Language.allCases.compactMap { lang in
        Bundle.main.path(forResource: lang.rawValue, ofType: "lproj").flatMap(Bundle.init(path:))
    }

    /// Finds the code whose localized string (`prefix + code`, any app language) equals `text`.
    static func code(for text: String, prefix: String, codes: [String]) -> String? {
        let needle = normalize(text)
        for code in codes {
            let key = prefix + code
            for bundle in bundles where normalize(bundle.localizedString(forKey: key, value: nil, table: nil)) == needle {
                return code
            }
        }
        return nil
    }

    /// Maps selected symptom labels (localized) to stable ids ("mental.1", "physical.4"...).
    static func symptomIDs(from labels: Set<String>) -> [String] {
        let groups: [(String, Int)] = [("mental", 6), ("physical", 6), ("social", 5)]
        var ids: [String] = []
        let needles = Set(labels.map(normalize))
        for (group, count) in groups {
            for i in 1...count {
                let key = "symptom_checker.\(group).\(i)"
                let current = normalize(LanguageManager.shared.localizedString(for: key))
                if needles.contains(current) || bundles.contains(where: { needles.contains(normalize($0.localizedString(forKey: key, value: nil, table: nil))) }) {
                    ids.append("\(group).\(i)")
                }
            }
        }
        return ids
    }

    private static func normalize(_ s: String) -> String {
        s.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}

private extension PlanPreferences {
    func adding(_ refID: String) -> PlanPreferences {
        var copy = self
        copy.excludedRefIDs.insert(refID)
        return copy
    }
}
