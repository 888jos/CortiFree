//
//  RecoveryScheduler.swift
//  CortiFree
//
//  Local notifications for people who left before starting the free trial.
//  Spec: docs/app-notes/TRIAL_RECOVERY_NOTIFICATIONS_PLAN.md
//

import Foundation
import UserNotifications

/// Who a recovery notification is for.
enum RecoverySegment: String {
    /// Left the onboarding before creating an account.
    case earlyOnboarding = "A1"
    /// Has an account and a plan, left before the paywall.
    case planReady = "A2"
    /// Saw the paywall, didn't start the trial.
    case paywall = "B"
}

struct RecoveryMessage: Equatable {
    enum Timing: Equatable {
        /// Exact delay after the anchor (moved out of quiet hours).
        case after(TimeInterval)
        /// Calendar day after the anchor's day, at a local time.
        case day(Int, hour: Int, minute: Int)
    }

    /// Stable id, also used for the notification identifier and analytics ("B-3").
    let id: String
    let timing: Timing
    /// Localization prefix: "<key>.title" and "<key>.body".
    let key: String
    /// Superwall placement opened on tap; nil resumes the onboarding.
    let placement: String?
    /// Carries an offer: only sent to people who accepted offers.
    let isPromotional: Bool
    /// Product the offer sells; the message is skipped until it exists in the RevenueCat offering.
    var requiredProduct: String? = nil
}

struct RecoveryNotification: Equatable {
    let message: RecoveryMessage
    let date: Date
}

/// Recovery placements configured in Superwall (fall back to the main paywall when missing).
enum RecoveryPlacement {
    /// 14-day trial, valid 48 h from day 1 at 10:00.
    static let offer = "recovery_offer"
    /// Last chance, valid 48 h from day 7 at 10:00.
    static let lastChance = "recovery_last_chance"

    /// App Store products behind the offers (same subscription group, own introductory offer).
    static let trialProduct = "cortifree_yearly_trial14"
    static let discountProduct = "cortifree_yearly_discount"
}

// MARK: - Planner (pure, unit-tested)

enum RecoveryPlanner {
    static let dropOffDelay: TimeInterval = 3 * 60
    /// Two sequence messages never fire closer than this (after quiet-hour shifts).
    static let minimumGap: TimeInterval = 45 * 60
    /// Quiet hours: 21:30 → 8:00, delayed messages move to 8:30.
    static let quietStart = (hour: 21, minute: 30)
    static let quietEnd = (hour: 8, minute: 0)
    static let quietResume = (hour: 8, minute: 30)

    static let goals = ["sleep", "stress", "energy", "focus", "emotional"]

