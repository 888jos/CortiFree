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
        Exercise(id: "deep-abdominal", title: "Respiration abdominale profonde", type: .breathing, duration: 180,
                description: "Débutant - Base pour tous les exercices",
                audioFileName: nil, icon: "wind"),
        Exercise(id: "478", title: "4-7-8", type: .breathing, duration: 300,
                description: "Débutant - Anxiété, sommeil",
                audioFileName: nil, icon: "moon.stars.fill"),
        Exercise(id: "coherence", title: "Cohérence cardiaque 5-5", type: .breathing, duration: 420,
                description: "Débutant - Stress quotidien ⭐",
                audioFileName: nil, icon: "heart.fill"),
        Exercise(id: "slow-66", title: "Respiration lente 6-6", type: .breathing, duration: 420,
                description: "Débutant - Sommeil profond",
                audioFileName: nil, icon: "bed.double.fill"),
        Exercise(id: "triangle", title: "Triangle Breathing 4-4-4", type: .breathing, duration: 300,
                description: "Débutant - Relaxation",
                audioFileName: nil, icon: "triangle"),
        Exercise(id: "box", title: "Box Breathing 4-4-4-4", type: .breathing, duration: 420,
                description: "Intermédiaire - Stress aigu",
                audioFileName: nil, icon: "square"),
        Exercise(id: "kapalabhati", title: "Kapalabhati", type: .breathing, duration: 300,
                description: "Avancé - Énergie explosive",
                audioFileName: nil, icon: "bolt.fill"),
        Exercise(id: "bhastrika", title: "Bhastrika (Soufflet)", type: .breathing, duration: 300,
                description: "Avancé - Énergie intense",
                audioFileName: nil, icon: "flame.fill")
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
        Exercise(id: "conscious-breathing", title: "Respiration consciente", type: .meditation, duration: 180,
                description: "Débutant - Premier pas",
                audioFileName: "conscious-breathing.mp3", icon: "wind"),
        Exercise(id: "body-scan", title: "Body Scan express", type: .meditation, duration: 300,
                description: "Débutant - Tensions rapides",
                audioFileName: "body-scan.mp3", icon: "figure.stand"),
        Exercise(id: "mindfulness", title: "Mindfulness de base", type: .meditation, duration: 480,
                description: "Débutant - Observer pensées",
                audioFileName: "mindfulness.mp3", icon: "eye.fill"),
        Exercise(id: "grounding", title: "Ancrage corporel / Grounding", type: .meditation, duration: 480,
                description: "Débutant - Anxiété, crises",
                audioFileName: "grounding.mp3", icon: "leaf.fill"),
        Exercise(id: "visualization", title: "Visualisation lieu sûr", type: .meditation, duration: 600,
                description: "Intermédiaire - Calme mental",
                audioFileName: "visualization.mp3", icon: "sparkles"),
        Exercise(id: "compassion", title: "Auto-compassion", type: .meditation, duration: 600,
                description: "Intermédiaire - Bienveillance",
                audioFileName: "compassion.mp3", icon: "heart.fill"),
        Exercise(id: "focus-clarity", title: "Méditation focus/clarté", type: .meditation, duration: 720,
                description: "Intermédiaire - Concentration",
                audioFileName: "focus-clarity.mp3", icon: "brain.head.profile"),
        Exercise(id: "yoga-nidra", title: "Méditation sommeil / Yoga Nidra", type: .meditation, duration: 1200,
                description: "Avancé - Sommeil profond",
                audioFileName: "yoga-nidra.mp3", icon: "moon.stars.fill")
    ]
}
