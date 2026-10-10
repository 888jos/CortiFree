//
//  AccountDeletionService.swift
//  CortiFree
//
//  In-app account deletion (App Store Review Guideline 5.1.1(v)).
//  Deletes Convex data, authentication rows, third-party identities and local state.
//

import Foundation
import UIKit
import AuthenticationServices
import CryptoKit
import SuperwallKit
import UserNotifications

@MainActor
final class AccountDeletionService {
    static let shared = AccountDeletionService()

    enum DeletionError: LocalizedError {
        case notSignedIn
        case requiresRecentLogin

        var errorDescription: String? {
            switch self {
            case .notSignedIn:
                return LanguageManager.shared.localizedString(for: "settings.delete.not_signed_in")
            case .requiresRecentLogin:
                return LanguageManager.shared.localizedString(for: "settings.delete.recent_login_required")
            }
        }
    }

    enum ReauthMethod {
        case none
        case password
        case apple
        case unsupported
    }

    private var appleReauthenticator: AppleReauthenticator?
    private var appleAuthorizationCode: String?

    private init() {}

    // MARK: - Re-authentication

    func reauthMethod(for user: ConvexUser) -> ReauthMethod {
        let providers = user.providerData.map(\.providerID)
        if providers.contains("apple.com") { return .apple }
        return .none
    }

    func reauthenticateWithPassword(password: String) async throws {
        guard let user = UnifiedFirebaseService.shared.auth.currentUser else { throw DeletionError.notSignedIn }
        guard let email = user.email else { throw DeletionError.requiresRecentLogin }
        _ = try await UnifiedFirebaseService.shared.auth.signIn(email: email, password: password)
    }

    func reauthenticateWithApple() async throws {
        guard UnifiedFirebaseService.shared.auth.currentUser != nil else { throw DeletionError.notSignedIn }
        let reauthenticator = AppleReauthenticator()
        appleReauthenticator = reauthenticator
        defer { appleReauthenticator = nil }

        let result = try await reauthenticator.start()
        _ = try await UnifiedFirebaseService.shared.auth.signInWithApple(
            identityToken: result.idToken,
            rawNonce: result.rawNonce,
            firstName: nil
        )
        appleAuthorizationCode = result.authorizationCode
    }

    // MARK: - Deletion

    func deleteAccount() async throws {
        guard UnifiedFirebaseService.shared.auth.currentUser != nil else { throw DeletionError.notSignedIn }
        try await UnifiedFirebaseService.shared.auth.deleteAccount(appleAuthorizationCode: appleAuthorizationCode)
        appleAuthorizationCode = nil

        await RevenueCatManager.shared.logout()
        Self.resetThirdPartyIdentities()
        Self.clearLocalState()
    }

    // MARK: - Local / third-party cleanup

    /// Clears analytics / paywall identities so the next account isn't linked to this one.
    static func resetThirdPartyIdentities() {
        AnalyticsManager.shared.reset()
        PostHogManager.shared.reset()
        TikTokManager.shared.logout()
        Superwall.shared.reset()
    }

    /// Sign-out: forgets device-level values that belong to the signed-out account (streak, program
    /// start, cached dashboard, check-in, onboarding answers, Health opt-in, widget), so the next
    /// account starts clean. Per-uid caches (plan, completions, anxiety checks) are already keyed by uid.
    @MainActor
    static func clearAccountScopedState() {
        let defaults = UserDefaults.standard
        [
            "streakDays", "bestStreak", "UserSettings", "programStartDate", "currentWeek", "currentDay",
            "progressDashboardCacheV2.lifetime",
            "daily_check_in_last_prompted_day", "daily_check_in_last_completed_day",
            "personalPlan.onboardingProfile.v1", "plan.shortModeDay",
            "userFirstName", "celebration.streak.lastDay"
        ].forEach { defaults.removeObject(forKey: $0) }
        SessionRatingStore.clear()
        OnboardingSync.clear()
        if HealthKitService.shared.isEnabled { HealthKitService.shared.disable() }
        WidgetDataStore.sharedDefaults?.removePersistentDomain(forName: WidgetDataStore.appGroupID)
    }

    /// Removes every locally stored piece of user data, keeping only the UI language.
    static func clearLocalState() {
        let defaults = UserDefaults.standard
        let language = defaults.string(forKey: "selectedLanguage")
        let appleLanguages = defaults.array(forKey: "AppleLanguages")

        if let domain = Bundle.main.bundleIdentifier {
            defaults.removePersistentDomain(forName: domain)
        }
        if let language { defaults.set(language, forKey: "selectedLanguage") }
        if let appleLanguages { defaults.set(appleLanguages, forKey: "AppleLanguages") }

        WidgetDataStore.sharedDefaults?.removePersistentDomain(forName: WidgetDataStore.appGroupID)

        ProgressPhotoStore.shared.deleteAll()
        ProfilePhotoStorage.delete()

        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
}

// MARK: - Sign in with Apple re-authentication

final class AppleReauthenticator: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    struct Result {
        let idToken: String
        let rawNonce: String
        let authorizationCode: String?
    }

    private var continuation: CheckedContinuation<Result, Error>?
    private var rawNonce = ""

    @MainActor
    func start() async throws -> Result {
        rawNonce = Self.randomNonce()
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = []
        request.nonce = Self.sha256(rawNonce)

        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let tokenData = credential.identityToken,
              let idToken = String(data: tokenData, encoding: .utf8) else {
            continuation?.resume(throwing: AccountDeletionService.DeletionError.requiresRecentLogin)
            continuation = nil
            return
        }
        let code = credential.authorizationCode.flatMap { String(data: $0, encoding: .utf8) }
        continuation?.resume(returning: Result(idToken: idToken, rawNonce: rawNonce, authorizationCode: code))
        continuation = nil
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        continuation?.resume(throwing: error)
        continuation = nil
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        return scenes.flatMap(\.windows).first(where: \.isKeyWindow) ?? ASPresentationAnchor()
    }

    private static func randomNonce(length: Int = 32) -> String {
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        while result.count < length {
            var byte: UInt8 = 0
            guard SecRandomCopyBytes(kSecRandomDefault, 1, &byte) == errSecSuccess else { continue }
            if Int(byte) < charset.count * (256 / charset.count) {
                result.append(charset[Int(byte) % charset.count])
            }
        }
        return result
    }

    private static func sha256(_ input: String) -> String {
        SHA256.hash(data: Data(input.utf8)).map { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Local profile photo

enum ProfilePhotoStorage {
    private static var url: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("profile_photo.jpg")
    }

    static func load() -> UIImage? {
        UIImage(contentsOfFile: url.path)
    }

    static func save(_ data: Data) {
        try? FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try? data.write(to: url, options: [.atomic, .completeFileProtection])
    }

    static func delete() {
        try? FileManager.default.removeItem(at: url)
    }

    /// Square-ish JPEG small enough for a Firestore field (well under the 1 MB doc limit).
    static func compressedJPEG(from image: UIImage, maxDimension: CGFloat = 400) -> Data? {
        let scale = min(maxDimension / max(image.size.width, image.size.height), 1.0)
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let resized = UIGraphicsImageRenderer(size: size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
        return resized.jpegData(compressionQuality: 0.7)
    }
}
