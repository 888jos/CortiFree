//
//  OnboardingPlanScreens.swift
//  CortiFree
//
//  The three screens shown right after the analysis, built from the plan that was
//  just generated (PersonalPlanStore): why this plan + starting point, a typical day
//  (the real day 1), and the four weeks of the cycle. Nothing here is a projection.
//

import SwiftUI

// MARK: - Shared pieces

private enum OnboardingPlanStyle {
    static let accent = Color(hex: "B794F6")

    static var titleGradient: LinearGradient {
        LinearGradient(colors: [.white, accent], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    /// Minutes of guided practice in a day (habits have no fixed duration).
    static func practiceMinutes(_ day: PlanDay?) -> Int {
        day?.items.filter { $0.kind != .habit }.reduce(0) { $0 + $1.minutes } ?? 0
    }
}

private struct OnboardingPlanScaffold<Content: View>: View {
    let onBack: (() -> Void)?
    let onContinue: () -> Void
    @ViewBuilder let content: () -> Content

    var body: some View {
        ZStack {
            GalaxyBackgroundView(intensity: 1.0)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    content()
                }
                .padding(.horizontal, 24)
                .padding(.top, 90)
                .padding(.bottom, 130)
            }

            VStack {
                Spacer()
                Button {
                    HapticManager.medium()
                    onContinue()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 18, weight: .semibold))
                        Text("onboarding_v2.common.continue".localized)
                            .font(.custom("Poppins-SemiBold", size: 18))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                }
                .buttonStyle(.glassPrimary)
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .ignoresSafeArea()
        .onboardingBackButton(onBack)
    }
}

private struct OnboardingPlanTitle: View {
    let title: String
    var subtitle: String? = nil
    var accent: Color = OnboardingPlanStyle.accent

