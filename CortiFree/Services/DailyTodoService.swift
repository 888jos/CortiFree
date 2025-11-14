//
//  DailyTodoService.swift
//  CortiFree
//
//  Created by Claude on 23/10/2025.
//  Service pour gérer les to-dos quotidiens dans Firebase
//

import Foundation
import FirebaseFirestore

class DailyTodoService {
    private let db = Firestore.firestore()
    private let collectionName = "dailyTodos"

    // Charger tous les to-dos actifs d'un utilisateur
    func loadTodos(for userId: String) async throws -> [DailyTodo] {
        let snapshot = try await db.collection(collectionName)
            .whereField("userId", isEqualTo: userId)
            .whereField("isActive", isEqualTo: true)
            .getDocuments()

        // Trier en mémoire au lieu d'utiliser orderBy (évite l'index composite)
        let todos = snapshot.documents.compactMap { doc in
            try? doc.data(as: DailyTodo.self)
        }

        return todos.sorted { $0.createdAt < $1.createdAt }
    }

    // Créer un nouveau to-do
    func createTodo(_ todo: DailyTodo) async throws {
        let _ = try db.collection(collectionName).addDocument(from: todo)
    }

    // Basculer l'état de complétion
    func toggleTodoCompletion(_ todo: DailyTodo) async throws {
        guard let todoId = todo.id else { return }

        try await db.collection(collectionName)
            .document(todoId)
            .updateData([
                "isCompleted": !todo.isCompleted
            ])
    }

    // Supprimer un to-do (archive)
    func deleteTodo(_ todo: DailyTodo) async throws {
        guard let todoId = todo.id else { return }

        try await db.collection(collectionName)
            .document(todoId)
            .updateData([
                "isActive": false
            ])
    }

    // Mettre à jour le titre d'un to-do
    func updateTodoTitle(_ todo: DailyTodo, newTitle: String) async throws {
        guard let todoId = todo.id else { return }

        try await db.collection(collectionName)
            .document(todoId)
            .updateData([
                "title": newTitle
            ])
    }
}
