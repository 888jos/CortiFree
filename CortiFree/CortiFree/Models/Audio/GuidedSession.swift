//
//  GuidedSession.swift
//  CortiFree
//
//  Guided audio sessions (meditations played like tracks).
//

import SwiftUI

// MARK: - Localized text (catalogue content, 6 UI languages)

struct LocalizedText: Hashable {
    let fr: String
    let en: String
    let de: String
    let es: String
    let ja: String
    let ko: String

    func value(for language: LanguageManager.Language) -> String {
        switch language {
        case .french: return fr
        case .english: return en
        case .german: return de
        case .spanish: return es
        case .japanese: return ja
        case .korean: return ko
        }
    }

    /// Value in the current app language.
    var localized: String { value(for: LanguageManager.shared.currentLanguage) }
}

// MARK: - Category

enum AudioSessionCategory: String, CaseIterable, Identifiable, Codable {
    case firstSteps
    case stressSOS
    case workBreak
    case sleep
    case morning
    case bodyRelax
    case anxiety
    case selfCompassion
    case focus
    case stressScience

    var id: String { rawValue }

    /// Theme names and one-line pitches come from catalog_plan.json (GuidedSessionCatalogData.swift).
    var title: LocalizedText { generatedTitle }
    var subtitle: LocalizedText { generatedSubtitle }

    var symbol: String {
        switch self {
        case .stressSOS: return "bolt.heart.fill"
        case .workBreak: return "laptopcomputer"
        case .sleep: return "moon.stars.fill"
        case .morning: return "sunrise.fill"
        case .bodyRelax: return "figure.mind.and.body"
        case .anxiety: return "cloud.sun.fill"
        case .selfCompassion: return "heart.fill"
        case .focus: return "scope"
        case .firstSteps: return "leaf.fill"
        case .stressScience: return "brain.head.profile"
        }
    }

    var colors: [Color] {
        switch self {
        case .stressSOS: return [Color(hex: "7B5CFF"), Color(hex: "C084FC")]
        case .workBreak: return [Color(hex: "3B82F6"), Color(hex: "8B5CF6")]
        case .sleep: return [Color(hex: "1E1B4B"), Color(hex: "4C1D95")]
        case .morning: return [Color(hex: "F59E0B"), Color(hex: "EC4899")]
        case .bodyRelax: return [Color(hex: "0EA5E9"), Color(hex: "6366F1")]
        case .anxiety: return [Color(hex: "14B8A6"), Color(hex: "6366F1")]
        case .selfCompassion: return [Color(hex: "F472B6"), Color(hex: "A855F7")]
        case .focus: return [Color(hex: "6366F1"), Color(hex: "22D3EE")]
        case .firstSteps: return [Color(hex: "10B981"), Color(hex: "6366F1")]
        case .stressScience: return [Color(hex: "8B5CF6"), Color(hex: "14B8A6")]
        }
    }
}

// MARK: - Ambience (bundled loops in Resources/Sounds)

enum AudioAmbience: String, CaseIterable, Identifiable, Codable {
    case rain
    case ocean
    case fire
    case whitenoise
    case morning
    case forest
    case stream
    case summerNight = "summer-night"

    var id: String { rawValue }

    /// Bundle resource name (m4a).
    var fileName: String { rawValue }

    /// Matching `Exercise.sounds` id (used for localized titles).
    var soundExerciseID: String {
        switch self {
        case .morning: return "wind"
        case .summerNight: return "night"
        default: return rawValue
        }
    }

    var symbol: String {
        switch self {
        case .rain: return "cloud.rain.fill"
        case .ocean: return "water.waves"
        case .fire: return "flame.fill"
        case .whitenoise: return "waveform"
        case .morning: return "sunrise.fill"
        case .forest: return "leaf.fill"
        case .stream: return "drop.fill"
        case .summerNight: return "moon.stars.fill"
        }
    }

    var localizedTitle: String {
        let key: String
        switch self {
        case .summerNight: key = "sounds.night"
        default: key = "sounds.\(rawValue)"
        }
        return LanguageManager.shared.localizedString(for: key)
    }

    var url: URL? {
        Bundle.main.url(forResource: fileName, withExtension: "m4a")
    }
}

// MARK: - Artwork

struct SessionArtwork: Hashable {
    let symbol: String
    let colors: [Color]
    /// Optional asset catalog image (illustration).
    let imageName: String?
}

// MARK: - Session

struct GuidedSession: Identifiable, Hashable {
    let id: String
    let title: LocalizedText
    let subtitle: LocalizedText
    let category: AudioSessionCategory
    /// Target duration in minutes (real duration comes from the audio track).
    let durationMinutes: Int
    let isPremium: Bool
    let artwork: SessionArtwork
    let defaultAmbience: AudioAmbience?
    /// Optional remote audio (streamed). Bundled files are discovered by naming convention,
    /// see `recordedAudioURL(for:)` and scripts/narration/README.md.
    let remoteAudioURL: URL?

    static func == (lhs: GuidedSession, rhs: GuidedSession) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }

    var localizedTitle: String { title.localized }
    var localizedSubtitle: String { subtitle.localized }
    var durationLabel: String { "\(durationMinutes) min" }

    /// Language used for the narration script / recorded audio: the UI language
    /// (fr, en, de, es, ja, ko). NarrationLibrary falls back to English if a script is missing.
    static func narrationLanguage(for language: LanguageManager.Language = LanguageManager.shared.currentLanguage) -> String {
        language.rawValue
    }

    /// A professionally recorded file, if one is bundled for this session
    /// (Resources/SessionAudio, see scripts/narration/README.md).
    /// Lookup order: `<id>_<uiLang>`, then the English recording `<id>_en`, then `<id>`,
    /// then `remoteAudioURL`. A recording in English beats the on-device voice in the UI language.
    func recordedAudioURL(language: LanguageManager.Language = LanguageManager.shared.currentLanguage) -> URL? {
        for name in ["\(id)_\(Self.narrationLanguage(for: language))", "\(id)_en", id] {
            if let url = Self.bundledRecording(named: name) { return url }
        }
        return remoteAudioURL
    }

    /// Language the listener actually hears, which is also the script shown in the player:
    /// the recording in the UI language, else the English recording, else the on-device
    /// voice reading the UI-language script (English when the session has none).
    var playbackLanguage: String {
        let language = Self.narrationLanguage()
        if Self.bundledRecording(named: "\(id)_\(language)") != nil { return language }
        if Self.bundledRecording(named: "\(id)_en") != nil { return "en" }
        return NarrationLibrary.shared.hasScript(for: id, language: language) ? language : "en"
    }

    private static func bundledRecording(named name: String) -> URL? {
        for ext in ["m4a", "mp3", "aac", "wav"] {
            if let url = Bundle.main.url(forResource: name, withExtension: ext) { return url }
        }
        return nil
    }
}
