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
            HabitBadgeDetailView(habitId: habitId)
                .presentationDragIndicator(.visible)
        }
    }
}

