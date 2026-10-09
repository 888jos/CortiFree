//
//  PlanReminderScheduler.swift
//  CortiFree
//
//  Local notifications for subscribers following their plan (RecoveryScheduler handles the
//  people without a subscription; identifiers never overlap).
//  - daily reminder naming today's plan session (replaces the generic morning reminder)
//  - cycle transition: day 26, day 28 evening (review ready), day 29 morning (next cycle)
//  Spec: docs/app-notes/RETENTION_POST_28_DAYS_PLAN.md (0.4).
//
//  Same rules as the recovery notifications: fixed identifiers, idempotent rescheduling on every
//  app open / plan change / completion, nothing during quiet hours (21:30 → 8:00).
//

import Foundation
import UIKit
import UserNotifications

struct PlanReminder: Equatable {
    enum Kind: String { case daily, transition }

    /// Stable id (notification identifier suffix, analytics).
    let id: String
    let kind: Kind
    let date: Date
    /// Localization prefix: "<key>.title" and "<key>.body".
    let key: String
    /// Format arguments of the body.
    let args: [String]
    let link: String
}

struct PlanReminderContext {
    let now: Date
    let planStart: Date
    let cycle: Int
    /// Title of the main session for plan days (at least today and the next days).
    let sessionTitles: [Int: String]
    /// First session of the next cycle (named in the day-29 notification).
    let nextCycleFirstSession: String?
    let reminderTime: (hour: Int, minute: Int)
    let doneToday: Bool
}

// MARK: - Planner (pure, unit-tested)

enum PlanReminderPlanner {
    static let identifierPrefix = "plan_reminder_"
    static let dailyIDs = ["daily_0", "daily_1"]
    static let transitionIDs = ["j26", "j28", "j29"]
    static var allIDs: [String] { dailyIDs + transitionIDs }

    static let reviewTime = (hour: 19, minute: 30)
    /// The day-29 message is a morning one, even when the usual reminder is later.
    static let latestMorning = (hour: 12, minute: 0)
    static let fallbackMorning = (hour: 9, minute: 30)

    static let planLink = "cortifree://tasks"
    static let reviewLink = "cortifree://tasks?bilan=1"

    static func reminders(_ context: PlanReminderContext, calendar: Calendar = .current) -> [PlanReminder] {
        let today = planDay(of: context.now, start: context.planStart, calendar: calendar)
        var result: [PlanReminder] = []

        // Cycle transitions (only those still ahead).
        let transitions: [(id: String, day: Int, time: (hour: Int, minute: Int), key: String, args: [String], link: String)] = [
            ("j26", 26, context.reminderTime, "plan_reminder.j26", [], planLink),
            ("j28", 28, reviewTime, "plan_reminder.j28", [], reviewLink),
            ("j29", 29, morning(context.reminderTime),
             context.nextCycleFirstSession == nil ? "plan_reminder.j29_generic" : "plan_reminder.j29",
             ["\(context.cycle + 1)"] + [context.nextCycleFirstSession].compactMap { $0 }, planLink)
        ]
        var transitionDays = Set<Int>()
        for t in transitions where t.day >= today {
            // Days 26 and 29 replace the daily reminder; the review (day 28) comes in the evening, on top.
            if t.id != "j28" { transitionDays.insert(t.day) }
            guard let date = fireDate(planDay: t.day, time: t.time, start: context.planStart, calendar: calendar),
                  date > context.now.addingTimeInterval(60) else { continue }
            result.append(PlanReminder(id: t.id, kind: .transition, date: date, key: t.key, args: t.args, link: t.link))
        }

        // Daily reminder for today and tomorrow (rescheduled on every open), naming the session.
        for (offset, id) in dailyIDs.enumerated() {
            let day = today + offset
            guard day <= PersonalPlan.length, !transitionDays.contains(day) else { continue }
            if offset == 0 && context.doneToday { continue }
            guard let date = fireDate(planDay: day, time: context.reminderTime, start: context.planStart, calendar: calendar),
                  date > context.now.addingTimeInterval(60) else { continue }
            let title = context.sessionTitles[day]
            result.append(PlanReminder(id: id, kind: .daily, date: date,
                                       key: title == nil ? "plan_reminder.daily_generic" : "plan_reminder.daily",
                                       args: [title].compactMap { $0 }, link: planLink))
        }

        return result
            .filter { !RecoveryPlanner.isQuiet($0.date, calendar: calendar) }
            .sorted { $0.date < $1.date }
    }

