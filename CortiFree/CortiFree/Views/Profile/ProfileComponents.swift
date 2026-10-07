//
//  ProfileComponents.swift
//  CortiFree
//
//  Created on 21/01/2026.
//  Extracted from ProfileView for better modularity
//

import SwiftUI

// MARK: - Horizontal Habit Bar Component

struct HorizontalHabitBar: View {
    let icon: String
    let title: String
    let progress: Double
    let color: Color
    let completed: Int
    let total: Int
    let animationTrigger: Bool

    @State private var animatedProgress: Double = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header: Icon + Title + Progress
            HStack(spacing: 8) {
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color)
                    .frame(width: 24)

                // Title
                Text(title)
                    .font(.custom("Poppins-Medium", size: 13))
                    .foregroundColor(.white)

                Spacer()

                // Progress as completed/total
                Text("\(completed)/\(total)")
                    .font(Font.Poppins.custom(.bold, size: 13))
                    .foregroundColor(.white.opacity(0.8))
            }

            // Horizontal progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Background bar
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 8)

                    // Progress fill with animation
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [
                                    color.opacity(0.8),
                                    color
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * animatedProgress, height: 8)
                }
            }
            .frame(height: 8)
        }
        .padding(14)
        .glassCard(cornerRadius: 16)
        .onChange(of: progress) { _, newProgress in
            // Data loads asynchronously; animate to the new value when visible
            guard animationTrigger else { return }
            withAnimation(.spring(response: 0.8, dampingFraction: 0.75)) {
                animatedProgress = newProgress
            }
        }
        .onChange(of: animationTrigger) { oldValue, newValue in
            // Reset and animate when tab becomes visible
            if newValue {
                animatedProgress = 0
                withAnimation(.spring(response: 0.8, dampingFraction: 0.75).delay(0.15)) {
                    animatedProgress = progress
                }
            }
        }
        .onAppear {
            if animationTrigger {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.75).delay(0.15)) {
                    animatedProgress = progress
                }
            }
        }
    }
}

// MARK: - Single Evolving Habit Badge Component

struct SingleEvolvingHabitBadge: View {
    let habitId: String
    let badges: [HabitBadge]
    let currentProgress: Int
    let totalTasks: Int

    @State private var showDetail = false

    // Find the highest unlocked badge or the next one to unlock
    private var displayBadge: HabitBadge {
        // First check if any badge is unlocked, return highest unlocked
        let unlockedBadges = badges.filter { $0.isUnlocked }.sorted { $0.level.percentage > $1.level.percentage }
        if let highestUnlocked = unlockedBadges.first {
            return highestUnlocked
        }
        // Otherwise return the first locked badge (bronze)
        if let firstBadge = badges.sorted(by: { $0.level.percentage < $1.level.percentage }).first {
            return firstBadge
        }
        // Fallback: create default bronze badge if badges array is empty
        return HabitBadge(id: "\(habitId)_bronze", habitId: habitId, level: .bronze, requirement: 1, progress: 0, unlockedAt: nil)
    }

    var body: some View {
        VStack(spacing: 6) {
            BadgeOctagonMark(
                icon: HabitBadge.habitIcon(habitId),
                number: nil,
                isUnlocked: displayBadge.isUnlocked,
                accent: Color(hex: displayBadge.level.color),
                size: 60,
                assetName: displayBadge.badgeAssetName
            )

            // Habit name
            Text(HabitBadge.habitDisplayName(habitId))
                .font(.custom("Poppins-Medium", size: 11))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            // Progress
            Text("\(currentProgress)/\(totalTasks)")
                .font(.custom("Poppins-Regular", size: 10))
                .foregroundColor(.white.opacity(0.6))
        }
        .onTapGesture {
            HapticManager.light()
            showDetail = true
        }
        .sheet(isPresented: $showDetail) {
            HabitBadgeDetailSheet(
                habitId: habitId,
                badges: badges,
                currentProgress: currentProgress,
                totalTasks: totalTasks
            )
        }
    }
}

