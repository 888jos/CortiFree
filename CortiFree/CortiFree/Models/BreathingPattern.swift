//
//  BreathingPattern.swift
//  CortiFree
//
//  Created by Claude on 22/10/2025.
//  Data model for breathing exercise patterns
//

import Foundation
import SwiftUI

// MARK: - Breathing Category

enum BreathingCategory: String, CaseIterable, Identifiable {
    case calm
    case sleep
    case focus
    case energy
    case sos

    var id: String { rawValue }

    var localizedTitle: String {
        LanguageManager.shared.localizedString(for: "breathing.category.\(rawValue)")
    }

    var symbol: String {
        switch self {
        case .calm: return "leaf.fill"
        case .sleep: return "moon.stars.fill"
        case .focus: return "scope"
        case .energy: return "sun.max.fill"
        case .sos: return "lifepreserver.fill"
        }
    }

    var color: Color {
        switch self {
        case .calm: return Color(hex: "8FE3C3")
        case .sleep: return Color(hex: "9D8CFF")
        case .focus: return Color(hex: "7FD1FF")
        case .energy: return Color(hex: "FFD36B")
        case .sos: return Color(hex: "FF9AA2")
        }
    }
}

// MARK: - Breathing Step (one segment of a cycle)

enum BreathingStepKind: String {
    case inhale        // rising
    case inhaleTopUp   // second short inhale (physiological sigh)
    case hold          // full lungs, flat top
    case exhale        // descending
    case holdOut       // empty lungs, flat bottom
}

struct BreathingStep: Equatable {
    let kind: BreathingStepKind
    let duration: Double
    /// Lung level (0 = empty, 1 = full) at the start / end of this step.
    let fromLevel: Double
    let toLevel: Double
    /// Localization key of the label shown during this step.
    let labelKey: String

    var localizedLabel: String {
        LanguageManager.shared.localizedString(for: labelKey)
    }
}

// MARK: - Breathing Pattern

struct BreathingPattern: Identifiable, Equatable {
    static func == (lhs: BreathingPattern, rhs: BreathingPattern) -> Bool {
        lhs.name == rhs.name
    }

    let id = UUID()
    let name: String
    let displayName: String
    let inhaleDuration: Double
    let holdDuration: Double
    let exhaleDuration: Double
    let holdOutDuration: Double // Pour box breathing (4 phases)
    let description: String

    // MARK: Catalogue metadata (added — all have defaults for source compatibility)

    /// Stable identifier used for localization keys (`breathing.ex.<key>.*`).
    let key: String
    /// Second, short inhale on top of the first one (physiological sigh). 0 = none.
    let secondInhaleDuration: Double
    let category: BreathingCategory
    let accentHex: String
    let symbol: String
    let defaultMinutes: Int
    let durationChoices: [Int]
    /// Optional custom label for the exhale (e.g. "Hum").
    let exhaleLabelKey: String?
    /// Alternate nostril guidance (left / right switch every cycle).
    let isAlternateNostril: Bool

    var totalCycleDuration: Double {
        inhaleDuration + secondInhaleDuration + holdDuration + exhaleDuration + holdOutDuration
    }

    /// Description courte pour l'affichage dans l'exercice (format: "4s - 2s - 6s")
    var shortDescription: String {
        if holdOutDuration > 0 {
            // Box breathing: 4-4-4-4
            return String(format: LanguageManager.shared.localizedString(for: "breathing.rhythm.four_phases"),
                          Int(inhaleDuration), Int(holdDuration), Int(exhaleDuration), Int(holdOutDuration))
        } else if holdDuration > 0 {
            // 3 phases: 4-7-8
            return String(format: LanguageManager.shared.localizedString(for: "breathing.rhythm.three_phases"),
                          Int(inhaleDuration), Int(holdDuration), Int(exhaleDuration))
        } else {
            // 2 phases: 5-5
            return String(format: LanguageManager.shared.localizedString(for: "breathing.rhythm.two_phases"),
                          Int(inhaleDuration), Int(exhaleDuration))
        }
    }

    // Init avec holdOutDuration par défaut à 0 (API historique)
    init(name: String, displayName: String, inhaleDuration: Double, holdDuration: Double, exhaleDuration: Double, holdOutDuration: Double = 0, description: String) {
        self.init(
            key: name.lowercased(),
            name: name,
            displayName: displayName,
            inhaleDuration: inhaleDuration,
            secondInhaleDuration: 0,
            holdDuration: holdDuration,
            exhaleDuration: exhaleDuration,
            holdOutDuration: holdOutDuration,
            description: description
        )
    }

