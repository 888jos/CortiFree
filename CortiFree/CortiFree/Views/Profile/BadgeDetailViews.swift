//
//  BadgeDetailViews.swift
//  CortiFree
//
//  Detail sheets of the achievements gallery: one for a habit badge (its four levels)
//  and one for a streak achievement. Galaxy background with a glow in the badge colour,
//  the progress, how to unlock it and every level.
//

import SwiftUI

// MARK: - Shared pieces

/// Galaxy background with a soft halo of the badge colour behind the hero.
private struct BadgeDetailBackground: View {
    let accent: Color

    var body: some View {
        ZStack {
            GalaxyBackgroundView(intensity: 0.55)
            RadialGradient(colors: [accent.opacity(0.32), .clear], center: .init(x: 0.5, y: 0.18), startRadius: 10, endRadius: 360)
        }
        .ignoresSafeArea()
    }
}

/// Large badge with a breathing glow once unlocked.
private struct BadgeHero: View {
    let icon: String
    let isUnlocked: Bool
    let accent: Color
    let assetName: String?
    @State private var glow = false

    var body: some View {
        ZStack {
            if isUnlocked {
                Circle()
                    .fill(accent.opacity(glow ? 0.34 : 0.18))
                    .frame(width: 200, height: 200)
                    .blur(radius: 40)
            }
            BadgeOctagonMark(icon: icon, number: nil, isUnlocked: isUnlocked, accent: accent, size: 150, assetName: assetName)
                .shadow(color: isUnlocked ? accent.opacity(0.45) : .clear, radius: 24, y: 10)
                .scaleEffect(glow && isUnlocked ? 1.02 : 1)
        }
        .frame(height: 210)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true)) { glow = true }
        }
    }
}

private struct BadgeCloseButton: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Button {
            HapticManager.light()
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .cfGlassCircle()
        }
        .buttonStyle(.plain)
        .accessibilityLabel("achievements.close".localized)
    }
}

private struct BadgeProgressBar: View {
    let value: Double
    let accent: Color

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.1))
                Capsule()
                    .fill(LinearGradient(colors: [accent.opacity(0.75), accent], startPoint: .leading, endPoint: .trailing))
                    .frame(width: max(8, geo.size.width * min(max(value, 0), 1)))
            }
        }
        .frame(height: 8)
    }
}

private func badgeCardTitle(_ key: String) -> some View {
    Text(key.localized.uppercased())
        .font(.faroSemiBold(12))
        .tracking(0.8)
        .foregroundStyle(.white.opacity(0.55))
}

private func badgeDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.locale = LanguageManager.shared.currentLanguage.locale
    formatter.dateStyle = .long
    return formatter.string(from: date)
}

// MARK: - Habit badge

struct HabitBadgeDetailView: View {
    let habitId: String
    @State private var selectedLevel: HabitBadge.BadgeLevel
    @ObservedObject private var service = HabitBadgeService.shared

    init(habitId: String, focusedLevel: HabitBadge.BadgeLevel? = nil) {
        self.habitId = habitId
        let badges = HabitBadgeService.shared.badges(for: habitId)
        // Default: the next level to earn, or diamond when everything is unlocked.
        let next = badges.first { !$0.isUnlocked }?.level ?? .diamond
        _selectedLevel = State(initialValue: focusedLevel ?? next)
    }

    private var badges: [HabitBadge] {
        service.badges(for: habitId).sorted { $0.level.percentage < $1.level.percentage }
    }

    private var progress: Int { badges.map(\.progress).max() ?? 0 }

    private var selected: HabitBadge {
        badges.first { $0.level == selectedLevel }
            ?? HabitBadge.badgesForHabit(habitId).first { $0.level == selectedLevel }!
    }

