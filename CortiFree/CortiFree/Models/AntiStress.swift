//
//  AntiStress.swift
//  CortiFree
//
//  Created by Claude on 22/10/2025.
//  Data models for Anti-Stress feature
//

import Foundation
import SwiftUI
import FirebaseFirestore

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
        case .overwhelmed: return NSLocalizedString("antistress.situation.overwhelmed", comment: "")
        case .insomnia: return NSLocalizedString("antistress.situation.insomnia", comment: "")
        case .physicalTension: return NSLocalizedString("antistress.situation.physical_tension", comment: "")
        case .beforeEvent: return NSLocalizedString("antistress.situation.before_event", comment: "")
        case .anxiety: return NSLocalizedString("antistress.situation.anxiety", comment: "")
        case .needEnergy: return NSLocalizedString("antistress.situation.need_energy", comment: "")
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
        case .guidedBreathing: return NSLocalizedString("antistress.exercise.guided_breathing", comment: "")
        case .grounding5Senses: return NSLocalizedString("antistress.exercise.grounding_5_senses", comment: "")
        case .consciousStretching: return NSLocalizedString("antistress.exercise.conscious_stretching", comment: "")
        case .cardiacCoherence: return NSLocalizedString("antistress.exercise.cardiac_coherence", comment: "")
        case .audioRelaxation: return NSLocalizedString("antistress.exercise.audio_relaxation", comment: "")
        case .bodyScan: return NSLocalizedString("antistress.exercise.body_scan", comment: "")
        case .boxBreathing: return NSLocalizedString("antistress.exercise.box_breathing", comment: "")
        case .anchoring54321: return NSLocalizedString("antistress.exercise.anchoring_54321", comment: "")
        case .positiveMantra: return NSLocalizedString("antistress.exercise.positive_mantra", comment: "")
        case .visualMicroBreak: return NSLocalizedString("antistress.exercise.visual_micro_break", comment: "")
        case .alternateBreathing: return NSLocalizedString("antistress.exercise.alternate_breathing", comment: "")
        case .slowWalk: return NSLocalizedString("antistress.exercise.slow_walk", comment: "")
        case .consciousBreathing: return NSLocalizedString("antistress.exercise.conscious_breathing", comment: "")
        case .meditation2Min: return NSLocalizedString("antistress.exercise.meditation_2_min", comment: "")
        case .whiteNoise: return NSLocalizedString("antistress.exercise.white_noise", comment: "")
        }
    }

    var description: String {
        switch self {
        case .guidedBreathing: return "Ralentis ton rythme cardiaque"
        case .grounding5Senses: return "Reconnecte avec le moment présent"
        case .consciousStretching: return "Relâche les tensions physiques"
        case .cardiacCoherence: return "Équilibre ton système nerveux"
        case .audioRelaxation: return "Laisse-toi guider par le son"
        case .bodyScan: return "Détends chaque partie de ton corps"
        case .boxBreathing: return "Technique de respiration militaire"
        case .anchoring54321: return "Ramène-toi dans l'instant présent"
        case .positiveMantra: return "Renforce ta confiance intérieure"
        case .visualMicroBreak: return "Repose tes yeux et ton esprit"
        case .alternateBreathing: return "Équilibre tes deux hémisphères"
        case .slowWalk: return "Marche en pleine conscience"
        case .consciousBreathing: return "Retrouve ton calme naturel"
        case .meditation2Min: return "Courte méditation guidée"
        case .whiteNoise: return "Sons apaisants pour te détendre"
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

    var xpReward: Int {
        return 5
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
            return NSLocalizedString("antistress.slow_walk.detailed_description", comment: "")
        case .consciousStretching:
            return NSLocalizedString("antistress.conscious_stretching.detailed_description", comment: "")
        case .audioRelaxation:
            return NSLocalizedString("antistress.audio_relaxation.detailed_description", comment: "")
        case .whiteNoise:
            return NSLocalizedString("antistress.white_noise.detailed_description", comment: "")
        case .positiveMantra:
            return NSLocalizedString("antistress.positive_mantra.detailed_description", comment: "")
        case .visualMicroBreak:
            return NSLocalizedString("antistress.visual_micro_break.detailed_description", comment: "")
        default:
            return NSLocalizedString("antistress.default.detailed_description", comment: "")
        }
    }

    var benefits: [String] {
        switch self {
        case .slowWalk:
            return [
                NSLocalizedString("antistress.slow_walk.benefit_1", comment: ""),
                NSLocalizedString("antistress.slow_walk.benefit_2", comment: ""),
                NSLocalizedString("antistress.slow_walk.benefit_3", comment: ""),
                NSLocalizedString("antistress.slow_walk.benefit_4", comment: "")
            ]
        case .consciousStretching:
            return [
                NSLocalizedString("antistress.conscious_stretching.benefit_1", comment: ""),
                NSLocalizedString("antistress.conscious_stretching.benefit_2", comment: ""),
                NSLocalizedString("antistress.conscious_stretching.benefit_3", comment: ""),
                NSLocalizedString("antistress.conscious_stretching.benefit_4", comment: "")
            ]
        case .audioRelaxation:
            return [
                NSLocalizedString("antistress.audio_relaxation.benefit_1", comment: ""),
                NSLocalizedString("antistress.audio_relaxation.benefit_2", comment: ""),
                NSLocalizedString("antistress.audio_relaxation.benefit_3", comment: ""),
                NSLocalizedString("antistress.audio_relaxation.benefit_4", comment: "")
            ]
        case .whiteNoise:
            return [
                NSLocalizedString("antistress.white_noise.benefit_1", comment: ""),
                NSLocalizedString("antistress.white_noise.benefit_2", comment: ""),
                NSLocalizedString("antistress.white_noise.benefit_3", comment: ""),
                NSLocalizedString("antistress.white_noise.benefit_4", comment: "")
            ]
        case .positiveMantra:
            return [
                NSLocalizedString("antistress.positive_mantra.benefit_1", comment: ""),
                NSLocalizedString("antistress.positive_mantra.benefit_2", comment: ""),
                NSLocalizedString("antistress.positive_mantra.benefit_3", comment: ""),
                NSLocalizedString("antistress.positive_mantra.benefit_4", comment: "")
            ]
        case .visualMicroBreak:
            return [
                NSLocalizedString("antistress.visual_micro_break.benefit_1", comment: ""),
                NSLocalizedString("antistress.visual_micro_break.benefit_2", comment: ""),
                NSLocalizedString("antistress.visual_micro_break.benefit_3", comment: ""),
                NSLocalizedString("antistress.visual_micro_break.benefit_4", comment: "")
            ]
        default:
            return []
        }
    }

    var scientificEvidence: [String] {
        switch self {
        case .slowWalk:
            return [
                NSLocalizedString("antistress.slow_walk.evidence_1", comment: ""),
                NSLocalizedString("antistress.slow_walk.evidence_2", comment: ""),
                NSLocalizedString("antistress.slow_walk.evidence_3", comment: "")
            ]
        case .consciousStretching:
            return [
                NSLocalizedString("antistress.conscious_stretching.evidence_1", comment: ""),
                NSLocalizedString("antistress.conscious_stretching.evidence_2", comment: ""),
                NSLocalizedString("antistress.conscious_stretching.evidence_3", comment: "")
            ]
        case .audioRelaxation:
            return [
                NSLocalizedString("antistress.audio_relaxation.evidence_1", comment: ""),
                NSLocalizedString("antistress.audio_relaxation.evidence_2", comment: ""),
                NSLocalizedString("antistress.audio_relaxation.evidence_3", comment: "")
            ]
        case .whiteNoise:
            return [
                NSLocalizedString("antistress.white_noise.evidence_1", comment: ""),
                NSLocalizedString("antistress.white_noise.evidence_2", comment: ""),
                NSLocalizedString("antistress.white_noise.evidence_3", comment: "")
            ]
        case .positiveMantra:
            return [
                NSLocalizedString("antistress.positive_mantra.evidence_1", comment: ""),
                NSLocalizedString("antistress.positive_mantra.evidence_2", comment: ""),
                NSLocalizedString("antistress.positive_mantra.evidence_3", comment: "")
            ]
        case .visualMicroBreak:
            return [
                NSLocalizedString("antistress.visual_micro_break.evidence_1", comment: ""),
                NSLocalizedString("antistress.visual_micro_break.evidence_2", comment: ""),
                NSLocalizedString("antistress.visual_micro_break.evidence_3", comment: "")
            ]
        default:
            return [NSLocalizedString("antistress.default.evidence", comment: "")]
        }
    }

    var scientificSource: String {
        switch self {
        case .slowWalk: return NSLocalizedString("antistress.slow_walk.source", comment: "")
        case .consciousStretching: return NSLocalizedString("antistress.conscious_stretching.source", comment: "")
        case .audioRelaxation: return NSLocalizedString("antistress.audio_relaxation.source", comment: "")
        case .whiteNoise: return NSLocalizedString("antistress.white_noise.source", comment: "")
        case .positiveMantra: return NSLocalizedString("antistress.positive_mantra.source", comment: "")
        case .visualMicroBreak: return NSLocalizedString("antistress.visual_micro_break.source", comment: "")
        default: return NSLocalizedString("antistress.default.source", comment: "")
        }
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
    let xpEarned: Int
}
