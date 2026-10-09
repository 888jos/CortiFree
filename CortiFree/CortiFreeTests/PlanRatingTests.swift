//
//  PlanRatingTests.swift
//  CortiFreeTests
//
//  End-of-session ratings (0–5) in the plan generator and the anti-stress recommendations:
//  disliked content is avoided, liked content comes back more, habits are untouched.
//

import Foundation
import Testing
@testable import CortiFree

struct PlanRatingTests {

    private let profile = PlanProfile(reasonCodes: ["anxiety"], durationCode: "2_6_months", availableMinutes: 22)
    private let start = Date(timeIntervalSince1970: 1_790_000_000)
    private static let unrated: (RatedContentType, String) -> Double? = { _, _ in nil }

    private func generate(cycle: Int = 1, ratings: [String: Double]) -> PersonalPlan {
        PersonalPlanGenerator.generate(profile: profile, startDate: start, cycle: cycle,
                                       ratings: { type, id in ratings["\(type.rawValue):\(id)"] })
    }

    private func refs(_ plan: PersonalPlan, _ kinds: Set<PlanItemKind>) -> [String] {
        plan.days.flatMap { $0.items.filter { kinds.contains($0.kind) }.map(\.refID) }
    }

    private func mostUsed(_ ids: [String]) -> String {
        Dictionary(grouping: ids, by: { $0 }).max { a, b in
            a.value.count != b.value.count ? a.value.count < b.value.count : a.key > b.key
        }!.key
    }

    @Test func dislikedMeditationLeavesThePlan() {
        for cycle in 1...4 {
            let base = generate(cycle: cycle, ratings: [:])
            let favourite = mostUsed(refs(base, [.audio, .evening]))
            let rated = generate(cycle: cycle, ratings: ["meditation:\(favourite)": 1])
            #expect(!refs(rated, [.audio, .evening]).contains(favourite), "cycle \(cycle): \(favourite)")
        }
    }

    @Test func dislikedBreathingLeavesThePlan() {
        for cycle in 1...4 {
            let base = generate(cycle: cycle, ratings: [:])
            let favourite = mostUsed(refs(base, [.breathing]))
            let rated = generate(cycle: cycle, ratings: ["breathing:\(favourite)": 0])
            #expect(!refs(rated, [.breathing]).contains(favourite), "cycle \(cycle): \(favourite)")
        }
    }

    @Test func likedBreathingComesBackMore() {
        let base = generate(ratings: [:])
        let counts = Dictionary(grouping: refs(base, [.breathing]), by: { $0 }).mapValues(\.count)
        guard let rare = counts.min(by: { a, b in a.value != b.value ? a.value < b.value : a.key < b.key })?.key else {
            Issue.record("no breathing in the plan"); return
        }
        let rated = generate(ratings: ["breathing:\(rare)": 5])
        #expect(refs(rated, [.breathing]).filter { $0 == rare }.count > counts[rare]!)
    }

    @Test func ratingsKeepTheHabitBalanceAndShape() {
        let base = generate(ratings: [:])
        let ratings = Dictionary(uniqueKeysWithValues:
            Set(refs(base, [.audio, .evening])).map { ("meditation:\($0)", 1.0) }
            + Set(refs(base, [.breathing])).map { ("breathing:\($0)", 5.0) })
        let rated = generate(ratings: ratings)
        #expect(rated.days.count == base.days.count)
        for (a, b) in zip(base.days, rated.days) {
            #expect(a.items.map(\.kind) == b.items.map(\.kind))
            #expect(a.items.filter { $0.kind == .habit } == b.items.filter { $0.kind == .habit })
        }
        // Even with every planned meditation disliked, each day still has its guided session.
        #expect(rated.days.allSatisfy { $0.items.contains { $0.kind == .audio } })
    }

    @Test func alternativesPutDislikedBreathingLast() {
        let plan = generate(ratings: [:])
        guard let day = plan.day(10), let item = day.items.first(where: { $0.kind == .breathing }) else {
            Issue.record("no breathing on day 10"); return
        }
        let base = PersonalPlanGenerator.alternatives(for: item, in: plan, dayNumber: 10, limit: 20, ratings: Self.unrated)
        guard let first = base.first else { Issue.record("no alternatives"); return }
        let rated = PersonalPlanGenerator.alternatives(for: item, in: plan, dayNumber: 10, limit: 20,
                                                       ratings: { type, id in type == .breathing && id == first.refID ? 1 : nil })
        #expect(rated.last?.refID == first.refID)
    }

    @Test func dislikedExerciseDropsToTheBottom() {
        let base = AntiStressRecommendationEngine.recommendations(for: .anxiety, ratings: Self.unrated)
        let top = base[0].exerciseType
        let rated = AntiStressRecommendationEngine.recommendations(for: .anxiety, ratings: { type, id in
            type == .exercise && id == top.rawValue ? 1 : nil
        })
        #expect(rated.last?.exerciseType == top)
        #expect(rated.map(\.exerciseType).dropLast() == base.map(\.exerciseType).dropFirst())
    }

    @Test func likedExerciseMovesUp() {
        let base = AntiStressRecommendationEngine.recommendations(for: .anxiety, ratings: Self.unrated)
        let second = base[1].exerciseType
        let rated = AntiStressRecommendationEngine.recommendations(for: .anxiety, ratings: { type, id in
            type == .exercise && id == second.rawValue ? 5 : nil
        })
        #expect(rated.first?.exerciseType == second)
    }
}