    private var accent: Color { Color(hex: selected.level.color) }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            BadgeDetailBackground(accent: accent)
                .animation(.easeInOut(duration: 0.35), value: selectedLevel)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    hero
                    progressCard
                    howCard
                    levelsCard
                }
                .padding(.horizontal, 20)
                .padding(.top, 36)
                .padding(.bottom, 40)
            }

            BadgeCloseButton()
                .padding(.top, 14)
                .padding(.trailing, 16)
        }
        .environment(\.colorScheme, .dark)
    }

    private var hero: some View {
        VStack(spacing: 12) {
            BadgeHero(icon: HabitBadge.habitIcon(habitId), isUnlocked: selected.isUnlocked, accent: accent, assetName: selected.badgeAssetName)
                .id(selectedLevel)
                .transition(.scale(scale: 0.9).combined(with: .opacity))

            Text(String(format: "badge.detail.tier".localized, selected.level.starCount, HabitBadge.BadgeLevel.allCases.count))
                .font(.faroSemiBold(12))
                .tracking(0.6)
                .foregroundStyle(accent)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(accent.opacity(0.14), in: Capsule())
                .overlay(Capsule().strokeBorder(accent.opacity(0.35), lineWidth: 1))

            Text("\(HabitBadge.habitDisplayName(habitId)) · \(selected.level.displayName)")
                .font(.faroBold(28))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            Group {
                if let date = selected.unlockedAt {
                    Label(String(format: "badge.unlocked_date".localized, badgeDate(date)), systemImage: "checkmark.seal.fill")
                        .foregroundStyle(accent)
                } else {
                    Label(String(format: "badge.detail.remaining".localized, max(0, selected.requirement - progress)), systemImage: "lock.fill")
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .font(.faroRegular(14))
        }
    }

    private var progressCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            badgeCardTitle("badge.detail.progress_title")
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("\(progress)")
                    .font(.faroBold(34))
                    .foregroundStyle(.white)
                    .monospacedDigit()
                Text(String(format: "badge.detail.progress_of".localized, selected.requirement))
                    .font(.faroRegular(15))
                    .foregroundStyle(.white.opacity(0.6))
                Spacer()
                if selected.isUnlocked {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(accent)
                }
            }
            BadgeProgressBar(value: Double(progress) / Double(max(1, selected.requirement)), accent: accent)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cfGlass(cornerRadius: 22)
    }

    private var howCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            badgeCardTitle("badge.detail.how_title")
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: HabitBadge.habitIcon(habitId))
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(accent)
                    .frame(width: 38, height: 38)
                    .background(accent.opacity(0.14), in: Circle())
                VStack(alignment: .leading, spacing: 6) {
                    Text("badge.how.\(habitId)".localized)
                        .font(.faroRegular(15))
                        .foregroundStyle(.white.opacity(0.9))
                        .fixedSize(horizontal: false, vertical: true)
                    Text("badge.detail.every_cycle".localized)
                        .font(.faroRegular(13))
                        .foregroundStyle(.white.opacity(0.55))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cfGlass(cornerRadius: 22)
    }

    private var levelsCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            badgeCardTitle("badge.detail.levels_title")
                .padding(.bottom, 6)
            ForEach(badges) { badge in
                levelRow(badge)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cfGlass(cornerRadius: 22)
    }

    private func levelRow(_ badge: HabitBadge) -> some View {
        let color = Color(hex: badge.level.color)
        let isSelected = badge.level == selectedLevel
        let isNext = !badge.isUnlocked && badges.first(where: { !$0.isUnlocked })?.level == badge.level
        return Button {
            HapticManager.light()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { selectedLevel = badge.level }
        } label: {
            HStack(spacing: 12) {
                BadgeOctagonMark(icon: HabitBadge.habitIcon(habitId), number: nil, isUnlocked: badge.isUnlocked,
                                 accent: color, size: 40, assetName: badge.badgeAssetName)
                VStack(alignment: .leading, spacing: 2) {
                    Text(badge.level.displayName)
                        .font(.faroSemiBold(15))
                        .foregroundStyle(.white)
                    Text(String(format: "badge.detail.times".localized, badge.requirement))
                        .font(.faroRegular(12))
                        .foregroundStyle(.white.opacity(0.55))
                }
                Spacer()
                if badge.isUnlocked {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(color)
                } else if isNext {
                    Text("\(min(progress, badge.requirement))/\(badge.requirement)")
                        .font(.faroSemiBold(13))
                        .foregroundStyle(color)
                        .monospacedDigit()
                } else {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.35))
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isSelected ? color.opacity(0.12) : .clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(isSelected ? color.opacity(0.4) : .clear, lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Streak achievement

struct AchievementDetailView: View {
    let achievement: Achievement
    private let accent = Color(hex: "B794F6")

    var body: some View {
        ZStack(alignment: .topTrailing) {
            BadgeDetailBackground(accent: accent)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    hero
                    if !achievement.isUnlocked { progressCard }
                    howCard
                }
                .padding(.horizontal, 20)
                .padding(.top, 36)
                .padding(.bottom, 40)
            }

            BadgeCloseButton()
                .padding(.top, 14)
                .padding(.trailing, 16)
        }
        .environment(\.colorScheme, .dark)
    }

    private var hero: some View {
        VStack(spacing: 12) {
            ZStack {
                if achievement.isUnlocked {
                    Circle().fill(accent.opacity(0.25)).frame(width: 200, height: 200).blur(radius: 40)
                }
                BadgeOctagonMark(icon: achievement.icon, number: nil, isUnlocked: achievement.isUnlocked,
                                 accent: accent, size: 150, assetName: achievement.badgeAssetName)
                    .shadow(color: achievement.isUnlocked ? accent.opacity(0.45) : .clear, radius: 24, y: 10)
            }
            .frame(height: 210)

            Text("achievement.detail.kind.streak".localized)
                .font(.faroSemiBold(12))
                .tracking(0.6)
                .foregroundStyle(accent)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(accent.opacity(0.14), in: Capsule())
                .overlay(Capsule().strokeBorder(accent.opacity(0.35), lineWidth: 1))

            Text(achievement.title)
                .font(.faroBold(28))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            Text(achievement.description)
                .font(.faroRegular(15))
                .foregroundStyle(.white.opacity(0.72))
                .multilineTextAlignment(.center)

            if let date = achievement.unlockedAt, achievement.isUnlocked {
                Label(String(format: "achievements.unlocked_date".localized, badgeDate(date)), systemImage: "checkmark.seal.fill")
                    .font(.faroRegular(14))
                    .foregroundStyle(accent)
            }
        }
    }

    private var progressCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            badgeCardTitle("badge.detail.progress_title")
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("\(achievement.progress)")
                    .font(.faroBold(34))
                    .foregroundStyle(.white)
                    .monospacedDigit()
                Text(String(format: "achievement.detail.days_of".localized, achievement.requirement))
                    .font(.faroRegular(15))
                    .foregroundStyle(.white.opacity(0.6))
            }
            BadgeProgressBar(value: achievement.progressPercentage, accent: accent)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cfGlass(cornerRadius: 22)
    }

    private var howCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            badgeCardTitle("badge.detail.how_title")
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(accent)
                    .frame(width: 38, height: 38)
                    .background(accent.opacity(0.14), in: Circle())
                Text("achievement.how.streak".localized)
                    .font(.faroRegular(15))
                    .foregroundStyle(.white.opacity(0.9))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cfGlass(cornerRadius: 22)
    }
}