    static func sequence(for segment: RecoverySegment, goal: String?) -> [RecoveryMessage] {
        switch segment {
        case .earlyOnboarding:
            return onboardingSequence(prefix: "A1", key: "recovery.a1", goalKey: nil)
        case .planReady:
            let goalKey = goal.flatMap { goals.contains($0) ? "recovery.a2.goal.\($0)" : nil }
            return onboardingSequence(prefix: "A2", key: "recovery.a2", goalKey: goalKey)
        case .paywall:
            let goalKey = goal.flatMap { goals.contains($0) ? "recovery.b.goal.\($0)" : nil }
            let main = SuperwallPlacement.onboarding
            return [
                RecoveryMessage(id: "B-1", timing: .after(3600), key: "recovery.b.1", placement: main, isPromotional: false),
                RecoveryMessage(id: "B-2", timing: .after(4 * 3600), key: "recovery.b.2", placement: main, isPromotional: false),
                RecoveryMessage(id: "B-3", timing: .day(1, hour: 10, minute: 0), key: "recovery.b.3", placement: RecoveryPlacement.offer, isPromotional: true, requiredProduct: RecoveryPlacement.trialProduct),
                RecoveryMessage(id: "B-4", timing: .day(1, hour: 19, minute: 0), key: goalKey ?? "recovery.b.4", placement: main, isPromotional: false),
                RecoveryMessage(id: "B-5", timing: .day(2, hour: 19, minute: 0), key: "recovery.b.5", placement: RecoveryPlacement.offer, isPromotional: true, requiredProduct: RecoveryPlacement.trialProduct),
                RecoveryMessage(id: "B-6", timing: .day(3, hour: 8, minute: 30), key: "recovery.b.6", placement: RecoveryPlacement.offer, isPromotional: true, requiredProduct: RecoveryPlacement.trialProduct),
                RecoveryMessage(id: "B-7", timing: .day(4, hour: 19, minute: 0), key: "recovery.b.7", placement: main, isPromotional: false),
                RecoveryMessage(id: "B-8", timing: .day(6, hour: 12, minute: 30), key: "recovery.b.8", placement: main, isPromotional: false),
                RecoveryMessage(id: "B-9", timing: .day(7, hour: 10, minute: 0), key: "recovery.b.9", placement: RecoveryPlacement.lastChance, isPromotional: true, requiredProduct: RecoveryPlacement.discountProduct),
                RecoveryMessage(id: "B-10", timing: .day(8, hour: 19, minute: 0), key: "recovery.b.10", placement: RecoveryPlacement.lastChance, isPromotional: true, requiredProduct: RecoveryPlacement.discountProduct),
                RecoveryMessage(id: "B-11", timing: .day(14, hour: 10, minute: 0), key: "recovery.b.11", placement: main, isPromotional: false)
            ]
        }
    }

    private static func onboardingSequence(prefix: String, key: String, goalKey: String?) -> [RecoveryMessage] {
        let timings: [RecoveryMessage.Timing] = [
            .after(3600),
            .after(4 * 3600),
            .day(1, hour: 12, minute: 30),
            .day(1, hour: 19, minute: 0),
            .day(2, hour: 19, minute: 0),
            .day(3, hour: 12, minute: 30),
            .day(5, hour: 19, minute: 0),
            .day(7, hour: 10, minute: 0),
            .day(10, hour: 19, minute: 0),
            .day(14, hour: 10, minute: 0)
        ]
        return timings.enumerated().map { index, timing in
            let number = index + 1
            let messageKey = number == 4 ? (goalKey ?? "\(key).4") : "\(key).\(number)"
            return RecoveryMessage(id: "\(prefix)-\(number)", timing: timing, key: messageKey, placement: nil, isPromotional: false)
        }
    }

    /// The nudge sent 3 minutes after every drop-off; rotates between 3 texts.
    static func dropOffMessage(for segment: RecoverySegment, dropOffCount: Int) -> RecoveryMessage {
        let variant = (max(dropOffCount, 1) - 1) % 3 + 1
        let placement = segment == .paywall ? SuperwallPlacement.onboarding : nil
        return RecoveryMessage(id: "drop-\(segment.rawValue)", timing: .after(dropOffDelay),
                               key: "recovery.drop.\(segment.rawValue.lowercased()).\(variant)",
                               placement: placement, isPromotional: false)
    }

    /// Every identifier the scheduler may have created (to clear them all at once).
    static var allIdentifiers: [String] {
        let sequences = [RecoverySegment.earlyOnboarding, .planReady, .paywall].flatMap { sequence(for: $0, goal: nil) }
        let drops = [RecoverySegment.earlyOnboarding, .planReady, .paywall].map { dropOffMessage(for: $0, dropOffCount: 1) }
        return (sequences + drops).map { identifier(for: $0) }
    }

    static func identifier(for message: RecoveryMessage) -> String { "recovery_\(message.id)" }

