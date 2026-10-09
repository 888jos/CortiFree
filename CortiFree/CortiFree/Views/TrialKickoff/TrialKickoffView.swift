//
//  TrialKickoffView.swift
//  CortiFree
//
//  First minutes after the trial starts (shown once, full screen, before Home):
//  stress 0-5 → 1 min physiological sigh → stress again with the delta → "First breath"
//  badge (1/7 this week) → the 7 trial days of the personal plan → Milo asks when to
//  remind tomorrow. The goal is to make the user feel an effect right away, so fewer
//  trials get cancelled on day 0/1. Every step is tracked in Amplitude (trial_kickoff_*).
//

import SwiftUI
import UserNotifications

// MARK: - State

enum TrialKickoff {
    private static let pendingKey = "trialKickoffPending"
    private static let doneKey = "trialKickoffDone"

    /// Set when the onboarding ends with an active subscription (trial just started).
    static var isPending: Bool {
        UserDefaults.standard.bool(forKey: pendingKey) && !UserDefaults.standard.bool(forKey: doneKey)
    }

    static func markPending() {
        guard !UserDefaults.standard.bool(forKey: doneKey) else { return }
        UserDefaults.standard.set(true, forKey: pendingKey)
    }

    static func markDone() {
        UserDefaults.standard.set(false, forKey: pendingKey)
        UserDefaults.standard.set(true, forKey: doneKey)
    }

    /// The kickoff's own achievement (unlocked at the end of the breathing).
    static let achievementID = "first_breath"
}

// MARK: - Flow

struct TrialKickoffView: View {
    /// Debug preview: same screens, no analytics, no achievement, no reminder change.
    var isPreview = false
    let onFinish: () -> Void

    private enum Stage: String { case intro, breathing, after, badge, plan, milo }

    @State private var stage: Stage = .intro
    @State private var stressBefore: Int?
    @State private var stressAfter: Int?
    @State private var reminderTime = NotificationService.shared.morningReminderDate
    @State private var startDate = Date()
    @State private var hasFinished = false

    var body: some View {
        ZStack {
            GalaxyBackgroundView(intensity: 0.9)
                .ignoresSafeArea()

            Group {
                switch stage {
                case .intro: introStage
                case .breathing:
                    TrialKickoffBreathingView(isPreview: isPreview, onComplete: finishBreathing)
                case .after: afterStage
                case .badge: badgeStage
                case .plan: planStage
                case .milo: miloStage
                }
            }
            .transition(.asymmetric(insertion: .opacity.combined(with: .move(edge: .trailing)), removal: .opacity))
        }
        .animation(.easeInOut(duration: 0.35), value: stage)
        .onAppear {
            startDate = Date()
            track("trial_kickoff_viewed", ["is_trial": RevenueCatManager.shared.isInTrialPeriod])
        }
    }

    // MARK: Intro (stress before)

    private var introStage: some View {
        VStack(spacing: 0) {
            topBar(showsSkip: true)

            Spacer(minLength: 12)

            LottieView(filename: "sloth_meditate.json", loopMode: .loop)
                .frame(width: 140, height: 140)
                .accessibilityHidden(true)

            Text("trial_kickoff.intro.title".localized)
                .font(.faroBold(30))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .balancedLines()
                .padding(.top, 14)
                .padding(.horizontal, 28)

            Text("trial_kickoff.intro.subtitle".localized)
                .font(.poppinsRegular(16))
                .foregroundStyle(.white.opacity(0.72))
                .multilineTextAlignment(.center)
                .balancedLines()
                .padding(.top, 10)
                .padding(.horizontal, 32)

            Spacer(minLength: 24)

            StressScalePicker(
                question: "trial_kickoff.stress.question_before".localized,
                value: $stressBefore
            )
            .padding(.horizontal, 20)

            Spacer(minLength: 24)

            primaryButton("trial_kickoff.intro.cta".localized, enabled: stressBefore != nil) {
                if let stressBefore { track("trial_kickoff_stress_rated", ["moment": "before", "value": stressBefore]) }
                stage = .breathing
            }
        }
    }

    private func finishBreathing(seconds: Int) {
        if !isPreview {
            ExerciseSessionRecorder.shared.record(
                exerciseID: BreathingPattern.physiologicalSigh.name,
                category: .breathing,
                durationSeconds: seconds,
                source: "trial_kickoff"
            )
        }
        track("trial_kickoff_breathing_completed", ["duration_seconds": seconds])
        stage = .after
    }

