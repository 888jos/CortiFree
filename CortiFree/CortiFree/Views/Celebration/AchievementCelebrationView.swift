//
//  AchievementCelebrationView.swift
//  CortiFree
//
//  Achievement unlocked: a compact card with the streak card's specs over the lightly
//  blurred app. The gold medal flips in with a single shine, confetti falls behind.
//

import SwiftUI

struct AchievementCelebrationView: View {
    let achievement: Achievement
    let onContinue: () -> Void

    @State private var appeared = false
    @State private var medalIn = false
    @State private var shine = false

    static let gold = Color(hex: "F6C453")
    static let goldDeep = Color(hex: "C98A1B")
    static let goldLight = Color(hex: "FFE7A6")

    var body: some View {
        ZStack {
            // Same backdrop as the streak card: the app stays visible, slightly blurred.
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
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { appeared = true }
            withAnimation(.spring(response: 0.55, dampingFraction: 0.65).delay(0.15)) { medalIn = true }
            withAnimation(.easeInOut(duration: 1.1).delay(0.7)) { shine = true }
        }
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
    }

    /// Same specs as the streak card (StreakCelebrationCard): dark violet panel, 24 pt corners,
    /// a title row with the pill, then the content.
    private var card: some View {
        VStack(spacing: 18) {
            HStack(alignment: .firstTextBaseline) {
                Text("achievement.unlocked".localized)
                    .font(.faroSemiBold(19))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer()
            }

            HStack(spacing: 16) {
                medal
                VStack(alignment: .leading, spacing: 4) {
                    Text(achievement.title)
                        .font(.faroBold(26))
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(achievement.description)
                        .font(Font.Poppins.custom(.regular, size: 14))
                        .foregroundStyle(.white.opacity(0.65))
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }

            Button {
                HapticManager.light()
                onContinue()
            } label: {
                Text("common.continue".localized)
                    .font(Font.Poppins.custom(.semiBold, size: 16))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .contentShape(Capsule())
            }
            .buttonStyle(.glassPrimary(tint: Color(hex: "9333EA")))
            .padding(.top, 2)

            ShareLink(item: String(format: "celebration.milestone.share_text".localized, achievement.title)) {
                Label("celebration.milestone.share".localized, systemImage: "square.and.arrow.up")
                    .font(Font.Poppins.custom(.medium, size: 14))
                    .foregroundStyle(.white.opacity(0.6))
            }
            .padding(.top, -4)
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

    // MARK: - Medal

    private var medal: some View {
        Circle()
            .fill(LinearGradient(colors: [Self.goldLight, Self.gold, Self.goldDeep], startPoint: .topLeading, endPoint: .bottomTrailing))
            .frame(width: 84, height: 84)
            .overlay(Circle().strokeBorder(.white.opacity(0.5), lineWidth: 1.5).padding(4))
            .overlay(artwork)
            .overlay(shineSweep.clipShape(Circle()))
            .shadow(color: Self.gold.opacity(0.35), radius: 16, y: 6)
            .scaleEffect(medalIn ? 1 : 0.5)
            .rotation3DEffect(.degrees(medalIn ? 0 : -90), axis: (x: 0, y: 1, z: 0))
            .accessibilityHidden(true)
    }

    @ViewBuilder
    private var artwork: some View {
        if let name = achievement.badgeAssetName, UIImage(named: name) != nil {
            Image(name)
                .resizable()
                .scaledToFit()
                .frame(width: 62, height: 62)
        } else {
            Image(systemName: achievement.icon)
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(Color(hex: "5A3A06"))
        }
    }

    private var shineSweep: some View {
        GeometryReader { geo in
            LinearGradient(colors: [.clear, .white.opacity(0.75), .clear], startPoint: .leading, endPoint: .trailing)
                .frame(width: geo.size.width * 0.45)
                .rotationEffect(.degrees(20))
                .offset(x: shine ? geo.size.width * 1.2 : -geo.size.width * 0.8)
                .blendMode(.screen)
        }
        .allowsHitTesting(false)
    }
}

/// Lottie confetti covering the whole screen (safe areas included), never blocking touches.
struct FullScreenConfetti: View {
    var body: some View {
        Color.clear
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea()
            .confetti(isActive: true)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}
