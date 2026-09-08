//
//  HabitsQuizInsightView.swift
//  CortiFree
//

import SwiftUI

struct HabitsQuizInsightView: View {
    enum Mode: Equatable {
        case earlyPattern
        case preliminaryProfile

        var analyticsName: String {
            switch self {
            case .earlyPattern: return "early_pattern"
            case .preliminaryProfile: return "preliminary_profile"
            }
        }
    }

    let mode: Mode
    let answers: [Int]
    let onBack: () -> Void
    let onContinue: () -> Void

    @State private var animateMetrics = false

    var body: some View {
        ZStack {
            GalaxyBackgroundView(intensity: 1.0)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 26) {
                        VStack(spacing: 12) {
                            Text(titleKey.localized)
                                .font(.faroBold(30))
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.center)

                            Text(subtitleKey.localized)
                                .font(.custom("Poppins-Regular", size: 15))
                                .foregroundStyle(.white.opacity(0.62))
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                        }
                        .padding(.horizontal, 28)

                        metricsPanel
                            .padding(.horizontal, 22)

                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(Color(hex: "B794F6"))

                            Text(priorityMessageKey.localized)
                                .font(.custom("Poppins-Medium", size: 14))
                                .foregroundStyle(.white.opacity(0.86))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.horizontal, 32)
                    }
                    .padding(.top, 24)
                    .padding(.bottom, 24)
                }

                Button(action: {
                    HapticManager.medium()
                    MixpanelManager.shared.track(
                        event: "onboarding_quiz_transition_continued",
                        properties: ["transition_type": mode.analyticsName]
                    )
                    onContinue()
                }) {
                    HStack(spacing: 10) {
                        Text(ctaKey.localized)
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
                properties: ["transition_type": mode.analyticsName]
            )
            withAnimation(.easeOut(duration: 1.0).delay(0.15)) {
                animateMetrics = true
            }
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

    private var metricsPanel: some View {
        VStack(spacing: 20) {
            ForEach(metrics) { metric in
                VStack(spacing: 8) {
                    HStack {
                        Label(metric.labelKey.localized, systemImage: metric.icon)
                            .font(.custom("Poppins-Medium", size: 14))
                            .foregroundStyle(.white.opacity(0.86))

                        Spacer()

                        Text(statusKey(for: metric.score).localized)
                            .font(.custom("Poppins-SemiBold", size: 12))
                            .foregroundStyle(metric.color)
                    }

                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.09))
                            Capsule()
                                .fill(metric.color)
                                .frame(
                                    width: animateMetrics
                                        ? geometry.size.width * Double(metric.score) / 100
                                        : 0
                                )
                        }
                    }
                    .frame(height: 9)
                }
            }
        }
        .padding(20)
        .background(Color(hex: "111032").opacity(0.88))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        }
    }

    private var metrics: [InsightMetric] {
        switch mode {
        case .earlyPattern:
            return [
                InsightMetric(
                    id: "evening",
                    labelKey: "onboarding_v2.insight.metric.evening",
                    icon: "moon.stars.fill",
                    score: score(forQuestion: 0),
                    color: Color(hex: "B794F6"),
                    priorityKey: "onboarding_v2.insight.pattern.priority.evening"
                ),
                InsightMetric(
                    id: "social",
                    labelKey: "onboarding_v2.insight.metric.social",
                    icon: "person.2.fill",
                    score: score(forQuestion: 1),
                    color: Color(hex: "4CC6FF"),
                    priorityKey: "onboarding_v2.insight.pattern.priority.social"
                ),
                InsightMetric(
                    id: "sleep",
                    labelKey: "onboarding_v2.insight.metric.sleep",
                    icon: "bed.double.fill",
                    score: score(forQuestion: 2),
                    color: Color(hex: "67DB3D"),
                    priorityKey: "onboarding_v2.insight.pattern.priority.sleep"
                )
            ]
        case .preliminaryProfile:
            let result = HabitsQuizResult(answers: answers)
            return [
                InsightMetric(
                    id: "calm",
                    labelKey: "onboarding_v2.insight.metric.calm",
                    icon: "wind",
                    score: result.serenityScore,
                    color: Color(hex: "B794F6"),
                    priorityKey: "onboarding_v2.insight.profile.priority.calm"
                ),
                InsightMetric(
                    id: "sleep",
                    labelKey: "onboarding_v2.insight.metric.sleep",
                    icon: "moon.fill",
                    score: result.sleepScore,
                    color: Color(hex: "4CC6FF"),
                    priorityKey: "onboarding_v2.insight.profile.priority.sleep"
                ),
                InsightMetric(
                    id: "energy",
                    labelKey: "onboarding_v2.insight.metric.energy",
                    icon: "bolt.fill",
                    score: result.energyScore,
                    color: Color(hex: "F6C85F"),
                    priorityKey: "onboarding_v2.insight.profile.priority.energy"
                ),
                InsightMetric(
                    id: "focus",
                    labelKey: "onboarding_v2.insight.metric.focus",
                    icon: "scope",
                    score: result.focusScore,
                    color: Color(hex: "67DB3D"),
                    priorityKey: "onboarding_v2.insight.profile.priority.focus"
                )
            ]
        }
    }

    private var priorityMessageKey: String {
        metrics.min(by: { $0.score < $1.score })?.priorityKey
            ?? "onboarding_v2.insight.profile.priority.calm"
    }

    private var titleKey: String {
        mode == .earlyPattern
            ? "onboarding_v2.insight.pattern.title"
            : "onboarding_v2.insight.profile.title"
    }

    private var subtitleKey: String {
        mode == .earlyPattern
            ? "onboarding_v2.insight.pattern.subtitle"
            : "onboarding_v2.insight.profile.subtitle"
    }

    private var ctaKey: String {
        mode == .earlyPattern
            ? "onboarding_v2.insight.pattern.cta"
            : "onboarding_v2.insight.profile.cta"
    }

    private func score(forQuestion index: Int) -> Int {
        let questions = getAllHabitsQuestions()
        guard questions.indices.contains(index), answers.indices.contains(index) else { return 50 }
        let question = questions[index]
        let answer = answers[index]
        guard question.scoring.indices.contains(answer) else { return 50 }
        return question.scoring[answer]
    }

    private func statusKey(for score: Int) -> String {
        switch score {
        case ..<45: return "onboarding_v2.insight.status.support"
        case ..<75: return "onboarding_v2.insight.status.building"
        default: return "onboarding_v2.insight.status.strong"
        }
    }
}

private struct InsightMetric: Identifiable {
    let id: String
    let labelKey: String
    let icon: String
    let score: Int
    let color: Color
    let priorityKey: String
}

#Preview("Early pattern") {
    HabitsQuizInsightView(
        mode: .earlyPattern,
        answers: [0, 1, 0] + Array(repeating: 0, count: 9),
        onBack: {},
        onContinue: {}
    )
}

#Preview("Preliminary profile") {
    HabitsQuizInsightView(
        mode: .preliminaryProfile,
        answers: [0, 1, 0, 1, 2, 0, 1, 2] + Array(repeating: 0, count: 4),
        onBack: {},
        onContinue: {}
    )
}
