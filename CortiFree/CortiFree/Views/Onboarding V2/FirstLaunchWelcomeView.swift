//
//  FirstLaunchWelcomeView.swift
//  CortiFree
//
//  Created by Claude on 18/11/2025.
//  First-launch welcome screen shown before onboarding quiz
//

import SwiftUI

struct FirstLaunchWelcomeView: View {
    let onContinue: () -> Void

    @ObservedObject var languageManager = LanguageManager.shared
    @State private var showContent = false
    @State private var showBenefits = false
    @State private var showButton = false
    @State private var screenViewTime: Date?

    var body: some View {
        ZStack {
            // Animated galaxy background
            GalaxyBackgroundView()
                .ignoresSafeArea()

            // Dark overlay for text readability
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top section: Title + Description + Benefits
                VStack(alignment: .leading, spacing: 24) {
                    // Main title
                    if showContent {
                        Text("onboarding_v2.welcome.title".localized)
                            .font(.custom("Poppins-Bold", size: 36))
                            .foregroundColor(.white)
                            .lineSpacing(4)
                            .lineLimit(2)
                            .minimumScaleFactor(0.7)
                            .fixedSize(horizontal: false, vertical: true)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    // Subtitle
                    if showContent {
                        Text("onboarding_v2.welcome.subtitle".localized)
                            .font(.custom("Poppins-Regular", size: 18))
                            .foregroundColor(.white.opacity(0.85))
                            .lineSpacing(6)
                            .padding(.top, 8)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    // Key benefits
                    if showBenefits {
                        VStack(alignment: .leading, spacing: 16) {
                            BenefitRow(icon: "sparkles", text: "onboarding_v2.welcome.benefit_1".localized)
                            BenefitRow(icon: "chart.line.uptrend.xyaxis", text: "onboarding_v2.welcome.benefit_2".localized)
                            BenefitRow(icon: "heart.fill", text: "onboarding_v2.welcome.benefit_3".localized)
                        }
                        .padding(.top, 16)
                        .transition(.opacity.combined(with: .move(edge: .leading)))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 40)
                .padding(.top, 100)

                Spacer()

                // Bottom section: CTA Button
                if showButton {
                    VStack(spacing: 12) {
                        Button(action: {
                            HapticManager.medium()

                            // Track continue button click with time spent
                            if let startTime = screenViewTime {
                                let timeSpent = Date().timeIntervalSince(startTime)
                                MixpanelManager.shared.trackOnboardingWelcomeContinue(timeSpent: timeSpent)
                            }

                            onContinue()
                        }) {
                            HStack(spacing: 12) {
                                Text("onboarding_v2.welcome.start_button".localized)
                                    .font(.custom("Poppins-SemiBold", size: 16))
                                    .foregroundColor(Color(hex: "1A1A4E"))

                                // Dark circle with white arrow
                                ZStack {
                                    Circle()
                                        .fill(Color(hex: "1A1A4E"))
                                        .frame(width: 32, height: 32)

                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                            }
                            .padding(.vertical, 12)
                            .padding(.leading, 24)
                            .padding(.trailing, 12)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 40))
                        }

                        // Time estimate
                        Text("onboarding_v2.welcome.time_estimate".localized)
                            .font(.custom("Poppins-Regular", size: 14))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 50)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .onAppear {
            // Track screen view
            screenViewTime = Date()
            MixpanelManager.shared.trackOnboardingWelcomeViewed()

            startAnimations()
        }
    }

    // MARK: - Animation sequence

    private func startAnimations() {
        // Show title and subtitle
        withAnimation(.easeOut(duration: 0.8)) {
            showContent = true
        }

        // Show benefits after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeOut(duration: 0.6)) {
                showBenefits = true
            }
        }

        // Show button after benefits
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.easeOut(duration: 0.6)) {
                showButton = true
            }
        }
    }
}

// MARK: - Benefit Row Component

private struct BenefitRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            // Icon with purple gradient background
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "B794F6").opacity(0.3), Color(hex: "B794F6").opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(hex: "B794F6"))
            }

            Text(text)
                .font(.custom("Poppins-Regular", size: 16))
                .foregroundColor(.white)
                .lineSpacing(4)
        }
    }
}

// MARK: - Preview

#Preview {
    FirstLaunchWelcomeView(onContinue: {
        print("Welcome screen completed")
    })
}
