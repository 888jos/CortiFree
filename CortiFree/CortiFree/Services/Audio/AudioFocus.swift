//
//  AudioFocus.swift
//  CortiFree
//
//  Single owner of the shared AVAudioSession.
//
//  At launch the session is only configured as `.ambient` (never activated), so opening
//  the app does not stop the user's music (Spotify, Apple Music, podcasts…).
//  A player takes the audio focus only when it actually starts playing, and gives it back
//  when it stops: the session is then deactivated with `.notifyOthersOnDeactivation`
//  so the other app can resume.
//

import AVFoundation

enum AudioFocus {
    enum Owner: String {
        /// Guided sessions: interrupts other audio (own ambience, lock-screen controls).
        case guidedSession
        /// Ambient sound loops: interrupts other audio (lock-screen controls).
        case ambientSound
        /// Ambience loop under a breathing exercise: mixes with the user's music.
        case breathingAmbience
        /// Spoken breathing cues: lowers the user's music while speaking.
        case voiceCues
        /// Milo voice dictation: records the mic, lowers whatever is playing.
        case dictation
    }

    private static var holders: Set<Owner> = []
    private static let lock = NSLock()

    /// Called once at launch. Configures without activating, so other apps keep playing.
    static func configureAtLaunch() {
        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers])
    }

    /// Takes the audio focus for `owner` (sets the category matching the strongest holder).
    static func acquire(_ owner: Owner) {
        lock.lock()
        holders.insert(owner)
        let current = holders
        lock.unlock()
        apply(current, activate: true)
    }

    /// Gives the focus back. The session is deactivated once nobody holds it anymore.
    static func release(_ owner: Owner) {
        lock.lock()
        let removed = holders.remove(owner) != nil
        let current = holders
        lock.unlock()
        guard removed else { return }

        if current.isEmpty {
            let session = AVAudioSession.sharedInstance()
            do {
                try session.setActive(false, options: [.notifyOthersOnDeactivation])
            } catch {
                #if DEBUG
                print("AudioFocus deactivate error: \(error.localizedDescription)")
                #endif
            }
            try? session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
        } else {
            apply(current, activate: false)
        }
    }

    private static func apply(_ holders: Set<Owner>, activate: Bool) {
        let session = AVAudioSession.sharedInstance()
        var category: AVAudioSession.Category = .playback
        let mode: AVAudioSession.Mode
        let options: AVAudioSession.CategoryOptions
        if holders.contains(.dictation) {
            category = .playAndRecord
            mode = .default
            options = [.duckOthers, .defaultToSpeaker]
        } else if holders.contains(.guidedSession) {
            mode = .spokenAudio
            options = []
        } else if holders.contains(.ambientSound) {
            mode = .default
            options = []
        } else if holders.contains(.voiceCues) {
            mode = .spokenAudio
            options = [.mixWithOthers, .duckOthers]
        } else {
            mode = .default
            options = [.mixWithOthers]
        }
        do {
            if session.category != category || session.mode != mode || session.categoryOptions != options {
                try session.setCategory(category, mode: mode, options: options)
            }
            if activate { try session.setActive(true) }
        } catch {
            #if DEBUG
            print("AudioFocus error: \(error.localizedDescription)")
            #endif
        }
    }
}
