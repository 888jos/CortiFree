//
//  ScientificPlanView.swift
//  CortiFree
//
//  Created by Claude on 10/11/2025.
//  Deuxième écran: Le plan scientifique avec citations
//

import SwiftUI

struct ScientificPlanView: View {
    var onBack: (() -> Void)? = nil
    let onContinue: () -> Void
    @ObservedObject var languageManager = LanguageManager.shared
    @State private var screenViewTime: Date?

    var body: some View {
        ZStack {
            // Galaxy background
            GalaxyBackgroundView(intensity: 1.0)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Title
                    Text("onboarding_v2.scientific.approach_title".localized)
                        .font(.faroBold(28))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, Color(hex: "B794F6")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .padding(.top, 80)
                        .padding(.bottom, 40)

                    // Scientific Citations
                    VStack(spacing: 24) {
                        // Harvard Quote
                        ScientificQuoteCard(
                            symbol: "doc.text",
                            quote: "onboarding_v2.scientific.harvard_quote".localized,
                            highlightedText: "onboarding_v2.scientific.harvard_highlight".localized,
                            // Citations stay in their original language and are never translated.
                            source: "Wood, W., & Rünger, D. (2016). Psychology of Habit. Annual Review of Psychology, 67, 289–314."
                        )

                        // UCL Quote
                        ScientificQuoteCard(
                            symbol: "doc.text",
                            quote: "onboarding_v2.scientific.ucl_quote".localized,
                            highlightedText: "onboarding_v2.scientific.ucl_highlight".localized,
                            source: "Lally, P., et al. (2010). How are habits formed: Modelling habit formation in the real world. European Journal of Social Psychology, 40(6), 998–1009."
                        )

                        // Atomic Habits Quote
                        ScientificQuoteCard(
                            symbol: "book.closed",
                            quote: "onboarding_v2.scientific.atomic_quote".localized,
                            highlightedText: "onboarding_v2.scientific.atomic_highlight".localized,
                            source: "Clear, J. (2018). Atomic Habits. New York: Avery."
                        )
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)

                    // Badges
                    HStack(spacing: 16) {
                        BadgeView(text: "onboarding_v2.scientific.citations".localized)
                        BadgeView(text: "onboarding_v2.scientific.copies_sold".localized)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 120)
                }
            }

            // Bottom button
            VStack {
                Spacer()

                Button(action: {
                    HapticManager.medium()

                    if let startTime = screenViewTime {
                        let timeSpent = Date().timeIntervalSince(startTime)
                        AnalyticsManager.shared.trackOnboardingScientificPlanContinue(timeSpent: timeSpent)
                    }

                    onContinue()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)

                        Text("onboarding_v2.scientific.next".localized)
                            .font(.custom("Poppins-SemiBold", size: 18))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                }
                .buttonStyle(.glassPrimary)
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .ignoresSafeArea()
        .onboardingBackButton(onBack)
        .onAppear {
            screenViewTime = Date()
            AnalyticsManager.shared.trackOnboardingScientificPlanViewed()
        }
    }
}

// MARK: - Scientific Quote Card

struct ScientificQuoteCard: View {
    let symbol: String
    let quote: String
    let highlightedText: String
    let source: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Top section: Logo left, Quote right with first gradient
            HStack(alignment: .top, spacing: 12) {
                // Logo
                Image(systemName: symbol)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(Color(hex: "D4B4FF"))
                    .frame(width: 50, height: 50)
                    .glassCard(cornerRadius: 8)

                // Quote with guillemets
                Text("\"\(attributedQuote)\"")
                    .font(.custom("Poppins-Regular", size: 14))
                    .foregroundColor(.white)
                    .lineSpacing(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(16)

            // Divider
            Rectangle()
                .fill(Color.white.opacity(0.15))
                .frame(height: 1)

            // Source section with second gradient
            Text(source)
                .font(.custom("Poppins-Regular", size: 11))
                .foregroundColor(.white.opacity(0.6))
                .lineSpacing(3)
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .glassCard(cornerRadius: 16, tint: Color(hex: "B794F6"))
    }

    private var attributedQuote: AttributedString {
        var attributedString = AttributedString(quote)

        if let range = attributedString.range(of: highlightedText) {
            attributedString[range].foregroundColor = Color(hex: "B794F6")
        }

        return attributedString
    }
}

// MARK: - Badge View

struct BadgeView: View {
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            // Laurier gauche
            Image(systemName: "laurel.leading")
                .font(.system(size: 28))
                .foregroundColor(.white)

            Text(text)
                .font(.custom("Poppins-SemiBold", size: 10))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            // Laurier droit
            Image(systemName: "laurel.trailing")
                .font(.system(size: 28))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

#Preview {
    ScientificPlanView(onContinue: {})
}
