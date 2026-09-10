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

    private struct ResponseBody: Decodable {
        let content: String
    }

    func reply(to messages: [DeepSeekChatMessage]) async throws -> String {
        guard let endpoint = URL(string: "https://us-central1-cortifree-app.cloudfunctions.net/deepSeekChat") else {
            throw DeepSeekChatError.notConfigured
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["messages": messages])

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw DeepSeekChatError.invalidResponse
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            let serverMessage = String(data: data, encoding: .utf8) ?? "Request failed."
            throw DeepSeekChatError.server(serverMessage)
        }

        let decoded = try JSONDecoder().decode(ResponseBody.self, from: data)
        guard !decoded.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw DeepSeekChatError.invalidResponse
        }
        return decoded.content
    }
}
