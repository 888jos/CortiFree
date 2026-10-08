//
//  SoundPlayer.swift
//  CortiFree
//
//  Created by Claude on 22/10/2025.
//

import Foundation
import AVFoundation
import MediaPlayer
import UIKit

class SoundPlayer: ObservableObject {
    static let shared = SoundPlayer()

    @Published var isPlaying: Bool = false
    @Published var currentExercise: Exercise?
    @Published var progress: Double = 0.0
    @Published var currentTime: TimeInterval = 0
    @Published var totalPlayTime: TimeInterval = 0  // Durée totale de lecture
    @Published var selectedDuration: TimeInterval? = nil  // Durée sélectionnée par l'utilisateur (nil = infini)

    private var audioPlayer: AVAudioPlayer?
    private var timer: Timer?
    private var playStartTime: Date?  // Pour tracker le temps de lecture
    private var accumulatedPlayTime: TimeInterval = 0  // Temps accumulé avant la pause

    private init() {
        AudioFocus.configureAtLaunch()
        setupRemoteTransportControls()
        setupNotifications()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(refreshLocalizedExercise),
            name: LanguageManager.languageDidChangeNotification,
            object: nil
        )
    }

    @objc private func refreshLocalizedExercise() {
        guard let currentExercise,
              let localizedExercise = Exercise.sounds.first(where: { $0.id == currentExercise.id }) else {
            return
        }

        self.currentExercise = localizedExercise
        updateNowPlayingInfo()
    }

    // MARK: - Audio Session

    // SoundPlayer.shared is created at launch (ContentView): only configure the session
    // there. The focus is taken in play()/resume() so opening the app never stops the
    // user's music (see AudioFocus).

    // MARK: - Remote Controls (Control Center)

    private func setupRemoteTransportControls() {
        let commandCenter = MPRemoteCommandCenter.shared()

        // GuidedSessionPlayer registers its own targets: each player only reacts
        // when it owns the current playback.
        commandCenter.playCommand.addTarget { [weak self] _ in
            guard let self, self.currentExercise != nil else { return .noActionableNowPlayingItem }
            self.resume()
            return .success
        }
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            guard let self, self.currentExercise != nil else { return .noActionableNowPlayingItem }
            self.pause()
            return .success
        }
        commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            guard let self, self.currentExercise != nil else { return .noActionableNowPlayingItem }
            if self.isPlaying { self.pause() } else { self.resume() }
            return .success
        }
        commandCenter.stopCommand.addTarget { [weak self] _ in
            guard let self, self.currentExercise != nil else { return .noActionableNowPlayingItem }
            self.stop()
            return .success
        }
    }

    private func updateNowPlayingInfo() {
        // Nothing to publish (the guided session player may own Now Playing).
        guard let exercise = currentExercise else { return }

        var info: [String: Any] = [
            MPMediaItemPropertyTitle: exercise.title,
            MPMediaItemPropertyArtist: "CortiFree",
            MPNowPlayingInfoPropertyIsLiveStream: true,  // loop infini = live stream
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: totalPlayTime
        ]

        // Artwork — the ambient sound photo (falls back to the app icon)
        if let image = UIImage(named: exercise.soundImageName) ?? UIImage(named: "AppIcon") ?? UIImage(named: "AppIcon60x60") {
            info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
        }

        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    // MARK: - Notifications

    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAudioInterruption),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRouteChange),
            name: AVAudioSession.routeChangeNotification,
            object: nil
        )
    }

    @objc private func handleAudioInterruption(_ notification: Notification) {
        guard currentExercise != nil, let info = notification.userInfo,
              let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }

        switch type {
        case .began:
            // Interruption (appel, Siri…) — mettre en pause proprement
            if isPlaying {
                audioPlayer?.pause()
                isPlaying = false
                if let startTime = playStartTime {
                    accumulatedPlayTime += Date().timeIntervalSince(startTime)
                    totalPlayTime = accumulatedPlayTime
                }
                playStartTime = nil
                stopTimer()
                updateNowPlayingInfo()
            }

        case .ended:
            // Reprendre si iOS le suggère
            let optionsValue = info[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            if options.contains(.shouldResume) {
                resume()
            }

        @unknown default:
            break
        }
    }

    @objc private func handleRouteChange(_ notification: Notification) {
        guard currentExercise != nil, let info = notification.userInfo,
              let reasonValue = info[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else { return }

        // Pause si les écouteurs sont débranchés (comportement standard iOS)
        if reason == .oldDeviceUnavailable {
            DispatchQueue.main.async { [weak self] in
                guard let self, self.currentExercise != nil, self.isPlaying else { return }
                self.pause()
            }
        }
    }

    // MARK: - Playback

    func play(exercise: Exercise) {
        // If same exercise is playing, just toggle pause
        if currentExercise?.id == exercise.id, audioPlayer != nil {
            if isPlaying {
                pause()
            } else {
                resume()
            }
            return
        }

        // Stop current if playing (keeping the audio focus: taken again just below, so
        // the user's other app is not told to resume in between).
        stop(releasingFocus: false)
        AudioFocus.acquire(.ambientSound)

        // Only one thing plays at a time: stop any guided audio session.
        stopGuidedSession()

        currentExercise = exercise

        guard let audioFileName = exercise.audioFileName else {
            AudioFocus.release(.ambientSound)
            print("No audio file for this exercise")
            return
        }

        // Load audio file (try m4a first, then mp3 as fallback)
        let baseName = audioFileName
            .replacingOccurrences(of: ".mp3", with: "")
            .replacingOccurrences(of: ".m4a", with: "")
        guard let url = Bundle.main.url(forResource: baseName, withExtension: "m4a")
                ?? Bundle.main.url(forResource: baseName, withExtension: "mp3") else {
            AudioFocus.release(.ambientSound)
            print("Audio file not found: \(audioFileName)")
            return
        }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.numberOfLoops = -1 // Loop indefinitely
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()

            isPlaying = true
            UIApplication.shared.isIdleTimerDisabled = true
            playStartTime = Date()
            accumulatedPlayTime = 0
            totalPlayTime = 0
            startTimer()
            updateNowPlayingInfo()
            triggerHaptic(.light)
        } catch {
            AudioFocus.release(.ambientSound)
            print("Failed to play audio: \(error.localizedDescription)")
        }
    }

    func pause() {
        guard currentExercise != nil else { return }
        audioPlayer?.pause()
        isPlaying = false
        UIApplication.shared.isIdleTimerDisabled = false

        // Accumuler le temps écoulé
        if let startTime = playStartTime {
            accumulatedPlayTime += Date().timeIntervalSince(startTime)
            totalPlayTime = accumulatedPlayTime
        }
        playStartTime = nil

        stopTimer()
        updateNowPlayingInfo()
        triggerHaptic(.light)
    }

    func resume() {
        guard currentExercise != nil, audioPlayer != nil else { return }
        AudioFocus.acquire(.ambientSound)

        audioPlayer?.play()
        isPlaying = true
        UIApplication.shared.isIdleTimerDisabled = true
        playStartTime = Date()
        startTimer()
        updateNowPlayingInfo()
        triggerHaptic(.light)
    }

    func stop() {
        stop(releasingFocus: true)
    }

    private func stop(releasingFocus: Bool) {
        let finishedExercise = currentExercise
        let finishedDuration = Int(totalPlayTime.rounded())

        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        UIApplication.shared.isIdleTimerDisabled = false
        currentExercise = nil
        progress = 0.0
        currentTime = 0
        totalPlayTime = 0
        accumulatedPlayTime = 0
        playStartTime = nil
        selectedDuration = nil
        stopTimer()
        if releasingFocus { AudioFocus.release(.ambientSound) }

        if let finishedExercise {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            let category = progressCategory(for: finishedExercise.type)
            Task { @MainActor in
                ExerciseSessionRecorder.shared.record(
                    exerciseID: finishedExercise.id,
                    category: category,
                    durationSeconds: finishedDuration,
                    source: "sound_player"
                )
            }
        }
    }

    private func progressCategory(for type: ExerciseType) -> ProgressActivityCategory {
        switch type {
        case .breathing: return .breathing
        case .meditation: return .meditation
        case .sound: return .sounds
        }
    }

    private func stopGuidedSession() {
        if Thread.isMainThread {
            MainActor.assumeIsolated {
                if GuidedSessionPlayer.shared.isActive { GuidedSessionPlayer.shared.stop() }
            }
        } else {
            DispatchQueue.main.sync {
                MainActor.assumeIsolated {
                    if GuidedSessionPlayer.shared.isActive { GuidedSessionPlayer.shared.stop() }
                }
            }
        }
    }

    // MARK: - Timer

    private func startTimer() {
        // RunLoop.common = fonctionne aussi en background et quand l'UI scroll
        timer = Timer(timeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let player = self.audioPlayer else { return }

            self.currentTime = player.currentTime

            if player.duration > 0 {
                self.progress = player.currentTime / player.duration
            }

            if let startTime = self.playStartTime {
                self.totalPlayTime = self.accumulatedPlayTime + Date().timeIntervalSince(startTime)
            }

            // Vérifier si la durée sélectionnée est atteinte
            if let duration = self.selectedDuration, self.totalPlayTime >= duration {
                self.stop()
            }
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }

    // Formater le temps en HH:MM:SS ou MM:SS
    func formattedTotalTime() -> String {
        let hours = Int(totalPlayTime) / 3600
        let minutes = Int(totalPlayTime) / 60 % 60
        let seconds = Int(totalPlayTime) % 60

        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }

    deinit {
        stop()
    }
}