    var body: some View {
        VStack(spacing: 10) {
            Text(title)
                .font(.faroBold(28))
                .foregroundStyle(LinearGradient(colors: [.white, accent],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing))
                .multilineTextAlignment(.center)
                .balancedLines()
            if let subtitle {
                Text(subtitle)
                    .font(.custom("Poppins-Regular", size: 15))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .balancedLines()
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 1. Ton plan est prêt

/// The plan picked from the answers, with the other four one swipe (or arrow) away:
/// choosing another plan rebuilds it right away. Below: why this plan (from the answers)
/// and, when the user answered the quiz themself, their starting point per area.
struct OnboardingPlanReadyView: View {
    let plan: PersonalPlan
    var habitsQuizResult: HabitsQuizResult?
    var onBack: (() -> Void)? = nil
    let onContinue: () -> Void

    @ObservedObject private var store = PersonalPlanStore.shared
    @State private var showConfetti = false
    /// The plan the answers picked, kept when the user browses the others.
    @State private var recommended: PlanGoal?
    @State private var selected: PlanGoal?

    private var livePlan: PersonalPlan { store.plan ?? plan }
    private var goals: [PlanGoal] { PlanGoal.allCases }

    /// Up to three reasons, one per theme (two sleep reasons would read as a repeat).
    private var whyLines: [(symbol: String, text: String)] {
        var seen = Set<String>()
        return livePlan.insights.map(PlanInsightText.sentence(for:))
            .filter { seen.insert($0.symbol).inserted }
            .prefix(3)
            .map { $0 }
    }

    /// The user's own quiz scores (0–100, higher is better), only when they answered the quiz
    /// themself: the « my AI answers for me » path has stand-in answers, not data.
    private var startingAreas: [(label: String, score: Int)]? {
        guard let result = habitsQuizResult, result.aiGoal == nil else { return nil }
        return [("serenity", result.serenityScore), ("sleep", result.sleepScore),
                ("energy", result.energyScore), ("focus", result.focusScore),
                ("balance", result.balanceScore)]
            .map { ("paywall_custom.radar_label_\($0.0)".localized, $0.1) }
    }

    var body: some View {
        OnboardingPlanScaffold(onBack: onBack, onContinue: onContinue) {
            VStack(spacing: 8) {
                Text("onboarding_v2.plan_ready.title".localized.uppercased())
                    .font(.custom("Poppins-SemiBold", size: 12))
                    .kerning(1.4)
                    .foregroundColor(livePlan.goal.accentColor)
                OnboardingPlanTitle(title: livePlan.localizedTitle, accent: livePlan.goal.accentColor)
                    .animation(.easeInOut(duration: 0.2), value: livePlan.goal)
            }

            carousel
                .padding(.horizontal, -24)

            HStack(spacing: 8) {
                chip(symbol: "calendar", text: "onboarding_v2.plan_ready.length".localized(PersonalPlan.length))
                chip(symbol: "clock", text: "onboarding_v2.plan_ready.per_day".localized(
                    OnboardingPlanStyle.practiceMinutes(livePlan.day(1))))
            }

            if !whyLines.isEmpty { whyCard }
            if let areas = startingAreas { startingPointCard(areas) }
        }
        // The plan reveal right after the analysis is celebrated (once per appearance).
        .overlay {
            if showConfetti { FullScreenConfetti() }
        }
        .onAppear {
            if recommended == nil {
                recommended = livePlan.goal
                selected = livePlan.goal
            }
            guard !showConfetti else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                showConfetti = true
                HapticManager.success()
            }
        }
        .onChange(of: selected) { _, goal in choose(goal) }
    }

    // MARK: Plans carousel

    private var carousel: some View {
        VStack(spacing: 12) {
            GeometryReader { geometry in
            // The centered card takes 64 % of the width; the neighbours peek out on each side.
            let cardWidth = geometry.size.width * 0.64
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 14) {
                    ForEach(goals) { goal in
                        planCard(goal)
                            .frame(width: cardWidth)
                            .scrollTransition(.interactive, axis: .horizontal) { content, phase in
                                content
                                    .scaleEffect(phase.isIdentity ? 1 : 0.86)
                                    .opacity(phase.isIdentity ? 1 : 0.45)
                            }
                            .id(goal)
                            .onTapGesture { withAnimation(.snappy) { selected = goal } }
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: $selected, anchor: .center)
            .contentMargins(.horizontal, (geometry.size.width - cardWidth) / 2, for: .scrollContent)
            .overlay { arrows }
            }
            .aspectRatio(1 / (0.64 / 0.86), contentMode: .fit)

            // One dot per plan: where the user is among the five.
            HStack(spacing: 6) {
                ForEach(goals) { goal in
                    Capsule()
                        .fill(goal == livePlan.goal ? livePlan.goal.accentColor : .white.opacity(0.22))
                        .frame(width: goal == livePlan.goal ? 18 : 6, height: 6)
                }
            }
            .animation(.snappy, value: livePlan.goal)
        }
    }

    private func planCard(_ goal: PlanGoal) -> some View {
        Image(goal.artworkName)
            .resizable()
            .scaledToFill()
            .frame(maxWidth: .infinity)
            .aspectRatio(0.86, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            .overlay(alignment: .bottomLeading) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(goal.localizedName)
                        .font(.custom("Poppins-SemiBold", size: 15))
                        .foregroundColor(.white)
                    Text(goal.localizedPromise)
                        .font(.custom("Poppins-Regular", size: 11))
                        .foregroundColor(.white.opacity(0.85))
                        .lineLimit(2)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    LinearGradient(colors: [.clear, .black.opacity(0.65)], startPoint: .top, endPoint: .bottom),
                    in: UnevenRoundedRectangle(bottomLeadingRadius: 26, bottomTrailingRadius: 26, style: .continuous)
                )
            }
            .overlay(alignment: .topLeading) {
                if goal == recommended {
                    Label("onboarding_v2.plan_ready.recommended".localized, systemImage: "sparkles")
                        .font(.custom("Poppins-SemiBold", size: 11))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(goal.accentDeep, in: Capsule())
                        .padding(12)
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .strokeBorder(goal == livePlan.goal ? goal.accentColor : .white.opacity(0.12),
                                  lineWidth: goal == livePlan.goal ? 2 : 1)
            }
            .accessibilityLabel(goal.localizedPlanTitle)
    }

    private var arrows: some View {
        let index = goals.firstIndex(of: selected ?? livePlan.goal) ?? 0
        return HStack {
            arrowButton("chevron.left", label: "onboarding_v2.plan_ready.prev_plan", enabled: index > 0) { step(index - 1) }
            Spacer()
            arrowButton("chevron.right", label: "onboarding_v2.plan_ready.next_plan", enabled: index < goals.count - 1) { step(index + 1) }
        }
        .padding(.horizontal, 14)
    }

    private func arrowButton(_ symbol: String, label: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .glassCircle(interactive: true)
        }
        .buttonStyle(.plain)
        .opacity(enabled ? 1 : 0)
        .disabled(!enabled)
        .accessibilityLabel(label.localized)
    }

    private func step(_ index: Int) {
        guard goals.indices.contains(index) else { return }
        HapticManager.light()
        withAnimation(.snappy) { selected = goals[index] }
    }

    /// The centered plan becomes the user's plan.
    private func choose(_ goal: PlanGoal?) {
        guard let goal, goal != livePlan.goal else { return }
        HapticManager.light()
        if store.regenerate(goal: goal) {
            AnalyticsManager.shared.track(event: "onboarding_plan_switched", properties: [
                "from": livePlan.goal.rawValue, "to": goal.rawValue,
                "recommended": recommended?.rawValue ?? ""
            ])
        }
    }

    // MARK: Why this plan

    private var whyCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("onboarding_v2.plan_ready.why".localized)
                .font(.faroSemiBold(17))
                .foregroundColor(.white)
                .padding(.bottom, 14)
            ForEach(Array(whyLines.enumerated()), id: \.offset) { index, line in
                if index > 0 {
                    Divider().overlay(Color.white.opacity(0.08)).padding(.leading, 48).padding(.vertical, 12)
                }
                HStack(alignment: .top, spacing: 14) {
                    Image(systemName: line.symbol)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(livePlan.goal.accentColor)
                        .frame(width: 34, height: 34)
                        .background(livePlan.goal.accentColor.opacity(0.16), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    Text(line.text)
                        .font(.custom("Poppins-Regular", size: 14))
                        .foregroundColor(.white.opacity(0.9))
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(cornerRadius: 20)
    }

    // MARK: Starting point (real quiz answers only)

    private func startingPointCard(_ areas: [(label: String, score: Int)]) -> some View {
        let lowest = areas.map(\.score).min()
        return VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("onboarding_v2.plan_ready.start_title".localized)
                    .font(.faroSemiBold(17))
                    .foregroundColor(.white)
                Text("onboarding_v2.week_progress.start_note".localized)
                    .font(.custom("Poppins-Regular", size: 12))
                    .foregroundColor(.white.opacity(0.6))
                    .fixedSize(horizontal: false, vertical: true)
            }
            ForEach(Array(areas.enumerated()), id: \.offset) { _, area in
                let isLowest = area.score == lowest
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(area.label)
                            .font(.custom("Poppins-Medium", size: 13))
                            .foregroundColor(.white)
                        Spacer()
                        Text(levelName(area.score))
                            .font(.custom("Poppins-SemiBold", size: 12))
                            .foregroundColor(isLowest ? livePlan.goal.accentColor : .white.opacity(0.6))
                    }
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.white.opacity(0.1))
                            Capsule()
                                .fill(isLowest ? livePlan.goal.accentColor : Color.white.opacity(0.45))
                                .frame(width: max(8, geometry.size.width * CGFloat(area.score) / 100))
                        }
                    }
                    .frame(height: 8)
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(cornerRadius: 20)
    }

