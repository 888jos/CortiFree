//
//  FaceScan.swift
//  CortiFree
//
//  Weekly face check: one selfie on days 1, 7, 14, 21 and 28 of the plan. Milo describes
//  visible signs of tiredness (through the Convex « faceScan:analyze » action, OpenAI vision)
//  and the photos build a week-by-week before/after. The photo stays on the device; only
//  the analysis request sends it, once. Wellness only, never a cortisol or medical measure.
//

import Foundation
import UIKit

struct FaceScanResult: Codable, Equatable {
    enum Level: String, Codable { case low, medium, high }

    var restedScore: Int
    var puffiness: Level
    var darkCircles: Level
    var jawTension: Level
    var skinDullness: Level
    var summary: String
    var tip: String
}

struct FaceScanRecord: Codable, Equatable, Identifiable {
    var id: UUID { photoID }
    let photoID: UUID
    let date: Date
    let cycle: Int
    /// 0…4 → days 1, 7, 14, 21, 28.
    let slot: Int
    let result: FaceScanResult
}

enum FaceScanError: LocalizedError {
    case noFace, unavailable, unreadable
    /// Server daily quota (3 face checks per account per UTC day).
    case quotaReached
    var errorDescription: String? {
        let key: String
        switch self {
        case .noFace: key = "calm.face.error.no_face"
        case .unavailable: key = "calm.face.error.unavailable"
        case .quotaReached: key = "assistant.quota.reached"
        case .unreadable: key = "milo.import.error.unreadable"
        }
        return LanguageManager.shared.localizedString(for: key)
    }
}

/// Explicit consent to send the selfie to OpenAI (per account, same storage format as `MiloConsent`).
enum FaceScanConsent {
    static let storageKey = "calm.face.consent.uids"
}

enum FaceScanAnalyzer {
    private struct Response: Decodable { let content: String }
    private struct Payload: Decodable {
        let face: Bool
        let rested_score: Int?
        let puffiness: String?
        let dark_circles: String?
        let jaw_tension: String?
        let skin_dullness: String?
        let summary: String?
        let tip: String?
    }

    @MainActor
    static func analyze(_ image: UIImage) async throws -> FaceScanResult {
        guard let jpeg = resized(image, maxSide: 768)?.jpegData(compressionQuality: 0.7) else { throw FaceScanError.unreadable }
        let code = LanguageManager.shared.currentLanguage.rawValue
        let language = Locale(identifier: "en").localizedString(forLanguageCode: code) ?? code

        let response: Response
        do {
            response = try await ConvexBackend.shared.call(
                .action, path: "faceScan:analyze",
                args: ["image": jpeg.base64EncodedString(), "language": language]
            )
        } catch ConvexBackendError.server(let message) where message == "quota_exceeded" {
            throw FaceScanError.quotaReached
        } catch {
            throw FaceScanError.unavailable
        }
        guard let data = response.content.data(using: .utf8),
              let payload = try? JSONDecoder().decode(Payload.self, from: data)
        else { throw FaceScanError.unavailable }
        guard payload.face, let score = payload.rested_score else { throw FaceScanError.noFace }

        func level(_ raw: String?) -> FaceScanResult.Level { FaceScanResult.Level(rawValue: raw ?? "") ?? .low }
        return FaceScanResult(
            restedScore: min(100, max(0, score)),
            puffiness: level(payload.puffiness),
            darkCircles: level(payload.dark_circles),
            jawTension: level(payload.jaw_tension),
            skinDullness: level(payload.skin_dullness),
            summary: String((payload.summary ?? "").prefix(300)),
            tip: String((payload.tip ?? "").prefix(200))
        )
    }

    private static func resized(_ image: UIImage, maxSide: CGFloat) -> UIImage? {
        let scale = min(1, maxSide / max(image.size.width, image.size.height))
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        return UIGraphicsImageRenderer(size: size).image { _ in image.draw(in: CGRect(origin: .zero, size: size)) }
    }
}

/// Weekly schedule and history (per account, on device).
@MainActor
final class FaceScanStore: ObservableObject {
    static let shared = FaceScanStore()
    static let slotDays = [1, 7, 14, 21, 28]

    @Published private(set) var records: [FaceScanRecord] = []
    private let defaults = UserDefaults.standard
    private var loadedUID: String?

    private init() { reload() }

    private var uid: String { UnifiedFirebaseService.shared.auth.currentUserId ?? "local" }
    private var key: String { "calm.face.records.\(uid)" }

    func reload() {
        guard loadedUID != uid else { return }
        loadedUID = uid
        records = defaults.data(forKey: key).flatMap { try? JSONDecoder().decode([FaceScanRecord].self, from: $0) } ?? []
    }

    /// Current plan cycle and day (1…28), or day 1 of cycle 1 without a plan.
    var planPosition: (cycle: Int, day: Int) {
        guard let plan = PersonalPlanStore.shared.plan else { return (1, 1) }
        return (plan.cycle, min(max(plan.dayIndex(), 1), PersonalPlan.length))
    }

    /// The week slot reached today (last of 1, 7, 14, 21, 28 that is ≤ today).
    var currentSlot: Int {
        let day = planPosition.day
        return Self.slotDays.lastIndex { $0 <= day } ?? 0
    }

    func record(cycle: Int, slot: Int) -> FaceScanRecord? {
        records.first { $0.cycle == cycle && $0.slot == slot }
    }

    /// True when this week's photo has not been taken yet.
    var isDue: Bool { record(cycle: planPosition.cycle, slot: currentSlot) == nil }

    var currentCycleRecords: [FaceScanRecord] {
        records.filter { $0.cycle == planPosition.cycle }.sorted { $0.slot < $1.slot }
    }

    /// Saves the photo with the progress photos and the analysis for this week (a retake replaces it).
    func save(image: UIImage, result: FaceScanResult) throws -> FaceScanRecord {
        guard let data = image.jpegData(compressionQuality: 0.85) else { throw FaceScanError.unreadable }
        let (cycle, _) = planPosition
        let slot = currentSlot
        if let previous = record(cycle: cycle, slot: slot),
           let photo = ProgressPhotoStore.shared.photos.first(where: { $0.id == previous.photoID }) {
            ProgressPhotoStore.shared.delete(photo)
        }
        let photo = try ProgressPhotoStore.shared.add(data: data)
        let record = FaceScanRecord(photoID: photo.id, date: Date(), cycle: cycle, slot: slot, result: result)
        records.removeAll { $0.cycle == cycle && $0.slot == slot }
        records.append(record)
        if let encoded = try? JSONEncoder().encode(records) { defaults.set(encoded, forKey: key) }
        return record
    }

    func image(for record: FaceScanRecord) -> UIImage? {
        ProgressPhotoStore.shared.photos.first { $0.id == record.photoID }.flatMap(ProgressPhotoStore.shared.image(for:))
    }

    var contextLine: String? {
        guard let last = records.max(by: { $0.date < $1.date }) else { return nil }
        return "Latest weekly face check (\(last.date.formatted(date: .abbreviated, time: .omitted))): looks \(last.result.restedScore)/100 rested; puffiness \(last.result.puffiness.rawValue), dark circles \(last.result.darkCircles.rawValue), jaw tension \(last.result.jawTension.rawValue). Wellness observation only, never a cortisol measure."
    }
}
