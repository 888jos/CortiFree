//
//  AuthManager.swift
//  CortiFree
//
//  Created by Claude on 09/11/2025.
//  Firebase Authentication manager
//

import Foundation
@preconcurrency import FirebaseAuth

@MainActor
class AuthManager: ObservableObject {
    static let shared = AuthManager()

    @Published var currentUser: FirebaseAuth.User?
    @Published var isAuthenticated = false

    private init() {
        // Check if user is already signed in
        if let user = Auth.auth().currentUser {
            self.currentUser = user
            self.isAuthenticated = true
            loadUserProfile(uid: user.uid)
        }
    }

    func signUp(email: String, password: String, displayName: String) async throws {
        let authResult = try await Auth.auth().createUser(withEmail: email, password: password)
        let user = authResult.user

        // Update display name
        let changeRequest = user.createProfileChangeRequest()
        changeRequest.displayName = displayName
        try await changeRequest.commitChanges()

        // Create Firestore profile
        try await FirebaseManager.shared.createUserProfile(
            uid: user.uid,
            email: email,
            displayName: displayName
        )

        // Set Mixpanel profile
        MixpanelManager.shared.setUserProfile(
            userId: user.uid,
            email: email,
            routineId: nil,
            level: 1
        )

        // Track signup
        MixpanelManager.shared.trackOnboardingStarted()

        self.currentUser = user
        self.isAuthenticated = true

        print("[Auth] Sign up successful: \(email)")
    }

    func signIn(email: String, password: String) async throws {
        let authResult = try await Auth.auth().signIn(withEmail: email, password: password)
        let user = authResult.user

        // Update last login
        try await FirebaseManager.shared.updateLastLogin(uid: user.uid)

        // Track session
        MixpanelManager.shared.trackSessionStarted()

        self.currentUser = user
        self.isAuthenticated = true

        loadUserProfile(uid: user.uid)

        print("[Auth] Sign in successful: \(email)")
    }

    func signOut() throws {
        try Auth.auth().signOut()

        self.currentUser = nil
        self.isAuthenticated = false
        FirebaseManager.shared.currentUser = nil

        print("[Auth] User signed out")
    }

    func resetPassword(email: String) async throws {
        try await Auth.auth().sendPasswordReset(withEmail: email)
        print("[Auth] Password reset email sent to: \(email)")
    }

    private func loadUserProfile(uid: String) {
        Task {
            do {
                _ = try await FirebaseManager.shared.fetchUserProfile(uid: uid)
            } catch {
                print("Error loading user profile: \(error)")
            }
        }
    }

    // MARK: - Apple Sign In (to be implemented)

    func signInWithApple() async throws {
        // Implementation with Sign in with Apple
        print("[Auth] Apple Sign In - To be implemented")
    }

    // MARK: - Google Sign In (to be implemented)

    func signInWithGoogle() async throws {
        // Implementation with Google Sign In
        print("[Auth] Google Sign In - To be implemented")
    }
}
