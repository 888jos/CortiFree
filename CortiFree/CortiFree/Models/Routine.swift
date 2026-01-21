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

// MARK: - Routine Category
enum RoutineCategory: String, CaseIterable {
    case morning = "morning"
    case sleep = "sleep"
    case focus = "focus"
    case energy = "energy"
    case stress = "stress"
    case relaxation = "relaxation"

    var nameKey: String {
        "routine.category.\(rawValue)"
    }

    var localizedName: String {
        NSLocalizedString(nameKey, comment: "")
    }

    var icon: String {
        switch self {
        case .morning: return "sunrise.fill"
        case .sleep: return "moon.zzz.fill"
        case .focus: return "brain.head.profile"
        case .energy: return "bolt.fill"
        case .stress: return "heart.fill"
        case .relaxation: return "sparkles"
        }
    }

    var color: String {
        switch self {
        case .morning: return "FFB74D"
        case .sleep: return "5C6BC0"
        case .focus: return "26A69A"
        case .energy: return "FF7043"
        case .stress: return "EC407A"
        case .relaxation: return "7E57C2"
        }
    }

    var imageName: String {
        "routine_\(rawValue)"
    }

    var descriptionKey: String {
        "routine.category.\(rawValue).description"
    }

    var localizedDescription: String {
        NSLocalizedString(descriptionKey, comment: "")
    }

    var durationRange: String {
        switch self {
        case .morning: return "5-15 min"
        case .sleep: return "5-20 min"
        case .focus: return "5-20 min"
        case .energy: return "3-15 min"
        case .stress: return "5-15 min"
        case .relaxation: return "5-20 min"
        }
    }
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
    let category: RoutineCategory
    let difficulty: Int           // 1-3 scale (Débutant, Intermédiaire, Avancé)
    let nameKey: String           // Localization key
    let descriptionKey: String    // Localization key for benefit
    let totalDuration: Int        // Total duration in seconds
    let steps: [RoutineStep]
    let impactDomains: [String]   // e.g., ["Energy", "Focus"]

    var icon: String { category.icon }
    var color: String { category.color }
    var imageName: String { category.imageName }

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

    var difficultyText: String {
        switch difficulty {
        case 1: return NSLocalizedString("routine.difficulty.beginner", comment: "")
        case 2: return NSLocalizedString("routine.difficulty.intermediate", comment: "")
        case 3: return NSLocalizedString("routine.difficulty.advanced", comment: "")
        default: return ""
        }
    }
}

// MARK: - Predefined Routines
extension Routine {

    // All routines grouped by category
    static let allRoutines: [Routine] = [
        // Morning - 3 levels
        morningBeginner, morningIntermediate, morningAdvanced,
        // Sleep - 3 levels
        sleepBeginner, sleepIntermediate, sleepAdvanced,
        // Focus - 3 levels
        focusBeginner, focusIntermediate, focusAdvanced,
        // Energy - 3 levels
        energyBeginner, energyIntermediate, energyAdvanced,
        // Stress - 3 levels
        stressBeginner, stressIntermediate, stressAdvanced,
        // Relaxation - 3 levels
        relaxationBeginner, relaxationIntermediate, relaxationAdvanced
    ]

    static func routines(for category: RoutineCategory) -> [Routine] {
        allRoutines.filter { $0.category == category }
    }

    // =====================================================
    // MARK: - MORNING ROUTINES
    // =====================================================

    static let morningBeginner = Routine(
        id: "morning_1",
        category: .morning,
        difficulty: 1,
        nameKey: "routine.morning.1.name",
        descriptionKey: "routine.morning.1.description",
        totalDuration: 300, // 5 min
        steps: [
            RoutineStep(id: "m1_1", type: .breathing, referenceId: "deepAbdominal", duration: 180, instructionKey: "routine.morning.step.breathing", icon: "wind"),
            RoutineStep(id: "m1_2", type: .pause, referenceId: nil, duration: 120, instructionKey: "routine.morning.step.intention", icon: "sparkles")
        ],
        impactDomains: ["Energy", "Focus"]
    )

