//
//  JournalService.swift
//  CortiFree
//
//  Service Firebase pour gérer les entrées de journal
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import UIKit

class JournalService {
    static let shared = JournalService()
    private let db = Firestore.firestore()

    private init() {}

    // MARK: - Photo Upload

    /// Convert photo to Base64 string for Firestore storage
    func uploadPhoto(_ image: UIImage) async -> String? {
        // Compress and convert to base64
        guard let imageData = image.jpegData(compressionQuality: 0.5) else {
            return nil
        }

        // Limit image size to avoid Firestore document size limits (1MB)
        let maxSize: Int = 800 * 1024 // 800KB
        if imageData.count > maxSize {
            // Resize image if too large
            if let resizedImage = resizeImage(image, targetSize: CGSize(width: 800, height: 800)),
               let resizedData = resizedImage.jpegData(compressionQuality: 0.5) {
                return resizedData.base64EncodedString()
            }
            return nil
        }

        return imageData.base64EncodedString()
    }

    /// Resize image to fit within target size while maintaining aspect ratio
    private func resizeImage(_ image: UIImage, targetSize: CGSize) -> UIImage? {
        let size = image.size
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        let ratio = min(widthRatio, heightRatio)

        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        let rect = CGRect(origin: .zero, size: newSize)

        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage
    }

    // MARK: - Journal Entry Operations

    // Sauvegarder une entrée de journal
    func saveEntry(_ entry: JournalEntry) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "JournalService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }

        var data: [String: Any] = [
            "content": entry.content,
            "createdAt": Timestamp(date: entry.createdAt),
            "userId": userId,
            "wordCount": entry.wordCount ?? 0
        ]

        // Add optional fields
        if let mood = entry.mood {
            data["mood"] = mood.rawValue
        }

        if let photoURL = entry.photoURL {
            data["photoURL"] = photoURL
        }

        // Legacy fields (for backward compatibility)
        if let meditationId = entry.meditationId {
            data["meditationId"] = meditationId
        }

        if let meditationType = entry.meditationType {
            data["meditationType"] = meditationType
        }

        if let prompt = entry.prompt {
            data["prompt"] = prompt
        }

        if let tags = entry.tags {
            data["tags"] = tags
        }

        if let isFavorite = entry.isFavorite {
            data["isFavorite"] = isFavorite
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

    // Supprimer une entrée (photo is stored as base64 in document, so it's deleted automatically)
    func deleteEntry(_ entry: JournalEntry) async throws {
        guard let userId = Auth.auth().currentUser?.uid,
              let entryId = entry.id else {
            return
        }

        // Delete entry from Firestore (photo base64 is deleted with the document)
        try await db.collection("users").document(userId)
            .collection("journalEntries").document(entryId)
            .delete()
    }
}
