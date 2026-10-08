//
//  Exercise.swift
//  CortiFree
//
//  Created by Claude on 22/10/2025.
//

import Foundation

enum ExerciseType: String, CaseIterable {
    case breathing = "respiration"
    case meditation = "meditation"
    case sound = "sound"

    var displayName: String {
        switch self {
        case .breathing: return LanguageManager.shared.localizedString(for: "exercise_type.breathing")
        case .meditation: return LanguageManager.shared.localizedString(for: "exercise_type.meditation")
        case .sound: return LanguageManager.shared.localizedString(for: "exercise_type.sound")
        }
    }
}

struct Exercise: Identifiable {
    let id: String
    let title: String
    let type: ExerciseType
    let duration: Int // in seconds
    let description: String
    let audioFileName: String?
    let icon: String

    // Computed collections are intentional: titles and descriptions must be
    // rebuilt after the user changes the app language.
    static var breathingExercises: [Exercise] {
        [
        Exercise(id: "deep-abdominal",
                title: LanguageManager.shared.localizedString(for: "breathing.deep_abdominal.title"),
                type: .breathing, duration: 180,
                description: LanguageManager.shared.localizedString(for: "breathing.deep_abdominal.description"),
                audioFileName: nil, icon: "wind"),
        Exercise(id: "478",
                title: LanguageManager.shared.localizedString(for: "breathing.478.title"),
                type: .breathing, duration: 300,
                description: LanguageManager.shared.localizedString(for: "breathing.478.description"),
                audioFileName: nil, icon: "moon.stars.fill"),
        Exercise(id: "coherence",
                title: LanguageManager.shared.localizedString(for: "breathing.coherence.title"),
                type: .breathing, duration: 420,
                description: LanguageManager.shared.localizedString(for: "breathing.coherence.description"),
                audioFileName: nil, icon: "heart.fill"),
        Exercise(id: "slow-66",
                title: LanguageManager.shared.localizedString(for: "breathing.slow.title"),
                type: .breathing, duration: 420,
                description: LanguageManager.shared.localizedString(for: "breathing.slow.description"),
                audioFileName: nil, icon: "bed.double.fill"),
        Exercise(id: "triangle",
                title: LanguageManager.shared.localizedString(for: "breathing.triangle.title"),
                type: .breathing, duration: 300,
                description: LanguageManager.shared.localizedString(for: "breathing.triangle.description"),
                audioFileName: nil, icon: "triangle"),
        Exercise(id: "box",
                title: LanguageManager.shared.localizedString(for: "breathing.box.title"),
                type: .breathing, duration: 420,
                description: LanguageManager.shared.localizedString(for: "breathing.box.description"),
                audioFileName: nil, icon: "square"),
        Exercise(id: "kapalabhati",
                title: LanguageManager.shared.localizedString(for: "breathing.kapalabhati.title"),
                type: .breathing, duration: 300,
                description: LanguageManager.shared.localizedString(for: "breathing.kapalabhati.description"),
                audioFileName: nil, icon: "bolt.fill"),
        Exercise(id: "bhastrika",
                title: LanguageManager.shared.localizedString(for: "breathing.bhastrika.title"),
                type: .breathing, duration: 300,
                description: LanguageManager.shared.localizedString(for: "breathing.bhastrika.description"),
                audioFileName: nil, icon: "flame.fill")
        ]
    }

    static var sounds: [Exercise] {
        [
        Exercise(id: "rain",
                title: LanguageManager.shared.localizedString(for: "sounds.rain"),
                type: .sound, duration: 0,
                description: LanguageManager.shared.localizedString(for: "sounds.rain.description"),
                audioFileName: "rain.m4a", icon: "cloud.rain.fill"),
        Exercise(id: "ocean",
                title: LanguageManager.shared.localizedString(for: "sounds.ocean"),
                type: .sound, duration: 0,
                description: LanguageManager.shared.localizedString(for: "sounds.ocean.description"),
                audioFileName: "ocean.m4a", icon: "water.waves"),
        Exercise(id: "fire",
                title: LanguageManager.shared.localizedString(for: "sounds.fire"),
                type: .sound, duration: 0,
                description: LanguageManager.shared.localizedString(for: "sounds.fire.description"),
                audioFileName: "fire.m4a", icon: "flame.fill"),
        Exercise(id: "whitenoise",
                title: LanguageManager.shared.localizedString(for: "sounds.whitenoise"),
                type: .sound, duration: 0,
                description: LanguageManager.shared.localizedString(for: "sounds.whitenoise.description"),
                audioFileName: "whitenoise.m4a", icon: "waveform"),
        Exercise(id: "wind",
                title: LanguageManager.shared.localizedString(for: "sounds.morning"),
                type: .sound, duration: 0,
                description: LanguageManager.shared.localizedString(for: "sounds.morning.description"),
                audioFileName: "morning.m4a", icon: "sunrise.fill"),
        Exercise(id: "forest",
                title: LanguageManager.shared.localizedString(for: "sounds.forest"),
                type: .sound, duration: 0,
                description: LanguageManager.shared.localizedString(for: "sounds.forest.description"),
                audioFileName: "forest.m4a", icon: "leaf.fill"),
        Exercise(id: "stream",
                title: LanguageManager.shared.localizedString(for: "sounds.stream"),
                type: .sound, duration: 0,
                description: LanguageManager.shared.localizedString(for: "sounds.stream.description"),
                audioFileName: "stream.m4a", icon: "drop.fill"),
        Exercise(id: "night",
                title: LanguageManager.shared.localizedString(for: "sounds.night"),
                type: .sound, duration: 0,
                description: LanguageManager.shared.localizedString(for: "sounds.night.description"),
                audioFileName: "summer-night.m4a", icon: "moon.stars.fill")
        ]
    }

