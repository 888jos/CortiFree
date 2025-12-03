//
//  CortiFreeApp.swift
//  CortiFree
//
//  Created by Josselin Biot on 25/09/2025.
//

import SwiftUI
import UIKit
import FirebaseCore
import FirebaseFirestore
import SuperwallKit
#if canImport(GoogleSignIn)
import GoogleSignIn
#endif
#if canImport(Mixpanel)
import Mixpanel
#endif

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {

        // Configure Firebase ONLY - NO Firestore settings to avoid crash
        FirebaseApp.configure()

        // DO NOT configure Firestore settings here - it crashes the app
        // Firestore will use default settings

        // Configurer Superwall seulement si activé
        if UserDefaults.standard.bool(forKey: "superwallEnabled") != false {
            Superwall.configure(apiKey: "pk_JPmmC0H5be4yqTnw24VTm")
        }

        // Register custom fonts
        FontManager.registerFonts()

        // Initialize Mixpanel Analytics
        MixpanelManager.shared.initialize()

        // Initialize TaskManager with optimization
        #if DEBUG
        print("🚀 Initializing TaskManager...")
        #endif
        _ = TaskManager.shared

        // Apply fixes
        AppFixes.shared.optimizeTaskManager()
        AppFixes.shared.suppressNetworkLogs()

        return true
    }

    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        #if canImport(GoogleSignIn)
        if GIDSignIn.sharedInstance.handle(url) {
            return true
        }
        #endif
        return false
    }
}

@main
struct CortiFreeApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authViewModel = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            if authViewModel.isAuthenticated {
                // User is authenticated - check if onboarding is completed
                if UserDefaults.standard.bool(forKey: "onboardingV2Completed") {
                    // Onboarding completed - show main app
                    ContentView()
                        .environmentObject(authViewModel)
                } else {
                    // Onboarding not completed - show onboarding flow (includes welcome screen)
                    OnboardingV2FlowView()
                }
            } else {
                // Not authenticated - show auth screens
                AuthView()
                    .environmentObject(authViewModel)
            }
        }
    }
}
