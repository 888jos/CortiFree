//
//  AntiStress.swift
//  CortiFree
//
//  Created by Claude on 22/10/2025.
//  Data models for Anti-Stress feature
//

import Foundation
import FirebaseFirestore

// MARK: - Stress Situation

enum StressSituation: String, CaseIterable, Codable {
    case overwhelmed = "overwhelmed"
    case insomnia = "insomnia"
    case physicalTension = "physical_tension"
    case beforeEvent = "before_event"
    case mentallyExhausted = "mentally_exhausted"
    case wantToCenter = "want_to_center"
    case anxiety = "anxiety"
    case needEnergy = "need_energy"

    var displayName: String {
        switch self {
        case .overwhelmed: return "Je me sens submergé"
        case .insomnia: return "Je n'arrive pas à dormir"
        case .physicalTension: return "Je suis tendu physiquement"
        case .beforeEvent: return "Je stresse avant un événement"
        case .mentallyExhausted: return "Je suis épuisé mentalement"
        case .wantToCenter: return "Je veux juste me recentrer"
        case .anxiety: return "J'ai de l'anxiété"
        case .needEnergy: return "J'ai besoin d'énergie"
        }
    }

    var icon: String {
        switch self {
        case .overwhelmed: return "water.waves"
        case .insomnia: return "moon.stars.fill"
        case .physicalTension: return "bolt.fill"
        case .beforeEvent: return "mic.fill"
        case .mentallyExhausted: return "cloud.fill"
        case .wantToCenter: return "leaf.fill"
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
        case .mentallyExhausted: return "situation_epuise"
        case .wantToCenter: return "situation_recentrer"
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
        case .guidedBreathing: return "Respiration guidée"
        case .grounding5Senses: return "Grounding 5 sens"
        case .consciousStretching: return "Étirement conscient"
        case .cardiacCoherence: return "Cohérence cardiaque"
        case .audioRelaxation: return "Relaxation auditive"
        case .bodyScan: return "Scan corporel"
        case .boxBreathing: return "Respiration carrée"
        case .anchoring54321: return "Ancrage 5-4-3-2-1"
        case .positiveMantra: return "Mantra positif"
        case .visualMicroBreak: return "Micro-pause visuelle"
        case .alternateBreathing: return "Respiration alternée"
        case .slowWalk: return "Marche lente"
        case .consciousBreathing: return "Respiration consciente"
        case .meditation2Min: return "Méditation 2 min"
        case .whiteNoise: return "Bruit blanc apaisant"
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

        case .mentallyExhausted:
            return [
                ExerciseRecommendation(exerciseType: .visualMicroBreak, matchPercentage: 91),
                ExerciseRecommendation(exerciseType: .alternateBreathing, matchPercentage: 83),
                ExerciseRecommendation(exerciseType: .slowWalk, matchPercentage: 72),
                ExerciseRecommendation(exerciseType: .whiteNoise, matchPercentage: 68),
                ExerciseRecommendation(exerciseType: .bodyScan, matchPercentage: 63),
                ExerciseRecommendation(exerciseType: .meditation2Min, matchPercentage: 57)
            ]

        case .wantToCenter:
            return [
                ExerciseRecommendation(exerciseType: .consciousBreathing, matchPercentage: 95),
                ExerciseRecommendation(exerciseType: .meditation2Min, matchPercentage: 88),
                ExerciseRecommendation(exerciseType: .whiteNoise, matchPercentage: 80),
                ExerciseRecommendation(exerciseType: .cardiacCoherence, matchPercentage: 75),
                ExerciseRecommendation(exerciseType: .bodyScan, matchPercentage: 70),
                ExerciseRecommendation(exerciseType: .alternateBreathing, matchPercentage: 65)
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

// MARK: - Exercise Completion

struct ExerciseCompletion: Codable {
    let exerciseType: AntiStressExerciseType
    let situation: StressSituation
    let completedAt: Timestamp
    let duration: Int
    let xpEarned: Int
}
