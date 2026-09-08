//
//  OnboardingBenefitsFlowView.swift
//  CortiFree
//
//  Five-screen feature tour shown between the custom pre-paywall and Superwall.
//

import SwiftUI

struct OnboardingBenefitsFlowView: View {
    let onContinueToPaywall: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedPage = 0

    private let pages: [BenefitsPage] = [
        BenefitsPage(
            imageName: "benefit_library",
            title: "Everything you need\nin one calm space",
            subtitle: "Explore breathing, meditation, journaling, and sounds designed to help your body slow down."
        ),
        BenefitsPage(
            imageName: "benefit_plan",
            title: "A daily plan\nbuilt for you",
            subtitle: "Simple routines turn small moments into a rhythm you can come back to every day."
        ),
        BenefitsPage(
            imageName: "benefit_breathing",
            title: "Reset your system\nin a few minutes",
            subtitle: "Follow guided exercises that help you create a real pause when stress starts to rise."
        ),
        BenefitsPage(
            imageName: "benefit_achievements",
            title: "Make your progress\nfeel real",
            subtitle: "See your streaks, unlock milestones, and notice the consistency you are building."
        ),
        BenefitsPage(
            imageName: "benefit_home",
            title: "Feel better\none day at a time",
            subtitle: "Your next step is ready whenever you are. Start with a plan that fits real life."
        )
    ]

    var body: some View {
        ZStack {
            GalaxyBackgroundView(intensity: 1.0)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header

                TabView(selection: $selectedPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        BenefitsPageView(page: page)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.25), value: selectedPage)

                continueButton
            }
        }
        .interactiveDismissDisabled()
    }

    private var header: some View {
        HStack {
            Button {
                HapticManager.light()
                if selectedPage == 0 {
                    dismiss()
                } else {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        selectedPage -= 1
                    }
                }
            } label: {
                Image(systemName: "arrow.left")
                    .font(.system(size: 21, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(selectedPage == 0 ? "Back" : "Previous page")

            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.top, 14)
    }

    private var continueButton: some View {
        Button {
            HapticManager.medium()
            if selectedPage == pages.count - 1 {
                onContinueToPaywall()
            } else {
                withAnimation(.easeInOut(duration: 0.25)) {
                    selectedPage += 1
                }
            }
        } label: {
            HStack(spacing: 10) {
                Text(selectedPage == pages.count - 1 ? "Continue to your plan" : "Continue")
                    .font(.poppinsSemiBold(17))

                Image(systemName: "arrow.right")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "8B5CF6"), Color(hex: "B794F6")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 24)
        .padding(.top, 8)
        .padding(.bottom, 32)
    }
}

private struct BenefitsPageView: View {
    let page: BenefitsPage

    var body: some View {
        VStack(spacing: 0) {
            Text(page.title)
                .font(.faroBold(28))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.horizontal, 24)
                .padding(.top, 14)

            Spacer(minLength: 20)

            Image(page.imageName)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 248, maxHeight: 500)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(.white, lineWidth: 2)
                }
                .shadow(color: Color(hex: "B794F6").opacity(0.24), radius: 24, y: 12)

            Spacer(minLength: 20)
        }
        .padding(.horizontal, 20)
    }
}

private struct BenefitsPage {
    let imageName: String
    let title: String
    let subtitle: String
}

#Preview {
    OnboardingBenefitsFlowView(onContinueToPaywall: {})
}
