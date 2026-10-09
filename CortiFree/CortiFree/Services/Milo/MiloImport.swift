//
//  MiloImport.swift
//  CortiFree
//
//  « Bring your story to Milo »: the user shares a conversation with another AI
//  (ChatGPT, Claude…), an Apple Health PDF export or notes. The text is read on
//  device, sent once to the assistant for a short summary, then dropped: only the
//  summary (MiloInsight) is kept, visible and deletable from Milo's memory page.
//

import Foundation
import PDFKit
import UniformTypeIdentifiers
import Vision
import UIKit

/// What Milo learned from an imported document. Stored per account by MiloStore.
struct MiloInsight: Codable, Equatable {
    enum Source: String, Codable {
        case aiChat, healthPDF, document
    }

    var summary: String
    var themes: [String]
    var firstStep: String
    var source: Source
    var date: Date

    /// Plain-text block added to Milo's context on every message.
    var contextLine: String {
        var line = "Summary of a document the user imported (\(source.rawValue), \(date.formatted(date: .abbreviated, time: .omitted))): \(summary)"
        if !themes.isEmpty { line += " Themes: \(themes.joined(separator: ", "))." }
        line += " Use it naturally to personalize advice; never quote it back word for word and never treat it as a diagnosis."
        return line
    }
}

enum MiloImportError: LocalizedError {
    case unreadable, empty, notPersonal, linkUnreadable, notConversation

    var errorDescription: String? {
        let key: String
        switch self {
        case .unreadable: key = "milo.import.error.unreadable"
        case .empty: key = "milo.import.error.empty"
        case .notPersonal: key = "milo.import.error.not_personal"
        case .linkUnreadable: key = "milo.import.error.link"
        case .notConversation: key = "milo.decode.error.not_conversation"
        }
        return LanguageManager.shared.localizedString(for: key)
    }
}

/// A document ready to analyse: its text and where it came from.
struct MiloImportDocument: Equatable {
    var text: String
    var source: MiloInsight.Source
    var fileName: String?
}

enum MiloImportReader {

    /// Types accepted by the file picker and by « Open in CortiFree ».
    static let fileTypes: [UTType] = [.pdf, .image, .plainText, .utf8PlainText, .text, .json, .html]
        + [UTType(filenameExtension: "md")].compactMap { $0 }

    /// Reads a PDF or text file the user picked or shared to the app.
    static func read(_ url: URL) throws -> MiloImportDocument {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }

        if let type = UTType(filenameExtension: url.pathExtension), type.conforms(to: .image) {
            guard let data = try? Data(contentsOf: url) else { throw MiloImportError.unreadable }
            return try image(data)
        }

