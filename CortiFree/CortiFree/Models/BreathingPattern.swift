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

    static let deepAbdominal = BreathingPattern(
        name: "DeepAbdominal",
        displayName: "Respiration abdominale profonde",
        inhaleDuration: 4,
        holdDuration: 2,
        exhaleDuration: 6,
        description: "Base pour tous les exercices"
    )

    static let fourSevenEight = BreathingPattern(
        name: "4-7-8",
        displayName: "4-7-8",
        inhaleDuration: 4,
        holdDuration: 7,
        exhaleDuration: 8,
        description: "Anxiété, sommeil"
    )

    static let coherence = BreathingPattern(
        name: "Coherence",
        displayName: "Cohérence cardiaque 5-5",
        inhaleDuration: 5,
        holdDuration: 0,
        exhaleDuration: 5,
        description: "Stress quotidien ⭐"
    )

    static let slow66 = BreathingPattern(
        name: "Slow66",
        displayName: "Respiration lente 6-6",
        inhaleDuration: 6,
        holdDuration: 0,
        exhaleDuration: 6,
        description: "Sommeil profond"
    )

    static let triangle = BreathingPattern(
        name: "Triangle",
        displayName: "Triangle Breathing 4-4-4",
        inhaleDuration: 4,
        holdDuration: 4,
        exhaleDuration: 4,
        description: "Relaxation"
    )

    static let boxBreathing = BreathingPattern(
        name: "Box",
        displayName: "Box Breathing 4-4-4-4",
        inhaleDuration: 4,
        holdDuration: 4,
        exhaleDuration: 4,
        description: "Stress aigu"
    )

    static let kapalabhati = BreathingPattern(
        name: "Kapalabhati",
        displayName: "Kapalabhati",
        inhaleDuration: 1,
        holdDuration: 0,
        exhaleDuration: 1,
        description: "Énergie explosive"
    )

    static let bhastrika = BreathingPattern(
        name: "Bhastrika",
        displayName: "Bhastrika (Soufflet)",
        inhaleDuration: 1,
        holdDuration: 0,
        exhaleDuration: 1,
        description: "Énergie intense"
    )

    static let allPatterns: [BreathingPattern] = [
        .deepAbdominal,
        .fourSevenEight,
        .coherence,
        .slow66,
        .triangle,
        .boxBreathing,
        .kapalabhati,
        .bhastrika
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
