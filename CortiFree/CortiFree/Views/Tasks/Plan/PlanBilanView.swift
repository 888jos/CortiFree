//
//  PlanBilanView.swift
//  CortiFree
//
//  « Ton bilan des 28 jours »: full screen, once per cycle (PlanBilanCenter).
//  1. the day-28 anxiety check if it is missing (30 s), 2. the results (anxiety J1 → J14 → J28,
//  sessions, minutes, best streak, habits) with a shareable card, 3. what the next cycle brings.
//

import SwiftUI

struct PlanBilanView: View {
    let request: PlanBilanCenter.Request

    private enum Step { case loading, check, results, next }

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var store = PersonalPlanStore.shared
    @State private var step: Step = .loading
    @State private var stats: PlanCycleStats?
    @State private var done: [Int: Set<String>] = [:]
    @State private var shareImage: Image?
    @State private var showCheck = false
    @State private var showGoalPicker = false
    @State private var selectedGoal: PlanGoal?
    @State private var trackedView = false

    private var plan: PersonalPlan { request.plan }
    private var nextCycle: Int { plan.cycle + 1 }
    private var nextTheme: PlanCycleTheme { .forCycle(nextCycle) }
    private var suggestion: PlanNextCycleSuggestion? {
        stats.map { PlanCycleReview.suggestion(for: $0, secondaryGoal: plan.secondaryGoal) }
    }
    private var nextGoal: PlanGoal { selectedGoal ?? suggestion?.goal ?? plan.goal }
    /// Gentler ramp when suggested for the goal that is kept.
    private var nextGentle: Bool {
        guard let suggestion else { return false }
        return suggestion.gentle && nextGoal == suggestion.goal
    }
    private var acquired: [String] { stats.map(PlanCycleReview.acquiredHabits) ?? [] }

    var body: some View {
        ZStack {
            PlanBackground(goal: plan.goal)
            switch step {
            case .loading:
                ProgressView().tint(.white)
            case .check:
                checkStep.transition(.opacity)
            case .results:
                if let stats { resultsStep(stats).transition(.opacity) }
            case .next:
                nextStep.transition(.opacity)
            }
        }
        .overlay(alignment: .topTrailing) {
            Button {
                HapticManager.light()
                finish(goal: nil, action: "close")
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
            }
            .planGlassCapsule()
            .padding(.trailing, 20)
            .padding(.top, 8)
            .accessibilityLabel("plan.close".localized)
        }
        .animation(.easeInOut(duration: 0.3), value: step)
        .sheet(isPresented: $showCheck) {
            AnxietyCheckSheet(checkpoint: AnxietyCheckStore.checkpoints.last ?? PersonalPlan.length) { result in
                AnalyticsManager.shared.track(event: "anxiety_check_completed", properties: [
                    "checkpoint": PersonalPlan.length, "source": result.source.rawValue, "context": "plan_bilan"
                ])
                recomputeStats()
            }
        }
        .sheet(isPresented: $showGoalPicker) {
            PlanGoalPickerSheet(currentGoal: nextGoal, mode: .nextCycle) { goal in
                selectedGoal = goal
                finish(goal: goal, action: "change_goal")
            }
        }
        .onAppear { PlanBilanCenter.shared.didAppear(request) }
        .task { await load() }
    }

    // MARK: - Steps

    private var checkStep: some View {
        VStack(spacing: 18) {
            Spacer()
            Image(systemName: "waveform.path.ecg")
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(PlanPalette.accent)
            Text("plan.bilan.check.title".localized)
                .font(.faroBold(28))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
            Text("plan.bilan.check.subtitle".localized)
                .font(Font.Poppins.custom(.regular, size: 15))
                .foregroundStyle(PlanPalette.secondaryText)
                .multilineTextAlignment(.center)
            Spacer()
            Button {
                HapticManager.medium()
                showCheck = true
            } label: {
                Text("plan.bilan.check.start".localized)
                    .font(Font.Poppins.custom(.semiBold, size: 16))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .planGlassButtonStyle(prominent: true)
            Button {
                HapticManager.light()
                step = .results
            } label: {
                Text("plan.bilan.check.skip".localized)
                    .font(Font.Poppins.custom(.medium, size: 15))
                    .foregroundStyle(.white.opacity(0.75))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.plain)
        }
        .padding(24)
    }

    private func resultsStep(_ stats: PlanCycleStats) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(String(format: "plan.bilan.kicker".localized, stats.cycle))
                        .font(Font.Poppins.custom(.semiBold, size: 12))
                        .foregroundStyle(PlanPalette.accent)
                        .textCase(.uppercase)
                        .tracking(0.6)
                    Text("plan.bilan.title".localized)
                        .font(.faroBold(32))
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                    Text(String(format: "plan.bilan.subtitle".localized, plan.goal.localizedName))
                        .font(Font.Poppins.custom(.regular, size: 14))
                        .foregroundStyle(PlanPalette.secondaryText)
                }

