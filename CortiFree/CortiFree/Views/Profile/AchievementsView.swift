//
//  AchievementsView.swift
//  CortiFree
//
//  Gallery view for browsing all achievements
//

import SwiftUI

struct AchievementsView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var achievementService = AchievementService.shared
    @ObservedObject private var habitBadgeService = HabitBadgeService.shared

    @State private var selectedAchievement: Achievement? = nil
    @State private var selectedHabitBadge: HabitBadge? = nil
    #if DEBUG
    @State private var debugAllBadgesUnlocked = true
    #endif

    var body: some View {
        ZStack {
            GalaxyBackgroundView(intensity: 0.65)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Achievements")
                            .font(.faroBold(28))
                            .foregroundColor(.white)

                        Text("\(achievementService.unlockedCount)/\(achievementService.totalCount) Unlocked")
                            .font(.faroRegular(13))
                            .foregroundColor(.white.opacity(0.62))
                    }

                    Spacer()

                    Button {
                        HapticManager.light()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 18)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        summaryCard

                        Text("Streaks")
                            .font(.faroSemiBold(19))
                            .foregroundColor(.white)

                        LazyVGrid(
                            columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3),
                            spacing: 10
                        ) {
                            ForEach(achievementService.achievements) { achievement in
                                AchievementBadge(
                                    achievement: achievement,
                                    size: .gallery,
                                    onTap: { selectedAchievement = achievement },
                                    usesEnglishLabels: true
                                )
                                .frame(maxWidth: .infinity)
                            }
                        }

                        Text("Habits")
                            .font(.faroSemiBold(19))
                            .foregroundColor(.white)
                            .padding(.top, 8)

                        VStack(spacing: 22) {
                            ForEach(HabitBadge.allHabitIds, id: \.self) { habitId in
                                habitBadgeSection(for: habitId)
                            }
                        }

                        #if DEBUG
                        Button {
                            HapticManager.light()
                            debugAllBadgesUnlocked.toggle()
                            achievementService.setAllUnlockedForDebug(debugAllBadgesUnlocked)
                            habitBadgeService.setAllUnlockedForDebug(debugAllBadgesUnlocked)
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: debugAllBadgesUnlocked ? "lock.fill" : "checkmark.seal.fill")
                                    .font(.system(size: 14, weight: .semibold))
                                Text(
                                    debugAllBadgesUnlocked
                                        ? "Show all locked"
                                        : "Show all unlocked"
                                )
                                .font(.faroSemiBold(13))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 46)
                            .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
                            .overlay {
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(.white.opacity(0.16), lineWidth: 1)
                            }
                        }
                        .buttonStyle(.plain)
                        #endif
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 36)
                }
            }
        }
        .fullScreenCover(item: $selectedAchievement) { achievement in
            AchievementDetailView(achievement: achievement)
        }
        .sheet(item: $selectedHabitBadge) { badge in
            BadgeDetailSheet(
                badge: badge,
                currentProgress: habitBadgeService.badges(for: badge.habitId).map(\.progress).max() ?? badge.progress,
                usesEnglishLabels: true
            )
        }
        .task {
            await achievementService.loadAchievements()
            await habitBadgeService.loadHabitBadges()
            #if DEBUG
            achievementService.setAllUnlockedForDebug(true)
            habitBadgeService.setAllUnlockedForDebug(true)
            debugAllBadgesUnlocked = true
            #endif
        }
    }

    private var summaryCard: some View {
        HStack(spacing: 0) {
            summaryValue(
                "\(totalUnlockedCount)",
                label: "Unlocked"
            )
            Divider().overlay(.white.opacity(0.12)).frame(height: 46)
            summaryValue(
                "\(totalBadgeCount)",
                label: "Total"
            )
            Divider().overlay(.white.opacity(0.12)).frame(height: 46)
            summaryValue(
                "\(Int((globalCompletionPercentage * 100).rounded()))%",
                label: "Complete"
            )
        }
        .padding(.vertical, 18)
        .background(Color(hex: "49288C").opacity(0.30))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(.white.opacity(0.08), lineWidth: 1))
    }

    private func summaryValue(_ value: String, label: String) -> some View {
        VStack(spacing: 5) {
            Text(value)
                .font(.faroBold(25))
                .foregroundColor(.white)
            Text(label)
                .font(.faroRegular(11))
                .foregroundColor(.white.opacity(0.58))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func habitBadgeSection(for habitId: String) -> some View {
        let badges = habitBadgeService.badges(for: habitId)
        let progress = badges.map(\.progress).max() ?? 0
        let total = badges.map(\.requirement).max() ?? 0

        VStack(alignment: .leading, spacing: 12) {
            HStack {
            Label(HabitBadge.englishHabitDisplayName(habitId), systemImage: HabitBadge.habitIcon(habitId))
                    .font(.faroSemiBold(14))
                    .foregroundColor(.white)

                Spacer()

                Text("\(progress)/\(total)")
                    .font(.faroRegular(11))
                    .foregroundColor(.white.opacity(0.55))
            }

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4),
                spacing: 8
            ) {
                ForEach(badges.sorted { $0.level.percentage < $1.level.percentage }) { badge in
                    HabitBadgeGalleryItem(badge: badge) {
                        selectedHabitBadge = badge
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var totalUnlockedCount: Int {
        achievementService.unlockedCount + habitBadgeService.unlockedBadgesCount
    }

    private var totalBadgeCount: Int {
        achievementService.totalCount + habitBadgeService.totalBadgesCount
    }

    private var globalCompletionPercentage: Double {
        guard totalBadgeCount > 0 else { return 0 }
        return Double(totalUnlockedCount) / Double(totalBadgeCount)
    }
}

private struct HabitBadgeGalleryItem: View {
    let badge: HabitBadge
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                BadgeOctagonMark(
                    icon: HabitBadge.habitIcon(badge.habitId),
                    number: nil,
                    isUnlocked: badge.isUnlocked,
                    accent: Color(hex: badge.level.color),
                    size: 64,
                    assetName: badge.badgeAssetName
                )

                Text("\(badge.requirement)")
                    .font(.faroRegular(10))
                    .foregroundColor(badge.isUnlocked ? .white : .white.opacity(0.45))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Category Filter Button

struct CategoryFilterButton: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticManager.light()
            action()
        }) {
            Text(title)
                .font(.custom("Poppins-SemiBold", size: 14))
                .foregroundColor(isSelected ? .white : .white.opacity(0.6))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? color : Color.white.opacity(0.1))
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Achievement Detail View

struct AchievementDetailView: View {
    @Environment(\.dismiss) var dismiss
    let achievement: Achievement

    var body: some View {
        ZStack {
            GalaxyBackgroundView(intensity: 0.55)

            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button {
                        HapticManager.light()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)

                Spacer(minLength: 30)

                badgeVisual
                    .frame(width: 190, height: 190)

                Text(achievement.isUnlocked ? "Achievement Unlocked!" : "Not started yet")
                    .font(.faroSemiBold(12))
                    .foregroundColor(.white.opacity(0.58))
                    .textCase(.uppercase)
                    .padding(.top, 28)

                Text(achievement.englishTitle)
                    .font(.faroBold(30))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.top, 10)

                Text(achievement.englishDescription)
                    .font(.faroRegular(15))
                    .foregroundColor(.white.opacity(0.72))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.top, 12)

                if achievement.isUnlocked, let unlockedAt = achievement.unlockedAt {
                    Label(
                        "Unlocked on \(formatDate(unlockedAt))",
                        systemImage: "checkmark.circle.fill"
                    )
                    .font(.faroRegular(13))
                    .foregroundColor(.white.opacity(0.68))
                    .padding(.top, 18)
                } else {
                    VStack(spacing: 9) {
                        Text("Progress: \(achievement.progress)/\(achievement.requirement)")
                            .font(.faroSemiBold(13))
                            .foregroundColor(.white)

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.white.opacity(0.1))

                                Capsule()
                                    .fill(Color(hex: "B794F6"))
                                    .frame(width: geo.size.width * achievement.progressPercentage)
                            }
                        }
                        .frame(height: 7)
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 18)
                }

                Spacer()
            }
        }
    }

    @ViewBuilder
    private var badgeVisual: some View {
        ZStack {
            BadgeOctagonShape()
                .fill(achievement.isUnlocked ? Color(hex: "B794F6").opacity(0.24) : Color.white.opacity(0.08))
                .overlay {
                    BadgeOctagonShape()
                        .stroke(achievement.isUnlocked ? Color(hex: "B794F6").opacity(0.72) : Color.white.opacity(0.22), lineWidth: 3)
                }

            if let assetName = achievement.badgeAssetName {
                Image(assetName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 132, height: 132)
                    .saturation(achievement.isUnlocked ? 1 : 0)
                    .opacity(achievement.isUnlocked ? 1 : 0.28)
            } else {
                Image(systemName: achievement.icon)
                    .font(.system(size: 82, weight: .semibold))
                    .foregroundColor(.white.opacity(achievement.isUnlocked ? 1 : 0.28))
            }

            if !achievement.isUnlocked {
                Image(systemName: "lock.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white.opacity(0.72))
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

#Preview {
    AchievementsView()
}