// MARK: - Habit Badge Detail Sheet

struct HabitBadgeDetailSheet: View {
    let habitId: String
    let badges: [HabitBadge]
    let currentProgress: Int
    let totalTasks: Int

    @Environment(\.dismiss) var dismiss

    // Find current level
    private var currentBadge: HabitBadge {
        let unlockedBadges = badges.filter { $0.isUnlocked }.sorted { $0.level.percentage > $1.level.percentage }
        if let highestUnlocked = unlockedBadges.first {
            return highestUnlocked
        }
        if let firstBadge = badges.sorted(by: { $0.level.percentage < $1.level.percentage }).first {
            return firstBadge
        }
        // Fallback: create default bronze badge if badges array is empty
        return HabitBadge(id: "\(habitId)_bronze", habitId: habitId, level: .bronze, requirement: 1, progress: 0, unlockedAt: nil)
    }

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color(hex: "1A1B3A"),
                    Color(hex: "0D0E1F")
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Large current badge
                    ZStack {
                        BadgeOctagonMark(
                            icon: HabitBadge.habitIcon(habitId),
                            number: nil,
                            isUnlocked: currentBadge.isUnlocked,
                            accent: Color(hex: currentBadge.level.color),
                            size: 140,
                            assetName: currentBadge.badgeAssetName
                        )
                    }
                    .padding(.top, 40)

                    // Title
                    VStack(spacing: 8) {
                        Text(HabitBadge.habitDisplayName(habitId))
                            .font(.custom("Poppins-Bold", size: 28))
                            .foregroundColor(.white)

                        Text(currentBadge.level.displayName)
                            .font(.custom("Poppins-SemiBold", size: 18))
                            .foregroundColor(Color(hex: currentBadge.level.color))
                    }

                    // All 4 levels progress
                    VStack(spacing: 16) {
                        ForEach(badges.sorted(by: { $0.level.percentage < $1.level.percentage })) { badge in
                            HStack(spacing: 12) {
                                BadgeOctagonMark(
                                    icon: HabitBadge.habitIcon(habitId),
                                    number: nil,
                                    isUnlocked: badge.isUnlocked,
                                    accent: Color(hex: badge.level.color),
                                    size: 30,
                                    assetName: badge.badgeAssetName
                                )

                                // Level name
                                Text(badge.level.displayName)
                                    .font(.custom("Poppins-Medium", size: 14))
                                    .foregroundColor(.white)
                                    .frame(width: 80, alignment: .leading)

                                // Progress bar
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color.white.opacity(0.1))
                                            .frame(height: 8)

                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(
                                                LinearGradient(
                                                    colors: [Color(hex: badge.level.color), Color(hex: badge.level.color).opacity(0.7)],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                            .frame(
                                                width: geo.size.width * min(Double(currentProgress) / Double(badge.requirement), 1.0),
                                                height: 8
                                            )
                                    }
                                }
                                .frame(height: 8)

                                // Requirement
                                Text("\(currentProgress)/\(badge.requirement)")
                                    .font(Font.Poppins.custom(.bold, size: 12))
                                    .foregroundColor(badge.isUnlocked ? .white : .white.opacity(0.5))
                                    .frame(width: 50, alignment: .trailing)

                                // Check or lock
                                Image(systemName: badge.isUnlocked ? "checkmark.circle.fill" : "lock.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(badge.isUnlocked ? Color(hex: badge.level.color) : .white.opacity(0.3))
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                    .padding(.vertical, 20)
                    .glassCard(cornerRadius: 22)
                    .padding(.horizontal, 16)

                    // Close button
                    Button(action: {
                        HapticManager.light()
                        dismiss()
                    }) {
                        Text("achievements.close".localized)
                            .font(.custom("Poppins-SemiBold", size: 16))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    }
                    .buttonStyle(.glassPrimary)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 40)
                }
            }
        }
    }
}
