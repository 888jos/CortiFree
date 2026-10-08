import Foundation
import Security

enum ConvexBackendError: LocalizedError {
    case invalidConfiguration
    case invalidResponse
    case server(String)
    case signedOut

    var errorDescription: String? {
        switch self {
        case .invalidConfiguration: return "Convex is not configured."
        case .invalidResponse: return "Invalid response from Convex."
        case .server(let message): return message
        case .signedOut: return "Authentication required."
        }
    }
}

struct ConvexUser: Codable, Identifiable, Sendable {
    struct Provider: Codable, Sendable { let providerID: String }

    let id: String
    let email: String?
    let displayName: String?
    let firstName: String?
    let photoURL: URL?
    let onboardingCompleted: Bool
    let providerData: [Provider]

    var uid: String { id }
}

/// Small source-compatible facade for existing `Auth.auth().currentUser` reads.
@MainActor
enum Auth {
    static func auth() -> AuthModule { UnifiedFirebaseService.shared.auth }
}

private struct ConvexEnvelope<Value: Decodable>: Decodable {
    let status: String
    let value: Value
    let errorMessage: String?
}

private struct AuthTokens: Codable, Sendable {
    let token: String
    let refreshToken: String
}

private struct SignInResult: Decodable {
    let tokens: AuthTokens?
}

private struct ProfileResult: Decodable {
    struct AuthProviders: Decodable {
        let apple: Bool
        let google: Bool
    }

    let _id: String
    let email: String?
    let firstName: String?
    let displayName: String?
    let avatarUrl: String?
    let onboardingCompleted: Bool
    let authProviders: AuthProviders

    var user: ConvexUser {
        var providers: [ConvexUser.Provider] = []
        if authProviders.apple { providers.append(.init(providerID: "apple.com")) }
        if authProviders.google { providers.append(.init(providerID: "google.com")) }
        if providers.isEmpty, email != nil { providers.append(.init(providerID: "password")) }
        return ConvexUser(
            id: _id,
            email: email,
            displayName: displayName,
            firstName: firstName,
            photoURL: avatarUrl.flatMap(URL.init(string:)),
            onboardingCompleted: onboardingCompleted,
            providerData: providers
        )
    }
}

private enum SessionKeychain {
    private static let service = "com.solstys.cortifree.convex"

    static func load() -> AuthTokens? {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "session",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data else { return nil }
        query.removeAll()
        return try? JSONDecoder().decode(AuthTokens.self, from: data)
    }

    static func save(_ tokens: AuthTokens) throws {
        let data = try JSONEncoder().encode(tokens)
        let base: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "session",
        ]
        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
        ]
        let status = SecItemUpdate(base as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            var insert = base
            attributes.forEach { insert[$0.key] = $0.value }
            guard SecItemAdd(insert as CFDictionary, nil) == errSecSuccess else {
                throw ConvexBackendError.invalidResponse
            }
        } else if status != errSecSuccess {
            throw ConvexBackendError.invalidResponse
        }
    }

    static func clear() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "session",
        ]
        SecItemDelete(query as CFDictionary)
    }
}

