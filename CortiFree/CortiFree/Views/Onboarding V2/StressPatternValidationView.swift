//
//  StressPatternValidationView.swift
//  CortiFree
//
//  Quiz result screen after the habits quiz
//  Shows the self-assessed stress load (0-100) next to a serene reference profile
//  Button leads to symptom checker
//

import SwiftUI

struct StressPatternValidationView: View {
    let habitsQuizResult: HabitsQuizResult
    let onContinue: () -> Void

    @State private var barProgress: CGFloat = 0
    @State private var screenViewTime: Date?

    // MARK: - Computed Data

    // Self-assessed stress load on a 0–100 scale, derived from the quiz domains
    // (globalScore is 100 when every answer is the calmest one). It is not a cortisol
    // measurement, and the screen says so.
    private var stressLoad: Int {
        max(0, min(100, 100 - habitsQuizResult.globalScore))
    }

    /// Load of someone who mostly picks the calm side of each answer ("rarely", "often relaxed").
    private let sereneReference = 30

    private var isAboveReference: Bool { stressLoad > sereneReference }

    private var userBarRatio: CGFloat { min(0.92, max(0.08, CGFloat(stressLoad) / 100)) }
    private var referenceBarRatio: CGFloat { CGFloat(sereneReference) / 100 }

    private var userBarColors: [Color] {
        isAboveReference ? [Color(hex: "FF6B6B"), Color(hex: "EF4444")] : [Color(hex: "B7F7A6"), Color(hex: "53B96B")]
    }

    private var resultText: AttributedString {
        let key = isAboveReference ? "stress_pattern.load_above" : "stress_pattern.load_near"
        let text = String(format: key.localized, stressLoad, sereneReference)
        return (try? AttributedString(markdown: text)) ?? AttributedString(text)
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
                        .foregroundColor(Color(hex: "7ED957"))

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
                stressHistogram
                    .frame(height: 336) // 280 × 1.2
                    .padding(.horizontal, 40)

                Spacer()
                    .frame(height: 48)

                // Result sentence
                Text(resultText)
                    .font(.custom("Poppins-Medium", size: 15))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .balancedLines()
                    .padding(.horizontal, 32)

                Spacer()

                // Disclaimer
                Text("stress_pattern.disclaimer".localized)
                    .font(.custom("Poppins-Regular", size: 11))
                    .foregroundColor(.white.opacity(0.25))
                    .multilineTextAlignment(.center)
                    .balancedLines()
                    .padding(.horizontal, 40)
                    .padding(.bottom, 10)

                // CTA Button
                Button(action: {
                    HapticManager.medium()

                    if let startTime = screenViewTime {
                        let timeSpent = Date().timeIntervalSince(startTime)
                        AnalyticsManager.shared.track(
                            event: "onboarding_stress_pattern_continue",
                            properties: [
                                "time_spent": timeSpent,
                                "stress_load": stressLoad
                            ]
                        )
                    }

                    onContinue()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "list.bullet.clipboard")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)

                        Text("stress_pattern.cta".localized)
                            .font(.custom("Poppins-SemiBold", size: 16))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                }
                .buttonStyle(.glassPrimary)
                .padding(.horizontal, 34)
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            screenViewTime = Date()
            AnalyticsManager.shared.track(
                event: "onboarding_stress_pattern_viewed",
                properties: ["stress_load": stressLoad]
            )

            withAnimation(.easeOut(duration: 1.2).delay(0.4)) {
                barProgress = 1.0
            }
        }
    }

    // MARK: - Histogram

    private var stressHistogram: some View {
        GeometryReader { geo in
            let maxHeight = geo.size.height - 28
            let barWidth: CGFloat = 67 // 56 × 1.2

            HStack(alignment: .bottom, spacing: 38) {
                Spacer()

                // User bar (red above the serene reference, green otherwise)
                VStack(spacing: 0) {
                    Text("\(stressLoad)")
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
                                colors: userBarColors,
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

                // Serene reference bar
                VStack(spacing: 0) {
                    Text("\(sereneReference)")
                        .font(.faroBold(18))
                        .foregroundColor(.white)
                        .padding(.top, 10)
                    Spacer()
                }
                .frame(width: barWidth, height: maxHeight * referenceBarRatio * barProgress)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "B7F7A6"), Color(hex: "53B96B")],
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
