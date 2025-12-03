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
    let holdOutDuration: Double // Pour box breathing (4 phases)
    let description: String

    var totalCycleDuration: Double {
        inhaleDuration + holdDuration + exhaleDuration + holdOutDuration
    }

    /// Description courte pour l'affichage dans l'exercice (format: "4s - 2s - 6s")
    var shortDescription: String {
        if holdOutDuration > 0 {
            // Box breathing: 4-4-4-4
            return String(format: NSLocalizedString("breathing.rhythm.four_phases", comment: ""),
                          Int(inhaleDuration), Int(holdDuration), Int(exhaleDuration), Int(holdOutDuration))
        } else if holdDuration > 0 {
            // 3 phases: 4-7-8
            return String(format: NSLocalizedString("breathing.rhythm.three_phases", comment: ""),
                          Int(inhaleDuration), Int(holdDuration), Int(exhaleDuration))
        } else {
            // 2 phases: 5-5
            return String(format: NSLocalizedString("breathing.rhythm.two_phases", comment: ""),
                          Int(inhaleDuration), Int(exhaleDuration))
        }
    }

    // Init avec holdOutDuration par défaut à 0
    init(name: String, displayName: String, inhaleDuration: Double, holdDuration: Double, exhaleDuration: Double, holdOutDuration: Double = 0, description: String) {
        self.name = name
        self.displayName = displayName
        self.inhaleDuration = inhaleDuration
        self.holdDuration = holdDuration
        self.exhaleDuration = exhaleDuration
        self.holdOutDuration = holdOutDuration
        self.description = description
    }

    // MARK: - Preset Patterns

    static let deepAbdominal = BreathingPattern(
        name: "DeepAbdominal",
        displayName: NSLocalizedString("library.breathing.deep_abdominal", comment: ""),
        inhaleDuration: 4,
        holdDuration: 2,
        exhaleDuration: 6,
        description: NSLocalizedString("breathing_pattern.deep_abdominal.description", comment: "")
    )

    static let fourSevenEight = BreathingPattern(
        name: "4-7-8",
        displayName: NSLocalizedString("library.breathing.4_7_8", comment: ""),
        inhaleDuration: 4,
        holdDuration: 7,
        exhaleDuration: 8,
        description: NSLocalizedString("breathing_pattern.four_seven_eight.description", comment: "")
    )

    static let coherence = BreathingPattern(
        name: "Coherence",
        displayName: NSLocalizedString("library.breathing.cardiac_coherence", comment: ""),
        inhaleDuration: 5,
        holdDuration: 0,
        exhaleDuration: 5,
        description: NSLocalizedString("breathing_pattern.coherence.description", comment: "")
    )

    static let slow66 = BreathingPattern(
        name: "Slow66",
        displayName: NSLocalizedString("library.breathing.slow", comment: ""),
        inhaleDuration: 6,
        holdDuration: 0,
        exhaleDuration: 6,
        description: NSLocalizedString("breathing_pattern.slow66.description", comment: "")
    )

    static let triangle = BreathingPattern(
        name: "Triangle",
        displayName: NSLocalizedString("library.breathing.triangle", comment: ""),
        inhaleDuration: 4,
        holdDuration: 4,
        exhaleDuration: 4,
        description: NSLocalizedString("breathing_pattern.triangle.description", comment: "")
    )

    static let boxBreathing = BreathingPattern(
        name: "Box",
        displayName: NSLocalizedString("library.breathing.box", comment: ""),
        inhaleDuration: 4,
        holdDuration: 4,
        exhaleDuration: 4,
        holdOutDuration: 4, // Box breathing: 4-4-4-4
        description: NSLocalizedString("breathing_pattern.box.description", comment: "")
    )

    static let kapalabhati = BreathingPattern(
        name: "Kapalabhati",
        displayName: NSLocalizedString("library.breathing.kapalabhati", comment: ""),
        inhaleDuration: 1,
        holdDuration: 0,
        exhaleDuration: 1,
        description: NSLocalizedString("breathing_pattern.kapalabhati.description", comment: "")
    )

    static let bhastrika = BreathingPattern(
        name: "Bhastrika",
        displayName: NSLocalizedString("library.breathing.bhastrika", comment: ""),
        inhaleDuration: 1,
        holdDuration: 0,
        exhaleDuration: 1,
        description: NSLocalizedString("breathing_pattern.bhastrika.description", comment: "")
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
    case inhale
    case hold
    case exhale

    var displayText: String {
        switch self {
        case .inhale:
            return NSLocalizedString("breathing.phase.inhale", comment: "")
        case .hold:
            return NSLocalizedString("breathing.phase.hold", comment: "")
        case .exhale:
            return NSLocalizedString("breathing.phase.exhale", comment: "")
        }
    }

    var glowIntensity: Double {
        switch self {
        case .inhale: return 1.0
        case .hold: return 0.8
        case .exhale: return 0.4
        }
    }
}
