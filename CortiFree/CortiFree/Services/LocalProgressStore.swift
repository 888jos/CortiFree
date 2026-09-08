import Foundation

/// Local source of truth for completions made before Firebase finishes syncing.
enum LocalProgressStore {
    struct Completion: Codable, Equatable, Identifiable {
        let taskID: String
        let habitID: String
        let programDay: Int
        let completedAt: Date
        let durationSeconds: Int

        var id: String { "\(programDay):\(taskID)" }
    }

    private static let keyPrefix = "cortifree.local.progress.v1"

    static func recordCompletion(
        taskID: String,
        habitID: String,
        programDay: Int,
        durationSeconds: Int,
        completedAt: Date = Date(),
        userID: String
    ) {
        var completions = load(for: userID)
        let completion = Completion(
            taskID: taskID,
            habitID: habitID,
            programDay: programDay,
            completedAt: completedAt,
            durationSeconds: max(0, durationSeconds)
        )

        if let index = completions.firstIndex(where: { $0.id == completion.id }) {
            completions[index] = completion
        } else {
            completions.append(completion)
        }
        save(completions, for: userID)
    }

    static func removeCompletion(taskID: String, programDay: Int, userID: String) {
        let id = "\(programDay):\(taskID)"
        save(load(for: userID).filter { $0.id != id }, for: userID)
    }

    static func load(for userID: String) -> [Completion] {
        guard let data = UserDefaults.standard.data(forKey: key(for: userID)),
              let completions = try? JSONDecoder().decode([Completion].self, from: data) else {
            return []
        }
        return completions
    }

    static func completedCount(for habitID: String, userID: String) -> Int {
        load(for: userID).filter { $0.habitID == habitID }.count
    }

    #if DEBUG
    static func clear(for userID: String) {
        UserDefaults.standard.removeObject(forKey: key(for: userID))
    }
    #endif

    private static func save(_ completions: [Completion], for userID: String) {
        guard let data = try? JSONEncoder().encode(completions) else { return }
        UserDefaults.standard.set(data, forKey: key(for: userID))
    }

    private static func key(for userID: String) -> String {
        "\(keyPrefix).\(userID)"
    }
}
