//
//  MiloRecommendationHistory.swift
//  CortiFree
//
//  Milo's exercise cards used to rotate on a counter: always the same 3 shortest sessions of a
//  category and, at night, always the same breathing exercise. Now every candidate list is
//  ordered by how well it fits (done in AssistantChatView) and Milo proposes the first one he
//  has not proposed recently, so the whole list is used before anything comes back.
//

import Foundation

enum MiloRecommendationHistory {
    /// How many proposals are remembered. Below the size of the smallest candidate lists
    /// (breathing ≈ 9, sessions ≈ 10 per category); a shorter list just comes back around sooner.
    static let limit = 8

    /// The first item (the best fit) not proposed recently. When everything was proposed recently,
    /// the one proposed the longest ago.
    static func freshest<T>(_ items: [T], recent: [String], id: (T) -> String) -> T? {
        if let fresh = items.first(where: { !recent.contains(id($0)) }) { return fresh }
        return items.min { (recent.firstIndex(of: id($0)) ?? -1) < (recent.firstIndex(of: id($1)) ?? -1) }
    }

    /// `recent` (oldest first) with `id` as the newest entry.
    static func remembering(_ id: String, in recent: [String]) -> [String] {
        Array((recent.filter { $0 != id } + [id]).suffix(limit))
    }

    static func decode(_ stored: String) -> [String] { stored.split(separator: ",").map(String.init) }
    static func encode(_ recent: [String]) -> String { recent.joined(separator: ",") }
}
