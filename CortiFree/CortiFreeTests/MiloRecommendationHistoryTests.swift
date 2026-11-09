//
//  MiloRecommendationHistoryTests.swift
//  CortiFreeTests
//
//  Milo walks down a list of candidates instead of repeating the first three.
//

import Foundation
import Testing
@testable import CortiFree

struct MiloRecommendationHistoryTests {

    private let items = (0..<10).map { "item-\($0)" }

    @Test func picksTheBestFitThatWasNotProposedRecently() {
        #expect(MiloRecommendationHistory.freshest(items, recent: [], id: { $0 }) == "item-0")
        #expect(MiloRecommendationHistory.freshest(items, recent: ["item-0", "item-1"], id: { $0 }) == "item-2")
    }

    @Test func fallsBackToTheOneProposedLongestAgoWhenEverythingIsRecent() {
        let list = ["a", "b", "c"]
        #expect(MiloRecommendationHistory.freshest(list, recent: ["b", "c", "a"], id: { $0 }) == "b")
        #expect(MiloRecommendationHistory.freshest([String](), recent: [], id: { $0 }) == nil)
    }

    @Test func historyKeepsTheLatestAndMovesARepeatToTheEnd() {
        var recent: [String] = []
        for i in 0..<12 { recent = MiloRecommendationHistory.remembering("x\(i)", in: recent) }
        #expect(recent.count == MiloRecommendationHistory.limit)
        #expect(recent.last == "x11")
        recent = MiloRecommendationHistory.remembering("x5", in: recent)
        #expect(recent.last == "x5")
        #expect(recent.filter { $0 == "x5" }.count == 1)
        #expect(MiloRecommendationHistory.decode(MiloRecommendationHistory.encode(recent)) == recent)
    }

    @Test func tenProposalsUseEightDifferentItemsBeforeAnythingRepeats() {
        var recent: [String] = []
        var proposed: [String] = []
        for _ in 0..<MiloRecommendationHistory.limit {
            let next = MiloRecommendationHistory.freshest(items, recent: recent, id: { $0 })!
            proposed.append(next)
            recent = MiloRecommendationHistory.remembering(next, in: recent)
        }
        #expect(Set(proposed).count == MiloRecommendationHistory.limit)
    }

    @Test func aShortListComesAroundInOrderInsteadOfRepeatingOneItem() {
        let sleep = ["478", "wave", "slow66"]
        var recent: [String] = []
        var proposed: [String] = []
        for _ in 0..<6 {
            let next = MiloRecommendationHistory.freshest(sleep, recent: recent, id: { $0 })!
            proposed.append(next)
            recent = MiloRecommendationHistory.remembering(next, in: recent)
        }
        #expect(proposed == ["478", "wave", "slow66", "478", "wave", "slow66"])
    }
}
