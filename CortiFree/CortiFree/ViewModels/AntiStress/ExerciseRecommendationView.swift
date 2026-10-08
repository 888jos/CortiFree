//
//  ExerciseRecommendationView.swift
//  CortiFree
//
//  Step 2 of the anti-stress flow: what to do now for the situation picked.
//  Tapping an exercise starts it right away with the app's current players (no intermediate
//  detail page): breathing → BreathingDetailFlowView, others → the matching guided session.
//  The situation's illustration and name on top, the best match as a large illustrated card
//  with a direct start, then the other options as a readable list (illustration, kind,
//  duration, one-line description). No match percentages: they suggested a precision the
//  recommendation engine doesn't have.
//

import SwiftUI

struct ExerciseRecommendationView: View {
    let situation: StressSituation
    @ObservedObject var viewModel: AntiStressViewModel
    /// Closes the whole anti-stress flow (the guided-session player is presented from the root).
    var closeFlow: () -> Void = {}
    @State private var breathingPattern: BreathingPattern?
    @Environment(\.dismiss) var dismiss

    var recommendations: [ExerciseRecommendation] {
        AntiStressRecommendationEngine.recommendations(for: situation)
    }

    var body: some View {
        ZStack {
            PlanBackground(goal: nil)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    header

                    if let best = recommendations.first {
                        sectionTitle("antistress.recommendation.best".localized)
                        BestExerciseCard(exercise: best.exerciseType) { open(best.exerciseType) }
                            .cascadeAppear(index: 0, baseDelay: 0.05)
                    }

                    if recommendations.count > 1 {
                        sectionTitle("antistress.recommendation.more".localized)
                            .padding(.top, 4)
                        VStack(spacing: 10) {
                            ForEach(Array(recommendations.dropFirst().enumerated()), id: \.element.id) { index, recommendation in
                                ExerciseOptionRow(exercise: recommendation.exerciseType) { open(recommendation.exerciseType) }
                                    .cascadeAppear(index: index + 1, baseDelay: 0.05)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    HapticManager.light()
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                }
                .accessibilityLabel("common.back".localized)
            }
        }
        .fullScreenCover(item: $breathingPattern) { pattern in
            BreathingDetailFlowView(pattern: pattern, duration: Double(pattern.defaultMinutes * 60))
        }
    }

    private func open(_ exercise: AntiStressExerciseType) {
        HapticManager.light()
        AnalyticsManager.shared.track(event: "antistress_exercise_started", properties: [
            "situation": situation.rawValue, "exercise": exercise.rawValue
        ])
        if let pattern = exercise.breathingPattern {
            breathingPattern = pattern
        } else if let session = exercise.guidedSession {
            // Same as the chat: close the flow first, the full player lives on the root view.
            closeFlow()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                GuidedSessionPlayer.shared.play(session, presentFullPlayer: true)
            }
        }
    }

    // MARK: - Header: the situation picked

    private var header: some View {
        HStack(spacing: 16) {
            Image(situation.customImageName ?? "situation_recentrer")
                .resizable()
                .scaledToFill()
                .frame(width: 84, height: 84)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(.white.opacity(0.12), lineWidth: 1))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 6) {
                Text(situation.displayName)
                    .font(.faroBold(24))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
                Text("antistress.recommendation.subtitle".localized)
                    .font(Font.Poppins.custom(.regular, size: 14))
                    .foregroundStyle(PlanPalette.secondaryText)
            }
            Spacer(minLength: 0)
        }
        .padding(.top, 8)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(Font.Poppins.custom(.semiBold, size: 13))
            .tracking(0.6)
            .textCase(.uppercase)
            .foregroundStyle(PlanPalette.secondaryText)
            .accessibilityAddTraits(.isHeader)
    }
}

// MARK: - Best match

private struct BestExerciseCard: View {
    let exercise: AntiStressExerciseType
    let onStart: () -> Void

    var body: some View {
        Button(action: onStart) {
            VStack(alignment: .leading, spacing: 0) {
                Image(exercise.artworkImage)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 170)
                    .clipped()
                    .overlay(alignment: .bottom) {
                        LinearGradient(colors: [.clear, .black.opacity(0.35)], startPoint: .top, endPoint: .bottom)
                            .frame(height: 70)
                    }
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 8) {
                    KindLine(exercise: exercise)
                    Text(exercise.displayName)
                        .font(.faroSemiBold(22))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.leading)
                    Text(exercise.description)
                        .font(Font.Poppins.custom(.regular, size: 14))
                        .foregroundStyle(PlanPalette.secondaryText)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    Label("common.start".localized, systemImage: "play.fill")
                        .font(Font.Poppins.custom(.semiBold, size: 15))
                        .foregroundStyle(PlanPalette.deep)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Capsule().fill(PlanPalette.accent))
                        .padding(.top, 6)
                }
                .padding(16)
            }
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
        .buttonStyle(.plain)
        .planGlass(cornerRadius: 24, tint: PlanPalette.accent, interactive: true)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Other options

private struct ExerciseOptionRow: View {
    let exercise: AntiStressExerciseType
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                Image(exercise.artworkImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(.white.opacity(0.10), lineWidth: 1))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    KindLine(exercise: exercise)
                    Text(exercise.displayName)
                        .font(Font.Poppins.custom(.semiBold, size: 16))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    Text(exercise.description)
                        .font(Font.Poppins.custom(.regular, size: 12))
                        .foregroundStyle(PlanPalette.secondaryText)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.35))
            }
            .padding(12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .planGlass(cornerRadius: 22, interactive: true)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }
}

private struct KindLine: View {
    let exercise: AntiStressExerciseType

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: exercise.kind.symbol)
                .font(.system(size: 11, weight: .semibold))
            Text(exercise.kind.localizedName)
            Text("·")
            Text(exercise.durationLabel)
        }
        .font(Font.Poppins.custom(.medium, size: 12))
        .foregroundStyle(PlanPalette.tertiaryText)
    }
}

#Preview {
    NavigationStack {
        ExerciseRecommendationView(
            situation: .overwhelmed,
            viewModel: AntiStressViewModel()
        )
    }
}
