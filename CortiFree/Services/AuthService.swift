//
//  AuthService.swift
//  CortiFree
//
//  Created by Claude on 23/10/2025.
//  Service pour gérer l'authentification Firebase
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

class AuthService {
    static let shared = AuthService()

    private let auth = Auth.auth()
    private let db = Firestore.firestore()

    private init() {}

    // Vérifier si un utilisateur est connecté
    var isAuthenticated: Bool {
        return auth.currentUser != nil
    }

    // Obtenir l'utilisateur actuel
    var currentUser: FirebaseAuth.User? {
        return auth.currentUser
    }

    // Inscription avec email et mot de passe
    func signUp(email: String, password: String, username: String) async throws -> FirebaseAuth.User {
        let authResult = try await auth.createUser(withEmail: email, password: password)

        // Créer le profil utilisateur dans Firestore
        let userData: [String: Any] = [
            "uid": authResult.user.uid,
            "email": email,
            "username": username,
            "createdAt": Timestamp(date: Date()),
            "xp": 0,
            "level": 1,
            "currentStreak": 0,
            "longestStreak": 0
        ]

        try await db.collection("users").document(authResult.user.uid).setData(userData)

        return authResult.user
    }

    // Connexion avec email et mot de passe
    func signIn(email: String, password: String) async throws -> FirebaseAuth.User {
        let authResult = try await auth.signIn(withEmail: email, password: password)
        return authResult.user
    }

    // Déconnexion
    func signOut() throws {
        try auth.signOut()
    }

    // Réinitialiser le mot de passe
    func resetPassword(email: String) async throws {
        try await auth.sendPasswordReset(withEmail: email)
    }

    // Mettre à jour le profil utilisateur
    func updateUserProfile(username: String? = nil) async throws {
        guard let user = auth.currentUser else {
            throw NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Aucun utilisateur connecté"])
        }

        let changeRequest = user.createProfileChangeRequest()

        if let username = username {
            changeRequest.displayName = username
        }

        try await changeRequest.commitChanges()
    }

    // Supprimer le compte
    func deleteAccount() async throws {
        guard let user = auth.currentUser else {
            throw NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Aucun utilisateur connecté"])
        }

        // Supprimer les données utilisateur dans Firestore
        try await db.collection("users").document(user.uid).delete()

        // Supprimer le compte Firebase Auth
        try await user.delete()
    }
}
