//
//  WeeklyPulse.swift
//  CortiFree
//
//  Weekly pulse check, next to the face check: one camera heart-rate reading per plan week
//  (days 1, 7, 14, 21, 28). The reading taken in the onboarding (when not skipped) is the
//  day-1 pulse of the first cycle, so it is never asked twice. Wellness only, not medical.
//

import Foundation

struct WeeklyPulseRecord: Codable, Equatable {
    let date: Date
    let cycle: Int
    /// 0…4 → days 1, 7, 14, 21, 28 (same slots as FaceScanStore).
    let slot: Int
    let bpm: Int
}

@MainActor
final class WeeklyPulseStore: ObservableObject {
    static let shared = WeeklyPulseStore()

    @Published private(set) var records: [WeeklyPulseRecord] = []
    private let defaults = UserDefaults.standard
    private var loadedUID: String?

    /// Taken before sign-in, so stored for the device and matched to the first plan by date.
    private static let onboardingKey = "calm.pulse.onboarding.v1"

    private init() { reload() }

    private var uid: String { UnifiedFirebaseService.shared.auth.currentUserId ?? "local" }
    private var key: String { "calm.pulse.weekly.\(uid)" }

    func reload() {
        guard loadedUID != uid else { return }
        loadedUID = uid
        records = defaults.data(forKey: key).flatMap { try? JSONDecoder().decode([WeeklyPulseRecord].self, from: $0) } ?? []
    }

    func record(cycle: Int, slot: Int) -> WeeklyPulseRecord? {
        reload()
        if let record = records.first(where: { $0.cycle == cycle && $0.slot == slot }) { return record }
        guard cycle == 1, slot == 0 else { return nil }
        return onboardingRecord
    }

    /// This week's pulse has not been measured yet.
    var isDue: Bool {
        let faces = FaceScanStore.shared
        return record(cycle: faces.planPosition.cycle, slot: faces.currentSlot) == nil
    }

    /// Resting pulse measured anywhere in the app: fills this week's slot when it is still empty
    /// (the first reading of the week is the reference, later ones do not overwrite it).
    func recordRestingPulse(_ bpm: Int) {
        guard PersonalPlanStore.shared.plan != nil else { return }
        let faces = FaceScanStore.shared
        let (cycle, slot) = (faces.planPosition.cycle, faces.currentSlot)
        guard record(cycle: cycle, slot: slot) == nil else { return }
        records.append(WeeklyPulseRecord(date: Date(), cycle: cycle, slot: slot, bpm: bpm))
        if let encoded = try? JSONEncoder().encode(records) { defaults.set(encoded, forKey: key) }
    }

    /// Onboarding measurement, before the account and the plan exist.
    static func recordOnboardingPulse(_ bpm: Int) {
        let record = WeeklyPulseRecord(date: Date(), cycle: 1, slot: 0, bpm: bpm)
        if let encoded = try? JSONEncoder().encode(record) { UserDefaults.standard.set(encoded, forKey: onboardingKey) }
    }

    /// The onboarding reading counts for the first plan only when it was taken around its start
    /// (so another account signing in later on this device does not inherit it).
    private var onboardingRecord: WeeklyPulseRecord? {
        guard let plan = PersonalPlanStore.shared.plan, plan.cycle == 1,
              let record = defaults.data(forKey: Self.onboardingKey)
                .flatMap({ try? JSONDecoder().decode(WeeklyPulseRecord.self, from: $0) }) else { return nil }
        let start = Calendar.current.startOfDay(for: plan.startDate)
        guard let from = Calendar.current.date(byAdding: .day, value: -2, to: start),
              let to = Calendar.current.date(byAdding: .day, value: 1, to: start) else { return nil }
        return (from..<to).contains(record.date) ? record : nil
    }
}
