//
//  BreathingPattern.swift
//  CortiFree
//
//  Created by Claude on 22/10/2025.
//  Data model for breathing exercise patterns
//

import Foundation

// MARK: - Breathing Pattern

struct BreathingPattern: Identifiable {
    let id = UUID()
    let name: String
    let displayName: String
    let inhaleDuration: Double
    let holdDuration: Double
    let exhaleDuration: Double
    let description: String

    var totalCycleDuration: Double {
        inhaleDuration + holdDuration + exhaleDuration
    }

    // MARK: - Preset Patterns

    static let fourSevenEight = BreathingPattern(
        name: "4-7-8",
        displayName: "Respiration 4-7-8",
        inhaleDuration: 4,
        holdDuration: 7,
        exhaleDuration: 8,
        description: "Ralentis ton rythme cardiaque"
    )

    static let boxBreathing = BreathingPattern(
        name: "Box",
        displayName: "Respiration Carrée",
        inhaleDuration: 4,
        holdDuration: 4,
        exhaleDuration: 4,
        description: "Technique militaire anti-stress"
    )

    static let coherence = BreathingPattern(
        name: "Coherence",
        displayName: "Cohérence Cardiaque",
        inhaleDuration: 5,
        holdDuration: 0,
        exhaleDuration: 5,
        description: "Équilibre ton système nerveux"
    )

    static let deepRelax = BreathingPattern(
        name: "DeepRelax",
        displayName: "Relaxation Profonde",
        inhaleDuration: 4,
        holdDuration: 2,
        exhaleDuration: 6,
        description: "Détente complète du corps"
    )

    static let energizing = BreathingPattern(
        name: "Energizing",
        displayName: "Respiration Énergisante",
        inhaleDuration: 3,
        holdDuration: 1,
        exhaleDuration: 3,
        description: "Booste ton énergie"
    )

    static let allPatterns: [BreathingPattern] = [
        .fourSevenEight,
        .boxBreathing,
        .coherence,
        .deepRelax,
        .energizing
    ]
}

// MARK: - Breathing Phase

enum BreathingPhase: String {
    case inhale = "Inspire"
    case hold = "Maintiens"
    case exhale = "Expire"

    var displayText: String {
        return self.rawValue
    }

    var glowIntensity: Double {
        switch self {
        case .inhale: return 1.0
        case .hold: return 0.8
        case .exhale: return 0.4
        }
    }
}