    /// Full catalogue initializer.
    init(
        key: String,
        name: String,
        displayName: String,
        inhaleDuration: Double,
        secondInhaleDuration: Double = 0,
        holdDuration: Double = 0,
        exhaleDuration: Double,
        holdOutDuration: Double = 0,
        description: String,
        category: BreathingCategory = .calm,
        accentHex: String = "B794F6",
        symbol: String = "wind",
        defaultMinutes: Int = 3,
        durationChoices: [Int] = [1, 3, 5, 10],
        exhaleLabelKey: String? = nil,
        isAlternateNostril: Bool = false
    ) {
        self.key = key
        self.name = name
        self.displayName = displayName
        self.inhaleDuration = inhaleDuration
        self.secondInhaleDuration = secondInhaleDuration
        self.holdDuration = holdDuration
        self.exhaleDuration = exhaleDuration
        self.holdOutDuration = holdOutDuration
        self.description = description
        self.category = category
        self.accentHex = accentHex
        self.symbol = symbol
        self.defaultMinutes = defaultMinutes
        self.durationChoices = durationChoices
        self.exhaleLabelKey = exhaleLabelKey
        self.isAlternateNostril = isAlternateNostril
    }

    // MARK: - Localized catalogue texts (computed: follow live language changes)

    private func text(_ field: String, fallback: String) -> String {
        let k = "breathing.ex.\(key).\(field)"
        let value = LanguageManager.shared.localizedString(for: k)
        return value == k || value.isEmpty ? fallback : value
    }

    var localizedTitle: String { text("title", fallback: displayName) }
    var localizedBenefit: String { text("benefit", fallback: description) }
    var localizedWhenToUse: String { text("when", fallback: description) }
    var localizedScience: String { text("science", fallback: "") }

    var accentColor: Color { Color(hex: accentHex) }

    /// Compact rhythm, e.g. "4 · 7 · 8" or "2+1 · 6".
    var rhythmLabel: String {
        func f(_ v: Double) -> String {
            v == v.rounded() ? String(Int(v)) : String(format: "%.1f", v)
        }
        var parts: [String] = []
        parts.append(secondInhaleDuration > 0 ? "\(f(inhaleDuration))+\(f(secondInhaleDuration))" : f(inhaleDuration))
        if holdDuration > 0 || holdOutDuration > 0 { parts.append(f(holdDuration)) }
        parts.append(f(exhaleDuration))
        if holdOutDuration > 0 { parts.append(f(holdOutDuration)) }
        return parts.joined(separator: " · ")
    }

    /// Breaths per minute (rounded to 0.5).
    var breathsPerMinute: Double {
        guard totalCycleDuration > 0 else { return 0 }
        return ((60 / totalCycleDuration) * 2).rounded() / 2
    }

    /// Ordered segments of one cycle (zero-length phases removed).
    var steps: [BreathingStep] {
        let topLevel = secondInhaleDuration > 0 ? 0.72 : 1.0
        var result: [BreathingStep] = [
            BreathingStep(kind: .inhale, duration: inhaleDuration, fromLevel: 0, toLevel: topLevel, labelKey: "breathing.wave.inhale")
        ]
        if secondInhaleDuration > 0 {
            result.append(BreathingStep(kind: .inhaleTopUp, duration: secondInhaleDuration, fromLevel: topLevel, toLevel: 1, labelKey: "breathing.wave.inhale_more"))
        }
        if holdDuration > 0 {
            result.append(BreathingStep(kind: .hold, duration: holdDuration, fromLevel: 1, toLevel: 1, labelKey: "breathing.wave.hold"))
        }
        result.append(BreathingStep(kind: .exhale, duration: exhaleDuration, fromLevel: 1, toLevel: 0, labelKey: exhaleLabelKey ?? "breathing.wave.exhale"))
        if holdOutDuration > 0 {
            result.append(BreathingStep(kind: .holdOut, duration: holdOutDuration, fromLevel: 0, toLevel: 0, labelKey: "breathing.wave.hold_out"))
        }
        return result.filter { $0.duration > 0 }
    }

    // MARK: - Preset Patterns (historical 8, enriched)

    static let deepAbdominal = BreathingPattern(
        key: "deep_abdominal",
        name: "DeepAbdominal",
        displayName: LanguageManager.shared.localizedString(for: "library.breathing.deep_abdominal"),
        inhaleDuration: 4,
        holdDuration: 2,
        exhaleDuration: 6,
        description: LanguageManager.shared.localizedString(for: "breathing_pattern.deep_abdominal.description"),
        category: .calm,
        accentHex: "B794F6",
        symbol: "wind",
        defaultMinutes: 3
    )

