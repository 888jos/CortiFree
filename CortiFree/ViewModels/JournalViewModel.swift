//
//  JournalViewModel.swift
//  CortiFree
//
//  Created by Claude on 23/10/2025.
//  ViewModel pour gérer les entrées de journal
//

import Foundation
import FirebaseAuth

@MainActor
class JournalViewModel: ObservableObject {
    @Published var entries: [JournalEntry] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let journalService = JournalService.shared

    // Sauvegarder une nouvelle entrée
    func saveEntry(meditationId: String, meditationType: String, prompt: String?, content: String, mood: Mood? = nil, tags: [String]? = nil, reloadAll: Bool = false) async {
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "Utilisateur non connecté"
            return
        }

        guard !content.isEmpty else {
            errorMessage = "Le contenu ne peut pas être vide"
            return
        }

        isLoading = true
        errorMessage = nil

        // Calculate word count
        let wordCount = content.split(separator: " ").count

        let entry = JournalEntry(
            id: nil,
            meditationId: meditationId,
            meditationType: meditationType,
            prompt: prompt,
            content: content,
            createdAt: Date(),
            userId: userId,
            mood: mood,
            tags: tags,
            isFavorite: false,
            wordCount: wordCount
        )

        do {
            try await journalService.saveEntry(entry)
            // Recharger toutes les entrées ou seulement celles de la méditation
            if reloadAll {
                await loadAllEntries()
            } else {
                await loadEntries(for: meditationId)
            }
        } catch {
            errorMessage = "Erreur lors de la sauvegarde: \(error.localizedDescription)"
        }

        isLoading = false
    }

    // Charger les entrées pour une méditation
    func loadEntries(for meditationId: String) async {
        isLoading = true
        errorMessage = nil

        do {
            entries = try await journalService.loadEntries(for: meditationId)
        } catch {
            errorMessage = "Erreur lors du chargement: \(error.localizedDescription)"
        }

        isLoading = false
    }

    // Charger toutes les entrées
    func loadAllEntries() async {
        isLoading = true
        errorMessage = nil

        do {
            entries = try await journalService.loadAllEntries()
        } catch {
            errorMessage = "Erreur lors du chargement: \(error.localizedDescription)"
        }

        isLoading = false
    }

    // Charger les entrées par type
    func loadEntries(byType type: String) async {
        isLoading = true
        errorMessage = nil

        do {
            entries = try await journalService.loadEntries(byType: type)
        } catch {
            errorMessage = "Erreur lors du chargement: \(error.localizedDescription)"
        }

        isLoading = false
    }

    // Supprimer une entrée
    func deleteEntry(_ entry: JournalEntry) async {
        do {
            try await journalService.deleteEntry(entry)
            entries.removeAll { $0.id == entry.id }
        } catch {
            errorMessage = "Erreur lors de la suppression: \(error.localizedDescription)"
        }
    }
}
