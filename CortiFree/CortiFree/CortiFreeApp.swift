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
import RevenueCat
import UserNotifications
#if canImport(GoogleSignIn)
import GoogleSignIn
#endif
#if canImport(Mixpanel)
import Mixpanel
#endif

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {

        // Configure Firebase ONLY - NO Firestore settings to avoid crash
        FirebaseApp.configure()

        // DO NOT configure Firestore settings here - it crashes the app
        // Firestore will use default settings

        // Set notification delegate
        UNUserNotificationCenter.current().delegate = self

        // Configure RevenueCat SDK
        #if DEBUG
        print("🔧 Configuring RevenueCat SDK")
        #endif
        Task { @MainActor in
            RevenueCatManager.shared.configure()
        }

        // Configurer Superwall (toujours actif)
        Superwall.configure(apiKey: APIConfig.shared.superwallAPIKey)
        Logger.success("Superwall configured", category: .subscription)

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

    // MARK: - UNUserNotificationCenterDelegate

    /// User tapped notification
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let notificationId = response.notification.request.identifier

        MixpanelManager.shared.track(
            event: "notification_clicked",
            properties: [
                "notification_id": notificationId,
                "action": response.actionIdentifier
            ]
        )

        #if DEBUG
        print("🔔 Notification clicked: \(notificationId)")
        #endif

        completionHandler()
    }

    /// Notification received while app in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let notificationId = notification.request.identifier

        MixpanelManager.shared.track(
            event: "notification_received",
            properties: [
                "notification_id": notificationId,
                "app_state": "foreground"
            ]
        )

        #if DEBUG
        print("🔔 Notification received (foreground): \(notificationId)")
        #endif

        // Show notification banner and play sound even when app is in foreground
        completionHandler([.banner, .sound])
    }
}

@main
struct CortiFreeApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authViewModel = AuthViewModel()
    @Environment(\.scenePhase) private var scenePhase

    // DEBUG: Set to true to skip onboarding and go directly to HomeView
    #if DEBUG
    private let skipOnboardingForTesting = true
    #else
    private let skipOnboardingForTesting = false
    #endif

    var body: some Scene {
        WindowGroup {
            if authViewModel.isAuthenticated {
                // User is authenticated - check if onboarding is completed (local or synced from Firestore)
                if skipOnboardingForTesting || authViewModel.hasCompletedOnboarding || UserDefaults.standard.bool(forKey: "onboardingV2Completed") {
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
        .onChange(of: scenePhase) { oldPhase, newPhase in
            handleScenePhaseChange(oldPhase: oldPhase, newPhase: newPhase)
        }
    }

    // MARK: - Scene Phase Handling

    private func handleScenePhaseChange(oldPhase: ScenePhase, newPhase: ScenePhase) {
        switch newPhase {
        case .background:
            // User left the app - schedule re-engagement notifications if onboarding incomplete
            scheduleReengagementIfNeeded()

        case .active:
            #if DEBUG
            print("📱 App became active")
            #endif

        case .inactive:
            break

        @unknown default:
            break
        }
    }

    private func scheduleReengagementIfNeeded() {
        // Only schedule if onboarding is NOT complete
        let onboardingCompleted = UserDefaults.standard.bool(forKey: "onboardingV2Completed")

        if !onboardingCompleted {
            NotificationService.shared.scheduleOnboardingReengagementNotifications()
            #if DEBUG
            print("📱 App went to background - re-engagement notifications scheduled")
            #endif
        } else {
            #if DEBUG
            print("📱 App went to background - onboarding complete, no re-engagement needed")
            #endif
        }
    }
}