    /// 1-based plan day of a date (like PersonalPlan.dayIndex, without the clamp at 1).
    static func planDay(of date: Date, start: Date, calendar: Calendar = .current) -> Int {
        (calendar.dateComponents([.day], from: calendar.startOfDay(for: start), to: calendar.startOfDay(for: date)).day ?? 0) + 1
    }

    static func fireDate(planDay: Int, time: (hour: Int, minute: Int), start: Date, calendar: Calendar = .current) -> Date? {
        guard let day = calendar.date(byAdding: .day, value: planDay - 1, to: calendar.startOfDay(for: start)) else { return nil }
        return calendar.date(bySettingHour: time.hour, minute: time.minute, second: 0, of: day)
    }

    /// A reminder time kept out of quiet hours (8:30 → 21:00).
    static func clamped(_ time: (hour: Int, minute: Int)) -> (hour: Int, minute: Int) {
        let minutes = max(8 * 60 + 30, min(21 * 60, time.hour * 60 + time.minute))
        return (minutes / 60, minutes % 60)
    }

    private static func morning(_ time: (hour: Int, minute: Int)) -> (hour: Int, minute: Int) {
        time.hour * 60 + time.minute < latestMorning.hour * 60 + latestMorning.minute ? time : fallbackMorning
    }
}

// MARK: - Scheduler

@MainActor
final class PlanReminderScheduler {
    static let shared = PlanReminderScheduler()

    /// True while this scheduler owns the daily reminder (NotificationService skips its generic one).
    static let activeKey = "planReminders.active"

    private let center = UNUserNotificationCenter.current()
    private var observers: [NSObjectProtocol] = []
    private var pending: Task<Void, Never>?

    private init() {}

    /// Starts listening to app opens, plan changes and completions. Safe to call more than once.
    func start() {
        guard observers.isEmpty else { return }
        let names: [Notification.Name] = [
            UIApplication.didBecomeActiveNotification, UIApplication.didEnterBackgroundNotification,
            .personalPlanDidChange, Notification.Name("TaskValidated"), Notification.Name("TaskSkippedAfterValidation")
        ]
        observers = names.map { name in
            NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { _ in
                Task { @MainActor in PlanReminderScheduler.shared.scheduleSoon() }
            }
        }
        scheduleSoon()
    }

    /// Coalesces bursts of events (open + plan load + statuses) into one reschedule.
    func scheduleSoon() {
        pending?.cancel()
        pending = Task {
            try? await Task.sleep(for: .seconds(1.5))
            guard !Task.isCancelled else { return }
            await reschedule()
        }
    }

    /// Idempotent: clears this scheduler's notifications and schedules what is still due.
    func reschedule(now: Date = Date()) async {
        let settings = await center.notificationSettings()
        let authorized = [.authorized, .ephemeral].contains(settings.authorizationStatus)
        let revenueCat = RevenueCatManager.shared
        // Unknown subscription status (launch): change nothing until it is known.
        guard revenueCat.isPremiumStatusReady else { return }
        guard authorized, !NotificationService.shared.userDisabledNotifications,
              revenueCat.hasPremiumEntitlement, let plan = PersonalPlanStore.shared.plan else {
            deactivate()
            return
        }

        let reminders = PlanReminderPlanner.reminders(context(for: plan, now: now))
        UserDefaults.standard.set(true, forKey: Self.activeKey)
        // The generic morning reminder is replaced by the plan one.
        center.removePendingNotificationRequests(withIdentifiers: ["daily_morning_meditation"])
        center.removePendingNotificationRequests(withIdentifiers: PlanReminderPlanner.allIDs.map(identifier))
        for reminder in reminders { add(reminder) }
        AnalyticsManager.shared.track(event: "plan_reminders_scheduled", properties: [
            "ids": reminders.map(\.id).joined(separator: ","), "count": reminders.count,
            "cycle": plan.cycle, "plan_day": plan.dayIndex(on: now)
        ])
    }