    /// Future fire dates of a sequence, moved out of quiet hours and spaced by `minimumGap`.
    static func schedule(_ messages: [RecoveryMessage], anchor: Date, now: Date, includePromotional: Bool,
                         availableProducts: Set<String> = [], calendar: Calendar = .current) -> [RecoveryNotification] {
        var result: [RecoveryNotification] = []
        for message in messages where includePromotional || !message.isPromotional {
            if let product = message.requiredProduct, !availableProducts.contains(product) { continue }
            guard let date = fireDate(for: message.timing, anchor: anchor, calendar: calendar), date > now else { continue }
            if let last = result.last, date.timeIntervalSince(last.date) < minimumGap { continue }
            result.append(RecoveryNotification(message: message, date: date))
        }
        return result
    }

    static func fireDate(for timing: RecoveryMessage.Timing, anchor: Date, calendar: Calendar = .current) -> Date? {
        switch timing {
        case .after(let delay):
            return shiftOutOfQuietHours(anchor.addingTimeInterval(delay), calendar: calendar)
        case .day(let offset, let hour, let minute):
            guard let day = calendar.date(byAdding: .day, value: offset, to: calendar.startOfDay(for: anchor)) else { return nil }
            return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day)
        }
    }

    static func isQuiet(_ date: Date, calendar: Calendar = .current) -> Bool {
        let parts = calendar.dateComponents([.hour, .minute], from: date)
        let minutes = (parts.hour ?? 0) * 60 + (parts.minute ?? 0)
        return minutes >= quietStart.hour * 60 + quietStart.minute || minutes < quietEnd.hour * 60 + quietEnd.minute
    }

    static func shiftOutOfQuietHours(_ date: Date, calendar: Calendar = .current) -> Date {
        guard isQuiet(date, calendar: calendar) else { return date }
        let hour = calendar.component(.hour, from: date)
        // Evening: next morning. After midnight: this morning.
        let base = hour >= quietEnd.hour ? calendar.date(byAdding: .day, value: 1, to: date) ?? date : date
        return calendar.date(bySettingHour: quietResume.hour, minute: quietResume.minute, second: 0, of: base) ?? date
    }

    /// Offer windows, both 48 h long: the 14-day trial from day 1 at 10:00, the last chance from day 7 at 10:00.
    static func activePlacement(for requested: String, paywallSeenAt: Date?, now: Date,
                                calendar: Calendar = .current) -> String {
        let windowStartDay: Int
        switch requested {
        case RecoveryPlacement.offer: windowStartDay = 1
        case RecoveryPlacement.lastChance: windowStartDay = 7
        default: return requested
        }
        guard let anchor = paywallSeenAt,
              let start = fireDate(for: .day(windowStartDay, hour: 10, minute: 0), anchor: anchor, calendar: calendar),
              now >= start, now < start.addingTimeInterval(48 * 3600) else {
            return SuperwallPlacement.onboarding
        }
        return requested
    }

    /// Plan goal from the onboarding answers (first matching reason).
    static func goal(fromReasonCodes codes: [String]) -> String? {
        for code in codes {
            switch code {
            case "sleep": return "sleep"
            case "anxiety": return "stress"
            case "energy": return "energy"
            case "focus": return "focus"
            case "mental", "difficult": return "emotional"
            default: continue
            }
        }
        return codes.isEmpty ? nil : "stress"
    }
}

// MARK: - Scheduler (state + UNUserNotificationCenter)

@MainActor
final class RecoveryScheduler {
    static let shared = RecoveryScheduler()

    private let defaults = UserDefaults.standard
    private let center = UNUserNotificationCenter.current()

    private enum Key {
        static let holdout = "recovery.holdout"
        static let offersOptIn = "recovery.offersOptIn"
        static let onboardingAnchor = "recovery.onboardingAnchor"
        static let onboardingAnchorStep = "recovery.onboardingAnchorStep"
        static let paywallSeenAt = "recovery.paywallFirstSeenAt"
        static let dropOffCount = "recovery.dropOffCount"
        static let legacyCleared = "recovery.legacyCleared"
    }