    // MARK: After (stress again + delta)

    private var afterStage: some View {
        VStack(spacing: 0) {
            topBar(showsSkip: false)

            Spacer(minLength: 12)

            Text("trial_kickoff.after.title".localized)
                .font(.faroBold(30))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .balancedLines()
                .padding(.horizontal, 28)

            Spacer(minLength: 24)

            StressScalePicker(
                question: "trial_kickoff.stress.question_after".localized,
                value: $stressAfter
            )
            .padding(.horizontal, 20)

            if let delta = stressDelta {
                StressDeltaCard(before: stressBefore ?? 0, after: stressAfter ?? 0, delta: delta)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .transition(.scale(scale: 0.9).combined(with: .opacity))
            }

            Spacer(minLength: 24)

            primaryButton("trial_kickoff.after.cta".localized, enabled: stressAfter != nil) {
                if let stressAfter { track("trial_kickoff_stress_rated", ["moment": "after", "value": stressAfter, "delta": stressDelta ?? 0]) }
                unlockAchievement()
                stage = .badge
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.8), value: stressAfter)
    }

    /// Negative when the stress went down.
    private var stressDelta: Int? {
        guard let stressBefore, let stressAfter else { return nil }
        return stressAfter - stressBefore
    }

    // MARK: Badge (1/7)

    private var badgeStage: some View {
        ZStack(alignment: .bottom) {
            AchievementCelebrationView(achievement: Self.firstBreathAchievement) {
                stage = .plan
            }

            WeekProgressStrip(done: 1, total: 7)
                .padding(.horizontal, 24)
                .padding(.bottom, 28)
        }
    }

    static var firstBreathAchievement: Achievement {
        var achievement = Achievement.allAchievements.first { $0.id == TrialKickoff.achievementID }
            ?? Achievement(id: TrialKickoff.achievementID, titleKey: "achievement.first_breath.title",
                           descriptionKey: "achievement.first_breath.description", icon: "wind",
                           category: .special, requirement: 1)
        achievement.progress = 1
        achievement.unlockedAt = Date()
        return achievement
    }

    private func unlockAchievement() {
        guard !isPreview else { return }
        Task { await AchievementService.shared.unlockFirstBreathAchievement() }
    }

    // MARK: Plan (7 trial days)

