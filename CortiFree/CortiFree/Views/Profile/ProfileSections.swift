//
//  ProfileSections.swift
//  CortiFree
//
//  Cards of the Profile tab: key stats, the user's "why", the current plan,
//  personal sessions, mood of the week, badge showcase and shortcuts.
//  Everything reads existing stores; the Progress tab keeps the detailed stats.
//

import SwiftUI

// MARK: - Shared bits

struct ProfileSectionHeader: View {
    let title: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.faroSemiBold(17))
                .foregroundColor(.white)
            Spacer()
            if let actionTitle, let action {
                Button {
                    HapticManager.light()
                    action()
                } label: {
                    HStack(spacing: 4) {
                        Text(actionTitle)
                        Image(systemName: "chevron.right").font(.system(size: 11, weight: .semibold))
                    }
                    .font(.faroRegular(13))
                    .foregroundColor(PlanPalette.accent)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 4)
    }
}

// MARK: - Key stats strip

struct ProfileStatsStrip: View {
    let streak: Int
    let calmMinutes: Int
    let unlockedBadges: Int
    let totalBadges: Int
    let action: () -> Void

    var body: some View {
        Button {
            HapticManager.light()
            action()
        } label: {
            HStack(spacing: 0) {
                stat(icon: "flame.fill", tint: Color(hex: "FF9F5A"), value: "\(streak)", label: "profile.v2.streak".localized)
                divider
                stat(icon: "timer", tint: PlanPalette.done, value: "\(calmMinutes)", label: "profile.v2.minutes".localized)
                divider
                stat(icon: "seal.fill", tint: PlanPalette.accent, value: "\(unlockedBadges)/\(totalBadges)", label: "profile.v2.badges".localized)
            }
            .padding(.vertical, 14)
            .glassCard(cornerRadius: 22, interactive: true)
        }
        .buttonStyle(PressableCardStyle())
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.1))
            .frame(width: 1, height: 36)
    }

    private func stat(icon: String, tint: Color, value: String, label: String) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(tint)
                Text(value)
                    .font(.faroBold(20))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            Text(label)
                .font(.faroRegular(11))
                .foregroundColor(.white.opacity(0.58))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - My why

struct ProfileWhyCard: View {
    let plan: PersonalPlan

    private var reasons: [String] {
        plan.profile.reasonCodes.prefix(3).map { "onboarding_v2.overall.reason_\($0)".localized }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: plan.goal.symbol)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle().fill(LinearGradient(colors: plan.goal.colors, startPoint: .topLeading, endPoint: .bottomTrailing))
                    )
                VStack(alignment: .leading, spacing: 2) {
                    Text("profile.v2.why.goal".localized.uppercased())
                        .font(.faroSemiBold(11))
                        .tracking(0.8)
                        .foregroundColor(PlanPalette.accent)
                    Text(plan.goal.localizedName)
                        .font(.faroBold(20))
                        .foregroundColor(.white)
                }
            }

            Text(plan.goal.localizedPromise)
                .font(.faroRegular(14))
                .foregroundColor(.white.opacity(0.78))
                .fixedSize(horizontal: false, vertical: true)

            if !reasons.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(reasons, id: \.self) { reason in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "sparkle")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(PlanPalette.accent)
                                .padding(.top, 3)
                            Text(reason)
                                .font(.faroRegular(13))
                                .foregroundColor(PlanPalette.secondaryText)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(.top, 2)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(cornerRadius: 22)
    }
}

// MARK: - My plan

struct ProfilePlanCard: View {
    let plan: PersonalPlan
    let todayDone: Int
    let action: () -> Void

    private var dayNumber: Int { min(plan.dayIndex(), PersonalPlan.length) }
    private var todayItems: Int { plan.day(dayNumber)?.items.count ?? 0 }
    private var fraction: Double { Double(dayNumber) / Double(PersonalPlan.length) }
    private var theme: PlanWeekTheme { plan.day(dayNumber)?.theme ?? .forWeek(1) }

