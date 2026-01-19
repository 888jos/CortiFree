//
//  Routine.swift
//  CortiFree
//
//  Created on 19/01/2026.
//

import Foundation
import SwiftUI

// MARK: - Routine Step Type
enum RoutineStepType: String, Codable {
    case breathing     // Links to BreathingPattern
    case meditation    // Links to MeditationSupport
    case sound         // Links to Exercise (sound type)
    case journaling    // Opens journal with prompt
    case pause         // Simple timed pause with instruction
}

// MARK: - Routine Step
struct RoutineStep: Identifiable, Codable {
    let id: String
    let type: RoutineStepType
    let referenceId: String?      // ID of breathing pattern, meditation, or sound
    let duration: Int             // Duration in seconds
    let instructionKey: String    // Localization key for instruction text
    let icon: String              // SF Symbol name

    var localizedInstruction: String {
        NSLocalizedString(instructionKey, comment: "")
    }
}

// MARK: - Routine
struct Routine: Identifiable {
    let id: String
    let nameKey: String           // Localization key
    let descriptionKey: String    // Localization key for benefit
    let icon: String              // SF Symbol
    let color: String             // Hex color
    let totalDuration: Int        // Total duration in seconds
    let steps: [RoutineStep]
    let impactDomains: [String]   // e.g., ["Energy", "Focus"]
    let difficulty: Int           // 1-3 scale

    var localizedName: String {
        NSLocalizedString(nameKey, comment: "")
    }

    var localizedDescription: String {
        NSLocalizedString(descriptionKey, comment: "")
    }

    var formattedDuration: String {
        let minutes = totalDuration / 60
        if minutes < 60 {
            return "\(minutes) min"
        } else {
            let hours = minutes / 60
            let remainingMins = minutes % 60
            return remainingMins > 0 ? "\(hours)h \(remainingMins)min" : "\(hours)h"
        }
    }
}

// MARK: - Predefined Routines
extension Routine {

    static let allRoutines: [Routine] = [
        morningRoutine,
        sleepRoutine,
        focusRoutine,
        energyRoutine,
        stressRoutine,
        relaxationRoutine,
        quickRoutine,
        deepWorkRoutine
    ]

    // MARK: 1. Morning Routine (Routine Matinale) - 10 min
    static let morningRoutine = Routine(
        id: "morning",
        nameKey: "routine.morning.name",
        descriptionKey: "routine.morning.description",
        icon: "sunrise.fill",
        color: "FFB74D",  // Orange/gold
        totalDuration: 600, // 10 min
        steps: [
            RoutineStep(
                id: "m1",
                type: .breathing,
                referenceId: "deepAbdominal",
                duration: 180,
                instructionKey: "routine.morning.step1",
                icon: "wind"
            ),
            RoutineStep(
                id: "m2",
                type: .meditation,
                referenceId: "conscious-breathing",
                duration: 180,
                instructionKey: "routine.morning.step2",
                icon: "brain.head.profile"
            ),
            RoutineStep(
                id: "m3",
                type: .journaling,
                referenceId: nil,
                duration: 180,
                instructionKey: "routine.morning.step3",
                icon: "pencil.and.list.clipboard"
            ),
            RoutineStep(
                id: "m4",
                type: .pause,
                referenceId: nil,
                duration: 60,
                instructionKey: "routine.morning.step4",
                icon: "sparkles"
            )
        ],
        impactDomains: ["Energy", "Focus", "Balance"],
        difficulty: 1
    )

