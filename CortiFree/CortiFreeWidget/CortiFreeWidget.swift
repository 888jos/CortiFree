//
//  CortiFreeWidget.swift
//  CortiFreeWidget
//

import WidgetKit
import SwiftUI

// MARK: - Provider

struct CortiFreeWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> CortiFreeWidgetEntry { .placeholder }

    func getSnapshot(in context: Context, completion: @escaping (CortiFreeWidgetEntry) -> Void) {
        completion(makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CortiFreeWidgetEntry>) -> Void) {
        let entry = makeEntry()
        let midnight = Calendar.current.nextDate(
            after: Date(),
            matching: DateComponents(hour: 0, minute: 0, second: 0),
            matchingPolicy: .nextTime
        ) ?? Date().addingTimeInterval(3600)
        completion(Timeline(entries: [entry], policy: .after(midnight)))
    }

    private func makeEntry() -> CortiFreeWidgetEntry {
        #if targetEnvironment(simulator)
        return .placeholder
        #else
        let tasks = WidgetDataStore.loadTasks()
        return CortiFreeWidgetEntry(
            date: Date(),
            tasks: tasks,
            completedCount: habitCompletedCount(tasks),
            totalCount: habitTotalCount(tasks),
            programDay: WidgetDataStore.currentProgramDay()
        )
        #endif
    }

    /// Nombre d'habitudes entièrement validées (vertes) — pour l'affichage X/Y dans le header.
    /// Orange (partiel) = non compté ici.
    private func habitCompletedCount(_ tasks: [WidgetTask]) -> Int {
        var groups = [String: [WidgetTask]]()
        for task in tasks {
            let key = task.habitId ?? task.id
            groups[key, default: []].append(task)
        }
        return groups.values.filter { $0.allSatisfy { $0.completed } }.count
    }

    /// Nombre total d'habitudes du jour — les sous-tâches d'une même habitude (même habitId)
    /// comptent comme 1.
    private func habitTotalCount(_ tasks: [WidgetTask]) -> Int {
        var seen = Set<String>()
        for task in tasks {
            seen.insert(task.habitId ?? task.id)
        }
        return seen.count
    }
}

// MARK: - Widget

struct CortiFreeWidget: Widget {
    let kind: String = "CortiFreeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CortiFreeWidgetProvider()) { entry in
            CortiFreeWidgetEntryView(entry: entry)
                .widgetURL(URL(string: "cortifree://tasks"))
        }
        .configurationDisplayName(NSLocalizedString("widget.display_name", comment: ""))
        .description(NSLocalizedString("widget.description", comment: ""))
        .supportedFamilies([.systemLarge])
    }
}

// MARK: - Entry View

struct CortiFreeWidgetEntryView: View {
    let entry: CortiFreeWidgetEntry

    var body: some View {
        LargeWidget(entry: entry)
    }
}

// MARK: - Design tokens

private extension Color {
    static let galaxy1     = Color(red: 0.122, green: 0.004, blue: 0.251)
    static let galaxy2     = Color(red: 0.043, green: 0.004, blue: 0.106)
    static let galaxy3     = Color(red: 0.004, green: 0.000, blue: 0.047)
    static let cortPurple  = Color(red: 0.718, green: 0.580, blue: 0.965) // #B794F6
    static let cortPurple2 = Color(red: 0.529, green: 0.263, blue: 0.918) // #8744EB
    static let done        = Color(red: 0.35,  green: 0.82,  blue: 0.22)
    static let cancelled   = Color(red: 0.94,  green: 0.27,  blue: 0.27)
    static let partial     = Color(red: 1.00,  green: 0.60,  blue: 0.10) // orange
    static let pending     = Color.white.opacity(0.22)
}

// MARK: - Grouped task (fusionne les sous-tâches d'une même habitude)

/// Une carte widget représentant une habitude — potentiellement composée de plusieurs sous-tâches.
/// Cas principal : sleep_morning + sleep_night → une seule carte avec état composite.
private struct GroupedWidgetTask: Identifiable {
    let id: String          // habitId ou id unique
    let sfSymbol: String    // icône de la première sous-tâche
    let subtasks: [WidgetTask]

