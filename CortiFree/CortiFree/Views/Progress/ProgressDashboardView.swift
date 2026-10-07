import SwiftUI

struct ProgressDashboardView: View {
    @StateObject private var viewModel = ProgressViewModel()
    @ObservedObject private var achievementService = AchievementService.shared
    @ObservedObject private var habitBadgeService = HabitBadgeService.shared
    @ObservedObject private var planStore = PersonalPlanStore.shared
    @State private var showAchievements = false

    var body: some View {
        ZStack {
            GalaxyBackgroundView(intensity: 0.65)

            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 28) {
                    header

                    if viewModel.isLoading && viewModel.data.days.isEmpty {
                        loadingState
                    } else {
                        overview
                        journeySection
                        ProgressPhotosSection()
                        trendSection
                        checkInTrackerSection
                        activitySection
                        milestoneSection

                        if let error = viewModel.errorMessage {
                            staleDataNotice(error)
                        }
                    }

                    Spacer(minLength: 108)
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
            }
            .refreshable {
                await viewModel.refresh()
                await achievementService.loadAchievements()
                await habitBadgeService.loadHabitBadges()
            }
        }
        .onAppear {
            AnalyticsManager.shared.track(event: "progress_tab_opened")
            Task {
                await planStore.ensurePlan()
                await viewModel.refresh()
                await achievementService.loadAchievements()
                await habitBadgeService.loadHabitBadges()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("DailyCheckInSaved"))) { _ in
            Task { await viewModel.refresh() }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("TaskValidated"))) { _ in
            Task { await viewModel.refresh() }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("StreakUpdated"))) { _ in
            Task { await viewModel.refresh() }
        }
        .fullScreenCover(isPresented: $showAchievements) {
            AchievementsView()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("progress.title".localized)
                .font(.faroBold(28))
                .foregroundColor(.white)
            Text("progress.subtitle".localized)
                .font(.faroRegular(13))
                .foregroundColor(.white.opacity(0.62))
        }
    }

    private var overview: some View {
        VStack(alignment: .leading, spacing: 20) {
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible())
                ],
                spacing: 12
            ) {
                streakCard
                badgesCard
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("progress.stats.title".localized)
                    .font(.faroSemiBold(17))
                    .foregroundColor(.white)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                    statCard(
                        icon: "calendar.badge.checkmark",
                        value: "\(viewModel.activeDays) / \(max(viewModel.data.days.count, 1))",
                        label: "progress.stats.active_days".localized
                    )
                    statCard(
                        icon: "checkmark.circle.fill",
                        value: "\(viewModel.completedSessions)",
                        label: "progress.stats.sessions".localized
                    )
                    statCard(
                        icon: "timer",
                        value: formattedDuration(totalRecoverySeconds),
                        label: "progress.stats.recovery_time".localized
                    )
                    statCard(
                        icon: "sparkles",
                        value: topActivityName,
                        label: "progress.stats.top_activity".localized
                    )
                }
            }
        }
    }

    private var streakCard: some View {
        Button {
            HapticManager.light()
            showAchievements = true
        } label: {
            VStack(spacing: 10) {
                Image("progress_streak_flame")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 38, height: 38)

                Text("\(viewModel.data.currentStreak)")
                    .font(.faroBold(25))
                    .foregroundColor(.white)

                Text("progress.current_streak".localized)
                    .font(.faroSemiBold(13))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                HStack(spacing: 5) {
                    ForEach(weeklyOverviewDays) { day in
                        VStack(spacing: 5) {
                            Text(weekdayInitial(for: day.date))
                                .font(.faroRegular(9))
                                .foregroundColor(.white.opacity(0.48))

                            Circle()
                                .fill(day.isActive ? libraryAccent.opacity(0.9) : .white.opacity(0.1))
                                .frame(width: 16, height: 16)
                                .overlay {
                                    if day.isActive {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 9, weight: .semibold))
                                            .foregroundColor(.white)
                                    }
                                }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .frame(height: 184)
            .background { progressCardBackground }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(.white.opacity(0.2), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var badgesCard: some View {
        Button {
            HapticManager.light()
            showAchievements = true
        } label: {
            VStack(spacing: 10) {
                BadgeOctagonMark(
                    icon: "seal.fill",
                    number: nil,
                    isUnlocked: true,
                    accent: libraryAccent,
                    size: 38
                )

                Text("\(totalUnlockedBadgeCount)")
                    .font(.faroBold(25))
                    .foregroundColor(.white)

                Text("progress.badges_unlocked".localized)
                    .font(.faroSemiBold(13))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                Text("\(totalBadgeCount) \("progress.milestones.title".localized.lowercased())")
                    .font(.faroRegular(10))
                    .foregroundColor(.white.opacity(0.48))
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .frame(height: 184)
            .background { progressCardBackground }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(.white.opacity(0.2), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private func statCard(icon: String, value: String, label: String, detail: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)

            Spacer(minLength: 0)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.faroRegular(12))
                    .foregroundColor(.white.opacity(0.58))
                    .lineLimit(1)

                if let detail {
                    Text(detail)
                        .font(.faroRegular(10))
                        .foregroundColor(.white.opacity(0.42))
                        .lineLimit(1)
                }
            }

            Text(value)
                .font(.faroBold(25))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 132)
        .background { progressCardBackground }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(.white.opacity(0.08), lineWidth: 1))
    }

    private var weeklyOverviewDays: [ProgressDay] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Keep the seven-day rhythm visible even during the first week of a program.
        return (0..<7).reversed().compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            return calendarDays.first(where: { calendar.isDate($0.date, inSameDayAs: date) })
                ?? ProgressDay(date: date, completionCount: 0, moodScore: nil)
        }
    }

    private var totalRecoverySeconds: Int {
        viewModel.data.activities.reduce(0) { $0 + $1.durationSeconds }
    }

    private var topActivityName: String {
        guard let topActivity = viewModel.data.topActivity else { return "--" }
        return activityTitle(topActivity)
    }

    private var totalUnlockedBadgeCount: Int {
        achievementService.unlockedCount + habitBadgeService.unlockedBadgesCount
    }

    private var totalBadgeCount: Int {
        achievementService.totalCount + habitBadgeService.totalBadgesCount
    }

    private var journeySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle(planStore.plan?.localizedTitle ?? "plan.progress.title".localized, icon: "chart.line.uptrend.xyaxis")

            VStack(alignment: .leading, spacing: 9) {
                HStack {
                    Text(String.localizedStringWithFormat("plan.progress.day_count".localized, programDay))
                        .font(.faroSemiBold(12))
                        .foregroundColor(.white)
                    Spacer()
                    Text("\(Int((programProgress * 100).rounded()))%")
                        .font(.faroRegular(11))
                        .foregroundColor(.white.opacity(0.62))
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule().fill(.white.opacity(0.1))
                        Capsule()
                            .fill(Color(hex: "B794F6"))
                            .frame(width: geometry.size.width * programProgress)
                    }
                }
                .frame(height: 7)
            }
            .padding(16)
            .background { progressCardBackground }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(.white.opacity(0.08), lineWidth: 1))
        }
    }

    private var trendSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle("progress.trends.title".localized, icon: "chart.line.uptrend.xyaxis")

            if let averageMood = viewModel.averageMood {
                moodTrend(averageMood)
            } else {
                inlineEmptyState(icon: "face.smiling", text: "progress.trends.mood_empty".localized)
            }

            if viewModel.data.domainTrends.isEmpty {
                inlineEmptyState(icon: "waveform.path.ecg", text: "progress.trends.domain_empty".localized)
            } else {
                VStack(spacing: 14) {
                    ForEach(viewModel.data.domainTrends) { trend in
                        domainTrendRow(trend)
                    }
                }
            }
        }
    }

    private func moodTrend(_ value: Double) -> some View {
        HStack(spacing: 14) {
            Image(systemName: moodIcon(value))
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 48, height: 48)
                .background(.white.opacity(0.08), in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text("progress.trends.mood".localized)
                    .font(.faroSemiBold(13))
                    .foregroundColor(.white)
                Text(String.localizedStringWithFormat("progress.trends.mood_value".localized, value))
                    .font(.faroRegular(12))
                    .foregroundColor(.white.opacity(0.62))
            }
            Spacer()
        }
    }

    private func domainTrendRow(_ trend: ProgressDomainTrend) -> some View {
        VStack(spacing: 7) {
            HStack {
                Text(domainTitle(trend.domain))
                    .font(.faroRegular(12))
                    .foregroundColor(.white.opacity(0.8))
                Spacer()
                Text(trendLabel(trend))
                    .font(.faroSemiBold(11))
                    .foregroundColor(trend.change == nil ? .white.opacity(0.45) : .white)
            }
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule().fill(.white.opacity(0.09))
                    Capsule()
                        .fill(.white)
                        .frame(width: geometry.size.width * CGFloat(trendProgress(trend)))
                }
            }
            .frame(height: 7)
        }
    }

    private var checkInTrackerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                sectionTitle("progress.checkin_tracker.title".localized, icon: "checkmark.message.fill")
                Spacer()
                Text(String.localizedStringWithFormat("progress.checkin_tracker.completed".localized, checkInCount))
                    .font(.faroRegular(11))
                    .foregroundColor(.white.opacity(0.55))
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 6) {
                    ForEach(Array(checkInWeeks.enumerated()), id: \.offset) { _, week in
                        VStack(spacing: 6) {
                            ForEach(week) { day in
                                checkInCell(day)
                            }
                        }
                    }
                }
                .padding(.vertical, 2)
            }
            .scrollClipDisabled()

            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 12, height: 12)
                Text("progress.checkin_tracker.empty".localized)
                    .font(.faroRegular(10))
                    .foregroundColor(.white.opacity(0.48))
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.appTheme)
                    .frame(width: 12, height: 12)
                Text("progress.checkin_tracker.done".localized)
                    .font(.faroRegular(10))
                    .foregroundColor(.white.opacity(0.48))
            }
        }
    }

    private var calendarDays: [ProgressDay] {
        if !viewModel.visibleDays.isEmpty { return viewModel.visibleDays }
        return [ProgressDay(date: Calendar.current.startOfDay(for: Date()), completionCount: 0, moodScore: nil)]
    }

    private var checkInWeeks: [[ProgressDay]] {
        let days = calendarDays
        return stride(from: 0, to: days.count, by: 7).map { start in
            Array(days[start..<min(start + 7, days.count)])
        }
    }

    private var checkInCount: Int {
        calendarDays.filter { $0.moodScore != nil }.count
    }

    private func checkInCell(_ day: ProgressDay) -> some View {
        let completed = day.moodScore != nil
        let intensity = completed ? 0.55 + min(max(day.moodScore ?? 0.5, 0), 1) * 0.45 : 0.08

        return RoundedRectangle(cornerRadius: 4, style: .continuous)
            .fill(
                completed
                    ? LinearGradient(
                        colors: [Color.appTheme.opacity(intensity), Color.appThemeSecondary.opacity(intensity)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    : LinearGradient(colors: [Color.white.opacity(0.08)], startPoint: .top, endPoint: .bottom)
            )
            .frame(width: 14, height: 14)
            .overlay {
                if completed {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .stroke(Color.white.opacity(0.14), lineWidth: 0.5)
                }
            }
            .accessibilityLabel(day.date.formatted(date: .complete, time: .omitted))
            .accessibilityValue(completed ? "progress.checkin_tracker.done".localized : "progress.checkin_tracker.empty".localized)
    }

    private func dayCell(_ day: ProgressDay) -> some View {
        VStack(spacing: 5) {
            Text(day.date.formatted(.dateTime.weekday(.narrow)))
                .font(.faroRegular(9))
                .foregroundColor(.white.opacity(0.4))
            RoundedRectangle(cornerRadius: 5)
                .fill(dayColor(day))
                .aspectRatio(1, contentMode: .fit)
                .overlay {
                    if day.completionCount > 0 {
                        Text("\(day.completionCount)")
                            .font(.faroSemiBold(9))
                            .foregroundColor(.black)
                    }
                }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(day.date.formatted(date: .complete, time: .omitted))
        .accessibilityValue(day.isActive ? String.localizedStringWithFormat("progress.calendar.completed".localized, day.completionCount) : "progress.calendar.none".localized)
    }

    private func dayColor(_ day: ProgressDay) -> Color {
        switch day.completionCount {
        case 0: return .white.opacity(0.08)
        case 1: return .white.opacity(0.4)
        case 2: return .white.opacity(0.7)
        default: return .white
        }
    }

    private var activitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle("progress.activities.title".localized, icon: "timer")

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                ForEach(viewModel.data.activities) { activity in
                    statCard(
                        icon: activityIcon(activity.category),
                        value: formattedDuration(activity.durationSeconds),
                        label: activityTitle(activity.category),
                        detail: String.localizedStringWithFormat(
                            "progress.activities.sessions".localized,
                            activity.sessionCount
                        )
                    )
                }
            }
        }
    }

    private var milestoneSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                sectionTitle("progress.milestones.title".localized, icon: "trophy.fill")
                Spacer()
                Text("\(totalUnlockedBadgeCount)/\(totalBadgeCount)")
                    .font(.faroSemiBold(12))
                    .foregroundColor(.white.opacity(0.6))
            }

            if featuredAchievements.isEmpty {
                inlineEmptyState(
                    icon: "hexagon",
                    text: "progress.milestones.empty".localized
                )
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(featuredAchievements) { achievement in
                            milestoneCard(achievement)
                        }
                    }
                }
            }
        }
    }

    private var featuredAchievements: [Achievement] {
        achievementService.achievements.filter(\.isUnlocked).sorted {
            ($0.unlockedAt ?? .distantPast) > ($1.unlockedAt ?? .distantPast)
        }
        .prefix(5)
        .map { $0 }
    }

    private func milestoneCard(_ achievement: Achievement) -> some View {
        Button {
            AnalyticsManager.shared.track(event: "progress_milestone_tapped", properties: [
                "achievement_id": achievement.id,
                "unlocked": achievement.isUnlocked
            ])
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                BadgeOctagonMark(
                    icon: achievement.icon,
                    number: nil,
                    isUnlocked: achievement.isUnlocked,
                    accent: libraryAccent,
                    size: 54,
                    assetName: achievement.badgeAssetName
                )
                Text(achievement.title)
                    .font(.faroSemiBold(11))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .frame(height: 34, alignment: .topLeading)
                ProgressView(value: achievement.progressPercentage)
                    .tint(.white)
            }
            .frame(width: 128, alignment: .leading)
            .padding(14)
            .background { progressCardBackground }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(.white.opacity(0.08), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var loadingState: some View {
        VStack(spacing: 12) {
            ProgressView().tint(.white)
            Text("progress.loading".localized)
                .font(.faroRegular(13))
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 100)
    }

    private func staleDataNotice(_ error: String) -> some View {
        HStack(spacing: 9) {
            Image(systemName: "icloud.slash")
            Text(viewModel.data.days.isEmpty ? error : "progress.cached_notice".localized)
        }
        .font(.faroRegular(11))
        .foregroundColor(.white.opacity(0.48))
    }

    private func inlineEmptyState(icon: String, text: String) -> some View {
        HStack(spacing: 11) {
            Image(systemName: icon).foregroundColor(.white.opacity(0.4))
            Text(text)
                .font(.faroRegular(12))
                .foregroundColor(.white.opacity(0.55))
        }
        .padding(.vertical, 5)
    }

    private func sectionTitle(_ text: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
            Text(text)
                .font(.faroSemiBold(17))
                .foregroundColor(.white)
        }
    }

    private func activityTitle(_ category: ProgressActivityCategory) -> String {
        "progress.activity.\(category.rawValue)".localized
    }

    private func activityIcon(_ category: ProgressActivityCategory) -> String {
        switch category {
        case .breathing: return "wind"
        case .meditation: return "figure.mind.and.body"
        case .sounds: return "waveform"
        case .other: return "sparkles"
        }
    }

    private func domainTitle(_ domain: ProgressDomainTrend.Domain) -> String {
        "progress.domain.\(domain.rawValue)".localized
    }

    private func trendProgress(_ trend: ProgressDomainTrend) -> Double {
        let scale = max(viewModel.data.domainTrends.map(\.currentValue).max() ?? 0, 1)
        return min(1, max(0, trend.currentValue / scale))
    }

    private func trendLabel(_ trend: ProgressDomainTrend) -> String {
        guard let change = trend.change else { return "progress.trends.building".localized }
        return String(format: "%@%.0f", change >= 0 ? "+" : "", change)
    }

    private func moodIcon(_ value: Double) -> String {
        switch value {
        case ..<2.5: return "cloud.rain.fill"
        case ..<3.5: return "cloud.fill"
        case ..<4.5: return "circle.lefthalf.filled"
        case ..<5.5: return "sun.min.fill"
        default: return "sun.max.fill"
        }
    }

    /// Day of the personalized 28-day plan (PersonalPlanStore).
    private var programDay: Int {
        guard let plan = planStore.plan else { return 1 }
        return min(PersonalPlan.length, plan.dayIndex())
    }

    private var programProgress: Double {
        min(1, max(0, Double(programDay) / Double(PersonalPlan.length)))
    }

    private var progressCardBackground: some View {
        // Match the resting cards used by Library > Sounds/Breathing/Meditation.
        Color.white.opacity(0.05)
    }

    private var libraryAccent: Color {
        Color(hex: "49288C")
    }

    private func weekdayInitial(for date: Date) -> String {
        let weekday = Calendar.current.component(.weekday, from: date)
        let symbols = Calendar.current.shortWeekdaySymbols
        guard symbols.indices.contains(weekday - 1) else { return "-" }
        return String(symbols[weekday - 1].prefix(1)).uppercased()
    }

    private func formattedDuration(_ seconds: Int) -> String {
        let safeSeconds = max(0, seconds)
        guard safeSeconds > 0 else { return "0 min" }
        let hours = safeSeconds / 3600
        let minutes = safeSeconds / 60 % 60
        let remainingSeconds = safeSeconds % 60

        if hours > 0 {
            return remainingSeconds == 0
                ? "\(hours)h \(minutes) min"
                : "\(hours)h \(minutes) min \(remainingSeconds) sec"
        }
        if minutes > 0 {
            return remainingSeconds == 0
                ? "\(minutes) min"
                : "\(minutes) min \(remainingSeconds) sec"
        }
        return "\(remainingSeconds) sec"
    }
}

#Preview {
    ProgressDashboardView()
}
