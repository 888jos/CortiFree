//
//  PlanReminderScheduler.swift
//  CortiFree
//
//  Local notifications for subscribers following their plan (RecoveryScheduler handles the
//  people without a subscription; identifiers never overlap).
//  - daily reminder naming today's plan session, at the user's usual practice time
//    (replaces the generic morning reminder)
//  - cycle transition: day 26, day 28 evening (review ready), day 29 morning (next cycle)
//  - streak at risk at 20:00 when nothing is done yet
//  - weekly summary on Sunday evening
//  - inactive users: day +2, +4, +7 without opening, then nothing until the next open
//  Spec: docs/app-notes/RETENTION_POST_28_DAYS_PLAN.md (0.4, 2.1).
//
//  Same rules as the recovery notifications: fixed identifiers, idempotent rescheduling on every
//  app open / plan change / completion, nothing during quiet hours (21:30 → 8:00).
//

import Foundation
import UIKit
import UserNotifications

struct PlanReminder: Equatable {
    enum Kind: String { case daily, transition, streak, weekly, inactive }

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
    /// Current streak (including today when something is done).
    var streak: Int = 0
    /// Breathing / guided sessions done since Monday, and their minutes.
    var weekSessions: Int = 0
    var weekMinutes: Int = 0
}

// MARK: - Planner (pure, unit-tested)

enum PlanReminderPlanner {
    static let identifierPrefix = "plan_reminder_"
    static let dailyIDs = ["daily_0", "daily_1"]
    static let transitionIDs = ["j26", "j28", "j29"]
    static let streakIDs = ["streak_0", "streak_1"]
    static let weeklyID = "weekly"
    /// Days without opening the app after which we nudge (3 messages, then silence).
    static let inactiveDays = [2, 4, 7]
    static var inactiveIDs: [String] { inactiveDays.map { "inactive_\($0)" } }
    static var allIDs: [String] { dailyIDs + transitionIDs + streakIDs + [weeklyID] + inactiveIDs }

    static let streakTime = (hour: 20, minute: 0)
    static let weeklyTime = (hour: 19, minute: 0)

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

        // Inactive: the plan reminders stop after tomorrow; three nudges follow, then silence until
        // the next open (every open reschedules from scratch).
        let contentDays = Set(result.map { planDay(of: $0.date, start: context.planStart, calendar: calendar) })
        for (index, offset) in inactiveDays.enumerated() {
            let day = today + offset
            guard !contentDays.contains(day),
                  let date = fireDate(planDay: day, time: context.reminderTime, start: context.planStart, calendar: calendar) else { continue }
            let title = index == 0 ? context.sessionTitles[day] : nil
            let key = index == 0 && title == nil ? "plan_reminder.inactive_generic.1" : "plan_reminder.inactive.\(index + 1)"
            result.append(PlanReminder(id: "inactive_\(offset)", kind: .inactive, date: date, key: key,
                                       args: [title].compactMap { $0 }, link: planLink))
        }

        // Streak at risk: tonight if nothing is done yet, tomorrow night if today is done (the
        // reminder is removed as soon as something gets validated).
        if context.streak >= 1 {
            let offset = context.doneToday ? 1 : 0
            if let date = fireDate(planDay: today + offset, time: streakTime, start: context.planStart, calendar: calendar),
               date > context.now.addingTimeInterval(60) {
                result.append(PlanReminder(id: streakIDs[offset], kind: .streak, date: date, key: "plan_reminder.streak",
                                           args: ["\(context.streak)"], link: planLink))
            }
        }

        // Weekly summary, Sunday evening of the current week.
        if context.weekSessions > 0, let sunday = upcomingSunday(after: context.now, calendar: calendar),
           let date = calendar.date(bySettingHour: weeklyTime.hour, minute: weeklyTime.minute, second: 0, of: sunday),
           date > context.now.addingTimeInterval(60) {
            result.append(PlanReminder(id: weeklyID, kind: .weekly, date: date, key: "plan_reminder.weekly",
                                       args: ["\(context.weekSessions)", "\(context.weekMinutes)"], link: planLink))
        }

