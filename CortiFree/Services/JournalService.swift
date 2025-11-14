//
//  JournalService.swift
//  CortiFree
//
//  Created by Claude on 23/10/2025.
//  Service Firebase pour gérer les entrées de journal
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

class JournalService {
    static let shared = JournalService()
    private let db = Firestore.firestore()

    private init() {}

    // Sauvegarder une entrée de journal
    func saveEntry(_ entry: JournalEntry) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "JournalService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }

        var data: [String: Any] = [
            "meditationId": entry.meditationId,
            "meditationType": entry.meditationType,
            "prompt": entry.prompt ?? "",
            "content": entry.content,
            "createdAt": Timestamp(date: entry.createdAt),
            "userId": userId,
            "isFavorite": entry.isFavorite ?? false,
            "wordCount": entry.wordCount ?? 0
        ]

        // Ajouter mood si présent
        if let mood = entry.mood {
            data["mood"] = mood.rawValue
        }

        // Ajouter tags si présent
        if let tags = entry.tags {
            data["tags"] = tags
        }

        if let id = entry.id {
            // Update existing entry
            try await db.collection("users").document(userId)
                .collection("journalEntries").document(id)
                .setData(data)
        } else {
            // Create new entry
            try await db.collection("users").document(userId)
                .collection("journalEntries")
                .addDocument(data: data)
        }
    }

    // Charger toutes les entrées pour un type de méditation
    func loadEntries(for meditationId: String) async throws -> [JournalEntry] {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "JournalService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }

        let snapshot = try await db.collection("users").document(userId)
            .collection("journalEntries")
            .whereField("meditationId", isEqualTo: meditationId)
            .order(by: "createdAt", descending: true)
            .getDocuments()

        return snapshot.documents.compactMap { doc in
            try? doc.data(as: JournalEntry.self)
        }
    }

    // Charger toutes les entrées
    func loadAllEntries() async throws -> [JournalEntry] {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "JournalService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }

        let snapshot = try await db.collection("users").document(userId)
            .collection("journalEntries")
            .order(by: "createdAt", descending: true)
            .getDocuments()

        return snapshot.documents.compactMap { doc in
            try? doc.data(as: JournalEntry.self)
        }
    }

    // Charger les entrées par type
    func loadEntries(byType type: String) async throws -> [JournalEntry] {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "JournalService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }

        let snapshot = try await db.collection("users").document(userId)
            .collection("journalEntries")
            .whereField("meditationType", isEqualTo: type)
            .order(by: "createdAt", descending: true)
            .getDocuments()

        return snapshot.documents.compactMap { doc in
            try? doc.data(as: JournalEntry.self)
        }
    }

    // Supprimer une entrée
    func deleteEntry(_ entry: JournalEntry) async throws {
        guard let userId = Auth.auth().currentUser?.uid,
              let entryId = entry.id else {
            return
        }

        try await db.collection("users").document(userId)
            .collection("journalEntries").document(entryId)
            .delete()
    }
}
