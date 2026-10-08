import Foundation

@MainActor
final class TaskStatusService {
    static let shared = TaskStatusService()
    static let habitTotals = ["meditation": 47, "breathing": 47, "journal": 66, "sport": 28,
                              "water": 66, "nature": 28, "social": 28, "sleep": 132]
    private init() {}

    func saveTaskStatus(day: Int, taskTitle: String, status: String) async throws {
        let _: JSONValue = try await ConvexBackend.shared.call(.mutation, path: "tasks:setStatus", args: [
            "programDay": day, "key": taskTitle, "status": status,
        ])
    }

    func loadAllTaskStatuses() async throws -> [String: [String: String]] {
        let rows: [StatusRow] = try await ConvexBackend.shared.call(.query, path: "tasks:listStatuses")
        return Dictionary(uniqueKeysWithValues: rows.map { ("day_\($0.programDay)", $0.statuses) })
    }

    func deleteTaskStatus(day: Int, taskTitle: String) async throws {
        let _: JSONValue = try await ConvexBackend.shared.call(.mutation, path: "tasks:clearStatus", args: [
            "programDay": day, "key": taskTitle,
        ])
    }

    func calculateHabitProgress() async throws -> [String: (completed: Int, total: Int)] {
        let statuses = (try? await loadAllTaskStatuses()) ?? [:]
        var result = Dictionary(uniqueKeysWithValues: Self.habitTotals.map { ($0.key, (completed: 0, total: $0.value)) })
        for tasks in statuses.values {
            for (title, status) in tasks where status == "done" {
                let habit = habitId(from: title)
                if var value = result[habit] { value.completed += 1; result[habit] = value }
            }
        }
        let userId = UnifiedFirebaseService.shared.auth.currentUser?.uid ?? UserPersistence.localUserID
        var local: [String: Int] = [:]
        LocalProgressStore.load(for: userId).forEach { local[$0.habitID, default: 0] += 1 }
        for (habit, count) in local where result[habit] != nil {
            result[habit]!.completed = max(result[habit]!.completed, count)
        }
        return result
    }

    private func habitId(from title: String) -> String {
        let value = title.lowercased()
        if ["lever", "coucher", "sommeil", "sleep", "routine"].contains(where: value.contains) { return "sleep" }
        if ["respir", "breath"].contains(where: value.contains) { return "breathing" }
        if ["médit", "medit"].contains(where: value.contains) { return "meditation" }
        if ["eau", "water", "boire", "hydrat"].contains(where: value.contains) { return "water" }
        if ["sport", "exercice", "nager", "course", "vélo", "sommet", "sauter"].contains(where: value.contains) { return "sport" }
        if ["nature", "marche", "balade", "plein air"].contains(where: value.contains) { return "nature" }
        if ["social", "ami", "lien", "appel", "rencontre", "convivial"].contains(where: value.contains) { return "social" }
        if ["journal", "écrire", "pensée", "noter"].contains(where: value.contains) { return "journal" }
        return "unknown"
    }
}

private struct StatusRow: Decodable { let programDay: Int; let statuses: [String: String] }