    private func levelName(_ score: Int) -> String {
        switch score {
        case ..<40: return "onboarding_v2.plan_ready.level_low".localized
        case ..<70: return "onboarding_v2.plan_ready.level_mid".localized
        default: return "onboarding_v2.plan_ready.level_good".localized
        }
    }

    private func chip(symbol: String, text: String) -> some View {
        Label(text, systemImage: symbol)
            .font(.custom("Poppins-SemiBold", size: 13))
            .foregroundColor(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .glassCapsule()
    }
}

// MARK: - 2. Calendrier des 4 semaines

/// The 28 days as a calendar. Week 1 is open: each day can be tapped to see and edit
/// its content (same edits as the Plan tab). Weeks 2–4 stay locked with the reason why.
struct OnboardingPlanCalendarView: View {
    let plan: PersonalPlan
    var onBack: (() -> Void)? = nil
    let onContinue: () -> Void

    @ObservedObject private var store = PersonalPlanStore.shared
    @State private var selectedDay = 1
    @State private var swapTarget: PlanItem?
    @State private var showAddSheet = false
    @State private var showGoalPicker = false
    @State private var editedCount = 0

    /// Live plan: edits made on this screen show up immediately.
    private var livePlan: PersonalPlan { store.plan ?? plan }
    private var day: PlanDay? { livePlan.day(selectedDay) }
    private var canEdit: Bool { store.isEditable(dayNumber: selectedDay) }

