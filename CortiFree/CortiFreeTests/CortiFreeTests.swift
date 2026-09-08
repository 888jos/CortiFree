//
//  CortiFreeTests.swift
//  CortiFreeTests
//
//  Created by Josselin Biot on 25/09/2025.
//

import Foundation
import Testing
@testable import CortiFree

struct CortiFreeTests {

    @Test func example() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    }

    @Test func progressAggregationMapsProgramDaysToCalendarDates() {
        let calendar = utcCalendar
        let start = date(2026, 8, 1, calendar: calendar)
        let now = date(2026, 8, 7, calendar: calendar)

        let days = ProgressAggregation.days(
            programStartDate: start,
            taskCompletionsByProgramDay: [1: 2, 3: 1, 7: 3],
            exerciseDates: [date(2026, 8, 2, calendar: calendar)],
            moodScoresByDate: [date(2026, 8, 7, calendar: calendar): 5],
            range: 7,
            now: now,
            calendar: calendar
        )

        #expect(days.map(\.completionCount) == [2, 1, 1, 0, 0, 0, 3])
        #expect(days.last?.moodScore == 5)
    }

    @Test func progressCurrentStreakAllowsTodayToRemainOpen() {
        let calendar = utcCalendar
        let start = date(2026, 8, 1, calendar: calendar)
        let now = date(2026, 8, 7, calendar: calendar)
        let days = ProgressAggregation.days(
            programStartDate: start,
            taskCompletionsByProgramDay: [4: 1, 5: 1, 6: 1],
            exerciseDates: [],
            moodScoresByDate: [:],
            range: 7,
            now: now,
            calendar: calendar
        )

        let streaks = ProgressAggregation.streaks(from: days)
        #expect(streaks.current == 3)
        #expect(streaks.best == 3)
    }

    @Test func progressCheckInActivatesAnOtherwiseEmptyDay() {
        let calendar = utcCalendar
        let start = date(2026, 8, 1, calendar: calendar)
        let now = date(2026, 8, 3, calendar: calendar)
        let days = ProgressAggregation.days(
            programStartDate: start,
            taskCompletionsByProgramDay: [:],
            exerciseDates: [],
            moodScoresByDate: [date(2026, 8, 3, calendar: calendar): 4],
            checkInDates: [date(2026, 8, 3, calendar: calendar)],
            range: 3,
            now: now,
            calendar: calendar
        )

        #expect(days.last?.isActive == true)
        #expect(days.last?.completionCount == 1)
        #expect(ProgressAggregation.streaks(from: days).current == 1)
    }

    @Test func localHabitProgressIsIdempotent() {
        let userID = "progress-test-\(UUID().uuidString)"
        defer { LocalProgressStore.clear(for: userID) }

        LocalProgressStore.recordCompletion(
            taskID: "breathing-task",
            habitID: "breathing",
            programDay: 1,
            durationSeconds: 300,
            userID: userID
        )
        LocalProgressStore.recordCompletion(
            taskID: "breathing-task",
            habitID: "breathing",
            programDay: 1,
            durationSeconds: 420,
            userID: userID
        )

        #expect(LocalProgressStore.load(for: userID).count == 1)
        #expect(LocalProgressStore.completedCount(for: "breathing", userID: userID) == 1)
        #expect(LocalProgressStore.load(for: userID).first?.durationSeconds == 420)
        #expect(TaskStatusService.habitTotals["breathing"] == 47)
    }

    @Test func localActivitySessionsKeepSecondsWithoutAuthentication() {
        let userID = "activity-test-\(UUID().uuidString)"
        defer { LocalActivitySessionStore.clear(for: userID) }

        LocalActivitySessionStore.record(
            exerciseID: "ocean",
            category: .sounds,
            durationSeconds: 60,
            source: "test",
            userID: userID
        )
        LocalActivitySessionStore.record(
            exerciseID: "box-breathing",
            category: .breathing,
            durationSeconds: 75,
            source: "test",
            userID: userID
        )

        let sessions = LocalActivitySessionStore.load(for: userID)
        #expect(sessions.count == 2)
        #expect(sessions.reduce(0) { $0 + $1.durationSeconds } == 135)
        #expect(sessions.contains { $0.category == .sounds && $0.durationSeconds == 60 })
        #expect(sessions.contains { $0.category == .breathing && $0.durationSeconds == 75 })
    }

    @Test func userDomainScoresReadIntegerFirestoreValues() {
        let scores = UserDomainScores.from([
            "serenity": 32,
            "sleep": 44,
            "energy": 51,
            "focus": 39,
            "balance": 34
        ])

        #expect(scores.serenity == 32)
        #expect(scores.sleep == 44)
        #expect(scores.energy == 51)
        #expect(scores.focus == 39)
        #expect(scores.balance == 34)
        #expect(scores.global == 40)
    }

    @Test func userDomainScoresReadLegacyHabitsDomain() {
        let scores = UserDomainScores.from([
            "serenity": 20,
            "sleep": 30,
            "energy": 40,
            "focus": 50,
            "habits": 60
        ])

        #expect(scores.balance == 60)
        #expect(scores.global == 40)
    }

    @Test func progressStreakResetsAfterMoreThanOneInactiveDay() {
        let calendar = utcCalendar
        let start = date(2026, 8, 1, calendar: calendar)
        let now = date(2026, 8, 7, calendar: calendar)
        let days = ProgressAggregation.days(
            programStartDate: start,
            taskCompletionsByProgramDay: [1: 1, 2: 1, 5: 1],
            exerciseDates: [],
            moodScoresByDate: [:],
            range: 7,
            now: now,
            calendar: calendar
        )

        let streaks = ProgressAggregation.streaks(from: days)
        #expect(streaks.current == 0)
        #expect(streaks.best == 2)
    }

    @Test func progressPeriodCountsOnlyVisibleActiveDays() {
        let calendar = utcCalendar
        let now = date(2026, 8, 28, calendar: calendar)
        let days = ProgressAggregation.days(
            programStartDate: date(2026, 8, 1, calendar: calendar),
            taskCompletionsByProgramDay: [1: 1, 22: 1, 24: 1, 28: 1],
            exerciseDates: [],
            moodScoresByDate: [:],
            range: 28,
            now: now,
            calendar: calendar
        )
        let dashboard = ProgressDashboardData(
            generatedAt: now,
            programStartDate: date(2026, 8, 1, calendar: calendar),
            days: days,
            currentStreak: 1,
            bestStreak: 1,
            activities: [],
            domainTrends: [],
            topActivity: nil,
            baselineScore: nil,
            currentScore: nil,
            scoreHistory: []
        )

        #expect(dashboard.activeDayCount(in: .week, relativeTo: now, calendar: calendar) == 3)
        #expect(dashboard.activeDayCount(in: .month, relativeTo: now, calendar: calendar) == 4)
    }

    private var utcCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, calendar: Calendar) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }

}
