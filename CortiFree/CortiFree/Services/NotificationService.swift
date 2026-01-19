import Foundation
import UserNotifications

class NotificationService {
    static let shared = NotificationService()

    private init() {}

    // MARK: - 🔔 DAILY NOTIFICATIONS (3 types)

    /// Schedule daily notifications for user engagement
    func scheduleDailyNotifications() {
        guard hasNotificationPermission() else {
            print("⚠️ No notification permission - skipping daily notifications")
            return
        }

        // Morning notification (9h)
        scheduleDailyNotification(
            id: "daily_morning_meditation",
            title: "Good morning! ☀️",
            body: "Start your day with a meditation session 🧘‍♀️",
            hour: 9,
            minute: 0
        )

        // Evening notification (19h)
        scheduleDailyNotification(
            id: "daily_evening_journal",
            title: "Evening Journal 📝",
            body: "How was your day? Write in your journal",
            hour: 19,
            minute: 0
        )

        // Track scheduled
        MixpanelManager.shared.track(
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
        guard hasNotificationPermission() else { return }

        // Cancel previous streak danger notification if exists
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["streak_danger"])

        // Schedule for 20h today
        scheduleDailyNotification(
            id: "streak_danger",
            title: "Your streak is in danger! ⚠️",
            body: "Complete a task to keep your progress 🔥",
            hour: 20,
            minute: 0,
            repeats: false // One-time notification
        )

        MixpanelManager.shared.track(
            event: "streak_danger_notification_scheduled",
            properties: [:]
        )

        print("✅ Streak danger notification scheduled (20h)")
    }

    // MARK: - 🎯 TRIAL NOTIFICATIONS (Day 2 & Day 3)

    /// Schedule trial-specific notifications (called after paywall acceptance)
    func scheduleTrialNotifications() {
        guard hasNotificationPermission() else {
            print("⚠️ No notification permission - skipping trial notifications")
            return
        }

        // Day 2 Morning (9h)
        scheduleNotificationFromNow(
            id: "trial_day2",
            title: "Keep your streak! 🔥",
            body: "Day 2/3 free • Complete a task today",
            daysFromNow: 1,
            hour: 9,
            minute: 0
        )

        // Day 3 Evening (19h)
        scheduleNotificationFromNow(
            id: "trial_day3_expiring",
            title: "Last free day 💎",
            body: "Continue your 66-day journey starting tomorrow",
            daysFromNow: 2,
            hour: 19,
            minute: 0
        )

        // Track scheduled
        MixpanelManager.shared.track(
            event: "trial_notifications_scheduled",
            properties: [
                "day2_time": "9h",
                "day3_time": "19h"
            ]
        )

        print("✅ Trial notifications scheduled (Day 2 at 9h, Day 3 at 19h)")
    }

    // MARK: - 🏆 MILESTONE NOTIFICATIONS (Streaks, Badges)

