//
//  ScreenTimeShield.swift
//  CortiFree
//
//  « Breathe before TikTok » without any Shortcuts automation (Screen Time API, like one sec
//  and Opal). The user picks the apps once (FamilyActivityPicker); iOS then shows our shield
//  over them. The shield's button posts a notification that opens CortiFree on the breathing
//  pause; after the pause the shield is lifted for ~10 minutes and the Device Activity
//  monitor puts it back.
//
//  Shared by the app and its three Screen Time extensions (Shield Configuration, Shield
//  Action, Device Activity Monitor): no UIApplication, no analytics here.
//
//  Needs the Family Controls entitlement (com.apple.developer.family-controls). Apple only
//  grants the distribution variant on request: until then `isEnabled` stays false and the
//  Shortcuts automation (BreathePauseIntent) remains the only path.
//

import DeviceActivity
import FamilyControls
import Foundation
import ManagedSettings
import UserNotifications

enum ScreenTimeShield {
    /// Flip to true once Apple has granted the Family Controls (Distribution) entitlement and
    /// the three extension targets are in the project.
    static let isEnabled = false

    static let appGroup = "group.com.solstys.cortifree"
    /// Notification campaign / deep link used by the Shield Action extension to open the pause.
    static let campaign = "breathe_shield"
    static let deepLink = "cortifree://breathe"
    /// After a pause, the shielded apps open freely for this long (same as the Shortcuts passWindow).
    static let passWindow: TimeInterval = 10 * 60
    /// DeviceActivity refuses schedules shorter than 15 minutes.
    private static let minimumSchedule: TimeInterval = 15 * 60

    static let store = ManagedSettingsStore(named: .init("breathe"))
    static let passActivity = DeviceActivityName("breathe.pass")

    private static var defaults: UserDefaults? { UserDefaults(suiteName: appGroup) }
    private static let selectionKey = "screenTime.breathe.selection"
    private static let passUntilKey = "screenTime.breathe.passUntil"

    // MARK: Selection (opaque tokens: we never learn which apps were picked)

    static var selection: FamilyActivitySelection {
        get {
            guard let data = defaults?.data(forKey: selectionKey),
                  let saved = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) else {
                return FamilyActivitySelection()
            }
            return saved
        }
        set {
            defaults?.set(try? JSONEncoder().encode(newValue), forKey: selectionKey)
            let picked = !newValue.applicationTokens.isEmpty || !newValue.categoryTokens.isEmpty || !newValue.webDomainTokens.isEmpty
            UserDefaults.standard.set(picked, forKey: BreathePauseCenter.configuredKey)
        }
    }

    static var hasSelection: Bool {
        let s = selection
        return !s.applicationTokens.isEmpty || !s.categoryTokens.isEmpty || !s.webDomainTokens.isEmpty
    }

    static var passUntil: Date? {
        guard let t = defaults?.double(forKey: passUntilKey), t > 0 else { return nil }
        return Date(timeIntervalSince1970: t)
    }

    // MARK: Shield

    /// Shields the picked apps, unless a pass (right after a pause) is still running.
    static func applyShield() {
        if let passUntil, passUntil > Date() { return }
        let s = selection
        store.shield.applications = s.applicationTokens.isEmpty ? nil : s.applicationTokens
        store.shield.applicationCategories = s.categoryTokens.isEmpty ? nil : .specific(s.categoryTokens)
        store.shield.webDomains = s.webDomainTokens.isEmpty ? nil : s.webDomainTokens
    }

    static func removeShield() {
        store.clearAllSettings()
    }

    /// The pause is over: open the apps for `passWindow`, then the monitor shields them again.
    static func startPass() {
        let end = Date().addingTimeInterval(passWindow)
        defaults?.set(end.timeIntervalSince1970, forKey: passUntilKey)
        removeShield()

        // The interval must last 15 min: start it in the past so it still ends in 10 min.
        let start = end.addingTimeInterval(-minimumSchedule)
        let calendar = Calendar.current
        let parts: Set<Calendar.Component> = [.year, .month, .day, .hour, .minute, .second]
        let schedule = DeviceActivitySchedule(
            intervalStart: calendar.dateComponents(parts, from: start),
            intervalEnd: calendar.dateComponents(parts, from: end),
            repeats: false
        )
        let center = DeviceActivityCenter()
        center.stopMonitoring([passActivity])
        do {
            try center.startMonitoring(passActivity, during: schedule)
        } catch {
            // Fallback: the app re-shields itself at its next launch (`endPassIfExpired`).
            #if DEBUG
            print("⚠️ ScreenTimeShield: could not schedule the re-lock: \(error)")
            #endif
        }
    }

    /// Called by the app when it becomes active (safety net if the re-lock schedule was refused).
    static func endPassIfExpired() {
        guard let passUntil, passUntil <= Date() else { return }
        endPass()
    }

    /// The Device Activity monitor calls this at the end of the interval (it may wake a hair early).
    static func endPass() {
        defaults?.removeObject(forKey: passUntilKey)
        applyShield()
    }

    // MARK: Shield → app hand-off

    /// A Shield Action extension cannot open its app (ShieldActionResponse has no such case):
    /// like one sec, we post a local notification the user taps to land on the pause.
    static func postBreatheNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.interruptionLevel = .timeSensitive
        content.userInfo = ["campaign": campaign, "deeplink": deepLink]
        let request = UNNotificationRequest(identifier: campaign, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}