    static let fourSevenEight = BreathingPattern(
        key: "four_seven_eight",
        name: "4-7-8",
        displayName: LanguageManager.shared.localizedString(for: "library.breathing.4_7_8"),
        inhaleDuration: 4,
        holdDuration: 7,
        exhaleDuration: 8,
        description: LanguageManager.shared.localizedString(for: "breathing_pattern.four_seven_eight.description"),
        category: .sleep,
        accentHex: "9D8CFF",
        symbol: "moon.stars.fill",
        defaultMinutes: 3,
        durationChoices: [1, 3, 5]
    )

    static let coherence = BreathingPattern(
        key: "coherence",
        name: "Coherence",
        displayName: LanguageManager.shared.localizedString(for: "library.breathing.cardiac_coherence"),
        inhaleDuration: 5,
        holdDuration: 0,
        exhaleDuration: 5,
        description: LanguageManager.shared.localizedString(for: "breathing_pattern.coherence.description"),
        category: .calm,
        accentHex: "F59AC8",
        symbol: "heart.fill",
        defaultMinutes: 5,
        durationChoices: [3, 5, 10, 15]
    )

    static let slow66 = BreathingPattern(
        key: "slow66",
        name: "Slow66",
        displayName: LanguageManager.shared.localizedString(for: "library.breathing.slow"),
        inhaleDuration: 6,
        holdDuration: 0,
        exhaleDuration: 6,
        description: LanguageManager.shared.localizedString(for: "breathing_pattern.slow66.description"),
        category: .sleep,
        accentHex: "6C8CFF",
        symbol: "bed.double.fill",
        defaultMinutes: 5,
        durationChoices: [3, 5, 10, 15]
    )

    static let triangle = BreathingPattern(
        key: "triangle",
        name: "Triangle",
        displayName: LanguageManager.shared.localizedString(for: "library.breathing.triangle"),
        inhaleDuration: 4,
        holdDuration: 4,
        exhaleDuration: 4,
        description: LanguageManager.shared.localizedString(for: "breathing_pattern.triangle.description"),
        category: .focus,
        accentHex: "5FD4E0",
        symbol: "triangle",
        defaultMinutes: 3
    )

    static let boxBreathing = BreathingPattern(
        key: "box",
        name: "Box",
        displayName: LanguageManager.shared.localizedString(for: "library.breathing.box"),
        inhaleDuration: 4,
        holdDuration: 4,
        exhaleDuration: 4,
        holdOutDuration: 4, // Box breathing: 4-4-4-4
        description: LanguageManager.shared.localizedString(for: "breathing_pattern.box.description"),
        category: .focus,
        accentHex: "7FD1FF",
        symbol: "square",
        defaultMinutes: 3
    )

    static let kapalabhati = BreathingPattern(
        key: "kapalabhati",
        name: "Kapalabhati",
        displayName: LanguageManager.shared.localizedString(for: "library.breathing.kapalabhati"),
        inhaleDuration: 1,
        holdDuration: 0,
        exhaleDuration: 1,
        description: LanguageManager.shared.localizedString(for: "breathing_pattern.kapalabhati.description"),
        category: .energy,
        accentHex: "FF8A65",
        symbol: "bolt.fill",
        defaultMinutes: 1,
        durationChoices: [1, 2, 3]
    )

    /// Kept for routines / history compatibility (not listed in the catalogue: redundant with Kapalabhati).
    static let bhastrika = BreathingPattern(
        key: "bhastrika",
        name: "Bhastrika",
        displayName: LanguageManager.shared.localizedString(for: "library.breathing.bhastrika"),
        inhaleDuration: 1,
        holdDuration: 0,
        exhaleDuration: 1,
        description: LanguageManager.shared.localizedString(for: "breathing_pattern.bhastrika.description"),
        category: .energy,
        accentHex: "FF7043",
        symbol: "flame.fill",
        defaultMinutes: 1,
        durationChoices: [1, 2, 3]
    )

    // MARK: - New Patterns

    static let physiologicalSigh = BreathingPattern(
        key: "physiological_sigh",
        name: "PhysiologicalSigh",
        displayName: LanguageManager.shared.localizedString(for: "breathing.ex.physiological_sigh.title"),
        inhaleDuration: 2,
        secondInhaleDuration: 1,
        exhaleDuration: 6,
        description: LanguageManager.shared.localizedString(for: "breathing.ex.physiological_sigh.benefit"),
        category: .sos,
        accentHex: "FF9AA2",
        symbol: "lungs.fill",
        defaultMinutes: 1,
        durationChoices: [1, 3, 5]
    )

