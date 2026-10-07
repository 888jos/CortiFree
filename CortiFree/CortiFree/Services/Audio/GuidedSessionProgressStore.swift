//
//  GuidedSessionProgressStore.swift
//  CortiFree
//
//  Local persistence for guided audio sessions: resume positions, completions,
//  recently played and mixer preferences.
//

import Foundation

enum GuidedSessionProgressStore {
    private static let defaults = UserDefaults.standard
    private static let resumeKey = "guidedSession.resumePositions"
    private static let completedKey = "guidedSession.completionCounts"
    private static let recentKey = "guidedSession.recent"
    private static let ambienceVolumeKey = "guidedSession.ambienceVolume"
    private static let voiceVolumeKey = "guidedSession.voiceVolume"
    private static let ambienceChoiceKey = "guidedSession.ambienceChoice"

    // MARK: Resume

    static func resumePosition(for id: String) -> TimeInterval {
        (defaults.dictionary(forKey: resumeKey)?[id] as? Double) ?? 0
    }

    static func saveResumePosition(_ seconds: TimeInterval, for id: String) {
        var map = defaults.dictionary(forKey: resumeKey) ?? [:]
        if seconds < 5 {
            map.removeValue(forKey: id)
        } else {
            map[id] = seconds
        }
        defaults.set(map, forKey: resumeKey)
    }

    static func clearResumePosition(for id: String) {
        saveResumePosition(0, for: id)
    }

    // MARK: Completion

    static func completionCount(for id: String) -> Int {
        (defaults.dictionary(forKey: completedKey)?[id] as? Int) ?? 0
    }

    static func isCompleted(_ id: String) -> Bool { completionCount(for: id) > 0 }

    static func markCompleted(_ id: String) {
        var map = defaults.dictionary(forKey: completedKey) ?? [:]
        map[id] = ((map[id] as? Int) ?? 0) + 1
        defaults.set(map, forKey: completedKey)
    }

    // MARK: Recent

    static var recentSessionIDs: [String] {
        defaults.stringArray(forKey: recentKey) ?? []
    }

    static func markPlayed(_ id: String) {
        var list = recentSessionIDs.filter { $0 != id }
        list.insert(id, at: 0)
        defaults.set(Array(list.prefix(12)), forKey: recentKey)
    }

    // MARK: Mixer preferences

    static var ambienceVolume: Float {
        get { defaults.object(forKey: ambienceVolumeKey) as? Float ?? 0.35 }
        set { defaults.set(newValue, forKey: ambienceVolumeKey) }
    }

    static var voiceVolume: Float {
        get { defaults.object(forKey: voiceVolumeKey) as? Float ?? 1.0 }
        set { defaults.set(newValue, forKey: voiceVolumeKey) }
    }

    /// Per-session ambience override. `""` means "no ambience", nil means "use default".
    static func ambienceChoice(for id: String) -> String? {
        defaults.dictionary(forKey: ambienceChoiceKey)?[id] as? String
    }

    static func saveAmbienceChoice(_ value: String, for id: String) {
        var map = defaults.dictionary(forKey: ambienceChoiceKey) ?? [:]
        map[id] = value
        defaults.set(map, forKey: ambienceChoiceKey)
    }
}
