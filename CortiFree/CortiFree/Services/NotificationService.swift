import Foundation
import UserNotifications

class NotificationService {
    static let shared = NotificationService()

    private init() {}

    // MARK: - DAILY NOTIFICATIONS (2 types)

    /// Schedule daily notifications for user engagement
    func scheduleDailyNotifications() {
        guard !userDisabledNotifications else { return }
        guard hasNotificationPermission() else {
            print("⚠️ No notification permission - skipping daily notifications")
            return
        }

        // Morning notification (9h)
        scheduleDailyNotification(
            id: "daily_morning_meditation",
            title: LanguageManager.shared.localizedString(for: "inline.notificationservice.00"),
            body: LanguageManager.shared.localizedString(for: "inline.notificationservice.01"),
            hour: 9,
            minute: 0
        )

        // Evening notification (19h)
        scheduleDailyNotification(
            id: "daily_evening_journal",
            title: LanguageManager.shared.localizedString(for: "inline.notificationservice.02"),
            body: LanguageManager.shared.localizedString(for: "inline.notificationservice.03"),
            hour: 19,
            minute: 0
        )

        // Track scheduled
        AnalyticsManager.shared.track(
            event: "daily_notifications_scheduled",
            properties: [
                "morning_hour": 9,
                "evening_hour": 19
            ]
        )

        print("✅ Daily notifications scheduled (9h, 19h)")
    }

    /// Schedule streak danger notification if user hasn't done anything today
    func scheduleStreakDangerNotification() {
        guard !userDisabledNotifications, hasNotificationPermission() else { return }

        // Cancel previous streak danger notification if exists
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["streak_danger"])

        // Schedule for 20h today
        scheduleDailyNotification(
            id: "streak_danger",
            title: LanguageManager.shared.localizedString(for: "inline.notificationservice.04"),
            body: LanguageManager.shared.localizedString(for: "inline.notificationservice.05"),
            hour: 20,
            minute: 0,
            repeats: false // One-time notification
        )

        AnalyticsManager.shared.track(
            event: "streak_danger_notification_scheduled",
            properties: [:]
        )

