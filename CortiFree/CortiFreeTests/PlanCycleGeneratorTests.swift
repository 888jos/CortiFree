//
//  PlanCycleGeneratorTests.swift
//  CortiFreeTests
//
//  Cycle themes in the plan generator: Ancrer (2), Autonomie (3), Entretien (4+), no visible
//  repetition across cycles, acquired habits, next-goal suggestion.
//

import Foundation
import Testing
@testable import CortiFree

struct PlanCycleGeneratorTests {

    private let profile = PlanProfile(reasonCodes: ["anxiety"], durationCode: "2_6_months", availableMinutes: 22)
    private let start = Date(timeIntervalSince1970: 1_790_000_000)

    private func generate(cycle: Int, goal: PlanGoal? = nil, options: PlanCycleOptions = PlanCycleOptions()) -> PersonalPlan {
        PersonalPlanGenerator.generate(profile: profile, overrideGoal: goal, startDate: start, cycle: cycle, options: options)
    }

    private func audioIDs(_ plan: PersonalPlan) -> Set<String> {
        Set(plan.days.flatMap { $0.items.filter { $0.kind == .audio || $0.kind == .evening }.map(\.refID) })
    }

    @Test func generationIsDeterministicForEveryCycle() {
        for cycle in 1...5 {
            let a = generate(cycle: cycle), b = generate(cycle: cycle)
            #expect(a.days == b.days)
        }
    }

    @Test func nextCycleAvoidsPreviousSessions() {
        let first = generate(cycle: 1)
        let avoid = PlanCycleReview.usedRefIDs(first)
        let plain = generate(cycle: 2)
        let fresh = generate(cycle: 2, options: PlanCycleOptions(avoidRefIDs: avoid))
        let repeatedPlain = audioIDs(plain).intersection(avoid).count
        let repeatedFresh = audioIDs(fresh).intersection(avoid).count
        #expect(repeatedFresh < repeatedPlain || repeatedFresh == 0)
        // Mostly new content on the main slot.
        let freshShare = Double(audioIDs(fresh).subtracting(avoid).count) / Double(max(1, audioIDs(fresh).count))
        #expect(freshShare >= 0.5)
    }

    /// « What should your 4-week plan focus on? »: the five answers are the five plans, and the answer
    /// decides the plan whatever reasons were ticked before (the reasons only shape the second plan).
    @Test func theQuizChoiceDecidesThePlan() {
        let choices: [(String, PlanGoal)] = [("sleep", .sleep), ("stress", .stress), ("energy", .energy), ("focus", .focus), ("balance", .emotional)]
        let reasonSets: [[String]] = [["anxiety"], ["sleep"], ["energy", "difficult"], ["mental", "habits"], ["sleep", "anxiety", "energy", "difficult"]]
        for (code, goal) in choices {
            for reasons in reasonSets {
                let profile = PlanProfile(reasonCodes: reasons, durationCode: "2_6_months", improvementGoal: code)
                let analysis = PersonalPlanGenerator.analyze(profile)
                #expect(analysis.primary == goal, "answer \(code) with reasons \(reasons) gave \(analysis.primary.rawValue)")
                #expect(analysis.primaryOrigin == .quiz)
                #expect(PersonalPlanGenerator.generate(profile: profile, startDate: start).goal == goal)
            }
        }
        // The quiz answers (index 10) decide too, like the improvement goal does without raw answers.
        var answers = [Int](repeating: 1, count: 12)
        answers[10] = 3
        let withAnswers = PlanProfile(reasonCodes: ["anxiety"], quizAnswers: answers)
        #expect(PersonalPlanGenerator.analyze(withAnswers).primary == .focus)
        // Nothing picked: the reasons decide as before.
        #expect(PersonalPlanGenerator.analyze(PlanProfile(reasonCodes: ["sleep"])).primary == .sleep)
        // The user's own AI and an explicit change of plan still win.
        let ai = PlanProfile(reasonCodes: ["anxiety"], improvementGoal: "sleep", aiGoal: PlanGoal.energy.rawValue)
        #expect(PersonalPlanGenerator.analyze(ai).primary == .energy)
        #expect(PersonalPlanGenerator.analyze(PlanProfile(improvementGoal: "sleep"), overrideGoal: .focus).primary == .focus)
    }

    /// Changing the goal in the onboarding must change the exercises: week 1 differs for each of the 5 goals.
    @Test func everyGoalHasItsOwnFirstWeek() {
        func firstWeekSessions(_ goal: PlanGoal) -> Set<String> {
            Set(generate(cycle: 1, goal: goal).days.prefix(7).flatMap { $0.items.filter { $0.kind == .audio || $0.kind == .evening }.map(\.refID) })
        }
        func firstWeekBreathing(_ goal: PlanGoal) -> Set<String> {
            Set(generate(cycle: 1, goal: goal).days.prefix(7).flatMap { $0.items.filter { $0.kind == .breathing }.map(\.refID) })
        }
        let goals = PlanGoal.allCases
        for (index, a) in goals.enumerated() {
            for b in goals[(index + 1)...] {
                let sessions = firstWeekSessions(a).symmetricDifference(firstWeekSessions(b)).count
                let breathing = firstWeekBreathing(a).symmetricDifference(firstWeekBreathing(b)).count
                #expect(sessions + breathing >= 3, "\(a.rawValue) and \(b.rawValue) have nearly the same first week")
                #expect(sessions >= 1, "\(a.rawValue) and \(b.rawValue) have the same guided sessions in week 1")
            }
        }
        // The goal's own sessions show up: focus gets focus sessions, energy gets morning ones.
        func categories(_ goal: PlanGoal) -> Set<AudioSessionCategory> {
            Set(firstWeekSessions(goal).compactMap { GuidedSessionCatalog.session(id: $0)?.category })
        }
        #expect(categories(.focus).contains(.focus))
        #expect(categories(.energy).contains(.morning))
        #expect(categories(.emotional).contains(.selfCompassion))
    }

