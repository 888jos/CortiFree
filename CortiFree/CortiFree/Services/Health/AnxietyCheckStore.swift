//
//  AnxietyCheckStore.swift
//  CortiFree
//
//  Local history of GAD-7 results (per user, on device only — never synced to Firestore).
//  The plan asks for a check on days 1, 14 and 28: the first one tunes the plan, the next
//  ones show the user how their anxiety evolved.
//

import Foundation

@MainActor
final class AnxietyCheckStore: ObservableObject {
    static let shared = AnxietyCheckStore()

    /// Plan days on which a check is suggested (GAD-7 covers the last 2 weeks).
    static let checkpoints = [1, 14, 28]

    /// Results of the signed-in user, oldest first.
    var results: [AnxietyCheckResult] {
        reloadIfNeeded()
        return storage
    }

    // Not @Published: reloads happen while views read the store (account switch).
    private var storage: [AnxietyCheckResult] = []

    private let defaults = UserDefaults.standard
    private var loadedForUser = ""

    private init() {
        reloadIfNeeded()
    }

    private var userKey: String { Auth.auth().currentUser?.uid ?? UserPersistence.localUserID }
    private var resultsKey: String { "anxietyCheck.results.v1.\(userKey)" }
    private var snoozeKey: String { "anxietyCheck.snoozedDay.v1.\(userKey)" }

    var latest: AnxietyCheckResult? { results.last }

    /// Band used to tune the plan: only a check from the last 6 weeks still describes the user.
    var currentSeverity: AnxietySeverity? {
        guard let latest, latest.date > Date().addingTimeInterval(-42 * 86_400) else { return nil }
        return latest.severity
    }

    // MARK: - Due checks

    /// The checkpoint (1, 14 or 28) the user should take now, if any.
    func dueCheckpoint(for plan: PersonalPlan, now: Date = Date()) -> Int? {
        let today = plan.dayIndex()
        guard let checkpoint = Self.checkpoints.last(where: { $0 <= today }),
              let windowStart = Calendar.current.date(byAdding: .day, value: checkpoint - 1, to: plan.startDate) else { return nil }
        // Day 1: a check from the last 2 weeks (e.g. taken in the Health app) still counts.
        let validSince = checkpoint == 1
            ? Calendar.current.date(byAdding: .day, value: -14, to: windowStart) ?? windowStart
            : windowStart
        if let latest, latest.date >= validSince { return nil }
        if defaults.string(forKey: snoozeKey) == Self.dayKey(now) { return nil }
        return checkpoint
    }

    func snoozeForToday() {
        defaults.set(Self.dayKey(Date()), forKey: snoozeKey)
        objectWillChange.send()
    }

    /// First result taken during the current plan (baseline for the before / after comparison).
    func baseline(for plan: PersonalPlan) -> AnxietyCheckResult? {
        let since = Calendar.current.date(byAdding: .day, value: -14, to: plan.startDate) ?? plan.startDate
        return results.first { $0.date >= since }
    }

    // MARK: - Saving

    /// Saves a check taken in the app (locally + Apple Health when enabled).
    func record(_ result: AnxietyCheckResult) {
        append(result)
        if result.source == .app {
            Task { await HealthKitService.shared.save(result) }
        }
    }

    /// Imports the latest GAD-7 from Apple Health when it is newer than ours.
    @discardableResult
    func importFromHealth() async -> Bool {
        guard let imported = await HealthKitService.shared.latestGAD7(),
              imported.date > (latest?.date ?? .distantPast) else { return false }
        append(imported)
        return true
    }

    private func append(_ result: AnxietyCheckResult) {
        objectWillChange.send()
        var updated = results.filter { abs($0.date.timeIntervalSince(result.date)) >= 1 }
        updated.append(result)
        updated.sort { $0.date < $1.date }
        storage = updated
        if let data = try? JSONEncoder().encode(updated) {
            defaults.set(data, forKey: resultsKey)
        }
    }

    private func reloadIfNeeded() {
        guard loadedForUser != userKey else { return }
        loadedForUser = userKey
        storage = defaults.data(forKey: resultsKey)
            .flatMap { try? JSONDecoder().decode([AnxietyCheckResult].self, from: $0) } ?? []
    }

    private static func dayKey(_ date: Date) -> String {
        let components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return "\(components.year ?? 0)-\(components.month ?? 0)-\(components.day ?? 0)"
    }
}
