//
//  DailyTodoViewModel.swift
//  CortiFree
//
//  Created by Claude on 23/10/2025.
//  ViewModel pour gérer les to-dos quotidiens
//

import Foundation
import SwiftUI
import FirebaseAuth

@MainActor
class DailyTodoViewModel: ObservableObject {
    @Published var todos: [DailyTodo] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let service = DailyTodoService()
    private var userId: String? {
        Auth.auth().currentUser?.uid
    }

    // Pour tracker le dernier jour où on a vérifié la réinitialisation
    @AppStorage("lastResetDate") private var lastResetDateString: String = ""

    // Charger tous les to-dos
    func loadTodos() async {
        guard let userId = userId else {
            errorMessage = "Vous devez être connecté pour accéder aux to-dos"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            todos = try await service.loadTodos(for: userId)
        } catch {
            errorMessage = "Erreur lors du chargement: \(error.localizedDescription)"
        }

        isLoading = false
    }

    // Créer un nouveau to-do
    func createTodo(title: String) async {
        guard !title.isEmpty else { return }

        guard let userId = userId else {
            errorMessage = "Vous devez être connecté pour créer des to-dos"
            return
        }

        let newTodo = DailyTodo(
            id: nil,
            userId: userId,
            title: title,
            createdAt: Date(),
            isCompleted: false,
            isActive: true
        )

        do {
            try await service.createTodo(newTodo)
            await loadTodos()
        } catch {
            errorMessage = "Erreur lors de la création: \(error.localizedDescription)"
        }
    }

    // Basculer la complétion d'un to-do
    func toggleCompletion(_ todo: DailyTodo) async {
        guard userId != nil else {
            errorMessage = "Vous devez être connecté"
            return
        }

        do {
            try await service.toggleTodoCompletion(todo)
            await loadTodos()

            // XP system removed - using scoring system instead
        } catch {
            errorMessage = "Erreur lors de la mise à jour: \(error.localizedDescription)"
        }
    }

    // Supprimer un to-do
    func deleteTodo(_ todo: DailyTodo) async {
        guard userId != nil else {
            errorMessage = "Vous devez être connecté"
            return
        }

        do {
            try await service.deleteTodo(todo)
            await loadTodos()
        } catch {
            errorMessage = "Erreur lors de la suppression: \(error.localizedDescription)"
        }
    }

    // Mettre à jour le titre
    func updateTitle(_ todo: DailyTodo, newTitle: String) async {
        guard !newTitle.isEmpty else { return }

        guard userId != nil else {
            errorMessage = "Vous devez être connecté"
            return
        }

        do {
            try await service.updateTodoTitle(todo, newTitle: newTitle)
            await loadTodos()
        } catch {
            errorMessage = "Erreur lors de la mise à jour: \(error.localizedDescription)"
        }
    }

    // Calculer le taux de complétion
    var completionRate: Double {
        guard !todos.isEmpty else { return 0.0 }
        let completed = todos.filter { $0.isCompleted }.count
        return Double(completed) / Double(todos.count)
    }

    // Obtenir le nombre de to-dos complétés
    var completedCount: Int {
        todos.filter { $0.isCompleted }.count
    }

    // Vérifier et supprimer tous les to-dos si on est un nouveau jour
    func checkAndResetDailyTodos() async {
        let today = Date().toDateString()

        // Si c'est un nouveau jour, supprimer TOUTES les tâches d'hier
        if lastResetDateString != today {
            guard userId != nil else { return }

            // Supprimer toutes les tâches (c'était le to-do d'hier)
            for todo in todos {
                do {
                    try await service.deleteTodo(todo)
                } catch {
                    // Ignorer les erreurs individuelles
                }
            }

            // Mettre à jour la date
            lastResetDateString = today

            // Recharger les to-dos (liste vide)
            await loadTodos()
        }
    }
}

// Extension Date pour obtenir une string "yyyy-MM-dd"
extension Date {
    func toDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: self)
    }
}
