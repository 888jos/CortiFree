import Foundation
import UIKit

@MainActor
final class JournalService {
    static let shared = JournalService()
    private init() {}

    private struct JournalRow: Decodable {
        let _id: String
        let userId: String
        let content: String
        let createdAt: Double
        let mood: Mood?
        let photoUrl: String?
        let wordCount: Int?
        let meditationId: String?
        let meditationType: String?
        let prompt: String?
        let tags: [String]?
        let isFavorite: Bool?

        var model: JournalEntry {
            JournalEntry(
                id: _id,
                content: content,
                createdAt: Date(timeIntervalSince1970: createdAt / 1000),
                userId: userId,
                mood: mood,
                photoURL: photoUrl,
                wordCount: wordCount,
                meditationId: meditationId,
                meditationType: meditationType,
                prompt: prompt,
                tags: tags,
                isFavorite: isFavorite
            )
        }
    }

    /// Returns the Convex storage id consumed by `saveEntry`.
    func uploadPhoto(_ image: UIImage) async -> String? {
        let prepared: UIImage
        if image.size.width > 1200 || image.size.height > 1200 {
            prepared = resizeImage(image, targetSize: CGSize(width: 1200, height: 1200)) ?? image
        } else {
            prepared = image
        }
        guard let data = prepared.jpegData(compressionQuality: 0.72) else { return nil }
        do {
            let uploadURL: String = try await ConvexBackend.shared.call(
                .mutation, path: "journal:generatePhotoUploadUrl"
            )
            return try await ConvexBackend.shared.upload(data, to: uploadURL)
        } catch {
            #if DEBUG
            print("⚠️ Journal photo upload failed: \(error.localizedDescription)")
            #endif
            return nil
        }
    }

    private func resizeImage(_ image: UIImage, targetSize: CGSize) -> UIImage? {
        let ratio = min(targetSize.width / image.size.width, targetSize.height / image.size.height, 1)
        let size = CGSize(width: image.size.width * ratio, height: image.size.height * ratio)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: size)) }
    }

    func saveEntry(_ entry: JournalEntry) async throws {
        guard Auth.auth().currentUser != nil else { throw ConvexBackendError.signedOut }
        var fields: [String: Any] = ["content": entry.content]
        if let mood = entry.mood { fields["mood"] = mood.rawValue }
        if let value = entry.meditationId { fields["meditationId"] = value }
        if let value = entry.meditationType { fields["meditationType"] = value }
        if let value = entry.prompt { fields["prompt"] = value }
        if let value = entry.tags { fields["tags"] = value }
        if let value = entry.isFavorite { fields["isFavorite"] = value }

        if let id = entry.id {
            fields["id"] = id
            if let photo = entry.photoURL, !photo.hasPrefix("http") { fields["photoStorageId"] = photo }
            let _: JSONValue = try await ConvexBackend.shared.call(.mutation, path: "journal:update", args: fields)
        } else {
            fields["createdAt"] = entry.createdAt.timeIntervalSince1970 * 1000
            if let photo = entry.photoURL { fields["photoStorageId"] = photo }
            let _: String = try await ConvexBackend.shared.call(.mutation, path: "journal:create", args: fields)
        }
    }

    func loadEntries(for meditationId: String) async throws -> [JournalEntry] {
        try await loadFiltered(["meditationId": meditationId])
    }

    func loadAllEntries() async throws -> [JournalEntry] {
        let rows: [JournalRow] = try await ConvexBackend.shared.call(
            .query, path: "journal:list", args: ["limit": 500]
        )
        return rows.map(\.model)
    }

    func loadEntries(byType type: String) async throws -> [JournalEntry] {
        try await loadFiltered(["meditationType": type])
    }

    private func loadFiltered(_ args: [String: Any]) async throws -> [JournalEntry] {
        let rows: [JournalRow] = try await ConvexBackend.shared.call(
            .query, path: "journal:listByMeditation", args: args
        )
        return rows.map(\.model)
    }

    func deleteEntry(_ entry: JournalEntry) async throws {
        guard let id = entry.id else { return }
        let _: JSONValue = try await ConvexBackend.shared.call(
            .mutation, path: "journal:remove", args: ["id": id]
        )
    }
}
