//
//  SessionRatingStore.swift
//  CortiFree
//
//  0–5 rating given at the end of a meditation, breathing exercise or exercise.
//  Every rating is sent to Amplitude (`session_rated`, averaged in the local analytics
//  dashboard) and kept on the device to recommend liked sessions more and disliked
//  ones less (`preferenceScore`).
//

import Foundation

enum RatedContentType: String, Codable {
    case meditation, breathing, exercise, routine
}

struct RatedContent: Equatable {
    let type: RatedContentType
    /// Stable identifier (session id, breathing pattern, exercise type…).
    let id: String
    let title: String

    var key: String { "\(type.rawValue):\(id)" }
}

enum SessionRatingStore {
    static let range = 0...5
    /// Below this average a session is pushed to the end of recommendations.
    static let dislikedBelow = 2.0

    private static let storageKey = "cortifree.sessionRatings.v1"
    /// Only the most recent ratings count, so a changed opinion wins quickly.
    private static let keptPerContent = 5

    static func record(_ rating: Int, for content: RatedContent, durationSeconds: Int? = nil) {
        let rating = min(max(rating, range.lowerBound), range.upperBound)
        var all = load()
        var ratings = all[content.key, default: []]
        ratings.append(rating)
        all[content.key] = Array(ratings.suffix(keptPerContent))
        save(all)

        var properties: [String: Any] = [
            "content_type": content.type.rawValue,
            "content_id": content.id,
            "content_key": content.key,
            "content_title": content.title,
            "rating": rating,
        ]
        if let durationSeconds { properties["duration_seconds"] = durationSeconds }
        AnalyticsManager.shared.track(event: "session_rated", properties: properties)
    }

    /// Average of the recent ratings, nil when the user never rated this content.
    static func averageRating(for type: RatedContentType, id: String) -> Double? {
        let ratings = load()["\(type.rawValue):\(id)"] ?? []
        guard !ratings.isEmpty else { return nil }
        return Double(ratings.reduce(0, +)) / Double(ratings.count)
    }

    /// Recommendation weight: the average rating, a neutral 3 for unrated content.
    static func preferenceScore(for type: RatedContentType, id: String) -> Double {
        averageRating(for: type, id: id) ?? 3
    }

    static func isDisliked(_ type: RatedContentType, id: String) -> Bool {
        (averageRating(for: type, id: id) ?? 3) < dislikedBelow
    }

    static func clear() { UserDefaults.standard.removeObject(forKey: storageKey) }

    private static func load() -> [String: [Int]] {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([String: [Int]].self, from: data) else { return [:] }
        return decoded
    }

    private static func save(_ ratings: [String: [Int]]) {
        if let data = try? JSONEncoder().encode(ratings) { UserDefaults.standard.set(data, forKey: storageKey) }
    }
}
