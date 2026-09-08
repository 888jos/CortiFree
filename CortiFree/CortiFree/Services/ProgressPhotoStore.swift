import Foundation
import UIKit

struct ProgressPhoto: Codable, Identifiable, Equatable {
    let id: UUID
    let createdAt: Date
    let filename: String
}

@MainActor
final class ProgressPhotoStore: ObservableObject {
    static let shared = ProgressPhotoStore()

    @Published private(set) var photos: [ProgressPhoto] = []

    private let fileManager = FileManager.default
    private let metadataFilename = "metadata.json"

    private init() {
        load()
    }

    func image(for photo: ProgressPhoto) -> UIImage? {
        UIImage(contentsOfFile: photosDirectory.appendingPathComponent(photo.filename).path)
    }

    func add(data: Data, date: Date = Date()) throws {
        guard let image = UIImage(data: data),
              let jpeg = image.jpegData(compressionQuality: 0.82) else {
            throw CocoaError(.fileReadCorruptFile)
        }

        try preparePhotosDirectory()
        let photo = ProgressPhoto(id: UUID(), createdAt: date, filename: "\(UUID().uuidString).jpg")
        try jpeg.write(
            to: photosDirectory.appendingPathComponent(photo.filename),
            options: [.atomic, .completeFileProtection]
        )
        photos.insert(photo, at: 0)
        try persist()
    }

    func delete(_ photo: ProgressPhoto) {
        try? fileManager.removeItem(at: photosDirectory.appendingPathComponent(photo.filename))
        photos.removeAll { $0.id == photo.id }
        try? persist()
    }

    private var photosDirectory: URL {
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("ProgressPhotos", isDirectory: true)
    }

    private var metadataURL: URL {
        photosDirectory.appendingPathComponent(metadataFilename)
    }

    private func load() {
        guard let data = try? Data(contentsOf: metadataURL),
              let decoded = try? JSONDecoder().decode([ProgressPhoto].self, from: data) else { return }
        photos = decoded.sorted { $0.createdAt > $1.createdAt }
    }

    private func persist() throws {
        try preparePhotosDirectory()
        try JSONEncoder().encode(photos).write(
            to: metadataURL,
            options: [.atomic, .completeFileProtection]
        )
    }

    private func preparePhotosDirectory() throws {
        try fileManager.createDirectory(at: photosDirectory, withIntermediateDirectories: true)
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        var directory = photosDirectory
        try directory.setResourceValues(values)
    }
}
