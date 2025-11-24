//
//  AuthModule.swift
//  CortiFree
//
//  Created by Claude on 24/11/2025.
//  Unified authentication module - merges AuthService and AuthManager
//

import Foundation
@preconcurrency import FirebaseAuth
import FirebaseFirestore

@MainActor
class AuthModule: ObservableObject {
    private let auth = Auth.auth()
    private let db = Firestore.firestore()

    @Published var currentUser: FirebaseAuth.User?
    @Published var isAuthenticated = false

    init() {
        // Check if user is already signed in
        if let user = auth.currentUser {
            self.currentUser = user
            self.isAuthenticated = true
        }
    }

    // MARK: - State Properties

    var currentUserId: String? {
        currentUser?.uid
    }

    // MARK: - Authentication Methods

    /// Sign up with email, password, and display name
    /// Creates both Firebase Auth user and Firestore profile
    /// Integrates with Mixpanel for analytics
    func signUp(email: String, password: String, displayName: String) async throws -> FirebaseAuth.User {
        do {
            // Create Firebase Auth user
            let authResult = try await auth.createUser(withEmail: email, password: password)
            let user = authResult.user

            // Update display name
            let changeRequest = user.createProfileChangeRequest()
            changeRequest.displayName = displayName
            try await changeRequest.commitChanges()

            // Create Firestore profile
            let userData: [String: Any] = [
                "uid": user.uid,
                "email": email,
                "displayName": displayName,
                "createdAt": Timestamp(date: Date()),
                "lastLoginAt": Timestamp(date: Date()),
                "xp": 0,
                "level": 1,
                "currentStreak": 0,
                "longestStreak": 0
            ]

            try await db.collection("users").document(user.uid).setData(userData)

            // Set Mixpanel profile
            MixpanelManager.shared.identify(userId: user.uid)
            MixpanelManager.shared.trackOnboardingWelcomeViewed()

            // Update state
            self.currentUser = user
            self.isAuthenticated = true

            print("✅ [AuthModule] Sign up successful: \(email)")
            return user

        } catch {
            let coreError = CoreError.from(error)
            print("❌ [AuthModule] Sign up failed: \(coreError)")
            throw coreError
        }
    }

    /// Sign in with email and password
    /// Updates last login timestamp and tracks session in Mixpanel
    func signIn(email: String, password: String) async throws -> FirebaseAuth.User {
        do {
            let authResult = try await auth.signIn(withEmail: email, password: password)
            let user = authResult.user

            // Update last login timestamp
            try await db.collection("users")
                .document(user.uid)
                .updateData(["lastLoginAt": Timestamp(date: Date())])

            // Track session in Mixpanel
            MixpanelManager.shared.trackSessionStarted()

            // Update state
            self.currentUser = user
            self.isAuthenticated = true

            print("✅ [AuthModule] Sign in successful: \(email)")
            return user

        } catch {
            let coreError = CoreError.from(error)
            print("❌ [AuthModule] Sign in failed: \(coreError)")
            throw coreError
        }
    }

    /// Sign out current user
    func signOut() async throws {
        do {
            try auth.signOut()

            // Update state
            self.currentUser = nil
            self.isAuthenticated = false

            print("✅ [AuthModule] User signed out")

        } catch {
            let coreError = CoreError.from(error)
            print("❌ [AuthModule] Sign out failed: \(coreError)")
            throw coreError
        }
    }

    /// Send password reset email
    func resetPassword(email: String) async throws {
        do {
            try await auth.sendPasswordReset(withEmail: email)
            print("✅ [AuthModule] Password reset email sent to: \(email)")

        } catch {
            let coreError = CoreError.from(error)
            print("❌ [AuthModule] Password reset failed: \(coreError)")
            throw coreError
        }
    }

    /// Update user profile (display name)
    func updateUserProfile(displayName: String? = nil) async throws {
        guard let user = currentUser else {
            throw CoreError.userNotFound
        }

        do {
            let changeRequest = user.createProfileChangeRequest()

            if let displayName = displayName {
                changeRequest.displayName = displayName
            }

            try await changeRequest.commitChanges()

            // Refresh currentUser reference
            self.currentUser = auth.currentUser

            print("✅ [AuthModule] Profile updated")

        } catch {
            let coreError = CoreError.from(error)
            print("❌ [AuthModule] Profile update failed: \(coreError)")
            throw coreError
        }
    }

    /// Delete user account
    /// Removes Firestore data and Firebase Auth account
    func deleteAccount() async throws {
        guard let user = currentUser else {
            throw CoreError.userNotFound
        }

        do {
            // Delete Firestore user data
            try await db.collection("users").document(user.uid).delete()

            // Delete Firebase Auth account
            try await user.delete()

            // Update state
            self.currentUser = nil
            self.isAuthenticated = false

            print("✅ [AuthModule] Account deleted")

        } catch {
            let coreError = CoreError.from(error)
            print("❌ [AuthModule] Account deletion failed: \(coreError)")
            throw coreError
        }
    }

    // MARK: - Social Authentication (Future)

    /// Sign in with Apple (to be implemented)
    func signInWithApple() async throws -> FirebaseAuth.User {
        // TODO: Implement Sign in with Apple
        print("⚠️ [AuthModule] Apple Sign In - To be implemented")
        throw CoreError.operationNotAllowed(reason: "Apple Sign In not yet implemented")
    }

    /// Sign in with Google (to be implemented)
    func signInWithGoogle() async throws -> FirebaseAuth.User {
        // TODO: Implement Google Sign In
        print("⚠️ [AuthModule] Google Sign In - To be implemented")
        throw CoreError.operationNotAllowed(reason: "Google Sign In not yet implemented")
    }
}
