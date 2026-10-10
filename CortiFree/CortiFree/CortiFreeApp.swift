//
//  CortiFreeApp.swift
//  CortiFree
//
//  Created by Josselin Biot on 25/09/2025.
//

import SwiftUI
import UIKit
import UserNotifications
#if canImport(GoogleSignIn)
import GoogleSignIn
#endif
import SuperwallKit

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {

        // Set notification delegate
        UNUserNotificationCenter.current().delegate = self

        // Register custom fonts
        FontManager.registerFonts()

        // iPad: centre the (iPhone) layout in a readable column. No-op on iPhone.
        IPadColumnLayout.install()

        // Initialize analytics (Amplitude)
        AnalyticsManager.shared.initialize()

        // Onboarding writes that didn't reach the server yet (quiz baseline, completion).
        OnboardingSync.start()

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

        // Keep the daily reminders scheduled (they used to be set only from Settings).
        // After Superwall.configure: the reminder copy loads LanguageManager, which updates Superwall.
        NotificationService.shared.syncDailyNotificationsWithPreference()

        // Restore the Convex session before linking RevenueCat to an account.
        Task { @MainActor in
            await UnifiedFirebaseService.shared.auth.restoreSession()
            if let user = UnifiedFirebaseService.shared.auth.currentUser {
                await RevenueCatManager.shared.identifyUser(userId: user.uid)
                await RevenueCatManager.shared.refreshCustomerInfo(forceServerFetch: true)
            } else {
                await RevenueCatManager.shared.refreshCustomerInfo(forceServerFetch: true)
                await RevenueCatManager.shared.loadCurrentOffering()
            }
        }

        // Initialize TaskManager with optimization
        #if DEBUG
        print("🚀 Initializing TaskManager...")
        #endif
        _ = TaskManager.shared

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
        let userInfo = response.notification.request.content.userInfo

        AnalyticsManager.shared.track(
            event: "notification_clicked",
            properties: [
                "notification_id": notificationId,
                "action": response.actionIdentifier,
                "campaign": userInfo["campaign"] as? String ?? "",
                "message_id": userInfo["message_id"] as? String ?? "",
                "segment": userInfo["segment"] as? String ?? ""
            ]
        )
        if response.actionIdentifier == UNNotificationDefaultActionIdentifier {
            Task { @MainActor in NotificationRouter.shared.handle(userInfo: userInfo) }
        }

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

        // Recovery notifications ask the user to come back: pointless while they're here.
        if notificationId.hasPrefix("recovery_") {
            completionHandler([])
            return
        }

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
    @State private var showsTrialKickoff = TrialKickoff.isPending

    var body: some View {
        ZStack {
            if accessResolved {
                ContentView()
                    .environmentObject(authViewModel)
                    .fullScreenCover(isPresented: $showsTrialKickoff) {
                        TrialKickoffView { showsTrialKickoff = false }
                    }
            } else if isLocked {
                SubscriptionLockedView(
                    authViewModel: authViewModel,
                    hasSubscribedBefore: revenueCat.customerInfo?.entitlements.all.isEmpty == false,
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
/// Keeps the legal links and account controls reachable (guidelines 3.1.2 and 5.1.1(v)).
private struct SubscriptionLockedView: View {
    @ObservedObject var authViewModel: AuthViewModel
    /// False for users who never had an entitlement: no "your subscription has ended".
    let hasSubscribedBefore: Bool
    let isRestoring: Bool
    let onUnlock: () -> Void
    let onRestore: () -> Void

    @State private var showSignOutAlert = false
    @State private var showAccountDeletion = false

    private func t(_ key: String) -> String { LanguageManager.shared.localizedString(for: key) }

    var body: some View {
        ZStack {
            GalaxyBackgroundView(intensity: 0.8)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer()

                Image(systemName: "lock.fill")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(.white)

                Text(t(hasSubscribedBefore ? "access_locked.title" : "access_locked.title_new"))
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text(t(hasSubscribedBefore ? "access_locked.subtitle" : "access_locked.subtitle_new"))
                    .font(.system(size: 16))
                    .foregroundStyle(.white.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Spacer()

                Button(action: onUnlock) {
                    Text(t(hasSubscribedBefore ? "access_locked.unlock" : "access_locked.unlock_new"))
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

                VStack(spacing: 10) {
                    HStack(spacing: 20) {
                        footerLink(t("paywall_custom.footer_terms")) { LegalDocumentsHelper.openTerms() }
                        footerLink(t("paywall_custom.footer_privacy")) { LegalDocumentsHelper.openPrivacyPolicy() }
                    }
                    HStack(spacing: 20) {
                        footerLink(t("settings.signout")) { showSignOutAlert = true }
                        footerLink(t("settings.delete_account")) { showAccountDeletion = true }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
        .alert(t("settings.alert.signout.title"), isPresented: $showSignOutAlert) {
            Button(t("common.cancel"), role: .cancel) {}
            Button(t("settings.alert.signout.title"), role: .destructive) { authViewModel.signOut() }
        } message: {
            Text(t("settings.alert.signout.message"))
        }
        // Settings runs the full deletion flow (confirmation, re-authentication, errors).
        .sheet(isPresented: $showAccountDeletion) {
            SettingsView(promptsAccountDeletion: true)
                .environmentObject(authViewModel)
        }
    }

    private func footerLink(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.6))
                .underline()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .buttonStyle(.plain)
    }
}

private enum CheckInDrawer: String, Identifiable {
    case daily, weekly
    var id: String { rawValue }
}

@main
struct CortiFreeApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authViewModel = AuthViewModel()
    @Environment(\.scenePhase) private var scenePhase
    @State private var checkIn: CheckInDrawer?

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
            .onReceive(NotificationRouter.shared.$pendingURL.compactMap { $0 }) { url in
                NotificationRouter.shared.pendingURL = nil
                handleIncomingURL(url)
            }
            .onAppear {
                presentDailyCheckInIfNeeded()
            }
            .onChange(of: authViewModel.isAuthenticated) { _, isAuthenticated in
                if isAuthenticated { presentDailyCheckInIfNeeded() }
            }
            .sheet(item: $checkIn, onDismiss: presentWeeklyCheckInIfNeeded) { drawer in
                Group {
                    switch drawer {
                    case .daily: DailyCheckInView(targetDate: Date())
                    case .weekly: WeeklyCheckInView()
                    }
                }
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
            RecoveryScheduler.shared.appDidEnterBackground()

        case .active:
            // Efface la pastille rouge dès que l'app est ouverte
            UNUserNotificationCenter.current().setBadgeCount(0)
            RecoveryScheduler.shared.appDidBecomeActive()
            #if DEBUG
            print("📱 App became active")
            #endif
            presentDailyCheckInIfNeeded()

        @unknown default:
            break
        }
    }

    /// First app open of the day: the daily check-in drawer, then the weekly one when due.
    private func presentDailyCheckInIfNeeded() {
        guard checkIn == nil, !TrialKickoff.isPending else { return }
        #if DEBUG
        if ProcessInfo.processInfo.environment["CORTIFREE_DEBUG_DAILY_CHECKIN"] == "1" {
            checkIn = .daily
            return
        }
        if ProcessInfo.processInfo.environment["CORTIFREE_DEBUG_WEEKLY_CHECKIN"] == "1" {
            checkIn = .weekly
            return
        }
        #endif
        if DailyCheckInService.shared.shouldPresent() {
            DailyCheckInService.shared.markPrompted()
            checkIn = .daily
        } else {
            presentWeeklyCheckInIfNeeded()
        }
    }

    private func presentWeeklyCheckInIfNeeded() {
        guard WeeklyCheckInService.shared.shouldPresent() else { return }
        WeeklyCheckInService.shared.markPrompted()
        // Let the previous drawer finish closing before opening the next one.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            if checkIn == nil { checkIn = .weekly }
        }
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
        guard url.scheme == "cortifree" else { return }
        let query = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        let messageID = query.first { $0.name == "message_id" }?.value ?? ""
        switch url.host {
        case "paywall":
            let requested = query.first { $0.name == "placement" }?.value ?? SuperwallPlacement.onboarding
            presentRecoveryPaywall(requested: requested, messageID: messageID)
            return
        case "onboarding":
            // The onboarding resumes from its saved checkpoint on its own.
            AnalyticsManager.shared.track(event: "recovery_onboarding_resumed", properties: ["message_id": messageID])
            return
        case SuperwallPlacement.liveGift:
            break
        default:
            return
        }

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

    /// Paywall opened from a recovery notification. Expired offers and placements missing
    /// from the Superwall dashboard fall back to the main paywall.
    private func presentRecoveryPaywall(requested: String, messageID: String) {
        Task { @MainActor in
            let revenueCat = RevenueCatManager.shared
            if !revenueCat.isPremiumStatusReady {
                await revenueCat.refreshCustomerInfo(forceServerFetch: true)
            }
            guard revenueCat.isPremiumStatusReady, !revenueCat.hasPremiumEntitlement else { return }

            let placement = RecoveryScheduler.shared.placementToPresent(for: requested)
            AnalyticsManager.shared.track(event: "recovery_paywall_opened", properties: [
                "requested_placement": requested, "placement": placement, "message_id": messageID
            ])
            registerRecoveryPlacement(placement, messageID: messageID)
        }
    }

    private func registerRecoveryPlacement(_ placement: String, messageID: String) {
        let handler = PaywallPresentationHandler()
        handler.onSkip { reason in
            guard placement != SuperwallPlacement.onboarding else { return }
            switch reason {
            case .placementNotFound, .noAudienceMatch:
                Task { @MainActor in registerRecoveryPlacement(SuperwallPlacement.onboarding, messageID: messageID) }
            default:
                break
            }
        }
        Superwall.shared.register(
            placement: placement,
            params: ["source": "recovery_notification", "message_id": messageID],
            handler: handler
        )
    }
}