    /// Steps from `authentication` on: the user has an account and a plan (segment A2).
    private static let planReadySteps: Set<String> = [
        "authentication", "loading", "notificationPermissions", "planReady", "planDay", "planWeeks",
        "commitmentPledge", "complete",
        // Steps of older builds (8-habits screens)
        "eightHabitsIntro", "weekProgress", "eightHabits", "habitsProgress"
    ]

    private init() {}

    // MARK: State

    /// 10% of users never get recovery notifications, to measure the real lift.
    var isInHoldout: Bool {
        if defaults.object(forKey: Key.holdout) == nil {
            let holdout = Int.random(in: 0..<100) < 10
            defaults.set(holdout, forKey: Key.holdout)
            AmplitudeManager.shared.setUserProperties(["recovery_holdout": holdout])
        }
        return defaults.bool(forKey: Key.holdout)
    }

    /// Consent to promotional notifications (offers), given on the notification screen.
    var offersOptIn: Bool {
        get { defaults.object(forKey: Key.offersOptIn) as? Bool ?? false }
        set {
            defaults.set(newValue, forKey: Key.offersOptIn)
            AmplitudeManager.shared.setUserProperties(["recovery_offers_opt_in": newValue])
            syncToServer()
        }
    }

    var paywallSeenAt: Date? { defaults.object(forKey: Key.paywallSeenAt) as? Date }

    func markPaywallSeen(now: Date = Date()) {
        guard paywallSeenAt == nil else { return }
        defaults.set(now, forKey: Key.paywallSeenAt)
        syncToServer()
    }

    /// Mirrors the recovery state to Convex, which forwards it to OneSignal for the email
    /// journeys (convex/recovery.ts). Needs an account, so it starts at the authentication step.
    func syncToServer() {
        guard Auth.auth().currentUser != nil else { return }
        var args: [String: Any] = [
            "step": defaults.string(forKey: "last_onboarding_checkpoint") ?? "",
            "holdout": isInHoldout,
            "timezone": TimeZone.current.identifier
        ]
        if let seen = paywallSeenAt { args["paywallSeenAt"] = (seen.timeIntervalSince1970 * 1000).rounded() }
        if let goal = currentGoal() { args["goal"] = goal }
        // Only an explicit answer on the notification screen counts as consent.
        if defaults.object(forKey: Key.offersOptIn) != nil { args["offersOptIn"] = offersOptIn }
        Task {
            do {
                let _: JSONValue = try await ConvexBackend.shared.call(.mutation, path: "recovery:sync", args: args)
            } catch {
                #if DEBUG
                print("⚠️ recovery:sync failed: \(error.localizedDescription)")
                #endif
            }
        }
    }

    // MARK: Lifecycle

    func appDidEnterBackground() {
        defaults.set(defaults.integer(forKey: Key.dropOffCount) + 1, forKey: Key.dropOffCount)
        reschedule(includeDropOff: true)
    }

    /// Back in the app: the 3-minute nudge is no longer needed.
    func appDidBecomeActive() {
        let drops = [RecoverySegment.earlyOnboarding, .planReady, .paywall]
            .map { RecoveryPlanner.identifier(for: RecoveryPlanner.dropOffMessage(for: $0, dropOffCount: 1)) }
        center.removePendingNotificationRequests(withIdentifiers: drops)
    }

    func cancelAll(reason: String) {
        center.removePendingNotificationRequests(withIdentifiers: RecoveryPlanner.allIdentifiers)
        #if DEBUG
        print("🔕 Recovery notifications cancelled (\(reason))")
        #endif
    }

