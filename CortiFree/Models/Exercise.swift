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
        case .breathing: return "Respiration"
        case .meditation: return "Méditation"
        case .sound: return "Sons Relaxants"
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
        Exercise(id: "478", title: "4-7-8", type: .breathing, duration: 240,
                description: "Inspire 4s, retiens 7s, expire 8s",
                audioFileName: nil, icon: "wind"),
        Exercise(id: "box", title: "Box Breathing", type: .breathing, duration: 300,
                description: "4 temps égaux pour respirer",
                audioFileName: nil, icon: "square"),
        Exercise(id: "coherence", title: "Cohérence Cardiaque", type: .breathing, duration: 300,
                description: "5s inspire, 5s expire pendant 5min",
                audioFileName: nil, icon: "heart.fill"),
        Exercise(id: "anulom", title: "Anulom-Vilom", type: .breathing, duration: 420,
                description: "Respiration alternée des narines",
                audioFileName: nil, icon: "nose")
    ]

    static let sounds: [Exercise] = [
        Exercise(id: "rain", title: "Pluie", type: .sound, duration: 0,
                description: "Son apaisant de pluie",
                audioFileName: "rain.mp3", icon: "cloud.rain.fill"),
        Exercise(id: "ocean", title: "Océan", type: .sound, duration: 0,
                description: "Vagues relaxantes",
                audioFileName: "ocean.mp3", icon: "water.waves"),
        Exercise(id: "fire", title: "Feu", type: .sound, duration: 0,
                description: "Crépitement du feu",
                audioFileName: "fire.mp3", icon: "flame.fill"),
        Exercise(id: "whitenoise", title: "Bruit Blanc", type: .sound, duration: 0,
                description: "Bruit blanc apaisant",
                audioFileName: "whitenoise.mp3", icon: "waveform"),
        Exercise(id: "wind", title: "Matinée", type: .sound, duration: 0,
                description: "Ambiance matinale apaisante",
                audioFileName: "morning.mp3", icon: "sunrise.fill"),
        Exercise(id: "forest", title: "Forêt", type: .sound, duration: 0,
                description: "Ambiance forestière relaxante",
                audioFileName: "forest.mp3", icon: "leaf.fill"),
        Exercise(id: "stream", title: "Ruisseau", type: .sound, duration: 0,
                description: "Écoulement d'eau douce",
                audioFileName: "stream.mp3", icon: "drop.fill"),
        Exercise(id: "night", title: "Nuit d'été", type: .sound, duration: 0,
                description: "Ambiance nocturne estivale paisible",
                audioFileName: "summer-night.mp3", icon: "moon.stars.fill")
    ]

    static let meditations: [Exercise] = [
        Exercise(id: "body-scan", title: "Scan Corporel", type: .meditation, duration: 600,
                description: "Méditation guidée pour scanner le corps",
                audioFileName: "body-scan.mp3", icon: "leaf.fill"),
        Exercise(id: "gratitude", title: "Gratitude", type: .meditation, duration: 480,
                description: "Cultiver la reconnaissance",
                audioFileName: "gratitude.mp3", icon: "heart.text.square.fill"),
        Exercise(id: "mindfulness", title: "Pleine Conscience", type: .meditation, duration: 600,
                description: "Être présent dans l'instant",
                audioFileName: "mindfulness.mp3", icon: "sunrise.fill"),
        Exercise(id: "visualization", title: "Visualisation", type: .meditation, duration: 540,
                description: "Imagerie mentale positive",
                audioFileName: "visualization.mp3", icon: "sparkles"),
        Exercise(id: "compassion", title: "Auto-Compassion", type: .meditation, duration: 480,
                description: "Développer la bienveillance envers soi",
                audioFileName: "compassion.mp3", icon: "heart.fill"),
        Exercise(id: "clarity", title: "Clarté", type: .meditation, duration: 420,
                description: "Clarifier l'esprit et les pensées",
                audioFileName: "clarity.mp3", icon: "brain.head.profile"),
        Exercise(id: "walking", title: "Marche Méditative", type: .meditation, duration: 600,
                description: "Méditation en mouvement",
                audioFileName: "walking.mp3", icon: "figure.walk"),
        Exercise(id: "grounding", title: "Ancrage", type: .meditation, duration: 360,
                description: "S'enraciner dans le moment présent",
                audioFileName: "grounding.mp3", icon: "star.fill")
    ]
}