        return result
            .filter { !RecoveryPlanner.isQuiet($0.date, calendar: calendar) }
            .sorted { $0.date < $1.date }
    }

    /// Sunday of the week containing `date` (weeks start on Monday), at midnight.
    static func upcomingSunday(after date: Date, calendar: Calendar = .current) -> Date? {
        let weekday = calendar.component(.weekday, from: date) // 1 = Sunday
        let daysToSunday = weekday == 1 ? 0 : 8 - weekday
        return calendar.date(byAdding: .day, value: daysToSunday, to: calendar.startOfDay(for: date))
    }

    /// Monday 00:00 of the week containing `date`.
    static func startOfWeek(_ date: Date, calendar: Calendar = .current) -> Date {
        let weekday = calendar.component(.weekday, from: date)
        let back = (weekday + 5) % 7 // Monday → 0, Sunday → 6
        return calendar.date(byAdding: .day, value: -back, to: calendar.startOfDay(for: date)) ?? date
    }

    /// Usual practice time: average time of the first completion of each of the last 7 days,
    /// rounded to 5 minutes. Needs at least 2 days of practice.
    static func usualPracticeTime(_ completions: [Date], now: Date, calendar: Calendar = .current) -> (hour: Int, minute: Int)? {
        let since = calendar.date(byAdding: .day, value: -7, to: calendar.startOfDay(for: now)) ?? now
        var firstOfDay: [Date: Int] = [:]
        for date in completions where date >= since && date <= now {
            let parts = calendar.dateComponents([.hour, .minute], from: date)
            let minutes = (parts.hour ?? 0) * 60 + (parts.minute ?? 0)
            let day = calendar.startOfDay(for: date)
            firstOfDay[day] = min(firstOfDay[day] ?? .max, minutes)
        }
        guard firstOfDay.count >= 2 else { return nil }
        let average = Double(firstOfDay.values.reduce(0, +)) / Double(firstOfDay.count)
        let rounded = Int((average / 5).rounded()) * 5
        return (rounded / 60, rounded % 60)
    }

    /// Sessions (breathing + guided) and minutes since Monday.
    static func weekSummary(_ completions: [LocalProgressStore.Completion], now: Date, calendar: Calendar = .current) -> (sessions: Int, minutes: Int) {
        let monday = startOfWeek(now, calendar: calendar)
        let practice = completions.filter { $0.completedAt >= monday && $0.completedAt <= now && ["breathing", "meditation"].contains($0.habitID) }
        return (practice.count, practice.reduce(0) { $0 + $1.durationSeconds } / 60)
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
            .personalPlanDidChange, Notification.Name("TaskValidated"), Notification.Name("TaskSkippedAfterValidation"),
            // The streak is recomputed from the server after an app open: re-plan with the fresh value.
            Notification.Name("StreakUpdated")
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

        let reminderContext = context(for: plan, now: now)
        let reminders = PlanReminderPlanner.reminders(reminderContext)
        UserDefaults.standard.set(true, forKey: Self.activeKey)
        // The generic morning reminder is replaced by the plan one.
        center.removePendingNotificationRequests(withIdentifiers: ["daily_morning_meditation"])
        center.removePendingNotificationRequests(withIdentifiers: PlanReminderPlanner.allIDs.map(identifier))
        for reminder in reminders { add(reminder) }
        AnalyticsManager.shared.track(event: "plan_reminders_scheduled", properties: [
            "ids": reminders.map(\.id).joined(separator: ","), "count": reminders.count,
            "reminder_time": String(format: "%02d:%02d", reminderContext.reminderTime.hour, reminderContext.reminderTime.minute),
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
        for offset in PlanReminderPlanner.inactiveDays where today + offset <= PersonalPlan.length {
            titles[today + offset] = Self.mainSessionTitle(plan.day(today + offset))
        }
        let completions = Self.completions()
        // The user's own rhythm first; the morning reminder setting until there is one.
        let usual = PlanReminderPlanner.usualPracticeTime(completions.map(\.completedAt), now: now)
        let week = PlanReminderPlanner.weekSummary(completions, now: now)
        return PlanReminderContext(
            now: now, planStart: plan.startDate, cycle: plan.cycle, sessionTitles: titles,
            nextCycleFirstSession: nextFirst,
            reminderTime: PlanReminderPlanner.clamped(usual ?? NotificationService.shared.morningReminderComponents),
            doneToday: completions.contains { Calendar.current.isDate($0.completedAt, inSameDayAs: now) },
            streak: StreakService.current,
            weekSessions: week.sessions, weekMinutes: week.minutes
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
