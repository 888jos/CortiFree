//
//  HabitBadgeRow.swift
//  CortiFree
//
//  Affiche une ligne de 4 badges pour une habitude
//

import SwiftUI

struct HabitBadgeRow: View {

    let habitId: String
    let badges: [HabitBadge]
    let currentProgress: Int
    let totalTasks: Int

    @State private var selectedBadge: HabitBadge?
    @State private var showDetail = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 12) {
                // Habit icon
                Image(systemName: HabitBadge.habitIcon(habitId))
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Color(hex: "B794F6"))

                // Habit name and progress
                VStack(alignment: .leading, spacing: 2) {
                    Text(HabitBadge.habitDisplayName(habitId))
                        .font(.custom("Poppins-SemiBold", size: 16))
                        .foregroundColor(.white)

                    Text("\(currentProgress)/\(totalTasks) tasks")
                        .font(.custom("Poppins-Regular", size: 12))
                        .foregroundColor(.white.opacity(0.6))
                }

                Spacer()
            }

            // 4 Badges horizontaux
            HStack(spacing: 16) {
                ForEach(badges.sorted(by: { $0.level.percentage < $1.level.percentage })) { badge in
                    BadgeMiniView(badge: badge)
                        .onTapGesture {
                            selectedBadge = badge
                            showDetail = true
                        }
                }
            }
            .padding(.leading, 4)

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 6)

                    // Progress
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "B794F6"), Color(hex: "9B59B6")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: geometry.size.width * progressPercentage,
                            height: 6
                        )
                }
            }
            .frame(height: 6)
        }
        .padding(16)
        .glassCard(cornerRadius: 16)
        .sheet(isPresented: $showDetail) {
            if let badge = selectedBadge {
                HabitBadgeDetailView(habitId: badge.habitId, focusedLevel: badge.level)
            }
        }
    }

    private var progressPercentage: Double {
        guard totalTasks > 0 else { return 0 }
        return min(Double(currentProgress) / Double(totalTasks), 1.0)
    }
}

// MARK: - Badge Mini View

struct BadgeMiniView: View {

    let badge: HabitBadge

    var body: some View {
            VStack(spacing: 6) {
            BadgeOctagonMark(
                icon: HabitBadge.habitIcon(badge.habitId),
                number: nil,
                isUnlocked: badge.isUnlocked,
                accent: Color(hex: badge.level.color),
                size: 50,
                assetName: badge.badgeAssetName
            )

            // Requirement text
            Text("\(badge.requirement)")
                .font(.custom("Poppins-Medium", size: 10))
                .foregroundColor(badge.isUnlocked ? .white : .white.opacity(0.4))
        }
    }
}

// MARK: - Preview

struct HabitBadgeRow_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            HabitBadgeRow(
                habitId: "meditation",
                badges: HabitBadge.badgesForHabit("meditation"),
                currentProgress: 15,
                totalTasks: 47
            )
            .padding()
        }
    }
}
