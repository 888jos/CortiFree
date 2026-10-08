import Foundation

@MainActor
final class DailyTodoService {
    private struct TodoRow: Decodable {
        let _id: String
        let userId: String
        let title: String
        let createdAt: Double
        let isCompleted: Bool
        let isActive: Bool

        var model: DailyTodo {
            DailyTodo(
                id: _id,
                userId: userId,
                title: title,
                createdAt: Date(timeIntervalSince1970: createdAt / 1000),
                isCompleted: isCompleted,
                isActive: isActive
            )
        }
    }

    func loadTodos(for userId: String) async throws -> [DailyTodo] {
        let rows: [TodoRow] = try await ConvexBackend.shared.call(.query, path: "todos:listActive")
        return rows.map(\.model).sorted { $0.createdAt < $1.createdAt }
    }

    func createTodo(_ todo: DailyTodo) async throws {
        let _: String = try await ConvexBackend.shared.call(
            .mutation, path: "todos:create", args: ["title": todo.title]
        )
    }

    func toggleTodoCompletion(_ todo: DailyTodo) async throws {
        guard let id = todo.id else { return }
        let _: JSONValue = try await ConvexBackend.shared.call(
            .mutation, path: "todos:setCompleted", args: ["id": id, "isCompleted": !todo.isCompleted]
        )
    }

    func deleteTodo(_ todo: DailyTodo) async throws {
        guard let id = todo.id else { return }
        let _: JSONValue = try await ConvexBackend.shared.call(
            .mutation, path: "todos:archive", args: ["id": id]
        )
    }

    func updateTodoTitle(_ todo: DailyTodo, newTitle: String) async throws {
        guard let id = todo.id else { return }
        let _: JSONValue = try await ConvexBackend.shared.call(
            .mutation, path: "todos:rename", args: ["id": id, "title": newTitle]
        )
    }
}
