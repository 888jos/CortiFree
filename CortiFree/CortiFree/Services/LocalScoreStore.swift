import Foundation

/// Device-local score source used until Firebase authentication is available.
enum LocalScoreStore {
    private struct Snapshot: Codable {
        var baseline: UserDomainScores?
        var current: UserDomainScores?
        var potential: UserDomainScores?
    }

    private static let key = "cortifree.local.scores.v1"

    static func saveOnboarding(currentScores: [Int], potentialScores: [Int]) {
        var snapshot = load() ?? Snapshot()
        let baseline = makeScores(from: currentScores)
        snapshot.baseline = baseline
        snapshot.current = baseline
        snapshot.potential = makeScores(from: potentialScores)
        save(snapshot)
    }

    static func saveCurrent(_ scores: UserDomainScores) {
        var snapshot = load() ?? Snapshot()
        snapshot.current = scores
        save(snapshot)
    }

    static func baseline() -> UserDomainScores? { load()?.baseline }
    static func current() -> UserDomainScores? {
        guard let snapshot = load(), let current = snapshot.current else { return nil }
        // Never let an empty remote/local snapshot hide a valid onboarding score.
        if isEmpty(current), let baseline = snapshot.baseline, !isEmpty(baseline) {
            return baseline
        }
        return current
    }
    static func potential() -> UserDomainScores? { load()?.potential }

    private static func makeScores(from values: [Int]) -> UserDomainScores? {
        guard values.count >= 6 else { return nil }
        return UserDomainScores(
            global: Double(values[0]),
            serenity: Double(values[1]),
            sleep: Double(values[2]),
            energy: Double(values[3]),
            focus: Double(values[4]),
            balance: Double(values[5])
        )
    }

    private static func isEmpty(_ scores: UserDomainScores) -> Bool {
        scores.global == 0
            && scores.serenity == 0
            && scores.sleep == 0
            && scores.energy == 0
            && scores.focus == 0
            && scores.balance == 0
    }

    private static func load() -> Snapshot? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(Snapshot.self, from: data)
    }

    private static func save(_ snapshot: Snapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}
