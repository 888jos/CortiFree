//
//  AntiStress.swift
//  CortiFree
//
//  Created by Claude on 22/10/2025.
//  Data models for Anti-Stress feature
//

import Foundation
import SwiftUI

// MARK: - Stress Situation

enum StressSituation: String, CaseIterable, Codable {
    case overwhelmed = "overwhelmed"
    case insomnia = "insomnia"
    case physicalTension = "physical_tension"
    case beforeEvent = "before_event"
    case anxiety = "anxiety"
    case needEnergy = "need_energy"

    var displayName: String {
        switch self {
        case .overwhelmed: return LanguageManager.shared.localizedString(for: "antistress.situation.overwhelmed")
        case .insomnia: return LanguageManager.shared.localizedString(for: "antistress.situation.insomnia")
        case .physicalTension: return LanguageManager.shared.localizedString(for: "antistress.situation.physical_tension")
        case .beforeEvent: return LanguageManager.shared.localizedString(for: "antistress.situation.before_event")
        case .anxiety: return LanguageManager.shared.localizedString(for: "antistress.situation.anxiety")
        case .needEnergy: return LanguageManager.shared.localizedString(for: "antistress.situation.need_energy")
        }
    }

    var icon: String {
        switch self {
        case .overwhelmed: return "water.waves"
        case .insomnia: return "moon.stars.fill"
        case .physicalTension: return "bolt.fill"
        case .beforeEvent: return "mic.fill"
        case .anxiety: return "heart.circle.fill"
        case .needEnergy: return "sun.max.fill"
        }
    }

    // Nouvelle propriété pour les images personnalisées
    var customImageName: String? {
        switch self {
        case .overwhelmed: return "situation_submerge"
        case .insomnia: return "situation_dormir"
        case .physicalTension: return "situation_tendu"
        case .beforeEvent: return "situation_stresse"
        case .anxiety: return "situation_anxiete"
        case .needEnergy: return "situation_energie"
        }
    }

    // Helper pour savoir si on doit utiliser l'image ou l'icône
    var hasCustomImage: Bool {
        return customImageName != nil
    }
}

// MARK: - Anti-Stress Exercise Type

enum AntiStressExerciseType: String, Codable {
    case guidedBreathing = "guided_breathing"
    case grounding5Senses = "grounding_5_senses"
    case consciousStretching = "conscious_stretching"
    case cardiacCoherence = "cardiac_coherence"
    case audioRelaxation = "audio_relaxation"
    case bodyScan = "body_scan"
    case boxBreathing = "box_breathing"
    case anchoring54321 = "anchoring_54321"
    case positiveMantra = "positive_mantra"
    case visualMicroBreak = "visual_micro_break"
    case alternateBreathing = "alternate_breathing"
    case slowWalk = "slow_walk"
    case consciousBreathing = "conscious_breathing"
    case meditation2Min = "meditation_2_min"
    case whiteNoise = "white_noise"

    var displayName: String {
        switch self {
        case .guidedBreathing: return LanguageManager.shared.localizedString(for: "antistress.exercise.guided_breathing")
        case .grounding5Senses: return LanguageManager.shared.localizedString(for: "antistress.exercise.grounding_5_senses")
        case .consciousStretching: return LanguageManager.shared.localizedString(for: "antistress.exercise.conscious_stretching")
        case .cardiacCoherence: return LanguageManager.shared.localizedString(for: "antistress.exercise.cardiac_coherence")
        case .audioRelaxation: return LanguageManager.shared.localizedString(for: "antistress.exercise.audio_relaxation")
        case .bodyScan: return LanguageManager.shared.localizedString(for: "antistress.exercise.body_scan")
        case .boxBreathing: return LanguageManager.shared.localizedString(for: "antistress.exercise.box_breathing")
        case .anchoring54321: return LanguageManager.shared.localizedString(for: "antistress.exercise.anchoring_54321")
        case .positiveMantra: return LanguageManager.shared.localizedString(for: "antistress.exercise.positive_mantra")
        case .visualMicroBreak: return LanguageManager.shared.localizedString(for: "antistress.exercise.visual_micro_break")
        case .alternateBreathing: return LanguageManager.shared.localizedString(for: "antistress.exercise.alternate_breathing")
        case .slowWalk: return LanguageManager.shared.localizedString(for: "antistress.exercise.slow_walk")
        case .consciousBreathing: return LanguageManager.shared.localizedString(for: "antistress.exercise.conscious_breathing")
        case .meditation2Min: return LanguageManager.shared.localizedString(for: "antistress.exercise.meditation_2_min")
        case .whiteNoise: return LanguageManager.shared.localizedString(for: "antistress.exercise.white_noise")
        }
    }

