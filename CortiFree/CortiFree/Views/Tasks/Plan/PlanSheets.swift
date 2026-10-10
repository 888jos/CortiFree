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
        // Goal-based reasons read as a written sentence per goal, not the goal's name in quotes.
        if let goal = arg.flatMap(PlanGoal.init(rawValue:)), key != "primary_default" {
            let family = key.hasPrefix("primary") ? "primary" : key
            let writtenKey = "plan.why.\(family).\(goal.rawValue)"
            let written = writtenKey.localized
            if written != writtenKey { return (symbol(for: key, arg: arg), written) }
        }
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

                    // 2×2 grid of illustrated goals; the fifth one gets a full-width card below.
                    VStack(spacing: 12) {
                        // Grid (not LazyVGrid): both cards of a row share the same height.
                        let firstFour = Array(PlanGoal.allCases.prefix(4))
                        Grid(horizontalSpacing: 12, verticalSpacing: 12) {
                            ForEach(0..<2, id: \.self) { row in
                                GridRow {
                                    ForEach(firstFour[(row * 2)..<(row * 2 + 2)]) { goal in
                                        goalTile(goal)
                                    }
                                }
                            }
                        }
                        ForEach(PlanGoal.allCases.dropFirst(4)) { goal in
                            goalWideTile(goal)
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

    private func isSelected(_ goal: PlanGoal) -> Bool { (selected ?? currentGoal) == goal }

    private func select(_ goal: PlanGoal) {
        HapticManager.light()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) { selected = goal }
    }

    /// Square illustration on top, name and promise below.
    private func goalTile(_ goal: PlanGoal) -> some View {
        Button { select(goal) } label: {
            VStack(alignment: .leading, spacing: 10) {
                goalArtwork(goal)
                    .aspectRatio(1, contentMode: .fit)
                VStack(alignment: .leading, spacing: 3) {
                    Text(goal.localizedName)
                        .font(Font.Poppins.custom(.semiBold, size: 15))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text(goal.localizedPromise)
                        .font(Font.Poppins.custom(.regular, size: 11))
                        .foregroundStyle(.white.opacity(0.6))
                        .multilineTextAlignment(.leading)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 4)
                Spacer(minLength: 0)
            }
            .padding(8)
            .frame(maxHeight: .infinity, alignment: .top)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .modifier(GoalCardStyle(goal: goal, isSelected: isSelected(goal)))
    }

    /// The odd goal out: same card, laid out wide.
    private func goalWideTile(_ goal: PlanGoal) -> some View {
        Button { select(goal) } label: {
            HStack(spacing: 14) {
                goalArtwork(goal)
                    .frame(width: 92, height: 92)
                VStack(alignment: .leading, spacing: 3) {
                    Text(goal.localizedName)
                        .font(Font.Poppins.custom(.semiBold, size: 15))
                        .foregroundStyle(.white)
                    Text(goal.localizedPromise)
                        .font(Font.Poppins.custom(.regular, size: 12))
                        .foregroundStyle(.white.opacity(0.6))
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            .padding(8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .modifier(GoalCardStyle(goal: goal, isSelected: isSelected(goal)))
    }

    private func goalArtwork(_ goal: PlanGoal) -> some View {
        Color.clear
            .overlay(Image(goal.artworkName).resizable().scaledToFill())
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(alignment: .topLeading) {
                if goal == currentGoal {
                    Text("plan.change.current".localized)
                        .font(Font.Poppins.custom(.medium, size: 10))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 7).padding(.vertical, 3)
                        .background(Capsule().fill(.black.opacity(0.45)))
                        .padding(6)
                }
            }
            .overlay(alignment: .topTrailing) {
                Image(systemName: isSelected(goal) ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(isSelected(goal) ? PlanPalette.accent : .white.opacity(0.85))
                    .background(Circle().fill(.black.opacity(0.25)).padding(2))
                    .padding(6)
            }
            .accessibilityHidden(true)
    }
}

/// Glass card with an accent outline when picked.
private struct GoalCardStyle: ViewModifier {
    let goal: PlanGoal
    let isSelected: Bool

    func body(content: Content) -> some View {
        content
            .planGlass(cornerRadius: 20, tint: isSelected ? goal.colors.last : nil)
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(isSelected ? PlanPalette.accent : .clear, lineWidth: 2)
            )
            .scaleEffect(isSelected ? 1 : 0.98)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}
