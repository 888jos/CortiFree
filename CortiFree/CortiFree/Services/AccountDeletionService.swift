//
//  AccountDeletionService.swift
//  CortiFree
//
//  In-app account deletion (App Store Review Guideline 5.1.1(v)).
//  Deletes users/{uid} (and every known subcollection), top-level docs owned
//  by the user, the Firebase Auth user, third-party identities and local state.
//

import Foundation
import UIKit
import AuthenticationServices
import CryptoKit
import FirebaseAuth
import FirebaseFirestore
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

    private let db = Firestore.firestore()
    private var appleReauthenticator: AppleReauthenticator?

    /// Subcollections of users/{uid} written by the app (see firestore.rules).
    private let userSubcollections = [
        "settings", "baseline", "habit_tracking", "journalEntries", "completed_tasks",
        "tasks", "daily_moods", "task_statuses", "stats", "routine_progress",
        "habit_goals", "habit_badges", "exercises_done", "dailyPrograms",
        "personalized_plan", "daily_checkins", "custom_tasks", "ai_insights",
        "achievements", "onboarding_responses", "feedback", "daily_progress"
    ]

    private init() {}

    // MARK: - Re-authentication

    /// Which re-authentication (if any) is needed before deleting the account.
    /// Firebase requires a sign-in younger than ~5 minutes for `user.delete()`;
    /// asking up front avoids deleting the data and then failing on the Auth user.
    func reauthMethod(for user: FirebaseAuth.User) -> ReauthMethod {
        let providers = user.providerData.map(\.providerID)
        // Apple: always re-authenticate so the Sign in with Apple token can be revoked.
        if providers.contains("apple.com") { return .apple }

        let isRecent = user.metadata.lastSignInDate.map { Date().timeIntervalSince($0) < 4 * 60 } ?? false
        if isRecent { return .none }
        if providers.contains("password") { return .password }
        return .unsupported
    }

    func reauthenticateWithPassword(password: String) async throws {
        guard let user = Auth.auth().currentUser else { throw DeletionError.notSignedIn }
        guard let email = user.email else { throw DeletionError.requiresRecentLogin }
        let credential = EmailAuthProvider.credential(withEmail: email, password: password)
        try await user.reauthenticate(with: credential)
    }

    func reauthenticateWithApple() async throws {
        guard let user = Auth.auth().currentUser else { throw DeletionError.notSignedIn }
        let reauthenticator = AppleReauthenticator()
        appleReauthenticator = reauthenticator
        defer { appleReauthenticator = nil }

        let result = try await reauthenticator.start()
        let credential = OAuthProvider.appleCredential(
            withIDToken: result.idToken,
            rawNonce: result.rawNonce,
            fullName: nil
        )
        try await user.reauthenticate(with: credential)

        // Required by Apple when deleting a Sign in with Apple account.
        // Needs the Apple provider (Services ID + key) configured in the Firebase console.
        if let code = result.authorizationCode {
            do {
                try await Auth.auth().revokeToken(withAuthorizationCode: code)
            } catch {
                #if DEBUG
                print("⚠️ Apple token revocation failed: \(error)")
                #endif
            }
        }
    }

    // MARK: - Deletion

    /// Deletes Firestore data, then the Firebase Auth user, then local/third-party state.
    func deleteAccount() async throws {
        guard let user = Auth.auth().currentUser else { throw DeletionError.notSignedIn }
        let uid = user.uid

        try await deleteUserData(uid: uid)

        do {
            try await user.delete()
        } catch let error as NSError where error.code == AuthErrorCode.requiresRecentLogin.rawValue {
            throw DeletionError.requiresRecentLogin
        }

        await RevenueCatManager.shared.logout()
        Self.resetThirdPartyIdentities()
        Self.clearLocalState()
    }

    private func deleteUserData(uid: String) async throws {
        let userRef = db.collection("users").document(uid)

        // Nested subcollections first (parents can be "phantom" docs that never list).
        try await deleteCollection(userRef.collection("baseline").document("collection").collection("days"))

        var habitIds = Set(TaskStatusService.habitTotals.keys)
        if let habitDocs = try? await userRef.collection("habit_tracking").getDocuments() {
            habitDocs.documents.forEach { habitIds.insert($0.documentID) }
        }
        for habitId in habitIds {
            try await deleteCollection(
                userRef.collection("habit_tracking").document(habitId).collection("daily_completion")
            )
        }

        var routineIds = Set<String>()
        if let routineId = UserPersistence.selectedRoutineId { routineIds.insert(routineId) }
        if let routineDocs = try? await userRef.collection("routine_progress").getDocuments() {
            routineDocs.documents.forEach { routineIds.insert($0.documentID) }
        }
        for routineId in routineIds {
            try await deleteCollection(
                userRef.collection("routine_progress").document(routineId).collection("daily_progress")
            )
        }

        for name in userSubcollections {
            try await deleteCollection(userRef.collection(name))
        }

        // Top-level documents keyed by userId.
        try await deleteQuery(db.collection("dailyTodos").whereField("userId", isEqualTo: uid))

        try await userRef.delete()
    }

    private func deleteCollection(_ collection: CollectionReference) async throws {
        try await deleteQuery(collection)
    }

    private func deleteQuery(_ query: Query) async throws {
        while true {
            let snapshot = try await query.limit(to: 400).getDocuments()
            guard !snapshot.documents.isEmpty else { return }
            let batch = db.batch()
            snapshot.documents.forEach { batch.deleteDocument($0.reference) }
            try await batch.commit()
            if snapshot.documents.count < 400 { return }
        }
    }

    // MARK: - Local / third-party cleanup

    /// Clears analytics / paywall identities so the next account isn't linked to this one.
    static func resetThirdPartyIdentities() {
        AnalyticsManager.shared.reset()
        PostHogManager.shared.reset()
        TikTokManager.shared.logout()
        Superwall.shared.reset()
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