actor ConvexBackend {
    static let shared = ConvexBackend()

    private let session = URLSession(configuration: .default)
    private var tokens = SessionKeychain.load()
    private var refreshTask: Task<AuthTokens, Error>?

    private var deploymentURL: URL {
        if let value = Bundle.main.object(forInfoDictionaryKey: "CONVEX_URL") as? String,
           let url = URL(string: value), !value.isEmpty {
            return url
        }
        // CONVEX_URL comes from the build configuration (Debug → dev, Release → prod).
        assertionFailure("CONVEX_URL missing from Info.plist")
        return URL(string: "https://compassionate-jackal-621.convex.cloud")!
    }

    var hasCachedSession: Bool { tokens != nil }

    func signUp(email: String, password: String, firstName: String) async throws -> ConvexUser {
        try await authenticate(provider: "password", params: [
            "flow": "signUp", "email": email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
            "password": password, "firstName": firstName,
        ])
    }

    func signIn(email: String, password: String) async throws -> ConvexUser {
        try await authenticate(provider: "password", params: [
            "flow": "signIn", "email": email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
            "password": password,
        ])
    }

    func signInWithApple(identityToken: String, rawNonce: String, firstName: String?) async throws -> ConvexUser {
        var params: [String: Any] = ["identityToken": identityToken, "nonce": rawNonce]
        if let firstName, !firstName.isEmpty { params["firstName"] = firstName }
        return try await authenticate(provider: "apple-native", params: params)
    }

    func signInWithGoogle(idToken: String, firstName: String?) async throws -> ConvexUser {
        var params: [String: Any] = ["idToken": idToken]
        if let firstName, !firstName.isEmpty { params["firstName"] = firstName }
        return try await authenticate(provider: "google-native", params: params)
    }

    func requestPasswordReset(email: String) async throws {
        let _: SignInResult = try await call(
            .action, path: "auth:signIn",
            args: ["provider": "password", "params": ["flow": "reset", "email": email.lowercased()]],
            authenticated: false
        )
    }

    func restoreSession() async throws -> ConvexUser {
        _ = try await refreshTokens()
        return try await loadCurrentUser()
    }

    func loadCurrentUser() async throws -> ConvexUser {
        let profile: ProfileResult? = try await call(.query, path: "profile:me")
        guard let profile else { throw ConvexBackendError.signedOut }
        return profile.user
    }

    func signOut() async {
        if tokens != nil {
            let _: JSONValue? = try? await call(.action, path: "auth:signOut")
        }
        tokens = nil
        SessionKeychain.clear()
    }

    func deleteAccount(appleAuthorizationCode: String? = nil) async throws {
        var args: [String: Any] = [:]
        if let appleAuthorizationCode { args["appleAuthorizationCode"] = appleAuthorizationCode }
        let _: JSONValue = try await call(.action, path: "account:deleteMyAccount", args: args)
        tokens = nil
        SessionKeychain.clear()
    }

    func upload(_ data: Data, to uploadURL: String, contentType: String = "image/jpeg") async throws -> String {
        guard let url = URL(string: uploadURL) else { throw ConvexBackendError.invalidResponse }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        request.httpBody = data
        let (responseData, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode),
              let object = try JSONSerialization.jsonObject(with: responseData) as? [String: Any],
              let storageId = object["storageId"] as? String else {
            throw ConvexBackendError.invalidResponse
        }
        return storageId
    }

    enum FunctionKind: String { case query, mutation, action }

    func call<T: Decodable>(
        _ kind: FunctionKind,
        path: String,
        args: [String: Any] = [:],
        authenticated: Bool = true
    ) async throws -> T {
        var accessToken: String?
        if authenticated {
            guard tokens != nil else { throw ConvexBackendError.signedOut }
            if accessTokenExpiresSoon(tokens?.token) { _ = try await refreshTokens() }
            accessToken = tokens?.token
        }
        return try await perform(kind, path: path, args: args, accessToken: accessToken)
    }

    private func authenticate(provider: String, params: [String: Any]) async throws -> ConvexUser {
        let result: SignInResult = try await call(
            .action, path: "auth:signIn", args: ["provider": provider, "params": params], authenticated: false
        )
        guard let fresh = result.tokens else { throw ConvexBackendError.signedOut }
        tokens = fresh
        try SessionKeychain.save(fresh)
        let _: JSONValue? = try? await call(.mutation, path: "profile:recordLogin", args: [:])
        let _: JSONValue? = try? await call(.mutation, path: "account:claimLegacyData", args: [:])
        return try await loadCurrentUser()
    }

    private func refreshTokens() async throws -> AuthTokens {
        if let refreshTask { return try await refreshTask.value }
        guard let refreshToken = tokens?.refreshToken else { throw ConvexBackendError.signedOut }
        let task = Task<AuthTokens, Error> {
            let result: SignInResult = try await self.perform(
                .action, path: "auth:signIn", args: ["refreshToken": refreshToken], accessToken: nil
            )
            guard let fresh = result.tokens else { throw ConvexBackendError.signedOut }
            return fresh
        }
        refreshTask = task
        defer { refreshTask = nil }
        do {
            let fresh = try await task.value
            tokens = fresh
            try SessionKeychain.save(fresh)
            return fresh
        } catch {
            tokens = nil
            SessionKeychain.clear()
            throw error
        }
    }

    private func perform<T: Decodable>(
        _ kind: FunctionKind,
        path: String,
        args: [String: Any],
        accessToken: String?
    ) async throws -> T {
        let url = deploymentURL.appending(path: "api/\(kind.rawValue)")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let accessToken { request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization") }
        request.httpBody = try JSONSerialization.data(withJSONObject: ["path": path, "args": args, "format": "json"])
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw ConvexBackendError.invalidResponse
        }
        let envelope = try JSONDecoder().decode(ConvexEnvelope<T>.self, from: data)
        guard envelope.status == "success" else {
            throw ConvexBackendError.server(envelope.errorMessage ?? "Convex request failed")
        }
        return envelope.value
    }

    private func accessTokenExpiresSoon(_ token: String?) -> Bool {
        guard let token else { return true }
        let parts = token.split(separator: ".")
        guard parts.count == 3 else { return true }
        var base64 = String(parts[1]).replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        base64 += String(repeating: "=", count: (4 - base64.count % 4) % 4)
        guard let data = Data(base64Encoded: base64),
              let payload = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let exp = payload["exp"] as? TimeInterval else { return true }
        return exp - Date().timeIntervalSince1970 < 300
    }
}

enum JSONValue: Codable, Sendable {
    case null, bool(Bool), number(Double), string(String), array([JSONValue]), object([String: JSONValue])

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() { self = .null }
        else if let value = try? container.decode(Bool.self) { self = .bool(value) }
        else if let value = try? container.decode(Double.self) { self = .number(value) }
        else if let value = try? container.decode(String.self) { self = .string(value) }
        else if let value = try? container.decode([JSONValue].self) { self = .array(value) }
        else { self = .object(try container.decode([String: JSONValue].self)) }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .null: try container.encodeNil()
        case .bool(let value): try container.encode(value)
        case .number(let value): try container.encode(value)
        case .string(let value): try container.encode(value)
        case .array(let value): try container.encode(value)
        case .object(let value): try container.encode(value)
        }
    }
}

extension JSONValue {
    var doubleValue: Double? {
        if case .number(let value) = self { return value }
        return nil
    }

    var arrayValue: [JSONValue]? {
        if case .array(let value) = self { return value }
        return nil
    }

    var foundationValue: Any {
        switch self {
        case .null: return NSNull()
        case .bool(let value): return value
        case .number(let value):
            return value.rounded() == value ? Int(value) : value
        case .string(let value): return value
        case .array(let value): return value.map(\.foundationValue)
        case .object(let value): return value.mapValues(\.foundationValue)
        }
    }
}
