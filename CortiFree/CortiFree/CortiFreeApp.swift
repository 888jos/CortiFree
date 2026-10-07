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
import SuperwallKit

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

        // Keep the daily reminders scheduled (they used to be set only from Settings).
        NotificationService.shared.syncDailyNotificationsWithPreference()

        // Register custom fonts
        FontManager.registerFonts()

        // Initialize analytics (Amplitude)
        AnalyticsManager.shared.initialize()

        // Initialize PostHog Analytics
        PostHogManager.shared.initialize()

        // Initialize TikTok App Events SDK
        TikTokManager.shared.initialize()

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

        AnalyticsManager.shared.track(
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

        AnalyticsManager.shared.track(
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

/// Resolves RevenueCat before showing the authenticated app. Only users with an
/// active `pro` entitlement get in; anyone else sees the Superwall paywall and,
/// if they dismiss it, a locked screen (hard paywall). If the subscription status
/// can't be determined (offline / RevenueCat unavailable) we fail open so paying
/// users are never locked out.
private struct AuthenticatedAppRootView: View {
    @ObservedObject private var revenueCat = RevenueCatManager.shared
    @ObservedObject var authViewModel: AuthViewModel
    @State private var accessResolved = false
    @State private var isLocked = false
    @State private var isPresentingPaywall = false
    @State private var isRestoring = false

    var body: some View {
        ZStack {
            if accessResolved {
                ContentView()
                    .environmentObject(authViewModel)
            } else if isLocked {
                SubscriptionLockedView(
                    isRestoring: isRestoring,
                    onUnlock: presentPaywall,
                    onRestore: restorePurchases
                )
            } else {
                GalaxyBackgroundView(intensity: 0.8)
                    .ignoresSafeArea()
                ProgressView()
                    .tint(.white)
            }
        }
        .task {
            await resolveAccess()
        }
        .onChange(of: revenueCat.hasPremiumEntitlement) { _, isPremium in
            if isPremium {
                isLocked = false
                accessResolved = true
            }
        }
    }

    @MainActor
    private func resolveAccess() async {
        guard !accessResolved else { return }

        if !revenueCat.isPremiumStatusReady {
            await revenueCat.refreshCustomerInfo(forceServerFetch: true)
        }

        guard !Task.isCancelled else { return }

        // Active subscribers go straight in. Unknown status fails open.
        if revenueCat.hasPremiumEntitlement || !revenueCat.isPremiumStatusReady {
            accessResolved = true
            return
        }

        presentPaywall()
    }

    /// Lapsed trial/subscribers get the winback offer, everyone else the main campaign.
    @MainActor
    private func presentPaywall() {
        guard !isPresentingPaywall else { return }
        isPresentingPaywall = true

        let placement = revenueCat.hasInactivePreviousProEntitlement
            ? "winback_cancelled_trial"
            : SuperwallPlacement.onboarding

        let handler = PaywallPresentationHandler()
        handler.onDismiss { _, _ in
            Task { @MainActor in finishPaywallPresentation() }
        }
        handler.onSkip { _ in
            Task { @MainActor in finishPaywallPresentation() }
        }
        handler.onError { _ in
            Task { @MainActor in finishPaywallPresentation() }
        }

        Superwall.shared.register(
            placement: placement,
            params: ["source": "authenticated_launch"],
            handler: handler
        ) {
            Task { @MainActor in finishPaywallPresentation() }
        }
    }

    @MainActor
    private func finishPaywallPresentation() {
        isPresentingPaywall = false
        if revenueCat.hasPremiumEntitlement {
            isLocked = false
            accessResolved = true
        } else {
            isLocked = true
        }
    }

    private func restorePurchases() {
        guard !isRestoring else { return }
        isRestoring = true
        Task { @MainActor in
            _ = try? await revenueCat.restorePurchases()
            isRestoring = false
            if revenueCat.hasPremiumEntitlement {
                isLocked = false
                accessResolved = true
            }
        }
    }
}

/// Shown to signed-in users without an active subscription after they close the paywall.
private struct SubscriptionLockedView: View {
    let isRestoring: Bool
    let onUnlock: () -> Void
    let onRestore: () -> Void

    var body: some View {
        ZStack {
            GalaxyBackgroundView(intensity: 0.8)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer()

                Image(systemName: "lock.fill")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(.white)

                Text(LanguageManager.shared.localizedString(for: "access_locked.title"))
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text(LanguageManager.shared.localizedString(for: "access_locked.subtitle"))
                    .font(.system(size: 16))
                    .foregroundStyle(.white.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Spacer()

                Button(action: onUnlock) {
                    Text(LanguageManager.shared.localizedString(for: "access_locked.unlock"))
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(hex: "B794F6"), in: Capsule())
                }
                .padding(.horizontal, 24)

                Button(action: onRestore) {
                    if isRestoring {
                        ProgressView().tint(.white)
                    } else {
                        Text(LanguageManager.shared.localizedString(for: "access_locked.restore"))
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
                .disabled(isRestoring)
                .padding(.bottom, 32)
            }
        }
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
                AuthenticatedAppRootView(authViewModel: authViewModel)
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
                AuthenticatedAppRootView(authViewModel: authViewModel)
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
        AnalyticsManager.shared.track(
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
