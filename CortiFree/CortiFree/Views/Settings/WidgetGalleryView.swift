//
//  WidgetGalleryView.swift
//  CortiFree
//
//  Réglages → Widgets : aperçu de chaque widget (avec les vraies données de l'utilisateur).
//  Toucher un aperçu ouvre la marche à suivre pour ce widget et cette taille précis :
//  iOS ne permet pas d'ajouter un widget depuis l'app.
//

import SwiftUI
import WidgetKit

struct WidgetGalleryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var insights = WidgetGalleryView.currentInsights()
    @State private var refreshed = false
    @State private var guide: WidgetAddGuide?

    private func t(_ key: String) -> String { LanguageManager.shared.localizedString(for: key) }

    /// Les vraies données si l'utilisateur en a, sinon la démo (nouveau compte).
    private static func currentInsights() -> WidgetInsights {
        let stored = WidgetInsightsStore.load()
        return stored.moods.isEmpty && stored.streak == 0 && stored.dayProgress.isEmpty ? .sample : stored
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: "1F0140"), Color(hex: "01000C")], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 28) {
                        howToCard
                        ForEach(CortiFreeWidgetKind.allCases) { kind in
                            widgetCard(kind)
                        }
                        refreshButton
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .onAppear { WidgetInsightsStore.mirrorLanguage(LanguageManager.shared.currentLanguage.rawValue) }
        .sheet(item: $guide) { guide in
            WidgetAddGuideSheet(guide: guide, insights: insights)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Color.clear.frame(width: 44, height: 44)
            Spacer()
            Text(t("widgets.gallery.title"))
                .font(.faroBold(22))
                .foregroundColor(.white)
            Spacer()
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .glassCircle(interactive: true)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 12)
    }

    // MARK: - Astuce

    private var howToCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "hand.tap.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(CFW.purple)
                .frame(width: 28, height: 28)
            Text(t("widgets.gallery.tap_hint"))
                .font(.custom("Poppins-Regular", size: 14))
                .foregroundColor(.white.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(cornerRadius: 22)
    }

    // MARK: - Carte d'un widget

    private func widgetCard(_ kind: CortiFreeWidgetKind) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(kind.displayName)
                    .font(.faroSemiBold(17))
                    .foregroundColor(.white)
                Text(kind.summary)
                    .font(.custom("Poppins-Regular", size: 13))
                    .foregroundColor(.white.opacity(0.6))
                    .fixedSize(horizontal: false, vertical: true)
            }
            WidgetFlowLayout(spacing: 14) {
                ForEach(kind.families, id: \.self) { family in
                    Button {
                        HapticManager.light()
                        guide = WidgetAddGuide(kind: kind, family: family)
                    } label: {
                        VStack(spacing: 6) {
                            WidgetPreviewTile(kind: kind, family: family, insights: insights)
                                .overlay(alignment: .topTrailing) { addBadge(family) }
                            Text(t("widgets.gallery.size.\(family.sizeKey)"))
                                .font(.custom("Poppins-Regular", size: 11))
                                .foregroundColor(.white.opacity(0.45))
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func addBadge(_ family: WidgetFamily) -> some View {
        Image(systemName: "plus")
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(Color(hex: "1F0140"))
            .frame(width: 24, height: 24)
            .background(Circle().fill(CFW.purple))
            .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
            .offset(x: family.isAccessory ? 4 : 6, y: family.isAccessory ? -4 : -6)
    }

    // MARK: - Actualiser

    private var refreshButton: some View {
        Button {
            HapticManager.light()
            WidgetInsightsStore.mirrorLanguage(LanguageManager.shared.currentLanguage.rawValue)
            WidgetCenter.shared.reloadAllTimelines()
            insights = Self.currentInsights()
            refreshed = true
        } label: {
            Label(t(refreshed ? "widgets.gallery.refreshed" : "widgets.gallery.refresh"),
                  systemImage: refreshed ? "checkmark" : "arrow.clockwise")
                .font(.custom("Poppins-SemiBold", size: 15))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .glassCard(cornerRadius: 18, interactive: true)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Aperçu d'un widget

private struct WidgetPreviewTile: View {
    let kind: CortiFreeWidgetKind
    let family: WidgetFamily
    let insights: WidgetInsights

    var body: some View {
        let size = family.previewSize
        let content = CortiFreeKindView(kind: kind, insights: insights, family: family,
                                        breathStart: nil, interactive: false)
        if family.isAccessory {
            content
                .foregroundStyle(.white)
                .padding(family == .accessoryRectangular ? 8 : 4)
                .frame(width: size.width, height: size.height)
                .background(
                    Group {
                        if family == .accessoryCircular {
                            Circle().fill(.white.opacity(0.14))
                        } else if family == .accessoryRectangular {
                            RoundedRectangle(cornerRadius: 14).fill(.white.opacity(0.14))
                        }
                    }
                )
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 22)
                        .fill(LinearGradient(colors: [Color(hex: "2B2F5C"), Color(hex: "0E0F24")],
                                             startPoint: .top, endPoint: .bottom))
                )
        } else {
            content
                .padding(16)
                .frame(width: size.width, height: size.height)
                .background(CFWidgetBackground())
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(.white.opacity(0.08)))
        }
    }
}

// MARK: - Marche à suivre pour un widget

struct WidgetAddGuide: Identifiable {
    let kind: CortiFreeWidgetKind
    let family: WidgetFamily
    var id: String { "\(kind.rawValue).\(String(describing: family))" }
}

private struct WidgetAddGuideSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var family: WidgetFamily
    let kind: CortiFreeWidgetKind
    let insights: WidgetInsights

    init(guide: WidgetAddGuide, insights: WidgetInsights) {
        kind = guide.kind
        _family = State(initialValue: guide.family)
        self.insights = insights
    }

    private func t(_ key: String) -> String { LanguageManager.shared.localizedString(for: key) }

    private var sizeName: String { t("widgets.gallery.size.\(family.sizeKey)") }

    private var steps: [String] {
        if family.isAccessory {
            return [
                t("widgets.add.lock.step1"),
                t("widgets.add.lock.step2"),
                t(family == .accessoryInline ? "widgets.add.lock.step3_inline" : "widgets.add.lock.step3"),
                String(format: t("widgets.add.lock.step4"), kind.displayName),
            ]
        }
        return [
            t("widgets.gallery.howto.step1"),
            t("widgets.gallery.howto.step2"),
            t("widgets.add.home.step3"),
            String(format: t("widgets.add.home.step4"), kind.displayName, sizeName),
        ]
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: "1F0140"), Color(hex: "01000C")], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    Capsule()
                        .fill(.white.opacity(0.25))
                        .frame(width: 40, height: 5)
                        .padding(.top, 10)

                    Text(String(format: t("widgets.add.title"), kind.displayName))
                        .font(.faroBold(24))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    WidgetPreviewTile(kind: kind, family: family, insights: insights)
                        .scaleEffect(family.isAccessory ? 1.3 : 1)
                        .padding(.vertical, family.isAccessory ? 12 : 0)
                        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: family)

                    if kind.families.count > 1 {
                        sizePicker
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                            HStack(alignment: .top, spacing: 12) {
                                Text("\(index + 1)")
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundColor(Color(hex: "1F0140"))
                                    .frame(width: 24, height: 24)
                                    .background(Circle().fill(CFW.purple))
                                Text(step)
                                    .font(.custom("Poppins-Regular", size: 15))
                                    .foregroundColor(.white.opacity(index == steps.count - 1 ? 1 : 0.85))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .glassCard(cornerRadius: 22)

                    Button {
                        HapticManager.light()
                        dismiss()
                    } label: {
                        Text(t("widgets.add.done"))
                            .font(.custom("Poppins-SemiBold", size: 16))
                            .foregroundColor(Color(hex: "1F0140"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Capsule().fill(CFW.purple))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
    }

    private var sizePicker: some View {
        HStack(spacing: 8) {
            ForEach(kind.families, id: \.self) { option in
                Button {
                    HapticManager.light()
                    family = option
                } label: {
                    Text(t("widgets.gallery.size.\(option.sizeKey)"))
                        .font(.custom(family == option ? "Poppins-SemiBold" : "Poppins-Regular", size: 13))
                        .foregroundColor(family == option ? Color(hex: "1F0140") : .white.opacity(0.8))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(family == option ? CFW.purple : Color.white.opacity(0.1)))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private extension WidgetFamily {
    var sizeKey: String {
        switch self {
        case .systemSmall: return "small"
        case .systemMedium: return "medium"
        case .systemLarge: return "large"
        default: return "lock"
        }
    }
}

/// Place les aperçus côte à côte et passe à la ligne quand la largeur manque.
private struct WidgetFlowLayout: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = arrange(width: proposal.width ?? .infinity, subviews: subviews)
        let height = rows.map(\.height).reduce(0, +) + spacing * CGFloat(max(0, rows.count - 1))
        let width = rows.map(\.width).max() ?? 0
        return CGSize(width: proposal.width ?? width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for row in arrange(width: bounds.width, subviews: subviews) {
            var x = bounds.minX
            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(at: CGPoint(x: x, y: y + (row.height - size.height) / 2),
                                      proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += row.height + spacing
        }
    }

    private struct Row { var indices: [Int] = []; var width: CGFloat = 0; var height: CGFloat = 0 }

    private func arrange(width: CGFloat, subviews: Subviews) -> [Row] {
        var rows: [Row] = []
        var current = Row()
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let needed = current.indices.isEmpty ? size.width : current.width + spacing + size.width
            if needed > width, !current.indices.isEmpty {
                rows.append(current)
                current = Row()
            }
            current.width = current.indices.isEmpty ? size.width : current.width + spacing + size.width
            current.height = max(current.height, size.height)
            current.indices.append(index)
        }
        if !current.indices.isEmpty { rows.append(current) }
        return rows
    }
}

#Preview {
    WidgetGalleryView()
}