    // Meditations are guided audio sessions (GuidedSessionPlayer): no bundled mp3.
    // `guidedSession` maps each legacy id to its audio session.
    static var meditations: [Exercise] {
        [
        Exercise(id: "conscious-breathing",
                title: LanguageManager.shared.localizedString(for: "meditation.conscious_breathing.title"),
                type: .meditation, duration: 180,
                description: LanguageManager.shared.localizedString(for: "meditation.conscious_breathing.short_description"),
                audioFileName: nil, icon: "wind"),
        Exercise(id: "body-scan",
                title: LanguageManager.shared.localizedString(for: "meditation.body_scan.title"),
                type: .meditation, duration: 300,
                description: LanguageManager.shared.localizedString(for: "meditation.body_scan.short_description"),
                audioFileName: nil, icon: "figure.stand"),
        Exercise(id: "mindfulness",
                title: LanguageManager.shared.localizedString(for: "meditation.mindfulness.title"),
                type: .meditation, duration: 480,
                description: LanguageManager.shared.localizedString(for: "meditation.mindfulness.short_description"),
                audioFileName: nil, icon: "eye.fill"),
        Exercise(id: "grounding",
                title: LanguageManager.shared.localizedString(for: "meditation.grounding.title"),
                type: .meditation, duration: 480,
                description: LanguageManager.shared.localizedString(for: "meditation.grounding.short_description"),
                audioFileName: nil, icon: "leaf.fill"),
        Exercise(id: "visualization",
                title: LanguageManager.shared.localizedString(for: "meditation.visualization.title"),
                type: .meditation, duration: 600,
                description: LanguageManager.shared.localizedString(for: "meditation.visualization.short_description"),
                audioFileName: nil, icon: "sparkles"),
        Exercise(id: "compassion",
                title: LanguageManager.shared.localizedString(for: "meditation.compassion.title"),
                type: .meditation, duration: 600,
                description: LanguageManager.shared.localizedString(for: "meditation.compassion.short_description"),
                audioFileName: nil, icon: "heart.fill"),
        Exercise(id: "focus-clarity",
                title: LanguageManager.shared.localizedString(for: "meditation.focus_clarity.title"),
                type: .meditation, duration: 720,
                description: LanguageManager.shared.localizedString(for: "meditation.focus_clarity.short_description"),
                audioFileName: nil, icon: "brain.head.profile"),
        Exercise(id: "yoga-nidra",
                title: LanguageManager.shared.localizedString(for: "meditation.yoga_nidra.title"),
                type: .meditation, duration: 1200,
                description: LanguageManager.shared.localizedString(for: "meditation.yoga_nidra.short_description"),
                audioFileName: nil, icon: "moon.stars.fill")
        ]
    }
}

extension Exercise {
    /// Guided audio session backing this meditation (nil for breathing / sounds).
    var guidedSession: GuidedSession? {
        guard type == .meditation else { return nil }
        return GuidedSessionCatalog.session(forLegacyID: id)
    }
}

// MARK: - Ambient sound artwork

extension Exercise {
    /// Photo of an ambient sound (rain, ocean…), used by the library tiles, the mini player and the lock screen.
    var soundImageName: String {
        let images = ["rain": "sound_rain", "ocean": "sound_ocean", "fire": "sound_fire", "whitenoise": "sound_whitenoise",
                      "wind": "sound_morning", "forest": "sound_forest", "stream": "sound_stream", "night": "sound_night"]
        return images[id] ?? "sound_rain"
    }
}
