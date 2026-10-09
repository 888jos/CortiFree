//
//  AchievementCelebrationView.swift
//  CortiFree
//
//  Achievement unlocked: a medal card centered over a dimmed backdrop, in a warm gold
//  palette (not the lavender used everywhere else). Slow light rays turn behind the
//  medal, a single shine crosses it, full-screen confetti falls behind the card.
//

import SwiftUI

struct AchievementCelebrationView: View {
    let achievement: Achievement
    let onContinue: () -> Void

    @State private var appeared = false
    @State private var medalIn = false
    @State private var shine = false
    @State private var raysAngle: Double = 0

    static let gold = Color(hex: "F6C453")
    static let goldDeep = Color(hex: "C98A1B")
    static let goldLight = Color(hex: "FFE7A6")

    var body: some View {
        ZStack {
            Color.black.opacity(appeared ? 0.6 : 0)
                .ignoresSafeArea()

            FullScreenConfetti()

            card
                .padding(.horizontal, 24)
                .scaleEffect(appeared ? 1 : 0.88)
                .opacity(appeared ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { appeared = true }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.15)) { medalIn = true }
            withAnimation(.easeInOut(duration: 1.1).delay(0.7)) { shine = true }
            withAnimation(.linear(duration: 24).repeatForever(autoreverses: false)) { raysAngle = 360 }
        }
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
    }

    private var card: some View {
        VStack(spacing: 0) {
            medal
                .padding(.top, 8)
                .padding(.bottom, 22)

            Text("achievement.unlocked".localized)
                .font(Font.Poppins.custom(.semiBold, size: 12))
                .tracking(1.6)
                .textCase(.uppercase)
                .foregroundStyle(Self.gold)
                .padding(.bottom, 8)

            Text(achievement.title)
                .font(.faroBold(28))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 8)

            Text(achievement.description)
                .font(Font.Poppins.custom(.regular, size: 15))
                .foregroundStyle(.white.opacity(0.68))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 8)
                .padding(.bottom, 26)

            Button {
                HapticManager.light()
                onContinue()
            } label: {
                Text("common.continue".localized)
                    .font(Font.Poppins.custom(.semiBold, size: 17))
                    .foregroundStyle(Color(hex: "2A1A05"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Capsule().fill(LinearGradient(colors: [Self.goldLight, Self.gold],
                                                              startPoint: .top, endPoint: .bottom)))
                    .shadow(color: Self.gold.opacity(0.35), radius: 14, y: 6)
            }
            .buttonStyle(.plain)

            ShareLink(item: String(format: "celebration.milestone.share_text".localized, achievement.title)) {
                Label("celebration.milestone.share".localized, systemImage: "square.and.arrow.up")
                    .font(Font.Poppins.custom(.medium, size: 15))
                    .foregroundStyle(.white.opacity(0.7))
                    .frame(height: 40)
            }
            .padding(.top, 6)
        }
        .padding(.horizontal, 24)
        .padding(.top, 26)
        .padding(.bottom, 14)
        .frame(maxWidth: 380)
        .background(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(LinearGradient(colors: [Color(hex: "2B1A3F"), Color(hex: "150D22")],
                                     startPoint: .top, endPoint: .bottom))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .strokeBorder(LinearGradient(colors: [Self.gold.opacity(0.45), .white.opacity(0.04)],
                                             startPoint: .top, endPoint: .bottom), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.5), radius: 34, y: 18)
    }

    // MARK: - Medal

    private var medal: some View {
        ZStack {
            // Slow turning light rays
            ForEach(0..<12, id: \.self) { index in
                Capsule()
                    .fill(LinearGradient(colors: [Self.gold.opacity(0.32), .clear], startPoint: .bottom, endPoint: .top))
                    .frame(width: 10, height: 96)
                    .offset(y: -78)
                    .rotationEffect(.degrees(Double(index) * 30))
            }
            .rotationEffect(.degrees(raysAngle))
            .opacity(medalIn ? 1 : 0)

            Circle()
                .fill(RadialGradient(colors: [Self.gold.opacity(0.45), .clear], center: .center, startRadius: 4, endRadius: 90))
                .frame(width: 180, height: 180)

            Circle()
                .fill(LinearGradient(colors: [Self.goldLight, Self.gold, Self.goldDeep], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 124, height: 124)
                .overlay(Circle().strokeBorder(.white.opacity(0.55), lineWidth: 2).padding(5))
                .overlay(artwork)
                .overlay(shineSweep.clipShape(Circle()))
                .shadow(color: Self.goldDeep.opacity(0.6), radius: 18, y: 8)
                .scaleEffect(medalIn ? 1 : 0.4)
                .rotation3DEffect(.degrees(medalIn ? 0 : -90), axis: (x: 0, y: 1, z: 0))
        }
        .frame(height: 190)
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private var artwork: some View {
        if let name = achievement.badgeAssetName, UIImage(named: name) != nil {
            Image(name)
                .resizable()
                .scaledToFit()
                .frame(width: 92, height: 92)
        } else {
            Image(systemName: achievement.icon)
                .font(.system(size: 50, weight: .semibold))
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