    var body: some View {
        Button {
            HapticManager.light()
            action()
        } label: {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.1), lineWidth: 6)
                        Circle()
                            .trim(from: 0, to: fraction)
                            .stroke(
                                LinearGradient(colors: PlanPalette.itemGradient, startPoint: .topLeading, endPoint: .bottomTrailing),
                                style: StrokeStyle(lineWidth: 6, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                        VStack(spacing: 0) {
                            Text("\(dayNumber)")
                                .font(.faroBold(20))
                                .foregroundColor(.white)
                            Text("/\(PersonalPlan.length)")
                                .font(.faroRegular(10))
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                    .frame(width: 64, height: 64)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(plan.localizedTitle)
                            .font(.faroBold(17))
                            .foregroundColor(.white)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        Text(plan.isFinished ? "profile.v2.plan.finished".localized : theme.localizedTitle)
                            .font(.faroRegular(13))
                            .foregroundColor(PlanPalette.secondaryText)
                            .lineLimit(1)
                        if !plan.isFinished, todayItems > 0 {
                            todayProgress
                        }
                    }
                    Spacer(minLength: 0)
                }

                HStack {
                    Text((plan.isFinished ? "profile.v2.plan.cta_finished" : "profile.v2.plan.cta").localized)
                        .font(.faroSemiBold(14))
                    Spacer()
                    Image(systemName: "arrow.right")
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundColor(PlanPalette.deep)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Capsule().fill(.white))
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassCard(cornerRadius: 22, interactive: true)
        }
        .buttonStyle(PressableCardStyle())
    }

    private var todayProgress: some View {
        HStack(spacing: 6) {
            HStack(spacing: 3) {
                ForEach(0..<todayItems, id: \.self) { index in
                    Capsule()
                        .fill(index < todayDone ? PlanPalette.done : Color.white.opacity(0.15))
                        .frame(width: 14, height: 5)
                }
            }
            Text(String(format: "profile.v2.plan.today_done".localized, min(todayDone, todayItems), todayItems))
                .font(.faroRegular(11))
                .foregroundColor(.white.opacity(0.58))
        }
        .padding(.top, 2)
    }
}

// MARK: - My sessions

struct ProfileSessionsSection: View {
    let explore: () -> Void
    @ObservedObject private var library = SessionLibraryStore.shared

    private var showsFavorites: Bool { !library.sessions(in: .favorites).isEmpty }

    private var sessions: [GuidedSession] {
        Array(library.sessions(in: showsFavorites ? .favorites : .recent).prefix(8))
    }

    var body: some View {
        let items = sessions
        VStack(alignment: .leading, spacing: 12) {
            ProfileSectionHeader(
                title: items.isEmpty ? "profile.v2.sessions.title".localized : (showsFavorites ? SessionLibrary.favorites : .recent).titleKey.localized,
                actionTitle: items.isEmpty ? nil : "profile.v2.see_all".localized,
                action: explore
            )

            if items.isEmpty {
                emptyState
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(items) { session in
                            ProfileSessionTile(session: session)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.horizontal, -20)
            }
        }
    }

    private var emptyState: some View {
        Button {
            HapticManager.light()
            explore()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(PlanPalette.accent)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(PlanPalette.accent.opacity(0.15)))
                VStack(alignment: .leading, spacing: 3) {
                    Text("profile.v2.sessions.empty".localized)
                        .font(.faroRegular(13))
                        .foregroundColor(.white.opacity(0.78))
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("profile.v2.sessions.explore".localized)
                        .font(.faroSemiBold(13))
                        .foregroundColor(PlanPalette.accent)
                }
                Spacer(minLength: 0)
            }
            .padding(16)
            .glassCard(cornerRadius: 22, interactive: true)
        }
        .buttonStyle(PressableCardStyle())
    }
}

private struct ProfileSessionTile: View {
    let session: GuidedSession

    var body: some View {
        Button {
            HapticManager.light()
            GuidedSessionPlayer.shared.play(session, presentFullPlayer: true)
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                LibraryImage(name: session.artwork.imageName ?? session.category.libraryImage)
                    .frame(width: 140, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(alignment: .bottomTrailing) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(PlanPalette.deep)
                            .frame(width: 28, height: 28)
                            .background(Circle().fill(.white))
                            .padding(8)
                    }
                Text(session.localizedTitle)
                    .font(.faroSemiBold(13))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(height: 34, alignment: .topLeading)
                Text(session.durationLabel)
                    .font(.faroRegular(11))
                    .foregroundColor(.white.opacity(0.5))
            }
            .frame(width: 140)
        }
        .buttonStyle(PressableCardStyle())
        .accessibilityLabel(session.localizedTitle)
    }
}

// MARK: - Mood of the week

struct ProfileMoodCard: View {
    /// Last seven days, oldest first.
    let days: [ProgressDay]
    let write: () -> Void
    let history: () -> Void

