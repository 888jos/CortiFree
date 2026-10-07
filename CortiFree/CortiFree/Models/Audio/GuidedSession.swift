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
    case stressSOS
    case workBreak
    case sleep
    case morning
    case bodyRelax
    case anxiety
    case selfCompassion
    case focus

    var id: String { rawValue }

    var title: LocalizedText {
        switch self {
        case .stressSOS:
            return LocalizedText(fr: "Stress SOS", en: "Stress SOS", de: "Stress-SOS", es: "SOS estrés", ja: "ストレスSOS", ko: "스트레스 SOS")
        case .workBreak:
            return LocalizedText(fr: "Pause travail", en: "Work break", de: "Arbeitspause", es: "Pausa en el trabajo", ja: "仕事の合間に", ko: "업무 중 휴식")
        case .sleep:
            return LocalizedText(fr: "Sommeil", en: "Sleep", de: "Schlaf", es: "Sueño", ja: "睡眠", ko: "수면")
        case .morning:
            return LocalizedText(fr: "Matin & énergie", en: "Morning & energy", de: "Morgen & Energie", es: "Mañana y energía", ja: "朝とエネルギー", ko: "아침 & 에너지")
        case .bodyRelax:
            return LocalizedText(fr: "Corps & détente", en: "Body & relaxation", de: "Körper & Entspannung", es: "Cuerpo y relajación", ja: "からだとリラックス", ko: "몸 & 이완")
        case .anxiety:
            return LocalizedText(fr: "Anxiété & émotions", en: "Anxiety & emotions", de: "Angst & Gefühle", es: "Ansiedad y emociones", ja: "不安と感情", ko: "불안 & 감정")
        case .selfCompassion:
            return LocalizedText(fr: "Bienveillance", en: "Self-compassion", de: "Selbstmitgefühl", es: "Autocompasión", ja: "セルフ・コンパッション", ko: "자기 자비")
        case .focus:
            return LocalizedText(fr: "Concentration", en: "Focus", de: "Fokus", es: "Concentración", ja: "集中", ko: "집중")
        }
    }

    var subtitle: LocalizedText {
        switch self {
        case .stressSOS:
            return LocalizedText(fr: "Retrouver le calme en quelques minutes", en: "Find calm in a few minutes", de: "In wenigen Minuten zur Ruhe kommen", es: "Recupera la calma en pocos minutos", ja: "数分で落ち着きを取り戻す", ko: "몇 분 만에 평온 되찾기")
        case .workBreak:
            return LocalizedText(fr: "Des pauses courtes pour souffler au travail", en: "Short breaks to breathe at work", de: "Kurze Pausen zum Durchatmen", es: "Pausas breves para respirar en el trabajo", ja: "仕事中にひと息つく短い休憩", ko: "일하면서 숨 돌리는 짧은 휴식")
        case .sleep:
            return LocalizedText(fr: "Lâcher la journée et s'endormir", en: "Let go of the day and fall asleep", de: "Den Tag loslassen und einschlafen", es: "Suelta el día y duérmete", ja: "一日を手放して眠りへ", ko: "하루를 내려놓고 잠들기")
        case .morning:
            return LocalizedText(fr: "Commencer la journée du bon pied", en: "Start the day on the right foot", de: "Gut in den Tag starten", es: "Empieza el día con buen pie", ja: "良い一日のスタートを", ko: "기분 좋게 하루 시작하기")
        case .bodyRelax:
            return LocalizedText(fr: "Relâcher les tensions du corps", en: "Release tension from the body", de: "Körperliche Spannungen lösen", es: "Libera la tensión del cuerpo", ja: "からだの緊張をほどく", ko: "몸의 긴장 풀기")
        case .anxiety:
            return LocalizedText(fr: "Accueillir et apaiser ce que tu ressens", en: "Meet and soothe what you feel", de: "Gefühle annehmen und beruhigen", es: "Acoge y calma lo que sientes", ja: "感じていることを受けとめ、和らげる", ko: "느끼는 감정을 받아들이고 달래기")
        case .selfCompassion:
            return LocalizedText(fr: "Être un allié pour toi-même", en: "Be on your own side", de: "Dir selbst ein Freund sein", es: "Sé tu propio aliado", ja: "自分の味方になる", ko: "나 자신의 편이 되기")
        case .focus:
            return LocalizedText(fr: "Clarté mentale et attention", en: "Mental clarity and attention", de: "Klarheit und Aufmerksamkeit", es: "Claridad mental y atención", ja: "頭をすっきり、集中力を", ko: "맑은 정신과 집중력")
        }
    }

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

    /// Language used for the narration script / recorded audio. Scripts exist in fr & en;
    /// other UI languages fall back to English.
    static func narrationLanguage(for language: LanguageManager.Language = LanguageManager.shared.currentLanguage) -> String {
        language == .french ? "fr" : "en"
    }

    /// A professionally recorded file, if one is bundled for this session.
    /// Lookup order: `<id>_<uiLang>`, `<id>_<narrationLang>`, `<id>` with m4a/mp3, then `remoteAudioURL`.
    func recordedAudioURL(language: LanguageManager.Language = LanguageManager.shared.currentLanguage) -> URL? {
        let candidates = ["\(id)_\(language.rawValue)", "\(id)_\(Self.narrationLanguage(for: language))", id]
        for name in candidates {
            for ext in ["m4a", "mp3", "aac", "wav"] {
                if let url = Bundle.main.url(forResource: name, withExtension: ext) { return url }
            }
        }
        return remoteAudioURL
    }
}