        let text: String
        if url.pathExtension.lowercased() == "pdf" || UTType(filenameExtension: url.pathExtension)?.conforms(to: .pdf) == true {
            guard let pdf = PDFDocument(url: url) else { throw MiloImportError.unreadable }
            text = (0..<pdf.pageCount).compactMap { pdf.page(at: $0)?.string }.joined(separator: "\n")
        } else {
            guard let data = try? Data(contentsOf: url),
                  let decoded = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1)
            else { throw MiloImportError.unreadable }
            text = url.pathExtension.lowercased() == "html" ? stripHTML(decoded) : decoded
        }

        let cleaned = normalize(text)
        guard cleaned.count >= minimumLength else { throw MiloImportError.empty }
        return MiloImportDocument(text: cleaned, source: source(for: cleaned, isPDF: url.pathExtension.lowercased() == "pdf"),
                                  fileName: url.lastPathComponent)
    }

    /// Text pasted from the clipboard (a copied conversation or an AI's answer).
    static func pasted(_ text: String) throws -> MiloImportDocument {
        let cleaned = normalize(text)
        guard cleaned.count >= minimumLength else { throw MiloImportError.empty }
        return MiloImportDocument(text: cleaned, source: .aiChat, fileName: nil)
    }

    static let minimumLength = 80

    /// A screenshot of a conversation (iMessage, WhatsApp, Instagram…). Bubbles on the right
    /// were sent by the user and bubbles on the left by the other person, so each line is
    /// tagged « Me: » / « Them: » from its position; centred lines (names, times) stay untagged.
    static func chatImage(_ data: Data) throws -> MiloImportDocument {
        guard let cgImage = UIImage(data: data)?.cgImage else { throw MiloImportError.unreadable }
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.automaticallyDetectsLanguage = true
        do {
            try VNImageRequestHandler(cgImage: cgImage).perform([request])
        } catch {
            throw MiloImportError.unreadable
        }
        let lines = (request.results ?? [])
            .sorted { $0.boundingBox.midY > $1.boundingBox.midY } // Vision's origin is bottom-left
            .compactMap { observation -> String? in
                guard let text = observation.topCandidates(1).first?.string else { return nil }
                let box = observation.boundingBox
                if box.minX > 0.3 && box.maxX > 0.75 { return "Me: \(text)" }
                if box.minX < 0.25 && box.maxX < 0.7 { return "Them: \(text)" }
                return text
            }
        let cleaned = normalize(lines.joined(separator: "\n"))
        guard cleaned.count >= 8 else { throw MiloImportError.empty }
        return MiloImportDocument(text: cleaned, source: .document, fileName: nil)
    }

    /// A screenshot (Apple Health result, a chat…): its text is recognised on device.
    static func image(_ data: Data) throws -> MiloImportDocument {
        guard let cgImage = UIImage(data: data)?.cgImage else { throw MiloImportError.unreadable }
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.automaticallyDetectsLanguage = true
        do {
            try VNImageRequestHandler(cgImage: cgImage).perform([request])
        } catch {
            throw MiloImportError.unreadable
        }
        let lines = (request.results ?? []).compactMap { $0.topCandidates(1).first?.string }
        let cleaned = normalize(lines.joined(separator: "\n"))
        // A Health result screenshot is short: accept less text than for a pasted chat.
        guard cleaned.count >= 40 else { throw MiloImportError.empty }
        return MiloImportDocument(text: cleaned, source: source(for: cleaned, isPDF: true), fileName: nil)
    }

    /// Health exports mention the questionnaire or the Health app; everything else is a chat or notes.
    private static func source(for text: String, isPDF: Bool) -> MiloInsight.Source {
        let lower = text.lowercased()
        let healthMarkers = ["gad-7", "gad7", "phq-9", "phq9", "apple health", "santé", "anxiety risk", "risque d'anxiété",
                             "mental wellbeing", "bien-être mental", "state of mind", "état d'esprit"]
        if healthMarkers.contains(where: lower.contains) { return .healthPDF }
        let chatMarkers = ["chatgpt", "claude", "gemini", "you said", "vous avez dit", "assistant:", "user:"]
        return chatMarkers.contains(where: lower.contains) || !isPDF ? .aiChat : .document
    }

    private static func normalize(_ text: String) -> String {
        text.replacingOccurrences(of: "\r", with: "\n")
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
    }

    private static func stripHTML(_ html: String) -> String {
        html.replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&amp;", with: "&")
    }

    /// The server accepts 6 000 characters per message: keep the start and the end, where
    /// people usually explain their situation and where the latest state is.
    static func excerpt(_ text: String, limit: Int = 5200) -> String {
        guard text.count > limit else { return text }
        let half = limit / 2
        return String(text.prefix(half)) + "\n[…]\n" + String(text.suffix(half))
    }
}

/// Topics spotted on device while Milo « reads »: they float in during the animation,
/// so what the user sees comes from their own document, not from a canned list.
enum MiloImportTopics {
    struct Topic: Identifiable, Equatable {
        let key: String
        let icon: String
        var id: String { key }
        var title: String { LanguageManager.shared.localizedString(for: "milo.import.topic.\(key)") }
    }

