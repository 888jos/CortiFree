//
//  CortiFreeApp.swift
//  CortiFree
//
//  Created by Josselin Biot on 25/09/2025.
//

import SwiftUI
import UIKit
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import UserNotifications
#if canImport(GoogleSignIn)
import GoogleSignIn
#endif
#if canImport(Mixpanel)
import Mixpanel
#endif
import SuperwallKit
import AppTrackingTransparency

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {

        // Configure Firebase
        FirebaseApp.configure()

        // Enable Firestore offline persistence (must be set before first Firestore access)
        let firestoreSettings = FirestoreSettings()
        firestoreSettings.cacheSettings = PersistentCacheSettings(sizeBytes: 50 * 1024 * 1024 as NSNumber)
        Firestore.firestore().settings = firestoreSettings

        // Set notification delegate
        UNUserNotificationCenter.current().delegate = self

        // Register custom fonts
        FontManager.registerFonts()

        // Initialize Mixpanel Analytics
        MixpanelManager.shared.initialize()

        // Initialize PostHog Analytics
        PostHogManager.shared.initialize()

        // Initialize TikTok App Events SDK
        TikTokManager.shared.initialize()
        TikTokManager.shared.trackLaunchApp()

        // Request App Tracking Transparency (ATT) permission for TikTok attribution
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            ATTrackingManager.requestTrackingAuthorization { status in
                #if DEBUG
                print("📊 ATT status: \(status.rawValue)")
                #endif
            }
        }

        // Configure RevenueCat SDK
        RevenueCatManager.shared.configure()

        // Configure Superwall with RevenueCat as PurchaseController
        let purchaseController = RCPurchaseController()
        let superwallOptions = SuperwallOptions()
        let savedLanguage = UserDefaults.standard.string(forKey: "selectedLanguage") ?? "en"
        superwallOptions.localeIdentifier = savedLanguage == "fr" ? "fr_FR" : "en_US"
        Superwall.configure(
            apiKey: APIConfig.shared.superwallAPIKey,
            purchaseController: purchaseController,
            options: superwallOptions
        )
        if let gender = UserDefaults.standard.string(forKey: "onboarding_gender") {
            Superwall.shared.setUserAttributes(["gender": gender])
        }
        purchaseController.syncSubscriptionStatus()

        // Sync RevenueCat with Firebase user on app launch
        // IMPORTANT: premium is NOT active until identifyUser/getCustomerInfo returns
        if let firebaseUser = Auth.auth().currentUser {
            Task {
                await RevenueCatManager.shared.identifyUser(userId: firebaseUser.uid)
                // Belt-and-suspenders: force server fetch to guarantee isPremiumStatusReady = true
                await RevenueCatManager.shared.refreshCustomerInfo(forceServerFetch: true)
            }
        } else {
            // No Firebase user - force server fetch + load offerings for anonymous user
            Task {
                await RevenueCatManager.shared.refreshCustomerInfo(forceServerFetch: true)
                await RevenueCatManager.shared.loadCurrentOffering()
            }
        }

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
    @State private var showDailyCheckIn = false

    // IMPORTANT: Use @AppStorage to make onboarding completion reactive
    @AppStorage("onboardingV2Completed") private var isOnboardingComplete: Bool = false
    #if DEBUG
    @AppStorage("debugSkipOnboardingToHome") private var debugSkipOnboardingToHome: Bool = false
    #endif

    // DEBUG: Set to true to skip onboarding and go directly to HomeView
    #if DEBUG
    private let skipOnboardingForTesting = false
    #else
    private let skipOnboardingForTesting = false
    #endif

    var body: some Scene {
        WindowGroup {
            Group {
            #if DEBUG
            if debugSkipOnboardingToHome {
                ContentView()
                    .environmentObject(authViewModel)
            } else if !skipOnboardingForTesting && !isOnboardingComplete && !authViewModel.hasCompletedOnboarding {
                OnboardingV2FlowView()
                    .environmentObject(authViewModel)
            } else if authViewModel.isAuthenticated {
                ContentView()
                    .environmentObject(authViewModel)
            } else {
                AuthView()
                    .environmentObject(authViewModel)
            }
            #else
            // First launch: check if onboarding is completed
            // IMPORTANT: Use @AppStorage variable for reactive updates
            if !skipOnboardingForTesting && !isOnboardingComplete && !authViewModel.hasCompletedOnboarding {
                // First time user - show onboarding
                OnboardingV2FlowView()
                    .environmentObject(authViewModel)
            } else if authViewModel.isAuthenticated {
                // User is authenticated and onboarding completed - show main app
                ContentView()
                    .environmentObject(authViewModel)
            } else {
                // Onboarding completed but not authenticated - show auth screens
                AuthView()
                    .environmentObject(authViewModel)
            }
            #endif
            }
            .onOpenURL(perform: handleIncomingURL)
            .onAppear {
                presentDailyCheckInIfNeeded()
            }
            .onChange(of: authViewModel.isAuthenticated) { _, isAuthenticated in
                if isAuthenticated { presentDailyCheckInIfNeeded() }
            }
            .sheet(isPresented: $showDailyCheckIn) {
                DailyCheckInView(targetDate: DailyCheckInService.shared.previousDay())
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(28)
            }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            handleScenePhaseChange(oldPhase: oldPhase, newPhase: newPhase)
        }
    }

    // MARK: - Scene Phase Handling

    private func handleScenePhaseChange(oldPhase: ScenePhase, newPhase: ScenePhase) {
        switch newPhase {
        case .inactive:
            startOnboardingDropOffLiveActivityIfNeeded()

        case .background:
            // User left the app - schedule re-engagement notifications if onboarding incomplete
            startOnboardingDropOffLiveActivityIfNeeded()
            scheduleReengagementIfNeeded()

        case .active:
            // Efface la pastille rouge dès que l'app est ouverte
            UNUserNotificationCenter.current().setBadgeCount(0)
            #if DEBUG
            print("📱 App became active")
            #endif
            presentDailyCheckInIfNeeded()

        @unknown default:
            break
        }
    }

    private func presentDailyCheckInIfNeeded() {
        #if DEBUG
        if ProcessInfo.processInfo.environment["CORTIFREE_DEBUG_DAILY_CHECKIN"] == "1" {
            showDailyCheckIn = true
            return
        }
        #endif
        guard !showDailyCheckIn,
              DailyCheckInService.shared.shouldPresent() else { return }
        DailyCheckInService.shared.markPrompted()
        showDailyCheckIn = true
    }

    private func startOnboardingDropOffLiveActivityIfNeeded() {
        let defaults = UserDefaults.standard
        let onboardingSessionIsActive = defaults.bool(forKey: "onboarding_session_active")
        let onboardingCompleted = defaults.bool(forKey: "onboardingV2Completed")
        let hardPaywallWasViewed = defaults.bool(forKey: "hasSeenPaywall")
        guard onboardingSessionIsActive || !onboardingCompleted || hardPaywallWasViewed else { return }

        let revenueCat = RevenueCatManager.shared
        guard revenueCat.isPremiumStatusReady else { return }
        if revenueCat.hasPremiumEntitlement {
            OnboardingLiveActivityManager.shared.clearLiveGiftOffer()
            return
        }

        let savedStep = max(defaults.integer(forKey: "onboarding_live_activity_step"), 1)
        let savedTotal = max(defaults.integer(forKey: "onboarding_live_activity_total_steps"), 1)
        OnboardingLiveActivityManager.shared.startForOnboardingDropOff(
            currentStep: savedStep,
            totalSteps: savedTotal,
            hasSeenPaywall: hardPaywallWasViewed
        )
    }

    private func handleIncomingURL(_ url: URL) {
        guard url.scheme == "cortifree", url.host == SuperwallPlacement.liveGift else { return }

        let revenueCat = RevenueCatManager.shared
        guard revenueCat.isPremiumStatusReady else {
            Task {
                await revenueCat.refreshCustomerInfo(forceServerFetch: true)
                if revenueCat.isPremiumStatusReady, !revenueCat.hasPremiumEntitlement {
                    presentLiveGiftPaywall()
                } else if revenueCat.hasPremiumEntitlement {
                    OnboardingLiveActivityManager.shared.clearLiveGiftOffer()
                }
            }
            return
        }
        guard !revenueCat.hasPremiumEntitlement else {
            OnboardingLiveActivityManager.shared.clearLiveGiftOffer()
            return
        }

        presentLiveGiftPaywall()
    }

    private func presentLiveGiftPaywall() {
        MixpanelManager.shared.track(
            event: "live_gift_opened",
            properties: ["placement": SuperwallPlacement.liveGift]
        )

        let handler = PaywallPresentationHandler()
        handler.onDismiss { _, result in
            switch result {
            case .purchased, .restored:
                OnboardingLiveActivityManager.shared.clearLiveGiftOffer()
            case .declined:
                break
            }
        }
        Superwall.shared.register(
            placement: SuperwallPlacement.liveGift,
            params: ["source": "live_activity"],
            handler: handler
        )
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