    private func deactivate() {
        center.removePendingNotificationRequests(withIdentifiers: PlanReminderPlanner.allIDs.map(identifier))
        guard UserDefaults.standard.bool(forKey: Self.activeKey) else { return }
        UserDefaults.standard.set(false, forKey: Self.activeKey)
        // Give the generic daily reminder back.
        NotificationService.shared.syncDailyNotificationsWithPreference()
    }

    private func identifier(_ id: String) -> String { PlanReminderPlanner.identifierPrefix + id }

    // MARK: Context

    func context(for plan: PersonalPlan, now: Date) -> PlanReminderContext {
        let today = plan.dayIndex(on: now)
        var titles: [Int: String] = [:]
        for day in today..<(today + 3) where day <= PersonalPlan.length {
            titles[day] = Self.mainSessionTitle(plan.day(day))
        }
        var nextFirst: String?
        if today <= PersonalPlan.length, let start = Calendar.current.date(byAdding: .day, value: PersonalPlan.length, to: plan.startDate) {
            nextFirst = Self.mainSessionTitle(PersonalPlanStore.shared.nextCyclePlan(startDate: start).day(1))
        }
        let morning = NotificationService.shared.morningReminderComponents
        return PlanReminderContext(
            now: now, planStart: plan.startDate, cycle: plan.cycle, sessionTitles: titles,
            nextCycleFirstSession: nextFirst,
            reminderTime: PlanReminderPlanner.clamped(morning),
            doneToday: Self.hasCompletion(on: now)
        )
    }

    /// The guided session of the day (else its breathing exercise).
    static func mainSessionTitle(_ day: PlanDay?) -> String? {
        guard let day else { return nil }
        let item = day.items.first { $0.kind == .audio } ?? day.items.first { $0.kind == .breathing }
        return item?.display(week: day.week, short: false).title
    }

    static func completions() -> [LocalProgressStore.Completion] {
        LocalProgressStore.load(for: Auth.auth().currentUser?.uid ?? UserPersistence.localUserID)
    }

    static func hasCompletion(on date: Date) -> Bool {
        completions().contains { Calendar.current.isDate($0.completedAt, inSameDayAs: date) }
    }

    // MARK: Notification

    private func add(_ reminder: PlanReminder) {
        let content = UNMutableNotificationContent()
        let language = LanguageManager.shared
        content.title = language.localizedString(for: "\(reminder.key).title")
        let body = language.localizedString(for: "\(reminder.key).body")
        content.body = reminder.args.isEmpty ? body : String(format: body, arguments: reminder.args.map { $0 as CVarArg })
        content.sound = .default
        content.threadIdentifier = "plan"
        content.userInfo = [
            "deeplink": reminder.link,
            "campaign": PlanReminderScheduler.campaign,
            "message_id": reminder.id
        ]
        let interval = max(1, reminder.date.timeIntervalSinceNow)
        let request = UNNotificationRequest(identifier: identifier(reminder.id), content: content,
                                            trigger: UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false))
        center.add(request) { error in
            #if DEBUG
            if let error { print("❌ Plan reminder \(reminder.id): \(error.localizedDescription)") }
            #endif
        }
    }

    static let campaign = "plan_engagement"
}
