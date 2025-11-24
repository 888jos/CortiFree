//
//  AchievementUnlockView.swift
//  CortiFree
//
//  Card-style popup celebration when an achievement is unlocked
//

import SwiftUI

struct AchievementUnlockView: View {
    let achievement: Achievement
    let onDismiss: () -> Void

    @State private var cardScale: CGFloat = 0.5
    @State private var cardOpacity: Double = 0
    @State private var backgroundOpacity: Double = 0
    @State private var badgeScale: CGFloat = 0.5
    @State private var glowRadius: CGFloat = 0
    @State private var showConfetti = false
    @State private var cardOffset: CGFloat = 100

    var body: some View {
        ZStack {
            // Semi-transparent background overlay
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .opacity(backgroundOpacity)
                .onTapGesture {
                    dismissCard()
                }

            // Confetti (full screen)
            if showConfetti {
                ConfettiAnimation(trigger: showConfetti)
                    .allowsHitTesting(false)
            }

            // Achievement Card
            VStack(spacing: 0) {
                // Badge section with glow
                ZStack {
                    // Glow effect
                    Circle()
                        .fill(categoryColor)
                        .frame(width: 140, height: 140)
                        .blur(radius: glowRadius)
                        .opacity(0.5)

                    // Badge
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        categoryColor.opacity(0.4),
                                        categoryColor.opacity(0.2)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)

                        Circle()
                            .stroke(categoryColor, lineWidth: 3)
                            .frame(width: 120, height: 120)

                        Image(systemName: achievement.icon)
                            .font(.system(size: 50, weight: .semibold))
                            .foregroundColor(categoryColor)
                    }
                    .scaleEffect(badgeScale)
                }
                .frame(height: 160)
                .padding(.top, 32)

                // Card content
                VStack(spacing: 16) {
                    // Title
                    Text("Achievement Unlocked!")
                        .font(Font.Poppins.custom(.bold, size: 22))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    // Achievement name
                    Text(achievement.title)
                        .font(.custom("Poppins-Bold", size: 20))
                        .foregroundColor(categoryColor)
                        .multilineTextAlignment(.center)

                    // Description
                    Text(achievement.description)
                        .font(.custom("Poppins-Regular", size: 14))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .padding(.horizontal, 24)

                    // Category badge
                    HStack(spacing: 6) {
                        Circle()
                            .fill(categoryColor)
                            .frame(width: 6, height: 6)

                        Text(categoryName)
                            .font(.custom("Poppins-Medium", size: 12))
                            .foregroundColor(categoryColor)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(categoryColor.opacity(0.2))
                    )
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 24)

                // Continue button
                Button(action: {
                    dismissCard()
                }) {
                    Text("Continue")
                        .font(.custom("Poppins-SemiBold", size: 16))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: AppConstants.Layout.cornerRadius)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            categoryColor,
                                            categoryColor.opacity(0.8)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            .frame(width: 340)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: "1A1A2E"),
                                Color(hex: "16213E")
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 28)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        categoryColor.opacity(0.6),
                                        categoryColor.opacity(0.2)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                    .shadow(color: categoryColor.opacity(0.4), radius: 30, x: 0, y: 15)
                    .shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: 10)
            )
            .scaleEffect(cardScale)
            .opacity(cardOpacity)
            .offset(y: cardOffset)
        }
        .onAppear {
            startAnimations()
        }
    }

    private func startAnimations() {
        HapticManager.success()

        // Background fade in
        withAnimation(.easeOut(duration: 0.25)) {
            backgroundOpacity = 1.0
        }

        // Card entrance
        withAnimation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.1)) {
            cardScale = 1.0
            cardOpacity = 1.0
            cardOffset = 0
        }

        // Badge pop
        withAnimation(.spring(response: 0.5, dampingFraction: 0.65).delay(0.35)) {
            badgeScale = 1.0
        }

        // Glow pulsing
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true).delay(0.5)) {
            glowRadius = 30
        }

        // Confetti
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showConfetti = true
        }
    }

    private func dismissCard() {
        HapticManager.light()

        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            cardScale = 0.8
            cardOpacity = 0
            cardOffset = 50
            backgroundOpacity = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onDismiss()
        }
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

    private var categoryName: String {
        switch achievement.category {
        case .streak:
            return "Streak"
        case .completion:
            return "Completion"
        case .habit:
            return "Habit"
        case .special:
            return "Special"
        }
    }
}

#Preview {
    AchievementUnlockView(
        achievement: Achievement(
            id: "week_warrior",
            title: "Week Warrior",
            description: "Complete 7 days in a row",
            icon: "flame.fill",
            category: .streak,
            requirement: 7,
            progress: 7,
            unlockedAt: Date()
        ),
        onDismiss: {}
    )
}