    private static let rules: [(Topic, [String])] = [
        (Topic(key: "sleep", icon: "moon.zzz.fill"), ["sleep", "insomn", "tired", "sommeil", "dormir", "fatigu", "schlaf", "sueño", "dormir", "眠", "睡眠", "잠", "수면"]),
        (Topic(key: "anxiety", icon: "waveform.path.ecg"), ["anxi", "panic", "worry", "angoiss", "panique", "inquiet", "angst", "ansiedad", "不安", "불안", "gad"]),
        (Topic(key: "work", icon: "briefcase.fill"), ["work", "job", "boss", "deadline", "travail", "boulot", "patron", "arbeit", "trabajo", "仕事", "직장", "업무"]),
        (Topic(key: "studies", icon: "book.fill"), ["exam", "school", "study", "university", "examen", "école", "fac", "études", "prüfung", "universidad", "試験", "시험"]),
        (Topic(key: "relationships", icon: "heart.fill"), ["relationship", "boyfriend", "girlfriend", "partner", "breakup", "couple", "copain", "copine", "rupture", "beziehung", "pareja", "恋人", "연애"]),
        (Topic(key: "family", icon: "house.fill"), ["family", "mom", "dad", "parents", "famille", "mère", "père", "familie", "familia", "家族", "가족"]),
        (Topic(key: "overthinking", icon: "tornado"), ["overthink", "ruminat", "racing thoughts", "can't stop thinking", "pensées", "rumin", "gedanken", "pensamientos", "考えすぎ", "생각"]),
        (Topic(key: "energy", icon: "bolt.fill"), ["energy", "burnout", "burn-out", "exhaust", "énergie", "épuis", "erschöpf", "agotad", "疲れ", "번아웃"]),
        (Topic(key: "self_esteem", icon: "person.fill"), ["confidence", "self-esteem", "insecure", "confiance", "estime", "selbstwert", "autoestima", "自信", "자존감"]),
        (Topic(key: "focus", icon: "scope"), ["focus", "concentrat", "adhd", "procrastin", "concentr", "konzentr", "集中", "집중"])
    ]

    static func detect(in text: String, limit: Int = 5) -> [Topic] {
        let lower = text.lowercased()
        return rules
            .map { rule in (rule.0, rule.1.reduce(0) { $0 + lower.components(separatedBy: $1).count - 1 }) }
            .filter { $0.1 > 0 }
            .sorted { $0.1 > $1.1 }
            .prefix(limit)
            .map(\.0)
    }
}

enum MiloImportAnalyzer {

    private struct Payload: Decodable {
        let summary: String
        let themes: [String]
        let first_step: String
    }

    static func analyze(_ document: MiloImportDocument) async throws -> MiloInsight {
        let code = LanguageManager.shared.currentLanguage.rawValue
        let language = Locale(identifier: "en").localizedString(forLanguageCode: code) ?? code
        // The server wraps the text in <document> tags under its own prompt.
        let raw = try await DeepSeekChatService.shared.reply(.importDocument(language: language), messages: [
            DeepSeekChatMessage(role: "user", content: MiloImportReader.excerpt(document.text))
        ])
        guard let payload = decode(raw) else { throw DeepSeekChatError.invalidResponse }
        let summary = payload.summary.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !summary.isEmpty else { throw MiloImportError.notPersonal }

        return MiloInsight(
            summary: String(summary.prefix(420)),
            themes: payload.themes.map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }.prefix(4).map { String($0.prefix(28)) },
            firstStep: String(payload.first_step.trimmingCharacters(in: .whitespacesAndNewlines).prefix(220)),
            source: document.source,
            date: Date()
        )
    }

    /// Accepts the JSON alone or wrapped in a ```json fence.
    private static func decode(_ raw: String) -> Payload? {
        guard let start = raw.firstIndex(of: "{"), let end = raw.lastIndex(of: "}"), start < end,
              let data = String(raw[start...end]).data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(Payload.self, from: data)
    }
}

/// Files shared to CortiFree from another app (« Open in CortiFree ») waiting for Milo.
@MainActor
final class MiloImportCenter: ObservableObject {
    static let shared = MiloImportCenter()
    private init() {}

    @Published var pendingDocument: MiloImportDocument?
    /// A conversation link shared from ChatGPT, Claude, Grok, Gemini…: read when Milo opens.
    @Published var pendingLink: URL?
    /// A message (screenshot or text) shared to be decoded by Milo.
    @Published var pendingDecode: MiloImportDocument?
    @Published var pendingError: String?

