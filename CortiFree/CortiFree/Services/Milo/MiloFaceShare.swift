//
//  MiloFaceShare.swift
//  CortiFree
//
//  « En parler avec Milo » on a face check result: Milo opens a new conversation with the
//  analysis (score and signs as the user's message, Milo's read and tip as its reply) and an
//  anti-stress exercise chosen from the signs. The user can then keep talking about it.
//

import Foundation

@MainActor
final class MiloFaceShare {
    static let shared = MiloFaceShare()

    /// Result to discuss, consumed by AssistantChatView when it appears.
    private var pending: FaceScanRecord?

    private init() {}

    /// Opens Milo with this result. Call after dismissing the face check screen: Milo is
    /// presented by the root view once the covers above it are gone.
    func share(_ record: FaceScanRecord, source: String) {
        pending = record
        AnalyticsManager.shared.track(event: "milo_face_shared", properties: [
            "source": source,
            "week": record.slot + 1,
            "rested_score": record.result.restedScore
        ])
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            NotificationRouter.shared.pendingAppLink = URL(string: "cortifree://milo")
        }
    }

    func consume() -> FaceScanRecord? {
        defer { pending = nil }
        return pending
    }

    /// The user's side of the conversation: week, score and signs, in the app language.
    static func userMessage(for record: FaceScanRecord) -> String {
        let t = LanguageManager.shared.localizedString(for:)
        let result = record.result
        let signs: [(String, FaceScanResult.Level)] = [
            ("calm.face.sign.puffiness", result.puffiness),
            ("calm.face.sign.dark_circles", result.darkCircles),
            ("calm.face.sign.jaw", result.jawTension),
            ("calm.face.sign.skin", result.skinDullness)
        ]
        let lines = signs.map { "\(t($0.0)): \(t("calm.face.level.\($0.1.rawValue)"))" }
        return [
            String(format: t("calm.face.title"), record.slot + 1),
            "\(result.restedScore)/100 \(t("calm.face.result.rested"))",
            lines.joined(separator: " · ")
        ].joined(separator: "\n")
    }

    /// Milo's reply: its read of the photo and the tip of the day.
    static func reply(for record: FaceScanRecord) -> String {
        [record.result.summary, record.result.tip].filter { !$0.isEmpty }.joined(separator: "\n\n")
    }
}