    static let morningIntermediate = Routine(
        id: "morning_2",
        category: .morning,
        difficulty: 2,
        nameKey: "routine.morning.2.name",
        descriptionKey: "routine.morning.2.description",
        totalDuration: 600, // 10 min
        steps: [
            RoutineStep(id: "m2_1", type: .breathing, referenceId: "deepAbdominal", duration: 180, instructionKey: "routine.morning.step.breathing", icon: "wind"),
            RoutineStep(id: "m2_2", type: .meditation, referenceId: "conscious-breathing", duration: 300, instructionKey: "routine.morning.step.meditation", icon: "brain.head.profile"),
            RoutineStep(id: "m2_3", type: .pause, referenceId: nil, duration: 120, instructionKey: "routine.morning.step.intention", icon: "sparkles")
        ],
        impactDomains: ["Energy", "Focus", "Serenity"]
    )

    static let morningAdvanced = Routine(
        id: "morning_3",
        category: .morning,
        difficulty: 3,
        nameKey: "routine.morning.3.name",
        descriptionKey: "routine.morning.3.description",
        totalDuration: 900, // 15 min
        steps: [
            RoutineStep(id: "m3_1", type: .breathing, referenceId: "coherence", duration: 300, instructionKey: "routine.morning.step.coherence", icon: "heart.fill"),
            RoutineStep(id: "m3_2", type: .meditation, referenceId: "visualization", duration: 300, instructionKey: "routine.morning.step.visualization", icon: "eye.fill"),
            RoutineStep(id: "m3_3", type: .journaling, referenceId: nil, duration: 180, instructionKey: "routine.morning.step.journal", icon: "pencil.and.list.clipboard"),
            RoutineStep(id: "m3_4", type: .pause, referenceId: nil, duration: 120, instructionKey: "routine.morning.step.intention", icon: "sparkles")
        ],
        impactDomains: ["Energy", "Focus", "Balance"]
    )

    // =====================================================
    // MARK: - SLEEP ROUTINES
    // =====================================================

    static let sleepBeginner = Routine(
        id: "sleep_1",
        category: .sleep,
        difficulty: 1,
        nameKey: "routine.sleep.1.name",
        descriptionKey: "routine.sleep.1.description",
        totalDuration: 300, // 5 min
        steps: [
            RoutineStep(id: "s1_1", type: .breathing, referenceId: "fourSevenEight", duration: 240, instructionKey: "routine.sleep.step.478", icon: "moon.stars.fill"),
            RoutineStep(id: "s1_2", type: .pause, referenceId: nil, duration: 60, instructionKey: "routine.sleep.step.relax", icon: "zzz")
        ],
        impactDomains: ["Sleep", "Serenity"]
    )

    static let sleepIntermediate = Routine(
        id: "sleep_2",
        category: .sleep,
        difficulty: 2,
        nameKey: "routine.sleep.2.name",
        descriptionKey: "routine.sleep.2.description",
        totalDuration: 600, // 10 min
        steps: [
            RoutineStep(id: "s2_1", type: .sound, referenceId: "rain", duration: 60, instructionKey: "routine.sleep.step.sound", icon: "cloud.rain.fill"),
            RoutineStep(id: "s2_2", type: .breathing, referenceId: "fourSevenEight", duration: 300, instructionKey: "routine.sleep.step.478", icon: "moon.stars.fill"),
            RoutineStep(id: "s2_3", type: .meditation, referenceId: "body-scan", duration: 240, instructionKey: "routine.sleep.step.bodyscan", icon: "figure.stand")
        ],
        impactDomains: ["Sleep", "Serenity"]
    )

