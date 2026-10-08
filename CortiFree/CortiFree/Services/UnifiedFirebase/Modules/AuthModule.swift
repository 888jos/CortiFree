import Foundation

@MainActor
final class AuthModule: ObservableObject {
    @Published private(set) var currentUser: ConvexUser?
    @Published private(set) var isAuthenticated = false

    private let backend = ConvexBackend.shared

    init() { Task { await restoreSession() } }

    var currentUserId: String? { currentUser?.uid }

    func restoreSession() async {
        do { apply(try await backend.restoreSession()) }
        catch { currentUser = nil; isAuthenticated = false }
    }

    func signUp(email: String, password: String, displayName: String) async throws -> ConvexUser {
        do {
            let user = try await backend.signUp(email: email, password: password, firstName: displayName)
            apply(user)
            AnalyticsManager.shared.identify(userId: user.uid)
            AnalyticsManager.shared.trackOnboardingWelcomeViewed()
            return user
        } catch { throw CoreError.from(error) }
    }

    func signIn(email: String, password: String) async throws -> ConvexUser {
        do {
            let user = try await backend.signIn(email: email, password: password)
            apply(user)
            AnalyticsManager.shared.trackSessionStarted()
            return user
        } catch { throw CoreError.from(error) }
    }

    func signInWithApple(identityToken: String, rawNonce: String, firstName: String?) async throws -> ConvexUser {
        let user = try await backend.signInWithApple(identityToken: identityToken, rawNonce: rawNonce, firstName: firstName)
        apply(user)
        return user
    }

    func signInWithGoogle(idToken: String, firstName: String?) async throws -> ConvexUser {
        let user = try await backend.signInWithGoogle(idToken: idToken, firstName: firstName)
        apply(user)
        return user
    }

    func signOut() async throws {
        await backend.signOut()
        currentUser = nil
        isAuthenticated = false
    }

    func resetPassword(email: String) async throws { try await backend.requestPasswordReset(email: email) }

    func updateUserProfile(displayName: String? = nil) async throws {
        var args: [String: Any] = [:]
        if let displayName { args["displayName"] = displayName }
        let _: JSONValue = try await backend.call(.mutation, path: "profile:updateProfile", args: args)
        apply(try await backend.loadCurrentUser())
    }

    func deleteAccount(appleAuthorizationCode: String? = nil) async throws {
        try await backend.deleteAccount(appleAuthorizationCode: appleAuthorizationCode)
        currentUser = nil
        isAuthenticated = false
    }

    private func apply(_ user: ConvexUser) { currentUser = user; isAuthenticated = true }
}
