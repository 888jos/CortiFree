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
    @State private var debugAllBadgesUnlocked = false
    #endif

    var body: some View {
        ZStack {
            GalaxyBackgroundView(intensity: 0.65)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("achievements.title".localized)
                            .font(.faroBold(28))
                            .foregroundColor(.white)

                        Text(String(format: "achievements.unlocked_count".localized, achievementService.unlockedCount, achievementService.totalCount))
                            .font(.faroRegular(13))
                            .foregroundColor(.white.opacity(0.62))
                    }

                    Spacer()

                    Button {
                        HapticManager.light()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .contentShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .glassCircle(interactive: true)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 18)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        summaryCard

                        Text("achievements.streaks".localized)
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
                                    usesEnglishLabels: false
                                )
                                .frame(maxWidth: .infinity)
                            }
                        }

                        Text("achievements.habits".localized)
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
                        }
                        .buttonStyle(.glassSecondary(cornerRadius: 14))
                        #endif
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 36)
                }
            }
        }
        .sheet(item: $selectedAchievement) { achievement in
            AchievementDetailView(achievement: achievement)
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $selectedHabitBadge) { badge in
            HabitBadgeDetailView(habitId: badge.habitId, focusedLevel: badge.level)
                .presentationDragIndicator(.visible)
        }
        .task {
            // Real progress, also in debug builds: the debug button below can still force a state.
            await achievementService.loadAchievements()
            await habitBadgeService.loadHabitBadges()
        }
    }

    private var summaryCard: some View {
        HStack(spacing: 0) {
            summaryValue(
                "\(totalUnlockedCount)",
                label: "achievements.summary.unlocked".localized
            )
            Divider().overlay(.white.opacity(0.12)).frame(height: 46)
            summaryValue(
                "\(totalBadgeCount)",
                label: "achievements.summary.total".localized
            )
            Divider().overlay(.white.opacity(0.12)).frame(height: 46)
            summaryValue(
                "\(Int((globalCompletionPercentage * 100).rounded()))%",
                label: "achievements.summary.complete".localized
            )
        }
        .padding(.vertical, 18)
        .glassCard(cornerRadius: 22, tint: Color(hex: "49288C"))
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
        let next = HabitBadge.nextLevel(for: habitId, progress: progress)

        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(HabitBadge.habitDisplayName(habitId), systemImage: HabitBadge.habitIcon(habitId))
                    .font(.faroSemiBold(14))
                    .foregroundColor(.white)

                Spacer()

                Text(verbatim: next.map { "\(progress)/\($0.requirement)" } ?? "\(progress)")
                    .font(.faroSemiBold(12))
                    .foregroundColor(next.map { Color(hex: $0.level.color) } ?? .white.opacity(0.55))
                    .monospacedDigit()
            }

            if let next {
                Text(String(format: "achievements.habit.next".localized, next.level.displayName, max(0, next.requirement - progress)))
                    .font(.faroRegular(12))
                    .foregroundColor(.white.opacity(0.55))
            } else {
                Text("achievements.habit.done".localized)
                    .font(.faroRegular(12))
                    .foregroundColor(Color(hex: HabitBadge.BadgeLevel.diamond.color))
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
        .padding(16)
        .glassCard(cornerRadius: 22)
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
                .glassCapsule(tint: isSelected ? color : nil, interactive: true)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    AchievementsView()
}
