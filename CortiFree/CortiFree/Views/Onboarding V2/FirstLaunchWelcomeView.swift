//
//  FirstLaunchWelcomeView.swift
//  CortiFree
//
//  First-launch welcome screen
//  Mascot introduction + CTA
//

import SwiftUI

struct FirstLaunchWelcomeView: View {
    let onContinue: () -> Void

    @State private var screenViewTime: Date?

    @State private var hasContinued = false
    var body: some View {
        ZStack {
            GalaxyBackgroundView(intensity: 1.0)
                .ignoresSafeArea()

            Color.black.opacity(0.45)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 48)

                LottieView(filename: "sloth_intro.json", loopMode: .loop)
                    .frame(width: 190, height: 190)

                ZStack {
                    VStack(spacing: 12) {
                        Text("first_launch.mascot_greeting".localized)
                            .font(.faroBold(25))
                            .foregroundStyle(.white)

                        Text("first_launch.mascot_role".localized)
                            .font(.poppinsRegular(16))
                            .foregroundStyle(.white.opacity(0.86))
                            .multilineTextAlignment(.center)
                            .lineSpacing(3)

                        Text("first_launch.mascot_plan".localized)
                            .font(.poppinsRegular(15))
                            .foregroundStyle(.white.opacity(0.68))
                            .multilineTextAlignment(.center)
                            .lineSpacing(3)
                    }

                    IntroSparkle(color: Color(hex: "FFB7E8"), size: 18, delay: 0.0)
                        .offset(x: -150, y: -42)
                    IntroSparkle(color: Color(hex: "E9B6FF"), size: 12, delay: 0.35)
                        .offset(x: 151, y: -28)
                    IntroSparkle(color: Color(hex: "FF8EDB"), size: 10, delay: 0.7)
                        .offset(x: 137, y: 48)
                    IntroSparkle(color: Color(hex: "D4B4FF"), size: 14, delay: 1.05)
                        .offset(x: -142, y: 55)
                }
                .padding(.horizontal, 30)
                .padding(.top, 20)

                Spacer()

                VStack(spacing: 10) {
                    Button(action: continueToQuiz) {
                        Text("first_launch.cta_button".localized)
                            .font(.custom("Poppins-SemiBold", size: 16))
                            .foregroundColor(Color(hex: "1A1A4E"))
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 40))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 34)

                    Text("first_launch.cta_sub".localized)
                        .font(.custom("Poppins-Regular", size: 12))
                        .foregroundColor(.white.opacity(0.35))
                }
                .padding(.bottom, 52)
            }
        }
        .onAppear {
            screenViewTime = Date()
            MixpanelManager.shared.trackOnboardingWelcomeViewed()
        }
    }

    private func continueToQuiz() {
        guard !hasContinued else { return }
        hasContinued = true

        let timeSpent = screenViewTime.map { Date().timeIntervalSince($0) } ?? 0
        HapticManager.medium()

        finishWelcome(timeSpent: timeSpent)
    }

    private func finishWelcome(timeSpent: TimeInterval) {
        onContinue()
        Task { @MainActor in
            await Task.yield()
            MixpanelManager.shared.trackOnboardingWelcomeContinue(timeSpent: timeSpent)
        }
    }

}

private struct IntroSparkle: View {
    let color: Color
    let size: CGFloat
    let delay: Double

    @State private var isShining = false

    var body: some View {
        Image(systemName: "sparkle")
            .font(.system(size: size, weight: .medium))
            .foregroundStyle(color)
            .shadow(color: color.opacity(0.75), radius: 8)
            .scaleEffect(isShining ? 1.18 : 0.62)
            .opacity(isShining ? 1.0 : 0.35)
            .animation(
                .easeInOut(duration: 1.35)
                    .repeatForever(autoreverses: true)
                    .delay(delay),
                value: isShining
            )
            .onAppear { isShining = true }
    }
}

#Preview {
    FirstLaunchWelcomeView(onContinue: {})
}