    static let sleepAdvanced = Routine(
        id: "sleep_3",
        category: .sleep,
        difficulty: 3,
        nameKey: "routine.sleep.3.name",
        descriptionKey: "routine.sleep.3.description",
        totalDuration: 1200, // 20 min
        steps: [
            RoutineStep(id: "s3_1", type: .sound, referenceId: "rain", duration: 120, instructionKey: "routine.sleep.step.sound", icon: "cloud.rain.fill"),
            RoutineStep(id: "s3_2", type: .breathing, referenceId: "slow66", duration: 300, instructionKey: "routine.sleep.step.slow", icon: "wind"),
            RoutineStep(id: "s3_3", type: .meditation, referenceId: "yoga-nidra", duration: 600, instructionKey: "routine.sleep.step.nidra", icon: "bed.double.fill"),
            RoutineStep(id: "s3_4", type: .journaling, referenceId: nil, duration: 180, instructionKey: "routine.sleep.step.journal", icon: "book.fill")
        ],
        impactDomains: ["Sleep", "Serenity", "Balance"]
    )

    // =====================================================
    // MARK: - FOCUS ROUTINES
    // =====================================================

    static let focusBeginner = Routine(
        id: "focus_1",
        category: .focus,
        difficulty: 1,
        nameKey: "routine.focus.1.name",
        descriptionKey: "routine.focus.1.description",
        totalDuration: 300, // 5 min
        steps: [
            RoutineStep(id: "f1_1", type: .breathing, referenceId: "coherence", duration: 300, instructionKey: "routine.focus.step.coherence", icon: "heart.fill")
        ],
        impactDomains: ["Focus", "Serenity"]
    )

    static let focusIntermediate = Routine(
        id: "focus_2",
        category: .focus,
        difficulty: 2,
        nameKey: "routine.focus.2.name",
        descriptionKey: "routine.focus.2.description",
        totalDuration: 720, // 12 min
        steps: [
            RoutineStep(id: "f2_1", type: .breathing, referenceId: "coherence", duration: 300, instructionKey: "routine.focus.step.coherence", icon: "heart.fill"),
            RoutineStep(id: "f2_2", type: .meditation, referenceId: "focus-clarity", duration: 360, instructionKey: "routine.focus.step.meditation", icon: "target"),
            RoutineStep(id: "f2_3", type: .pause, referenceId: nil, duration: 60, instructionKey: "routine.focus.step.ready", icon: "checkmark.circle.fill")
        ],
        impactDomains: ["Focus", "Energy"]
    )

    static let focusAdvanced = Routine(
        id: "focus_3",
        category: .focus,
        difficulty: 3,
        nameKey: "routine.focus.3.name",
        descriptionKey: "routine.focus.3.description",
        totalDuration: 1200, // 20 min
        steps: [
            RoutineStep(id: "f3_1", type: .breathing, referenceId: "coherence", duration: 300, instructionKey: "routine.focus.step.coherence", icon: "heart.fill"),
            RoutineStep(id: "f3_2", type: .journaling, referenceId: nil, duration: 180, instructionKey: "routine.focus.step.goals", icon: "list.bullet.clipboard"),
            RoutineStep(id: "f3_3", type: .meditation, referenceId: "focus-clarity", duration: 480, instructionKey: "routine.focus.step.deepfocus", icon: "brain.head.profile"),
            RoutineStep(id: "f3_4", type: .sound, referenceId: "whitenoise", duration: 180, instructionKey: "routine.focus.step.whitenoise", icon: "waveform"),
            RoutineStep(id: "f3_5", type: .pause, referenceId: nil, duration: 60, instructionKey: "routine.focus.step.deepwork", icon: "target")
        ],
        impactDomains: ["Focus", "Energy", "Balance"]
    )

    // =====================================================
    // MARK: - ENERGY ROUTINES
    // =====================================================

    static let energyBeginner = Routine(
        id: "energy_1",
        category: .energy,
        difficulty: 1,
        nameKey: "routine.energy.1.name",
        descriptionKey: "routine.energy.1.description",
        totalDuration: 180, // 3 min
        steps: [
            RoutineStep(id: "e1_1", type: .breathing, referenceId: "triangle", duration: 120, instructionKey: "routine.energy.step.triangle", icon: "triangle"),
            RoutineStep(id: "e1_2", type: .pause, referenceId: nil, duration: 60, instructionKey: "routine.energy.step.ready", icon: "bolt.fill")
        ],
        impactDomains: ["Energy"]
    )

