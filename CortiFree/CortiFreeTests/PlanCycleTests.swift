//
//  PlanCycleTests.swift
//  CortiFreeTests
//
//  After the 28 days: cycle review (bilan), automatic continuation helpers, plan reminders.
//

import Foundation
import Testing
@testable import CortiFree

struct PlanCycleTests {

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Paris")!
        return calendar
    }

    private func date(_ day: Int, _ hour: Int = 12, _ minute: Int = 0, month: Int = 10) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: hour, minute: minute))!
    }

    private func plan(start: Date = Date(), cycle: Int = 1) -> PersonalPlan {
        PersonalPlanGenerator.generate(profile: PlanProfile(reasonCodes: ["anxiety"]), startDate: start, cycle: cycle)
    }

    private func check(_ score: Int, on date: Date) -> AnxietyCheckResult {
        // 7 answers summing to `score` (max 3 each).
        var answers = Array(repeating: 0, count: 7)
        var left = score
        for i in 0..<7 where left > 0 { answers[i] = min(3, left); left -= answers[i] }
        return AnxietyCheckResult(date: date, answers: answers, source: .app)
    }

    // MARK: Review stats

    @Test func statsCountSessionsMinutesAndBestStreak() {
        let p = plan()
        var done: [Int: Set<String>] = [:]
        // Days 1–5 and 10–12: breathing done; day 2 also the guided session.
        for day in [1, 2, 3, 4, 5, 10, 11, 12] { done[day] = ["plan_breathing"] }
        done[2]?.insert("plan_meditation")

        let stats = PlanCycleReview.stats(plan: p, done: done, anxietyResults: [])
        let breathingMinutes = [1, 2, 3, 4, 5, 10, 11, 12].compactMap { p.day($0)?.items.first { $0.kind == .breathing }?.minutes }.reduce(0, +)
        let audioMinutes = p.day(2)?.items.first { $0.id == "meditation" }?.minutes ?? 0

        #expect(stats.sessionsCompleted == 9)
        #expect(stats.minutesPracticed == breathingMinutes + audioMinutes)
        #expect(stats.activeDays == 8)
        #expect(stats.bestStreak == 5)
        #expect(stats.topPractice == "breathing")
    }

    @Test func habitRatesAreSortedAndAcquiredAboveThreshold() {
        let p = plan()
        let anchor = p.day(1)!.items.first { $0.kind == .habit }!.refID
        var done: [Int: Set<String>] = [:]
        for day in p.days {
            if let item = day.items.first(where: { $0.kind == .habit && $0.refID == anchor }) {
                done[day.dayNumber, default: []].insert(item.statusKey)
            }
        }
        let stats = PlanCycleReview.stats(plan: p, done: done, anxietyResults: [])
        #expect(stats.habits.first?.habitID == anchor)
        #expect(stats.habits.first?.rate == 1)
        #expect(PlanCycleReview.acquiredHabits(stats) == [anchor])
    }

    @Test func rarelyScheduledHabitIsNotAcquired() {
        let stats = PlanCycleStats(cycle: 1, goal: .stress, activeDays: 20, sessionsCompleted: 0, minutesPracticed: 0, bestStreak: 0,
                                   habits: [PlanHabitRate(habitID: "sport", scheduled: 4, done: 4),
                                            PlanHabitRate(habitID: "water", scheduled: 28, done: 23)],
                                   topPractice: nil, anxiety: PlanAnxietyTrend())
        #expect(PlanCycleReview.acquiredHabits(stats) == ["water"])
    }

    // MARK: Anxiety trend

    @Test func anxietyTrendPicksTheThreeCheckpoints() {
        let start = date(1, 0)
        let results = [
            check(14, on: date(1, 9)),   // day 1
            check(10, on: date(14, 9)),  // day 14
            check(9, on: date(15, 9)),   // later in the day-14 window: wins
            check(8, on: date(29, 9))    // day 29 (late day-28 check)
        ]
        let trend = PlanCycleReview.anxietyTrend(results: results, planStart: start, calendar: calendar)
        #expect(trend.start == 14)
        #expect(trend.middle == 9)
        #expect(trend.end == 8)
        #expect(trend.changePercent == -43)
    }

    @Test func anxietyChangeNeedsBothEnds() {
        #expect(PlanAnxietyTrend(start: 12, middle: nil, end: nil).changePercent == nil)
        #expect(PlanAnxietyTrend(start: 0, middle: nil, end: 3).changePercent == nil)
        #expect(PlanAnxietyTrend(start: 10, middle: nil, end: 12).changePercent == 20)
    }

    // MARK: Completion mapping

    @Test func doneKeysMapAbsoluteProgramDaysToPlanDays() {
        // Plan started 30 days ago (plan day 31 today); program day 40 today → plan day 1 = program day 10.
        let now = Date()
        let start = Calendar.current.date(byAdding: .day, value: -30, to: now)!
        let p = plan(start: start)
        let statuses: [String: [String: String]] = [
            "day_10": ["plan_breathing": "done", "plan_meditation": "skipped"],
            "day_37": ["plan_habit_water": "done"],
            "day_9": ["plan_breathing": "done"] // before this plan
        ]
        let done = PlanCompletionLoader.doneKeys(for: p, statuses: statuses, absoluteToday: 40, now: now)
        #expect(done[1] == ["plan_breathing"])
        #expect(done[28] == ["plan_habit_water"])
        #expect(done.count == 2)
    }

    // MARK: Cycle themes

    @Test func cycleThemes() {
        #expect(PlanCycleTheme.forCycle(1) == .soothe)
        #expect(PlanCycleTheme.forCycle(2) == .anchor)
        #expect(PlanCycleTheme.forCycle(3) == .autonomy)
        #expect(PlanCycleTheme.forCycle(4) == .maintenance)
        #expect(PlanCycleTheme.forCycle(12) == .maintenance)
    }

    // MARK: Plan reminders

    private func context(today: Int, hour: Int = 7, doneToday: Bool = false, reminder: (Int, Int) = (9, 0)) -> PlanReminderContext {
        // Plan starts on October 1st: plan day d = October d.
        PlanReminderContext(now: date(today, hour), planStart: date(1, 0), cycle: 1,
                            sessionTitles: [today: "Session \(today)", today + 1: "Session \(today + 1)"],
                            nextCycleFirstSession: "First", reminderTime: reminder, doneToday: doneToday)
    }

    @Test func dailyRemindersNameTheSession() {
        let reminders = PlanReminderPlanner.reminders(context(today: 10), calendar: calendar)
        let daily = reminders.filter { $0.kind == .daily }
        #expect(daily.map(\.id) == ["daily_0", "daily_1"])
        #expect(daily[0].date == date(10, 9))
        #expect(daily[0].args == ["Session 10"])
        #expect(daily[1].date == date(11, 9))
        #expect(reminders.filter { $0.kind == .transition }.map(\.id) == ["j26", "j28", "j29"])
    }

    @Test func noReminderTodayOnceSomethingIsDone() {
        let reminders = PlanReminderPlanner.reminders(context(today: 10, doneToday: true), calendar: calendar)
        #expect(!reminders.contains { $0.id == "daily_0" })
        #expect(reminders.contains { $0.id == "daily_1" })
    }

    @Test func transitionsReplaceTheDailyReminder() {
        let reminders = PlanReminderPlanner.reminders(context(today: 28, hour: 8), calendar: calendar)
        #expect(reminders.map(\.id) == ["daily_0", "j28", "j29"])
        let j28 = reminders.first { $0.id == "j28" }!
        #expect(j28.date == date(28, 19, 30))
        #expect(j28.link == PlanReminderPlanner.reviewLink)
        let j29 = reminders.first { $0.id == "j29" }!
        #expect(j29.date == date(29, 9))
        #expect(j29.args == ["2", "First"])
    }

    @Test func dayTwentyNineIsAMorningMessage() {
        let reminders = PlanReminderPlanner.reminders(context(today: 27, reminder: (18, 30)), calendar: calendar)
        #expect(reminders.first { $0.id == "j29" }?.date == date(29, 9, 30))
        #expect(reminders.first { $0.id == "daily_0" }?.date == date(27, 18, 30))
    }

    @Test func reminderTimeStaysOutOfQuietHours() {
        let early = PlanReminderPlanner.clamped((6, 0)), late = PlanReminderPlanner.clamped((23, 15)), day = PlanReminderPlanner.clamped((13, 5))
        #expect(early.hour == 8 && early.minute == 30)
        #expect(late.hour == 21 && late.minute == 0)
        #expect(day.hour == 13 && day.minute == 5)
    }
}