    private var planStage: some View {
        VStack(spacing: 0) {
            topBar(showsSkip: false)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Text("trial_kickoff.plan.eyebrow".localized)
                        .font(.poppinsSemiBold(12))
                        .tracking(1.4)
                        .textCase(.uppercase)
                        .foregroundStyle(PlanPalette.accent)

                    Text(planTitle)
                        .font(.faroBold(28))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .balancedLines()
                        .padding(.top, 8)

                    Text("trial_kickoff.plan.subtitle".localized)
                        .font(.poppinsRegular(15))
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .balancedLines()
                        .padding(.top, 8)
                        .padding(.horizontal, 12)

                    VStack(spacing: 10) {
                        ForEach(trialDays) { day in
                            TrialDayRow(day: day)
                        }
                    }
                    .padding(.top, 22)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }

            primaryButton("trial_kickoff.plan.cta".localized, enabled: true) {
                track("trial_kickoff_plan_viewed", ["days": trialDays.count])
                stage = .milo
            }
        }
    }

    private var plan: PersonalPlan? {
        PersonalPlanStore.shared.plan
    }

    private var planTitle: String {
        plan?.goal.localizedPlanTitle ?? "trial_kickoff.plan.title_generic".localized
    }

    private var trialDays: [TrialDay] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let firstDay = plan.map { min(max($0.dayIndex(on: Date()), 1), PersonalPlan.length) } ?? 1
        return (0..<7).map { offset in
            let date = calendar.date(byAdding: .day, value: offset, to: today) ?? today
            let planDay = plan?.day(firstDay + offset)
            if offset == 0 {
                return TrialDay(offset: 0, date: date, title: "trial_kickoff.plan.day1_title".localized,
                                detail: "trial_kickoff.plan.day1_detail".localized, symbol: "wind", isDone: true)
            }
            let item = planDay?.items.first { $0.kind == .audio } ?? planDay?.items.first { $0.kind == .breathing } ?? planDay?.items.first
            let display = item.map { $0.display(week: planDay?.week ?? 1, short: false) }
            let minutes = planDay?.items.reduce(0) { $0 + $1.resolvedMinutes(short: false) } ?? 0
            return TrialDay(
                offset: offset,
                date: date,
                title: display?.title ?? "trial_kickoff.plan.day_generic".localized,
                detail: minutes > 0
                    ? String(format: "trial_kickoff.plan.day_detail".localized, planDay?.items.count ?? 1, minutes)
                    : (display?.kindLabel ?? ""),
                symbol: display?.symbol ?? "sparkles",
                isDone: false
            )
        }
    }

    // MARK: Milo (reminder time)

    private var miloStage: some View {
        VStack(spacing: 0) {
            topBar(showsSkip: false)

            Spacer(minLength: 8)

            HStack(alignment: .top, spacing: 12) {
                Image("cortifree_assistant_avatar")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 52, height: 52)
                    .clipShape(Circle())
                    .overlay(Circle().strokeBorder(.white.opacity(0.25), lineWidth: 1))
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Milo")
                        .font(.poppinsSemiBold(13))
                        .foregroundStyle(PlanPalette.accent)
                    Text(miloMessage)
                        .font(.poppinsRegular(16))
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .planGlass(cornerRadius: 22)
            }
            .padding(.horizontal, 20)

            Text("trial_kickoff.milo.time_label".localized)
                .font(.poppinsMedium(14))
                .foregroundStyle(.white.opacity(0.7))
                .padding(.top, 28)

            DatePicker("", selection: $reminderTime, displayedComponents: .hourAndMinute)
                .datePickerStyle(.wheel)
                .labelsHidden()
                .colorScheme(.dark)
                .frame(maxHeight: 180)

            Spacer(minLength: 12)

            primaryButton("trial_kickoff.milo.cta".localized, enabled: true) {
                saveReminderAndFinish()
            }

            Button("trial_kickoff.milo.later".localized) {
                HapticManager.light()
                finish(reminderSet: false)
            }
            .font(.poppinsMedium(14))
            .foregroundStyle(.white.opacity(0.62))
            .buttonStyle(.plain)
            .padding(.top, 2)
            .padding(.bottom, 20)
        }
    }

    private var miloMessage: String {
        let tomorrow = trialDays.dropFirst().first?.title ?? "trial_kickoff.plan.day_generic".localized
        let name = Self.firstName
        let lead: String
        if let delta = stressDelta, delta < 0 {
            lead = String(format: "trial_kickoff.milo.lead_down".localized, -delta)
        } else {
            lead = "trial_kickoff.milo.lead_neutral".localized
        }
        let greeting = name.isEmpty
            ? "trial_kickoff.milo.greeting".localized
            : String(format: "trial_kickoff.milo.greeting_name".localized, name)
        return "\(greeting) \(lead) " + String(format: "trial_kickoff.milo.tomorrow".localized, tomorrow)
    }

    private static var firstName: String {
        if let displayName = Auth.auth().currentUser?.displayName, !displayName.isEmpty {
            return displayName.components(separatedBy: " ").first ?? displayName
        }
        return UserDefaults.standard.string(forKey: "userFirstName") ?? ""
    }

    private func saveReminderAndFinish() {
        guard !isPreview else { return finish(reminderSet: true) }
        let time = reminderTime
        Task { @MainActor in
            let center = UNUserNotificationCenter.current()
            let settings = await center.notificationSettings()
            var granted = settings.authorizationStatus == .authorized || settings.authorizationStatus == .ephemeral
            if settings.authorizationStatus == .notDetermined || settings.authorizationStatus == .provisional {
                granted = (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
            }
            if granted {
                UserDefaults.standard.set(true, forKey: "notificationsEnabled")
                NotificationService.shared.setMorningReminder(time)
            }
            finish(reminderSet: granted)
        }
    }

    // MARK: Finish

    private func finish(reminderSet: Bool) {
        guard !hasFinished else { return }
        hasFinished = true
        var properties: [String: Any] = [
            "reminder_set": reminderSet,
            "duration_seconds": Int(Date().timeIntervalSince(startDate))
        ]
        if reminderSet {
            let parts = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
            properties["reminder_time"] = String(format: "%02d:%02d", parts.hour ?? 0, parts.minute ?? 0)
        }
        if let stressBefore { properties["stress_before"] = stressBefore }
        if let stressAfter { properties["stress_after"] = stressAfter }
        if let stressDelta { properties["stress_delta"] = stressDelta }
        track("trial_kickoff_completed", properties)
        if !isPreview {
            var userProperties: [String: Any] = ["trial_kickoff_completed": true]
            if let stressDelta { userProperties["trial_kickoff_stress_delta"] = stressDelta }
            AmplitudeManager.shared.setUserProperties(userProperties)
            TrialKickoff.markDone()
        }
        onFinish()
    }

    private func skip() {
        guard !hasFinished else { return }
        hasFinished = true
        track("trial_kickoff_skipped", ["stage": stage.rawValue])
        if !isPreview { TrialKickoff.markDone() }
        onFinish()
    }

    private func track(_ event: String, _ properties: [String: Any] = [:]) {
        #if DEBUG
        if isPreview {
            print("[TrialKickoff preview] \(event) \(properties)")
            return
        }
        #endif
        AnalyticsManager.shared.track(event: event, properties: properties)
    }

    // MARK: Shared pieces

    private func topBar(showsSkip: Bool) -> some View {
        HStack {
            Spacer()
            if showsSkip {
                Button("onboarding_v2.skip".localized) {
                    HapticManager.light()
                    skip()
                }
                .font(.poppinsMedium(14))
                .foregroundStyle(.white.opacity(0.62))
                .buttonStyle(.plain)
            }
        }
        .frame(height: 44)
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    private func primaryButton(_ title: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button {
            HapticManager.light()
            action()
        } label: {
            Text(title)
                .font(.poppinsSemiBold(17))
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .contentShape(Capsule())
        }
        .buttonStyle(.glassPrimary)
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.45)
        .padding(.horizontal, 24)
        .padding(.bottom, 12)
    }
}

