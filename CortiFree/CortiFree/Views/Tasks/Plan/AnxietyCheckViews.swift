//
//  AnxietyCheckViews.swift
//  CortiFree
//
//  GAD-7 anxiety check in the Plan tab: the reminder card (days 1, 14, 28) and the
//  questionnaire sheet (intro + optional Apple Health connection → 7 questions → result).
//

import SwiftUI

// MARK: - Card

struct PlanAnxietyCheckCard: View {
    let checkpoint: Int
    let onStart: () -> Void
    let onLater: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: "waveform.path.ecg")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(PlanPalette.accent)
                    .frame(width: 42, height: 42)
                    .background(Circle().fill(PlanPalette.accent.opacity(0.15)))
                VStack(alignment: .leading, spacing: 4) {
                    Text("anxiety_check.card.title".localized)
                        .font(.faroSemiBold(18))
                        .foregroundStyle(.white)
                    Text((checkpoint == 1 ? "anxiety_check.card.subtitle_first" : "anxiety_check.card.subtitle_progress").localized)
                        .font(Font.Poppins.custom(.regular, size: 13))
                        .foregroundStyle(PlanPalette.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            HStack(spacing: 10) {
                Button {
                    HapticManager.medium()
                    onStart()
                } label: {
                    Text("anxiety_check.card.start".localized)
                        .font(Font.Poppins.custom(.semiBold, size: 14))
                        .padding(.horizontal, 4)
                }
                .planGlassButtonStyle(prominent: true)
                Button {
                    HapticManager.light()
                    onLater()
                } label: {
                    Text("anxiety_check.card.later".localized)
                        .font(Font.Poppins.custom(.medium, size: 14))
                        .foregroundStyle(.white)
                }
                .planGlassButtonStyle(prominent: false)
            }
        }
        .padding(18)
        .planGlass(cornerRadius: 26, tint: PlanPalette.accent)
    }
}

// MARK: - Sheet

struct AnxietyCheckSheet: View {
    let checkpoint: Int
    /// Called once a result is saved (taken in the app or imported from Health).
    let onComplete: (AnxietyCheckResult) -> Void

    private enum Step: Equatable { case intro, question(Int), result }

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var health = HealthKitService.shared
    @State private var step: Step = .intro
    @State private var answers: [Int?] = Array(repeating: nil, count: AnxietyCheck.questionCount)
    @State private var result: AnxietyCheckResult?
    @State private var isConnecting = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    switch step {
                    case .intro: intro
                    case .question(let index): question(index)
                    case .result: resultView
                    }

