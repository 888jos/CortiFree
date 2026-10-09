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

    private func stats(goal: PlanGoal, start: Int?, end: Int?, activeDays: Int = 20) -> PlanCycleStats {
        PlanCycleStats(cycle: 1, goal: goal, activeDays: activeDays, sessionsCompleted: 20, minutesPracticed: 120, bestStreak: 7,
                       habits: [], topPractice: nil, anxiety: PlanAnxietyTrend(start: start, middle: nil, end: end))
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
