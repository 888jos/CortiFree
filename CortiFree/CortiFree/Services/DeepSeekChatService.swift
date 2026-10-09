import Foundation

struct DeepSeekChatMessage: Codable { let role: String; let content: String }

enum DeepSeekChatError: LocalizedError {
    case notConfigured, signedOut, unauthorized, quotaExceeded, offline, unavailable, invalidResponse
    var errorDescription: String? {
        let key: String
        switch self {
        case .notConfigured, .unavailable: key = "assistant.error.unavailable"
        case .signedOut, .unauthorized: key = "assistant.error.signin"
        case .quotaExceeded: key = "assistant.quota.reached"
        case .offline: key = "assistant.error.offline"
        case .invalidResponse: key = "assistant.error.invalid"
        }
        return LanguageManager.shared.localizedString(for: key)
    }
}

@MainActor
final class DeepSeekChatService {
    static let shared = DeepSeekChatService()
    private init() {}
    private struct Response: Decodable { let content: String }

    func reply(to messages: [DeepSeekChatMessage]) async throws -> String {
        guard UnifiedFirebaseService.shared.auth.currentUser != nil else { throw DeepSeekChatError.signedOut }
        let payload = messages.map { ["role": $0.role, "content": $0.content] }
        do {
            let response: Response = try await ConvexBackend.shared.call(
                .action, path: "assistant:chat", args: ["messages": payload]
            )
            return response.content
        } catch let error as URLError where [.notConnectedToInternet, .networkConnectionLost, .timedOut, .dataNotAllowed].contains(error.code) {
            throw DeepSeekChatError.offline
        } catch { throw DeepSeekChatError.unavailable }
    }
}

enum MiloConsent {
    /// v2: the disclosure now covers Apple Health / heart-rate context, so earlier consents are asked again.
    static let storageKey = "milo.consent.v2.uids"
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