                    Text("anxiety_check.disclaimer".localized)
                        .font(Font.Poppins.custom(.regular, size: 11))
                        .foregroundStyle(PlanPalette.tertiaryText)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 8)
                }
                .padding(20)
                .animation(.spring(response: 0.35, dampingFraction: 0.85), value: step)
            }
            .scrollIndicators(.hidden)
            .background(PlanBackground(goal: nil))
            .toolbar {
                if case .question(let index) = step {
                    ToolbarItem(placement: .topBarLeading) {
                        Button { step = index == 0 ? .intro : .question(index - 1) } label: { Image(systemName: "chevron.left") }
                            .tint(.white)
                            .accessibilityLabel("anxiety_check.back".localized)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: { Image(systemName: "xmark") }
                        .tint(.white)
                        .accessibilityLabel("plan.close".localized)
                }
            }
        }
        .presentationDetents([.large])
        .presentationBackground(PlanPalette.deep)
        .interactiveDismissDisabled(step != .intro && step != .result)
    }

    // MARK: Intro

    private var intro: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("anxiety_check.title".localized)
                .font(.faroBold(28))
                .foregroundStyle(.white)
            Text((checkpoint == 1 ? "anxiety_check.intro_first" : "anxiety_check.intro_progress").localized)
                .font(Font.Poppins.custom(.regular, size: 15))
                .foregroundStyle(.white.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)

            Label("anxiety_check.duration".localized, systemImage: "clock")
                .font(Font.Poppins.custom(.medium, size: 13))
                .foregroundStyle(PlanPalette.secondaryText)

            Button {
                HapticManager.medium()
                step = .question(0)
            } label: {
                Text("anxiety_check.begin".localized)
                    .font(Font.Poppins.custom(.semiBold, size: 16))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .planGlassButtonStyle(prominent: true)

            if health.isAvailable && !health.isEnabled {
                healthConnect
            }
        }
    }

    private var healthConnect: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color(hex: "FF5A6E"))
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(.white.opacity(0.9)))
                Text("health.connect.title".localized)
                    .font(Font.Poppins.custom(.semiBold, size: 15))
                    .foregroundStyle(.white)
            }
            Text("health.connect.subtitle".localized)
                .font(Font.Poppins.custom(.regular, size: 13))
                .foregroundStyle(PlanPalette.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
            Button {
                Task { await connectHealth() }
            } label: {
                HStack {
                    if isConnecting { ProgressView().tint(.white) }
                    Text("health.connect.button".localized)
                        .font(Font.Poppins.custom(.semiBold, size: 14))
                        .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity)
            }
            .planGlassButtonStyle(prominent: false)
            .disabled(isConnecting)
        }
        .padding(16)
        .planGlass(cornerRadius: 22)
    }

    private func connectHealth() async {
        isConnecting = true
        defer { isConnecting = false }
        guard await health.enable() else { return }
        // A questionnaire already taken in the Health app can replace this one.
        let before = AnxietyCheckStore.shared.latest
        await AnxietyCheckStore.shared.importFromHealth()
        if let imported = AnxietyCheckStore.shared.latest, imported != before, imported.source == .health,
           imported.date > Date().addingTimeInterval(-14 * 86_400) {
            finish(with: imported)
        }
    }

    // MARK: Questions

    private func question(_ index: Int) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            ProgressView(value: Double(index + 1), total: Double(AnxietyCheck.questionCount))
                .tint(PlanPalette.accent)
            Text(String(format: "anxiety_check.progress".localized, index + 1, AnxietyCheck.questionCount))
                .font(Font.Poppins.custom(.medium, size: 12))
                .foregroundStyle(PlanPalette.secondaryText)
            Text("anxiety_check.prompt".localized)
                .font(Font.Poppins.custom(.regular, size: 14))
                .foregroundStyle(.white.opacity(0.7))
                .fixedSize(horizontal: false, vertical: true)
            Text(AnxietyCheck.questionKey(index).localized)
                .font(.faroSemiBold(22))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)

            VStack(spacing: 10) {
                ForEach(Array(AnxietyCheck.answerRange), id: \.self) { value in
                    answerButton(question: index, value: value)
                }
            }
        }
        .id(index)
        .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .opacity))
    }

    private func answerButton(question index: Int, value: Int) -> some View {
        let isSelected = answers[index] == value
        return Button {
            HapticManager.light()
            answers[index] = value
            if index + 1 < AnxietyCheck.questionCount {
                step = .question(index + 1)
            } else {
                finish(with: AnxietyCheckResult(date: Date(), answers: answers.map { $0 ?? 0 }, source: .app))
            }
        } label: {
            HStack {
                Text(AnxietyCheck.answerKey(value).localized)
                    .font(Font.Poppins.custom(isSelected ? .semiBold : .medium, size: 15))
                    .foregroundStyle(.white)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(PlanPalette.accent)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .planGlass(cornerRadius: 18, tint: isSelected ? PlanPalette.accent : nil, interactive: true)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func finish(with newResult: AnxietyCheckResult) {
        if newResult.source == .app {
            AnxietyCheckStore.shared.record(newResult)
        }
        result = newResult
        step = .result
        onComplete(newResult)
    }

    // MARK: Result

    @ViewBuilder
    private var resultView: some View {
        if let result {
            let severity = result.severity
            VStack(alignment: .leading, spacing: 18) {
                Text("anxiety_check.result.title".localized)
                    .font(.faroBold(28))
                    .foregroundStyle(.white)

                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("\(result.score)")
                            .font(.faroBold(44))
                            .foregroundStyle(.white)
                        Text("/ 21")
                            .font(Font.Poppins.custom(.medium, size: 16))
                            .foregroundStyle(PlanPalette.secondaryText)
                        Spacer()
                        Text(severity.localizedName)
                            .font(Font.Poppins.custom(.semiBold, size: 13))
                            .foregroundStyle(PlanPalette.deep)
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .background(Capsule().fill(PlanPalette.accent))
                    }
                    Text(severity.localizedDescription)
                        .font(Font.Poppins.custom(.regular, size: 14))
                        .foregroundStyle(.white.opacity(0.85))
                        .fixedSize(horizontal: false, vertical: true)
                    if let comparison = comparison(for: result) {
                        Text(comparison.text)
                            .font(Font.Poppins.custom(.medium, size: 14))
                            .foregroundStyle(comparison.improved ? PlanPalette.done : PlanPalette.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    if result.source == .health {
                        Label("anxiety_check.result.imported".localized, systemImage: "heart.fill")
                            .font(Font.Poppins.custom(.regular, size: 12))
                            .foregroundStyle(PlanPalette.secondaryText)
                    }
                }
                .padding(18)
                .planGlass(cornerRadius: 24)

                if severity == .severe {
                    supportCard
                }

                if checkpoint == 1 {
                    Label("anxiety_check.result.plan_adjusted".localized, systemImage: "slider.horizontal.3")
                        .font(Font.Poppins.custom(.regular, size: 13))
                        .foregroundStyle(.white.opacity(0.8))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Button {
                    HapticManager.medium()
                    dismiss()
                } label: {
                    Text("anxiety_check.result.done".localized)
                        .font(Font.Poppins.custom(.semiBold, size: 16))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .planGlassButtonStyle(prominent: true)
            }
            .transition(.opacity)
        }
    }

    private var supportCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("anxiety_check.support.title".localized, systemImage: "person.2.wave.2.fill")
                .font(Font.Poppins.custom(.semiBold, size: 15))
                .foregroundStyle(.white)
            Text("anxiety_check.support.body".localized)
                .font(Font.Poppins.custom(.regular, size: 13))
                .foregroundStyle(.white.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .planGlass(cornerRadius: 20, tint: Color(hex: "FF8A65"))
    }

    /// "Down from 14 at the start of your plan" — only when an earlier check exists.
    private func comparison(for result: AnxietyCheckResult) -> (text: String, improved: Bool)? {
        guard checkpoint > 1,
              let plan = PersonalPlanStore.shared.plan,
              let baseline = AnxietyCheckStore.shared.baseline(for: plan),
              baseline.date < result.date else { return nil }
        let delta = result.score - baseline.score
        let key = delta < 0 ? "anxiety_check.result.lower" : delta == 0 ? "anxiety_check.result.same" : "anxiety_check.result.higher"
        return (String(format: key.localized, baseline.score), delta < 0)
    }
}
