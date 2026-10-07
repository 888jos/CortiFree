//
//  TikTokManager.swift
//  CortiFree
//
//  TikTok App Events SDK integration for ad conversion tracking
//  Events: Registration, ViewContent (paywall), StartTrial, Purchase, LaunchApp, Login, Identify
//  Uses official TikTokBaseEvent / TikTokContentsEvent API
//

import Foundation
import AppTrackingTransparency
#if canImport(TikTokBusinessSDK)
import TikTokBusinessSDK
#endif

final class TikTokManager {
    private enum PendingEvent {
        case identify(userId: String, email: String?)
        case registration(method: String)
        case login
        case viewContent
        case startTrial(productId: String)
        case subscribe(productId: String, price: Double, currency: String)
    }

    static let shared = TikTokManager()
    private var isInitialized = false
    private var didTrackLaunch = false
    private var pendingEvents: [PendingEvent] = []
    private init() {}

    // MARK: - SDK Initialization

    func initialize() {
        #if canImport(TikTokBusinessSDK)
        guard !isInitialized else { return }
        let accessToken = APIConfig.shared.tiktokAccessToken
        guard !accessToken.isEmpty else {
            #if DEBUG
            print("⚠️ TikTok: Access token not configured, skipping initialization")
            #endif
            return
        }

        let config = TikTokConfig(
            accessToken: accessToken,
            appId: APIConfig.shared.tiktokEventAppId,
            tiktokAppId: APIConfig.shared.tiktokAppId
        )
        if ATTrackingManager.trackingAuthorizationStatus != .authorized {
            config?.disableTracking()
        }
        config?.setLogLevel(TikTokLogLevelSuppress)
        #if DEBUG
        config?.enableDebugMode()
        config?.setLogLevel(TikTokLogLevelInfo)
        #endif

        TikTokBusiness.initializeSdk(config)
        isInitialized = true

        if isTrackingAuthorized {
            TikTokBusiness.setTrackingEnabled(true)
            trackLaunchApp()
        }

        #if DEBUG
        print("✅ TikTok SDK initialized (appId: \(APIConfig.shared.tiktokEventAppId), tiktokAppId: \(APIConfig.shared.tiktokAppId))")
        #endif
        #endif
    }

    /// Requests ATT only after the onboarding has established context. TikTok
    /// stays disabled until the user explicitly authorizes cross-app tracking.
    func requestTrackingAuthorizationIfNeeded() {
        #if canImport(TikTokBusinessSDK)
        initialize()

        switch ATTrackingManager.trackingAuthorizationStatus {
        case .authorized:
            enableTrackingAfterConsent()
        case .notDetermined:
            ATTrackingManager.requestTrackingAuthorization { [weak self] status in
                guard status == .authorized else {
                    TikTokBusiness.setTrackingEnabled(false)
                    self?.pendingEvents.removeAll()
                    return
                }
                DispatchQueue.main.async {
                    self?.enableTrackingAfterConsent()
                }
            }
        case .denied, .restricted:
            TikTokBusiness.setTrackingEnabled(false)
            pendingEvents.removeAll()
        @unknown default:
            TikTokBusiness.setTrackingEnabled(false)
            pendingEvents.removeAll()
        }
        #endif
    }

    private var isTrackingAuthorized: Bool {
        ATTrackingManager.trackingAuthorizationStatus == .authorized
    }

    private func enableTrackingAfterConsent() {
        #if canImport(TikTokBusinessSDK)
        guard isInitialized, isTrackingAuthorized else { return }
        TikTokBusiness.setTrackingEnabled(true)
        trackLaunchApp()
        flushPendingEvents()
        #endif
    }

    private func shouldDefer(_ event: PendingEvent) -> Bool {
        guard isInitialized else { return true }
        guard !isTrackingAuthorized else { return false }
        if ATTrackingManager.trackingAuthorizationStatus == .notDetermined {
            pendingEvents.append(event)
        }
        return true
    }

    private func flushPendingEvents() {
        guard isTrackingAuthorized else { return }
        let events = pendingEvents
        pendingEvents.removeAll()
        for event in events {
            switch event {
            case let .identify(userId, email):
                identify(userId: userId, email: email)
            case let .registration(method):
                trackCompleteRegistration(method: method)
            case .login:
                trackLogin()
            case .viewContent:
                trackViewContent()
            case let .startTrial(productId):
                trackStartTrial(productId: productId)
            case let .subscribe(productId, price, currency):
                trackSubscribe(productId: productId, price: price, currency: currency)
            }
        }
    }

