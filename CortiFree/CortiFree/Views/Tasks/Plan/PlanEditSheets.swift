//
//  PlanEditSheets.swift
//  CortiFree
//
//  Plan editing UI: replace an item (with "don't suggest again"), add an item to a day,
//  and the undo banner shown after an edit. Operations live in PersonalPlanStore.
//

import SwiftUI

// MARK: - Swap

struct PlanSwapSheet: View {
    let item: PlanItem
    let week: Int
    let alternatives: [PlanItem]
    let onSelect: (PlanItem, _ excludeOld: Bool) -> Void

    @State private var excludeOld = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let current = item.display(week: week, short: false)
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("plan.swap.title".localized)
                        .font(.faroBold(26))
                        .foregroundStyle(.white)
                    Text(String(format: "plan.swap.subtitle".localized, current.title))
                        .font(Font.Poppins.custom(.regular, size: 14))
                        .foregroundStyle(PlanPalette.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)

                    if alternatives.isEmpty {
                        Text("plan.swap.empty".localized)
                            .font(Font.Poppins.custom(.regular, size: 14))
                            .foregroundStyle(PlanPalette.secondaryText)
                            .padding(.vertical, 20)
                    } else {
                        PlanGlassGroup {
                            VStack(spacing: 10) {
                                ForEach(alternatives, id: \.refID) { candidate in
                                    PlanChoiceRow(display: candidate.display(week: week, short: false)) {
                                        HapticManager.success()
                                        onSelect(candidate, excludeOld)
                                        dismiss()
                                    }
                                }
                            }
                        }
                    }

                    Toggle(isOn: $excludeOld) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("plan.swap.exclude".localized)
                                .font(Font.Poppins.custom(.semiBold, size: 15))
                                .foregroundStyle(.white)
                            Text("plan.swap.exclude_subtitle".localized)
                                .font(Font.Poppins.custom(.regular, size: 12))
                                .foregroundStyle(PlanPalette.secondaryText)
                        }
                    }
                    .tint(PlanPalette.accent)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .planGlass(cornerRadius: 20)
                }
                .padding(20)
            }
            .background(PlanBackground(goal: nil))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: { Image(systemName: "xmark") }
                        .tint(.white)
                        .accessibilityLabel("plan.close".localized)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationBackground(PlanPalette.deep)
    }
}

// MARK: - Add

struct PlanAddSheet: View {
    let week: Int
    let suggestions: [PlanItem]
    let onSelect: (PlanItem) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("plan.add.title".localized)
                        .font(.faroBold(26))
                        .foregroundStyle(.white)
                    Text("plan.add.subtitle".localized)
                        .font(Font.Poppins.custom(.regular, size: 14))
                        .foregroundStyle(PlanPalette.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)

                    PlanGlassGroup {
                        VStack(spacing: 10) {
                            ForEach(suggestions, id: \.refID) { candidate in
                                PlanChoiceRow(display: candidate.display(week: week, short: false), symbol: "plus") {
                                    HapticManager.success()
                                    onSelect(candidate)
                                    dismiss()
                                }
                            }
                        }
                    }
                }
                .padding(20)
            }
            .background(PlanBackground(goal: nil))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: { Image(systemName: "xmark") }
                        .tint(.white)
                        .accessibilityLabel("plan.close".localized)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationBackground(PlanPalette.deep)
    }
}

// MARK: - Choice row

struct PlanChoiceRow: View {
    let display: PlanItemDisplay
    var symbol = "arrow.triangle.2.circlepath"
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                PlanThumbnail(display: display, size: 52, cornerRadius: 14)
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(display.kindLabel)
                        if let duration = display.durationLabel {
                            Text("·")
                            Text(duration)
                        }
                    }
                    .font(Font.Poppins.custom(.medium, size: 12))
                    .foregroundStyle(PlanPalette.tertiaryText)
                    Text(display.title)
                        .font(Font.Poppins.custom(.semiBold, size: 15))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
                Image(systemName: symbol)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(PlanPalette.accent)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(PlanPalette.accent.opacity(0.15)))
            }
            .padding(12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .planGlass(cornerRadius: 20, interactive: true)
    }
}

// MARK: - Undo banner

struct PlanUndoBanner: View {
    let onUndo: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(PlanPalette.done)
            Text("plan.edit.updated".localized)
                .font(Font.Poppins.custom(.medium, size: 14))
                .foregroundStyle(.white)
            Spacer(minLength: 8)
            Button {
                HapticManager.light()
                onUndo()
            } label: {
                Text("plan.edit.undo".localized)
                    .font(Font.Poppins.custom(.semiBold, size: 14))
                    .foregroundStyle(PlanPalette.accent)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .planGlass(cornerRadius: 18)
    }
}
