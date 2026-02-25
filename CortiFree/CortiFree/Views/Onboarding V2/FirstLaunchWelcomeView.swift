//
//  FirstLaunchWelcomeView.swift
//  CortiFree
//
//  First-launch welcome screen
//  Logo centré + 3 questions rhétoriques + hook cortisol + CTA
//

import SwiftUI

struct FirstLaunchWelcomeView: View {
    let onContinue: () -> Void

    @State private var screenViewTime: Date?

    @State private var showLogo = false
    @State private var showQ1 = false
    @State private var showQ2 = false
    @State private var showQ3 = false
    @State private var showDivider = false
    @State private var showStat = false
    @State private var showSolution = false
    @State private var showButton = false

    var body: some View {
        ZStack {
            GalaxyBackgroundView(intensity: 1.0)
                .ignoresSafeArea()

            Color.black.opacity(0.45)
                .ignoresSafeArea()

            VStack(spacing: 0) {

                // ── Logo centré ──
                if showLogo {
                    VStack(spacing: 10) {
                        Image("AppLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 96, height: 96)

                        Text("CortiFree")
                            .font(.faroBold(20))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 68)
                    .transition(.opacity.combined(with: .scale(scale: 0.92)))
                }

                Spacer()

                // ── 3 questions rhétoriques ──
                VStack(alignment: .leading, spacing: 0) {

                    if showQ1 {
                        painLine(text: "first_launch.q1".localized)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }

                    if showQ2 {
                        painLine(text: "first_launch.q2".localized)
                        .padding(.top, 20)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }

                    if showQ3 {
                        painLine(text: "first_launch.q3".localized)
                        .padding(.top, 20)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                }
                .padding(.horizontal, 36)
                .frame(maxWidth: .infinity, alignment: .leading)

                // ── Séparateur ──
                if showDivider {
                    Rectangle()
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 1)
                        .padding(.horizontal, 36)
                        .padding(.top, 30)
                        .transition(.opacity)
                }

                // ── Explication cortisol ──
                if showStat {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("first_launch.cortisol_intro".localized)
                            .font(.custom("Poppins-SemiBold", size: 16))
                            .foregroundColor(.white.opacity(0.55))

                        HStack(alignment: .firstTextBaseline, spacing: 0) {
                            Text("first_launch.cortisol_prefix".localized)
                                .font(.custom("Poppins-Regular", size: 22))
                                .foregroundColor(.white)

                            Text("first_launch.cortisol_word".localized)
                                .font(.faroBold(24))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color(hex: "B794F6"), Color(hex: "E0C4FF")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        }

                        Text("first_launch.cortisol_desc".localized)
                            .font(.custom("Poppins-Regular", size: 14))
                            .foregroundColor(.white.opacity(0.5))
                            .lineSpacing(5)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 36)
                    .padding(.top, 26)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                // ── Pill solution ──
                if showSolution {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color(hex: "4FC3A1"))

                        Text("first_launch.solution_pill".localized)
                            .font(.custom("Poppins-SemiBold", size: 13))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color(hex: "4FC3A1").opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(Color(hex: "4FC3A1").opacity(0.3), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal, 36)
                    .padding(.top, 18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
                }

                Spacer()

                // ── CTA ──
                if showButton {
                    VStack(spacing: 10) {
                        Button(action: {
                            HapticManager.medium()
                            if let startTime = screenViewTime {
                                MixpanelManager.shared.trackOnboardingWelcomeContinue(
                                    timeSpent: Date().timeIntervalSince(startTime)
                                )
                            }
                            onContinue()
                        }) {
                            Text("first_launch.cta_button".localized)
                                .font(.custom("Poppins-SemiBold", size: 16))
                                .foregroundColor(Color(hex: "1A1A4E"))
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 40))
                        }
                        .padding(.horizontal, 34)

                        Text("first_launch.cta_sub".localized)
                            .font(.custom("Poppins-Regular", size: 12))
                            .foregroundColor(.white.opacity(0.35))
                    }
                    .padding(.bottom, 52)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .onAppear {
            screenViewTime = Date()
            MixpanelManager.shared.trackOnboardingWelcomeViewed()
            startAnimations()
        }
    }

    // MARK: - Pain line

    private func painLine(text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(hex: "B794F6").opacity(0.7))
                .frame(width: 3, height: 40)
                .padding(.top, 3)

            Text(text)
                .font(.faroRegular(20))
                .foregroundColor(.white.opacity(0.88))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Animations

    private func startAnimations() {
        withAnimation(.easeOut(duration: 0.5).delay(0.2)) { showLogo = true }
        withAnimation(.easeOut(duration: 0.5).delay(0.7)) { showQ1 = true }
        withAnimation(.easeOut(duration: 0.5).delay(1.4)) { showQ2 = true }
        withAnimation(.easeOut(duration: 0.5).delay(2.1)) { showQ3 = true }
        withAnimation(.easeOut(duration: 0.4).delay(2.8)) { showDivider = true }
        withAnimation(.easeOut(duration: 0.6).delay(3.1)) { showStat = true }
        withAnimation(.easeOut(duration: 0.5).delay(3.9)) {
            showSolution = true
            HapticManager.light()
        }
        withAnimation(.easeOut(duration: 0.5).delay(4.5)) { showButton = true }
    }
}

#Preview {
    FirstLaunchWelcomeView(onContinue: {})
}
