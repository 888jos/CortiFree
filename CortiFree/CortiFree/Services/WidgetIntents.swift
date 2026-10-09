//
//  WidgetIntents.swift
//  CortiFree
//
//  Actions des widgets interactifs (humeur en 1 tap, Respire).
//  Fichier membre des deux targets : CortiFree + CortiFreeWidgetExtension.
//

import AppIntents
import WidgetKit

struct LogMoodIntent: AppIntent {
    static let title: LocalizedStringResource = "Log my mood"
    static let isDiscoverable = false

    @Parameter(title: "Mood")
    var mood: String

    init() {}

    init(mood: WidgetMood) {
        self.mood = mood.rawValue
    }

    func perform() async throws -> some IntentResult {
        WidgetInsightsStore.recordMood(mood)
        return .result()
    }
}

struct StartBreathingIntent: AppIntent {
    static let title: LocalizedStringResource = "Start a 1-minute breathing"
    static let isDiscoverable = false

    func perform() async throws -> some IntentResult {
        WidgetInsightsStore.startBreathing()
        return .result()
    }
}

struct StopBreathingIntent: AppIntent {
    static let title: LocalizedStringResource = "Stop breathing"
    static let isDiscoverable = false

    func perform() async throws -> some IntentResult {
        WidgetInsightsStore.stopBreathing()
        return .result()
    }
}