    /// Quiet notifications (Notification Center only, no prompt) until the user answers the real prompt.
    func requestProvisionalAuthorizationIfNeeded() {
        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .notDetermined else { return }
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge, .provisional]) { granted, _ in
                AnalyticsManager.shared.track(event: "notification_permission_provisional", properties: ["granted": granted])
            }
        }
    }

    /// The placement to open for a tapped notification (expired offers fall back to the main paywall).
    func placementToPresent(for requested: String, now: Date = Date()) -> String {
        RecoveryPlanner.activePlacement(for: requested, paywallSeenAt: paywallSeenAt, now: now)
    }

    // MARK: Scheduling

    /// Idempotent: clears every pending recovery notification and schedules what is still due.
    func reschedule(includeDropOff: Bool = false, now: Date = Date()) {
        clearLegacyNotificationsOnce()

        guard let segment = currentSegment() else {
            cancelAll(reason: "not_eligible")
            return
        }
        guard !isInHoldout else {
            cancelAll(reason: "holdout")
            return
        }

        let anchor = anchorDate(for: segment, now: now)
        let goal = currentGoal()
        let messages = RecoveryPlanner.sequence(for: segment, goal: goal)
        let products = Set(RevenueCatManager.shared.currentOffering?.availablePackages
            .map(\.storeProduct.productIdentifier) ?? [])
        var notifications = RecoveryPlanner.schedule(messages, anchor: anchor, now: now,
                                                     includePromotional: offersOptIn, availableProducts: products)
        if includeDropOff {
            let drop = RecoveryPlanner.dropOffMessage(for: segment, dropOffCount: defaults.integer(forKey: Key.dropOffCount))
            notifications.insert(RecoveryNotification(message: drop, date: now.addingTimeInterval(RecoveryPlanner.dropOffDelay)), at: 0)
        }

        center.getNotificationSettings { settings in
            let status = settings.authorizationStatus
            guard [.authorized, .provisional, .ephemeral].contains(status) else { return }
            Task { @MainActor in
                self.cancelAll(reason: "reschedule")
                for notification in notifications {
                    self.add(notification, segment: segment)
                }
                AnalyticsManager.shared.track(event: "recovery_scheduled", properties: [
                    "segment": segment.rawValue,
                    "message_ids": notifications.map(\.message.id).joined(separator: ","),
                    "count": notifications.count,
                    "includes_drop_off": includeDropOff,
                    "permission": status == .provisional ? "provisional" : "authorized",
                    "goal": goal ?? ""
                ])
            }
        }
    }

    private func add(_ notification: RecoveryNotification, segment: RecoverySegment, identifier: String? = nil) {
        let message = notification.message
        let content = UNMutableNotificationContent()
        content.title = LanguageManager.shared.localizedString(for: "\(message.key).title")
        content.body = LanguageManager.shared.localizedString(for: "\(message.key).body")
        content.sound = .default
        content.threadIdentifier = "recovery"

        var link = URLComponents()
        link.scheme = "cortifree"
        if let placement = message.placement {
            link.host = "paywall"
            link.queryItems = [URLQueryItem(name: "placement", value: placement), URLQueryItem(name: "message_id", value: message.id)]
        } else {
            link.host = "onboarding"
            link.path = "/resume"
            link.queryItems = [URLQueryItem(name: "message_id", value: message.id)]
        }
        content.userInfo = [
            "deeplink": link.url?.absoluteString ?? "",
            "campaign": "recovery",
            "message_id": message.id,
            "segment": segment.rawValue
        ]

        let interval = max(1, notification.date.timeIntervalSinceNow)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request = UNNotificationRequest(identifier: identifier ?? RecoveryPlanner.identifier(for: message),
                                            content: content, trigger: trigger)
        center.add(request) { error in
            #if DEBUG
            if let error { print("❌ Recovery notification \(message.id): \(error.localizedDescription)") }
            #endif
        }
    }

    // MARK: Segment & anchors

    private func currentSegment() -> RecoverySegment? {
        let revenueCat = RevenueCatManager.shared
        if revenueCat.isPremiumStatusReady,
           revenueCat.hasPremiumEntitlement || revenueCat.hasInactivePreviousProEntitlement {
            return nil // subscribers, and lapsed users who get the winback paywall instead
        }
        let sawPaywall = paywallSeenAt != nil || defaults.bool(forKey: "hasSeenPaywall")
        if sawPaywall {
            // Never invite someone to start a trial before knowing they don't have one.
            guard revenueCat.isPremiumStatusReady else { return nil }
            if paywallSeenAt == nil { markPaywallSeen() }
            return .paywall
        }
        guard !defaults.bool(forKey: "onboardingV2Completed") else { return nil }
        let step = defaults.string(forKey: "last_onboarding_checkpoint") ?? ""
        return Self.planReadySteps.contains(step) ? .planReady : .earlyOnboarding
    }

    private func anchorDate(for segment: RecoverySegment, now: Date) -> Date {
        if segment == .paywall { return paywallSeenAt ?? now }
        // The onboarding sequence restarts only when the user moved to another step.
        let step = defaults.string(forKey: "last_onboarding_checkpoint") ?? ""
        if let anchor = defaults.object(forKey: Key.onboardingAnchor) as? Date,
           defaults.string(forKey: Key.onboardingAnchorStep) == step {
            return anchor
        }
        defaults.set(now, forKey: Key.onboardingAnchor)
        defaults.set(step, forKey: Key.onboardingAnchorStep)
        return now
    }

    private func currentGoal() -> String? {
        guard let profile = PersonalPlanStore.shared.storedOnboardingProfile() else { return nil }
        return RecoveryPlanner.goal(fromReasonCodes: profile.reasonCodes)
    }

    /// Notifications scheduled by the previous re-engagement system.
    private func clearLegacyNotificationsOnce() {
        guard !defaults.bool(forKey: Key.legacyCleared) else { return }
        defaults.set(true, forKey: Key.legacyCleared)
        center.removePendingNotificationRequests(withIdentifiers: [
            "reengagement_checkpoint_2h", "reengagement_checkpoint_24h", "reengagement_checkpoint_48h",
            "reengagement_paywall_1h", "reengagement_paywall_6h", "reengagement_paywall_24h",
            "reengagement_auth_12h", "reengagement_auth_48h", "reengagement_auth_7d"
        ])
    }
}

