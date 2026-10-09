//
//  PlanBilanCenter.swift
//  CortiFree
//
//  Decides when « Ton bilan des 28 jours » opens (once per cycle): on day 28 for the cycle
//  in progress, or during the first week of the next cycle when the user missed day 28.
//  Presented full screen by ContentView.
//

import Foundation

@MainActor
final class PlanBilanCenter: ObservableObject {
    static let shared = PlanBilanCenter()

    struct Request: Identifiable, Equatable {
        var id: String { PlanBilanCenter.seenKey(for: plan) }
        /// The cycle being reviewed.
        let plan: PersonalPlan
        /// True on day 28: the next cycle starts tomorrow. False when it already started.
        let isCurrentCycle: Bool
        let source: String
    }

    @Published var request: Request?
    /// Requests whose screen actually appeared (a cover can't open while another sheet is up).
    private var appearedIDs = Set<String>()
    private let defaults = UserDefaults.standard

    private init() {}

    /// Opens the review when it is due and wasn't seen yet. Safe to call often.
    func checkIfDue(source: String) {
        let store = PersonalPlanStore.shared
        guard let plan = store.plan else { return }
        let due: Request?
        if plan.dayIndex() == PersonalPlan.length, !isSeen(plan) {
            due = Request(plan: plan, isCurrentCycle: true, source: source)
        } else if let previous = store.previousPlan, plan.cycle == previous.cycle + 1,
                  plan.dayIndex() <= 7, !isSeen(previous) {
            due = Request(plan: previous, isCurrentCycle: false, source: source)
        } else {
            due = nil
        }
        guard let due else { return }
        if let current = request {
            // Still pending but never shown (another sheet was up): publish it again.
            guard current.id == due.id, !appearedIDs.contains(current.id) else { return }
            request = nil
            Task { @MainActor in self.request = due }
            return
        }
        request = due
    }

    /// App open / notification: let the plan load (and the next cycle start on day 29) and the
    /// launch sheets settle before opening the review.
    func checkAfterLaunch(source: String) {
        Task {
            await PersonalPlanStore.shared.ensurePlan()
            try? await Task.sleep(for: .seconds(1.2))
            checkIfDue(source: source)
        }
    }

    func didAppear(_ request: Request) {
        appearedIDs.insert(request.id)
        defaults.set(true, forKey: Self.storageKey(request.plan))
    }

    func isSeen(_ plan: PersonalPlan) -> Bool { defaults.bool(forKey: Self.storageKey(plan)) }

    nonisolated private static func seenKey(for plan: PersonalPlan) -> String {
        "\(plan.cycle).\(Int(plan.startDate.timeIntervalSince1970))"
    }

    private static func storageKey(_ plan: PersonalPlan) -> String {
        let user = Auth.auth().currentUser?.uid ?? UserPersistence.localUserID
        return "plan.bilan.seen.v1.\(user).\(seenKey(for: plan))"
    }

    #if DEBUG
    /// Opens the review of the current plan now (debug menu / simulator checks).
    func debugPresent() {
        guard let plan = PersonalPlanStore.shared.plan else { return }
        request = Request(plan: PersonalPlanStore.shared.previousPlan ?? plan, isCurrentCycle: false, source: "debug")
    }
    #endif
}
