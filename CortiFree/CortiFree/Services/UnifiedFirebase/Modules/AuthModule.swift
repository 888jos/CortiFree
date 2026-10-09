import Foundation

@MainActor
final class AuthModule: ObservableObject {
    @Published private(set) var currentUser: ConvexUser?
    @Published private(set) var isAuthenticated = false

    private let backend = ConvexBackend.shared
    private var restoreTask: Task<Void, Never>?

    init() {
        // A stored session with a cached profile opens the app right away; the
        // session is then refreshed in the background (see CortiFreeApp).
        if let cached = ConvexBackend.cachedUserForLaunch() { apply(cached) }
    }

    var currentUserId: String? { currentUser?.uid }

    /// Refreshes the stored session. Only a session rejected by the server signs the
    /// user out; offline or slow launches keep the cached profile.
    func restoreSession() async {
        if let restoreTask { return await restoreTask.value }
        let task = Task { @MainActor in
            do {
                apply(try await backend.restoreSession())
            } catch ConvexBackendError.signedOut {
                currentUser = nil
                isAuthenticated = false
            } catch {
                // Keep whatever is cached; the next call will retry.
            }
        }
        restoreTask = task
        await task.value
        restoreTask = nil
    }

    func signUp(email: String, password: String, displayName: String) async throws -> ConvexUser {
        do {
            let user = try await backend.signUp(email: email, password: password, firstName: displayName)
            didAuthenticate(user)
            AnalyticsManager.shared.identify(userId: user.uid)
            AnalyticsManager.shared.trackOnboardingWelcomeViewed()
            return user
        } catch {
            #if DEBUG
            print("❌ AuthModule: \(error)")
            #endif
            throw CoreError.from(error)
        }
    }

    func signIn(email: String, password: String) async throws -> ConvexUser {
        do {
            let user = try await backend.signIn(email: email, password: password)
            didAuthenticate(user)
            AnalyticsManager.shared.trackSessionStarted()
            return user
        } catch {
            #if DEBUG
            print("❌ AuthModule: \(error)")
            #endif
            throw CoreError.from(error)
        }
    }

    func signInWithApple(identityToken: String, rawNonce: String, firstName: String?) async throws -> ConvexUser {
        let user = try await backend.signInWithApple(identityToken: identityToken, rawNonce: rawNonce, firstName: firstName)
        didAuthenticate(user)
        return user
    }

    func signInWithGoogle(idToken: String, firstName: String?) async throws -> ConvexUser {
        let user = try await backend.signInWithGoogle(idToken: idToken, firstName: firstName)
        didAuthenticate(user)
        return user
    }

    func signOut() async throws {
        await backend.signOut()
        currentUser = nil
        isAuthenticated = false
    }

    func resetPassword(email: String) async throws { try await backend.requestPasswordReset(email: email) }

    /// Sets the new password with the emailed code; the user is signed in afterwards.
    func confirmPasswordReset(email: String, code: String, newPassword: String) async throws -> ConvexUser {
        let user = try await backend.confirmPasswordReset(email: email, code: code, newPassword: newPassword)
        didAuthenticate(user)
        AnalyticsManager.shared.trackSessionStarted()
        return user
    }

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

    /// After a fresh sign-in, re-read the full profile shortly after: `ConvexBackend`
    /// falls back to a minimal profile when the first read is slow.
    private func didAuthenticate(_ user: ConvexUser) {
        apply(user)
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2))
            await restoreSession()
        }
    }
}
