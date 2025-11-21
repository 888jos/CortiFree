//
//  MilestoneCelebrationView.swift
//  CortiFree
//
//  Full-screen celebration for day milestones (7, 21, 33, 66)
//

import SwiftUI

struct MilestoneCelebrationView: View {
    let milestone: Milestone
    let onDismiss: () -> Void

    @State private var titleScale: CGFloat = 0.5
    @State private var titleOpacity: Double = 0
    @State private var badgeScale: CGFloat = 0.5
    @State private var badgeOpacity: Double = 0
    @State private var bonusScale: CGFloat = 0
    @State private var bonusOpacity: Double = 0
    @State private var descriptionOffset: CGFloat = 50
    @State private var showConfetti = false
    @State private var particleOffset: CGFloat = 0

    var body: some View {
        ZStack {
            // Background
            GalaxyBackgroundView(intensity: 1.5)
                .ignoresSafeArea()

            // Confetti
            if showConfetti {
                ConfettiAnimation(trigger: showConfetti)
            }

            // Floating particles
            ZStack {
                ForEach(0..<20, id: \.self) { index in
                    Circle()
                        .fill(milestoneColor.opacity(0.3))
                        .frame(width: CGFloat.random(in: 4...12))
                        .offset(
                            x: CGFloat.random(in: -200...200),
                            y: particleOffset + CGFloat.random(in: -400...400)
                        )
                        .blur(radius: 2)
                }
            }

            // Content
            VStack(spacing: 32) {
                Spacer()

                // Milestone day number
                VStack(spacing: 8) {
                    Text("Day \(milestone.day)")
                        .font(.custom("HankenGrotesk-ExtraBold", size: 72))
                        .foregroundColor(milestoneColor)
                        .shadow(color: milestoneColor.opacity(0.8), radius: 20, x: 0, y: 0)

                    Text("Milestone Reached!")
                        .font(.custom("HankenGrotesk-Bold", size: 28))
                        .foregroundColor(.white)
                }
                .scaleEffect(titleScale)
                .opacity(titleOpacity)

                // Milestone badge (if exists)
                if let badgeId = milestone.badgeId,
                   let achievement = Achievement.allAchievements.first(where: { $0.id == badgeId }) {
                    ZStack {
                        // Glow
                        Circle()
                            .fill(milestoneColor)
                            .frame(width: 200, height: 200)
                            .blur(radius: 40)
                            .opacity(0.6)

                        // Badge
                        AchievementBadge(
                            achievement: achievement,
                            size: .large
                        )
                    }
                    .scaleEffect(badgeScale)
                    .opacity(badgeOpacity)
                }

                // Milestone info
                VStack(spacing: 16) {
                    // Title
                    Text(milestone.title)
                        .font(.custom("Poppins-Bold", size: 24))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    // Description
                    Text(milestone.description)
                        .font(.custom("Poppins-Regular", size: 16))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)

                    // Score bonus
                    HStack(spacing: 12) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 24))
                            .foregroundColor(Color(hex: "F39C12"))

                        Text("+\(Int(milestone.scoreBonus)) Score Bonus")
                            .font(.custom("Poppins-Bold", size: 20))
                            .foregroundColor(Color(hex: "F39C12"))

                        Image(systemName: "star.fill")
                            .font(.system(size: 24))
                            .foregroundColor(Color(hex: "F39C12"))
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(hex: "F39C12").opacity(0.2))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color(hex: "F39C12"), lineWidth: 2)
                            )
                    )
                    .scaleEffect(bonusScale)
                    .opacity(bonusOpacity)
                }
                .offset(y: descriptionOffset)
                .opacity(descriptionOffset == 0 ? 1 : 0)

                // Personalized message
                Text(getPersonalizedMessage())
                    .font(.custom("Poppins-MediumItalic", size: 15))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .offset(y: descriptionOffset)
                    .opacity(descriptionOffset == 0 ? 0.7 : 0)

                Spacer()

                // Action buttons
                VStack(spacing: 12) {
                    // Continue button
                    Button(action: {
                        HapticManager.light()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            titleScale = 0.5
                            titleOpacity = 0
                            badgeScale = 0.5
                            badgeOpacity = 0
                            descriptionOffset = 50
                        }

                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            onDismiss()
                        }
                    }) {
                        Text("Continue Your Journey")
                            .font(.custom("Poppins-SemiBold", size: 18))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                milestoneColor,
                                                milestoneColor.opacity(0.8)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .shadow(color: milestoneColor.opacity(0.5), radius: 16, x: 0, y: 8)
                            )
                    }

                    // Share button
                    Button(action: {
                        HapticManager.light()
                        shareAchievement()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 16, weight: .semibold))

                            Text("Share Achievement")
                                .font(.custom("Poppins-SemiBold", size: 16))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.15))
                        )
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            startAnimations()
        }
    }

    private var milestoneColor: Color {
        switch milestone.day {
        case 7:
            return Color(hex: "FF8800") // Orange - Week Warrior
        case 21:
            return Color(hex: "9B59B6") // Purple - Three Weeks Strong
        case 33:
            return Color(hex: "F39C12") // Gold - Halfway Hero
        case 66:
            return Color(hex: "2ECC71") // Green - Graduate
        default:
            return Color(hex: "B794F6") // Default purple
        }
    }

    private func getPersonalizedMessage() -> String {
        switch milestone.day {
        case 7:
            return "You've completed your first week! This is just the beginning of your transformation."
        case 21:
            return "Three weeks in! You're building lasting habits that will transform your life."
        case 33:
            return "Halfway there! Your dedication and consistency are truly inspiring."
        case 66:
            return "Congratulations, graduate! You've completed the full journey. These habits are now part of who you are."
        default:
            return "Keep up the amazing work! Every day brings you closer to your goals."
        }
    }

    private func startAnimations() {
        // Trigger haptics
        HapticManager.success()

        // Title animation
        withAnimation(.spring(response: 0.7, dampingFraction: 0.6)) {
            titleScale = 1.0
            titleOpacity = 1.0
        }

        // Badge animation (delayed)
        withAnimation(.spring(response: 0.7, dampingFraction: 0.6).delay(0.3)) {
            badgeScale = 1.0
            badgeOpacity = 1.0
        }

        // Bonus animation (delayed)
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.6)) {
            bonusScale = 1.0
            bonusOpacity = 1.0
        }

        // Description animation
        withAnimation(.easeOut(duration: 0.8).delay(0.8)) {
            descriptionOffset = 0
        }

        // Confetti
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showConfetti = true
        }

        // Floating particles animation
        withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
            particleOffset = -800
        }
    }

    private func shareAchievement() {
        let text = "🎉 I just reached Day \(milestone.day) in my wellness journey with CortiFree! \(milestone.title)"

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            return
        }

        let activityVC = UIActivityViewController(
            activityItems: [text],
            applicationActivities: nil
        )

        // For iPad
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = window
            popover.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }

        rootViewController.present(activityVC, animated: true)
    }
}

#Preview {
    MilestoneCelebrationView(
        milestone: Milestone(
            id: "milestone_7",
            day: 7,
            title: "Week Warrior",
            description: "You've completed your first week of transformation!",
            scoreBonus: 50,
            badgeId: "week_warrior"
        ),
        onDismiss: {}
    )
}