    /// Schedule milestone notification for streak achievements
    func scheduleMilestoneNotification(streakDays: Int) {
        guard hasNotificationPermission() else { return }

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

                MixpanelManager.shared.track(
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
        guard hasNotificationPermission() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Badge Unlocked! \(badgeIcon)"
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

                MixpanelManager.shared.track(
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

    // MARK: - ❌ CANCEL NOTIFICATIONS

    /// Cancel all trial notifications (called when user converts or cancels)
    func cancelTrialNotifications() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [
            "trial_day2",
            "trial_day3_expiring"
        ])

        print("✅ Trial notifications cancelled")

        MixpanelManager.shared.track(
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

        MixpanelManager.shared.track(
            event: "all_notifications_cancelled",
            properties: [:]
        )
    }

    // MARK: - 🔍 DEBUG / CHECK NOTIFICATIONS

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

    // MARK: - 🔐 PERMISSION HELPERS

    /// Check if user has granted notification permission
    func hasNotificationPermission() -> Bool {
        var hasPermission = false
        let semaphore = DispatchSemaphore(value: 0)

        UNUserNotificationCenter.current().getNotificationSettings { settings in
            hasPermission = settings.authorizationStatus == .authorized
            semaphore.signal()
        }

        semaphore.wait()
        return hasPermission
    }

    /// Request notification permission (if not already granted)
    func requestNotificationPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("❌ Notification permission error: \(error.localizedDescription)")
            }

            print(granted ? "✅ Notification permission granted" : "⚠️ Notification permission denied")

            MixpanelManager.shared.track(
                event: "notification_permission_requested",
                properties: [
                    "granted": granted,
                    "error": error?.localizedDescription ?? ""
                ]
            )

            completion(granted)
        }
    }

    // MARK: - 🛠️ INTERNAL HELPERS

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

        var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        dateComponents.day! += daysFromNow
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

    // MARK: - 🔄 RE-ENGAGEMENT NOTIFICATIONS (Onboarding Incomplete)

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
        MixpanelManager.shared.track(
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
        // 2 hours after quitting
        scheduleNotificationFromNow(
            id: "reengagement_checkpoint_2h",
            title: "Complete your profile 🎯",
            body: "2 minutes to unlock your personalized program",
            daysFromNow: 0,
            hour: Calendar.current.component(.hour, from: Date().addingTimeInterval(2 * 3600)),
            minute: Calendar.current.component(.minute, from: Date().addingTimeInterval(2 * 3600))
        )

        // 24 hours
        scheduleNotificationFromNow(
            id: "reengagement_checkpoint_24h",
            title: "Your journey awaits ✨",
            body: "Start your 66-day path to wellness",
            daysFromNow: 1,
            hour: 10,
            minute: 0
        )

        // 48 hours
        scheduleNotificationFromNow(
            id: "reengagement_checkpoint_48h",
            title: "Last chance 🔥",
            body: "Thousands are transforming their lives with CortiFree",
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

        // 1 hour after seeing paywall
        scheduleNotificationFromNow(
            id: "reengagement_paywall_1h",
            title: "3-day free trial 🎁",
            body: "Start with no commitment • Cancel anytime",
            daysFromNow: 0,
            hour: Calendar.current.component(.hour, from: Date().addingTimeInterval(3600)),
            minute: Calendar.current.component(.minute, from: Date().addingTimeInterval(3600))
        )

        // 6 hours
        scheduleNotificationFromNow(
            id: "reengagement_paywall_6h",
            title: "Limited offer ⏰",
            body: "3 free days to transform your habits",
            daysFromNow: 0,
            hour: Calendar.current.component(.hour, from: Date().addingTimeInterval(6 * 3600)),
            minute: Calendar.current.component(.minute, from: Date().addingTimeInterval(6 * 3600))
        )

        // 24 hours
        scheduleNotificationFromNow(
            id: "reengagement_paywall_24h",
            title: "Ready to start? 💪",
            body: "Join 10,000+ users transforming their lives",
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
            // 12 hours
            scheduleNotificationFromNow(
                id: "reengagement_auth_12h",
                title: "Continue your signup 📋",
                body: "Your account is waiting • Finish in 2 minutes",
                daysFromNow: 0,
                hour: Calendar.current.component(.hour, from: Date().addingTimeInterval(12 * 3600)),
                minute: Calendar.current.component(.minute, from: Date().addingTimeInterval(12 * 3600))
            )

            // 48 hours
            scheduleNotificationFromNow(
                id: "reengagement_auth_48h",
                title: "We saved your spot 🎯",
                body: "Start your transformation journey today",
                daysFromNow: 2,
                hour: 14,
                minute: 0
            )

            // 7 days
            scheduleNotificationFromNow(
                id: "reengagement_auth_7d",
                title: "Still interested? 🌟",
                body: "Your personalized program is ready",
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

        MixpanelManager.shared.track(
            event: "reengagement_notifications_cancelled",
            properties: [:]
        )
    }

    // MARK: - 🛠️ INTERNAL HELPERS (CONTINUED)

    /// Get milestone content based on streak days
    private func getMilestoneContent(for streakDays: Int) -> (title: String, body: String, emoji: String) {
        switch streakDays {
        case 3:
            return (
                "3 days in a row! 🔥",
                "You're building the habit! Keep it up",
                "🔥"
            )
        case 7:
            return (
                "1 full week! 🎉",
                "Awesome! You're on the right path to 66 days",
                "🎉"
            )
        case 14:
            return (
                "2-week streak! ⭐",
                "Amazing! The habit is starting to stick",
                "⭐"
            )
        case 30:
            return (
                "30 days straight! 🚀",
                "Champion! You're halfway to 66 days",
                "🚀"
            )
        case 66:
            return (
                "66 DAYS! YOU DID IT! 🏆",
                "The habit is ingrained! You're a wellness champion",
                "🏆"
            )
        default:
            return (
                "\(streakDays) days in a row! 🔥",
                "Keep progressing towards 66 days!",
                "🔥"
            )
        }
    }
}
