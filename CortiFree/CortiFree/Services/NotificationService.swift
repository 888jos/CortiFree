import Foundation
import UserNotifications

class NotificationService {
    static let shared = NotificationService()

    private init() {}

    // MARK: - DAILY NOTIFICATIONS (2 types)

    /// Schedule daily notifications for user engagement
    func scheduleDailyNotifications() {
        guard !userDisabledNotifications else { return }
        // Only for someone who finished the onboarding (the reminders talk about their program);
        // not for a signed-out device or an abandoned onboarding.
        guard UserDefaults.standard.bool(forKey: "onboardingV2Completed") else {
            cancelDailyNotifications()
            return
        }
        guard hasNotificationPermission() else {
            print("⚠️ No notification permission - skipping daily notifications")
            return
        }

        // Morning notification (9h by default, time chosen during onboarding). Subscribers following
        // their plan get PlanReminderScheduler's reminder instead, which names today's session.
        let morning = morningReminderComponents
        if !UserDefaults.standard.bool(forKey: "planReminders.active") {
            scheduleDailyNotification(
                id: "daily_morning_meditation",
                title: LanguageManager.shared.localizedString(for: "inline.notificationservice.00"),
                body: LanguageManager.shared.localizedString(for: "inline.notificationservice.01"),
                hour: morning.hour,
                minute: morning.minute
            )
        }

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
                "morning_hour": morning.hour,
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

    // MARK: - MORNING REMINDER TIME

    private static let morningReminderKey = "morningReminderMinutes"

    /// Hour and minute of the morning reminder (default 9:00).
    var morningReminderComponents: (hour: Int, minute: Int) {
        let stored = UserDefaults.standard.object(forKey: Self.morningReminderKey) as? Int ?? 9 * 60
        return (stored / 60, stored % 60)
    }

    /// Today's date at the morning reminder time, for time pickers.
    var morningReminderDate: Date {
        let time = morningReminderComponents
        return Calendar.current.date(bySettingHour: time.hour, minute: time.minute, second: 0, of: Date()) ?? Date()
    }

    /// Saves the morning reminder time and reschedules the daily reminders.
    func setMorningReminder(_ date: Date) {
        let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
        UserDefaults.standard.set((parts.hour ?? 9) * 60 + (parts.minute ?? 0), forKey: Self.morningReminderKey)
        scheduleDailyNotifications()
        Task { @MainActor in PlanReminderScheduler.shared.scheduleSoon() }
    }

    // MARK: - TRIAL NOTIFICATIONS (Day 2 & Day 3)

    private static let trialEndingID = "trial_ending_reminder"

    /// Keeps the promise made on the paywall: a reminder 2 days before the trial converts
    /// (at least 2 hours ahead for very short trials), at 10:00 local time when possible.
    func scheduleTrialNotifications(trialEndsAt: Date, now: Date = Date()) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [Self.trialEndingID])

        let calendar = Calendar.current
        let twoDaysBefore = trialEndsAt.addingTimeInterval(-2 * 86_400)
        var fireDate = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: twoDaysBefore) ?? twoDaysBefore
        if fireDate <= now { fireDate = trialEndsAt.addingTimeInterval(-24 * 3600) }
        guard fireDate > now.addingTimeInterval(60), fireDate < trialEndsAt.addingTimeInterval(-2 * 3600) else { return }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: LanguageManager.shared.currentLanguage.rawValue)
        formatter.setLocalizedDateFormatFromTemplate("EEEEdMMMM")

        let content = UNMutableNotificationContent()
        content.title = LanguageManager.shared.localizedString(for: "recovery.trial_ending.title")
        content.body = String(format: LanguageManager.shared.localizedString(for: "recovery.trial_ending.body"),
                              formatter.string(from: trialEndsAt))
        content.sound = .default
        content.userInfo = ["campaign": "trial_ending"]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: fireDate.timeIntervalSince(now), repeats: false)
        let request = UNNotificationRequest(identifier: Self.trialEndingID, content: content, trigger: trigger)
        center.getNotificationSettings { settings in
            guard [.authorized, .provisional, .ephemeral].contains(settings.authorizationStatus) else { return }
            center.add(request)
        }
    }

    func cancelTrialEndingReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [Self.trialEndingID])
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
            // Provisional (quiet) authorization is reserved for the trial recovery notifications
            // until the user answers the real prompt.
            let authorized = [.authorized, .ephemeral].contains(settings.authorizationStatus)
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

    // MARK: - RE-ENGAGEMENT NOTIFICATIONS (Onboarding Incomplete)

    /// Re-engagement before the trial now lives in RecoveryScheduler.
    func cancelReengagementNotifications() {
        Task { @MainActor in
            RecoveryScheduler.shared.cancelAll(reason: "onboarding_completed")
        }
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
