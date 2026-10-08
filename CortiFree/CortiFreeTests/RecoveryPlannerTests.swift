//
//  RecoveryPlannerTests.swift
//  CortiFreeTests
//

import Foundation
import Testing
@testable import CortiFree

struct RecoveryPlannerTests {

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Paris")!
        return calendar
    }

    private func date(_ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour, minute: minute))!
    }

    private let allProducts: Set<String> = [RecoveryPlacement.trialProduct, RecoveryPlacement.discountProduct]

    // MARK: Quiet hours

    @Test func eveningDelaysMoveToNextMorning() {
        #expect(RecoveryPlanner.shiftOutOfQuietHours(date(8, 22), calendar: calendar) == date(9, 8, 30))
        #expect(RecoveryPlanner.shiftOutOfQuietHours(date(8, 21, 30), calendar: calendar) == date(9, 8, 30))
    }

    @Test func nightDelaysMoveToSameMorning() {
        #expect(RecoveryPlanner.shiftOutOfQuietHours(date(9, 2), calendar: calendar) == date(9, 8, 30))
        #expect(RecoveryPlanner.shiftOutOfQuietHours(date(9, 7, 59), calendar: calendar) == date(9, 8, 30))
    }

    @Test func daytimeIsUnchanged() {
        #expect(RecoveryPlanner.shiftOutOfQuietHours(date(9, 8), calendar: calendar) == date(9, 8))
        #expect(RecoveryPlanner.shiftOutOfQuietHours(date(9, 21, 29), calendar: calendar) == date(9, 21, 29))
    }

    // MARK: Sequences

    @Test func paywallSequenceFromAfternoonAnchor() {
        let anchor = date(8, 14)
        let messages = RecoveryPlanner.sequence(for: .paywall, goal: nil)
        let scheduled = RecoveryPlanner.schedule(messages, anchor: anchor, now: anchor, includePromotional: true,
                                                 availableProducts: allProducts, calendar: calendar)
        #expect(scheduled.map(\.message.id) == ["B-1", "B-2", "B-3", "B-4", "B-5", "B-6", "B-7", "B-8", "B-9", "B-10", "B-11"])
        #expect(scheduled[0].date == date(8, 15))
        #expect(scheduled[1].date == date(8, 18))
        #expect(scheduled[2].date == date(9, 10))
        #expect(scheduled[5].date == date(11, 8, 30))
        #expect(scheduled[10].date == date(22, 10))
    }

    @Test func offersNeedConsent() {
        let anchor = date(8, 14)
        let scheduled = RecoveryPlanner.schedule(RecoveryPlanner.sequence(for: .paywall, goal: nil), anchor: anchor, now: anchor,
                                                 includePromotional: false, availableProducts: allProducts, calendar: calendar)
        #expect(scheduled.allSatisfy { !$0.message.isPromotional })
        #expect(scheduled.count == 6)
    }

    @Test func offersNeedTheirProduct() {
        let anchor = date(8, 14)
        let messages = RecoveryPlanner.sequence(for: .paywall, goal: nil)
        let none = RecoveryPlanner.schedule(messages, anchor: anchor, now: anchor, includePromotional: true, calendar: calendar)
        #expect(!none.contains { $0.message.isPromotional })

        let trialOnly = RecoveryPlanner.schedule(messages, anchor: anchor, now: anchor, includePromotional: true,
                                                 availableProducts: [RecoveryPlacement.trialProduct], calendar: calendar)
        #expect(trialOnly.filter(\.message.isPromotional).map(\.message.id) == ["B-3", "B-5", "B-6"])
    }

    @Test func pastMessagesAreSkipped() {
        let anchor = date(8, 14)
        let now = date(10, 20)
        let scheduled = RecoveryPlanner.schedule(RecoveryPlanner.sequence(for: .planReady, goal: nil), anchor: anchor, now: now,
                                                 includePromotional: true, calendar: calendar)
        #expect(scheduled.first?.message.id == "A2-6")
        #expect(scheduled.allSatisfy { $0.date > now })
    }

    @Test func shiftedMessagesKeepTheirSpacing() {
        // 21:00 anchor: +1 h and +4 h both land at 8:30 the next morning; only the first is kept.
        let anchor = date(8, 21)
        let scheduled = RecoveryPlanner.schedule(RecoveryPlanner.sequence(for: .paywall, goal: nil), anchor: anchor, now: anchor,
                                                 includePromotional: true, availableProducts: allProducts, calendar: calendar)
        #expect(scheduled[0].message.id == "B-1")
        #expect(scheduled[0].date == date(9, 8, 30))
        #expect(scheduled[1].message.id == "B-3")
        for (previous, next) in zip(scheduled, scheduled.dropFirst()) {
            #expect(next.date.timeIntervalSince(previous.date) >= RecoveryPlanner.minimumGap)
        }
    }

    @Test func goalPersonalizesTheEveningMessage() {
        let a2 = RecoveryPlanner.sequence(for: .planReady, goal: "sleep")
        #expect(a2.first { $0.id == "A2-4" }?.key == "recovery.a2.goal.sleep")
        let b = RecoveryPlanner.sequence(for: .paywall, goal: "unknown")
        #expect(b.first { $0.id == "B-4" }?.key == "recovery.b.4")
        #expect(RecoveryPlanner.sequence(for: .earlyOnboarding, goal: "sleep").allSatisfy { !$0.key.contains("goal") })
    }

    @Test func goalComesFromFirstKnownReason() {
        #expect(RecoveryPlanner.goal(fromReasonCodes: ["habits", "sleep"]) == "sleep")
        #expect(RecoveryPlanner.goal(fromReasonCodes: ["anxiety"]) == "stress")
        #expect(RecoveryPlanner.goal(fromReasonCodes: ["mental"]) == "emotional")
        #expect(RecoveryPlanner.goal(fromReasonCodes: ["habits"]) == "stress")
        #expect(RecoveryPlanner.goal(fromReasonCodes: []) == nil)
    }

    // MARK: Drop-off nudge

    @Test func dropOffNudgeRotatesTexts() {
        let keys = (1...4).map { RecoveryPlanner.dropOffMessage(for: .paywall, dropOffCount: $0).key }
        #expect(keys == ["recovery.drop.b.1", "recovery.drop.b.2", "recovery.drop.b.3", "recovery.drop.b.1"])
        #expect(RecoveryPlanner.dropOffMessage(for: .earlyOnboarding, dropOffCount: 1).placement == nil)
    }

    @Test func identifiersAreUnique() {
        let ids = RecoveryPlanner.allIdentifiers
        #expect(Set(ids).count == ids.count)
        #expect(ids.contains("recovery_drop-B"))
        #expect(ids.contains("recovery_B-11"))
    }

    // MARK: Offer windows

    @Test func trialOfferIsOpenFor48HoursFromDayOne() {
        let seen = date(8, 14)
        let open = { (now: Date) in
            RecoveryPlanner.activePlacement(for: RecoveryPlacement.offer, paywallSeenAt: seen, now: now, calendar: calendar)
        }
        #expect(open(date(9, 9, 59)) == SuperwallPlacement.onboarding)
        #expect(open(date(9, 10)) == RecoveryPlacement.offer)
        #expect(open(date(11, 9, 59)) == RecoveryPlacement.offer)
        #expect(open(date(11, 10)) == SuperwallPlacement.onboarding)
    }

    @Test func lastChanceWindowAndPassThrough() {
        let seen = date(8, 14)
        #expect(RecoveryPlanner.activePlacement(for: RecoveryPlacement.lastChance, paywallSeenAt: seen, now: date(15, 12), calendar: calendar) == RecoveryPlacement.lastChance)
        #expect(RecoveryPlanner.activePlacement(for: RecoveryPlacement.lastChance, paywallSeenAt: nil, now: date(15, 12), calendar: calendar) == SuperwallPlacement.onboarding)
        #expect(RecoveryPlanner.activePlacement(for: "campaign_trigger", paywallSeenAt: seen, now: date(30, 12), calendar: calendar) == "campaign_trigger")
    }

    // MARK: Copy

    @Test func everyMessageHasCopyInEveryLanguage() throws {
        let goals = RecoveryPlanner.goals + [nil]
        let segments: [RecoverySegment] = [.earlyOnboarding, .planReady, .paywall]
        var keys = Set(goals.flatMap { goal in segments.flatMap { RecoveryPlanner.sequence(for: $0, goal: goal).map(\.key) } })
        for segment in segments { for count in 1...3 { keys.insert(RecoveryPlanner.dropOffMessage(for: segment, dropOffCount: count).key) } }
        keys.insert("recovery.trial_ending")

        let bundle = Bundle.main // the app hosts the unit tests
        for language in ["en", "fr", "de", "es", "ja", "ko"] {
            let path = try #require(bundle.path(forResource: "Localizable", ofType: "strings", inDirectory: nil, forLocalization: language))
            let table = try #require(NSDictionary(contentsOfFile: path) as? [String: String])
            for key in keys {
                #expect(table["\(key).title"] != nil, "\(language) missing \(key).title")
                #expect(table["\(key).body"] != nil, "\(language) missing \(key).body")
            }
        }
    }
}