    static let energyIntermediate = Routine(
        id: "energy_2",
        category: .energy,
        difficulty: 2,
        nameKey: "routine.energy.2.name",
        descriptionKey: "routine.energy.2.description",
        totalDuration: 480, // 8 min
        steps: [
            RoutineStep(id: "e2_1", type: .breathing, referenceId: "kapalabhati", duration: 180, instructionKey: "routine.energy.step.kapalabhati", icon: "bolt.fill"),
            RoutineStep(id: "e2_2", type: .breathing, referenceId: "bhastrika", duration: 180, instructionKey: "routine.energy.step.bhastrika", icon: "flame.fill"),
            RoutineStep(id: "e2_3", type: .pause, referenceId: nil, duration: 120, instructionKey: "routine.energy.step.move", icon: "figure.walk")
        ],
        impactDomains: ["Energy", "Focus"]
    )

    static let energyAdvanced = Routine(
        id: "energy_3",
        category: .energy,
        difficulty: 3,
        nameKey: "routine.energy.3.name",
        descriptionKey: "routine.energy.3.description",
        totalDuration: 900, // 15 min
        steps: [
            RoutineStep(id: "e3_1", type: .breathing, referenceId: "kapalabhati", duration: 240, instructionKey: "routine.energy.step.kapalabhati", icon: "bolt.fill"),
            RoutineStep(id: "e3_2", type: .breathing, referenceId: "bhastrika", duration: 240, instructionKey: "routine.energy.step.bhastrika", icon: "flame.fill"),
            RoutineStep(id: "e3_3", type: .pause, referenceId: nil, duration: 120, instructionKey: "routine.energy.step.move", icon: "figure.walk"),
            RoutineStep(id: "e3_4", type: .meditation, referenceId: "visualization", duration: 240, instructionKey: "routine.energy.step.visualization", icon: "sparkles"),
            RoutineStep(id: "e3_5", type: .pause, referenceId: nil, duration: 60, instructionKey: "routine.energy.step.power", icon: "star.fill")
        ],
        impactDomains: ["Energy", "Focus", "Balance"]
    )

    // =====================================================
    // MARK: - STRESS ROUTINES
    // =====================================================

    static let stressBeginner = Routine(
        id: "stress_1",
        category: .stress,
        difficulty: 1,
        nameKey: "routine.stress.1.name",
        descriptionKey: "routine.stress.1.description",
        totalDuration: 300, // 5 min
        steps: [
            RoutineStep(id: "st1_1", type: .breathing, referenceId: "boxBreathing", duration: 240, instructionKey: "routine.stress.step.box", icon: "square"),
            RoutineStep(id: "st1_2", type: .pause, referenceId: nil, duration: 60, instructionKey: "routine.stress.step.calm", icon: "hand.raised.fill")
        ],
        impactDomains: ["Serenity"]
    )

    static let stressIntermediate = Routine(
        id: "stress_2",
        category: .stress,
        difficulty: 2,
        nameKey: "routine.stress.2.name",
        descriptionKey: "routine.stress.2.description",
        totalDuration: 600, // 10 min
        steps: [
            RoutineStep(id: "st2_1", type: .breathing, referenceId: "boxBreathing", duration: 240, instructionKey: "routine.stress.step.box", icon: "square"),
            RoutineStep(id: "st2_2", type: .meditation, referenceId: "grounding", duration: 300, instructionKey: "routine.stress.step.grounding", icon: "leaf.fill"),
            RoutineStep(id: "st2_3", type: .pause, referenceId: nil, duration: 60, instructionKey: "routine.stress.step.calm", icon: "hand.raised.fill")
        ],
        impactDomains: ["Serenity", "Balance"]
    )

