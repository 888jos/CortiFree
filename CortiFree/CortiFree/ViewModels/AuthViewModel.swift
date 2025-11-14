//
//  AuthViewModel.swift
//  CortiFree
//
//  Created by Claude on 23/10/2025.
//  ViewModel pour gérer l'authentification
//

import Foundation
import FirebaseAuth
import Combine

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: FirebaseAuth.User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    private let authService = AuthService.shared
    private var cancellables = Set<AnyCancellable>()

    init() {
        checkAuthState()
        setupAuthStateListener()
    }

    // Vérifier l'état d'authentification au démarrage
    private func checkAuthState() {
        isAuthenticated = authService.isAuthenticated
        currentUser = authService.currentUser
    }

    // Écouter les changements d'état d'authentification
    private func setupAuthStateListener() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.currentUser = user
                self?.isAuthenticated = user != nil
            }
        }
    }

    // Inscription
    func signUp(email: String, password: String, username: String) async {
        guard !email.isEmpty, !password.isEmpty, !username.isEmpty else {
            errorMessage = "Tous les champs sont requis"
            return
        }

        guard password.count >= 6 else {
            errorMessage = "Le mot de passe doit contenir au moins 6 caractères"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let user = try await authService.signUp(email: email, password: password, username: username)
            currentUser = user
            isAuthenticated = true
            successMessage = "Compte créé avec succès !"
        } catch {
            errorMessage = handleAuthError(error)
        }

        isLoading = false
    }

    // Connexion
    func signIn(email: String, password: String) async {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Email et mot de passe requis"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let user = try await authService.signIn(email: email, password: password)
            currentUser = user
            isAuthenticated = true
            successMessage = "Connexion réussie !"
        } catch {
            errorMessage = handleAuthError(error)
        }

        isLoading = false
    }

    // Déconnexion
    func signOut() {
        do {
            try authService.signOut()
            currentUser = nil
            isAuthenticated = false
            successMessage = "Déconnexion réussie"
        } catch {
            errorMessage = "Erreur lors de la déconnexion"
        }
    }

    // Réinitialiser le mot de passe
    func resetPassword(email: String) async {
        guard !email.isEmpty else {
            errorMessage = "Email requis"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            try await authService.resetPassword(email: email)
            successMessage = "Email de réinitialisation envoyé !"
        } catch {
            errorMessage = handleAuthError(error)
        }

        isLoading = false
    }

    // Gérer les erreurs d'authentification
    private func handleAuthError(_ error: Error) -> String {
        let nsError = error as NSError

        switch nsError.code {
        case AuthErrorCode.emailAlreadyInUse.rawValue:
            return "Cette adresse email est déjà utilisée"
        case AuthErrorCode.invalidEmail.rawValue:
            return "Adresse email invalide"
        case AuthErrorCode.weakPassword.rawValue:
            return "Le mot de passe est trop faible"
        case AuthErrorCode.wrongPassword.rawValue:
            return "Mot de passe incorrect"
        case AuthErrorCode.userNotFound.rawValue:
            return "Aucun compte trouvé avec cet email"
        case AuthErrorCode.networkError.rawValue:
            return "Erreur de connexion. Vérifiez votre connexion internet"
        case AuthErrorCode.tooManyRequests.rawValue:
            return "Trop de tentatives. Réessayez plus tard"
        default:
            return "Erreur: \(error.localizedDescription)"
        }
    }

    // Effacer les messages
    func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }
}
