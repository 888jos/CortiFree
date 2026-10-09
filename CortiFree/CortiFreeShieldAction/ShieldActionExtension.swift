//
//  ShieldActionExtension.swift
//  CortiFreeShieldAction
//
//  Buttons of the shield. iOS gives no way to open CortiFree from here (ShieldActionResponse is
//  only none / close / defer): « Breathe » posts a notification the user taps to land on the
//  pause (same workaround as one sec), and closes the shielded app.
//

import ManagedSettings
import UserNotifications

final class ShieldActionExtension: ShieldActionDelegate {
    override func handle(action: ShieldAction, for application: ApplicationToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        handle(action, completionHandler)
    }

    override func handle(action: ShieldAction, for webDomain: WebDomainToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        handle(action, completionHandler)
    }

    override func handle(action: ShieldAction, for category: ActivityCategoryToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        handle(action, completionHandler)
    }

    private func handle(_ action: ShieldAction, _ completionHandler: @escaping (ShieldActionResponse) -> Void) {
        // Every other button (« Not now », the newer submenu items) just closes the app.
        if action == .primaryButtonPressed {
            ScreenTimeShield.postBreatheNotification(
                title: String(localized: "shield.notification.title", defaultValue: "Breathe with Milo"),
                body: String(localized: "shield.notification.body", defaultValue: "Tap here: 30 seconds, then your app is unlocked for 10 minutes.")
            )
        }
        completionHandler(.close)
    }
}