    var description: String {
        switch self {
        case .guidedBreathing: return LanguageManager.shared.localizedString(for: "antistress.exercise.guided_breathing.desc")
        case .grounding5Senses: return LanguageManager.shared.localizedString(for: "antistress.exercise.grounding_5_senses.desc")
        case .consciousStretching: return LanguageManager.shared.localizedString(for: "antistress.exercise.conscious_stretching.desc")
        case .cardiacCoherence: return LanguageManager.shared.localizedString(for: "antistress.exercise.cardiac_coherence.desc")
        case .audioRelaxation: return LanguageManager.shared.localizedString(for: "antistress.exercise.audio_relaxation.desc")
        case .bodyScan: return LanguageManager.shared.localizedString(for: "antistress.exercise.body_scan.desc")
        case .boxBreathing: return LanguageManager.shared.localizedString(for: "antistress.exercise.box_breathing.desc")
        case .anchoring54321: return LanguageManager.shared.localizedString(for: "antistress.exercise.anchoring_54321.desc")
        case .positiveMantra: return LanguageManager.shared.localizedString(for: "antistress.exercise.positive_mantra.desc")
        case .visualMicroBreak: return LanguageManager.shared.localizedString(for: "antistress.exercise.visual_micro_break.desc")
        case .alternateBreathing: return LanguageManager.shared.localizedString(for: "antistress.exercise.alternate_breathing.desc")
        case .slowWalk: return LanguageManager.shared.localizedString(for: "antistress.exercise.slow_walk.desc")
        case .consciousBreathing: return LanguageManager.shared.localizedString(for: "antistress.exercise.conscious_breathing.desc")
        case .meditation2Min: return LanguageManager.shared.localizedString(for: "antistress.exercise.meditation_2_min.desc")
        case .whiteNoise: return LanguageManager.shared.localizedString(for: "antistress.exercise.white_noise.desc")
        }
    }

    var duration: Int {
        switch self {
        case .guidedBreathing, .grounding5Senses, .consciousStretching: return 180
        case .cardiacCoherence, .boxBreathing, .anchoring54321: return 300
        case .audioRelaxation, .bodyScan: return 420
        case .positiveMantra, .visualMicroBreak: return 120
        case .alternateBreathing, .consciousBreathing: return 240
        case .slowWalk: return 360
        case .meditation2Min: return 120
        case .whiteNoise: return 600
        }
    }

    var icon: String {
        switch self {
        case .guidedBreathing: return "wind"
        case .grounding5Senses: return "hand.raised.fill"
        case .consciousStretching: return "figure.flexibility"
        case .cardiacCoherence: return "heart.circle.fill"
        case .audioRelaxation: return "speaker.wave.3.fill"
        case .bodyScan: return "figure.stand"
        case .boxBreathing: return "square.on.square"
        case .anchoring54321: return "123.rectangle.fill"
        case .positiveMantra: return "text.quote"
        case .visualMicroBreak: return "eye.fill"
        case .alternateBreathing: return "arrow.left.arrow.right"
        case .slowWalk: return "figure.walk"
        case .consciousBreathing: return "lungs.fill"
        case .meditation2Min: return "sparkles"
        case .whiteNoise: return "waveform"
        }
    }

    var completionEmoji: String {
        switch self {
        case .guidedBreathing: return "🌬️"
        case .grounding5Senses: return "🖐️"
        case .consciousStretching: return "🤸"
        case .cardiacCoherence: return "💓"
        case .audioRelaxation: return "🎧"
        case .bodyScan: return "🧘"
        case .boxBreathing: return "📦"
        case .anchoring54321: return "🔢"
        case .positiveMantra: return "✨"
        case .visualMicroBreak: return "👁️"
        case .alternateBreathing: return "🔄"
        case .slowWalk: return "🚶"
        case .consciousBreathing: return "🫁"
        case .meditation2Min: return "🧘‍♂️"
        case .whiteNoise: return "🎵"
        }
    }
}

