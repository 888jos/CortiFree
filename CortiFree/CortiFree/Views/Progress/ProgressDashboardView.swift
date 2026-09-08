import SwiftUI

struct ProgressDashboardView: View {
    @StateObject private var viewModel = ProgressViewModel()
    @ObservedObject private var achievementService = AchievementService.shared
    @ObservedObject private var habitBadgeService = HabitBadgeService.shared
    @State private var showAchievements = false
    @State private var selectedDomain: ProgressDomainTrend.Domain = .serenity

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
                        scoreJourneySection
                        ProgressPhotosSection()
                        trendSection
                        calendarSection
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
            MixpanelManager.shared.track(event: "progress_tab_opened")
            Task {
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

    private var scoreJourneySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle("progress.journey.title".localized, icon: "chart.line.uptrend.xyaxis")

            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("progress.journey.score".localized)
                            .font(.faroRegular(11))
                            .foregroundColor(.white.opacity(0.58))
                        Text(scoreText(viewModel.data.currentScore))
                            .font(.faroBold(34))
                            .foregroundColor(.white)
                    }

                    Spacer()

                    if let scoreChange {
                        Label(
                            String(format: "%+.0f", scoreChange),
                            systemImage: scoreChange >= 0 ? "arrow.up.right" : "arrow.down.right"
                        )
                        .font(.faroSemiBold(13))
                        .foregroundColor(.white)
                    }
                }

                if viewModel.data.scoreHistory.isEmpty {
                    inlineEmptyState(icon: "chart.line.uptrend.xyaxis", text: "progress.journey.empty".localized)
                        .frame(height: 100)
                } else {
                    ScoreJourneyChart(points: viewModel.data.scoreHistory)
                        .frame(height: 112)

                    HStack {
                        scoreEndpoint(
                            "progress.journey.day_one".localized,
                            value: scoreText(viewModel.data.baselineScore)
                        )
                        Spacer()
                        scoreEndpoint(
                            "progress.journey.today".localized,
                            value: scoreText(viewModel.data.currentScore),
                            alignment: .trailing
                        )
                    }
                }

                Divider().overlay(.white.opacity(0.1))

                VStack(alignment: .leading, spacing: 9) {
                    HStack {
                        Text("progress.journey.program".localized)
                            .font(.faroSemiBold(12))
                            .foregroundColor(.white)
                        Spacer()
                        Text(String.localizedStringWithFormat("progress.journey.day_count".localized, programDay))
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

                Divider().overlay(.white.opacity(0.1))

                domainProgressSection
            }
            .padding(16)
            .background { progressCardBackground }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(.white.opacity(0.08), lineWidth: 1))
        }
    }

    private var domainProgressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                Text("progress.journey.domains_title".localized)
                    .font(.faroSemiBold(13))
                    .foregroundColor(.white)

                Spacer()

                Menu {
                    ForEach(ProgressDomainTrend.Domain.allCases, id: \.self) { domain in
                        Button {
                            selectedDomain = domain
                        } label: {
                            Label(domainTitle(domain), systemImage: domainIcon(domain))
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: domainIcon(selectedDomain))
                            .font(.system(size: 12, weight: .semibold))
                        Text(domainTitle(selectedDomain))
                            .font(.faroRegular(11))
                            .lineLimit(1)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 9, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
                }
            }

            if let trend = selectedDomainTrend {
                HStack(alignment: .firstTextBaseline) {
                    Text(scoreText(trend.currentValue))
                        .font(.faroBold(24))
                        .foregroundColor(.white)

                    Spacer()

                    if let changeSinceDayOne = trend.dayOneValue.map({ trend.currentValue - $0 }) {
                        Text(String(format: "%@%.0f", changeSinceDayOne >= 0 ? "+" : "", changeSinceDayOne))
                            .font(.faroSemiBold(12))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule().fill(.white.opacity(0.1))
                        Capsule()
                            .fill(.white)
                            .frame(width: geometry.size.width * scoreProgress(trend))
                    }
                }
                .frame(height: 7)

                HStack {
                    scoreEndpoint(
                        "progress.journey.day_one".localized,
                        value: trend.dayOneValue.map(scoreText) ?? "--"
                    )
                    Spacer()
                    scoreEndpoint(
                        "progress.journey.today".localized,
                        value: scoreText(trend.currentValue),
                        alignment: .trailing
                    )
                }
            } else {
                inlineEmptyState(
                    icon: "chart.line.uptrend.xyaxis",
                    text: "progress.journey.domain_empty".localized
                )
            }
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
                        .frame(width: geometry.size.width * min(1, max(0, trend.currentValue / 100)))
                }
            }
            .frame(height: 7)
        }
    }

    private var calendarSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                sectionTitle("progress.calendar.title".localized, icon: "calendar")
                Spacer()
                Text(String.localizedStringWithFormat("progress.best_streak".localized, viewModel.data.bestStreak))
                    .font(.faroRegular(11))
                    .foregroundColor(.white.opacity(0.55))
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 7), count: 7), spacing: 7) {
                ForEach(calendarDays) { day in
                    dayCell(day)
                }
            }
        }
    }

    private var calendarDays: [ProgressDay] {
        if !viewModel.visibleDays.isEmpty { return viewModel.visibleDays }
        return [ProgressDay(date: Calendar.current.startOfDay(for: Date()), completionCount: 0, moodScore: nil)]
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
            MixpanelManager.shared.track(event: "progress_milestone_tapped", properties: [
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

    private func domainIcon(_ domain: ProgressDomainTrend.Domain) -> String {
        switch domain {
        case .serenity: return "leaf.fill"
        case .sleep: return "moon.fill"
        case .energy: return "bolt.fill"
        case .focus: return "target"
        case .balance: return "heart.fill"
        }
    }

    private func scoreProgress(_ trend: ProgressDomainTrend) -> Double {
        min(1, max(0, trend.currentValue / 100))
    }

    private var selectedDomainTrend: ProgressDomainTrend? {
        viewModel.data.domainTrends.first { $0.domain == selectedDomain }
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

    private var programDay: Int {
        let start = Calendar.current.startOfDay(for: viewModel.data.programStartDate)
        let today = Calendar.current.startOfDay(for: Date())
        let elapsed = Calendar.current.dateComponents([.day], from: start, to: today).day ?? 0
        return min(66, max(1, elapsed + 1))
    }

    private var programProgress: Double {
        min(1, max(0, Double(programDay) / 66.0))
    }

    private var scoreChange: Double? {
        guard let baseline = viewModel.data.baselineScore,
              let current = viewModel.data.currentScore else { return nil }
        return current - baseline
    }

    private func scoreText(_ score: Double?) -> String {
        guard let score else { return "--" }
        return "\(Int(score.rounded()))/100"
    }

    private func scoreEndpoint(
        _ label: String,
        value: String,
        alignment: HorizontalAlignment = .leading
    ) -> some View {
        VStack(alignment: alignment, spacing: 2) {
            Text(label)
                .font(.faroRegular(10))
                .foregroundColor(.white.opacity(0.48))
            Text(value)
                .font(.faroSemiBold(12))
                .foregroundColor(.white)
        }
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

private struct ScoreJourneyChart: View {
    let points: [ProgressScorePoint]

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack(spacing: 0) {
                    ForEach(0..<3, id: \.self) { index in
                        Rectangle()
                            .fill(.white.opacity(0.07))
                            .frame(height: 1)
                        if index < 2 { Spacer() }
                    }
                }

                if points.count == 1, let point = points.first {
                    Circle()
                        .fill(.white)
                        .frame(width: 8, height: 8)
                        .position(x: geometry.size.width / 2, y: yPosition(for: point.score, height: geometry.size.height))
                } else if points.count > 1 {
                    Path { path in
                        for (index, point) in points.enumerated() {
                            let position = CGPoint(
                                x: xPosition(for: index, width: geometry.size.width),
                                y: yPosition(for: point.score, height: geometry.size.height)
                            )
                            index == 0 ? path.move(to: position) : path.addLine(to: position)
                        }
                    }
                    .stroke(
                        Color(hex: "B794F6"),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                    )

                    ForEach(Array(points.enumerated()), id: \.element.id) { index, point in
                        Circle()
                            .fill(.white)
                            .frame(width: index == points.count - 1 ? 9 : 5, height: index == points.count - 1 ? 9 : 5)
                            .position(
                                x: xPosition(for: index, width: geometry.size.width),
                                y: yPosition(for: point.score, height: geometry.size.height)
                            )
                    }
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("progress.journey.chart_accessibility".localized)
    }

    private func xPosition(for index: Int, width: CGFloat) -> CGFloat {
        guard points.count > 1 else { return width / 2 }
        return width * CGFloat(index) / CGFloat(points.count - 1)
    }

    private func yPosition(for score: Double, height: CGFloat) -> CGFloat {
        let normalized = min(1, max(0, score / 100))
        return height - (height * normalized)
    }
}

#Preview {
    ProgressDashboardView()
}
