import Foundation

/// Local source of truth for exercise sessions until a signed-in user syncs with Firestore.
enum LocalActivitySessionStore {
    struct Session: Codable, Equatable, Identifiable {
        let id: String
        let exerciseID: String
        let category: ProgressActivityCategory
        let durationSeconds: Int
        let completedAt: Date
        let source: String
    }

    private static let keyPrefix = "cortifree.local.activity-sessions.v1"

    @discardableResult
    static func record(
        exerciseID: String,
        category: ProgressActivityCategory,
        durationSeconds: Int,
        completedAt: Date = Date(),
        source: String,
        userID: String
    ) -> String? {
        let duration = max(0, durationSeconds)
        guard duration > 0 else { return nil }

        let session = Session(
            id: UUID().uuidString,
            exerciseID: exerciseID,
            category: category,
            durationSeconds: duration,
            completedAt: completedAt,
            source: source
        )
        var sessions = load(for: userID)
        sessions.append(session)
        save(sessions, for: userID)
        return session.id
    }

    static func load(for userID: String) -> [Session] {
        guard let data = UserDefaults.standard.data(forKey: key(for: userID)),
              let sessions = try? JSONDecoder().decode([Session].self, from: data) else {
            return []
        }
        return sessions
    }

    #if DEBUG
    static func clear(for userID: String) {
        UserDefaults.standard.removeObject(forKey: key(for: userID))
    }
    #endif

    private static func save(_ sessions: [Session], for userID: String) {
        guard let data = try? JSONEncoder().encode(sessions) else { return }
        UserDefaults.standard.set(data, forKey: key(for: userID))
    }

    private static func key(for userID: String) -> String {
        "\(keyPrefix).\(userID)"
    }
}