    @Test func anchorCycleHasLongerSessionsThanTheFirst() {
        func avgAudio(_ p: PersonalPlan) -> Double {
            let minutes = p.days.compactMap { $0.items.first { $0.kind == .audio }?.minutes }
            return Double(minutes.reduce(0, +)) / Double(max(1, minutes.count))
        }
        #expect(avgAudio(generate(cycle: 2)) >= avgAudio(generate(cycle: 1)))
    }

    @Test func autonomyCycleOffersChoicesAndFewerHabits() {
        let plan = generate(cycle: 3)
        #expect(plan.days.contains { $0.items.contains { $0.choice == true } })
        #expect(plan.days.allSatisfy { $0.items.filter { $0.kind == .habit }.count <= 2 })
        let first = generate(cycle: 1)
        let habits3 = plan.days.reduce(0) { $0 + $1.items.filter { $0.kind == .habit }.count }
        let habits1 = first.days.reduce(0) { $0 + $1.items.filter { $0.kind == .habit }.count }
        #expect(habits3 < habits1)
    }

    @Test func maintenanceCycleIsLightAndRotatesThemes() {
        let plan = generate(cycle: 4)
        for day in plan.days {
            let practice = day.items.filter { $0.kind == .breathing || $0.kind == .audio }.reduce(0) { $0 + $1.minutes }
            #expect(practice <= 12, "day \(day.dayNumber): \(practice) min")
            #expect(day.items.filter { $0.kind == .habit }.count <= 2)
        }
        #expect(PlanMaintenanceTheme.forWeek(1, cycle: 4) == .sleep)
        #expect(PlanMaintenanceTheme.forWeek(4, cycle: 4) == .energy)
        #expect(PlanMaintenanceTheme.forWeek(1, cycle: 5) == .sleep)
        #expect(PlanMaintenanceTheme.forWeek(2, cycle: 5) == .focus)
    }

    @Test func maintenanceNeverEnds() {
        let plan = generate(cycle: 9)
        #expect(plan.days.count == PersonalPlan.length)
        #expect(plan.cycleTheme == .maintenance)
    }

    @Test func acquiredHabitsLeaveThePlan() {
        let first = generate(cycle: 1)
        let anchor = first.days[0].items.first { $0.kind == .habit }!.refID
        let next = generate(cycle: 2, options: PlanCycleOptions(retiredHabits: [anchor]))
        #expect(!next.days.contains { $0.items.contains { $0.kind == .habit && $0.refID == anchor } })
        #expect(next.days.allSatisfy { $0.items.contains { $0.kind == .habit } })
    }

    @Test func gentleOptionGivesAGentlerPlan() {
        let gentle = generate(cycle: 2, options: PlanCycleOptions(gentle: true))
        #expect(gentle.gentle)
    }

    @Test func priorityContentIsPickedFirst() {
        let base = generate(cycle: 2)
        guard let unused = GuidedSessionCatalog.all
            .filter({ $0.category == .stressSOS && $0.durationMinutes <= 6 && !audioIDs(base).contains($0.id) }).first else { return }
        PersonalPlanGenerator.priorityRefIDs = [unused.id]
        defer { PersonalPlanGenerator.priorityRefIDs = [] }
        #expect(audioIDs(generate(cycle: 2)).contains(unused.id))
    }

    // MARK: Next goal

    private func stats(goal: PlanGoal, start: Double?, end: Double?, activeDays: Int = 20) -> PlanCycleStats {
        PlanCycleStats(cycle: 1, goal: goal, activeDays: activeDays, sessionsCompleted: 20, minutesPracticed: 120, bestStreak: 7,
                       habits: [], topPractice: nil, stress: PlanStressTrend(weeks: [start, nil, nil, end]))
    }

    @Test func bigStressDropSuggestsSleepOrFocus() {
        let s = PlanCycleReview.suggestion(for: stats(goal: .stress, start: 15, end: 8), secondaryGoal: .focus)
        #expect(s.goal == .focus && !s.gentle && s.reason == .bigProgress)
        let t = PlanCycleReview.suggestion(for: stats(goal: .stress, start: 15, end: 8), secondaryGoal: .energy)
        #expect(t.goal == .sleep)
        let u = PlanCycleReview.suggestion(for: stats(goal: .sleep, start: 15, end: 8), secondaryGoal: .stress)
        #expect(u.goal == .focus)
    }

    @Test func littleProgressKeepsTheGoalGentler() {
        let s = PlanCycleReview.suggestion(for: stats(goal: .emotional, start: 12, end: 12), secondaryGoal: .sleep)
        #expect(s.goal == .emotional && s.gentle && s.reason == .littleProgress)
        let few = PlanCycleReview.suggestion(for: stats(goal: .stress, start: nil, end: nil, activeDays: 4), secondaryGoal: .sleep)
        #expect(few.gentle)
        let ok = PlanCycleReview.suggestion(for: stats(goal: .stress, start: 12, end: 10), secondaryGoal: .sleep)
        #expect(ok.goal == .stress && !ok.gentle && ok.reason == .progress)
    }
}
