import Foundation
import Security

enum ConvexBackendError: LocalizedError {
    case invalidConfiguration
    case invalidResponse
    /// `message` is the function's error (ConvexError data when present, else the raw message).
    case server(String)
    case signedOut
    /// HTTP 401: the access token was rejected.
    case unauthorized

    var errorDescription: String? {
        switch self {
        case .invalidConfiguration: return "Convex is not configured."
        case .invalidResponse: return "Invalid response from Convex."
        case .server(let message): return message
        case .signedOut, .unauthorized: return "Authentication required."
        }
    }
}

/// User-facing reason for an auth failure, derived from Convex Auth's error strings.
enum AuthFailure: Equatable {
    case invalidCredentials, emailInUse, passwordTooShort, invalidEmail, tooManyAttempts
    case invalidCode, network, unknown

    init(_ error: Error) {
        var error = error
        if case .unknown(let wrapped) = error as? CoreError { error = wrapped }
        if let core = error as? CoreError {
            switch core {
            case .invalidCredentials, .userNotFound: self = .invalidCredentials
            case .emailAlreadyInUse: self = .emailInUse
            case .weakPassword: self = .passwordTooShort
            case .networkUnavailable, .timeout, .serverError: self = .network
            default: self = .unknown
            }
            return
        }
        if error is URLError || (error as NSError).domain == NSURLErrorDomain {
            self = .network
            return
        }
        guard case .server(let raw) = error as? ConvexBackendError else {
            self = .unknown
            return
        }
        let message = raw.lowercased()
        if message.contains("invalidaccountid") || message.contains("invalidsecret")
            || message.contains("invalid credentials") || message.contains("invalid password") {
            self = .invalidCredentials
        } else if message.contains("already exists") {
            self = .emailInUse
        } else if message.contains("password must contain") {
            self = .passwordTooShort
        } else if message.contains("invalid email") || message.contains("missing email") {
            self = .invalidEmail
        } else if message.contains("toomanyfailedattempts") {
            self = .tooManyAttempts
        } else if message.contains("invalid code") || message.contains("could not verify code") {
            self = .invalidCode
        } else if message.contains("timed out") {
            self = .network
        } else {
            self = .unknown
        }
    }

    var localizedMessage: String {
        switch self {
        case .invalidCredentials: return "auth.error.invalid_credentials".localized
        case .emailInUse: return "auth.error.email_exists".localized
        case .passwordTooShort: return "auth.error.password_too_short".localized
        case .invalidEmail: return "auth.error.invalid_email".localized
        case .tooManyAttempts: return "auth.error.too_many_attempts".localized
        case .invalidCode: return "auth.reset.invalid_code".localized
        case .network: return "auth.error.network".localized
        case .unknown: return "onboarding_v2.auth.generic_error".localized
        }
    }
}

/// Minimum password length enforced by `convex/auth.ts`.
let convexMinimumPasswordLength = 8

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

/// `value` is only present on success, so it is decoded separately (see `perform`).
private struct ConvexStatus: Decodable {
    let status: String
    let errorMessage: String?
    let errorData: JSONValue?
}

private struct ConvexEnvelope<Value: Decodable>: Decodable {
    let value: Value
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

    /// Never fails the sign-in: if the Keychain refuses the item (e.g. an unsigned
    /// simulator build), the session simply lives in memory for this launch.
    static func save(_ tokens: AuthTokens) {
        do { try write(tokens) } catch {
            #if DEBUG
            print("⚠️ SessionKeychain: \(error)")
            #endif
        }
    }

    private static func write(_ tokens: AuthTokens) throws {
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
            let addStatus = SecItemAdd(insert as CFDictionary, nil)
            guard addStatus == errSecSuccess else {
                throw NSError(domain: NSOSStatusErrorDomain, code: Int(addStatus))
            }
        } else if status != errSecSuccess {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(status))
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

/// Last known profile, so a signed-in user lands in the app immediately at launch
/// (and stays signed in offline) while the session is refreshed in the background.
private enum SessionUserCache {
    private static let key = "convex.cachedUser"

    static func load() -> ConvexUser? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(ConvexUser.self, from: data)
    }

    static func save(_ user: ConvexUser) {
        if let data = try? JSONEncoder().encode(user) { UserDefaults.standard.set(data, forKey: key) }
    }

    static func clear() { UserDefaults.standard.removeObject(forKey: key) }
}