    // MARK: - User Identification

    /// Link events to a specific user — call after successful authentication
    func identify(userId: String, email: String? = nil) {
        #if canImport(TikTokBusinessSDK)
        guard !shouldDefer(.identify(userId: userId, email: email)) else { return }
        TikTokBusiness.identify(
            withExternalID: userId,
            externalUserName: nil,
            phoneNumber: nil,
            email: email
        )
        #if DEBUG
        print("📊 TikTok: Identify (userId: \(userId))")
        #endif
        #endif
    }

    /// Clear identity on sign out
    func logout() {
        #if canImport(TikTokBusinessSDK)
        TikTokBusiness.logout()
        #if DEBUG
        print("📊 TikTok: Logout")
        #endif
        #endif
    }

    // MARK: - Standard Events

    /// App launched — call once after SDK init
    func trackLaunchApp() {
        #if canImport(TikTokBusinessSDK)
        guard isInitialized, isTrackingAuthorized, !didTrackLaunch else { return }
        didTrackLaunch = true
        let event = TikTokBaseEvent(eventName: TTEventName.launchAPP.rawValue)
        TikTokBusiness.trackTTEvent(event)
        #if DEBUG
        print("📊 TikTok: LaunchApp")
        #endif
        #endif
    }

    /// User completed authentication (Google/Apple/Email sign in — first time)
    func trackCompleteRegistration(method: String) {
        #if canImport(TikTokBusinessSDK)
        guard !shouldDefer(.registration(method: method)) else { return }
        let event = TikTokBaseEvent(eventName: TTEventName.registration.rawValue)
        TikTokBusiness.trackTTEvent(event)
        #if DEBUG
        print("📊 TikTok: Registration (method: \(method))")
        #endif
        #endif
    }

    /// Returning user logged in (not first registration)
    func trackLogin() {
        #if canImport(TikTokBusinessSDK)
        guard !shouldDefer(.login) else { return }
        let event = TikTokBaseEvent(eventName: TTEventName.login.rawValue)
        TikTokBusiness.trackTTEvent(event)
        #if DEBUG
        print("📊 TikTok: Login")
        #endif
        #endif
    }

    /// User viewed the paywall
    func trackViewContent() {
        #if canImport(TikTokBusinessSDK)
        guard !shouldDefer(.viewContent) else { return }
        let event: TikTokContentsEvent = TikTokViewContentEvent()
        event.setDescription("paywall")
        event.setContentType("paywall")
        TikTokBusiness.trackTTEvent(event)
        #if DEBUG
        print("📊 TikTok: ViewContent (paywall)")
        #endif
        #endif
    }

    /// User started a free trial
    func trackStartTrial(productId: String) {
        #if canImport(TikTokBusinessSDK)
        guard !shouldDefer(.startTrial(productId: productId)) else { return }
        let event = TikTokBaseEvent(eventName: TTEventName.startTrial.rawValue)
        TikTokBusiness.trackTTEvent(event)
        #if DEBUG
        print("📊 TikTok: StartTrial (product: \(productId))")
        #endif
        #endif
    }

    /// User became a paying subscriber (trial → paid, or direct purchase)
    /// Ne pas appeler pour les trials gratuits — utiliser trackStartTrial à la place
    func trackSubscribe(productId: String, price: Double, currency: String) {
        #if canImport(TikTokBusinessSDK)
        guard !shouldDefer(.subscribe(productId: productId, price: price, currency: currency)) else { return }
        let event: TikTokContentsEvent = TikTokPurchaseEvent()
        event.setContentId(productId)
        event.setValue(String(price))
        event.setCurrency(currency == "EUR" ? TTCurrency.EUR : TTCurrency.USD)
        event.setContentType("subscription")
        event.setDescription("CortiFree subscription")

        let content = TikTokContentParams()
        content.price = NSNumber(value: price)
        content.quantity = 1
        content.contentName = productId
        event.setContents([content])

        TikTokBusiness.trackTTEvent(event)
        #if DEBUG
        print("📊 TikTok: Subscribe (product: \(productId), price: \(price) \(currency))")
        #endif
        #endif
    }
}
