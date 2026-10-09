//
//  OnboardingBenefitsFlowView.swift
//  CortiFree
//
//  Four-screen feature tour shown between the custom pre-paywall and Superwall.
//

import SwiftUI

struct OnboardingBenefitsFlowView: View {
    let onContinueToPaywall: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedPage = 0

    private let pages: [BenefitsPage] = [
        BenefitsPage(
            imageName: "benefit_plan",
            titleKey: "onboarding_v2.benefits.plan_title",
            subtitleKey: "onboarding_v2.benefits.plan_subtitle"
        ),
        BenefitsPage(
            imageName: "benefit_library",
            titleKey: "onboarding_v2.benefits.library_title",
            subtitleKey: "onboarding_v2.benefits.library_subtitle"
        ),
        BenefitsPage(
            imageName: "benefit_progress",
            titleKey: "onboarding_v2.benefits.progress_title",
            subtitleKey: "onboarding_v2.benefits.progress_subtitle"
        ),
        BenefitsPage(
            imageName: "benefit_achievements",
            titleKey: "onboarding_v2.benefits.achievements_title",
            subtitleKey: "onboarding_v2.benefits.achievements_subtitle"
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
            .accessibilityLabel((selectedPage == 0 ? "common.back" : "common.previous_page").localized)

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
                Text((selectedPage == pages.count - 1 ? "onboarding_v2.benefits.continue_plan" : "common.continue").localized)
                    .font(.poppinsSemiBold(17))

                Image(systemName: "arrow.right")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
        }
        .buttonStyle(.glassPrimary)
        .padding(.horizontal, 24)
        .padding(.top, 8)
        .padding(.bottom, 32)
    }
}

private struct BenefitsPageView: View {
    let page: BenefitsPage
    private let screenshotAspectRatio = CGFloat(1179.0 / 2556.0)

    var body: some View {
        VStack(spacing: 0) {
            Text(page.titleKey.localized)
                .font(.faroBold(28))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .balancedLines()
                .lineSpacing(3)
                .padding(.horizontal, 24)
                .padding(.top, 14)

            Text(page.subtitleKey.localized)
                .font(.poppinsRegular(13))
                .foregroundStyle(.white.opacity(0.66))
                .multilineTextAlignment(.center)
                .balancedLines()
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 32)
                .padding(.top, 10)

            GeometryReader { geometry in
                let phoneHeight = min(geometry.size.height - 24, 500)
                let phoneWidth = phoneHeight * screenshotAspectRatio
                let phoneShape = RoundedRectangle(
                    cornerRadius: max(18, phoneWidth * 0.105),
                    style: .continuous
                )

                ZStack {
                    Color.black

                    Image(page.imageName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: phoneWidth, height: phoneHeight)
                        .clipped()
                }
                .frame(width: phoneWidth, height: phoneHeight)
                .clipShape(phoneShape)
                .overlay {
                    phoneShape
                        .strokeBorder(.white.opacity(0.96), lineWidth: 2.25)
                }
                .shadow(color: Color(hex: "B794F6").opacity(0.24), radius: 24, y: 12)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
            .padding(.top, 14)
        }
        .padding(.horizontal, 20)
    }
}

private struct BenefitsPage {
    let imageName: String
    let titleKey: String
    let subtitleKey: String
}

#Preview {
    OnboardingBenefitsFlowView(onContinueToPaywall: {})
}