    /// État composite :
    /// - .done      : toutes les sous-tâches complétées (vert)
    /// - .partial   : au moins 1 complétée, pas toutes (orange)
    /// - .cancelled : aucune complétée, toutes annulées (rouge)
    /// - .pending   : aucune complétée, pas toutes annulées (gris)
    enum GroupStatus { case done, partial, cancelled, pending }

    var status: GroupStatus {
        let completedCount = subtasks.filter { $0.completed }.count
        let cancelledCount = subtasks.filter { $0.cancelled }.count
        if completedCount == subtasks.count { return .done }
        if completedCount > 0              { return .partial }
        if cancelledCount == subtasks.count { return .cancelled }
        return .pending
    }

    var color: Color {
        switch status {
        case .done:      return .done
        case .partial:   return .partial
        case .cancelled: return .cancelled
        case .pending:   return .pending
        }
    }
}

/// Fusionne les tâches partageant le même habitId en GroupedWidgetTask.
/// Les tâches sans habitId (ou habitId unique) génèrent un groupe à 1 élément.
private func groupedTasks(_ tasks: [WidgetTask]) -> [GroupedWidgetTask] {
    var seen = [String: Int]()  // habitId → index dans result
    var result = [GroupedWidgetTask]()

    for task in tasks {
        let key = task.habitId ?? task.id
        if let idx = seen[key] {
            // Ajouter la sous-tâche au groupe existant
            let existing = result[idx]
            result[idx] = GroupedWidgetTask(
                id: existing.id,
                sfSymbol: existing.sfSymbol,
                subtasks: existing.subtasks + [task]
            )
        } else {
            seen[key] = result.count
            result.append(GroupedWidgetTask(id: key, sfSymbol: task.sfSymbol, subtasks: [task]))
        }
    }
    return result
}

/// Score de progression [0.0–1.0] incluant le prorata orange.
/// Groupe sleep à 1/2 = +0.5 → 50% pour la barre et le footer.
private func habitProgressScore(_ tasks: [WidgetTask]) -> Double {
    var groups = [String: [WidgetTask]]()
    for task in tasks {
        let key = task.habitId ?? task.id
        groups[key, default: []].append(task)
    }
    guard !groups.isEmpty else { return 0 }
    let score = groups.values.reduce(0.0) { sum, subtasks in
        let completed = Double(subtasks.filter { $0.completed }.count)
        return sum + completed / Double(subtasks.count)
    }
    return score / Double(groups.count)
}

/// Score absolu (pas normalisé) pour l'affichage "X,5 / N" dans le header.
private func habitCompletedScore(_ tasks: [WidgetTask]) -> Double {
    var groups = [String: [WidgetTask]]()
    for task in tasks {
        let key = task.habitId ?? task.id
        groups[key, default: []].append(task)
    }
    return groups.values.reduce(0.0) { sum, subtasks in
        let completed = Double(subtasks.filter { $0.completed }.count)
        return sum + completed / Double(subtasks.count)
    }
}

private extension Font {
    static func fB(_ size: CGFloat)  -> Font { .custom("Faro-BoldLucky",     size: size) }
    static func fSB(_ size: CGFloat) -> Font { .custom("Faro-SemiBoldLucky", size: size) }
    static func fR(_ size: CGFloat)  -> Font { .custom("Faro-RegularLucky",  size: size) }
}

// MARK: - Galaxy Background

private struct GalaxyBG: View {
    private static let stars: [(x: Double, y: Double, r: Double, a: Double)] = {
        var res: [(Double, Double, Double, Double)] = []
        var rng: UInt64 = 0xCAFEBABE
        func nx() -> Double {
            rng = rng &* 6364136223846793005 &+ 1442695040888963407
            return Double(rng >> 33) / Double(UInt32.max)
        }
        for _ in 0..<55 { res.append((nx(), nx(), nx() * 1.6 + 0.4, nx() * 0.55 + 0.25)) }
        return res
    }()

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            ZStack {
                LinearGradient(colors: [.galaxy1, .galaxy2, .galaxy3],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                RadialGradient(
                    colors: [Color(red: 0.45, green: 0.15, blue: 0.85).opacity(0.35), .clear],
                    center: UnitPoint(x: 0.78, y: 0.18),
                    startRadius: 0, endRadius: max(w, h) * 0.55)
                RadialGradient(
                    colors: [Color(red: 0.10, green: 0.05, blue: 0.55).opacity(0.25), .clear],
                    center: UnitPoint(x: 0.18, y: 0.82),
                    startRadius: 0, endRadius: max(w, h) * 0.5)
                Canvas { ctx, size in
                    for s in Self.stars {
                        let rect = CGRect(x: s.x * size.width - s.r / 2,
                                         y: s.y * size.height - s.r / 2,
                                         width: s.r, height: s.r)
                        ctx.fill(Path(ellipseIn: rect), with: .color(.white.opacity(s.a)))
                    }
                }
            }
        }
    }
}

