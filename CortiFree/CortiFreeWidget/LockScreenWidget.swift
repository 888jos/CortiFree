//
//  LockScreenWidget.swift
//  CortiFreeWidget
//
//  Widget lock screen : logo de l'app, ouvre l'app au tap.
//  Famille : accessoryCircular (carré arrondi sur le lock screen)
//

import WidgetKit
import SwiftUI

// MARK: - Provider (timeline minimal, pas de données nécessaires)

struct LockScreenProvider: TimelineProvider {
    func placeholder(in context: Context) -> LockScreenEntry {
        LockScreenEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (LockScreenEntry) -> Void) {
        completion(LockScreenEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LockScreenEntry>) -> Void) {
        // Pas de refresh nécessaire — le logo ne change jamais
        completion(Timeline(entries: [LockScreenEntry(date: Date())], policy: .never))
    }
}

struct LockScreenEntry: TimelineEntry {
    let date: Date
}

// MARK: - Widget

struct LockScreenWidget: Widget {
    let kind: String = "CortiFreeLockScreenWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LockScreenProvider()) { _ in
            LockScreenWidgetView()
                .widgetURL(URL(string: "cortifree://home"))
        }
        .configurationDisplayName(NSLocalizedString("widget.lockscreen.display_name", comment: ""))
        .description(NSLocalizedString("widget.lockscreen.description", comment: ""))
        .supportedFamilies([.accessoryCircular])
    }
}

// MARK: - View

struct LockScreenWidgetView: View {
    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            Image("AppLogo")
                .resizable()
                .scaledToFit()
                .padding(6)
        }
    }
}

// MARK: - Preview

#Preview(as: .accessoryCircular) { LockScreenWidget() } timeline: { LockScreenEntry(date: Date()) }
