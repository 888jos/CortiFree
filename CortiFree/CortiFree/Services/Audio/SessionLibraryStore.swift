//
//  SessionLibraryStore.swift
//  CortiFree
//
//  The user's personal libraries shown by the three Library header buttons:
//  recently played, downloads (meditations, breathing, sounds) and favourites.
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
    /// Items the user downloaded, as `session:<id>`, `breathing:<name>` or `sound:<id>`.
    @Published private(set) var downloads: Set<String>

    private let defaults = UserDefaults.standard
    private let favoritesKey = "guidedSession.favorites.v1"
    private let downloadsKey = "library.downloads.v1"

    private init() {
        favorites = Set(defaults.stringArray(forKey: favoritesKey) ?? [])
        downloads = Set(defaults.stringArray(forKey: downloadsKey) ?? [])
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

    /// Breathing favourites share the set, as `breathing:<name>`.
    func isFavorite(_ pattern: BreathingPattern) -> Bool { favorites.contains(Self.key(pattern)) }

    func toggleFavorite(_ pattern: BreathingPattern) {
        let key = Self.key(pattern)
        if favorites.contains(key) {
            favorites.remove(key)
        } else {
            favorites.insert(key)
            AnalyticsManager.shared.track(event: "breathing_favorited", properties: ["pattern": pattern.name])
        }
        defaults.set(Array(favorites), forKey: favoritesKey)
    }

    var favoriteBreathing: [BreathingPattern] {
        BreathingPattern.allPatterns.filter(isFavorite)
    }

    // MARK: Downloads

    /// What a download button shows.
    enum DownloadState { case none, downloading, downloaded }

    /// Audio is ready on the device: a bundled recording or an already rendered narration.
    func isAudioReady(_ session: GuidedSession) -> Bool {
        if let url = session.recordedAudioURL(), url.isFileURL { return true }
        guard let script = NarrationLibrary.shared.script(for: session.id, language: session.playbackLanguage) else {
            return false
        }
        return NarrationRenderer.shared.cachedFile(for: script, targetDuration: TimeInterval(session.durationMinutes * 60)) != nil
    }

    func isDownloaded(_ session: GuidedSession) -> Bool { downloads.contains(Self.key(session)) }

    func downloadState(_ session: GuidedSession) -> DownloadState {
        if preparingIDs.contains(session.id) { return .downloading }
        return isDownloaded(session) ? .downloaded : .none
    }

    /// Prepares the session's audio ahead of time so it starts instantly and works offline.
    func download(_ session: GuidedSession) {
        guard !preparingIDs.contains(session.id), !isDownloaded(session) else { return }
        AnalyticsManager.shared.track(event: "library_item_downloaded", properties: ["kind": "session", "id": session.id])
        guard !isAudioReady(session),
              let script = NarrationLibrary.shared.script(for: session.id, language: session.playbackLanguage) else {
            setRenderPinned(true, for: session)
            markDownloaded(Self.key(session))
            return
        }
        preparingIDs.insert(session.id)
        Task {
            // keepIfAbandoned: shares the player's render if it is already preparing this
            // session, and keeps going if the player is closed meanwhile.
            let file = try? await NarrationRenderer.shared.render(script, targetDuration: TimeInterval(session.durationMinutes * 60),
                                                                  keepIfAbandoned: true) { _ in }
            preparingIDs.remove(session.id)
            if file != nil {
                setRenderPinned(true, for: session)
                markDownloaded(Self.key(session))
            }
        }
    }

    /// A downloaded session's render is kept out of the renderer's storage cap.
    private func setRenderPinned(_ pinned: Bool, for session: GuidedSession) {
        guard let script = NarrationLibrary.shared.script(for: session.id, language: session.playbackLanguage) else { return }
        NarrationRenderer.shared.setPinned(pinned, script: script, targetDuration: TimeInterval(session.durationMinutes * 60))
    }

    /// Breathing exercises ship with the app: downloading only files them under Downloads.
    func isDownloaded(_ pattern: BreathingPattern) -> Bool { downloads.contains(Self.key(pattern)) }

    /// Sounds ship with the app: downloading only files them under Downloads.
    func isDownloaded(_ sound: Exercise) -> Bool { downloads.contains(Self.key(sound)) }

    func toggleDownload(_ session: GuidedSession) {
        if isDownloaded(session) {
            setRenderPinned(false, for: session)
            removeDownload(Self.key(session))
        } else {
            download(session)
        }
    }

    func toggleDownload(_ pattern: BreathingPattern) {
        let key = Self.key(pattern)
        if downloads.contains(key) { return removeDownload(key) }
        AnalyticsManager.shared.track(event: "library_item_downloaded", properties: ["kind": "breathing", "id": pattern.name])
        markDownloaded(key)
    }

    func toggleDownload(_ sound: Exercise) {
        let key = Self.key(sound)
        if downloads.contains(key) { return removeDownload(key) }
        AnalyticsManager.shared.track(event: "library_item_downloaded", properties: ["kind": "sound", "id": sound.id])
        markDownloaded(key)
    }

    var downloadedBreathing: [BreathingPattern] {
        BreathingPattern.allPatterns.filter(isDownloaded)
    }

    var downloadedSounds: [Exercise] {
        Exercise.sounds.filter(isDownloaded)
    }

    var hasDownloads: Bool { !downloads.isEmpty }

    private func markDownloaded(_ key: String) {
        downloads.insert(key)
        defaults.set(Array(downloads), forKey: downloadsKey)
    }

    private func removeDownload(_ key: String) {
        downloads.remove(key)
        defaults.set(Array(downloads), forKey: downloadsKey)
    }

    private static func key(_ session: GuidedSession) -> String { "session:\(session.id)" }
    private static func key(_ pattern: BreathingPattern) -> String { "breathing:\(pattern.name)" }
    private static func key(_ sound: Exercise) -> String { "sound:\(sound.id)" }

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
