//
//  AchievementBadge.swift
//  CortiFree
//
//  Component for displaying a single achievement badge
//

import SwiftUI

struct AchievementBadge: View {
    let achievement: Achievement
    let size: BadgeSize

    @State private var isPressed = false
    @State private var triggerShake = false

    enum BadgeSize {
        case small // 50x50
        case medium // 60x60 (uniformisé)
        case large // 120x120

        var dimension: CGFloat {
            switch self {
            case .small: return 50
            case .medium: return 60
            case .large: return 120
            }
        }

        var iconSize: CGFloat {
            switch self {
            case .small: return 20
            case .medium: return 24
            case .large: return 48
            }
        }

        var titleSize: CGFloat {
            switch self {
            case .small: return 10
            case .medium: return 11
            case .large: return 16
            }
        }
    }

    var body: some View {
        Button(action: {
            if achievement.isUnlocked {
                HapticManager.light()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isPressed = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isPressed = false
                    }
                }
            } else {
                HapticManager.error()
                triggerShake.toggle()
            }
        }) {
            VStack(spacing: 6) {
                // Badge circle (NO GLOW)
                ZStack {
                // Background circle
                Circle()
                    .fill(
                        achievement.isUnlocked ?
                        LinearGradient(
                            colors: [
                                categoryColor.opacity(0.3),
                                categoryColor.opacity(0.15)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            colors: [Color.white.opacity(0.05), Color.white.opacity(0.02)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: size.dimension, height: size.dimension)

                // Icon
                Image(systemName: achievement.icon)
                    .font(.system(size: size.iconSize, weight: .semibold))
                    .foregroundColor(achievement.isUnlocked ? categoryColor : .white.opacity(0.3))

                // Lock overlay for locked badges
                if !achievement.isUnlocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: size.iconSize * 0.5))
                        .foregroundColor(.white.opacity(0.5))
                        .offset(x: size.dimension * 0.25, y: size.dimension * 0.25)
                }
            }

            // Title (only for medium/large)
            if size != .small {
                Text(achievement.title)
                    .font(.custom("Poppins-Medium", size: size.titleSize))
                    .foregroundColor(achievement.isUnlocked ? .white : .white.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .frame(maxWidth: size.dimension + 20)
            }

            // Progress text - ALWAYS show for streaks, locked at requirement when unlocked
            if size != .small {
                let displayProgress = achievement.isUnlocked ? achievement.requirement : achievement.progress
                Text("\(displayProgress)/\(achievement.requirement) Jours")
                    .font(.custom("Poppins-Regular", size: 10))
                    .foregroundColor(.white.opacity(achievement.isUnlocked ? 0.7 : 0.5))
            }
        }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 1.1 : 1.0)
        .shake(trigger: triggerShake)
    }

    private var categoryColor: Color {
        switch achievement.category {
        case .streak:
            return Color(hex: "FF8800") // Orange
        case .completion:
            return Color(hex: "2ECC71") // Green
        case .habit:
            return Color(hex: "B794F6") // Purple
        case .special:
            return Color(hex: "E74C3C") // Red
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 40) {
            HStack(spacing: 20) {
                // Unlocked
                AchievementBadge(
                    achievement: Achievement(
                        id: "test1",
                        title: "Test Badge",
                        description: "Test",
                        icon: "star.fill",
                        category: .streak,
                        requirement: 1,
                        progress: 1,
                        unlockedAt: Date()
                    ),
                    size: .large
                )

                // Locked with progress
                AchievementBadge(
                    achievement: Achievement(
                        id: "test2",
                        title: "Locked Badge",
                        description: "Test",
                        icon: "flame.fill",
                        category: .streak,
                        requirement: 10,
                        progress: 5
                    ),
                    size: .large
                )
            }

            HStack(spacing: 20) {
                AchievementBadge(
                    achievement: Achievement.allAchievements[0],
                    size: .medium
                )

                AchievementBadge(
                    achievement: Achievement.allAchievements[1],
                    size: .medium
                )

                AchievementBadge(
                    achievement: Achievement.allAchievements[2],
                    size: .medium
                )
            }
        }
    }
}
