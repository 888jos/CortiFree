//
//  StressPatternValidationView.swift
//  CortiFree
//
//  Cortisol analysis result screen after habits quiz
//  Shows cortisol comparison histogram (user vs average)
//  Button leads to symptom checker
//

import SwiftUI

struct StressPatternValidationView: View {
    let habitsQuizResult: HabitsQuizResult
    let onContinue: () -> Void

    @State private var barProgress: CGFloat = 0
    @State private var screenViewTime: Date?

    // MARK: - Computed Data

    // Échelle absolue fixe : 0 → 80 µg/dL
    // Le vert (normale) est ancré à 18 → toujours lisible et bas
    // L'user monte entre 30 et 72 → toujours au-dessus du vert, impactant
    private let scaleMax: CGFloat = 80

    private var avgCortisolValue: Int { 18 }

    // globalScore 0-100 → valeur 54-96 (toujours impactant, bien au-dessus de la normale)
    private var userCortisolValue: Int {
        let score = habitsQuizResult.globalScore
        // score=0 → 54, score=100 → 96 (plage de 42 pts)
        return max(54, min(96, Int(Double(score) * 0.42 + 54)))
    }

    // Kept for Mixpanel tracking
    private var cortisolPercentAbove: Int {
        userCortisolValue - avgCortisolValue
    }

    // Ratios sur l'échelle absolue 0–80, visuellement capés
    // Vert : 18/80 = 22.5% → on affiche 28% (un peu gonflé pour la lisibilité)
    private var avgBarRatio: CGFloat { 0.28 }
    // User : avgBarRatio × 1.3 au minimum, capé à 0.88 pour garder de l'espace au-dessus
    private var userBarRatio: CGFloat {
        min(0.88, max(avgBarRatio * 1.3, CGFloat(userCortisolValue) / scaleMax))
    }

    var body: some View {
        ZStack {
            GalaxyBackgroundView(intensity: 1.0)
                .ignoresSafeArea()

            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 60)

                // Analysis complete header
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(Color(hex: "67DB3D"))

                    Text("stress_pattern.analysis_complete".localized)
                        .font(.faroSemiBold(22))
                        .foregroundColor(.white)
                }

                // Subheading
                Text("stress_pattern.news_to_break".localized)
                    .font(.custom("Poppins-Regular", size: 15))
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.top, 8)

                Spacer()
                    .frame(height: 16)

                Spacer()
                    .frame(height: 28)

                // Histogram
                cortisolHistogram
                    .frame(height: 336) // 280 × 1.2
                    .padding(.horizontal, 40)

                Spacer()
                    .frame(height: 48)

                // Cortisol stat
                Text(try! AttributedString(
                    markdown: String(format: "stress_pattern.cortisol_above".localized, cortisolPercentAbove)
                ))
                    .font(.custom("Poppins-Medium", size: 15))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Spacer()

                // Disclaimer
                Text("stress_pattern.disclaimer".localized)
                    .font(.custom("Poppins-Regular", size: 11))
                    .foregroundColor(.white.opacity(0.25))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 10)

                // CTA Button
                Button(action: {
                    HapticManager.medium()

                    if let startTime = screenViewTime {
                        let timeSpent = Date().timeIntervalSince(startTime)
                        MixpanelManager.shared.track(
                            event: "onboarding_stress_pattern_continue",
                            properties: [
                                "time_spent": timeSpent,
                                "cortisol_percent_above": cortisolPercentAbove
                            ]
                        )
                    }

                    onContinue()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "stethoscope")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(hex: "1A1A4E"))

                        Text("stress_pattern.cta".localized)
                            .font(.custom("Poppins-SemiBold", size: 16))
                            .foregroundColor(Color(hex: "1A1A4E"))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 40))
                }
                .padding(.horizontal, 34)
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            screenViewTime = Date()
            MixpanelManager.shared.track(
                event: "onboarding_stress_pattern_viewed",
                properties: ["cortisol_percent_above": cortisolPercentAbove]
            )

            withAnimation(.easeOut(duration: 1.2).delay(0.4)) {
                barProgress = 1.0
            }
        }
    }

    // MARK: - Histogram

    private var cortisolHistogram: some View {
        GeometryReader { geo in
            let maxHeight = geo.size.height - 28
            let barWidth: CGFloat = 67 // 56 × 1.2

            HStack(alignment: .bottom, spacing: 38) {
                Spacer()

                // User bar (rouge)
                VStack(spacing: 0) {
                    Text("\(userCortisolValue)")
                        .font(.faroBold(18))
                        .foregroundColor(.white)
                        .padding(.top, 10)
                    Spacer()
                }
                .frame(width: barWidth, height: maxHeight * userBarRatio * barProgress)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "FF8A80"), Color(hex: "EF4444")],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(alignment: .bottom) {
                    Text("stress_pattern.bar_you".localized)
                        .font(.custom("Poppins-SemiBold", size: 13))
                        .foregroundColor(.white.opacity(0.7))
                        .offset(y: 24)
                }

                // Average bar (vert)
                VStack(spacing: 0) {
                    Text("\(avgCortisolValue)")
                        .font(.faroBold(18))
                        .foregroundColor(.white)
                        .padding(.top, 10)
                    Spacer()
                }
                .frame(width: barWidth, height: maxHeight * avgBarRatio * barProgress)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "67DB3D"), Color(hex: "22C55E")],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(alignment: .bottom) {
                    Text("stress_pattern.bar_normal".localized)
                        .font(.custom("Poppins-SemiBold", size: 13))
                        .foregroundColor(.white.opacity(0.7))
                        .offset(y: 24)
                }

                Spacer()
            }
            .frame(maxHeight: .infinity, alignment: .bottom)
        }
    }
}

#Preview {
    let mockResult = HabitsQuizResult(answers: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
    StressPatternValidationView(habitsQuizResult: mockResult, onContinue: {})
}