    /// Picks up what the share extension left in the App Group. Returns true if Milo should open.
    @discardableResult
    func checkShareInbox() -> Bool {
        guard let (item, file) = MiloShareInbox.pending() else { return false }
        defer { MiloShareInbox.clear() }
        if item.mode == .decode {
            do {
                if item.kind == .file, let file {
                    pendingDecode = try MiloImportReader.chatImage(Data(contentsOf: file))
                } else if let text = item.text?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty {
                    pendingDecode = MiloImportDocument(text: text, source: .document, fileName: nil)
                } else {
                    return false
                }
            } catch {
                pendingError = (error as? LocalizedError)?.errorDescription ?? MiloImportError.unreadable.errorDescription
            }
            return true
        }
        switch item.kind {
        case .link:
            guard let link = item.link.flatMap(URL.init(string:)) else { return false }
            pendingLink = link
        case .text:
            do { pendingDocument = try MiloImportReader.pasted(item.text ?? "") }
            catch { pendingError = error.localizedDescription }
        case .file:
            guard let file else { return false }
            do { pendingDocument = try MiloImportReader.read(file) }
            catch { pendingError = error.localizedDescription }
        }
        return true
    }

    func receive(_ url: URL) {
        do {
            pendingDocument = try MiloImportReader.read(url)
        } catch {
            pendingError = error.localizedDescription
        }
        // Copies land in the app's Inbox: nothing of the raw file is kept.
        if url.path.contains("/Inbox/") { try? FileManager.default.removeItem(at: url) }
    }

    /// Ready-made question for the user's own AI, opened with the text already filled in.
    static func askPrompt() -> String {
        LanguageManager.shared.localizedString(for: "milo.import.ask.prompt")
    }

    static func askURL(_ app: AskApp) -> URL? {
        var components = URLComponents(string: app.baseURL)
        components?.queryItems = [URLQueryItem(name: "q", value: askPrompt())]
        return components?.url
    }

    enum AskApp: String, CaseIterable, Identifiable {
        case chatgpt, claude
        var id: String { rawValue }
        var name: String { self == .chatgpt ? "ChatGPT" : "Claude" }
        var baseURL: String { self == .chatgpt ? "https://chatgpt.com/" : "https://claude.ai/new" }
    }
}

/// Reads a shared conversation page (chatgpt.com/share/…, claude.ai/share/…, grok.com/share/…,
/// gemini.google.com/share/…). These pages are built for browsers and change without notice,
/// so the text is pulled out generically: prose strings in the page's embedded data, then its
/// visible text. If too little comes out, the user is asked to paste the conversation instead.
enum MiloShareLinkReader {

