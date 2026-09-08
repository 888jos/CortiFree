//
//  AchievementBadge.swift
//  CortiFree
//
//  Component for displaying a single achievement badge
//

import SwiftUI

struct BadgeOctagonShape: Shape {
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.height / 2, rect.width / sqrt(3))
        let horizontalRadius = radius * sqrt(3) / 2
        var path = Path()

        // Pointy-top regular hexagon: each of the six edges has the same length.
        path.move(to: CGPoint(x: center.x, y: center.y - radius))
        path.addLine(to: CGPoint(x: center.x + horizontalRadius, y: center.y - radius / 2))
        path.addLine(to: CGPoint(x: center.x + horizontalRadius, y: center.y + radius / 2))
        path.addLine(to: CGPoint(x: center.x, y: center.y + radius))
        path.addLine(to: CGPoint(x: center.x - horizontalRadius, y: center.y + radius / 2))
        path.addLine(to: CGPoint(x: center.x - horizontalRadius, y: center.y - radius / 2))
        path.closeSubpath()
        return path
    }
}

struct BadgeOctagonMark: View {
    let icon: String
    let number: String?
    let isUnlocked: Bool
    let accent: Color
    let size: CGFloat
    var assetName: String? = nil

    var body: some View {
        BadgeOctagonShape()
            .fill(isUnlocked ? accent.opacity(0.24) : Color.white.opacity(0.08))
            .overlay {
                BadgeOctagonShape()
                    .stroke(isUnlocked ? accent.opacity(0.72) : Color.white.opacity(0.22), lineWidth: 2)
            }
            .overlay {
                Group {
                    if let assetName {
                        Image(assetName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: size * 0.62, height: size * 0.62)
                            .saturation(isUnlocked ? 1 : 0)
                            .opacity(isUnlocked ? 1 : 0.3)
                    } else if let number {
                        Text(number)
                            .font(.faroBold(size * 0.34))
                            .minimumScaleFactor(0.55)
                    } else {
                        Image(systemName: icon)
                            .font(.system(size: size * 0.34, weight: .semibold))
                    }
                }
                .foregroundColor(isUnlocked ? .white : .white.opacity(0.32))
                .frame(width: size * 0.62, height: size * 0.62)
            }
            .overlay {
                if !isUnlocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: size * 0.18, weight: .semibold))
                        .foregroundColor(.white.opacity(0.72))
                }
            }
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

struct AchievementBadge: View {
    let achievement: Achievement
    let size: BadgeSize
    var onTap: (() -> Void)? = nil
    var usesEnglishLabels = true

    @State private var isPressed = false
    @State private var triggerShake = false

    enum BadgeSize {
        case small // 50x50
        case medium // 60x60 (uniformisé)
        case gallery // Larger hexagon without a surrounding card
        case large // 120x120

        var dimension: CGFloat {
            switch self {
            case .small: return 50
            case .medium: return 60
            case .gallery: return 92
            case .large: return 120
            }
        }

        var iconSize: CGFloat {
            switch self {
            case .small: return 20
            case .medium: return 24
            case .gallery: return 34
            case .large: return 48
            }
        }

        var titleSize: CGFloat {
            switch self {
            case .small: return 10
            case .medium: return 11
            case .gallery: return 12
            case .large: return 16
            }
        }
    }

    var body: some View {
        Button(action: {
            if let onTap {
                HapticManager.light()
                onTap()
                return
            }

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
                ZStack {
                    BadgeOctagonShape()
                        .fill(achievement.isUnlocked ? categoryColor.opacity(0.24) : Color.white.opacity(0.08))
                        .overlay {
                            BadgeOctagonShape()
                                .stroke(achievement.isUnlocked ? categoryColor.opacity(0.72) : Color.white.opacity(0.22), lineWidth: 2)
                        }

                    if let assetName = achievement.badgeAssetName {
                        Image(assetName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: size.dimension * 0.76, height: size.dimension * 0.76)
                            .clipped()
                            .saturation(achievement.isUnlocked ? 1 : 0)
                            .opacity(achievement.isUnlocked ? 1 : 0.28)
                    } else {
                        Image(systemName: achievement.icon)
                            .font(.system(size: size.iconSize, weight: .semibold))
                            .foregroundColor(achievement.isUnlocked ? .white : .white.opacity(0.3))
                    }

                    if !achievement.isUnlocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: size.iconSize * 0.42, weight: .semibold))
                            .foregroundColor(.white.opacity(0.72))
                    }
                }
                .frame(width: size.dimension, height: size.dimension)

            // Title (only for medium/large)
            if size != .small {
                Text(usesEnglishLabels ? achievement.englishTitle : achievement.title)
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
                Text("\(displayProgress)/\(achievement.requirement) \(usesEnglishLabels ? "Days" : "Jours")")
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
                        id: "streak_3",
                        titleKey: "achievement.streak_3.title",
                        descriptionKey: "achievement.streak_3.description",
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
                        id: "streak_7",
                        titleKey: "achievement.streak_7.title",
                        descriptionKey: "achievement.streak_7.description",
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
