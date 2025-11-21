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

                    Text("\(currentProgress)/\(totalTasks) tâches")
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
            ZStack {
                // Badge circle
                Circle()
                    .fill(
                        badge.isUnlocked
                        ? LinearGradient(
                            colors: [
                                Color(hex: badge.level.color),
                                Color(hex: badge.level.color).opacity(0.7)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        : LinearGradient(
                            colors: [Color.white.opacity(0.1), Color.white.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)

                // Glow effect for unlocked badges
                if badge.isUnlocked {
                    Circle()
                        .stroke(Color(hex: badge.level.color).opacity(0.5), lineWidth: 2)
                        .frame(width: 54, height: 54)
                        .blur(radius: 4)
                }

                // Icon or Lock
                if badge.isUnlocked {
                    Text(badge.level.emoji)
                        .font(.system(size: 24))
                } else {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white.opacity(0.3))
                }
            }

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
                    // Glow
                    if badge.isUnlocked {
                        Circle()
                            .fill(Color(hex: badge.level.color).opacity(0.3))
                            .frame(width: 140, height: 140)
                            .blur(radius: 30)
                    }

                    // Badge
                    Circle()
                        .fill(
                            badge.isUnlocked
                            ? LinearGradient(
                                colors: [
                                    Color(hex: badge.level.color),
                                    Color(hex: badge.level.color).opacity(0.7)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(
                                colors: [Color.white.opacity(0.1), Color.white.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)

                    if badge.isUnlocked {
                        Text(badge.level.emoji)
                            .font(.system(size: 60))
                    } else {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 40, weight: .semibold))
                            .foregroundColor(.white.opacity(0.3))
                    }
                }

                // Title
                Text("\(HabitBadge.habitDisplayName(badge.habitId)) - \(badge.level.displayName)")
                    .font(.custom("Poppins-Bold", size: 24))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                // Status
                if badge.isUnlocked {
                    if let unlockedDate = badge.unlockedAt {
                        Text("Débloqué le \(formattedDate(unlockedDate))")
                            .font(.custom("Poppins-Regular", size: 14))
                            .foregroundColor(.white.opacity(0.7))
                    }
                } else {
                    VStack(spacing: 8) {
                        Text("\(currentProgress) / \(badge.requirement) tâches")
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

                        Text("Encore \(max(0, badge.requirement - currentProgress)) tâches")
                            .font(.custom("Poppins-Regular", size: 12))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }

                Spacer()

                // Close button
                Button(action: {
                    dismiss()
                }) {
                    Text("Fermer")
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

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "fr_FR")
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
