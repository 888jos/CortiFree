//
//  PostHogManager.swift
//  CortiFree
//
//  PostHog analytics integration
//  Mirrors the same events as MixpanelManager for cross-validation
//

import Foundation
import PostHog

final class PostHogManager {
    static let shared = PostHogManager()
    private init() {}

    private let apiKey = "phc_bmVnhDgm2OuQ7kEnmwkZzxKsWiR2U9ZoUpPnRzVGT7"
    private let host = "https://us.i.posthog.com"

    // MARK: - Initialization

    func initialize() {
        let config = PostHogConfig(apiKey: apiKey, host: host)
        PostHogSDK.shared.setup(config)
        #if DEBUG
        print("✅ PostHog initialized")
        #endif
    }

    // MARK: - Identity

    func identify(userId: String, properties: [String: Any] = [:]) {
        PostHogSDK.shared.identify(userId, userProperties: properties)
    }

    func reset() {
        PostHogSDK.shared.reset()
    }

    // MARK: - Events

    func capture(_ event: String, properties: [String: Any]? = nil) {
        PostHogSDK.shared.capture(event, properties: properties)
    }

    // MARK: - Standard App Events

    func trackOnboardingStep(_ step: String, properties: [String: Any]? = nil) {
        var props: [String: Any] = ["step": step]
        if let extra = properties { props.merge(extra) { _, new in new } }
        capture("onboarding_step", properties: props)
    }

    func trackOnboardingCompleted(score: Int) {
        capture("onboarding_completed", properties: ["score": score])
    }

    func trackPaywallViewed(source: String) {
        capture("paywall_viewed", properties: ["source": source])
    }

    func trackTrialStarted(productId: String) {
        capture("trial_started", properties: ["product_id": productId])
    }

    func trackPurchase(productId: String, price: Double, currency: String) {
        capture("purchase", properties: [
            "product_id": productId,
            "price": price,
            "currency": currency
        ])
    }

    func trackRegistration(method: String) {
        capture("sign_up", properties: ["method": method])
    }

    func trackHabitCompleted(habitId: String, day: Int) {
        capture("habit_completed", properties: ["habit_id": habitId, "day": day])
    }

    func trackExerciseStarted(exerciseId: String, type: String) {
        capture("exercise_started", properties: ["exercise_id": exerciseId, "type": type])
    }

    func trackAntiStressUsed(situation: String) {
        capture("antistress_used", properties: ["situation": situation])
    }
}
