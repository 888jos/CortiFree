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
        case .breathing: return NSLocalizedString("exercise_type.breathing", comment: "")
        case .meditation: return NSLocalizedString("exercise_type.meditation", comment: "")
        case .sound: return NSLocalizedString("exercise_type.sound", comment: "")
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

    static let breathingExercises: [Exercise] = [
        Exercise(id: "deep-abdominal",
                title: NSLocalizedString("breathing.deep_abdominal.title", comment: ""),
                type: .breathing, duration: 180,
                description: NSLocalizedString("breathing.deep_abdominal.description", comment: ""),
                audioFileName: nil, icon: "wind"),
        Exercise(id: "478",
                title: NSLocalizedString("breathing.478.title", comment: ""),
                type: .breathing, duration: 300,
                description: NSLocalizedString("breathing.478.description", comment: ""),
                audioFileName: nil, icon: "moon.stars.fill"),
        Exercise(id: "coherence",
                title: NSLocalizedString("breathing.coherence.title", comment: ""),
                type: .breathing, duration: 420,
                description: NSLocalizedString("breathing.coherence.description", comment: ""),
                audioFileName: nil, icon: "heart.fill"),
        Exercise(id: "slow-66",
                title: NSLocalizedString("breathing.slow.title", comment: ""),
                type: .breathing, duration: 420,
                description: NSLocalizedString("breathing.slow.description", comment: ""),
                audioFileName: nil, icon: "bed.double.fill"),
        Exercise(id: "triangle",
                title: NSLocalizedString("breathing.triangle.title", comment: ""),
                type: .breathing, duration: 300,
                description: NSLocalizedString("breathing.triangle.description", comment: ""),
                audioFileName: nil, icon: "triangle"),
        Exercise(id: "box",
                title: NSLocalizedString("breathing.box.title", comment: ""),
                type: .breathing, duration: 420,
                description: NSLocalizedString("breathing.box.description", comment: ""),
                audioFileName: nil, icon: "square"),
        Exercise(id: "kapalabhati",
                title: NSLocalizedString("breathing.kapalabhati.title", comment: ""),
                type: .breathing, duration: 300,
                description: NSLocalizedString("breathing.kapalabhati.description", comment: ""),
                audioFileName: nil, icon: "bolt.fill"),
        Exercise(id: "bhastrika",
                title: NSLocalizedString("breathing.bhastrika.title", comment: ""),
                type: .breathing, duration: 300,
                description: NSLocalizedString("breathing.bhastrika.description", comment: ""),
                audioFileName: nil, icon: "flame.fill")
    ]

    static let sounds: [Exercise] = [
        Exercise(id: "rain",
                title: NSLocalizedString("sounds.rain", comment: ""),
                type: .sound, duration: 0,
                description: NSLocalizedString("sounds.rain.description", comment: ""),
                audioFileName: "rain.m4a", icon: "cloud.rain.fill"),
        Exercise(id: "ocean",
                title: NSLocalizedString("sounds.ocean", comment: ""),
                type: .sound, duration: 0,
                description: NSLocalizedString("sounds.ocean.description", comment: ""),
                audioFileName: "ocean.m4a", icon: "water.waves"),
        Exercise(id: "fire",
                title: NSLocalizedString("sounds.fire", comment: ""),
                type: .sound, duration: 0,
                description: NSLocalizedString("sounds.fire.description", comment: ""),
                audioFileName: "fire.m4a", icon: "flame.fill"),
        Exercise(id: "whitenoise",
                title: NSLocalizedString("sounds.whitenoise", comment: ""),
                type: .sound, duration: 0,
                description: NSLocalizedString("sounds.whitenoise.description", comment: ""),
                audioFileName: "whitenoise.m4a", icon: "waveform"),
        Exercise(id: "wind",
                title: NSLocalizedString("sounds.morning", comment: ""),
                type: .sound, duration: 0,
                description: NSLocalizedString("sounds.morning.description", comment: ""),
                audioFileName: "morning.m4a", icon: "sunrise.fill"),
        Exercise(id: "forest",
                title: NSLocalizedString("sounds.forest", comment: ""),
                type: .sound, duration: 0,
                description: NSLocalizedString("sounds.forest.description", comment: ""),
                audioFileName: "forest.m4a", icon: "leaf.fill"),
        Exercise(id: "stream",
                title: NSLocalizedString("sounds.stream", comment: ""),
                type: .sound, duration: 0,
                description: NSLocalizedString("sounds.stream.description", comment: ""),
                audioFileName: "stream.m4a", icon: "drop.fill"),
        Exercise(id: "night",
                title: NSLocalizedString("sounds.night", comment: ""),
                type: .sound, duration: 0,
                description: NSLocalizedString("sounds.night.description", comment: ""),
                audioFileName: "summer-night.m4a", icon: "moon.stars.fill")
    ]

    static let meditations: [Exercise] = [
        Exercise(id: "conscious-breathing",
                title: NSLocalizedString("meditation.conscious_breathing.title", comment: ""),
                type: .meditation, duration: 180,
                description: NSLocalizedString("meditation.conscious_breathing.short_description", comment: ""),
                audioFileName: "conscious-breathing.mp3", icon: "wind"),
        Exercise(id: "body-scan",
                title: NSLocalizedString("meditation.body_scan.title", comment: ""),
                type: .meditation, duration: 300,
                description: NSLocalizedString("meditation.body_scan.short_description", comment: ""),
                audioFileName: "body-scan.mp3", icon: "figure.stand"),
        Exercise(id: "mindfulness",
                title: NSLocalizedString("meditation.mindfulness.title", comment: ""),
                type: .meditation, duration: 480,
                description: NSLocalizedString("meditation.mindfulness.short_description", comment: ""),
                audioFileName: "mindfulness.mp3", icon: "eye.fill"),
        Exercise(id: "grounding",
                title: NSLocalizedString("meditation.grounding.title", comment: ""),
                type: .meditation, duration: 480,
                description: NSLocalizedString("meditation.grounding.short_description", comment: ""),
                audioFileName: "grounding.mp3", icon: "leaf.fill"),
        Exercise(id: "visualization",
                title: NSLocalizedString("meditation.visualization.title", comment: ""),
                type: .meditation, duration: 600,
                description: NSLocalizedString("meditation.visualization.short_description", comment: ""),
                audioFileName: "visualization.mp3", icon: "sparkles"),
        Exercise(id: "compassion",
                title: NSLocalizedString("meditation.compassion.title", comment: ""),
                type: .meditation, duration: 600,
                description: NSLocalizedString("meditation.compassion.short_description", comment: ""),
                audioFileName: "compassion.mp3", icon: "heart.fill"),
        Exercise(id: "focus-clarity",
                title: NSLocalizedString("meditation.focus_clarity.title", comment: ""),
                type: .meditation, duration: 720,
                description: NSLocalizedString("meditation.focus_clarity.short_description", comment: ""),
                audioFileName: "focus-clarity.mp3", icon: "brain.head.profile"),
        Exercise(id: "yoga-nidra",
                title: NSLocalizedString("meditation.yoga_nidra.title", comment: ""),
                type: .meditation, duration: 1200,
                description: NSLocalizedString("meditation.yoga_nidra.short_description", comment: ""),
                audioFileName: "yoga-nidra.mp3", icon: "moon.stars.fill")
    ]
}