    static let stressAdvanced = Routine(
        id: "stress_3",
        category: .stress,
        difficulty: 3,
        nameKey: "routine.stress.3.name",
        descriptionKey: "routine.stress.3.description",
        totalDuration: 900, // 15 min
        steps: [
            RoutineStep(id: "st3_1", type: .sound, referenceId: "rain", duration: 60, instructionKey: "routine.stress.step.sound", icon: "cloud.rain.fill"),
            RoutineStep(id: "st3_2", type: .breathing, referenceId: "coherence", duration: 300, instructionKey: "routine.stress.step.coherence", icon: "heart.fill"),
            RoutineStep(id: "st3_3", type: .meditation, referenceId: "grounding", duration: 240, instructionKey: "routine.stress.step.grounding", icon: "leaf.fill"),
            RoutineStep(id: "st3_4", type: .meditation, referenceId: "compassion", duration: 240, instructionKey: "routine.stress.step.compassion", icon: "heart.fill"),
            RoutineStep(id: "st3_5", type: .pause, referenceId: nil, duration: 60, instructionKey: "routine.stress.step.affirmation", icon: "sparkles")
        ],
        impactDomains: ["Serenity", "Balance", "Sleep"]
    )

    // =====================================================
    // MARK: - RELAXATION ROUTINES
    // =====================================================

    static let relaxationBeginner = Routine(
        id: "relaxation_1",
        category: .relaxation,
        difficulty: 1,
        nameKey: "routine.relaxation.1.name",
        descriptionKey: "routine.relaxation.1.description",
        totalDuration: 300, // 5 min
        steps: [
            RoutineStep(id: "r1_1", type: .breathing, referenceId: "slow66", duration: 240, instructionKey: "routine.relaxation.step.slow", icon: "wind"),
            RoutineStep(id: "r1_2", type: .pause, referenceId: nil, duration: 60, instructionKey: "routine.relaxation.step.savor", icon: "face.smiling")
        ],
        impactDomains: ["Serenity"]
    )

    static let relaxationIntermediate = Routine(
        id: "relaxation_2",
        category: .relaxation,
        difficulty: 2,
        nameKey: "routine.relaxation.2.name",
        descriptionKey: "routine.relaxation.2.description",
        totalDuration: 720, // 12 min
        steps: [
            RoutineStep(id: "r2_1", type: .sound, referenceId: "ocean", duration: 120, instructionKey: "routine.relaxation.step.ocean", icon: "water.waves"),
            RoutineStep(id: "r2_2", type: .breathing, referenceId: "slow66", duration: 300, instructionKey: "routine.relaxation.step.slow", icon: "wind"),
            RoutineStep(id: "r2_3", type: .meditation, referenceId: "body-scan", duration: 300, instructionKey: "routine.relaxation.step.bodyscan", icon: "figure.stand")
        ],
        impactDomains: ["Serenity", "Sleep"]
    )

    static let relaxationAdvanced = Routine(
        id: "relaxation_3",
        category: .relaxation,
        difficulty: 3,
        nameKey: "routine.relaxation.3.name",
        descriptionKey: "routine.relaxation.3.description",
        totalDuration: 1200, // 20 min
        steps: [
            RoutineStep(id: "r3_1", type: .sound, referenceId: "ocean", duration: 180, instructionKey: "routine.relaxation.step.ocean", icon: "water.waves"),
            RoutineStep(id: "r3_2", type: .breathing, referenceId: "fourSevenEight", duration: 300, instructionKey: "routine.relaxation.step.478", icon: "moon.fill"),
            RoutineStep(id: "r3_3", type: .meditation, referenceId: "body-scan", duration: 360, instructionKey: "routine.relaxation.step.bodyscan", icon: "figure.stand"),
            RoutineStep(id: "r3_4", type: .meditation, referenceId: "compassion", duration: 300, instructionKey: "routine.relaxation.step.compassion", icon: "heart.fill"),
            RoutineStep(id: "r3_5", type: .pause, referenceId: nil, duration: 60, instructionKey: "routine.relaxation.step.gratitude", icon: "sparkles")
        ],
        impactDomains: ["Serenity", "Sleep", "Balance"]
    )

    // MARK: - Helper Methods
    static func routine(for id: String) -> Routine? {
        return allRoutines.first { $0.id == id }
    }
}
