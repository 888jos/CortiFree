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
                    Text(HabitBadge.englishHabitDisplayName(habitId))
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
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
        .sheet(isPresented: $showDetail) {
            if let badge = selectedBadge {
                BadgeDetailSheet(badge: badge, currentProgress: currentProgress)
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

// MARK: - Badge Detail Sheet

struct BadgeDetailSheet: View {

    let badge: HabitBadge
    let currentProgress: Int
    var usesEnglishLabels = true
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(hex: "1A1B3A"),
                    Color(hex: "0D0E1F")
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                // Large badge display
                ZStack {
                    BadgeOctagonMark(
                        icon: HabitBadge.habitIcon(badge.habitId),
                        number: nil,
                        isUnlocked: badge.isUnlocked,
                        accent: Color(hex: badge.level.color),
                        size: 120,
                        assetName: badge.badgeAssetName
                    )
                }

                // Title
                Text("\(habitName) - \(levelName)")
                    .font(.custom("Poppins-Bold", size: 24))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                // Status
                if badge.isUnlocked {
                    if let unlockedDate = badge.unlockedAt {
                        Text("Unlocked on \(formattedDate(unlockedDate))")
                            .font(.custom("Poppins-Regular", size: 14))
                            .foregroundColor(.white.opacity(0.7))
                    }
                } else {
                    VStack(spacing: 8) {
                        Text("\(currentProgress) / \(badge.requirement) tasks")
                            .font(.custom("Poppins-SemiBold", size: 16))
                            .foregroundColor(.white)

                        // Progress bar
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.white.opacity(0.1))

                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(hex: "B794F6"))
                                    .frame(width: geometry.size.width * badge.progressPercentage)
                            }
                        }
                        .frame(height: 12)
                        .frame(maxWidth: 200)

                        Text("\(max(0, badge.requirement - currentProgress)) tasks remaining")
                            .font(.custom("Poppins-Regular", size: 12))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }

                Spacer()

                // Close button
                Button(action: {
                    dismiss()
                }) {
                    Text("Close")
                        .font(.custom("Poppins-SemiBold", size: 16))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "B794F6"), Color(hex: "9B59B6")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 20)
            }
        }
    }

    private var habitName: String {
        usesEnglishLabels
            ? HabitBadge.englishHabitDisplayName(badge.habitId)
            : HabitBadge.habitDisplayName(badge.habitId)
    }

    private var levelName: String {
        usesEnglishLabels ? badge.level.englishDisplayName : badge.level.displayName
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = usesEnglishLabels
            ? Locale(identifier: "en_US_POSIX")
            : Locale.current
        return formatter.string(from: date)
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