    private var hasMood: Bool { days.contains { $0.moodScore != nil } }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("profile.v2.mood.title".localized)
                    .font(.faroSemiBold(17))
                    .foregroundColor(.white)
                Text((hasMood ? "profile.v2.mood.subtitle" : "profile.v2.mood.empty").localized)
                    .font(.faroRegular(12))
                    .foregroundColor(.white.opacity(0.58))
            }

            HStack(spacing: 0) {
                ForEach(days) { day in
                    VStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(day.moodScore == nil ? 0.06 : 0.12))
                                .frame(width: 36, height: 36)
                            if let mood = Self.mood(for: day.moodScore) {
                                Text(mood.emoji).font(.system(size: 19))
                            } else {
                                Circle()
                                    .fill(Color.white.opacity(0.2))
                                    .frame(width: 5, height: 5)
                            }
                        }
                        Text(Self.weekdayInitial(day.date))
                            .font(.faroRegular(10))
                            .foregroundColor(.white.opacity(Calendar.current.isDateInToday(day.date) ? 0.9 : 0.45))
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            HStack(spacing: 10) {
                pill(title: "profile.v2.mood.write".localized, icon: "square.and.pencil", filled: true, action: write)
                pill(title: "profile.v2.mood.history".localized, icon: "book.closed.fill", filled: false, action: history)
            }
        }
        .padding(18)
        .glassCard(cornerRadius: 22)
    }

    private func pill(title: String, icon: String, filled: Bool, action: @escaping () -> Void) -> some View {
        Button {
            HapticManager.light()
            action()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 13, weight: .semibold))
                Text(title).font(.faroSemiBold(13))
            }
            .foregroundColor(filled ? PlanPalette.deep : .white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 11)
            .background(Capsule().fill(filled ? Color.white : Color.white.opacity(0.1)))
        }
        .buttonStyle(PressableCardStyle())
    }

    /// Inverse of ProgressAnalyticsService.moodScore (1 = awful … 6 = amazing).
    private static func mood(for score: Double?) -> Mood? {
        guard let score else { return nil }
        let index = Int(score.rounded()) - 1
        return Mood.allCases.indices.contains(index) ? Mood.allCases[index] : nil
    }

    private static func weekdayInitial(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: LanguageManager.shared.currentLanguage.rawValue)
        formatter.dateFormat = "EEEEE"
        return formatter.string(from: date).uppercased()
    }
}

// MARK: - Badge showcase

struct ProfileBadgesShowcase: View {
    let achievements: [Achievement]
    let seeAll: () -> Void

    /// The two latest unlocked badges, then the next one to earn.
    private var showcased: [Achievement] {
        let unlocked = achievements
            .filter(\.isUnlocked)
            .sorted { ($0.unlockedAt ?? .distantPast) > ($1.unlockedAt ?? .distantPast) }
        let next = achievements
            .filter { !$0.isUnlocked }
            .sorted { $0.requirement < $1.requirement }
        return Array((unlocked.prefix(2) + next.prefix(3 - min(2, unlocked.count))).prefix(3))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ProfileSectionHeader(title: "profile.v2.badges".localized, actionTitle: "profile.v2.see_all".localized, action: seeAll)

            HStack(alignment: .top, spacing: 12) {
                ForEach(showcased) { achievement in
                    AchievementBadge(achievement: achievement, size: .medium, onTap: seeAll)
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 8)
            .glassCard(cornerRadius: 22)
        }
    }
}

// MARK: - Shortcuts

struct ProfileShortcutsSection: View {
    let openMilo: () -> Void
    @Environment(\.openURL) private var openURL

    private static let appStoreURL = URL(string: "https://apps.apple.com/app/id6758314805")!
    private static let reviewURL = URL(string: "https://apps.apple.com/app/id6758314805?action=write-review")!

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ProfileSectionHeader(title: "profile.v2.more.title".localized)

            VStack(spacing: 0) {
                Button {
                    HapticManager.light()
                    openMilo()
                } label: {
                    row(icon: "bubble.left.and.bubble.right.fill", title: "profile.v2.more.milo", subtitle: "profile.v2.more.milo_sub")
                }
                .buttonStyle(.plain)

                separator

                ShareLink(item: Self.appStoreURL, message: Text("profile.v2.more.share_message".localized)) {
                    row(icon: "gift.fill", title: "profile.v2.more.invite", subtitle: "profile.v2.more.invite_sub")
                }
                .buttonStyle(.plain)

                separator

                Button {
                    HapticManager.light()
                    openURL(Self.reviewURL)
                } label: {
                    row(icon: "star.fill", title: "profile.v2.more.rate", subtitle: "profile.v2.more.rate_sub")
                }
                .buttonStyle(.plain)
            }
            .glassCard(cornerRadius: 22)
        }
    }

    private var separator: some View {
        Rectangle()
            .fill(Color.white.opacity(0.08))
            .frame(height: 1)
            .padding(.leading, 64)
    }

    private func row(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(PlanPalette.accent)
                .frame(width: 36, height: 36)
                .background(RoundedRectangle(cornerRadius: 11, style: .continuous).fill(PlanPalette.accent.opacity(0.15)))
            VStack(alignment: .leading, spacing: 2) {
                Text(title.localized)
                    .font(.faroSemiBold(15))
                    .foregroundColor(.white)
                Text(subtitle.localized)
                    .font(.faroRegular(12))
                    .foregroundColor(.white.opacity(0.55))
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.35))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}
