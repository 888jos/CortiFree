//
//  BreathingListView.swift
//  CortiFree
//
//  Created by Claude on 23/10/2025.
//  Breathing catalogue: 14 exercises grouped by category, with filter chips.
//

import SwiftUI

struct BreathingListView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var languageManager = LanguageManager.shared

    /// nil = all categories
    @State private var selectedCategory: BreathingCategory?
    @State private var selectedBreathingPattern: BreathingPattern?
    @State private var quickStartPattern: BreathingPattern?

    init(initialCategory: BreathingCategory? = nil) {
        _selectedCategory = State(initialValue: initialCategory)
    }

    private var visibleCategories: [BreathingCategory] {
        if let selectedCategory { return [selectedCategory] }
        return BreathingCategory.displayOrder
    }

    private func patterns(in category: BreathingCategory) -> [BreathingPattern] {
        BreathingPattern.allPatterns.filter { $0.category == category }
    }

    var body: some View {
        ZStack {
            BreathingBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    filterChips

                    ForEach(visibleCategories) { category in
                        section(for: category)
                    }
                }
                .padding(.bottom, 40)
                .animation(.spring(response: 0.4, dampingFraction: 0.85), value: selectedCategory)
            }
            .id(languageManager.refreshID)
        }
        .environment(\.colorScheme, .dark)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(item: $selectedBreathingPattern) { pattern in
            BreathingExerciseDetailView(pattern: pattern)
        }
        .fullScreenCover(item: $quickStartPattern) { pattern in
            BreathingDetailFlowView(pattern: pattern, duration: Double(pattern.defaultMinutes * 60))
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 16) {
            BreathingIconButton(systemName: "chevron.left", accessibilityLabel: languageManager.localized("breathing.session.close")) {
                dismiss()
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(languageManager.localized("breathing.catalog.title"))
                    .font(.faroBold(32))
                    .foregroundStyle(.white)
                Text(String(format: languageManager.localized("breathing.catalog.subtitle"), BreathingPattern.allPatterns.count))
                    .font(.custom("Poppins-Regular", size: 15))
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }

    // MARK: - Filter chips

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            BreathingGlassGroup(spacing: 8) {
                HStack(spacing: 8) {
                    chip(title: languageManager.localized("breathing.category.all"), symbol: "square.grid.2x2.fill", color: BreathingPalette.violet, isSelected: selectedCategory == nil) {
                        selectedCategory = nil
                    }
                    ForEach(BreathingCategory.displayOrder) { category in
                        chip(title: category.localizedTitle, symbol: category.symbol, color: category.color, isSelected: selectedCategory == category) {
                            selectedCategory = (selectedCategory == category) ? nil : category
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 4)
            }
        }
    }

    private func chip(title: String, symbol: String, color: Color, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button {
            HapticManager.light()
            action()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: symbol)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(isSelected ? .white : color)
                Text(title)
                    .font(.custom(isSelected ? "Poppins-SemiBold" : "Poppins-Medium", size: 14))
                    .foregroundStyle(.white.opacity(isSelected ? 1 : 0.8))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .breathingGlassCapsule(tint: isSelected ? color.opacity(0.5) : nil)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: - Section

    @ViewBuilder
    private func section(for category: BreathingCategory) -> some View {
        let items = patterns(in: category)
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: category.symbol)
                        .foregroundStyle(category.color)
                    Text(category.localizedTitle)
                        .font(.custom("Poppins-SemiBold", size: 18))
                        .foregroundStyle(.white)
                    Spacer()
                }
                .accessibilityAddTraits(.isHeader)

                Text(languageManager.localized("breathing.category.\(category.rawValue).subtitle"))
                    .font(.custom("Poppins-Regular", size: 13))
                    .foregroundStyle(.white.opacity(0.6))
                    .padding(.top, -6)

                ForEach(items) { pattern in
                    BreathingCatalogCard(
                        pattern: pattern,
                        onOpen: { selectedBreathingPattern = pattern },
                        onQuickStart: { quickStartPattern = pattern }
                    )
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Category order

extension BreathingCategory {
    static let displayOrder: [BreathingCategory] = [.calm, .sos, .sleep, .focus, .energy]
}

// MARK: - Catalogue card

struct BreathingCatalogCard: View {
    let pattern: BreathingPattern
    let onOpen: () -> Void
    let onQuickStart: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Button {
                HapticManager.light()
                onOpen()
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: pattern.symbol)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(pattern.accentColor)
                        .frame(width: 48, height: 48)
                        .background(
                            RoundedRectangle(cornerRadius: 15, style: .continuous)
                                .fill(pattern.accentColor.opacity(0.16))
                        )

                    VStack(alignment: .leading, spacing: 4) {
                        Text(pattern.localizedTitle)
                            .font(.custom("Poppins-SemiBold", size: 16))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        Text(pattern.localizedBenefit)
                            .font(.custom("Poppins-Regular", size: 13))
                            .foregroundStyle(.white.opacity(0.68))
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                        HStack(spacing: 8) {
                            Text(pattern.rhythmLabel)
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundStyle(pattern.accentColor)
                            BreathingPatternPreview(pattern: pattern, cycles: pattern.totalCycleDuration < 4 ? 3 : 2, lineWidth: 1.8)
                                .frame(width: 54, height: 14)
                            Text("· \(pattern.defaultMinutes) min")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundStyle(.white.opacity(0.5))
                        }
                        .padding(.top, 2)
                    }
                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityHint(LanguageManager.shared.localized("breathing.catalog.open_hint"))

            Button {
                HapticManager.medium()
                onQuickStart()
            } label: {
                Image(systemName: "play.fill")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .breathingGlassCapsule(tint: pattern.accentColor.opacity(0.45))
            .accessibilityLabel(LanguageManager.shared.localized("breathing.catalog.quick_start") + " " + pattern.localizedTitle)
        }
        .padding(14)
        .breathingGlass(cornerRadius: 24, interactive: true)
    }
}

// MARK: - Legacy image card (kept for compatibility)

struct BreathingCard: View {
    let imageName: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticManager.light()
            action()
        }) {
            ZStack(alignment: .topLeading) {
                Image(imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                LinearGradient(colors: [.black.opacity(0.62), .clear, .black.opacity(0.52)], startPoint: .top, endPoint: .bottom)
                Text(title)
                    .font(.faroSemiBold(12))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .padding(12)
            }
            .frame(maxWidth: .infinity, minHeight: 160)
            .aspectRatio(1, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

#Preview {
    BreathingListView()
}
