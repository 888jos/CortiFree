//
//  CortiFreeComparisonView.swift
//  CortiFree
//

import SwiftUI

struct CortiFreeComparisonView: View {
    let previousAppExperience: Int
    let onBack: () -> Void
    let onContinue: () -> Void

    @State private var animateCurves = false

    private let cortiFreeColor = Color(hex: "72D572")
    private let baselineColor = Color.white.opacity(0.42)

    var body: some View {
        ZStack {
            GalaxyBackgroundView(intensity: 1.0)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 26) {
                        VStack(spacing: 12) {
                            Text(personalizedTitleKey.localized)
                                .font(.faroBold(30))
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.center)

                            Text("onboarding_v2.comparison.subtitle".localized)
                                .font(.custom("Poppins-Regular", size: 15))
                                .foregroundStyle(.white.opacity(0.62))
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                        }
                        .padding(.horizontal, 28)

                        chart
                            .padding(.horizontal, 22)

                        Text("onboarding_v2.comparison.disclaimer".localized)
                            .font(.custom("Poppins-Regular", size: 12))
                            .foregroundStyle(.white.opacity(0.42))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 34)
                    }
                    .padding(.top, 26)
                    .padding(.bottom, 24)
                }

                Button(action: {
                    HapticManager.medium()
                    MixpanelManager.shared.track(
                        event: "onboarding_quiz_transition_continued",
                        properties: [
                            "transition_type": "cortifree_comparison",
                            "previous_app_experience": previousAppExperience
                        ]
                    )
                    onContinue()
                }) {
                    HStack(spacing: 10) {
                        Text("onboarding_v2.comparison.cta".localized)
                            .font(.custom("Poppins-SemiBold", size: 16))

                        Image(systemName: "arrow.right")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundStyle(Color(hex: "1A1A4E"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                }
                .padding(.horizontal, 34)
                .padding(.bottom, 46)
            }
        }
        .onAppear {
            MixpanelManager.shared.track(
                event: "onboarding_quiz_transition_viewed",
                properties: [
                    "transition_type": "cortifree_comparison",
                    "previous_app_experience": previousAppExperience
                ]
            )
            withAnimation(.easeOut(duration: 1.4).delay(0.2)) {
                animateCurves = true
            }
        }
    }

    private var personalizedTitleKey: String {
        switch previousAppExperience {
        case 0: return "onboarding_v2.comparison.title.first_app"
        case 1: return "onboarding_v2.comparison.title.stopped"
        case 2: return "onboarding_v2.comparison.title.current_app"
        default: return "onboarding_v2.comparison.title.several_apps"
        }
    }

    private var header: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Back")

            Spacer()

            Text("CortiFree")
                .font(.faroBold(18))
                .foregroundStyle(.white.opacity(0.9))

            Spacer()

            Color.clear
                .frame(width: 44, height: 44)
        }
        .padding(.horizontal, 18)
        .padding(.top, 42)
    }

    private var chart: some View {
        VStack(spacing: 18) {
            HStack(spacing: 18) {
                legend(color: cortiFreeColor, text: "onboarding_v2.comparison.with".localized)
                legend(color: baselineColor, text: "onboarding_v2.comparison.without".localized)
            }

            GeometryReader { geometry in
                ZStack {
                    chartGrid

                    ComparisonCurve(kind: .withoutCortiFree)
                        .trim(from: 0, to: animateCurves ? 1 : 0)
                        .stroke(
                            baselineColor,
                            style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round, dash: [7, 7])
                        )

                    ComparisonCurve(kind: .withCortiFree)
                        .trim(from: 0, to: animateCurves ? 1 : 0)
                        .stroke(
                            cortiFreeColor,
                            style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round)
                        )
                        .shadow(color: cortiFreeColor.opacity(0.35), radius: 8)

                    chartLabels
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
            .frame(height: 260)
        }
        .padding(20)
        .background(Color(hex: "111032").opacity(0.88))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        }
    }

    private var chartGrid: some View {
        VStack(spacing: 0) {
            ForEach(0..<5, id: \.self) { index in
                Rectangle()
                    .fill(Color.white.opacity(index == 4 ? 0.14 : 0.07))
                    .frame(height: 1)
                if index < 4 {
                    Spacer()
                }
            }
        }
        .padding(.horizontal, 2)
        .padding(.vertical, 24)
    }

    private var chartLabels: some View {
        VStack {
            Spacer()
            HStack {
                Text("onboarding_v2.comparison.today".localized)
                Spacer()
                Text("onboarding_v2.comparison.day66".localized)
            }
            .font(.custom("Poppins-Medium", size: 11))
            .foregroundStyle(.white.opacity(0.45))
        }
        .padding(.horizontal, 2)
    }

    private func legend(color: Color, text: String) -> some View {
        HStack(spacing: 7) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(text)
                .font(.custom("Poppins-Medium", size: 12))
                .foregroundStyle(.white.opacity(0.78))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }
}

private struct ComparisonCurve: Shape {
    enum Kind {
        case withCortiFree
        case withoutCortiFree
    }

    let kind: Kind

    func path(in rect: CGRect) -> Path {
        let points: [CGPoint]
        switch kind {
        case .withCortiFree:
            points = [
                CGPoint(x: 0.02, y: 0.80),
                CGPoint(x: 0.18, y: 0.74),
                CGPoint(x: 0.34, y: 0.63),
                CGPoint(x: 0.50, y: 0.52),
                CGPoint(x: 0.67, y: 0.39),
                CGPoint(x: 0.83, y: 0.27),
                CGPoint(x: 0.98, y: 0.18)
            ]
        case .withoutCortiFree:
            points = [
                CGPoint(x: 0.02, y: 0.80),
                CGPoint(x: 0.18, y: 0.72),
                CGPoint(x: 0.34, y: 0.78),
                CGPoint(x: 0.50, y: 0.69),
                CGPoint(x: 0.67, y: 0.75),
                CGPoint(x: 0.83, y: 0.66),
                CGPoint(x: 0.98, y: 0.71)
            ]
        }

        var path = Path()
        guard let first = points.first else { return path }
        path.move(to: scaled(first, in: rect))

        for index in 1..<points.count {
            let previous = scaled(points[index - 1], in: rect)
            let current = scaled(points[index], in: rect)
            let midpointX = (previous.x + current.x) / 2
            path.addCurve(
                to: current,
                control1: CGPoint(x: midpointX, y: previous.y),
                control2: CGPoint(x: midpointX, y: current.y)
            )
        }
        return path
    }

    private func scaled(_ point: CGPoint, in rect: CGRect) -> CGPoint {
        CGPoint(
            x: rect.minX + point.x * rect.width,
            y: rect.minY + point.y * rect.height
        )
    }
}

#Preview {
    CortiFreeComparisonView(previousAppExperience: 1, onBack: {}, onContinue: {})
}