#if DEBUG
// MARK: - Debug (RecoveryDebugView)

extension RecoveryScheduler {
    struct DebugState {
        let segment: String
        let holdout: Bool
        let offersOptIn: Bool
        let paywallSeenAt: Date?
        let onboardingAnchor: Date?
        let dropOffCount: Int
    }

    var debugState: DebugState {
        DebugState(
            segment: currentSegment()?.rawValue ?? "—",
            holdout: defaults.bool(forKey: Key.holdout),
            offersOptIn: offersOptIn,
            paywallSeenAt: paywallSeenAt,
            onboardingAnchor: defaults.object(forKey: Key.onboardingAnchor) as? Date,
            dropOffCount: defaults.integer(forKey: Key.dropOffCount)
        )
    }

    var debugGoal: String? { currentGoal() }

    /// Sends one message now (after `delay`), with its real copy and deep link.
    func debugSend(_ message: RecoveryMessage, segment: RecoverySegment, after delay: TimeInterval = 5) {
        // Own identifier: leaving the app reschedules (and clears) the real sequence.
        add(RecoveryNotification(message: message, date: Date().addingTimeInterval(delay)), segment: segment,
            identifier: "debug_recovery_\(message.id)")
    }

    func debugSetHoldout(_ holdout: Bool) {
        defaults.set(holdout, forKey: Key.holdout)
    }

    /// Back to a fresh install state for the recovery system (pending notifications included).
    func debugReset() {
        cancelAll(reason: "debug_reset")
        for key in [Key.holdout, Key.offersOptIn, Key.onboardingAnchor, Key.onboardingAnchorStep,
                    Key.paywallSeenAt, Key.dropOffCount] {
            defaults.removeObject(forKey: key)
        }
    }
}
#endif
