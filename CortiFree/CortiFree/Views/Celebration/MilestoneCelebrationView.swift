//
//  MilestoneCelebrationView.swift
//  CortiFree
//
//  One full-screen template for every milestone (achievement, habit badge): the real
//  artwork in a calm halo, a short overline, a Faro title, one line of context, a single
//  primary action. Brand colours only; the badge metal is a thin ring and a small pill.
//

import SwiftUI

struct MilestoneCelebrationView: View {
    struct Content {
        let overline: String
        let title: String
        let subtitle: String
        let imageName: String?
        let symbol: String
        /// Thin ring around the artwork (badge metal); brand accent otherwise.
        let ringColor: Color
        /// e.g. "Gold" for habit badges.
        let levelLabel: String?
        let shareText: String
    }

    let content: Content
    let onContinue: () -> Void

    @State private var appeared = false
    @State private var burst = false

    var body: some View {
        ZStack {
            PlanBackground(goal: nil)
            RadialGradient(colors: [PlanPalette.accent.opacity(0.28), .clear],
                           center: .init(x: 0.5, y: 0.36), startRadius: 10, endRadius: 320)
                .ignoresSafeArea()
                .opacity(appeared ? 1 : 0)

            VStack(spacing: 0) {
                Spacer(minLength: 40)

                artwork
                    .padding(.bottom, 36)

                Text(content.overline)
                    .font(Font.Poppins.custom(.semiBold, size: 12))
                    .tracking(1.4)
                    .textCase(.uppercase)
                    .foregroundStyle(PlanPalette.accent)
                    .padding(.bottom, 10)

                Text(content.title)
                    .font(.faroBold(32))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 10)

                Text(content.subtitle)
                    .font(Font.Poppins.custom(.regular, size: 15))
                    .foregroundStyle(PlanPalette.secondaryText)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 12)

                if let level = content.levelLabel {
                    HStack(spacing: 8) {
                        Circle().fill(content.ringColor).frame(width: 8, height: 8)
                        Text(level)
                            .font(Font.Poppins.custom(.medium, size: 13))
                            .foregroundStyle(.white.opacity(0.85))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(Capsule().fill(.white.opacity(0.08)))
                    .overlay(Capsule().strokeBorder(.white.opacity(0.10), lineWidth: 1))
                    .padding(.top, 18)
                }

                Spacer(minLength: 40)

                VStack(spacing: 14) {
                    Button {
                        HapticManager.light()
                        onContinue()
                    } label: {
                        Text("common.continue".localized)
                            .font(Font.Poppins.custom(.semiBold, size: 17))
                            .foregroundStyle(PlanPalette.deep)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Capsule().fill(PlanPalette.accent))
                    }
                    .buttonStyle(.plain)

                    ShareLink(item: content.shareText) {
                        Label("celebration.milestone.share".localized, systemImage: "square.and.arrow.up")
                            .font(Font.Poppins.custom(.medium, size: 15))
                            .foregroundStyle(.white.opacity(0.75))
                            .frame(height: 36)
                    }
                }
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 12)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 24)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.82)) { appeared = true }
            withAnimation(.easeOut(duration: 1.1).delay(0.2)) { burst = true }
        }
        .accessibilityElement(children: .contain)
    }

    private var artwork: some View {
        ZStack {
            // One-shot sparkle burst, in the brand accent only.
            ForEach(0..<10, id: \.self) { index in
                let angle = Double(index) / 10 * 2 * .pi
                Image(systemName: "sparkle")
                    .font(.system(size: index.isMultiple(of: 2) ? 12 : 8, weight: .semibold))
                    .foregroundStyle(PlanPalette.accent)
                    .offset(x: cos(angle) * (burst ? 150 : 60), y: sin(angle) * (burst ? 150 : 60))
                    .opacity(burst ? 0 : 0.9)
            }

            Circle()
                .fill(.white.opacity(0.05))
                .frame(width: 210, height: 210)
            Circle()
                .strokeBorder(content.ringColor.opacity(0.55), lineWidth: 1.5)
                .frame(width: 210, height: 210)
            Circle()
                .strokeBorder(.white.opacity(0.06), lineWidth: 1)
                .frame(width: 250, height: 250)

            Group {
                if let imageName = content.imageName, UIImage(named: imageName) != nil {
                    Image(imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 136, height: 136)
                } else {
                    Image(systemName: content.symbol)
                        .font(.system(size: 64, weight: .semibold))
                        .foregroundStyle(PlanPalette.accent)
                }
            }
            .scaleEffect(appeared ? 1 : 0.6)
        }
        .frame(height: 260)
        .accessibilityHidden(true)
    }
}

// MARK: - Content builders

extension MilestoneCelebrationView.Content {
    static func achievement(_ achievement: Achievement) -> Self {
        .init(
            overline: "achievement.unlocked".localized,
            title: achievement.title,
            subtitle: achievement.description,
            imageName: achievement.badgeAssetName,
            symbol: achievement.icon,
            ringColor: PlanPalette.accent,
            levelLabel: nil,
            shareText: String(format: "celebration.milestone.share_text".localized, achievement.title)
        )
    }

    static func badge(_ badge: HabitBadge) -> Self {
        let habit = HabitBadge.habitDisplayName(badge.habitId)
        return .init(
            overline: "achievement.badge_unlocked".localized,
            title: habit,
            subtitle: String(format: "achievement.tasks_completed".localized, badge.requirement, habit),
            imageName: "habit_badge_\(badge.habitId)",
            symbol: PlanItem.habitSymbol(badge.habitId),
            ringColor: Color(hex: badge.level.color),
            levelLabel: badge.level.displayName,
            shareText: String(format: "celebration.milestone.share_text".localized, "\(habit) · \(badge.level.displayName)")
        )
    }
}