    private var locale: Locale { LanguageManager.shared.currentLanguage.locale }

    private func date(ofDay number: Int) -> Date {
        let start = livePlan.startDay.flatMap(PersonalPlan.date(fromDay:)) ?? Calendar.current.startOfDay(for: livePlan.startDate)
        return Calendar.current.date(byAdding: .day, value: number - 1, to: start) ?? start
    }

    private func format(_ date: Date, _ template: String) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.setLocalizedDateFormatFromTemplate(template)
        return formatter.string(from: date)
    }

    /// Same morning / day / evening order as the Plan tab.
    private var orderedItems: [PlanItem] {
        let slots = PlanDaySlot.allCases
        return (day?.items ?? []).enumerated()
            .sorted {
                (slots.firstIndex(of: PlanDaySlot.slot(for: $0.element)) ?? 0, $0.offset)
                    < (slots.firstIndex(of: PlanDaySlot.slot(for: $1.element)) ?? 0, $1.offset)
            }
            .map(\.element)
    }

    var body: some View {
        OnboardingPlanScaffold(onBack: onBack, onContinue: onContinue) {
            OnboardingPlanTitle(title: "onboarding_v2.plan_calendar.title".localized,
                                subtitle: "onboarding_v2.plan_calendar.subtitle".localized)

            goalChip

            weekCard(week: 1)

            ForEach(2...4, id: \.self) { week in
                weekCard(week: week)
            }

            adaptCard
        }
        .sheet(item: $swapTarget) { item in
            PlanSwapSheet(
                item: item,
                week: 1,
                alternatives: (item.choice == true ? [item] : []) + store.alternatives(dayNumber: selectedDay, itemID: item.id)
            ) { replacement, excludeOld in
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    if store.swapItem(dayNumber: selectedDay, itemID: item.id, with: replacement, excludeOld: excludeOld) { didEdit("swap") }
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            PlanAddSheet(week: 1, suggestions: store.additions(dayNumber: selectedDay)) { item in
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    if store.addItem(item, dayNumber: selectedDay) { didEdit("add") }
                }
            }
        }
        .sheet(isPresented: $showGoalPicker) {
            PlanGoalPickerSheet(currentGoal: livePlan.goal, mode: .change) { goal in
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    if store.regenerate(goal: goal) { didEdit("goal") }
                }
            }
        }
        .onAppear {
            // Open on the first day that can still be edited (today for a new plan).
            selectedDay = min(7, max(1, livePlan.dayIndex()))
        }
    }

    private func didEdit(_ kind: String) {
        HapticManager.success()
        editedCount += 1
        AnalyticsManager.shared.track(event: "onboarding_plan_edited", properties: ["kind": kind, "day": selectedDay])
    }

    // MARK: Goal

    private var goalChip: some View {
        Button {
            HapticManager.light()
            showGoalPicker = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: livePlan.goal.symbol)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 30, height: 30)
                    .background(Circle().fill(LinearGradient(colors: livePlan.goal.colors, startPoint: .topLeading, endPoint: .bottomTrailing)))
                Text(livePlan.localizedTitle)
                    .font(.custom("Poppins-SemiBold", size: 14))
                    .foregroundColor(.white)
                    .lineLimit(1)
                Text("plan.change.button".localized)
                    .font(.custom("Poppins-Regular", size: 12))
                    .foregroundColor(OnboardingPlanStyle.accent)
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(OnboardingPlanStyle.accent)
            }
            .padding(.leading, 6)
            .padding(.trailing, 14)
            .padding(.vertical, 6)
            .glassCapsule()
        }
        .buttonStyle(.plain)
    }

    // MARK: Week card

    private func weekCard(week: Int) -> some View {
        let theme = PlanWeekTheme.forWeek(week)
        let locked = week > 1
        let firstDay = (week - 1) * 7 + 1
        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 10) {
                Text("S\(week)")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(locked ? .white.opacity(0.7) : Color(hex: "1F0140"))
                    .frame(width: 34, height: 26)
                    .background(Capsule().fill(locked ? Color.white.opacity(0.12) : OnboardingPlanStyle.accent))
                Text(theme.localizedTitle)
                    .font(.faroSemiBold(17))
                    .foregroundColor(.white)
                Spacer(minLength: 6)
                if locked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.5))
                }
                Text("\(format(date(ofDay: firstDay), "d MMM")) – \(format(date(ofDay: firstDay + 6), "d MMM"))")
                    .font(.custom("Poppins-Regular", size: 11))
                    .foregroundColor(.white.opacity(0.5))
            }

            HStack(spacing: 6) {
                ForEach(firstDay...(firstDay + 6), id: \.self) { number in
                    dayCell(number, locked: locked)
                }
            }

            if locked {
                VStack(alignment: .leading, spacing: 6) {
                    Text(theme.localizedSubtitle)
                        .font(.custom("Poppins-Regular", size: 13))
                        .foregroundColor(.white.opacity(0.8))
                        .fixedSize(horizontal: false, vertical: true)
                    Label("onboarding_v2.plan_calendar.locked".localized(format(date(ofDay: firstDay), "d MMMM")),
                          systemImage: "sparkles")
                        .font(.custom("Poppins-Regular", size: 12))
                        .foregroundColor(OnboardingPlanStyle.accent.opacity(0.9))
                        .fixedSize(horizontal: false, vertical: true)
                }
            } else {
                dayDetail
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(cornerRadius: 22)
        .opacity(locked ? 0.85 : 1)
    }

    private func dayCell(_ number: Int, locked: Bool) -> some View {
        let isSelected = !locked && number == selectedDay
        let isToday = number == livePlan.dayIndex()
        let itemCount = livePlan.day(number)?.items.count ?? 0
        return Button {
            guard !locked else {
                HapticManager.light()
                return
            }
            HapticManager.light()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) { selectedDay = number }
        } label: {
            VStack(spacing: 4) {
                Text(format(date(ofDay: number), "EEEEE").uppercased())
                    .font(.custom("Poppins-SemiBold", size: 10))
                    .foregroundColor(isSelected ? Color(hex: "1F0140").opacity(0.7) : .white.opacity(0.5))
                if locked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.35))
                        .frame(height: 20)
                } else {
                    Text(format(date(ofDay: number), "d"))
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(isSelected ? Color(hex: "1F0140") : .white)
                        .frame(height: 20)
                }
                HStack(spacing: 2) {
                    ForEach(0..<min(itemCount, 4), id: \.self) { _ in
                        Circle()
                            .fill(isSelected ? Color(hex: "1F0140").opacity(0.6) : OnboardingPlanStyle.accent.opacity(locked ? 0.3 : 0.8))
                            .frame(width: 4, height: 4)
                    }
                }
                .frame(height: 4)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? OnboardingPlanStyle.accent : Color.white.opacity(locked ? 0.04 : 0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isToday && !isSelected ? OnboardingPlanStyle.accent : .clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("plan.day_title".localized(number))
    }

    // MARK: Day detail (week 1)

    private var dayDetail: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text("plan.day_title".localized(selectedDay))
                    .font(.faroSemiBold(16))
                    .foregroundColor(.white)
                Text(format(date(ofDay: selectedDay), "EEEE d MMMM"))
                    .font(.custom("Poppins-Regular", size: 12))
                    .foregroundColor(.white.opacity(0.55))
                Spacer(minLength: 4)
                Label("onboarding_v2.plan_day.total".localized(OnboardingPlanStyle.practiceMinutes(day)), systemImage: "clock")
                    .font(.custom("Poppins-Regular", size: 11))
                    .foregroundColor(.white.opacity(0.6))
                    .labelStyle(.titleOnly)
            }
            .padding(.top, 4)

            VStack(spacing: 0) {
                ForEach(Array(orderedItems.enumerated()), id: \.element.id) { index, item in
                    itemRow(item, isLast: index == orderedItems.count - 1)
                        .transition(.opacity.combined(with: .move(edge: .leading)))
                }
            }
            .id(selectedDay)
            .transition(.opacity)

            if canEdit {
                HStack(spacing: 10) {
                    Button {
                        HapticManager.light()
                        showAddSheet = true
                    } label: {
                        Label("plan.edit.add".localized, systemImage: "plus")
                            .font(.custom("Poppins-SemiBold", size: 13))
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 9)
                            .background(Capsule().fill(Color.white.opacity(0.1)))
                    }
                    .buttonStyle(.plain)
                    .disabled((day?.items.count ?? 0) >= 8)

                    if store.undoSnapshot != nil && editedCount > 0 {
                        Button {
                            HapticManager.light()
                            withAnimation { store.undoLastEdit() }
                        } label: {
                            Label("plan.edit.undo".localized, systemImage: "arrow.uturn.backward")
                                .font(.custom("Poppins-SemiBold", size: 13))
                                .foregroundColor(OnboardingPlanStyle.accent)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.top, 8)

                Text("onboarding_v2.plan_calendar.edit_hint".localized)
                    .font(.custom("Poppins-Regular", size: 11))
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.top, 2)
            }
        }
    }

    private func itemRow(_ item: PlanItem, isLast: Bool) -> some View {
        let display = item.display(week: 1, short: false)
        return HStack(alignment: .center, spacing: 12) {
            Group {
                if let image = display.imageName, UIImage(named: image) != nil {
                    Image(image).resizable().scaledToFill()
                } else {
                    Image(systemName: display.symbol)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(LinearGradient(colors: display.colors, startPoint: .topLeading, endPoint: .bottomTrailing))
                }
            }
            .frame(width: 46, height: 46)
            .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                // « Soir · Rituel du soir » would repeat itself: the evening ritual names its moment.
                Text((item.kind == .evening ? display.kindLabel
                      : "\(PlanDaySlot.slot(for: item).localizedTitle) · \(display.kindLabel)").uppercased())
                    .font(.custom("Poppins-SemiBold", size: 9))
                    .kerning(0.8)
                    .foregroundColor(OnboardingPlanStyle.accent)
                Text(display.title)
                    .font(.custom("Poppins-SemiBold", size: 14))
                    .foregroundColor(.white)
                    .lineLimit(2)
                if let duration = display.durationLabel {
                    Text(duration)
                        .font(.custom("Poppins-Regular", size: 11))
                        .foregroundColor(.white.opacity(0.55))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if canEdit {
                Menu {
                    Button {
                        swapTarget = item
                    } label: {
                        Label("plan.edit.swap".localized, systemImage: "arrow.triangle.2.circlepath")
                    }
                    if (day?.items.count ?? 0) > 1 {
                        Button(role: .destructive) {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                if store.removeItem(dayNumber: selectedDay, itemID: item.id) { didEdit("remove") }
                            }
                        } label: {
                            Label("plan.edit.remove".localized, systemImage: "minus.circle")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white.opacity(0.8))
                        .frame(width: 34, height: 34)
                        .background(Circle().fill(Color.white.opacity(0.08)))
                }
            }
        }
        .padding(.vertical, 10)
        .overlay(alignment: .bottom) {
            if !isLast {
                Rectangle().fill(Color.white.opacity(0.08)).frame(height: 1).padding(.leading, 58)
            }
        }
    }

    // MARK: Adapts

    private var adaptCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("onboarding_v2.plan_weeks.adapts_title".localized)
                .font(.faroSemiBold(17))
                .foregroundColor(.white)
            adaptRow(symbol: "star.fill", text: "onboarding_v2.plan_weeks.adapt_ratings".localized)
            adaptRow(symbol: "bubble.left.and.text.bubble.right.fill", text: "onboarding_v2.plan_weeks.adapt_milo".localized)
            adaptRow(symbol: "chart.line.uptrend.xyaxis", text: "onboarding_v2.plan_weeks.adapt_review".localized)
            adaptRow(symbol: "arrow.triangle.2.circlepath",
                     text: "onboarding_v2.plan_weeks.next_cycle".localized(
                        PlanCycleTheme.anchor.localizedTitle,
                        PlanCycleTheme.autonomy.localizedTitle,
                        PlanCycleTheme.maintenance.localizedTitle))
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(cornerRadius: 20)
    }

    private func adaptRow(symbol: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(OnboardingPlanStyle.accent)
                .frame(width: 22)
            Text(text)
                .font(.custom("Poppins-Regular", size: 14))
                .foregroundColor(.white.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
