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

    @State private var selectedCategory: Achievement.AchievementCategory? = nil
    @State private var selectedAchievement: Achievement? = nil
    @State private var showDetail = false

    var body: some View {
        ZStack {
            // Background
            GalaxyBackgroundView(intensity: 1.0)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        HapticManager.light()
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(
                                Circle()
                                    .fill(Color.white.opacity(0.1))
                            )
                    }

                    Spacer()

                    VStack(spacing: 4) {
                        Text("Achievements")
                            .font(Font.Poppins.custom(.bold, size: 24))
                            .foregroundColor(.white)

                        Text("\(achievementService.unlockedCount)/\(achievementService.totalCount) Unlocked")
                            .font(.custom("Poppins-Regular", size: 14))
                            .foregroundColor(.white.opacity(0.7))
                    }

                    Spacer()

                    // Placeholder for symmetry
                    Color.clear
                        .frame(width: 40, height: 40)
                }
                .padding(.horizontal, 24)
                .padding(.top, 60)
                .padding(.bottom, 24)

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        // Background
                        Capsule()
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 8)

                        // Progress
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(hex: "B794F6"),
                                        Color(hex: "9B59B6")
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * achievementService.completionPercentage, height: 8)
                    }
                }
                .frame(height: 8)
                .padding(.horizontal, 40)
                .padding(.bottom, 24)

                // Category filters
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        CategoryFilterButton(
                            title: "All",
                            isSelected: selectedCategory == nil,
                            color: Color(hex: "B794F6")
                        ) {
                            selectedCategory = nil
                        }

                        CategoryFilterButton(
                            title: "Streak",
                            isSelected: selectedCategory == .streak,
                            color: Color(hex: "FF8800")
                        ) {
                            selectedCategory = .streak
                        }

                        CategoryFilterButton(
                            title: "Completion",
                            isSelected: selectedCategory == .completion,
                            color: Color(hex: "2ECC71")
                        ) {
                            selectedCategory = .completion
                        }

                        CategoryFilterButton(
                            title: "Habit",
                            isSelected: selectedCategory == .habit,
                            color: Color(hex: "B794F6")
                        ) {
                            selectedCategory = .habit
                        }


                        CategoryFilterButton(
                            title: "Special",
                            isSelected: selectedCategory == .special,
                            color: Color(hex: "E74C3C")
                        ) {
                            selectedCategory = .special
                        }
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 24)

                // Achievement grid
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 20),
                        GridItem(.flexible(), spacing: 20),
                        GridItem(.flexible(), spacing: 20)
                    ], spacing: 24) {
                        ForEach(filteredAchievements) { achievement in
                            Button(action: {
                                HapticManager.light()
                                selectedAchievement = achievement
                                showDetail = true
                            }) {
                                AchievementBadge(
                                    achievement: achievement,
                                    size: .medium
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
        }
        .sheet(isPresented: $showDetail) {
            if let achievement = selectedAchievement {
                AchievementDetailView(achievement: achievement)
            }
        }
    }

    private var filteredAchievements: [Achievement] {
        if let category = selectedCategory {
            return achievementService.achievements.filter { $0.category == category }
        }
        return achievementService.achievements
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
            // Background
            Color.black.opacity(0.9)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                // Large badge
                AchievementBadge(
                    achievement: achievement,
                    size: .large
                )

                // Details
                VStack(spacing: 12) {
                    Text(achievement.title)
                        .font(.custom("Poppins-Bold", size: 28))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    Text(achievement.description)
                        .font(.custom("Poppins-Regular", size: 16))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)

                    // Progress or unlock date
                    if achievement.isUnlocked, let unlockedAt = achievement.unlockedAt {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(Color(hex: "2ECC71"))

                            Text("Unlocked \(formatDate(unlockedAt))")
                                .font(.custom("Poppins-Medium", size: 14))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .padding(.top, 8)
                    } else if achievement.progress > 0 {
                        VStack(spacing: 8) {
                            Text("Progress: \(achievement.progress)/\(achievement.requirement)")
                                .font(.custom("Poppins-SemiBold", size: 16))
                                .foregroundColor(.white)

                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(Color.white.opacity(0.2))
                                        .frame(height: 8)

                                    Capsule()
                                        .fill(categoryColor)
                                        .frame(width: geo.size.width * achievement.progressPercentage, height: 8)
                                }
                            }
                            .frame(height: 8)
                            .padding(.horizontal, 40)
                        }
                        .padding(.top, 8)
                    } else {
                        Text("Not started yet")
                            .font(.custom("Poppins-Regular", size: 14))
                            .foregroundColor(.white.opacity(0.5))
                            .padding(.top, 8)
                    }
                }

                Spacer()

                // Dismiss button
                Button(action: {
                    HapticManager.light()
                    dismiss()
                }) {
                    Text("Close")
                        .font(.custom("Poppins-SemiBold", size: 16))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.15))
                        )
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
    }

    private var categoryColor: Color {
        switch achievement.category {
        case .streak:
            return Color(hex: "FF8800")
        case .completion:
            return Color(hex: "2ECC71")
        case .habit:
            return Color(hex: "B794F6")
        case .special:
            return Color(hex: "E74C3C")
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

#Preview {
    AchievementsView()
}
