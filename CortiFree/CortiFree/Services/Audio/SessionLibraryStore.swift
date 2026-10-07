//
//  SessionLibraryStore.swift
//  CortiFree
//
//  The user's personal libraries shown by the three Library header buttons:
//  recently played, ready offline ("downloads") and favourites.
//

import Foundation
import Combine

/// One of the user's personal session lists.
enum SessionLibrary: String, Identifiable, Hashable, CaseIterable {
    case recent
    case downloads
    case favorites

    var id: String { rawValue }

    var titleKey: String { "library.collection.\(rawValue)" }
    var emptyKey: String { "library.collection.\(rawValue).empty" }

    var symbol: String {
        switch self {
        case .recent: return "clock.arrow.circlepath"
        case .downloads: return "arrow.down.circle.fill"
        case .favorites: return "heart.fill"
        }
    }
}

@MainActor
final class SessionLibraryStore: ObservableObject {
    static let shared = SessionLibraryStore()

    @Published private(set) var favorites: Set<String>
    @Published private(set) var preparingIDs: Set<String> = []

    private let defaults = UserDefaults.standard
    private let favoritesKey = "guidedSession.favorites.v1"

    private init() {
        favorites = Set(defaults.stringArray(forKey: favoritesKey) ?? [])
    }

    // MARK: Favourites

    func isFavorite(_ session: GuidedSession) -> Bool { favorites.contains(session.id) }

    func toggleFavorite(_ session: GuidedSession) {
        if favorites.contains(session.id) {
            favorites.remove(session.id)
        } else {
            favorites.insert(session.id)
            AnalyticsManager.shared.track(event: "audio_session_favorited", properties: ["session_id": session.id])
        }
        defaults.set(Array(favorites), forKey: favoritesKey)
    }

    // MARK: Downloads (audio ready on the device)

    /// A session is "downloaded" when a recorded file is bundled or its narration is already rendered.
    func isDownloaded(_ session: GuidedSession) -> Bool {
        if let url = session.recordedAudioURL(), url.isFileURL { return true }
        guard let script = NarrationLibrary.shared.script(for: session.id, language: GuidedSession.narrationLanguage()) else {
            return false
        }
        return NarrationRenderer.shared.cachedFile(for: script, targetDuration: TimeInterval(session.durationMinutes * 60)) != nil
    }

    /// Renders the narration ahead of time so the session starts instantly and works offline.
    func download(_ session: GuidedSession) {
        guard !preparingIDs.contains(session.id), !isDownloaded(session),
              let script = NarrationLibrary.shared.script(for: session.id, language: GuidedSession.narrationLanguage()) else { return }
        preparingIDs.insert(session.id)
        Task {
            _ = try? await NarrationRenderer.shared.render(script, targetDuration: TimeInterval(session.durationMinutes * 60)) { _ in }
            preparingIDs.remove(session.id)
            objectWillChange.send()
        }
    }

    // MARK: Lists

    func sessions(in library: SessionLibrary) -> [GuidedSession] {
        switch library {
        case .recent:
            return GuidedSessionProgressStore.recentSessionIDs.compactMap(GuidedSessionCatalog.session(id:))
        case .downloads:
            return GuidedSessionCatalog.all.filter(isDownloaded)
        case .favorites:
            return GuidedSessionCatalog.all.filter { favorites.contains($0.id) }
        }
    }
}
