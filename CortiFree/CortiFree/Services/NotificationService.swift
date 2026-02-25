import Foundation
import UserNotifications

class NotificationService {
    static let shared = NotificationService()

    private init() {}

    private var isFrench: Bool {
        LanguageManager.shared.currentLanguage == .french
    }

    // MARK: - DAILY NOTIFICATIONS (2 types)

    /// Schedule daily notifications for user engagement
    func scheduleDailyNotifications() {
        guard hasNotificationPermission() else {
            print("⚠️ No notification permission - skipping daily notifications")
            return
        }

        // Morning notification (9h)
        scheduleDailyNotification(
            id: "daily_morning_meditation",
            title: isFrench ? "Bonjour ☀️" : "Good morning ☀️",
            body: isFrench
                ? "5 min de respiration pour bien démarrer ta journée"
                : "5 min of breathing to start your day right",
            hour: 9,
            minute: 0
        )

        // Evening notification (19h)
        scheduleDailyNotification(
            id: "daily_evening_journal",
            title: isFrench ? "Journal du soir 📝" : "Evening Journal 📝",
            body: isFrench
                ? "Comment s'est passée ta journée ? Prends 2 min pour écrire"
                : "How was your day? Take 2 min to write it down",
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
            title: isFrench ? "Ta série est en danger ⚠️" : "Your streak is in danger ⚠️",
            body: isFrench
                ? "1 seule tâche pour garder ta progression 🔥"
                : "Complete 1 task to keep your progress 🔥",
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

    // MARK: - TRIAL NOTIFICATIONS (Day 2 & Day 3)

    /// Schedule trial-specific notifications (disabled)
    func scheduleTrialNotifications() {
        // Disabled — Apple's native trial reminder handles this automatically
    }

    // MARK: - MILESTONE NOTIFICATIONS (Streaks, Badges)

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
        content.title = isFrench ? "Badge débloqué ! \(badgeIcon)" : "Badge Unlocked! \(badgeIcon)"
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

    // MARK: - CANCEL NOTIFICATIONS

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
        // 2 hours after quitting — curiosity gap
        scheduleNotificationFromNow(
            id: "reengagement_checkpoint_2h",
            title: isFrench ? "Ton plan est presque prêt" : "Your plan is almost ready",
            body: isFrench
                ? "Il te reste 2 min pour découvrir ton profil de stress personnalisé"
                : "2 min left to discover your personalized stress profile",
            daysFromNow: 0,
            hour: Calendar.current.component(.hour, from: Date().addingTimeInterval(2 * 3600)),
            minute: Calendar.current.component(.minute, from: Date().addingTimeInterval(2 * 3600))
        )

        // 24 hours — emotional pull
        scheduleNotificationFromNow(
            id: "reengagement_checkpoint_24h",
            title: isFrench ? "Tu mérites de dormir mieux ce soir" : "You deserve to sleep better tonight",
            body: isFrench
                ? "Ton parcours de 66 jours t'attend — commence maintenant"
                : "Your 66-day journey is waiting — start now",
            daysFromNow: 1,
            hour: 10,
            minute: 0
        )

        // 48 hours — urgency + loss aversion
        scheduleNotificationFromNow(
            id: "reengagement_checkpoint_48h",
            title: isFrench ? "Chaque jour sans agir, le stress s'installe" : "Every day without action, stress builds up",
            body: isFrench
                ? "Reprends là où tu t'es arrêté(e) — 66 jours pour tout changer"
                : "Pick up where you left off — 66 days to change everything",
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
            title: isFrench ? "Essai gratuit de 3 jours 🎁" : "3-day free trial 🎁",
            body: isFrench
                ? "Aucun engagement — annule quand tu veux. Ton corps te remerciera."
                : "No commitment — cancel anytime. Your body will thank you.",
            daysFromNow: 0,
            hour: Calendar.current.component(.hour, from: Date().addingTimeInterval(3600)),
            minute: Calendar.current.component(.minute, from: Date().addingTimeInterval(3600))
        )

        // 6 hours — future self visualization
        scheduleNotificationFromNow(
            id: "reengagement_paywall_6h",
            title: isFrench ? "Imagine-toi dans 66 jours" : "Imagine yourself in 66 days",
            body: isFrench
                ? "Plus calme. Mieux reposé(e). Plus concentré(e). C'est possible."
                : "Calmer. Better rested. More focused. It's possible.",
            daysFromNow: 0,
            hour: Calendar.current.component(.hour, from: Date().addingTimeInterval(6 * 3600)),
            minute: Calendar.current.component(.minute, from: Date().addingTimeInterval(6 * 3600))
        )

        // 24 hours — personal + scientific credibility
        scheduleNotificationFromNow(
            id: "reengagement_paywall_24h",
            title: isFrench ? "Le cortisol ne se régule pas tout seul" : "Cortisol doesn't regulate itself",
            body: isFrench
                ? "Un programme basé sur les neurosciences, fait pour toi. Essaie gratuitement."
                : "A neuroscience-based program, made for you. Try it free.",
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
                title: isFrench ? "Ton compte t'attend" : "Your account is waiting",
                body: isFrench
                    ? "2 min pour finaliser ton profil et accéder à ton plan personnalisé"
                    : "2 min to finish your profile and access your personalized plan",
                daysFromNow: 0,
                hour: Calendar.current.component(.hour, from: Date().addingTimeInterval(12 * 3600)),
                minute: Calendar.current.component(.minute, from: Date().addingTimeInterval(12 * 3600))
            )

            // 48 hours — emotional
            scheduleNotificationFromNow(
                id: "reengagement_auth_48h",
                title: isFrench ? "Le stress ne prend pas de pause" : "Stress doesn't take a break",
                body: isFrench
                    ? "Mais toi, tu peux apprendre à le gérer. Ton programme est prêt."
                    : "But you can learn to manage it. Your program is ready.",
                daysFromNow: 2,
                hour: 14,
                minute: 0
            )

            // 7 days — last chance
            scheduleNotificationFromNow(
                id: "reengagement_auth_7d",
                title: isFrench ? "On garde ta place 🎯" : "We're holding your spot 🎯",
                body: isFrench
                    ? "Ton plan de reset du cortisol en 66 jours est toujours disponible"
                    : "Your 66-day cortisol reset plan is still available",
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

    // MARK: - MILESTONE CONTENT

    /// Get milestone content based on streak days
    private func getMilestoneContent(for streakDays: Int) -> (title: String, body: String, emoji: String) {
        switch streakDays {
        case 3:
            return (
                isFrench ? "3 jours d'affilée ! 🔥" : "3 days in a row! 🔥",
                isFrench ? "L'habitude se construit. Continue comme ça !" : "You're building the habit! Keep it up",
                "🔥"
            )
        case 7:
            return (
                isFrench ? "1 semaine complète ! 🎉" : "1 full week! 🎉",
                isFrench ? "Ton système nerveux commence à se réguler" : "Your nervous system is starting to regulate",
                "🎉"
            )
        case 14:
            return (
                isFrench ? "2 semaines de série ! ⭐" : "2-week streak! ⭐",
                isFrench ? "L'habitude commence à s'ancrer — continue !" : "The habit is starting to stick — keep going!",
                "⭐"
            )
        case 30:
            return (
                isFrench ? "30 jours consécutifs ! 🚀" : "30 days straight! 🚀",
                isFrench ? "Tu es à mi-chemin des 66 jours. Champion(ne) !" : "You're halfway to 66 days. Champion!",
                "🚀"
            )
        case 66:
            return (
                isFrench ? "66 JOURS ! TU L'AS FAIT ! 🏆" : "66 DAYS! YOU DID IT! 🏆",
                isFrench ? "L'habitude est ancrée ! Tu es un(e) champion(ne) du bien-être" : "The habit is ingrained! You're a wellness champion",
                "🏆"
            )
        default:
            return (
                isFrench ? "\(streakDays) jours d'affilée ! 🔥" : "\(streakDays) days in a row! 🔥",
                isFrench ? "Continue vers les 66 jours !" : "Keep progressing towards 66 days!",
                "🔥"
            )
        }
    }
}
