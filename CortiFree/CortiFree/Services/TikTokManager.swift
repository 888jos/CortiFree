//
//  TikTokManager.swift
//  CortiFree
//
//  TikTok App Events SDK integration for ad conversion tracking
//  Events: Registration, ViewContent (paywall), StartTrial, Purchase
//  Uses official TikTokBaseEvent / TikTokContentsEvent API
//

import Foundation
#if canImport(TikTokBusinessSDK)
import TikTokBusinessSDK
#endif

final class TikTokManager {
    static let shared = TikTokManager()
    private init() {}

    // MARK: - SDK Initialization

    func initialize() {
        #if canImport(TikTokBusinessSDK)
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
        config?.setLogLevel(TikTokLogLevelSuppress)
        #if DEBUG
        config?.enableDebugMode()
        config?.setLogLevel(TikTokLogLevelInfo)
        #endif

        TikTokBusiness.initializeSdk(config)

        #if DEBUG
        print("✅ TikTok SDK initialized (appId: \(APIConfig.shared.tiktokEventAppId), tiktokAppId: \(APIConfig.shared.tiktokAppId))")
        #endif
        #endif
    }

    // MARK: - Standard Events

    /// User completed authentication (Google/Apple/Email sign in)
    func trackCompleteRegistration(method: String) {
        #if canImport(TikTokBusinessSDK)
        let event = TikTokBaseEvent(eventName: TTEventName.registration.rawValue)
        TikTokBusiness.trackTTEvent(event)
        #if DEBUG
        print("📊 TikTok: Registration (method: \(method))")
        #endif
        #endif
    }

    /// User viewed the paywall
    func trackViewContent() {
        #if canImport(TikTokBusinessSDK)
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