// MARK: - Exercise Recommendation

struct ExerciseRecommendation: Identifiable {
    let id = UUID()
    let exerciseType: AntiStressExerciseType
    let matchPercentage: Int

    var displayName: String { exerciseType.displayName }
    var description: String { exerciseType.description }
    var duration: Int { exerciseType.duration }
}

// MARK: - Recommendation Engine

class AntiStressRecommendationEngine {
    static func recommendations(for situation: StressSituation) -> [ExerciseRecommendation] {
        switch situation {
        case .overwhelmed:
            return [
                ExerciseRecommendation(exerciseType: .guidedBreathing, matchPercentage: 92),
                ExerciseRecommendation(exerciseType: .grounding5Senses, matchPercentage: 84),
                ExerciseRecommendation(exerciseType: .consciousStretching, matchPercentage: 73),
                ExerciseRecommendation(exerciseType: .bodyScan, matchPercentage: 68),
                ExerciseRecommendation(exerciseType: .cardiacCoherence, matchPercentage: 65),
                ExerciseRecommendation(exerciseType: .slowWalk, matchPercentage: 60)
            ]

        case .insomnia:
            return [
                ExerciseRecommendation(exerciseType: .cardiacCoherence, matchPercentage: 88),
                ExerciseRecommendation(exerciseType: .audioRelaxation, matchPercentage: 81),
                ExerciseRecommendation(exerciseType: .bodyScan, matchPercentage: 70),
                ExerciseRecommendation(exerciseType: .whiteNoise, matchPercentage: 67),
                ExerciseRecommendation(exerciseType: .meditation2Min, matchPercentage: 62),
                ExerciseRecommendation(exerciseType: .consciousBreathing, matchPercentage: 58)
            ]

        case .physicalTension:
            return [
                ExerciseRecommendation(exerciseType: .consciousStretching, matchPercentage: 90),
                ExerciseRecommendation(exerciseType: .bodyScan, matchPercentage: 82),
                ExerciseRecommendation(exerciseType: .boxBreathing, matchPercentage: 75),
                ExerciseRecommendation(exerciseType: .slowWalk, matchPercentage: 69),
                ExerciseRecommendation(exerciseType: .guidedBreathing, matchPercentage: 64),
                ExerciseRecommendation(exerciseType: .audioRelaxation, matchPercentage: 59)
            ]

        case .beforeEvent:
            return [
                ExerciseRecommendation(exerciseType: .boxBreathing, matchPercentage: 93),
                ExerciseRecommendation(exerciseType: .anchoring54321, matchPercentage: 85),
                ExerciseRecommendation(exerciseType: .positiveMantra, matchPercentage: 79),
                ExerciseRecommendation(exerciseType: .cardiacCoherence, matchPercentage: 72),
                ExerciseRecommendation(exerciseType: .consciousBreathing, matchPercentage: 66),
                ExerciseRecommendation(exerciseType: .visualMicroBreak, matchPercentage: 61)
            ]

        case .anxiety:
            return [
                ExerciseRecommendation(exerciseType: .cardiacCoherence, matchPercentage: 94),
                ExerciseRecommendation(exerciseType: .guidedBreathing, matchPercentage: 87),
                ExerciseRecommendation(exerciseType: .grounding5Senses, matchPercentage: 80),
                ExerciseRecommendation(exerciseType: .boxBreathing, matchPercentage: 74),
                ExerciseRecommendation(exerciseType: .anchoring54321, matchPercentage: 69),
                ExerciseRecommendation(exerciseType: .bodyScan, matchPercentage: 64)
            ]

        case .needEnergy:
            return [
                ExerciseRecommendation(exerciseType: .alternateBreathing, matchPercentage: 92),
                ExerciseRecommendation(exerciseType: .consciousStretching, matchPercentage: 85),
                ExerciseRecommendation(exerciseType: .slowWalk, matchPercentage: 76),
                ExerciseRecommendation(exerciseType: .boxBreathing, matchPercentage: 71),
                ExerciseRecommendation(exerciseType: .visualMicroBreak, matchPercentage: 66),
                ExerciseRecommendation(exerciseType: .consciousBreathing, matchPercentage: 60)
            ]
        }
    }
}