    static let sos214 = BreathingPattern(
        key: "sos_214",
        name: "SOS214",
        displayName: LanguageManager.shared.localizedString(for: "breathing.ex.sos_214.title"),
        inhaleDuration: 2,
        holdDuration: 1,
        exhaleDuration: 4,
        description: LanguageManager.shared.localizedString(for: "breathing.ex.sos_214.benefit"),
        category: .sos,
        accentHex: "FFB86B",
        symbol: "cross.circle.fill",
        defaultMinutes: 1,
        durationChoices: [1, 2, 3]
    )

    static let extendedExhale = BreathingPattern(
        key: "extended_exhale",
        name: "ExtendedExhale",
        displayName: LanguageManager.shared.localizedString(for: "breathing.ex.extended_exhale.title"),
        inhaleDuration: 4,
        exhaleDuration: 8,
        description: LanguageManager.shared.localizedString(for: "breathing.ex.extended_exhale.benefit"),
        category: .calm,
        accentHex: "8FE3C3",
        symbol: "leaf.fill",
        defaultMinutes: 3
    )

    static let humming = BreathingPattern(
        key: "humming",
        name: "Humming",
        displayName: LanguageManager.shared.localizedString(for: "breathing.ex.humming.title"),
        inhaleDuration: 4,
        exhaleDuration: 7,
        description: LanguageManager.shared.localizedString(for: "breathing.ex.humming.benefit"),
        category: .calm,
        accentHex: "E6B3FF",
        symbol: "waveform",
        defaultMinutes: 3,
        durationChoices: [1, 3, 5],
        exhaleLabelKey: "breathing.wave.hum"
    )

    static let sleepWave = BreathingPattern(
        key: "sleep_wave",
        name: "SleepWave",
        displayName: LanguageManager.shared.localizedString(for: "breathing.ex.sleep_wave.title"),
        inhaleDuration: 4,
        exhaleDuration: 6,
        holdOutDuration: 2,
        description: LanguageManager.shared.localizedString(for: "breathing.ex.sleep_wave.benefit"),
        category: .sleep,
        accentHex: "A78BFA",
        symbol: "moon.zzz.fill",
        defaultMinutes: 10,
        durationChoices: [5, 10, 15]
    )

    static let alternateNostril = BreathingPattern(
        key: "alternate_nostril",
        name: "AlternateNostril",
        displayName: LanguageManager.shared.localizedString(for: "breathing.ex.alternate_nostril.title"),
        inhaleDuration: 4,
        exhaleDuration: 6,
        description: LanguageManager.shared.localizedString(for: "breathing.ex.alternate_nostril.benefit"),
        category: .focus,
        accentHex: "80E0B0",
        symbol: "circle.lefthalf.filled",
        defaultMinutes: 3,
        durationChoices: [1, 3, 5],
        isAlternateNostril: true
    )

    static let energize = BreathingPattern(
        key: "energize",
        name: "Energize",
        displayName: LanguageManager.shared.localizedString(for: "breathing.ex.energize.title"),
        inhaleDuration: 4,
        exhaleDuration: 2,
        description: LanguageManager.shared.localizedString(for: "breathing.ex.energize.benefit"),
        category: .energy,
        accentHex: "FFD36B",
        symbol: "sun.max.fill",
        defaultMinutes: 1,
        durationChoices: [1, 2, 3]
    )

    /// The 14-exercise catalogue.
    static let allPatterns: [BreathingPattern] = [
        // Calm
        .coherence,
        .extendedExhale,
        .deepAbdominal,
        .humming,
        // SOS
        .physiologicalSigh,
        .sos214,
        // Sleep
        .fourSevenEight,
        .sleepWave,
        .slow66,
        // Focus
        .boxBreathing,
        .triangle,
        .alternateNostril,
        // Energy
        .energize,
        .kapalabhati
    ]

    /// Lookup by `name` or `key` (includes legacy patterns).
    static func pattern(named value: String) -> BreathingPattern? {
        (allPatterns + [.bhastrika]).first { $0.name == value || $0.key == value }
    }
}

// MARK: - Breathing Phase

enum BreathingPhase: String {
    case inhale
    case hold
    case exhale

    var displayText: String {
        switch self {
        case .inhale:
            return LanguageManager.shared.localizedString(for: "breathing.phase.inhale")
        case .hold:
            return LanguageManager.shared.localizedString(for: "breathing.phase.hold")
        case .exhale:
            return LanguageManager.shared.localizedString(for: "breathing.phase.exhale")
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