    // MARK: 2. Sleep Routine (Routine Sommeil) - 15 min
    static let sleepRoutine = Routine(
        id: "sleep",
        nameKey: "routine.sleep.name",
        descriptionKey: "routine.sleep.description",
        icon: "moon.zzz.fill",
        color: "5C6BC0",  // Indigo
        totalDuration: 900, // 15 min
        steps: [
            RoutineStep(
                id: "s1",
                type: .sound,
                referenceId: "rain",
                duration: 60,
                instructionKey: "routine.sleep.step1",
                icon: "cloud.rain.fill"
            ),
            RoutineStep(
                id: "s2",
                type: .breathing,
                referenceId: "fourSevenEight",
                duration: 300,
                instructionKey: "routine.sleep.step2",
                icon: "moon.stars.fill"
            ),
            RoutineStep(
                id: "s3",
                type: .meditation,
                referenceId: "yoga-nidra",
                duration: 480,
                instructionKey: "routine.sleep.step3",
                icon: "bed.double.fill"
            ),
            RoutineStep(
                id: "s4",
                type: .pause,
                referenceId: nil,
                duration: 60,
                instructionKey: "routine.sleep.step4",
                icon: "zzz"
            )
        ],
        impactDomains: ["Sleep", "Serenity"],
        difficulty: 1
    )

    // MARK: 3. Focus Routine (Concentration) - 12 min
    static let focusRoutine = Routine(
        id: "focus",
        nameKey: "routine.focus.name",
        descriptionKey: "routine.focus.description",
        icon: "brain.head.profile",
        color: "26A69A",  // Teal
        totalDuration: 720, // 12 min
        steps: [
            RoutineStep(
                id: "f1",
                type: .breathing,
                referenceId: "coherence",
                duration: 300,
                instructionKey: "routine.focus.step1",
                icon: "heart.fill"
            ),
            RoutineStep(
                id: "f2",
                type: .meditation,
                referenceId: "focus-clarity",
                duration: 300,
                instructionKey: "routine.focus.step2",
                icon: "target"
            ),
            RoutineStep(
                id: "f3",
                type: .pause,
                referenceId: nil,
                duration: 60,
                instructionKey: "routine.focus.step3",
                icon: "lightbulb.fill"
            ),
            RoutineStep(
                id: "f4",
                type: .journaling,
                referenceId: nil,
                duration: 60,
                instructionKey: "routine.focus.step4",
                icon: "list.bullet.clipboard"
            )
        ],
        impactDomains: ["Focus", "Energy"],
        difficulty: 2
    )

    // MARK: 4. Energy Boost (Boost d'Énergie) - 8 min
    static let energyRoutine = Routine(
        id: "energy",
        nameKey: "routine.energy.name",
        descriptionKey: "routine.energy.description",
        icon: "bolt.fill",
        color: "FF7043",  // Deep orange
        totalDuration: 480, // 8 min
        steps: [
            RoutineStep(
                id: "e1",
                type: .breathing,
                referenceId: "kapalabhati",
                duration: 120,
                instructionKey: "routine.energy.step1",
                icon: "bolt.fill"
            ),
            RoutineStep(
                id: "e2",
                type: .breathing,
                referenceId: "bhastrika",
                duration: 120,
                instructionKey: "routine.energy.step2",
                icon: "flame.fill"
            ),
            RoutineStep(
                id: "e3",
                type: .pause,
                referenceId: nil,
                duration: 60,
                instructionKey: "routine.energy.step3",
                icon: "figure.stand"
            ),
            RoutineStep(
                id: "e4",
                type: .meditation,
                referenceId: "visualization",
                duration: 180,
                instructionKey: "routine.energy.step4",
                icon: "sparkles"
            )
        ],
        impactDomains: ["Energy", "Focus"],
        difficulty: 3
    )

    // MARK: 5. Stress Relief (Anti-stress) - 10 min
    static let stressRoutine = Routine(
        id: "stress",
        nameKey: "routine.stress.name",
        descriptionKey: "routine.stress.description",
        icon: "heart.fill",
        color: "EC407A",  // Pink
        totalDuration: 600, // 10 min
        steps: [
            RoutineStep(
                id: "st1",
                type: .breathing,
                referenceId: "boxBreathing",
                duration: 240,
                instructionKey: "routine.stress.step1",
                icon: "square"
            ),
            RoutineStep(
                id: "st2",
                type: .meditation,
                referenceId: "grounding",
                duration: 180,
                instructionKey: "routine.stress.step2",
                icon: "leaf.fill"
            ),
            RoutineStep(
                id: "st3",
                type: .meditation,
                referenceId: "compassion",
                duration: 120,
                instructionKey: "routine.stress.step3",
                icon: "heart.fill"
            ),
            RoutineStep(
                id: "st4",
                type: .pause,
                referenceId: nil,
                duration: 60,
                instructionKey: "routine.stress.step4",
                icon: "hand.raised.fill"
            )
        ],
        impactDomains: ["Serenity", "Balance"],
        difficulty: 2
    )

