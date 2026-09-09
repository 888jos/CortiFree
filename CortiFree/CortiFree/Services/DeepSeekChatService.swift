import Foundation

struct DeepSeekChatMessage: Codable {
    let role: String
    let content: String
}

enum DeepSeekChatError: LocalizedError {
    case notConfigured
    case invalidResponse
    case server(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "The assistant is not configured yet."
        case .invalidResponse:
            return "The assistant returned an unexpected response."
        case .server(let message):
            return message
        }
    }
}

final class DeepSeekChatService {
    static let shared = DeepSeekChatService()
    private init() {}

    private struct RequestBody: Encodable {
        let model: String
        let messages: [DeepSeekChatMessage]
        let temperature: Double
        let stream: Bool
    }

    private struct ResponseBody: Decodable {
        struct Choice: Decodable {
            let message: DeepSeekChatMessage
        }
        let choices: [Choice]
    }

    func reply(to messages: [DeepSeekChatMessage]) async throws -> String {
        guard let apiKey = APIConfig.shared.deepSeekAPIKey else {
            throw DeepSeekChatError.notConfigured
        }

        var request = URLRequest(url: URL(string: "https://api.deepseek.com/chat/completions")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(RequestBody(
            model: "deepseek-chat",
            messages: messages,
            temperature: 0.6,
            stream: false
        ))

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw DeepSeekChatError.invalidResponse
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            let serverMessage = String(data: data, encoding: .utf8) ?? "Request failed."
            throw DeepSeekChatError.server(serverMessage)
        }

        let decoded = try JSONDecoder().decode(ResponseBody.self, from: data)
        guard let content = decoded.choices.first?.message.content,
              !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw DeepSeekChatError.invalidResponse
        }
        return content
    }
}
