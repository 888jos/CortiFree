//
//  AuthViewModel.swift
//  CortiFree
//
//  Created by Claude on 23/10/2025.
//  ViewModel pour gérer l'authentification
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: FirebaseAuth.User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var hasCompletedOnboarding = false

    private let firebase = UnifiedFirebaseService.shared
    private var cancellables = Set<AnyCancellable>()

    init() {
        checkAuthState()
        setupAuthStateListener()
    }

    // Vérifier l'état d'authentification au démarrage
    private func checkAuthState() {
        isAuthenticated = firebase.auth.isAuthenticated
        currentUser = firebase.auth.currentUser

        // Vérifier le statut d'onboarding local
        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "onboardingV2Completed")

        // Si authentifié et onboarding pas encore marqué localement, synchroniser avec Firestore
        if isAuthenticated, !hasCompletedOnboarding, let user = currentUser {
            Task {
                await syncOnboardingStatus(userId: user.uid)
            }
        }
    }

    // Écouter les changements d'état d'authentification
    private var authStateListenerHandle: AuthStateDidChangeListenerHandle?

    private func setupAuthStateListener() {
        authStateListenerHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.currentUser = user
                self?.isAuthenticated = user != nil
            }
        }
    }

    deinit {
        if let handle = authStateListenerHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    // Inscription
    func signUp(email: String, password: String, username: String) async {
        guard !email.isEmpty, !password.isEmpty, !username.isEmpty else {
            errorMessage = NSLocalizedString("error.validation.missing_field", comment: "")
            return
        }

        guard password.count >= 6 else {
            errorMessage = NSLocalizedString("error.auth.weak_password", comment: "")
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let user = try await firebase.auth.signUp(email: email, password: password, displayName: username)
            currentUser = user
            isAuthenticated = true
            successMessage = NSLocalizedString("auth.success.account_created", comment: "")

            // Identify user in RevenueCat with Firebase UID
            await RevenueCatManager.shared.identifyUser(userId: user.uid)
        } catch let error as CoreError {
            errorMessage = error.errorDescription
            ErrorHandler.shared.handle(error, context: "AuthViewModel.signUp", showToUser: false)
        } catch {
            errorMessage = error.localizedDescription
            ErrorHandler.shared.handle(error, context: "AuthViewModel.signUp", showToUser: false)
        }

        isLoading = false
    }

    // Connexion
    func signIn(email: String, password: String) async {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = NSLocalizedString("error.validation.missing_field", comment: "")
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let user = try await firebase.auth.signIn(email: email, password: password)
            currentUser = user

            // Vérifier si l'utilisateur a déjà complété l'onboarding
            await syncOnboardingStatus(userId: user.uid)

            // Identify user in RevenueCat with Firebase UID
            await RevenueCatManager.shared.identifyUser(userId: user.uid)

            isAuthenticated = true
            successMessage = NSLocalizedString("auth.success.login", comment: "")
        } catch let error as CoreError {
            errorMessage = error.errorDescription
            ErrorHandler.shared.handle(error, context: "AuthViewModel.signIn", showToUser: false)
        } catch {
            errorMessage = error.localizedDescription
            ErrorHandler.shared.handle(error, context: "AuthViewModel.signIn", showToUser: false)
        }

        isLoading = false
    }

    // Déconnexion
    func signOut() {
        Task {
            do {
                // Logout from RevenueCat FIRST (before Firebase sign out)
                await RevenueCatManager.shared.logout()

                try await firebase.auth.signOut()

                currentUser = nil
                isAuthenticated = false
                hasCompletedOnboarding = false
                UserDefaults.standard.set(false, forKey: "onboardingV2Completed")

                // Clean any legacy local subscription flags
                UserDefaults.standard.removeObject(forKey: "isSubscribed")
                UserDefaults.standard.removeObject(forKey: "subscriptionProductID")
                UserDefaults.standard.removeObject(forKey: "current_subscription_status")

                successMessage = NSLocalizedString("auth.success.logout", comment: "")
            } catch let error as CoreError {
                errorMessage = error.errorDescription
                ErrorHandler.shared.handle(error, context: "AuthViewModel.signOut", showToUser: false)
            } catch {
                errorMessage = error.localizedDescription
                ErrorHandler.shared.handle(error, context: "AuthViewModel.signOut", showToUser: false)
            }
        }
    }

    // Réinitialiser le mot de passe
    func resetPassword(email: String) async {
        guard !email.isEmpty else {
            errorMessage = NSLocalizedString("error.validation.missing_field", comment: "")
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            try await firebase.auth.resetPassword(email: email)
            successMessage = NSLocalizedString("auth.success.reset_email_sent", comment: "")
        } catch let error as CoreError {
            errorMessage = error.errorDescription
            ErrorHandler.shared.handle(error, context: "AuthViewModel.resetPassword", showToUser: false)
        } catch {
            errorMessage = error.localizedDescription
            ErrorHandler.shared.handle(error, context: "AuthViewModel.resetPassword", showToUser: false)
        }

        isLoading = false
    }

    // Effacer les messages
    func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }

    // Synchroniser le statut d'onboarding avec Firestore
    func syncOnboardingStatus(userId: String) async {
        do {
            let db = Firestore.firestore()
            let document = try await db.collection("users").document(userId).getDocument()

            if let data = document.data(),
               let onboardingCompleted = data["onboardingCompleted"] as? Bool,
               onboardingCompleted {
                // L'utilisateur a déjà fait l'onboarding, mettre à jour UserDefaults
                UserDefaults.standard.set(true, forKey: "onboardingV2Completed")
                hasCompletedOnboarding = true
                #if DEBUG
                print("✅ Onboarding déjà complété - synchronisé depuis Firestore")
                #endif
            }
        } catch {
            #if DEBUG
            print("⚠️ Impossible de vérifier le statut d'onboarding: \(error.localizedDescription)")
            #endif
        }
    }
}
