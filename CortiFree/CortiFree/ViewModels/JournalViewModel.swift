//
//  JournalViewModel.swift
//  CortiFree
//
//  ViewModel pour gérer les entrées de journal
//

import Foundation
import FirebaseAuth
import UIKit

@MainActor
class JournalViewModel: ObservableObject {
    @Published var entries: [JournalEntry] = []
    @Published var allEntries: [JournalEntry] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let journalService = JournalService.shared

    // MARK: - New Simplified Methods

    /// Save simplified journal entry with optional photo
    func saveEntry(content: String, mood: Mood?, photoURL: String?, wordCount: Int, entryId: String? = nil) async {
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = NSLocalizedString("error.auth.not_connected", comment: "")
            return
        }

        guard !content.isEmpty else {
            errorMessage = NSLocalizedString("error.journal.empty_content", comment: "")
            return
        }

        isLoading = true
        errorMessage = nil

        let entry = JournalEntry(
            id: entryId,  // Pass existing ID if updating
            content: content,
            createdAt: Date(),
            userId: userId,
            mood: mood,
            photoURL: photoURL,
            wordCount: wordCount,
            meditationId: nil,
            meditationType: nil,
            prompt: nil,
            tags: nil,
            isFavorite: nil
        )

        do {
            try await journalService.saveEntry(entry)
            await loadAllEntries()
        } catch {
            errorMessage = String(format: NSLocalizedString("error.journal.save_failed", comment: ""), error.localizedDescription)
        }

        isLoading = false
    }

    /// Upload photo to Firebase Storage
    func uploadPhoto(_ image: UIImage) async -> String? {
        return await journalService.uploadPhoto(image)
    }

    // MARK: - Legacy Methods (for backward compatibility)

    /// Save entry with legacy format
    func saveEntry(meditationId: String, meditationType: String, prompt: String?, content: String, mood: Mood? = nil, tags: [String]? = nil, reloadAll: Bool = false) async {
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = NSLocalizedString("error.auth.not_connected", comment: "")
            return
        }

        guard !content.isEmpty else {
            errorMessage = NSLocalizedString("error.journal.empty_content", comment: "")
            return
        }

        isLoading = true
        errorMessage = nil

        // Calculate word count
        let wordCount = content.split(separator: " ").count

        let entry = JournalEntry(
            id: nil,
            content: content,
            createdAt: Date(),
            userId: userId,
            mood: mood,
            photoURL: nil,
            wordCount: wordCount,
            meditationId: meditationId,
            meditationType: meditationType,
            prompt: prompt,
            tags: tags,
            isFavorite: false
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
            errorMessage = String(format: NSLocalizedString("error.journal.save_failed", comment: ""), error.localizedDescription)
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
            errorMessage = String(format: NSLocalizedString("error.journal.load_failed", comment: ""), error.localizedDescription)
        }

        isLoading = false
    }

    // Charger toutes les entrées
    func loadAllEntries() async {
        isLoading = true
        errorMessage = nil

        do {
            allEntries = try await journalService.loadAllEntries()
            entries = allEntries // Keep both for compatibility
        } catch {
            errorMessage = String(format: NSLocalizedString("error.journal.load_failed", comment: ""), error.localizedDescription)
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
            errorMessage = String(format: NSLocalizedString("error.journal.load_failed", comment: ""), error.localizedDescription)
        }

        isLoading = false
    }

    // Supprimer une entrée
    func deleteEntry(_ entry: JournalEntry) async {
        do {
            try await journalService.deleteEntry(entry)
            entries.removeAll { $0.id == entry.id }
            allEntries.removeAll { $0.id == entry.id }
        } catch {
            errorMessage = String(format: NSLocalizedString("error.journal.delete_failed", comment: ""), error.localizedDescription)
        }
    }
}
