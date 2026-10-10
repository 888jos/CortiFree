import Foundation

struct DeepSeekChatMessage: Codable { let role: String; let content: String }

enum DeepSeekChatError: LocalizedError {
    case notConfigured, signedOut, unauthorized, quotaExceeded, subscriptionRequired, offline, unavailable, invalidResponse
    var errorDescription: String? {
        let key: String
        switch self {
        case .notConfigured, .unavailable: key = "assistant.error.unavailable"
        // No active subscription on the server (expired, or not synced yet): say so instead of « unavailable ».
        case .subscriptionRequired: key = "assistant.error.premium"
        case .signedOut, .unauthorized: key = "assistant.error.signin"
        case .quotaExceeded: key = "assistant.quota.reached"
        case .offline: key = "assistant.error.offline"
        case .invalidResponse: key = "assistant.error.invalid"
        }
        return LanguageManager.shared.localizedString(for: key)
    }
}

/// What Milo is asked to do. The system prompts live on the server (convex/assistant.ts):
/// the app only sends user/assistant turns and these options.
enum MiloRequestKind {
    case chat(context: String, replyLength: MiloReplyLength, hasPlan: Bool, card: (title: String, kind: String, meta: String)?)
    /// « Decode this message »: one user turn with the conversation text.
    case decode(language: String)
    /// Shared document: one user turn with the document text.
    case importDocument(language: String)
}

@MainActor
final class DeepSeekChatService {
    static let shared = DeepSeekChatService()
    private init() {}
    private struct Response: Decodable { let content: String; let remaining: Int? }

    /// Calls left today according to the server (12/day, shared by chat, decode and import).
    private(set) var remainingToday: Int?

    func reply(_ kind: MiloRequestKind, messages: [DeepSeekChatMessage]) async throws -> String {
        guard UnifiedFirebaseService.shared.auth.currentUser != nil else { throw DeepSeekChatError.signedOut }
        // The server accepts at most 24 turns (6000 characters each, 24000 in all): keep the latest ones.
        var turns: [DeepSeekChatMessage] = []
        var total = 0
        for message in messages.reversed() where message.role == "user" || message.role == "assistant" {
            let content = String(message.content.prefix(5000))
            guard turns.count < 20, total + content.utf16.count <= 20_000 else { break }
            total += content.utf16.count
            turns.insert(DeepSeekChatMessage(role: message.role, content: content), at: 0)
        }
        var args: [String: Any] = ["messages": turns.map { ["role": $0.role, "content": $0.content] }]
        switch kind {
        case let .chat(context, replyLength, hasPlan, card):
            args["kind"] = "chat"
            args["context"] = String(context.prefix(7000))
            args["replyLength"] = replyLength == .detailed ? "detailed" : "short"
            args["hasPlan"] = hasPlan
            if let card { args["card"] = ["title": card.title, "kind": card.kind, "meta": card.meta] }
        case let .decode(language):
            args["kind"] = "decode"
            args["language"] = language
        case let .importDocument(language):
            args["kind"] = "import"
            args["language"] = language
        }
        do {
            let response: Response = try await ConvexBackend.shared.call(.action, path: "assistant:chat", args: args)
            if let remaining = response.remaining { remainingToday = remaining }
            return response.content
        } catch let error as URLError where [.notConnectedToInternet, .networkConnectionLost, .timedOut, .dataNotAllowed].contains(error.code) {
            throw DeepSeekChatError.offline
        } catch ConvexBackendError.server(let message) where message == "quota_exceeded" {
            remainingToday = 0
            throw DeepSeekChatError.quotaExceeded
        } catch ConvexBackendError.server(let message) where message == "subscription_required" {
            throw DeepSeekChatError.subscriptionRequired
        } catch { throw DeepSeekChatError.unavailable }
    }
}

enum MiloConsent {
    /// v2: the disclosure covers Apple Health / heart-rate context. v3: voice dictation is sent
    /// to OpenAI for transcription. Each new disclosure asks earlier consents again.
    static let storageKey = "milo.consent.v3.uids"
    static func isGranted(in stored: String, uid: String?) -> Bool {
        guard let uid else { return false }; return stored.split(separator: ",").contains { $0 == uid }
    }
    static func granting(_ uid: String, in stored: String) -> String {
        var ids = stored.split(separator: ",").map(String.init).filter { $0 != uid }; ids.append(uid); return ids.joined(separator: ",")
    }
    static func revoking(_ uid: String, in stored: String) -> String {
        stored.split(separator: ",").map(String.init).filter { $0 != uid }.joined(separator: ",")
    }
}
