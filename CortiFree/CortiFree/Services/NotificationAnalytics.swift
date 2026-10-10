//
//  NotificationAnalytics.swift
//  CortiFree
//
//  Notification funnel in Amplitude, for every kind of notification the app sends:
//  scheduled → delivered → opened, by `notification_type`, plus the permission status as a
//  user property. Local notifications give no callback when they are shown while the app is
//  closed, so each time the app comes to the foreground the pending and delivered lists are
//  compared with what was already reported. Nothing to add where notifications are scheduled.
//

import Foundation
import UIKit
import UserNotifications

enum NotificationAnalytics {
    private static let defaults = UserDefaults.standard
    private static let scheduledKey = "analytics.notifications.scheduled"
    private static let deliveredKey = "analytics.notifications.delivered"
    private static let permissionKey = "analytics.notifications.permission"
    private static var observer: NSObjectProtocol?

    static func start() {
        guard observer == nil else { return }
        observer = NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification,
                                                          object: nil, queue: .main) { _ in sync() }
        sync()
    }

    /// Kind of notification, stable across instances: the campaign when there is one, else the
    /// identifier without its numbers / ids (« milestone_streak_7 » → « milestone_streak »).
    static func type(of request: UNNotificationRequest) -> String {
        let info = request.content.userInfo
        for key in ["campaign", "type", "notification_type"] {
            if let value = info[key] as? String, !value.isEmpty { return value }
        }
        let parts = request.identifier
            .split(whereSeparator: { $0 == "_" || $0 == "-" || $0 == "." })
            .map(String.init)
            .prefix { part in !part.contains(where: \.isNumber) && part.count < 20 }
        let base = parts.prefix(3).joined(separator: "_")
        return base.isEmpty ? "other" : base.lowercased()
    }

    private static func properties(_ request: UNNotificationRequest) -> [String: Any] {
        var properties: [String: Any] = [
            "notification_type": type(of: request),
            "notification_id": request.identifier
        ]
        let info = request.content.userInfo
        for key in ["campaign", "message_id", "segment"] {
            if let value = info[key] as? String, !value.isEmpty { properties[key] = value }
        }
        return properties
    }

    // MARK: Opened / shown in foreground (AppDelegate)

    static func opened(_ response: UNNotificationResponse) {
        let request = response.notification.request
        reportDelivered(request, date: response.notification.date, appState: "background")
        var props = properties(request)
        props["action"] = response.actionIdentifier == UNNotificationDefaultActionIdentifier ? "open" : response.actionIdentifier
        props["minutes_after_delivery"] = max(0, Int(Date().timeIntervalSince(response.notification.date) / 60))
        AnalyticsManager.shared.track(event: "notification_opened", properties: props)
    }

    static func shownInForeground(_ notification: UNNotification) {
        reportDelivered(notification.request, date: notification.date, appState: "foreground")
    }

    // MARK: Sync

    private static func sync() {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            let status: String
            switch settings.authorizationStatus {
            case .authorized: status = "authorized"
            case .denied: status = "denied"
            case .provisional: status = "provisional"
            case .ephemeral: status = "ephemeral"
            case .notDetermined: status = "not_determined"
            @unknown default: status = "unknown"
            }
            DispatchQueue.main.async {
                AnalyticsManager.shared.setUserProperty("notification_permission", value: status)
                let previous = defaults.string(forKey: permissionKey)
                if let previous, previous != status {
                    AnalyticsManager.shared.track(event: "notification_permission_changed",
                                                  properties: ["from": previous, "to": status])
                }
                defaults.set(status, forKey: permissionKey)
            }
        }
        center.getPendingNotificationRequests { requests in
            DispatchQueue.main.async { reportScheduled(requests) }
        }
        center.getDeliveredNotifications { notifications in
            DispatchQueue.main.async {
                for notification in notifications {
                    reportDelivered(notification.request, date: notification.date, appState: "closed")
                }
            }
        }
    }

    /// New pending requests since the last look are reported once each.
    private static func reportScheduled(_ requests: [UNNotificationRequest]) {
        let known = Set(defaults.stringArray(forKey: scheduledKey) ?? [])
        for request in requests {
            let key = fingerprint(request.identifier, nextFire(request))
            guard !known.contains(key) else { continue }
            var props = properties(request)
            if let fire = nextFire(request) {
                props["hours_until_fire"] = Int(fire.timeIntervalSinceNow / 3600)
                props["fire_hour"] = Calendar.current.component(.hour, from: fire)
            }
            props["repeats"] = request.trigger?.repeats ?? false
            AnalyticsManager.shared.track(event: "notification_scheduled", properties: props)
        }
        // Remember what is pending now (bounded: pending requests are at most 64).
        defaults.set(requests.map { fingerprint($0.identifier, nextFire($0)) }, forKey: scheduledKey)
        AnalyticsManager.shared.setUserProperty("notifications_pending", value: requests.count)
    }

    private static func reportDelivered(_ request: UNNotificationRequest, date: Date, appState: String) {
        var known = defaults.stringArray(forKey: deliveredKey) ?? []
        let key = fingerprint(request.identifier, date)
        guard !known.contains(key) else { return }
        var props = properties(request)
        props["app_state"] = appState
        props["delivered_hour"] = Calendar.current.component(.hour, from: date)
        AnalyticsManager.shared.track(event: "notification_delivered", properties: props)
        known.append(key)
        defaults.set(Array(known.suffix(300)), forKey: deliveredKey)
    }

    private static func nextFire(_ request: UNNotificationRequest) -> Date? {
        switch request.trigger {
        case let trigger as UNCalendarNotificationTrigger: return trigger.nextTriggerDate()
        case let trigger as UNTimeIntervalNotificationTrigger: return trigger.nextTriggerDate()
        default: return nil
        }
    }

    private static func fingerprint(_ identifier: String, _ date: Date?) -> String {
        "\(identifier)@\(Int((date?.timeIntervalSince1970 ?? 0) / 60))"
    }
}