// MARK: - Breathing (1 min physiological sigh)

private struct TrialKickoffBreathingView: View {
    let isPreview: Bool
    let onComplete: (Int) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var startDate: Date?
    @State private var lastToken = -1
    @State private var isDone = false

    private static let timeline = BreathingTimeline(pattern: .physiologicalSigh)
    /// Whole cycles only (≈ 1 min), so the session ends on an exhale.
    private static let duration = (60 / timeline.cycleDuration).rounded(.up) * timeline.cycleDuration

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                #if DEBUG
                if isPreview {
                    Button("⏩ fin") { complete() }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.6))
                }
                #endif
            }
            .frame(height: 44)
            .padding(.horizontal, 20)
            .padding(.top, 8)

            Spacer(minLength: 12)

            Text("trial_kickoff.breathing.title".localized)
                .font(.faroBold(28))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .balancedLines()
                .padding(.horizontal, 28)

            Text("trial_kickoff.breathing.subtitle".localized)
                .font(.poppinsRegular(15))
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .balancedLines()
                .padding(.top, 8)
                .padding(.horizontal, 32)

            Spacer(minLength: 20)

            TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: isDone)) { context in
                let elapsed = startDate.map { context.date.timeIntervalSince($0) } ?? 0
                let position = Self.timeline.position(at: elapsed)
                VStack(spacing: 18) {
                    VStack(spacing: 5) {
                        Text(position.step.labelKey.localized)
                            .font(.faroBold(25))
                            .foregroundStyle(.white)
                        Text("\(Int(ceil(position.stepRemaining)))")
                            .font(.poppinsMedium(16))
                            .foregroundStyle(.white.opacity(0.78))
                            .monospacedDigit()
                    }

                    BreathingWaveView(
                        timeline: Self.timeline,
                        elapsed: elapsed,
                        accent: AudioPalette.accent,
                        reduceMotion: reduceMotion
                    )
                    .frame(height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                    .padding(.horizontal, 20)

                    ProgressView(value: min(elapsed / Self.duration, 1))
                        .tint(AudioPalette.accent)
                        .padding(.horizontal, 60)
                }
                .onChange(of: position.token) { _, token in
                    guard token != lastToken else { return }
                    lastToken = token
                    HapticManager.light()
                }
                .onChange(of: elapsed >= Self.duration) { _, finished in
                    if finished { complete() }
                }
            }

            Spacer()
        }
        .onAppear { startDate = Date() }
    }

    private func complete() {
        guard !isDone else { return }
        isDone = true
        HapticManager.success()
        let seconds = Int(startDate.map { Date().timeIntervalSince($0) } ?? Self.duration)
        onComplete(min(seconds, Int(Self.duration)))
    }
}

