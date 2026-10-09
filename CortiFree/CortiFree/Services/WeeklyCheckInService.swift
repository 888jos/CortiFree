//
//  WeeklyCheckInService.swift
//  CortiFree
//
//  Weekly check-in: on each face-check day of the plan (days 1, 7, 14, 21, 28), the first app
//  open shows a drawer with the week's moods, the face scan, the pulse and a talk with Milo.
//  Once per week.
//

import Foundation

@MainActor
final class WeeklyCheckInService {
    static let shared = WeeklyCheckInService()
    private let defaults = UserDefaults.standard
    private init() {}

    private var promptedKey: String {
        "weekly_check_in_prompted_slot.\(UnifiedFirebaseService.shared.auth.currentUserId ?? "local")"
    }

    /// "cycle-slot" of the current plan week.
    private var weekKey: String {
        let store = FaceScanStore.shared
        return "\(store.planPosition.cycle)-\(store.currentSlot)"
    }

    /// This week's face check or pulse is still to do (needs a plan).
    var isDue: Bool {
        guard PersonalPlanStore.shared.plan != nil else { return false }
        FaceScanStore.shared.reload()
        return FaceScanStore.shared.isDue || WeeklyPulseStore.shared.isDue
    }

    func shouldPresent() -> Bool {
        guard UserPersistence.hasCompletedOnboarding,
              UnifiedFirebaseService.shared.auth.currentUser != nil,
              !DailyCheckInService.shared.isProgramFirstDay(),
              isDue else { return false }
        return defaults.string(forKey: promptedKey) != weekKey
    }

    func markPrompted() { defaults.set(weekKey, forKey: promptedKey) }
}
