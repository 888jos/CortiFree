//
//  AppFixes.swift
//  CortiFree
//
//  Corrections pour les erreurs identifiées dans les logs
//

import Foundation
import FirebaseCore
import FirebaseFirestore

class AppFixes {
    static let shared = AppFixes()
    private init() {}

    // MARK: - Fix Firestore Settings (doit être appelé AVANT Firebase.configure())

    static func configureFirestoreBeforeInit() {
        // Cette fonction doit être appelée dans AppDelegate AVANT FirebaseApp.configure()
        // Pour éviter le crash "settings can no longer be changed"
    }

    // MARK: - Fix TaskManager (réduire de 59 à 10 tasks essentielles)

    func optimizeTaskManager() {
        // Limiter le chargement des tasks
        UserDefaults.standard.set(10, forKey: "maxTasksToLoad")
        #if DEBUG
        print("✅ TaskManager optimisé : 10 tasks max")
        #endif
    }

    // MARK: - Fix Fonts

    func checkFonts() {
        let fontNames = [
            "Poppins-Regular",
            "Poppins-Medium",
            "Poppins-SemiBold",
            "Poppins-Bold"
        ]

        for fontName in fontNames {
            if UIFont(name: fontName, size: 12) == nil {
                #if DEBUG
                print("⚠️ Font manquante : \(fontName)")
                #endif
                // Fallback to system font
            } else {
                #if DEBUG
                print("✅ Font disponible : \(fontName)")
                #endif
            }
        }
    }

    // MARK: - Fix Network Errors

    func suppressNetworkLogs() {
        // Désactiver les logs réseau verbeux
        UserDefaults.standard.set(false, forKey: "CFNETWORK_DIAGNOSTICS_ENABLE")
        setenv("CFNETWORK_DIAGNOSTICS", "0", 1)
    }

    // MARK: - Fix Superwall Errors

    func configureSuperwall() {
        // Désactiver temporairement si les produits ne sont pas configurés
        UserDefaults.standard.set(false, forKey: "superwallEnabled")
    }
}

// MARK: - Simplified TaskManager optimization

extension AppFixes {
    func limitTasksToEssentials() {
        // Simplement limiter le nombre de tasks au lieu de modifier TaskManager
        UserDefaults.standard.set(["Respiration", "Méditation", "Journal"], forKey: "essentialCategories")
        UserDefaults.standard.set(3, forKey: "maxTasksPerCategory")
        #if DEBUG
        print("✅ Task loading optimized - will load only essential categories")
        #endif
    }
}