// MARK: - AntiStressExerciseType Extension for Localized Content

extension AntiStressExerciseType {
    var detailedDescription: String {
        switch self {
        case .slowWalk:
            return LanguageManager.shared.localizedString(for: "antistress.slow_walk.detailed_description")
        case .consciousStretching:
            return LanguageManager.shared.localizedString(for: "antistress.conscious_stretching.detailed_description")
        case .audioRelaxation:
            return LanguageManager.shared.localizedString(for: "antistress.audio_relaxation.detailed_description")
        case .whiteNoise:
            return LanguageManager.shared.localizedString(for: "antistress.white_noise.detailed_description")
        case .positiveMantra:
            return LanguageManager.shared.localizedString(for: "antistress.positive_mantra.detailed_description")
        case .visualMicroBreak:
            return LanguageManager.shared.localizedString(for: "antistress.visual_micro_break.detailed_description")
        default:
            return LanguageManager.shared.localizedString(for: "antistress.default.detailed_description")
        }
    }

    var benefits: [String] {
        switch self {
        case .slowWalk:
            return [
                LanguageManager.shared.localizedString(for: "antistress.slow_walk.benefit_1"),
                LanguageManager.shared.localizedString(for: "antistress.slow_walk.benefit_2"),
                LanguageManager.shared.localizedString(for: "antistress.slow_walk.benefit_3"),
                LanguageManager.shared.localizedString(for: "antistress.slow_walk.benefit_4")
            ]
        case .consciousStretching:
            return [
                LanguageManager.shared.localizedString(for: "antistress.conscious_stretching.benefit_1"),
                LanguageManager.shared.localizedString(for: "antistress.conscious_stretching.benefit_2"),
                LanguageManager.shared.localizedString(for: "antistress.conscious_stretching.benefit_3"),
                LanguageManager.shared.localizedString(for: "antistress.conscious_stretching.benefit_4")
            ]
        case .audioRelaxation:
            return [
                LanguageManager.shared.localizedString(for: "antistress.audio_relaxation.benefit_1"),
                LanguageManager.shared.localizedString(for: "antistress.audio_relaxation.benefit_2"),
                LanguageManager.shared.localizedString(for: "antistress.audio_relaxation.benefit_3"),
                LanguageManager.shared.localizedString(for: "antistress.audio_relaxation.benefit_4")
            ]
        case .whiteNoise:
            return [
                LanguageManager.shared.localizedString(for: "antistress.white_noise.benefit_1"),
                LanguageManager.shared.localizedString(for: "antistress.white_noise.benefit_2"),
                LanguageManager.shared.localizedString(for: "antistress.white_noise.benefit_3"),
                LanguageManager.shared.localizedString(for: "antistress.white_noise.benefit_4")
            ]
        case .positiveMantra:
            return [
                LanguageManager.shared.localizedString(for: "antistress.positive_mantra.benefit_1"),
                LanguageManager.shared.localizedString(for: "antistress.positive_mantra.benefit_2"),
                LanguageManager.shared.localizedString(for: "antistress.positive_mantra.benefit_3"),
                LanguageManager.shared.localizedString(for: "antistress.positive_mantra.benefit_4")
            ]
        case .visualMicroBreak:
            return [
                LanguageManager.shared.localizedString(for: "antistress.visual_micro_break.benefit_1"),
                LanguageManager.shared.localizedString(for: "antistress.visual_micro_break.benefit_2"),
                LanguageManager.shared.localizedString(for: "antistress.visual_micro_break.benefit_3"),
                LanguageManager.shared.localizedString(for: "antistress.visual_micro_break.benefit_4")
            ]
        default:
            return []
        }
    }