// MARK: - Stress 0-5

private struct StressScalePicker: View {
    let question: String
    @Binding var value: Int?

    var body: some View {
        VStack(spacing: 14) {
            Text(question)
                .font(.poppinsSemiBold(16))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            HStack(spacing: 8) {
                ForEach(0...5, id: \.self) { level in
                    Button {
                        HapticManager.light()
                        value = level
                    } label: {
                        Text("\(level)")
                            .font(.poppinsSemiBold(18))
                            .foregroundStyle(value == level ? PlanPalette.deep : .white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(value == level ? PlanPalette.accent : .white.opacity(0.08))
                            )
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(level) / 5")
                    .accessibilityAddTraits(value == level ? .isSelected : [])
                }
            }

            HStack {
                Text("trial_kickoff.stress.low".localized)
                Spacer()
                Text("trial_kickoff.stress.high".localized)
            }
            .font(.poppinsRegular(12))
            .foregroundStyle(.white.opacity(0.55))
        }
        .padding(18)
        .planGlass(cornerRadius: 24)
    }
}

private struct StressDeltaCard: View {
    let before: Int
    let after: Int
    let delta: Int

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: delta < 0 ? "arrow.down.heart.fill" : "heart.fill")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(PlanPalette.deep)
                .frame(width: 48, height: 48)
                .background(Circle().fill(delta < 0 ? PlanPalette.done : PlanPalette.accent))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.faroBold(20))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.poppinsRegular(13))
                    .foregroundStyle(PlanPalette.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .planGlass(cornerRadius: 22)
        .accessibilityElement(children: .combine)
    }

    private var title: String {
        delta < 0
            ? String(format: "trial_kickoff.delta.down_title".localized, -delta)
            : "trial_kickoff.delta.same_title".localized
    }

    private var subtitle: String {
        delta < 0
            ? String(format: "trial_kickoff.delta.down_subtitle".localized, before, after)
            : "trial_kickoff.delta.same_subtitle".localized
    }
}

// MARK: - Week strip (1/7)

private struct WeekProgressStrip: View {
    let done: Int
    let total: Int

    var body: some View {
        VStack(spacing: 10) {
            Text(String(format: "trial_kickoff.badge.week".localized, done, total))
                .font(.poppinsSemiBold(14))
                .foregroundStyle(.white)
            HStack(spacing: 8) {
                ForEach(0..<total, id: \.self) { index in
                    Capsule()
                        .fill(index < done ? AchievementCelebrationView.gold : .white.opacity(0.18))
                        .frame(height: 8)
                }
            }
        }
        .padding(16)
        .planGlass(cornerRadius: 22)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Trial day row

private struct TrialDay: Identifiable {
    let offset: Int
    let date: Date
    let title: String
    let detail: String
    let symbol: String
    let isDone: Bool
    var id: Int { offset }
}

private struct TrialDayRow: View {
    let day: TrialDay

    var body: some View {
        HStack(spacing: 14) {
            VStack(spacing: 2) {
                Text(dayLabel)
                    .font(.poppinsSemiBold(11))
                    .textCase(.uppercase)
                    .foregroundStyle(day.isDone ? PlanPalette.done : PlanPalette.accent)
                Text("\(day.offset + 1)")
                    .font(.faroBold(20))
                    .foregroundStyle(.white)
            }
            .frame(width: 52)

            VStack(alignment: .leading, spacing: 3) {
                Text(day.title)
                    .font(.poppinsSemiBold(15))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                if !day.detail.isEmpty {
                    Text(day.detail)
                        .font(.poppinsRegular(12))
                        .foregroundStyle(PlanPalette.secondaryText)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 0)

            Image(systemName: day.isDone ? "checkmark.circle.fill" : day.symbol)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(day.isDone ? PlanPalette.done : .white.opacity(0.5))
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .planGlass(cornerRadius: 20, tint: day.isDone ? PlanPalette.done.opacity(0.12) : nil)
        .accessibilityElement(children: .combine)
    }

    private var dayLabel: String {
        if day.offset == 0 { return "trial_kickoff.plan.today".localized }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: LanguageManager.shared.currentLanguage.rawValue)
        formatter.setLocalizedDateFormatFromTemplate("EEE")
        return formatter.string(from: day.date)
    }
}

#Preview {
    TrialKickoffView(isPreview: true, onFinish: {})
}