    // MARK: 6. Relaxation (Détente) - 12 min
    static let relaxationRoutine = Routine(
        id: "relaxation",
        nameKey: "routine.relaxation.name",
        descriptionKey: "routine.relaxation.description",
        icon: "sparkles",
        color: "7E57C2",  // Deep purple
        totalDuration: 720, // 12 min
        steps: [
            RoutineStep(
                id: "r1",
                type: .sound,
                referenceId: "ocean",
                duration: 120,
                instructionKey: "routine.relaxation.step1",
                icon: "water.waves"
            ),
            RoutineStep(
                id: "r2",
                type: .breathing,
                referenceId: "slow66",
                duration: 300,
                instructionKey: "routine.relaxation.step2",
                icon: "wind"
            ),
            RoutineStep(
                id: "r3",
                type: .meditation,
                referenceId: "body-scan",
                duration: 240,
                instructionKey: "routine.relaxation.step3",
                icon: "figure.stand"
            ),
            RoutineStep(
                id: "r4",
                type: .pause,
                referenceId: nil,
                duration: 60,
                instructionKey: "routine.relaxation.step4",
                icon: "face.smiling"
            )
        ],
        impactDomains: ["Serenity", "Sleep"],
        difficulty: 1
    )

    // MARK: 7. Quick Break (Pause Rapide) - 3 min
    static let quickRoutine = Routine(
        id: "quick",
        nameKey: "routine.quick.name",
        descriptionKey: "routine.quick.description",
        icon: "timer",
        color: "42A5F5",  // Blue
        totalDuration: 180, // 3 min
        steps: [
            RoutineStep(
                id: "q1",
                type: .breathing,
                referenceId: "triangle",
                duration: 120,
                instructionKey: "routine.quick.step1",
                icon: "triangle"
            ),
            RoutineStep(
                id: "q2",
                type: .pause,
                referenceId: nil,
                duration: 60,
                instructionKey: "routine.quick.step2",
                icon: "checkmark.circle.fill"
            )
        ],
        impactDomains: ["Serenity", "Focus"],
        difficulty: 1
    )

    // MARK: 8. Deep Work (Concentration Profonde) - 20 min
    static let deepWorkRoutine = Routine(
        id: "deepwork",
        nameKey: "routine.deepwork.name",
        descriptionKey: "routine.deepwork.description",
        icon: "target",
        color: "66BB6A",  // Green
        totalDuration: 1200, // 20 min
        steps: [
            RoutineStep(
                id: "d1",
                type: .breathing,
                referenceId: "coherence",
                duration: 300,
                instructionKey: "routine.deepwork.step1",
                icon: "heart.fill"
            ),
            RoutineStep(
                id: "d2",
                type: .journaling,
                referenceId: nil,
                duration: 180,
                instructionKey: "routine.deepwork.step2",
                icon: "pencil.and.list.clipboard"
            ),
            RoutineStep(
                id: "d3",
                type: .meditation,
                referenceId: "focus-clarity",
                duration: 420,
                instructionKey: "routine.deepwork.step3",
                icon: "brain.head.profile"
            ),
            RoutineStep(
                id: "d4",
                type: .sound,
                referenceId: "whitenoise",
                duration: 240,
                instructionKey: "routine.deepwork.step4",
                icon: "waveform"
            ),
            RoutineStep(
                id: "d5",
                type: .pause,
                referenceId: nil,
                duration: 60,
                instructionKey: "routine.deepwork.step5",
                icon: "checkmark.seal.fill"
            )
        ],
        impactDomains: ["Focus", "Energy", "Balance"],
        difficulty: 3
    )

    // MARK: - Helper Methods
    static func routine(for id: String) -> Routine? {
        return allRoutines.first { $0.id == id }
    }
}
