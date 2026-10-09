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

    // MARK: Review stats

    @Test func statsCountSessionsMinutesAndBestStreak() {
        let p = plan()
        var done: [Int: Set<String>] = [:]
        // Days 1–5 and 10–12: breathing done; day 2 also the guided session.
        for day in [1, 2, 3, 4, 5, 10, 11, 12] { done[day] = ["plan_breathing"] }
        done[2]?.insert("plan_meditation")

        let stats = PlanCycleReview.stats(plan: p, done: done, stress: [:])
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
        let stats = PlanCycleReview.stats(plan: p, done: done, stress: [:])
        #expect(stats.habits.first?.habitID == anchor)
        #expect(stats.habits.first?.rate == 1)
        #expect(PlanCycleReview.acquiredHabits(stats) == [anchor])
    }

    @Test func rarelyScheduledHabitIsNotAcquired() {
        let stats = PlanCycleStats(cycle: 1, goal: .stress, activeDays: 20, sessionsCompleted: 0, minutesPracticed: 0, bestStreak: 0,
                                   habits: [PlanHabitRate(habitID: "sport", scheduled: 4, done: 4),
                                            PlanHabitRate(habitID: "water", scheduled: 28, done: 23)],
                                   topPractice: nil, stress: PlanStressTrend())
        #expect(PlanCycleReview.acquiredHabits(stats) == ["water"])
    }

    // MARK: Stress trend (daily check-ins)

    @Test func stressTrendAveragesEachWeek() {
        // Week 1: 4, 5, 4 → 4.33; week 2: one check-in only → nil; week 3: 3, 3; week 4: 3, 2, 3, 2 → 2.5.
        let stress: [Int: Int] = [1: 4, 3: 5, 6: 4, 10: 2, 15: 3, 21: 3, 22: 3, 24: 2, 26: 3, 28: 2]
        let trend = PlanCycleReview.stressTrend(stress)
        #expect(trend.weeks.count == 4)
        #expect(abs((trend.start ?? 0) - 13.0 / 3.0) < 0.001)
        #expect(trend.weeks[1] == nil)
        #expect(trend.weeks[2] == 3)
        #expect(trend.end == 2.5)
        #expect(trend.changePercent == -42)
    }

    @Test func stressChangeNeedsBothEnds() {
        #expect(PlanStressTrend(weeks: [4, nil, nil, nil]).changePercent == nil)
        #expect(PlanStressTrend(weeks: [nil, 3, 3, 2]).changePercent == nil)
        #expect(PlanStressTrend(weeks: [2.5, nil, nil, 3]).changePercent == 20)
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
        #expect(reminders.filter { $0.kind == .daily || $0.kind == .transition }.map(\.id) == ["daily_0", "j28", "j29"])
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

    // MARK: Smart reminders (phase 2)

    @Test func usualPracticeTimeAveragesTheFirstCompletionOfEachDay() {
        let now = date(10, 21)
        let times = [date(8, 18, 10), date(8, 21), date(9, 18, 40), date(1, 7)] // Oct 1st: too old
        let usual = PlanReminderPlanner.usualPracticeTime(times, now: now, calendar: calendar)
        #expect(usual?.hour == 18 && usual?.minute == 25)
        #expect(PlanReminderPlanner.usualPracticeTime([date(9, 18)], now: now, calendar: calendar) == nil)
    }

    @Test func streakAtRiskOnlyWhenNothingDone() {
        var ctx = context(today: 10, hour: 12)
        ctx.streak = 4
        let risky = PlanReminderPlanner.reminders(ctx, calendar: calendar).filter { $0.kind == .streak }
        #expect(risky.map(\.id) == ["streak_0"])
        #expect(risky.first?.date == date(10, 20))
        #expect(risky.first?.args == ["4"])

        var done = context(today: 10, hour: 12, doneToday: true)
        done.streak = 5
        let tomorrow = PlanReminderPlanner.reminders(done, calendar: calendar).filter { $0.kind == .streak }
        #expect(tomorrow.map(\.id) == ["streak_1"])
        #expect(tomorrow.first?.date == date(11, 20))

        #expect(PlanReminderPlanner.reminders(context(today: 10, hour: 12), calendar: calendar).allSatisfy { $0.kind != .streak })
    }

    @Test func inactiveNudgesStopAfterThree() {
        let reminders = PlanReminderPlanner.reminders(context(today: 5), calendar: calendar).filter { $0.kind == .inactive }
        #expect(reminders.map(\.id) == ["inactive_2", "inactive_4", "inactive_7"])
        #expect(reminders.map(\.date) == [date(7, 9), date(9, 9), date(12, 9)])
    }

    @Test func inactiveNudgeGivesWayToTransitions() {
        // Day 24: +2 = day 26 and +4 = day 28 already have a transition message → no nudge those days.
        let ids = PlanReminderPlanner.reminders(context(today: 24), calendar: calendar).map(\.id)
        #expect(ids.contains("j26") && ids.contains("j28"))
        #expect(!ids.contains("inactive_2") && !ids.contains("inactive_4"))
        #expect(ids.contains("inactive_7"))
    }

    @Test func weeklySummaryOnSundayEvening() {
        // October 7th 2026 is a Wednesday.
        var ctx = context(today: 7)
        ctx.weekSessions = 5
        ctx.weekMinutes = 42
        let weekly = PlanReminderPlanner.reminders(ctx, calendar: calendar).first { $0.kind == .weekly }
        #expect(weekly?.date == date(11, 19))
        #expect(weekly?.args == ["5", "42"])
        #expect(PlanReminderPlanner.reminders(context(today: 7), calendar: calendar).allSatisfy { $0.kind != .weekly })
    }

    @Test func weekSummaryCountsPracticeSinceMonday() {
        let now = date(7, 20) // Wednesday
        func completion(_ habit: String, _ at: Date, _ seconds: Int) -> LocalProgressStore.Completion {
            LocalProgressStore.Completion(taskID: "plan_\(habit)", habitID: habit, programDay: 1, completedAt: at, durationSeconds: seconds)
        }
        let list = [completion("breathing", date(5, 9), 180), completion("meditation", date(6, 9), 600),
                    completion("water", date(6, 10), 0), completion("breathing", date(4, 9), 300)] // Sunday before
        let summary = PlanReminderPlanner.weekSummary(list, now: now, calendar: calendar)
        #expect(summary.sessions == 2)
        #expect(summary.minutes == 13)
    }

    @Test func remindersNeverFireInQuietHours() {
        var ctx = context(today: 3, hour: 7, reminder: (21, 0))
        ctx.streak = 2
        ctx.weekSessions = 1
        for reminder in PlanReminderPlanner.reminders(ctx, calendar: calendar) {
            #expect(!RecoveryPlanner.isQuiet(reminder.date, calendar: calendar))
        }
    }

    // MARK: Milo weekly check-in

    @Test func miloCheckInIsWeekly() {
        let wednesday = date(7, 10), sunday = date(11, 10)
        #expect(!MiloWeeklyCheckIn.isDue(planDay: 5, now: sunday, lastHandled: nil, calendar: calendar))
        #expect(MiloWeeklyCheckIn.isDue(planDay: 7, now: wednesday, lastHandled: nil, calendar: calendar))
        #expect(!MiloWeeklyCheckIn.isDue(planDay: 8, now: wednesday, lastHandled: nil, calendar: calendar))
        #expect(MiloWeeklyCheckIn.isDue(planDay: 9, now: sunday, lastHandled: nil, calendar: calendar))
        #expect(!MiloWeeklyCheckIn.isDue(planDay: 14, now: sunday, lastHandled: date(9, 10), calendar: calendar))
        #expect(MiloWeeklyCheckIn.questionKey(week: 1) == "milo.weekly.question.1")
        #expect(MiloWeeklyCheckIn.questionKey(week: 5) == "milo.weekly.question.1")
    }
}
