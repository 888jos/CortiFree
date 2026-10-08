import Foundation

/// Compatibility facade for older view models. No Firebase SDK is used.
@MainActor
final class FirebaseService: ObservableObject {
    static let shared = FirebaseService()
    private init() {}

    var currentUserId: String? { Auth.auth().currentUser?.uid }

    private struct StatsRow: Decodable {
        let streak: Int
        let totalTasksCompleted: Int
        let history: [String: Double]
        let updatedAt: Double?
    }

    private struct TaskRow: Decodable {
        let _id: String
        let _creationTime: Double
        let title: String
        let category: String
        let completed: Bool
        let frequency: Int?
        let goalType: String?
        let completedAt: Double?
        let taskFrequency: String?
        let customCategory: String?
        let durationInMinutes: Int?
        let isCustomTask: Bool?
        let icon: String?
        let sfSymbol: String?
        let recommendedTime: String?
        let taskDescription: String?
        let habitId: String?

        var model: TaskItem {
            TaskItem(
                id: _id,
                title: title,
                category: TaskCategory(rawValue: category) ?? .day,
                completed: completed,
                frequency: frequency ?? 1,
                goalType: goalType ?? "equilibre",
                createdAt: Timestamp(date: Date(timeIntervalSince1970: _creationTime / 1000)),
                completedAt: completedAt.map { Timestamp(date: Date(timeIntervalSince1970: $0 / 1000)) },
                taskFrequency: taskFrequency.flatMap(TaskFrequency.init(rawValue:)),
                customCategory: customCategory.flatMap(CustomTaskCategory.init(rawValue:)),
                durationInMinutes: durationInMinutes,
                isCustomTask: isCustomTask ?? false,
                icon: icon,
                sfSymbol: sfSymbol,
                recommendedTime: recommendedTime,
                taskDescription: taskDescription,
                habitId: habitId
            )
        }
    }

    func fetchUser() async throws -> User {
        guard let profile = Auth.auth().currentUser else { throw FirebaseError.noUserLoggedIn }
        return User(id: profile.uid, name: profile.displayName ?? profile.firstName ?? "")
    }

    func saveUser(_ user: User) async throws {
        guard currentUserId != nil else { throw FirebaseError.noUserLoggedIn }
        let _: JSONValue = try await ConvexBackend.shared.call(
            .mutation, path: "profile:updateProfile", args: ["displayName": user.name]
        )
    }

    func updateUserXP(addXP: Int) async throws -> User {
        var user = try await fetchUser()
        let oldLevel = user.level
        user.xp += addXP
        user.level = (user.xp / 100) + 1
        if user.level > oldLevel {
            NotificationCenter.default.post(name: .userLeveledUp, object: user.level)
        }
        return user
    }

    func fetchTasks() async throws -> [TaskItem] {
        guard currentUserId != nil else { throw FirebaseError.noUserLoggedIn }
        let rows: [TaskRow] = try await ConvexBackend.shared.call(.query, path: "tasks:listUserTasks")
        return rows.map(\.model).sorted { $0.createdAt.dateValue() < $1.createdAt.dateValue() }
    }

    func saveTask(_ task: TaskItem) async throws {
        guard currentUserId != nil else { throw FirebaseError.noUserLoggedIn }
        var args: [String: Any] = [
            "title": task.title,
            "category": task.category.rawValue,
            "completed": task.completed,
            "frequency": task.frequency,
            "goalType": task.goalType,
            "isCustomTask": task.isCustomTask,
        ]
        if let value = task.id { args["id"] = value }
        if let value = task.completedAt { args["completedAt"] = value.dateValue().timeIntervalSince1970 * 1000 }
        if let value = task.taskFrequency { args["taskFrequency"] = value.rawValue }
        if let value = task.customCategory { args["customCategory"] = value.rawValue }
        if let value = task.durationInMinutes { args["durationInMinutes"] = value }
        if let value = task.icon { args["icon"] = value }
        if let value = task.sfSymbol { args["sfSymbol"] = value }
        if let value = task.recommendedTime { args["recommendedTime"] = value }
        if let value = task.taskDescription { args["taskDescription"] = value }
        if let value = task.habitId { args["habitId"] = value }
        let _: String = try await ConvexBackend.shared.call(.mutation, path: "tasks:upsertUserTask", args: args)
    }

    func updateTask(_ task: TaskItem) async throws { try await saveTask(task) }

    func deleteTask(_ taskId: String) async throws {
        let _: JSONValue = try await ConvexBackend.shared.call(
            .mutation, path: "tasks:removeUserTask", args: ["id": taskId]
        )
    }

    func completeTask(_ taskId: String) async throws { try await setTask(taskId, completed: true) }
    func uncompleteTask(_ taskId: String) async throws { try await setTask(taskId, completed: false) }

    private func setTask(_ id: String, completed: Bool) async throws {
        guard var task = try await fetchTasks().first(where: { $0.id == id }) else {
            throw FirebaseError.documentNotFound
        }
        task.completed = completed
        task.completedAt = completed ? Timestamp() : nil
        try await saveTask(task)
    }

    func fetchStats() async throws -> UserStats {
        let row: StatsRow = try await ConvexBackend.shared.call(.query, path: "progress:getStats")
        return UserStats(
            streak: row.streak,
            lastUpdated: Timestamp(date: row.updatedAt.map { Date(timeIntervalSince1970: $0 / 1000) } ?? Date()),
            history: row.history,
            totalTasksCompleted: row.totalTasksCompleted
        )
    }

    func saveStats(_ stats: UserStats) async throws {
        let _: JSONValue = try await ConvexBackend.shared.call(
            .mutation,
            path: "progress:updateStats",
            args: ["streak": stats.streak, "totalTasksCompleted": stats.totalTasksCompleted]
        )
    }

    func updateDailyProgress(completionRate: Double) async throws {
        var stats = try await fetchStats()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())
        let yesterday = formatter.string(from: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date())
        if completionRate > 0 {
            stats.streak = (stats.history[yesterday] ?? 0) > 0 ? stats.streak + 1 : max(1, stats.streak)
        } else {
            stats.streak = 0
        }
        let _: JSONValue = try await ConvexBackend.shared.call(
            .mutation,
            path: "progress:updateStats",
            args: ["streak": stats.streak, "historyEntry": ["date": today, "value": completionRate]]
        )
    }

    func listenToUser(completion: @escaping (Result<User, Error>) -> Void) {
        Task {
            do { completion(.success(try await fetchUser())) }
            catch { completion(.failure(error)) }
        }
    }

    func removeAllListeners() {}
}

enum FirebaseError: LocalizedError {
    case noUserLoggedIn, invalidUserId, documentNotFound
    var errorDescription: String? {
        switch self {
        case .noUserLoggedIn: return "Aucun utilisateur connecté"
        case .invalidUserId: return "ID utilisateur invalide"
        case .documentNotFound: return "Document introuvable"
        }
    }
}

extension Notification.Name {
    static let userLeveledUp = Notification.Name("userLeveledUp")
}
