//
//  CortiFreeViralWidgets.swift
//  CortiFreeWidget
//
//  Les 6 widgets « écran d'accueil » : Milo, Respire, Cortisol, Humeur,
//  Message de Milo, Streak. Les vues vivent dans CortiFree/Views/Widgets (partagées
//  avec la galerie des Réglages).
//

import SwiftUI
import WidgetKit

// MARK: - Entry & Provider

struct InsightsEntry: TimelineEntry {
    let date: Date
    let insights: WidgetInsights
    let breathStart: Date?
}

struct InsightsProvider: TimelineProvider {
    let kind: CortiFreeWidgetKind

    func placeholder(in context: Context) -> InsightsEntry {
        InsightsEntry(date: Date(), insights: .sample, breathStart: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (InsightsEntry) -> Void) {
        completion(context.isPreview ? placeholder(in: context) : entry(at: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<InsightsEntry>) -> Void) {
        let now = Date()

        // Session « Respire » en cours : une entrée par seconde jusqu'à la fin, pour que
        // la piste des montagnes russes défile (WidgetKit anime d'une entrée à l'autre).
        if kind == .breathe, let start = WidgetInsightsStore.breathStart,
           now.timeIntervalSince(start) < WidgetInsightsStore.breathSessionSeconds {
            let tick: TimeInterval = 1
            let end = start.addingTimeInterval(WidgetInsightsStore.breathSessionSeconds)
            var dates: [Date] = [now]
            var next = start.addingTimeInterval((floor(now.timeIntervalSince(start) / tick) + 1) * tick)
            while next < end {
                dates.append(next)
                next = next.addingTimeInterval(tick)
            }
            dates.append(end)
            completion(Timeline(entries: dates.map { entry(at: $0) }, policy: .atEnd))
            return
        }

        // Sinon : rafraîchit à chaque heure pile (Milo, cortisol et phrases changent avec l'heure).
        let nextHour = Calendar.current.nextDate(after: now, matching: DateComponents(minute: 0),
                                                 matchingPolicy: .nextTime) ?? now.addingTimeInterval(3600)
        completion(Timeline(entries: [entry(at: now)], policy: .after(nextHour)))
    }

    private func entry(at date: Date) -> InsightsEntry {
        #if targetEnvironment(simulator)
        let stored = WidgetInsightsStore.load(at: date)
        // Sur simulateur sans données, on montre la démo — mais on garde humeurs / respirations
        // enregistrées depuis le widget pour pouvoir tester l'interactivité.
        let sample = WidgetInsights.sample
        let insights = WidgetInsights(
            date: date, streak: sample.streak, bestStreak: sample.bestStreak, programDay: sample.programDay,
            todayProgress: sample.todayProgress, breathsToday: stored.breathsToday,
            moods: sample.moods.merging(stored.moods) { $1 }, lastStress: sample.lastStress,
            dayProgress: sample.dayProgress)
        #else
        let insights = WidgetInsightsStore.load(at: date)
        #endif
        return InsightsEntry(date: date, insights: insights, breathStart: WidgetInsightsStore.breathStart)
    }
}

// MARK: - Vue d'entrée commune

private struct InsightsEntryView: View {
    let kind: CortiFreeWidgetKind
    let entry: InsightsEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        CortiFreeKindView(kind: kind, insights: entry.insights, family: family, breathStart: entry.breathStart)
            .widgetURL(kind.deepLink)
            .containerBackground(for: .widget) {
                if family.isAccessory {
                    if family == .accessoryRectangular { AccessoryWidgetBackground() } else { Color.clear }
                } else {
                    CFWidgetBackground()
                }
            }
    }
}

private func insightsConfiguration(_ kind: CortiFreeWidgetKind) -> some WidgetConfiguration {
    StaticConfiguration(kind: kind.kind, provider: InsightsProvider(kind: kind)) { entry in
        InsightsEntryView(kind: kind, entry: entry)
    }
    .configurationDisplayName(kind.displayName)
    .description(kind.summary)
    .supportedFamilies(kind.families)
}

// MARK: - Widgets

struct MiloCompanionWidget: Widget {
    var body: some WidgetConfiguration { insightsConfiguration(.milo) }
}

struct BreatheWidget: Widget {
    var body: some WidgetConfiguration { insightsConfiguration(.breathe) }
}

struct CortisolWidget: Widget {
    var body: some WidgetConfiguration { insightsConfiguration(.cortisol) }
}

struct MoodWidget: Widget {
    var body: some WidgetConfiguration { insightsConfiguration(.mood) }
}

struct MiloMessageWidget: Widget {
    var body: some WidgetConfiguration { insightsConfiguration(.message) }
}

struct StreakWidget: Widget {
    var body: some WidgetConfiguration { insightsConfiguration(.streak) }
}

/// Regroupés dans un bundle à part : un WidgetBundle accepte au plus 10 widgets.
struct CortiFreeInsightsWidgets: WidgetBundle {
    var body: some Widget {
        MiloCompanionWidget()
        BreatheWidget()
        CortisolWidget()
        MoodWidget()
        MiloMessageWidget()
        StreakWidget()
    }
}

// MARK: - Previews

#Preview("Milo", as: .systemMedium) { MiloCompanionWidget() } timeline: {
    InsightsEntry(date: .now, insights: .sample, breathStart: nil)
}

#Preview("Respire", as: .systemSmall) { BreatheWidget() } timeline: {
    InsightsEntry(date: .now, insights: .sample, breathStart: nil)
    InsightsEntry(date: .now, insights: .sample, breathStart: .now)
}

#Preview("Cortisol", as: .systemMedium) { CortisolWidget() } timeline: {
    InsightsEntry(date: .now, insights: .sample, breathStart: nil)
}

#Preview("Humeur", as: .systemLarge) { MoodWidget() } timeline: {
    InsightsEntry(date: .now, insights: .sample, breathStart: nil)
}
