//
//  AnxietyCheckStore.swift
//  CortiFree
//
//  GAD-7 results imported from Apple Health (per user, on device only — never synced).
//  The app never asks the questionnaire itself (Health already does): a recent result only
//  tunes the plan quietly. Progress comes from the daily check-in stress (PlanStressLoader).
//

import Foundation

@MainActor
final class AnxietyCheckStore: ObservableObject {
    static let shared = AnxietyCheckStore()

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

    var latest: AnxietyCheckResult? { results.last }

    /// Band used to tune the plan: only a check from the last 6 weeks still describes the user.
    var currentSeverity: AnxietySeverity? {
        guard let latest, latest.date > Date().addingTimeInterval(-42 * 86_400) else { return nil }
        return latest.severity
    }

    // MARK: - Import

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
}
