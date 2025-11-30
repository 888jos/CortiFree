//
//  FirebaseService.swift
//  CortiFree
//
//  Created by Claude on 22/10/2025.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

class FirebaseService: ObservableObject {
    static let shared = FirebaseService()

    private let db = Firestore.firestore()
    private var listenerRegistrations: [ListenerRegistration] = []

    private init() {}

    // MARK: - User Management

    var currentUserId: String? {
        Auth.auth().currentUser?.uid
    }

    func fetchUser() async throws -> User {
        guard let userId = currentUserId else {
            throw FirebaseError.noUserLoggedIn
        }

        let document = try await db.collection("users").document(userId).getDocument()

        if document.exists {
            return try document.data(as: User.self)
        } else {
            // Create new user if doesn't exist
            let newUser = User(id: userId)
            try await saveUser(newUser)
            return newUser
        }
    }

    func saveUser(_ user: User) async throws {
        guard let userId = user.id else {
            throw FirebaseError.invalidUserId
        }

        try db.collection("users").document(userId).setData(from: user)
    }

    func updateUserXP(addXP: Int) async throws -> User {
        guard currentUserId != nil else {
            throw FirebaseError.noUserLoggedIn
        }

        var user = try await fetchUser()
        let oldLevel = user.level
        user.xp += addXP
        user.level = (user.xp / 100) + 1

        try await saveUser(user)

        // Check if leveled up
        if user.level > oldLevel {
            NotificationCenter.default.post(name: .userLeveledUp, object: user.level)
        }

        return user
    }

    // MARK: - Tasks Management

    func fetchTasks() async throws -> [TaskItem] {
        guard let userId = currentUserId else {
            throw FirebaseError.noUserLoggedIn
        }

        let snapshot = try await db.collection("users")
            .document(userId)
            .collection("tasks")
            .order(by: "createdAt", descending: false)
            .getDocuments()

        return snapshot.documents.compactMap { try? $0.data(as: TaskItem.self) }
    }

    func saveTask(_ task: TaskItem) async throws {
        guard let userId = currentUserId else {
            throw FirebaseError.noUserLoggedIn
        }

        let taskId = task.id ?? UUID().uuidString

        try db.collection("users")
            .document(userId)
            .collection("tasks")
            .document(taskId)
            .setData(from: task)
    }

    func updateTask(_ task: TaskItem) async throws {
        try await saveTask(task)
    }

    func deleteTask(_ taskId: String) async throws {
        guard let userId = currentUserId else {
            throw FirebaseError.noUserLoggedIn
        }

        try await db.collection("users")
            .document(userId)
            .collection("tasks")
            .document(taskId)
            .delete()
    }

    func completeTask(_ taskId: String) async throws {
        guard let userId = currentUserId else {
            throw FirebaseError.noUserLoggedIn
        }

        let taskRef = db.collection("users")
            .document(userId)
            .collection("tasks")
            .document(taskId)

        try await taskRef.updateData([
            "completed": true,
            "completedAt": Timestamp()
        ])

        // Award XP
        _ = try await updateUserXP(addXP: 5)
    }

    func uncompleteTask(_ taskId: String) async throws {
        guard let userId = currentUserId else {
            throw FirebaseError.noUserLoggedIn
        }

        let taskRef = db.collection("users")
            .document(userId)
            .collection("tasks")
            .document(taskId)

        try await taskRef.updateData([
            "completed": false,
            "completedAt": FieldValue.delete()
        ])
    }

    // MARK: - Stats Management

    func fetchStats() async throws -> UserStats {
        guard let userId = currentUserId else {
            throw FirebaseError.noUserLoggedIn
        }

        let document = try await db.collection("users")
            .document(userId)
            .collection("stats")
            .document("main")
            .getDocument()

        if document.exists {
            return try document.data(as: UserStats.self)
        } else {
            let newStats = UserStats()
            try await saveStats(newStats)
            return newStats
        }
    }

    func saveStats(_ stats: UserStats) async throws {
        guard let userId = currentUserId else {
            throw FirebaseError.noUserLoggedIn
        }

        try db.collection("users")
            .document(userId)
            .collection("stats")
            .document("main")
            .setData(from: stats)
    }

    func updateDailyProgress(completionRate: Double) async throws {
        var stats = try await fetchStats()

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let todayString = dateFormatter.string(from: Date())

        stats.history[todayString] = completionRate
        stats.lastUpdated = Timestamp()

        // Update streak - criteria: at least 1 task completed (completionRate > 0)
        if completionRate > 0 {
            let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
            let yesterdayString = dateFormatter.string(from: yesterday)

            if let yesterdayRate = stats.history[yesterdayString], yesterdayRate > 0 {
                stats.streak += 1
            } else if stats.streak == 0 {
                stats.streak = 1
            }
        } else {
            stats.streak = 0
        }

        try await saveStats(stats)
    }

    // MARK: - Real-time Listeners

    func listenToUser(completion: @escaping (Result<User, Error>) -> Void) {
        guard let userId = currentUserId else {
            completion(.failure(FirebaseError.noUserLoggedIn))
            return
        }

        let listener = db.collection("users").document(userId).addSnapshotListener { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let snapshot = snapshot, snapshot.exists else {
                completion(.failure(FirebaseError.documentNotFound))
                return
            }

            do {
                let user = try snapshot.data(as: User.self)
                completion(.success(user))
            } catch {
                completion(.failure(error))
            }
        }

        listenerRegistrations.append(listener)
    }

    func removeAllListeners() {
        listenerRegistrations.forEach { $0.remove() }
        listenerRegistrations.removeAll()
    }
}

// MARK: - Errors

enum FirebaseError: LocalizedError {
    case noUserLoggedIn
    case invalidUserId
    case documentNotFound

    var errorDescription: String? {
        switch self {
        case .noUserLoggedIn:
            return "Aucun utilisateur connecté"
        case .invalidUserId:
            return "ID utilisateur invalide"
        case .documentNotFound:
            return "Document introuvable"
        }
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let userLeveledUp = Notification.Name("userLeveledUp")
}