                PlanBilanAnxietyCard(trend: stats.anxiety)

                LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                    statTile("checkmark.circle.fill", value: "\(stats.sessionsCompleted)", label: "plan.bilan.stat.sessions".localized)
                    statTile("clock.fill", value: "\(stats.minutesPracticed)", label: "plan.bilan.stat.minutes".localized)
                    statTile("flame.fill", value: "\(stats.bestStreak)", label: "plan.bilan.stat.streak".localized)
                    statTile("calendar", value: "\(stats.activeDays)/\(PersonalPlan.length)", label: "plan.bilan.stat.days".localized)
                }

                if let top = PlanBilanText.practiceName(stats.topPractice) {
                    infoRow("sparkles", String(format: "plan.bilan.top_practice".localized, top))
                }

                let keptHabits = stats.habits.filter { $0.done > 0 }.prefix(3)
                if !keptHabits.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("plan.bilan.habits.title".localized)
                            .font(.faroSemiBold(18))
                            .foregroundStyle(.white)
                        ForEach(Array(keptHabits), id: \.habitID) { habit in
                            habitRow(habit)
                        }
                    }
                    .padding(16)
                    .planGlass(cornerRadius: 22)
                }

                if let shareImage {
                    ShareLink(item: shareImage, preview: SharePreview("plan.bilan.title".localized, image: shareImage)) {
                        Label("plan.bilan.share".localized, systemImage: "square.and.arrow.up")
                            .font(Font.Poppins.custom(.semiBold, size: 15))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .planGlass(cornerRadius: 20, interactive: true)
                    .simultaneousGesture(TapGesture().onEnded {
                        AnalyticsManager.shared.track(event: "plan_bilan_shared", properties: analyticsProperties(stats))
                    })
                }

                Button {
                    HapticManager.medium()
                    step = .next
                } label: {
                    Text("plan.bilan.continue".localized)
                        .font(Font.Poppins.custom(.semiBold, size: 16))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .planGlassButtonStyle(prominent: true)
            }
            .padding(.horizontal, 20)
            .padding(.top, 60)
            .padding(.bottom, 40)
        }
        .scrollIndicators(.hidden)
        .onAppear {
            guard !trackedView else { return }
            trackedView = true
            AnalyticsManager.shared.track(event: "plan_bilan_viewed", properties: analyticsProperties(stats))
        }
    }

    private var nextStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            Spacer(minLength: 40)
            Image(systemName: nextTheme.symbol)
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 72, height: 72)
                .background(Circle().fill(LinearGradient(colors: PlanPalette.itemGradient, startPoint: .topLeading, endPoint: .bottomTrailing)))
            Text(String(format: "plan.bilan.next.title".localized, nextCycle, nextTheme.localizedTitle))
                .font(.faroBold(30))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)
            Text(nextTheme.localizedSubtitle)
                .font(Font.Poppins.custom(.regular, size: 15))
                .foregroundStyle(PlanPalette.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
            VStack(alignment: .leading, spacing: 12) {
                ForEach(nextTheme.localizedChanges, id: \.self) { line in
                    infoRow("checkmark", line)
                }
            }
            .padding(16)
            .planGlass(cornerRadius: 22)

            if let suggestion, selectedGoal == nil {
                infoRow(suggestion.goal == plan.goal ? "arrow.triangle.2.circlepath" : "arrow.turn.up.right",
                        String(format: "plan.bilan.suggest.\(suggestion.reason.rawValue)".localized, suggestion.goal.localizedName))
            } else {
                Text(String(format: "plan.bilan.next.goal".localized, nextGoal.localizedName))
                    .font(Font.Poppins.custom(.medium, size: 14))
                    .foregroundStyle(.white.opacity(0.85))
            }
            ForEach(acquired, id: \.self) { habit in
                infoRow("checkmark.seal.fill", String(format: "plan.bilan.acquired.next".localized, "plan.habit.\(habit).name".localized))
            }

            Spacer()

            Button {
                HapticManager.success()
                finish(goal: nextGoal, action: "start")
            } label: {
                Text((request.isCurrentCycle ? "plan.bilan.next.start_tomorrow" : "plan.bilan.next.start").localized)
                    .font(Font.Poppins.custom(.semiBold, size: 16))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .planGlassButtonStyle(prominent: true)
            Button {
                HapticManager.light()
                showGoalPicker = true
            } label: {
                Text("plan.bilan.next.change_goal".localized)
                    .font(Font.Poppins.custom(.medium, size: 15))
                    .foregroundStyle(.white.opacity(0.8))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
    }

    // MARK: - Pieces

    private func statTile(_ symbol: String, value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(PlanPalette.accent)
            Text(value)
                .font(.faroBold(26))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(Font.Poppins.custom(.regular, size: 12))
                .foregroundStyle(PlanPalette.secondaryText)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .planGlass(cornerRadius: 20)
        .accessibilityElement(children: .combine)
    }

    private func infoRow(_ symbol: String, _ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(PlanPalette.accent)
            Text(text)
                .font(Font.Poppins.custom(.regular, size: 14))
                .foregroundStyle(.white.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func habitRow(_ habit: PlanHabitRate) -> some View {
        HStack(spacing: 12) {
            Image(systemName: PlanItem.habitSymbol(habit.habitID))
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(Circle().fill(.white.opacity(0.12)))
            Text("plan.habit.\(habit.habitID).name".localized)
                .font(Font.Poppins.custom(.medium, size: 14))
                .foregroundStyle(.white)
            Spacer()
            if acquired.contains(habit.habitID) {
                Label("plan.bilan.acquired.badge".localized, systemImage: "checkmark.seal.fill")
                    .font(Font.Poppins.custom(.semiBold, size: 11))
                    .foregroundStyle(PlanPalette.deep)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Capsule().fill(PlanPalette.done))
            }
            Text("\(Int((habit.rate * 100).rounded())) %")
                .font(Font.Poppins.custom(.semiBold, size: 14))
                .foregroundStyle(habit.rate >= PlanCycleReview.acquiredThreshold ? PlanPalette.done : .white.opacity(0.75))
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - Data

    private func load() async {
        done = await PlanCompletionLoader.doneKeys(for: plan)
        recomputeStats()
        let missingCheck = stats?.anxiety.end == nil && (!request.isCurrentCycle || plan.dayIndex() >= PersonalPlan.length)
        step = missingCheck ? .check : .results
        if missingCheck { AnalyticsManager.shared.track(event: "plan_bilan_check_offered", properties: ["cycle": plan.cycle]) }
    }

    private func recomputeStats() {
        let computed = PlanCycleReview.stats(plan: plan, done: done, anxietyResults: AnxietyCheckStore.shared.results)
        stats = computed
        shareImage = renderShareImage(computed)
        if step == .check { step = .results }
    }

    private func renderShareImage(_ stats: PlanCycleStats) -> Image? {
        let renderer = ImageRenderer(content: PlanBilanShareCard(stats: stats).frame(width: 360, height: 450))
        renderer.scale = 3
        return renderer.uiImage.map { Image(uiImage: $0) }
    }

    private func analyticsProperties(_ stats: PlanCycleStats) -> [String: Any] {
        [
            "cycle": stats.cycle, "goal": stats.goal.rawValue, "source": request.source,
            "timing": request.isCurrentCycle ? "day_28" : "next_cycle",
            "sessions": stats.sessionsCompleted, "minutes": stats.minutesPracticed,
            "active_days": stats.activeDays, "best_streak": stats.bestStreak,
            "anxiety_change": stats.anxiety.changePercent ?? NSNull(),
            "has_end_check": stats.anxiety.end != nil
        ]
    }

    /// Start / change goal / close. On day 28 the choice is kept for tomorrow; after that the
    /// next cycle already started on its own: a new goal rebuilds it from today.
    private func finish(goal: PlanGoal?, action: String) {
        let gentle = nextGentle
        if let goal {
            if request.isCurrentCycle {
                store.setNextCycleChoice(goal: goal, gentle: gentle)
            } else if let current = store.plan, current.cycle == nextCycle,
                      goal != current.goal || gentle != (current.preferences?.gentler ?? false) {
                store.adjustCurrentCycle(goal: goal, gentle: gentle)
            }
        }
        AnalyticsManager.shared.track(event: "plan_bilan_next_cycle", properties: [
            "action": action, "cycle": nextCycle, "goal": (goal ?? plan.goal).rawValue,
            "goal_changed": goal.map { $0 != plan.goal } ?? false,
            "suggested_goal": suggestion?.goal.rawValue ?? "", "suggestion": suggestion?.reason.rawValue ?? "",
            "followed_suggestion": goal == nil || goal == suggestion?.goal, "gentle": gentle,
            "acquired_habits": acquired.joined(separator: ","),
            "timing": request.isCurrentCycle ? "day_28" : "next_cycle"
        ])
        PlanBilanCenter.shared.request = nil
        dismiss()
    }
}

// MARK: - Anxiety J1 → J14 → J28

struct PlanBilanAnxietyCard: View {
    let trend: PlanAnxietyTrend

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let change = trend.changePercent {
                Text(PlanBilanText.change(change))
                    .font(.faroBold(26))
                    .foregroundStyle(change <= 0 ? PlanPalette.done : .white)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("plan.bilan.anxiety.title".localized)
                    .font(.faroSemiBold(18))
                    .foregroundStyle(.white)
            }
            HStack(spacing: 8) {
                point(1, trend.start)
                arrow
                point(14, trend.middle)
                arrow
                point(28, trend.end)
            }
            Text("plan.bilan.anxiety.footnote".localized)
                .font(Font.Poppins.custom(.regular, size: 11))
                .foregroundStyle(PlanPalette.tertiaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .planGlass(cornerRadius: 24, tint: PlanPalette.accent)
        .accessibilityElement(children: .combine)
    }

    private var arrow: some View {
        Image(systemName: "arrow.right")
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(.white.opacity(0.4))
    }

    private func point(_ day: Int, _ score: Int?) -> some View {
        VStack(spacing: 4) {
            Text(String(format: "plan.bilan.anxiety.day".localized, day))
                .font(Font.Poppins.custom(.medium, size: 11))
                .foregroundStyle(PlanPalette.secondaryText)
            Text(score.map { "\($0)/21" } ?? "–")
                .font(Font.Poppins.custom(.semiBold, size: 16))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Shareable card (rendered to an image)

struct PlanBilanShareCard: View {
    let stats: PlanCycleStats

    var body: some View {
        ZStack {
            LinearGradient(colors: [PlanPalette.deep, PlanPalette.accentDeep.opacity(0.8), PlanPalette.plum],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            VStack(alignment: .leading, spacing: 18) {
                Text("CortiFree")
                    .font(Font.Poppins.custom(.semiBold, size: 14))
                    .foregroundStyle(.white.opacity(0.7))
                Text("plan.bilan.share.title".localized)
                    .font(.faroBold(30))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
                if let change = stats.anxiety.changePercent, change < 0 {
                    Text(PlanBilanText.change(change))
                        .font(.faroBold(36))
                        .foregroundStyle(PlanPalette.done)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                HStack(spacing: 18) {
                    figure("\(stats.sessionsCompleted)", "plan.bilan.stat.sessions".localized)
                    figure("\(stats.minutesPracticed)", "plan.bilan.stat.minutes".localized)
                    figure("\(stats.bestStreak)", "plan.bilan.stat.streak".localized)
                }
            }
            .padding(28)
        }
    }

    private func figure(_ value: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.faroBold(28))
                .foregroundStyle(.white)
            Text(label)
                .font(Font.Poppins.custom(.regular, size: 11))
                .foregroundStyle(.white.opacity(0.7))
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

enum PlanBilanText {
    /// « -32 % de stress ressenti » / « +5 % … ».
    static func change(_ percent: Int) -> String {
        String(format: "plan.bilan.anxiety.change".localized, percent > 0 ? "+\(percent)" : "\(percent)")
    }

    static func practiceName(_ key: String?) -> String? {
        guard let key else { return nil }
        if key == "breathing" { return "plan.item.breathing".localized }
        return AudioSessionCategory(rawValue: key)?.title.localized
    }
}