// MARK: - Ring Progress

private struct RingProgress: View {
    let completed: Int
    let total: Int
    let ringSize: CGFloat
    let lineWidth: CGFloat

    private var ratio: Double { total > 0 ? Double(completed) / Double(total) : 0 }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.08), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: ratio)
                .stroke(Color.cortPurple.opacity(0.22),
                        style: StrokeStyle(lineWidth: lineWidth + 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Circle()
                .trim(from: 0, to: ratio)
                .stroke(
                    LinearGradient(colors: [.cortPurple, .cortPurple2],
                                   startPoint: .topLeading, endPoint: .bottomTrailing),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: -2) {
                Text("\(completed)")
                    .font(.fB(ringSize * 0.30))
                    .foregroundColor(.white)
                Text("/ \(total)")
                    .font(.fR(ringSize * 0.14))
                    .foregroundColor(.white.opacity(0.45))
            }
        }
        .frame(width: ringSize, height: ringSize)
    }
}

// MARK: - Task Card

private struct TaskCard: View {
    let group: GroupedWidgetTask
    let size: CGFloat
    var isTinted: Bool = false

    private var cardColor: Color { isTinted ? .primary : group.color }

    // Icône principale du statut (mode tinted)
    private var statusIcon: String {
        switch group.status {
        case .done:      return "checkmark.circle.fill"
        case .partial:   return "circle.lefthalf.filled"
        case .cancelled: return "xmark.circle.fill"
        case .pending:   return "circle.dotted"      // cercle en pointillés = "pas encore"
        }
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Image(systemName: group.sfSymbol)
                .font(.system(size: size * 0.62, weight: .semibold))
                .foregroundColor(cardColor)
                .widgetAccentable()
                .frame(width: size, height: size)

            // Petit badge statut en bas à droite
            Image(systemName: statusIcon)
                .font(.system(size: size * 0.24, weight: .bold))
                .foregroundColor(cardColor)
                .padding(2)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - "Jour X" header unifié

private struct DayLabel: View {
    let day: Int
    let size: CGFloat
    var isTinted: Bool = false

    var body: some View {
        HStack(alignment: .lastTextBaseline, spacing: 3) {
            Text(NSLocalizedString("widget.day", comment: ""))
                .font(.fSB(size))
                .foregroundColor(.primary.opacity(0.55))
            if day <= 66 {
                HStack(alignment: .lastTextBaseline, spacing: 1) {
                    Text("\(day)")
                        .font(.fB(size))
                        .foregroundColor(.primary)
                        .widgetAccentable()
                    Text(NSLocalizedString("widget.day_of", comment: ""))
                        .font(.fR(size * 0.55))
                        .foregroundColor(.primary.opacity(0.35))
                }
            } else {
                Text("\(day)")
                    .font(.fB(size))
                    .foregroundColor(.primary)
                    .widgetAccentable()
            }
        }
    }
}

// MARK: - LARGE

struct LargeWidget: View {
    let entry: CortiFreeWidgetEntry
    @Environment(\.widgetRenderingMode) private var renderingMode
    private var groups: [GroupedWidgetTask] { Array(groupedTasks(entry.tasks).prefix(8)) }

    /// En mode tinted (iOS 18 icon tint), iOS impose sa propre couleur sur tout.
    /// On utilise `.widgetAccentable()` sur les éléments clés et on laisse iOS gérer.
    private var isTinted: Bool { renderingMode == .accented }

    // Score réel incluant le prorata orange (1/2 = 50%)
    // On utilise entry.totalCount (source unique de vérité) comme dénominateur
    private var progress: Double {
        guard entry.totalCount > 0 else { return 0 }
        return habitCompletedScore(entry.tasks) / Double(entry.totalCount)
    }

    // Score absolu pour le header : "2,5 / 7" si sleep partiel
    private var completedScore: Double { habitCompletedScore(entry.tasks) }

    private var completedScoreText: String {
        completedScore.truncatingRemainder(dividingBy: 1) == 0
            ? "\(Int(completedScore))"
            : String(format: "%.1f", completedScore).replacingOccurrences(of: ".", with: ",")
    }

    private var footerMessage: String {
        let pct = Int(progress * 100)
        switch pct {
        case 0:
            return NSLocalizedString("widget.footer.zero", comment: "")
        case ..<25:
            return String(format: NSLocalizedString("widget.footer.low", comment: ""), pct)
        case ..<50:
            return String(format: NSLocalizedString("widget.footer.mid", comment: ""), pct)
        case ..<75:
            return String(format: NSLocalizedString("widget.footer.high", comment: ""), pct)
        case ..<100:
            return String(format: NSLocalizedString("widget.footer.almost", comment: ""), pct)
        default:
            return NSLocalizedString("widget.footer.perfect", comment: "")
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

                // ── Header ──
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(NSLocalizedString("widget.program", comment: ""))
                            .font(.fR(8))
                            .foregroundColor(isTinted ? .primary.opacity(0.55) : .cortPurple.opacity(0.65))
                            .kerning(1.4)
                        DayLabel(day: entry.programDay, size: 28, isTinted: isTinted)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 1) {
                        HStack(alignment: .lastTextBaseline, spacing: 3) {
                            Text(completedScoreText)
                                .font(.fB(26))
                                .foregroundColor(isTinted ? .primary : .cortPurple)
                                .widgetAccentable()
                            Text("/ \(entry.totalCount)")
                                .font(.fR(14))
                                .foregroundColor(.primary.opacity(0.40))
                        }
                        Text(NSLocalizedString("widget.tasks", comment: ""))
                            .font(.fR(9))
                            .foregroundColor(.primary.opacity(0.30))
                    }
                }
                .padding(.bottom, 12)

                // Divider
                Rectangle()
                    .fill(Color.primary.opacity(0.07))
                    .frame(height: 1)
                    .padding(.bottom, 14)

                // Grid 4 colonnes — flexible pour occuper l'espace
                if groups.isEmpty {
                    Text(NSLocalizedString("widget.empty", comment: ""))
                        .font(.fR(13))
                        .foregroundColor(.primary.opacity(0.35))
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                } else {
                    let cols = Array(repeating: GridItem(.flexible(), spacing: 10), count: 4)
                    LazyVGrid(columns: cols, spacing: 12) {
                        ForEach(groups) { group in
                            TaskCard(group: group, size: 58, isTinted: isTinted)
                        }
                    }
                }

                Spacer(minLength: 12)

                // ── Footer ──
                VStack(spacing: 8) {
                    // Barre de progression
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.primary.opacity(0.08))
                                .frame(height: 3)
                            Capsule()
                                .fill(isTinted
                                      ? AnyShapeStyle(Color.primary)
                                      : AnyShapeStyle(LinearGradient(
                                            colors: [.cortPurple, .cortPurple2],
                                            startPoint: .leading, endPoint: .trailing)))
                                .frame(width: geo.size.width * progress, height: 3)
                                .widgetAccentable()
                        }
                    }
                    .frame(height: 3)

                    HStack {
                        Text(footerMessage)
                            .font(.fR(11))
                            .foregroundColor(.primary.opacity(0.38))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        Spacer()
                        Text("CortiFree")
                            .font(.fSB(11))
                            .foregroundColor(isTinted ? .primary.opacity(0.50) : .cortPurple.opacity(0.50))
                    }
                }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .containerBackground(for: .widget) {
            if isTinted {
                Color.clear
            } else {
                GalaxyBG()
            }
        }
    }
}

// MARK: - Previews

#Preview(as: .systemLarge) { CortiFreeWidget() } timeline: { CortiFreeWidgetEntry.placeholder }
