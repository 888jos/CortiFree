//
//  AntiStressArtwork.swift
//  CortiFree
//
//  How each anti-stress exercise is shown and launched with the app's current players:
//  breathing exercises open the breathing session (BreathingDetailFlowView, as in the
//  Library and the Plan); the others play the matching guided session from the Library.
//  Illustrations come from those same sources so the three places look the same.
//

import SwiftUI

extension AntiStressExerciseType {

    enum Kind: String {
        case breathing, meditation, movement, grounding, sound

        var localizedName: String { "antistress.kind.\(rawValue)".localized }

        var symbol: String {
            switch self {
            case .breathing: return "wind"
            case .meditation: return "figure.mind.and.body"
            case .movement: return "figure.walk"
            case .grounding: return "hand.raised.fill"
            case .sound: return "waveform"
            }
        }
    }

    var kind: Kind {
        switch self {
        case .guidedBreathing, .consciousBreathing, .cardiacCoherence, .boxBreathing, .alternateBreathing:
            return .breathing
        case .bodyScan, .audioRelaxation, .positiveMantra, .visualMicroBreak, .meditation2Min:
            return .meditation
        case .consciousStretching, .slowWalk:
            return .movement
        case .grounding5Senses, .anchoring54321:
            return .grounding
        case .whiteNoise:
            return .sound
        }
    }

    /// Guided session (Library catalogue) played for non-breathing exercises.
    var guidedSessionID: String? {
        switch self {
        case .grounding5Senses: return "anxiety-grounding-54321-6"
        case .anchoring54321: return "sos-panic-anchor-4"
        case .bodyScan: return "body-quick-scan-3"
        case .consciousStretching: return "morning-stretch-8"
        case .slowWalk: return "morning-walk-10"
        case .audioRelaxation: return "body-pmr-8"
        case .positiveMantra: return "compassion-kind-pause-5"
        case .visualMicroBreak: return "focus-visual-anchor-6"
        case .meditation2Min: return "sos-reset-3"
        case .whiteNoise: return "focus-sound-anchor-8"
        default: return nil
        }
    }

    var guidedSession: GuidedSession? {
        guidedSessionID.flatMap { GuidedSessionCatalog.session(id: $0) }
    }

    var artworkImage: String {
        if let pattern = breathingPattern {
            return PlanArtwork.breathingImage(pattern.category)
        }
        if let session = guidedSession {
            return session.artwork.imageName ?? PlanArtwork.sessionImage(session.category)
        }
        return "meditation_04"
    }

    /// Real length of what is launched: the breathing default or the guided session's length.
    var minutes: Int {
        if let pattern = breathingPattern { return pattern.defaultMinutes }
        if let session = guidedSession { return session.durationMinutes }
        return max(1, duration / 60)
    }

    /// "3 min"
    var durationLabel: String { "\(minutes) min" }
}
