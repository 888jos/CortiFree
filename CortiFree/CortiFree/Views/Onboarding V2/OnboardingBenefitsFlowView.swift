//
//  OnboardingBenefitsFlowView.swift
//  CortiFree
//
//  Five-screen feature tour shown between the custom pre-paywall and Superwall, with app
//  screenshots in the user's language.
//

import SwiftUI

struct OnboardingBenefitsFlowView: View {
    let onBack: () -> Void
    /// Last page: on to the pre-paywall.
    let onContinueToPaywall: () -> Void
    @State private var selectedPage = 0

    /// Screenshots captured per language by CortiFreeUITests/BenefitsScreenshotsUITests.
    private let pages: [BenefitsPage] = [
        BenefitsPage(id: "plan"),
        BenefitsPage(id: "breathing"),
        BenefitsPage(id: "library"),
        BenefitsPage(id: "home"),
        BenefitsPage(id: "meditation")
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
        // Where the tour loses people before the paywall.
        .onAppear { trackPage(0) }
        .onChange(of: selectedPage) { _, page in trackPage(page) }
    }

    private func trackPage(_ page: Int) {
        AnalyticsManager.shared.track(event: "onboarding_benefits_page_viewed",
                                      properties: ["page": page + 1, "total": pages.count])
    }

    private var header: some View {
        HStack {
            Button {
                HapticManager.light()
                if selectedPage == 0 {
                    onBack()
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
    let id: String

    var titleKey: String { "onboarding_v2.benefits.\(id)_title" }
    var subtitleKey: String { "onboarding_v2.benefits.\(id)_subtitle" }

    /// `benefit_<id>_<lang>` in the app language, English otherwise.
    var imageName: String {
        let localized = "benefit_\(id)_\(LanguageManager.shared.currentLanguage.rawValue)"
        return UIImage(named: localized) != nil ? localized : "benefit_\(id)_en"
    }
}

#Preview {
    OnboardingBenefitsFlowView(onBack: {}, onContinueToPaywall: {})
}
