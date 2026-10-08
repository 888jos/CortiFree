//
//  NarrationScript.swift
//  CortiFree
//
//  Loads narration scripts from Resources/Narration/narration_<lang>.json and parses
//  `[pause Ns]` markers into speech / silence segments.
//

import Foundation

enum NarrationSegment: Equatable {
    case speech(String)
    case pause(TimeInterval)
}

struct NarrationScript {
    let sessionID: String
    let language: String
    /// Raw script lines (spoken passages and `[pause Ns]` markers).
    let lines: [String]

    /// Full text with markers, used as the render cache key.
    var rawText: String { lines.joined(separator: "\n") }

    /// Readable text without pause markers (shown in the player's script panel).
    var displayParagraphs: [String] {
        segments.compactMap {
            if case .speech(let text) = $0 { return text }
            return nil
        }
    }

    var segments: [NarrationSegment] { Self.parse(lines) }

    // MARK: - Parsing

    private static let pauseRegex = try! NSRegularExpression(
        pattern: #"\[\s*pause\s+(\d+(?:[.,]\d+)?)\s*s?\s*\]"#,
        options: [.caseInsensitive]
    )

    static func parse(_ lines: [String]) -> [NarrationSegment] {
        var result: [NarrationSegment] = []
        for line in lines {
            let ns = line as NSString
            var cursor = 0
            let matches = pauseRegex.matches(in: line, range: NSRange(location: 0, length: ns.length))
            for match in matches {
                let before = ns.substring(with: NSRange(location: cursor, length: match.range.location - cursor))
                appendSpeech(before, to: &result)
                let value = ns.substring(with: match.range(at: 1)).replacingOccurrences(of: ",", with: ".")
                if let seconds = Double(value), seconds > 0 {
                    result.append(.pause(seconds))
                }
                cursor = match.range.location + match.range.length
            }
            appendSpeech(ns.substring(from: cursor), to: &result)
        }
        return result
    }

    private static func appendSpeech(_ text: String, to result: inout [NarrationSegment]) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        result.append(.speech(trimmed))
    }
}

// MARK: - Library (bundled JSON)

final class NarrationLibrary {
    static let shared = NarrationLibrary()

    private struct FileModel: Decodable {
        struct Session: Decodable {
            let id: String
            let script: [String]
        }
        let language: String
        let sessions: [Session]
    }

    private var cache: [String: [String: [String]]] = [:]
    private let lock = NSLock()

    private init() {}

    /// Script for a session in the requested narration language, falling back to English.
    /// The fallback is never silent: the UI shows an "English narration" tag
    /// (`GuidedSession.hasNarrationInCurrentLanguage`), and the English script is always read
    /// by an English voice (`NarrationScript.language` picks the voice).
    func script(for sessionID: String, language: String) -> NarrationScript? {
        for lang in [language, "en"] {
            if let lines = sessions(for: lang)[sessionID], !lines.isEmpty {
                return NarrationScript(sessionID: sessionID, language: lang, lines: lines)
            }
        }
        return nil
    }

    /// True when the session has its own script in `language` (no English fallback).
    func hasScript(for sessionID: String, language: String) -> Bool {
        !(sessions(for: language)[sessionID]?.isEmpty ?? true)
    }

    private func sessions(for language: String) -> [String: [String]] {
        lock.lock()
        defer { lock.unlock() }
        if let cached = cache[language] { return cached }

        var map: [String: [String]] = [:]
        if let url = Bundle.main.url(forResource: "narration_\(language)", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let file = try? JSONDecoder().decode(FileModel.self, from: data) {
            for session in file.sessions { map[session.id] = session.script }
        }
        cache[language] = map
        return map
    }
}

extension GuidedSession {
    /// False when the listener would hear English in another app language (no recording or
    /// script in that language yet, see `playbackLanguage`). Shown as an "EN" tag in the
    /// Library and the player.
    var hasNarrationInCurrentLanguage: Bool {
        playbackLanguage == GuidedSession.narrationLanguage()
    }
}