actor ConvexBackend {
    static let shared = ConvexBackend()

    private let session = URLSession(configuration: .default)
    private var tokens = SessionKeychain.load()
    private var refreshTask: Task<AuthTokens, Error>?

    /// Cached profile of the stored session, readable synchronously at launch.
    nonisolated static func cachedUserForLaunch() -> ConvexUser? {
        guard SessionKeychain.load() != nil else { return nil }
        return SessionUserCache.load()
    }

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

    /// Emails an 8-digit code (15 min). An unknown address is reported as success so the
    /// screen never reveals whether an account exists.
    func requestPasswordReset(email: String) async throws {
        do {
            let _: SignInResult = try await call(
                .action, path: "auth:signIn",
                args: ["provider": "password", "params": ["flow": "reset", "email": Self.normalized(email)]],
                authenticated: false
            )
        } catch let error as ConvexBackendError {
            if case .server(let message) = error, message.contains("InvalidAccountId") { return }
            throw error
        }
    }

    /// Second step of the reset: sets the new password and signs the user in.
    func confirmPasswordReset(email: String, code: String, newPassword: String) async throws -> ConvexUser {
        try await authenticate(provider: "password", params: [
            "flow": "reset-verification", "email": Self.normalized(email),
            "code": code.trimmingCharacters(in: .whitespacesAndNewlines), "newPassword": newPassword,
        ])
    }

    /// Resumes the stored session. Throws `.signedOut` only when the server rejected it;
    /// network failures are rethrown as-is and keep the stored session.
    func restoreSession() async throws -> ConvexUser {
        guard tokens != nil else { throw ConvexBackendError.signedOut }
        return try await loadCurrentUser()
    }

    func loadCurrentUser() async throws -> ConvexUser {
        let profile: ProfileResult? = try await call(.query, path: "profile:me")
        guard let profile else {
            // The account no longer exists (deleted on another device).
            clearSession()
            throw ConvexBackendError.signedOut
        }
        let user = profile.user
        SessionUserCache.save(user)
        return user
    }

    func signOut() async {
        if tokens != nil {
            let _: JSONValue? = try? await call(.action, path: "auth:signOut")
        }
        clearSession()
    }

    func deleteAccount(appleAuthorizationCode: String? = nil) async throws {
        var args: [String: Any] = [:]
        if let appleAuthorizationCode { args["appleAuthorizationCode"] = appleAuthorizationCode }
        let _: JSONValue = try await call(.action, path: "account:deleteMyAccount", args: args)
        clearSession()
    }

    private func clearSession() {
        tokens = nil
        SessionKeychain.clear()
        SessionUserCache.clear()
    }

    private static func normalized(_ email: String) -> String {
        email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
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
        guard authenticated else {
            return try await perform(kind, path: path, args: args, accessToken: nil)
        }
        guard tokens != nil else { throw ConvexBackendError.signedOut }
        if accessTokenExpiresSoon(tokens?.token) { _ = try await refreshTokens() }
        do {
            return try await perform(kind, path: path, args: args, accessToken: tokens?.token)
        } catch ConvexBackendError.unauthorized {
            // Token rejected before its expiry (clock skew, key rotation): refresh once and retry.
            let fresh = try await refreshTokens()
            return try await perform(kind, path: path, args: args, accessToken: fresh.token)
        }
    }

    private func authenticate(provider: String, params: [String: Any]) async throws -> ConvexUser {
        let result: SignInResult = try await call(
            .action, path: "auth:signIn", args: ["provider": provider, "params": params], authenticated: false
        )
        guard let fresh = result.tokens else { throw ConvexBackendError.signedOut }
        tokens = fresh
        SessionKeychain.save(fresh)
        let _: JSONValue? = try? await call(.mutation, path: "profile:recordLogin", args: [:])
        let _: JSONValue? = try? await call(.mutation, path: "account:claimLegacyData", args: [:])
        // The session exists from here on: a slow profile read must not report the
        // sign-in as failed (retrying a sign-up would then hit "already exists").
        for delay in [0.4, 1.2] {
            do { return try await loadCurrentUser() } catch ConvexBackendError.signedOut {
                throw ConvexBackendError.signedOut
            } catch {
                try? await Task.sleep(for: .seconds(delay))
            }
        }
        if let user = try? await loadCurrentUser() { return user }
        guard let userId = Self.userId(fromAccessToken: fresh.token) else { throw ConvexBackendError.invalidResponse }
        let email = params["email"] as? String
        let firstName = params["firstName"] as? String
        // Minimal profile until the next restoreSession() fills in the rest.
        let user = ConvexUser(
            id: userId, email: email, displayName: firstName, firstName: firstName, photoURL: nil,
            onboardingCompleted: false,
            providerData: [.init(providerID: provider == "apple-native" ? "apple.com" : provider == "google-native" ? "google.com" : "password")]
        )
        SessionUserCache.save(user)
        return user
    }

    /// Convex Auth access tokens carry `sub = "<userId>|<sessionId>"`.
    private static func userId(fromAccessToken token: String) -> String? {
        guard let payload = jwtPayload(token), let sub = payload["sub"] as? String else { return nil }
        return sub.split(separator: "|").first.map(String.init)
    }

    private static func jwtPayload(_ token: String) -> [String: Any]? {
        let parts = token.split(separator: ".")
        guard parts.count == 3 else { return nil }
        var base64 = String(parts[1]).replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        base64 += String(repeating: "=", count: (4 - base64.count % 4) % 4)
        guard let data = Data(base64Encoded: base64) else { return nil }
        return try? JSONSerialization.jsonObject(with: data) as? [String: Any]
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
            SessionKeychain.save(fresh)
            return fresh
        } catch ConvexBackendError.signedOut {
            // The server rejected the refresh token: the session is really over.
            clearSession()
            throw ConvexBackendError.signedOut
        }
        // Any other failure (offline, timeout) keeps the session for the next attempt.
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
        guard let http = response as? HTTPURLResponse else { throw ConvexBackendError.invalidResponse }
        if http.statusCode == 401 { throw ConvexBackendError.unauthorized }
        guard (200..<300).contains(http.statusCode) else { throw ConvexBackendError.invalidResponse }
        let status = try JSONDecoder().decode(ConvexStatus.self, from: data)
        guard status.status == "success" else {
            // ConvexError payloads carry the readable message in errorData.
            if case .string(let message)? = status.errorData { throw ConvexBackendError.server(message) }
            throw ConvexBackendError.server(status.errorMessage ?? "Convex request failed")
        }
        return try JSONDecoder().decode(ConvexEnvelope<T>.self, from: data).value
    }

    private func accessTokenExpiresSoon(_ token: String?) -> Bool {
        guard let token, let exp = Self.jwtPayload(token)?["exp"] as? TimeInterval else { return true }
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
