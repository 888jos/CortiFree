//
//  SixtyDaysExplanationView.swift
//  CortiFree
//
//  Created by Claude on 10/11/2025.
//  Premier écran: Explication des 66 jours avec statistiques
//

import SwiftUI

struct SixtyDaysExplanationView: View {
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
                    // Title with gradient on "66 jours"
                    VStack(spacing: 6) {
                        // Première partie
                        Text("onboarding_v2.sixty_days.studies_confirm".localized)
                            .font(.custom("Poppins-Regular", size: 16))
                            .foregroundColor(Color(hex: "B794F6").opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 32)
                    .padding(.top, 100)
                    .padding(.bottom, 12)

                    // "66 jours" - Grande police avec gradient
                    Text("onboarding_v2.sixty_days.days".localized)
                        .font(.custom("Faro-BoldLucky", size: 64))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(hex: "D4B4FF"),
                                    Color(hex: "B794F6"),
                                    Color(hex: "9775D5")
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .multilineTextAlignment(.center)
                        .shadow(color: Color(hex: "B794F6").opacity(0.8), radius: 30, x: 0, y: 0)
                        .padding(.bottom, 12)

                    // Deuxième partie
                    VStack(spacing: 6) {
                        Text("onboarding_v2.sixty_days.time_needed".localized)
                            .font(.custom("Poppins-Regular", size: 16))
                            .foregroundColor(Color(hex: "B794F6").opacity(0.8))
                            .multilineTextAlignment(.center)

                        Text("onboarding_v2.sixty_days.habit_transform".localized)
                            .font(.custom("Poppins-Regular", size: 16))
                            .foregroundColor(Color(hex: "B794F6").opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 32)

                    // The program the user actually gets: four weekly themes, renewable.
                    VStack(alignment: .leading, spacing: 12) {
                        Text("onboarding_v2.sixty_days.plan_title".localized)
                            .font(.faroSemiBold(20))
                            .foregroundColor(.white)

                        Text("onboarding_v2.sixty_days.plan_subtitle".localized)
                            .font(.custom("Poppins-Regular", size: 14))
                            .foregroundColor(.white.opacity(0.7))
                            .fixedSize(horizontal: false, vertical: true)

                        VStack(spacing: 10) {
                            ForEach(Array(PlanWeekTheme.allCases.enumerated()), id: \.element) { index, theme in
                                WeekThemeCard(week: index + 1, theme: theme)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)

                    // Scientific Research Section
                    VStack(alignment: .leading, spacing: 0) {
                        Text("onboarding_v2.sixty_days.scientific_research".localized)
                            .font(.faroSemiBold(20))
                            .foregroundColor(.white)

                        Spacer()
                            .frame(height: 16)

                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(ScientificReference.habitFormation) { reference in
                                ScientificLinkRow(reference: reference)
                            }
                        }
                    }
                    .padding(16)
                    .glassCard(cornerRadius: 16)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 120)
                }
            }

            // Bottom button
            VStack {
                Spacer()

                Button(action: {
                    HapticManager.medium()

                    // Track continue with time spent
                    if let startTime = screenViewTime {
                        let timeSpent = Date().timeIntervalSince(startTime)
                        AnalyticsManager.shared.trackOnboardingSixtyDaysExplanationContinue(timeSpent: timeSpent)
                    }

                    onContinue()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)

                        Text("onboarding_v2.sixty_days.next".localized)
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
            AnalyticsManager.shared.trackOnboardingSixtyDaysExplanationViewed()
        }
    }
}

// MARK: - Week theme card

struct WeekThemeCard: View {
    let week: Int
    let theme: PlanWeekTheme

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Text(String(format: "onboarding.week_progress.week_number".localized, week))
                .font(.custom("Poppins-SemiBold", size: 12))
                .foregroundColor(Color(hex: "D4B4FF"))
                .frame(width: 78, alignment: .leading)

            VStack(alignment: .leading, spacing: 3) {
                Text(theme.localizedTitle)
                    .font(.custom("Poppins-SemiBold", size: 15))
                    .foregroundColor(.white)
                Text(theme.localizedSubtitle)
                    .font(.custom("Poppins-Regular", size: 13))
                    .foregroundColor(.white.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .glassCard(cornerRadius: 14, tint: Color(hex: "B794F6"))
    }
}

// MARK: - Scientific references

/// Published sources shown in the onboarding. Authors and titles stay in their original
/// language (they are citations, never translated); only the summary line is localized.
struct ScientificReference: Identifiable {
    let id: String
    let citation: String
    let summaryKey: String
    let url: URL

    static let habitFormation: [ScientificReference] = [
        ScientificReference(
            id: "lally2010",
            citation: "Lally, P., van Jaarsveld, C. H. M., Potts, H. W. W., & Wardle, J. (2010). How are habits formed: Modelling habit formation in the real world. European Journal of Social Psychology, 40(6), 998–1009.",
            summaryKey: "onboarding_v2.sources.lally_summary",
            url: URL(string: "https://doi.org/10.1002/ejsp.674")!
        ),
        ScientificReference(
            id: "gardner2012",
            citation: "Gardner, B., Lally, P., & Wardle, J. (2012). Making health habitual: the psychology of ‘habit-formation’ and general practice. British Journal of General Practice, 62(605), 664–666.",
            summaryKey: "onboarding_v2.sources.gardner_summary",
            url: URL(string: "https://pmc.ncbi.nlm.nih.gov/articles/PMC3505409/")!
        ),
        ScientificReference(
            id: "wood2016",
            citation: "Wood, W., & Rünger, D. (2016). Psychology of Habit. Annual Review of Psychology, 67, 289–314.",
            summaryKey: "onboarding_v2.sources.wood_summary",
            url: URL(string: "https://doi.org/10.1146/annurev-psych-122414-033417")!
        )
    ]
}

// MARK: - Scientific Link Row

struct ScientificLinkRow: View {
    let reference: ScientificReference

    var body: some View {
        Link(destination: reference.url) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color(hex: "D4B4FF"))
                    .frame(width: 20)

                VStack(alignment: .leading, spacing: 4) {
                    Text(reference.summaryKey.localized)
                        .font(.custom("Poppins-Medium", size: 13))
                        .foregroundColor(.white)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(reference.citation)
                        .font(.custom("Poppins-Regular", size: 11))
                        .foregroundColor(.white.opacity(0.6))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.5))
            }
            .multilineTextAlignment(.leading)
        }
        .accessibilityHint("onboarding_v2.sources.open_hint".localized)
    }
}

#Preview {
    SixtyDaysExplanationView(onContinue: {})
        .onAppear {
            FontManager.registerFonts()
        }
}
