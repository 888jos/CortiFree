//
//  AnalyticsUserProperties.swift
//  CortiFree
//
//  User properties refreshed each time the app comes to the foreground, so every
//  Amplitude chart can be split by them: app language, plan goal and day, Apple Watch,
//  Apple Health, Milo consent. Subscription and notification properties are set by
//  RevenueCatManager and NotificationAnalytics.
//

import Foundation
import UIKit

@MainActor
enum AnalyticsUserProperties {
    private static var observer: NSObjectProtocol?

    static func start() {
        guard observer == nil else { return }
        observer = NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification,
                                                          object: nil, queue: .main) { _ in
            Task { @MainActor in refresh() }
        }
        refresh()
    }

    static func refresh() {
        var properties: [String: Any] = [
            "app_language": LanguageManager.shared.currentLanguage.rawValue,
            "has_apple_watch": UserDefaults.standard.string(forKey: AppleWatchPreference.storageKey) ?? "unknown",
            "health_connected": HealthKitService.shared.isEnabled,
            "breathe_pause_configured": UserDefaults.standard.bool(forKey: BreathePauseCenter.configuredKey)
        ]
        if let plan = PersonalPlanStore.shared.plan {
            properties["plan_goal"] = plan.goal.rawValue
            properties["plan_day"] = plan.dayIndex()
        } else {
            properties["plan_goal"] = "none"
        }
        AmplitudeManager.shared.setUserProperties(properties)
    }
}
