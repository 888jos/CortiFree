//
//  MiloDecode.swift
//  CortiFree
//
//  « Decode this message »: the user shares the text that is making them overthink
//  (a screenshot of the chat or the pasted message). Milo gives the most likely reading,
//  one sentence to calm the spiral and a calm reply they can send. Nothing is stored.
//

import Foundation

struct MiloDecodeResult: Equatable {
    var tone: String
    var meaning: String
    var reassurance: String
    var reply: String
}

enum MiloDecodeAnalyzer {

    private struct Payload: Decodable {
        let tone: String
        let meaning: String
        let reassurance: String
        let reply: String
    }

    static func decode(_ document: MiloImportDocument) async throws -> MiloDecodeResult {
        let code = LanguageManager.shared.currentLanguage.rawValue
        let language = Locale(identifier: "en").localizedString(forLanguageCode: code) ?? code
        // The server wraps the text in <conversation> tags under its own prompt.
        let raw = try await DeepSeekChatService.shared.reply(.decode(language: language), messages: [
            DeepSeekChatMessage(role: "user", content: MiloImportReader.excerpt(document.text, limit: 4000))
        ])
        guard let start = raw.firstIndex(of: "{"), let end = raw.lastIndex(of: "}"), start < end,
              let data = String(raw[start...end]).data(using: .utf8),
              let payload = try? JSONDecoder().decode(Payload.self, from: data)
        else { throw DeepSeekChatError.invalidResponse }

        let meaning = payload.meaning.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !meaning.isEmpty else { throw MiloImportError.notConversation }
        return MiloDecodeResult(
            tone: String(payload.tone.trimmingCharacters(in: .whitespacesAndNewlines).prefix(40)),
            meaning: String(meaning.prefix(420)),
            reassurance: String(payload.reassurance.trimmingCharacters(in: .whitespacesAndNewlines).prefix(240)),
            reply: String(payload.reply.trimmingCharacters(in: .whitespacesAndNewlines).prefix(400))
        )
    }
}