    var scientificEvidence: [String] {
        switch self {
        case .slowWalk:
            return [
                LanguageManager.shared.localizedString(for: "antistress.slow_walk.evidence_1"),
                LanguageManager.shared.localizedString(for: "antistress.slow_walk.evidence_2"),
                LanguageManager.shared.localizedString(for: "antistress.slow_walk.evidence_3")
            ]
        case .consciousStretching:
            return [
                LanguageManager.shared.localizedString(for: "antistress.conscious_stretching.evidence_1"),
                LanguageManager.shared.localizedString(for: "antistress.conscious_stretching.evidence_2"),
                LanguageManager.shared.localizedString(for: "antistress.conscious_stretching.evidence_3")
            ]
        case .audioRelaxation:
            return [
                LanguageManager.shared.localizedString(for: "antistress.audio_relaxation.evidence_1"),
                LanguageManager.shared.localizedString(for: "antistress.audio_relaxation.evidence_2"),
                LanguageManager.shared.localizedString(for: "antistress.audio_relaxation.evidence_3")
            ]
        case .whiteNoise:
            return [
                LanguageManager.shared.localizedString(for: "antistress.white_noise.evidence_1"),
                LanguageManager.shared.localizedString(for: "antistress.white_noise.evidence_2"),
                LanguageManager.shared.localizedString(for: "antistress.white_noise.evidence_3")
            ]
        case .positiveMantra:
            return [
                LanguageManager.shared.localizedString(for: "antistress.positive_mantra.evidence_1"),
                LanguageManager.shared.localizedString(for: "antistress.positive_mantra.evidence_2"),
                LanguageManager.shared.localizedString(for: "antistress.positive_mantra.evidence_3")
            ]
        case .visualMicroBreak:
            return [
                LanguageManager.shared.localizedString(for: "antistress.visual_micro_break.evidence_1"),
                LanguageManager.shared.localizedString(for: "antistress.visual_micro_break.evidence_2"),
                LanguageManager.shared.localizedString(for: "antistress.visual_micro_break.evidence_3")
            ]
        default:
            return [LanguageManager.shared.localizedString(for: "antistress.default.evidence")]
        }
    }

    var scientificSources: [String] {
        switch self {
        case .slowWalk:
            return [LanguageManager.shared.localizedString(for: "antistress.slow_walk.source")]
        case .consciousStretching:
            return [LanguageManager.shared.localizedString(for: "antistress.conscious_stretching.source")]
        case .audioRelaxation:
            return [LanguageManager.shared.localizedString(for: "antistress.audio_relaxation.source")]
        case .whiteNoise:
            return [LanguageManager.shared.localizedString(for: "antistress.white_noise.source")]
        case .positiveMantra:
            return [LanguageManager.shared.localizedString(for: "antistress.positive_mantra.source")]
        case .visualMicroBreak:
            return [LanguageManager.shared.localizedString(for: "antistress.visual_micro_break.source")]
        case .bodyScan:
            return [LanguageManager.shared.localizedString(for: "antistress.body_scan.source")]
        case .grounding5Senses:
            return [LanguageManager.shared.localizedString(for: "antistress.grounding_5_senses.source")]
        case .anchoring54321:
            return [LanguageManager.shared.localizedString(for: "antistress.anchoring_54321.source")]
        default:
            return [LanguageManager.shared.localizedString(for: "antistress.default.source")]
        }
    }

    // Keep for backward compatibility
    var scientificSource: String {
        return scientificSources.first ?? ""
    }

    // Header gradient color based on exercise type
    var headerGradientColor: Color {
        switch self {
        case .guidedBreathing, .boxBreathing, .consciousBreathing, .alternateBreathing, .cardiacCoherence:
            return Color(hex: "3B5998") // Blue for breathing exercises
        case .meditation2Min:
            return Color(hex: "49288C") // Violet for meditation
        default:
            return Color(hex: "49288C") // Violet for all other exercises (grounding, etc.)
        }
    }
}

// MARK: - Exercise Completion

struct ExerciseCompletion: Codable {
    let exerciseType: AntiStressExerciseType
    let situation: StressSituation
    let completedAt: Timestamp
    let duration: Int
}

// MARK: - Breathing Pattern Mapping

extension AntiStressExerciseType {
    /// Maps AntiStressExerciseType to BreathingPattern for unified breathing view
    var breathingPattern: BreathingPattern? {
        switch self {
        case .guidedBreathing, .consciousBreathing:
            return .deepAbdominal  // 4-2-6
        case .cardiacCoherence:
            return .coherence      // 5-0-5
        case .boxBreathing:
            return .boxBreathing   // 4-4-4-4
        case .alternateBreathing:
            return .alternateNostril // nadi shodhana (4-7-8 is a sleep pattern)
        default:
            return nil // Non-breathing exercises
        }
    }

    /// Returns true if this exercise type is a breathing exercise
    var isBreathingExercise: Bool {
        return breathingPattern != nil
    }
}
