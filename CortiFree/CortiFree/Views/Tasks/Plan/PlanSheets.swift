//
//  PlanSheets.swift
//  CortiFree
//
//  "Why this plan" explanation (plain words, from the stored insight codes — never scores)
//  and the goal picker used to change goal / regenerate / start a follow-up cycle.
//

import SwiftUI

// MARK: - Insight text

enum PlanInsightText {
    /// Converts "key" or "key:arg" codes to sentences.
    static func sentence(for code: String) -> (symbol: String, text: String) {
        let parts = code.split(separator: ":", maxSplits: 1).map(String.init)
        let key = parts[0]
        let arg = parts.count > 1 ? parts[1] : nil
        let template = "plan.why.\(key)".localized

        var argText = ""
        if let arg {
            if let goal = PlanGoal(rawValue: arg) {
                argText = goal.localizedName
            } else {
                argText = "plan.habit.\(arg).name".localized
            }
        }
        let text = template.contains("%@") ? String(format: template, argText) : template
        return (symbol(for: key, arg: arg), text)
    }

    private static func symbol(for key: String, arg: String?) -> String {
        switch key {
        case let k where k.hasPrefix("primary"): return arg.flatMap(PlanGoal.init(rawValue:))?.symbol ?? "target"
        case "secondary": return arg.flatMap(PlanGoal.init(rawValue:))?.symbol ?? "plus.circle"
        case "gentle": return "tortoise.fill"
        case "recent": return "sparkles"
        case "compact": return "hourglass"
        case "tension": return "figure.mind.and.body"
        case "palpitations": return "heart.text.square"
        case "evening": return "moon.stars.fill"
        case "racing_mind": return "cloud.fill"
        case "isolation": return "person.2.fill"
        case "anxiety_check": return "waveform.path.ecg"
        case "anchor": return PlanItem.habitSymbol(arg ?? "")
        case "progression": return "chart.line.uptrend.xyaxis"
        default: return "checkmark.seal"
        }
    }
}

// MARK: - Why sheet

struct PlanWhySheet: View {
    let plan: PersonalPlan
    let onChangeGoal: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Image(systemName: plan.goal.symbol)
                            .font(.system(size: 26, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 56, height: 56)
                            .background(Circle().fill(LinearGradient(colors: plan.goal.colors, startPoint: .topLeading, endPoint: .bottomTrailing)))
                        Text(plan.localizedTitle)
                            .font(.faroBold(26))
                            .foregroundStyle(.white)
                        Text("plan.why.subtitle".localized)
                            .font(Font.Poppins.custom(.regular, size: 14))
                            .foregroundStyle(.white.opacity(0.65))
                    }

                    PlanGlassGroup {
                        VStack(spacing: 10) {
                            ForEach(plan.insights, id: \.self) { code in
                                let sentence = PlanInsightText.sentence(for: code)
                                HStack(alignment: .top, spacing: 14) {
                                    Image(systemName: sentence.symbol)
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundStyle(PlanPalette.accent)
                                        .frame(width: 32, height: 32)
                                        .background(Circle().fill(PlanPalette.accent.opacity(0.15)))
                                    Text(sentence.text)
                                        .font(Font.Poppins.custom(.regular, size: 14))
                                        .foregroundStyle(.white.opacity(0.9))
                                        .fixedSize(horizontal: false, vertical: true)
                                    Spacer(minLength: 0)
                                }
                                .padding(14)
                                .planGlass(cornerRadius: 18)
                            }
                        }
                    }

