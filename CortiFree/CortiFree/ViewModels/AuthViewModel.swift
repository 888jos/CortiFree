import Foundation
import Combine

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: ConvexUser?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var hasCompletedOnboarding = false

    private let auth = UnifiedFirebaseService.shared.auth
    private var cancellables = Set<AnyCancellable>()

    init() {
        auth.$currentUser
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                self?.currentUser = user
                self?.isAuthenticated = user != nil
                if let user {
                    self?.hasCompletedOnboarding = user.onboardingCompleted || UserDefaults.standard.bool(forKey: "onboardingV2Completed")
                }
            }
            .store(in: &cancellables)
        currentUser = auth.currentUser
        isAuthenticated = auth.isAuthenticated
        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "onboardingV2Completed")
    }

    func signUp(email: String, password: String, username: String) async {
        guard !email.isEmpty, !password.isEmpty, !username.isEmpty else {
            errorMessage = LanguageManager.shared.localizedString(for: "error.validation.missing_field")
            return
        }
        guard password.count >= convexMinimumPasswordLength else {
            errorMessage = AuthFailure.passwordTooShort.localizedMessage
            return
        }
        await runAuthOperation {
            let user = try await self.auth.signUp(email: email, password: password, displayName: username)
            await RevenueCatManager.shared.identifyUser(userId: user.uid)
            self.successMessage = LanguageManager.shared.localizedString(for: "auth.success.account_created")
        }
    }

    func signIn(email: String, password: String) async {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = LanguageManager.shared.localizedString(for: "error.validation.missing_field")
            return
        }
        await runAuthOperation {
            let user = try await self.auth.signIn(email: email, password: password)
            self.syncOnboardingStatus(userId: user.uid)
            await RevenueCatManager.shared.identifyUser(userId: user.uid)
            self.successMessage = LanguageManager.shared.localizedString(for: "auth.success.login")
        }
    }

    func signOut() {
        Task {
            do {
                await RevenueCatManager.shared.logout()
                try await auth.signOut()
                AccountDeletionService.resetThirdPartyIdentities()
                AccountDeletionService.clearAccountScopedState()
                currentUser = nil
                isAuthenticated = false
                hasCompletedOnboarding = false
                UserDefaults.standard.set(false, forKey: "onboardingV2Completed")
                ["isSubscribed", "subscriptionProductID", "current_subscription_status"].forEach {
                    UserDefaults.standard.removeObject(forKey: $0)
                }
                successMessage = LanguageManager.shared.localizedString(for: "auth.success.logout")
            } catch { handle(error, context: "AuthViewModel.signOut") }
        }
    }

    func resetPassword(email: String) async {
        guard !email.isEmpty else {
            errorMessage = LanguageManager.shared.localizedString(for: "error.validation.missing_field")
            return
        }
        await runAuthOperation {
            try await self.auth.resetPassword(email: email)
            self.successMessage = LanguageManager.shared.localizedString(for: "auth.success.reset_email_sent")
        }
    }

    func clearMessages() { errorMessage = nil; successMessage = nil }

    func syncOnboardingStatus(userId: String) {
        guard let user = auth.currentUser else { return }
        hasCompletedOnboarding = user.onboardingCompleted
        UserDefaults.standard.set(user.onboardingCompleted, forKey: "onboardingV2Completed")
    }

    private func runAuthOperation(_ operation: @escaping @MainActor () async throws -> Void) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do { try await operation() }
        catch { handle(error, context: "AuthViewModel") }
    }

    private func handle(_ error: Error, context: String) {
        let coreError = CoreError.from(error)
        errorMessage = AuthFailure(error).localizedMessage
        ErrorHandler.shared.handle(coreError, context: context, showToUser: false)
    }
}