        print("✅ Streak danger notification scheduled (20h)")
    }

    // MARK: - TRIAL NOTIFICATIONS (Day 2 & Day 3)

    /// Schedule trial-specific notifications (disabled)
    func scheduleTrialNotifications() {
        // Disabled — Apple's native trial reminder handles this automatically
    }

    // MARK: - MILESTONE NOTIFICATIONS (Streaks, Badges)

    /// Schedule milestone notification for streak achievements
    func scheduleMilestoneNotification(streakDays: Int) {
        guard !userDisabledNotifications, hasNotificationPermission() else { return }

        let (title, body, emoji) = getMilestoneContent(for: streakDays)

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.badge = 1

        // Immediate notification
        let request = UNNotificationRequest(
            identifier: "milestone_streak_\(streakDays)",
            content: content,
            trigger: nil // Deliver immediately
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Milestone notification error: \(error.localizedDescription)")
            } else {
                print("✅ Milestone notification sent: \(streakDays) days streak")

                AnalyticsManager.shared.track(
                    event: "milestone_notification_sent",
                    properties: [
                        "streak_days": streakDays,
                        "milestone_type": "streak",
                        "emoji": emoji
                    ]
                )
            }
        }
    }

    /// Schedule badge unlock notification
    func scheduleBadgeUnlockedNotification(badgeName: String, badgeIcon: String, points: Int) {
        guard !userDisabledNotifications, hasNotificationPermission() else { return }

        let content = UNMutableNotificationContent()
        content.title = String(
            format: LanguageManager.shared.localizedString(for: "notification.badge_unlocked"),
            badgeIcon
        )
        content.body = "\(badgeName) • +\(points) points"
        content.sound = .default
        content.badge = 1

        let request = UNNotificationRequest(
            identifier: "badge_unlocked_\(badgeName.replacingOccurrences(of: " ", with: "_"))",
            content: content,
            trigger: nil // Deliver immediately
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Badge notification error: \(error.localizedDescription)")
            } else {
                print("✅ Badge notification sent: \(badgeName)")

                AnalyticsManager.shared.track(
                    event: "badge_notification_sent",
                    properties: [
                        "badge_name": badgeName,
                        "badge_icon": badgeIcon,
                        "points": points
                    ]
                )
            }
        }
    }

    // MARK: - CANCEL NOTIFICATIONS

    /// Cancel all trial notifications (called when user converts or cancels)
    func cancelTrialNotifications() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [
            "trial_day2",
            "trial_day3_expiring"
        ])

        print("✅ Trial notifications cancelled")

        AnalyticsManager.shared.track(
            event: "trial_notifications_cancelled",
            properties: [:]
        )
    }

    /// Cancel all daily notifications (when user unsubscribes)
    func cancelDailyNotifications() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [
            "daily_morning_meditation",
            "daily_evening_journal"
        ])

        print("✅ Daily notifications cancelled")
    }

    /// Cancel streak danger notification (when user completes a task)
    func cancelStreakDangerNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [
            "streak_danger"
        ])

        print("✅ Streak danger notification cancelled")
    }

    /// Cancel ALL notifications
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()

        print("✅ All notifications cancelled")

        AnalyticsManager.shared.track(
            event: "all_notifications_cancelled",
            properties: [:]
        )
    }

    // MARK: - DEBUG / CHECK NOTIFICATIONS

    /// Get list of all pending notifications (for debugging)
    func getPendingNotifications(completion: @escaping ([UNNotificationRequest]) -> Void) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            completion(requests)
        }
    }

    /// Print all pending notifications to console (for debugging)
    func debugPrintPendingNotifications() {
        getPendingNotifications { requests in
            print("\n📋 PENDING NOTIFICATIONS (\(requests.count)):")

            if requests.isEmpty {
                print("   (none)")
            } else {
                for request in requests {
                    var triggerInfo = "immediate"

                    if let trigger = request.trigger as? UNCalendarNotificationTrigger {
                        let components = trigger.dateComponents
                        triggerInfo = "hour: \(components.hour ?? -1), day: \(components.day ?? -1)"
                    } else if let trigger = request.trigger as? UNTimeIntervalNotificationTrigger {
                        triggerInfo = "interval: \(trigger.timeInterval)s"
                    }

                    print("   • \(request.identifier)")
                    print("     Title: \(request.content.title)")
                    print("     Body: \(request.content.body)")
                    print("     Trigger: \(triggerInfo)")
                    print("")
                }
            }

            print("To view in Settings: Settings > Notifications > CortiFree\n")
        }
    }

    // MARK: - PERMISSION HELPERS

    /// Check if user has granted notification permission
    func hasNotificationPermission() -> Bool {
        var hasPermission = false
        let semaphore = DispatchSemaphore(value: 0)

        UNUserNotificationCenter.current().getNotificationSettings { settings in
            hasPermission = [.authorized, .provisional, .ephemeral].contains(settings.authorizationStatus)
            semaphore.signal()
        }

        semaphore.wait()
        return hasPermission
    }

    /// True when the user turned the "Notifications" toggle off in Settings.
    var userDisabledNotifications: Bool {
        (UserDefaults.standard.object(forKey: "notificationsEnabled") as? Bool) == false
    }

    /// Re-schedules (idempotent, same identifiers) or cancels the daily reminders so
    /// they match the Settings toggle and the real system permission.
    func syncDailyNotificationsWithPreference() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            let authorized = [.authorized, .provisional, .ephemeral].contains(settings.authorizationStatus)
            if authorized && !self.userDisabledNotifications {
                // Hop off the callback queue: scheduleDailyNotifications() waits on another settings callback.
                DispatchQueue.global(qos: .utility).async { self.scheduleDailyNotifications() }
            } else {
                self.cancelDailyNotifications()
                self.cancelStreakDangerNotification()
            }
        }
    }

    /// Request notification permission (if not already granted)
    func requestNotificationPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("❌ Notification permission error: \(error.localizedDescription)")
            }

            print(granted ? "✅ Notification permission granted" : "⚠️ Notification permission denied")

            AnalyticsManager.shared.track(
                event: "notification_permission_requested",
                properties: [
                    "granted": granted,
                    "error": error?.localizedDescription ?? ""
                ]
            )

            completion(granted)
        }
    }

    // MARK: - INTERNAL HELPERS

    /// Schedule a daily repeating notification
    private func scheduleDailyNotification(
        id: String,
        title: String,
        body: String,
        hour: Int,
        minute: Int,
        repeats: Bool = true
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.badge = 1

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: repeats)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Notification scheduling error (\(id)): \(error.localizedDescription)")
            } else {
                print("✅ Scheduled: \(id) at \(hour):\(String(format: "%02d", minute)) (repeats: \(repeats))")
            }
        }
    }

    /// Schedule a notification X days from now at specific time
    private func scheduleNotificationFromNow(
        id: String,
        title: String,
        body: String,
        daysFromNow: Int,
        hour: Int,
        minute: Int
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.badge = 1

        // Add days via Calendar so month/year rollover yields a real date (e.g. Jan 30 + 7 → Feb 6).
        let calendar = Calendar.current
        let targetDay = calendar.date(byAdding: .day, value: daysFromNow, to: Date()) ?? Date()
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: targetDay)
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Notification scheduling error (\(id)): \(error.localizedDescription)")
            } else {
                print("✅ Scheduled: \(id) for +\(daysFromNow) days at \(hour):\(String(format: "%02d", minute))")
            }
        }
    }

    // MARK: - RE-ENGAGEMENT NOTIFICATIONS (Onboarding Incomplete)

    /// Schedule re-engagement notifications for users who quit onboarding
    /// Combines 3 strategies with anti-spam logic
    func scheduleOnboardingReengagementNotifications() {
        guard hasNotificationPermission() else {
            print("⚠️ No notification permission - skipping re-engagement notifications")
            return
        }

        // Check if user already completed onboarding
        if UserDefaults.standard.bool(forKey: "onboardingV2Completed") {
            print("⚠️ Onboarding already completed - skipping re-engagement")
            return
        }

        // Get last checkpoint
        let lastCheckpoint = UserDefaults.standard.string(forKey: "last_onboarding_checkpoint") ?? "unknown"
        let sawPaywall = UserDefaults.standard.bool(forKey: "saw_paywall_without_accepting")
        let isAuthenticated = UserDefaults.standard.bool(forKey: "user_is_authenticated")

        // STRATEGY 1: Checkpoint-based (2h, 24h, 48h)
        if lastCheckpoint != "unknown" && lastCheckpoint != "completed" {
            scheduleCheckpointBasedNotifications(checkpoint: lastCheckpoint)
        }

        // STRATEGY 2: Paywall-focused (1h, 6h, 24h)
        if sawPaywall {
            schedulePaywallReengagementNotifications()
        }

        // STRATEGY 3: Auth-based (12h, 48h, 7d)
        if isAuthenticated {
            scheduleAuthBasedNotifications()
        }

        // Track scheduling
        AnalyticsManager.shared.track(
            event: "reengagement_notifications_scheduled",
            properties: [
                "last_checkpoint": lastCheckpoint,
                "saw_paywall": sawPaywall,
                "is_authenticated": isAuthenticated
            ]
        )

        print("✅ Re-engagement notifications scheduled")
    }

    /// Strategy 1: Checkpoint-based notifications
    private func scheduleCheckpointBasedNotifications(checkpoint: String) {
        // 2 hours after quitting — curiosity gap
        scheduleNotificationFromNow(
            id: "reengagement_checkpoint_2h",
            title: LanguageManager.shared.localizedString(for: "inline.notificationservice.06"),
            body: LanguageManager.shared.localizedString(for: "inline.notificationservice.07"),
            daysFromNow: 0,
            hour: Calendar.current.component(.hour, from: Date().addingTimeInterval(2 * 3600)),
            minute: Calendar.current.component(.minute, from: Date().addingTimeInterval(2 * 3600))
        )

        // 24 hours — emotional pull
        scheduleNotificationFromNow(
            id: "reengagement_checkpoint_24h",
            title: LanguageManager.shared.localizedString(for: "inline.notificationservice.08"),
            body: LanguageManager.shared.localizedString(for: "inline.notificationservice.09"),
            daysFromNow: 1,
            hour: 10,
            minute: 0
        )

        // 48 hours — urgency + loss aversion
        scheduleNotificationFromNow(
            id: "reengagement_checkpoint_48h",
            title: LanguageManager.shared.localizedString(for: "inline.notificationservice.10"),
            body: LanguageManager.shared.localizedString(for: "inline.notificationservice.11"),
            daysFromNow: 2,
            hour: 18,
            minute: 0
        )

        print("✅ Checkpoint-based notifications scheduled (2h, 24h, 48h)")
    }

    /// Strategy 2: Paywall-focused notifications
    private func schedulePaywallReengagementNotifications() {
        // Cancel checkpoint notifications to avoid spam
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [
            "reengagement_checkpoint_2h",
            "reengagement_checkpoint_24h",
            "reengagement_checkpoint_48h"
        ])

        // 1 hour — remind of value, zero risk
        scheduleNotificationFromNow(
            id: "reengagement_paywall_1h",
            title: LanguageManager.shared.localizedString(for: "inline.notificationservice.12"),
            body: LanguageManager.shared.localizedString(for: "inline.notificationservice.13"),
            daysFromNow: 0,
            hour: Calendar.current.component(.hour, from: Date().addingTimeInterval(3600)),
            minute: Calendar.current.component(.minute, from: Date().addingTimeInterval(3600))
        )

        // 6 hours — future self visualization
        scheduleNotificationFromNow(
            id: "reengagement_paywall_6h",
            title: LanguageManager.shared.localizedString(for: "inline.notificationservice.14"),
            body: LanguageManager.shared.localizedString(for: "inline.notificationservice.15"),
            daysFromNow: 0,
            hour: Calendar.current.component(.hour, from: Date().addingTimeInterval(6 * 3600)),
            minute: Calendar.current.component(.minute, from: Date().addingTimeInterval(6 * 3600))
        )

        // 24 hours — personal + scientific credibility
        scheduleNotificationFromNow(
            id: "reengagement_paywall_24h",
            title: LanguageManager.shared.localizedString(for: "inline.notificationservice.16"),
            body: LanguageManager.shared.localizedString(for: "inline.notificationservice.17"),
            daysFromNow: 1,
            hour: 11,
            minute: 0
        )

        print("✅ Paywall-focused notifications scheduled (1h, 6h, 24h)")
    }

    /// Strategy 3: Auth-based notifications (less aggressive)
    private func scheduleAuthBasedNotifications() {
        // Only schedule if no paywall notifications
        if !UserDefaults.standard.bool(forKey: "saw_paywall_without_accepting") {
            // 12 hours — gentle reminder
            scheduleNotificationFromNow(
                id: "reengagement_auth_12h",
                title: LanguageManager.shared.localizedString(for: "inline.notificationservice.18"),
                body: LanguageManager.shared.localizedString(for: "inline.notificationservice.19"),
                daysFromNow: 0,
                hour: Calendar.current.component(.hour, from: Date().addingTimeInterval(12 * 3600)),
                minute: Calendar.current.component(.minute, from: Date().addingTimeInterval(12 * 3600))
            )

            // 48 hours — emotional
            scheduleNotificationFromNow(
                id: "reengagement_auth_48h",
                title: LanguageManager.shared.localizedString(for: "inline.notificationservice.20"),
                body: LanguageManager.shared.localizedString(for: "inline.notificationservice.21"),
                daysFromNow: 2,
                hour: 14,
                minute: 0
            )

            // 7 days — last chance
            scheduleNotificationFromNow(
                id: "reengagement_auth_7d",
                title: LanguageManager.shared.localizedString(for: "inline.notificationservice.22"),
                body: LanguageManager.shared.localizedString(for: "inline.notificationservice.23"),
                daysFromNow: 7,
                hour: 10,
                minute: 0
            )

            print("✅ Auth-based notifications scheduled (12h, 48h, 7d)")
        } else {
            print("⚠️ Skipping auth-based notifications (paywall already shown)")
        }
    }

    /// Cancel all re-engagement notifications (when user completes onboarding)
    func cancelReengagementNotifications() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [
            "reengagement_checkpoint_2h",
            "reengagement_checkpoint_24h",
            "reengagement_checkpoint_48h",
            "reengagement_paywall_1h",
            "reengagement_paywall_6h",
            "reengagement_paywall_24h",
            "reengagement_auth_12h",
            "reengagement_auth_48h",
            "reengagement_auth_7d"
        ])

        print("✅ Re-engagement notifications cancelled")

        AnalyticsManager.shared.track(
            event: "reengagement_notifications_cancelled",
            properties: [:]
        )
    }

    // MARK: - MILESTONE CONTENT

    /// Get milestone content based on streak days
    private func getMilestoneContent(for streakDays: Int) -> (title: String, body: String, emoji: String) {
        switch streakDays {
        case 3:
            return (
                LanguageManager.shared.localizedString(for: "inline.notificationservice.24"),
                LanguageManager.shared.localizedString(for: "inline.notificationservice.25"),
                "🔥"
            )
        case 7:
            return (
                LanguageManager.shared.localizedString(for: "inline.notificationservice.26"),
                LanguageManager.shared.localizedString(for: "inline.notificationservice.27"),
                "🎉"
            )
        case 14:
            return (
                LanguageManager.shared.localizedString(for: "inline.notificationservice.28"),
                LanguageManager.shared.localizedString(for: "inline.notificationservice.29"),
                "⭐"
            )
        case 30:
            return (
                LanguageManager.shared.localizedString(for: "inline.notificationservice.30"),
                LanguageManager.shared.localizedString(for: "inline.notificationservice.31"),
                "🚀"
            )
        case 66:
            return (
                LanguageManager.shared.localizedString(for: "inline.notificationservice.32"),
                LanguageManager.shared.localizedString(for: "inline.notificationservice.33"),
                "🏆"
            )
        default:
            return (
                String(
                    format: LanguageManager.shared.localizedString(for: "notification.streak_message"),
                    streakDays
                ),
                LanguageManager.shared.localizedString(for: "inline.notificationservice.34"),
                "🔥"
            )
        }
    }
}
