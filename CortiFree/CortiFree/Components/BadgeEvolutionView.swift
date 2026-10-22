//
//  BadgeEvolutionView.swift
//  CortiFree
//
//  Célébration quand un badge d'habitude est débloqué (même carte que « Succès débloqué »)
//

import SwiftUI

struct BadgeEvolutionView: View {

    let badge: HabitBadge
    @Binding var isPresented: Bool
    @State private var appeared = false
    @State private var showBadge = false

    var body: some View {
        ZStack {
            // Same backdrop as the streak and achievement cards: the app slightly blurred.
            Rectangle()
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
                .opacity(appeared ? 0.55 : 0)
                .ignoresSafeArea()

            FullScreenConfetti()

            card
                .padding(.horizontal, 22)
                .scaleEffect(appeared ? 1 : 0.94)
                .opacity(appeared ? 1 : 0)
        }
        .onAppear {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { appeared = true }
            withAnimation(.spring(response: 0.55, dampingFraction: 0.65).delay(0.15)) { showBadge = true }
        }
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
    }

    /// Same layout as AchievementCelebrationView: title row, the badge beside its name, Continue.
    private var card: some View {
        VStack(spacing: 18) {
            HStack {
                Text("achievement.badge_unlocked".localized)
                    .font(.faroSemiBold(19))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer()
            }

            HStack(spacing: 16) {
                BadgeOctagonMark(
                    icon: HabitBadge.habitIcon(badge.habitId),
                    number: nil,
                    isUnlocked: true,
                    accent: Color(hex: badge.level.color),
                    size: 84,
                    assetName: badge.badgeAssetName
                )
                .shadow(color: Color(hex: badge.level.color).opacity(0.35), radius: 16, y: 6)
                .scaleEffect(showBadge ? 1 : 0.5)
                .opacity(showBadge ? 1 : 0)
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(badge.level.displayName)
                            .font(Font.Poppins.custom(.semiBold, size: 13))
                        HStack(spacing: 2) {
                            ForEach(0..<badge.level.starCount, id: \.self) { _ in
                                Image(systemName: "star.fill").font(.system(size: 10))
                            }
                        }
                    }
                    .foregroundStyle(Color(hex: badge.level.color))
                    Text(HabitBadge.habitDisplayName(badge.habitId))
                        .font(.faroBold(26))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text(String(format: "achievement.tasks_completed".localized, badge.requirement, HabitBadge.habitDisplayName(badge.habitId)))
                        .font(Font.Poppins.custom(.regular, size: 14))
                        .foregroundStyle(.white.opacity(0.65))
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }

            Button {
                HapticManager.light()
                withAnimation(.spring(response: 0.3)) { isPresented = false }
            } label: {
                Text("common.continue".localized)
                    .font(Font.Poppins.custom(.semiBold, size: 16))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .contentShape(Capsule())
            }
            .buttonStyle(.glassPrimary(tint: Color(hex: "9333EA")))
            .padding(.top, 2)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 20)
        .frame(maxWidth: 400)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(hex: "1A1030"))
                .shadow(color: .black.opacity(0.34), radius: 20, y: 12)
        )
    }
}

// MARK: - Preview

struct BadgeEvolutionView_Previews: PreviewProvider {
    static var previews: some View {
        BadgeEvolutionView(
            badge: HabitBadge(
                id: "meditation_gold",
                habitId: "meditation",
                level: .gold,
                requirement: 36,
                progress: 36,
                unlockedAt: Date()
            ),
            isPresented: .constant(true)
        )
    }
}
