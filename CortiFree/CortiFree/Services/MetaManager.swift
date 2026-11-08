//
//  MetaManager.swift
//  CortiFree
//
//  Meta (Facebook/Instagram) App Events for ad conversion tracking.
//  Events: CompleteRegistration, ViewContent (pre-paywall), StartTrial, Subscribe.
//  Install and app opens are logged automatically by the SDK.
//
//  Unlike TikTok, events are sent right away, before the tracking prompt: without ATT the
//  SDK sends no advertising identifier and Meta measures them through Aggregated Event
//  Measurement. The trial starts on day 1 while the ATT prompt only comes on day 2, so
//  deferring would lose most trials.
//
//  Renewals and trial conversions happen on Apple's servers: RevenueCat sends them to Meta
//  (RevenueCat dashboard → Integrations → Meta Ads), linked through the anonymous ID below.
//

import Foundation
import UIKit
#if canImport(FacebookCore)
import FacebookCore
#endif
import RevenueCat

final class MetaManager {
    static let shared = MetaManager()
    private var isInitialized = false
    private init() {}

    // MARK: - SDK Initialization

    func initialize(application: UIApplication, launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        #if canImport(FacebookCore)
        guard !isInitialized else { return }
        let appId = APIConfig.shared.metaAppId
        let clientToken = APIConfig.shared.metaClientToken
        guard !appId.isEmpty, !clientToken.isEmpty else {
            #if DEBUG
            print("⚠️ Meta: App ID or client token not configured, skipping initialization")
            #endif
            return
        }

        Settings.shared.appID = appId
        Settings.shared.clientToken = clientToken
        Settings.shared.displayName = "CortiFree"
        Settings.shared.isAutoLogAppEventsEnabled = true
        Settings.shared.isAdvertiserIDCollectionEnabled = true
        #if DEBUG
        Settings.shared.enableLoggingBehavior(.appEvents)
        #endif

        ApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: launchOptions)
        isInitialized = true

        #if DEBUG
        print("✅ Meta SDK initialized (appId: \(appId))")
        #endif
        #endif
    }

    /// Lets RevenueCat send server-side subscription events (renewals, trial conversions)
    /// to Meta for the same person. Call after RevenueCat is configured.
    func linkRevenueCat() {
        #if canImport(FacebookCore)
        guard isInitialized else { return }
        Purchases.shared.attribution.setFBAnonymousID(AppEvents.shared.anonymousID)
        Purchases.shared.attribution.collectDeviceIdentifiers()
        #endif
    }

    // MARK: - User Identification

    func identify(userId: String) {
        #if canImport(FacebookCore)
        guard isInitialized else { return }
        AppEvents.shared.userID = userId
        #endif
    }

    func logout() {
        #if canImport(FacebookCore)
        guard isInitialized else { return }
        AppEvents.shared.userID = nil
        #endif
    }

    // MARK: - Standard Events

    func trackCompleteRegistration(method: String) {
        #if canImport(FacebookCore)
        guard isInitialized else { return }
        AppEvents.shared.logEvent(.completedRegistration, parameters: [.registrationMethod: method])
        #if DEBUG
        print("📊 Meta: CompleteRegistration (method: \(method))")
        #endif
        #endif
    }

    /// The pre-paywall (plan) was seen.
    func trackViewContent() {
        #if canImport(FacebookCore)
        guard isInitialized else { return }
        AppEvents.shared.logEvent(.viewedContent, parameters: [.contentType: "paywall"])
        #if DEBUG
        print("📊 Meta: ViewContent (paywall)")
        #endif
        #endif
    }

    /// Free trial started: the event the campaigns optimize on.
    func trackStartTrial(productId: String, currency: String) {
        #if canImport(FacebookCore)
        guard isInitialized else { return }
        AppEvents.shared.logEvent(.startTrial, parameters: [.contentID: productId, .currency: currency])
        #if DEBUG
        print("📊 Meta: StartTrial (product: \(productId))")
        #endif
        #endif
    }

    /// Direct paid purchase in the app (no trial). Trial conversions and renewals come from RevenueCat.
    func trackSubscribe(productId: String, price: Double, currency: String) {
        #if canImport(FacebookCore)
        guard isInitialized else { return }
        AppEvents.shared.logEvent(.subscribe, valueToSum: price, parameters: [.contentID: productId, .currency: currency])
        #if DEBUG
        print("📊 Meta: Subscribe (product: \(productId), price: \(price) \(currency))")
        #endif
        #endif
    }
}
