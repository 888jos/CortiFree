//
//  GuidedSessionCatalog.swift
//  CortiFree
//
//  Catalogue of guided audio sessions focused on stress & cortisol.
//  Narration scripts live in Resources/Narration/narration_<lang>.json (fr, en).
//

import SwiftUI

enum GuidedSessionCatalog {

    // MARK: - Lookup

    static func session(id: String) -> GuidedSession? {
        all.first { $0.id == id }
    }

    static func sessions(in category: AudioSessionCategory) -> [GuidedSession] {
        all.filter { $0.category == category }
    }

    /// Hand-picked sessions for the Library "Quick start" carousel.
    static var featured: [GuidedSession] {
        ["sos-reset-3", "sos-cortisol-drop-5", "sleep-wind-down-10", "work-desk-reset-3", "anxiety-grounding-54321-6", "morning-intention-7"]
            .compactMap(session(id:))
    }

    /// Maps the legacy meditation ids (Exercise.meditations / MeditationSupport / routines /
    /// anti-stress flow) to audio sessions, so nothing points to missing mp3 files anymore.
    static func sessionID(forLegacyID legacyID: String) -> String? {
        switch legacyID {
        case "conscious-breathing": return "focus-single-point-6"
        case "body-scan": return "body-scan-10"
        case "mindfulness": return "anxiety-leaves-stream-8"
        case "grounding": return "anxiety-grounding-54321-6"
        case "visualization": return "sos-safe-place-7"
        case "compassion": return "compassion-loving-kindness-10"
        case "focus-clarity": return "focus-mindful-breath-12"
        case "yoga-nidra": return "body-yoga-nidra-15"
        case "meditation-2-min": return "sos-reset-3"
        default: return session(id: legacyID)?.id
        }
    }

    static func session(forLegacyID legacyID: String) -> GuidedSession? {
        sessionID(forLegacyID: legacyID).flatMap(session(id:))
    }

    // MARK: - Builder

    static func make(
        _ id: String,
        _ category: AudioSessionCategory,
        _ minutes: Int,
        title: LocalizedText,
        subtitle: LocalizedText,
        symbol: String,
        image: String? = nil,
        colors: [Color]? = nil,
        ambience: AudioAmbience?
    ) -> GuidedSession {
        GuidedSession(
            id: id,
            title: title,
            subtitle: subtitle,
            category: category,
            durationMinutes: minutes,
            isPremium: false, // App is behind a hard paywall: everything unlocked once subscribed.
            artwork: SessionArtwork(symbol: symbol, colors: colors ?? category.colors, imageName: image),
            defaultAmbience: ambience,
            remoteAudioURL: nil
        )
    }


    // MARK: - Catalogue

    /// Generated from scripts/narration/catalog_plan.json (see GuidedSessionCatalogData.swift).
    static let all: [GuidedSession] = generatedSessions
}
