//
//  UnifiedFirebaseService.swift
//  CortiFree
//
//  Created by Claude on 24/11/2025.
//  Unified Firebase service coordinator - consolidates all Firebase operations
//

import Foundation
@preconcurrency import FirebaseAuth
import FirebaseFirestore

/// Main coordinator for all Firebase operations
/// Provides access to modular services: auth, userData, progress, analytics
@MainActor
class UnifiedFirebaseService {
    static let shared = UnifiedFirebaseService()

    // MARK: - Modules

    /// Authentication module - sign up, sign in, sign out, password reset
    let auth: AuthModule

    /// User data module - profile, settings, onboarding data (to be implemented)
    // let userData: UserDataModule

    /// Progress module - tasks, habits, routines, stats (to be implemented)
    // let progress: ProgressModule

    /// Analytics module - feedback, insights, background operations (to be implemented)
    // let analytics: AnalyticsModule

    // MARK: - Initialization

    private init() {
        // Initialize Firestore instance (shared across modules)
        let db = Firestore.firestore()

        // Initialize modules
        self.auth = AuthModule()

        // TODO: Initialize other modules
        // self.userData = UserDataModule(db: db)
        // self.progress = ProgressModule(db: db)
        // self.analytics = AnalyticsModule(db: db)

        print("✅ [UnifiedFirebaseService] Initialized with AuthModule")
    }

    // MARK: - Convenience Properties

    /// Current user ID (from AuthModule)
    var currentUserId: String? {
        auth.currentUserId
    }

    /// Is user authenticated (from AuthModule)
    var isAuthenticated: Bool {
        auth.isAuthenticated
    }

    /// Current user (from AuthModule)
    var currentUser: FirebaseAuth.User? {
        auth.currentUser
    }
}