    static func read(_ url: URL) async throws -> MiloImportDocument {
        guard let scheme = url.scheme?.lowercased(), scheme == "https" || scheme == "http" else {
            throw MiloImportError.linkUnreadable
        }
        var request = URLRequest(url: url, timeoutInterval: 20)
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Mobile/15E148 Safari/604.1",
                         forHTTPHeaderField: "User-Agent")
        request.setValue(Locale.preferredLanguages.first ?? "en", forHTTPHeaderField: "Accept-Language")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse).map({ 200..<300 ~= $0.statusCode }) ?? false,
              let html = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1)
        else { throw MiloImportError.linkUnreadable }

        let text = await Task.detached(priority: .userInitiated) { extractConversation(from: html) }.value
        guard text.count >= 150 else { throw MiloImportError.linkUnreadable }
        return MiloImportDocument(text: text, source: .aiChat, fileName: provider(for: url))
    }

    static func provider(for url: URL) -> String? {
        let host = url.host?.lowercased() ?? ""
        if host.contains("chatgpt.com") || host.contains("openai.com") { return "ChatGPT" }
        if host.contains("claude.ai") { return "Claude" }
        if host.contains("grok.com") || host.hasSuffix("x.com") { return "Grok" }
        if host.contains("gemini") || host == "g.co" { return "Gemini" }
        if host.contains("perplexity") { return "Perplexity" }
        if host.contains("copilot") { return "Copilot" }
        if host.contains("mistral") { return "Le Chat" }
        if host.contains("deepseek") { return "DeepSeek" }
        return nil
    }

    // MARK: Extraction

    static func extractConversation(from html: String) -> String {
        var found: [String] = []
        var seen = Set<String>()

        func keep(_ candidate: String) {
            let trimmed = candidate.trimmingCharacters(in: .whitespacesAndNewlines)
            guard isProse(trimmed) else { return }
            let key = String(trimmed.prefix(120))
            guard !seen.contains(key) else { return }
            seen.insert(key)
            found.append(trimmed)
        }

        // 1. String literals inside scripts (JSON / streamed data), unescaped up to twice.
        collectStrings(in: html, depth: 0, into: keep)

        // 2. Server-rendered visible text, for pages that put the messages in the HTML.
        if found.joined().count < 300 {
            visibleText(in: html).forEach(keep)
        }

        // Longest conversations first would scramble the order: keep page order, cap the size.
        var total = 0
        var result: [String] = []
        for part in found where total < 20_000 {
            result.append(part)
            total += part.count
        }
        return result.joined(separator: "\n")
    }

    private static let stringLiteral = try! NSRegularExpression(pattern: #""((?:[^"\\\n]|\\.){40,})""#)

    private static func collectStrings(in source: String, depth: Int, into keep: (String) -> Void) {
        let range = NSRange(source.startIndex..., in: source)
        stringLiteral.enumerateMatches(in: source, range: range) { match, _, _ in
            guard let match, let inner = Range(match.range(at: 1), in: source) else { return }
            let raw = String(source[inner])
            guard let decoded = decodeJSONString(raw) else { return }
            if depth < 2, decoded.contains("\"") {
                collectStrings(in: decoded, depth: depth + 1, into: keep)
            } else {
                keep(decoded)
            }
        }
    }

    private static func decodeJSONString(_ raw: String) -> String? {
        guard let data = "\"\(raw)\"".data(using: .utf8) else { return nil }
        return try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as? String
    }

    private static func visibleText(in html: String) -> [String] {
        var body = html
        for pattern in ["<script[\\s\\S]*?</script>", "<style[\\s\\S]*?</style>", "<svg[\\s\\S]*?</svg>"] {
            body = body.replacingOccurrences(of: pattern, with: " ", options: [.regularExpression, .caseInsensitive])
        }
        body = body.replacingOccurrences(of: "<(br|/p|/div|/li|/h[1-6])[^>]*>", with: "\n", options: [.regularExpression, .caseInsensitive])
        body = body.replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
        body = body.replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&#x27;", with: "'")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&quot;", with: "\"")
        return body.components(separatedBy: .newlines)
            .map { $0.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression) }
    }

    /// Sentences people wrote, not code, CSS, URLs, IDs or interface labels.
    private static func isProse(_ text: String) -> Bool {
        guard text.count >= 40 else { return false }
        let spaces = text.reduce(0) { $1 == " " ? $0 + 1 : $0 }
        guard spaces >= 6 else { return false }
        let letters = text.unicodeScalars.filter { CharacterSet.letters.contains($0) }.count
        guard Double(letters) / Double(text.count) > 0.6 else { return false }
        let lower = text.lowercased()
        // CSS class lists and SEO keyword lists.
        let words = text.split(separator: " ")
        let technical = words.filter { $0.contains("-") || $0.contains("_") || $0.contains("[") }.count
        if Double(technical) / Double(max(1, words.count)) > 0.3 { return false }
        let commas = text.reduce(0) { $1 == "," ? $0 + 1 : $0 }
        if commas > 8, !text.contains(".") { return false }
        let codeMarkers = ["function(", "=>", "{\"", "};", "px;", "var(--", "http://", "https://", "window.", "document.", "</", "!important"]
        if codeMarkers.contains(where: lower.contains) { return false }
        let boilerplate = ["can make mistakes", "check important info", "cookie", "terms of use", "privacy policy",
                           "enable javascript", "log in", "sign up", "shared conversation", "report conversation",
                           "by messaging", "conversation has been", "this link", "get the app", "try chatgpt",
                           "try claude", "try grok", "gemini apps", "all rights reserved", "use chatgpt to",
                           "chatgpt helps you", "grok is an ai", "built by xai", "built by spacexai", "meet gemini"]
        return !boilerplate.contains(where: lower.contains)
    }
}
