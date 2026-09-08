//
//  GlowScanStore.swift
//  CortiFree
//

import Foundation
import Combine

@MainActor
final class GlowScanStore: ObservableObject {
    static let shared = GlowScanStore()

    @Published private(set) var history: [GlowAnalysis] = []
    private let storageKey = "glow_scan_history"

    init() {
        load()
    }

    var latest: GlowAnalysis? { history.first }

    func save(_ analysis: GlowAnalysis) {
        history.insert(analysis, at: 0)
        history = Array(history.prefix(12))
        persist()
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let saved = try? JSONDecoder().decode([GlowAnalysis].self, from: data) else { return }
        history = saved.sorted { $0.createdAt > $1.createdAt }
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(history) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}
