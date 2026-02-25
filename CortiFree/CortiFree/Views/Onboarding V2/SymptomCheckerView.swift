//
//  SymptomCheckerView.swift
//  CortiFree
//
//  Symptom checker — one symptom per row
//

import SwiftUI

private let accentPurple = Color(hex: "B794F6")

struct SymptomCheckerView: View {
    let onContinue: (Set<String>) -> Void

    @State private var selectedSymptoms: Set<String> = []
    @State private var screenViewTime: Date?

    // MARK: - Data (localized via .strings keys)

    private var categories: [SymptomCategory] {
        [
            SymptomCategory(
                title: "symptom_checker.category.mental".localized,
                symptoms: (1...6).map { i in
                    SymptomItem(
                        key: "symptom_checker.mental.\(i)".localized,
                        bold: "symptom_checker.mental.\(i).bold".localized
                    )
                }
            ),
            SymptomCategory(
                title: "symptom_checker.category.physical".localized,
                symptoms: (1...6).map { i in
                    SymptomItem(
                        key: "symptom_checker.physical.\(i)".localized,
                        bold: "symptom_checker.physical.\(i).bold".localized
                    )
                }
            ),
            SymptomCategory(
                title: "symptom_checker.category.social".localized,
                symptoms: (1...5).map { i in
                    SymptomItem(
                        key: "symptom_checker.social.\(i)".localized,
                        bold: "symptom_checker.social.\(i).bold".localized
                    )
                }
            ),
        ]
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            GalaxyBackgroundView(intensity: 1.0)
                .ignoresSafeArea()

            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 0) {

                // ── Header — left aligned, no logo ──
                VStack(alignment: .leading, spacing: 12) {
                    Text("symptom_checker.title".localized)
                        .font(.faroBold(28))
                        .foregroundColor(.white)

                    // ── Alert banner ──
                    Text("symptom_checker.alert".localized)
                        .font(.custom("Poppins-Medium", size: 13))
                        .foregroundColor(.white)
                        .lineSpacing(3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(accentPurple.opacity(0.25))
                        )

                    Text("symptom_checker.select_all".localized)
                        .font(.custom("Poppins-Regular", size: 14))
                        .foregroundColor(.white.opacity(0.45))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 64)
                .padding(.bottom, 24)

                // ── Scroll content ──
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        ForEach(categories) { category in
                            categorySection(category)
                        }

                        if !selectedSymptoms.isEmpty {
                            let countKey = selectedSymptoms.count == 1
                                ? "symptom_checker.count_singular"
                                : "symptom_checker.count_plural"
                            Text(String(format: countKey.localized, selectedSymptoms.count))
                                .font(.custom("Poppins-Medium", size: 13))
                                .foregroundColor(accentPurple)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 140)
                }

                // ── Sticky continue button ──
                VStack(spacing: 0) {
                    LinearGradient(
                        colors: [.clear, Color.black.opacity(0.85)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 28)

                    Button(action: {
                        HapticManager.medium()
                        if let startTime = screenViewTime {
                            MixpanelManager.shared.track(
                                event: "onboarding_symptom_checker_continue",
                                properties: [
                                    "time_spent": Date().timeIntervalSince(startTime),
                                    "symptoms_selected": selectedSymptoms.count,
                                    "symptoms": Array(selectedSymptoms)
                                ]
                            )
                        }
                        onContinue(selectedSymptoms)
                    }) {
                        Text("symptom_checker.cta".localized)
                            .font(.custom("Poppins-SemiBold", size: 16))
                            .foregroundColor(Color(hex: "1A1A4E"))
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 40))
                    }
                    .padding(.horizontal, 34)
                    .padding(.bottom, 50)
                    .background(Color.black.opacity(0.85))
                }
            }
        }
        .onAppear {
            screenViewTime = Date()
            MixpanelManager.shared.track(event: "onboarding_symptom_checker_viewed", properties: [:])
        }
    }

    // MARK: - Category section

    private func categorySection(_ category: SymptomCategory) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(category.title)
                .font(.faroBold(22))
                .foregroundColor(accentPurple)
                .padding(.leading, 4)

            VStack(spacing: 8) {
                ForEach(category.symptoms) { item in
                    symptomRow(item)
                }
            }
        }
    }

    // MARK: - Symptom row

    private func symptomRow(_ item: SymptomItem) -> some View {
        let isSelected = selectedSymptoms.contains(item.key)

        return Button(action: {
            HapticManager.light()
            withAnimation(.easeOut(duration: 0.15)) {
                if isSelected {
                    selectedSymptoms.remove(item.key)
                } else {
                    selectedSymptoms.insert(item.key)
                }
            }
        }) {
            HStack(spacing: 14) {
                // Toggle circle
                ZStack {
                    Circle()
                        .fill(isSelected ? accentPurple : Color.clear)
                        .frame(width: 26, height: 26)
                    Circle()
                        .stroke(isSelected ? accentPurple : Color.white.opacity(0.25), lineWidth: 1.5)
                        .frame(width: 26, height: 26)
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                    }
                }

                // Text with bold keyword
                boldText(full: item.key, bold: item.bold, isSelected: isSelected)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? accentPurple.opacity(0.18) : Color.white.opacity(0.05))
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Bold keyword helper

    private func boldText(full: String, bold: String, isSelected: Bool) -> Text {
        let baseColor: Color = isSelected ? .white : .white.opacity(0.6)

        guard let range = full.range(of: bold, options: .caseInsensitive) else {
            return Text(full)
                .font(.custom("Poppins-Regular", size: 15))
                .foregroundColor(baseColor)
        }

        let before = String(full[full.startIndex..<range.lowerBound])
        let keyword = String(full[range])
        let after = String(full[range.upperBound...])

        return Text(before)
            .font(.custom("Poppins-Regular", size: 15))
            .foregroundColor(baseColor)
        + Text(keyword)
            .font(.custom("Poppins-Bold", size: 15))
            .foregroundColor(isSelected ? .white : .white.opacity(0.85))
        + Text(after)
            .font(.custom("Poppins-Regular", size: 15))
            .foregroundColor(baseColor)
    }
}

// MARK: - Models

private struct SymptomItem: Identifiable {
    let id = UUID()
    let key: String   // full text, used as selection key
    let bold: String  // substring to make bold
}

private struct SymptomCategory: Identifiable {
    let id = UUID()
    let title: String
    let symptoms: [SymptomItem]
}

#Preview {
    SymptomCheckerView(onContinue: { _ in })
}