                    // Week themes
                    VStack(alignment: .leading, spacing: 10) {
                        Text("plan.why.weeks_title".localized)
                            .font(Font.Poppins.custom(.semiBold, size: 16))
                            .foregroundStyle(.white)
                        ForEach(Array(PlanWeekTheme.allCases.enumerated()), id: \.offset) { index, theme in
                            HStack(alignment: .top, spacing: 12) {
                                Text("\(index + 1)")
                                    .font(Font.Poppins.custom(.semiBold, size: 13))
                                    .foregroundStyle(.white)
                                    .frame(width: 26, height: 26)
                                    .background(Circle().fill(PlanPalette.accent.opacity(0.3)))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(theme.localizedTitle)
                                        .font(Font.Poppins.custom(.semiBold, size: 14))
                                        .foregroundStyle(.white)
                                    Text(theme.localizedSubtitle)
                                        .font(Font.Poppins.custom(.regular, size: 12))
                                        .foregroundStyle(.white.opacity(0.6))
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                    }

                    Button {
                        HapticManager.light()
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { onChangeGoal() }
                    } label: {
                        Label("plan.change.button".localized, systemImage: "arrow.triangle.2.circlepath")
                            .font(Font.Poppins.custom(.semiBold, size: 15))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                    }
                    .planGlassButtonStyle(prominent: false)

                    Text("plan.why.footer".localized)
                        .font(Font.Poppins.custom(.regular, size: 11))
                        .foregroundStyle(.white.opacity(0.45))
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                }
                .padding(20)
            }
            .background(PlanBackground(goal: plan.goal))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: { Image(systemName: "xmark") }
                        .tint(.white)
                        .accessibilityLabel("plan.close".localized)
                }
            }
        }
        .presentationDetents([.large])
        .presentationBackground(PlanPalette.deep)
    }
}

// MARK: - Goal picker

struct PlanGoalPickerSheet: View {
    enum Mode { case change, nextCycle }

    let currentGoal: PlanGoal?
    let mode: Mode
    let onConfirm: (PlanGoal) -> Void
    @State private var selected: PlanGoal?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("plan.change.title".localized)
                        .font(.faroBold(26))
                        .foregroundStyle(.white)
                    Text((mode == .change ? "plan.change.subtitle" : "plan.change.subtitle_cycle").localized)
                        .font(Font.Poppins.custom(.regular, size: 14))
                        .foregroundStyle(.white.opacity(0.65))
                        .fixedSize(horizontal: false, vertical: true)

                    PlanGlassGroup {
                        VStack(spacing: 10) {
                            ForEach(PlanGoal.allCases) { goal in
                                goalRow(goal)
                            }
                        }
                    }

                    Button {
                        guard let goal = selected ?? currentGoal else { return }
                        HapticManager.success()
                        onConfirm(goal)
                        dismiss()
                    } label: {
                        Text("plan.change.confirm".localized)
                            .font(Font.Poppins.custom(.semiBold, size: 16))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                    .planGlassButtonStyle(prominent: true)
                    .disabled((selected ?? currentGoal) == nil)
                    .padding(.top, 6)
                }
                .padding(20)
            }
            .background(PlanBackground(goal: selected ?? currentGoal))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: { Image(systemName: "xmark") }
                        .tint(.white)
                        .accessibilityLabel("plan.close".localized)
                }
            }
        }
        .presentationDetents([.large])
        .presentationBackground(PlanPalette.deep)
        .onAppear { selected = currentGoal }
    }

    private func goalRow(_ goal: PlanGoal) -> some View {
        let isSelected = (selected ?? currentGoal) == goal
        return Button {
            HapticManager.light()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) { selected = goal }
        } label: {
            HStack(spacing: 14) {
                Image(systemName: goal.symbol)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 46, height: 46)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(LinearGradient(colors: goal.colors, startPoint: .topLeading, endPoint: .bottomTrailing)))
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(goal.localizedName)
                            .font(Font.Poppins.custom(.semiBold, size: 15))
                            .foregroundStyle(.white)
                        if goal == currentGoal {
                            Text("plan.change.current".localized)
                                .font(Font.Poppins.custom(.medium, size: 10))
                                .foregroundStyle(.white.opacity(0.8))
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(Capsule().fill(.white.opacity(0.12)))
                        }
                    }
                    Text(goal.localizedPromise)
                        .font(Font.Poppins.custom(.regular, size: 12))
                        .foregroundStyle(.white.opacity(0.6))
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(isSelected ? PlanPalette.accent : .white.opacity(0.3))
            }
            .padding(14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .planGlass(cornerRadius: 20, tint: isSelected ? goal.colors.last : nil, interactive: true)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
