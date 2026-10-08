//
//  GuidedSessionPlayer.swift
//  CortiFree
//
//  Single shared player for guided audio sessions (Spotify-like).
//  - Recorded audio (bundled / remote) → AVPlayer (streaming OK)
//  - Otherwise the narration script is rendered on-device (NarrationRenderer) into a
//    cached audio file, then played with AVPlayer → real seekable track with duration.
//  - Ambience loop mixed underneath with its own volume, faded out at the end.
//  - Lock screen / Control Center, interruptions, route changes, resume position,
//    completion (≥ 50% actually listened), sleep timer.
//

import AVFoundation
import Combine
import MediaPlayer
import SwiftUI
import UIKit

@MainActor
final class PlaybackClock: ObservableObject {
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var preparationProgress: Double = 0
}

enum SleepTimerOption: Hashable, Identifiable {
    case off
    case minutes(Int)
    case endOfSession

    var id: String {
        switch self {
        case .off: return "off"
        case .minutes(let m): return "m\(m)"
        case .endOfSession: return "end"
        }
    }

    static let allOptions: [SleepTimerOption] = [.off, .minutes(5), .minutes(10), .minutes(15), .minutes(30), .endOfSession]

    var label: String {
        switch self {
        case .off: return LanguageManager.shared.localizedString(for: "audio.sleep_timer.off")
        case .minutes(let m): return "\(m) min"
        case .endOfSession: return LanguageManager.shared.localizedString(for: "audio.sleep_timer.end_of_session")
        }
    }
}

@MainActor
final class GuidedSessionPlayer: ObservableObject {
    static let shared = GuidedSessionPlayer()

    enum Phase: Equatable {
        case idle
        case preparing
        case ready
        case failed(String)
    }

    // MARK: Published state

    @Published private(set) var currentSession: GuidedSession?
    @Published private(set) var phase: Phase = .idle
    @Published private(set) var isPlaying = false

    /// Fast-changing values live in `clock` so that views which only need the session /
    /// play state (ContentView, Library) are not re-rendered twice per second.
    let clock = PlaybackClock()

    private(set) var currentTime: TimeInterval {
        get { clock.currentTime }
        set { clock.currentTime = newValue }
    }

    private(set) var duration: TimeInterval {
        get { clock.duration }
        set { clock.duration = newValue }
    }

    private(set) var preparationProgress: Double {
        get { clock.preparationProgress }
        set { clock.preparationProgress = newValue }
    }
    @Published private(set) var didFinish = false
    @Published private(set) var script: NarrationScript?
    @Published private(set) var usesSynthesizedVoice = false
    @Published private(set) var ambience: AudioAmbience?
    @Published private(set) var sleepTimer: SleepTimerOption = .off
    @Published private(set) var sleepTimerRemaining: TimeInterval?

    /// Global full-screen player (hosted by ContentView). Only set from non-modal contexts.
    @Published var isFullPlayerPresented = false

    @Published var ambienceVolume: Float = GuidedSessionProgressStore.ambienceVolume {
        didSet {
            GuidedSessionProgressStore.ambienceVolume = ambienceVolume
            if !isAmbienceFadingOut { ambiencePlayer?.volume = ambienceVolume }
        }
    }

    @Published var voiceVolume: Float = GuidedSessionProgressStore.voiceVolume {
        didSet {
            GuidedSessionProgressStore.voiceVolume = voiceVolume
            player?.volume = voiceVolume
        }
    }

    var progress: Double {
        guard duration > 0 else { return 0 }
        return min(1, max(0, currentTime / duration))
    }

    var isActive: Bool { currentSession != nil }
    var isPreparing: Bool { phase == .preparing }

    /// Target duration while the real one is unknown.
    var displayDuration: TimeInterval {
        if duration > 0 { return duration }
        return TimeInterval((currentSession?.durationMinutes ?? 0) * 60)
    }

    // MARK: Private

    private var player: AVPlayer?
    private var timeObserver: Any?
    private var endObserver: NSObjectProtocol?
    private var itemStatusObserver: NSKeyValueObservation?
    private var loadTask: Task<Void, Never>?
    private var ambiencePlayer: AVAudioPlayer?
    private var isAmbienceFadingOut = false
    private var wantsPlayback = true
    private var wasInterrupted = false

    private var listenedSeconds: TimeInterval = 0
    private var lastTickTime: TimeInterval?
    private var completionRecorded = false
    /// False when the plan credits the session itself on finish (avoids a double count in Progress).
    private var recordsSession = true
    private var lastResumeSave = Date.distantPast

    private var sleepTimerTask: Task<Void, Never>?
    private var nowPlayingArtwork: MPMediaItemArtwork?
    private var cancellables = Set<AnyCancellable>()

    private init() {
        setupRemoteCommands()
        setupNotifications()
    }

    // MARK: - Public API

    /// Starts (or resumes) a session. Stops any ambient sound playing in `SoundPlayer`.
    func play(_ session: GuidedSession, presentFullPlayer: Bool = false, recordsSession: Bool = true) {
        if presentFullPlayer { isFullPlayerPresented = true }
        self.recordsSession = recordsSession

        if currentSession?.id == session.id, phase != .idle {
            if case .failed = phase {
                // Retry below.
            } else {
                if !isPlaying { resume() }
                return
            }
        }

        // Take the focus first so stopping the previous playback doesn't hand it back
        // to the user's music app for a split second.
        AudioFocus.acquire(.guidedSession)
        stop(keepPresentation: true, releasingFocus: false)
        if SoundPlayer.shared.currentExercise != nil { SoundPlayer.shared.stop() }

        currentSession = session
        phase = .preparing
        preparationProgress = 0
        didFinish = false
        currentTime = 0
        duration = 0
        listenedSeconds = 0
        lastTickTime = nil
        completionRecorded = false
        wantsPlayback = true
        nowPlayingArtwork = makeArtwork(for: session)

        script = NarrationLibrary.shared.script(for: session.id, language: session.playbackLanguage)

        startAmbience(resolvedAmbience(for: session))
        GuidedSessionProgressStore.markPlayed(session.id)
        setSkipCommandsEnabled(true)
        updateNowPlaying()

        AnalyticsManager.shared.track(event: "audio_session_started", properties: [
            "session_id": session.id,
            "category": session.category.rawValue,
            "language": LanguageManager.shared.currentLanguage.rawValue
        ])

        loadTask = Task { [weak self] in
            await self?.loadAudio(for: session)
        }
    }

    func togglePlayPause() {
        isPlaying || (isPreparing && wantsPlayback) ? pause() : resume()
    }

    func pause() {
        guard currentSession != nil else { return }
        wantsPlayback = false
        player?.pause()
        ambiencePlayer?.pause()
        isPlaying = false
        saveResumePosition(force: true)
        UIApplication.shared.isIdleTimerDisabled = false
        updateNowPlaying()
    }

    func resume() {
        guard let session = currentSession else { return }
        if case .failed = phase {
            play(session)
            return
        }
        wantsPlayback = true
        AudioFocus.acquire(.guidedSession)

        if didFinish {
            didFinish = false
            listenedSeconds = 0
            completionRecorded = false
            seek(to: 0)
            restoreAmbienceVolume()
            if ambiencePlayer == nil { startAmbience(ambience) }
        }

        ambiencePlayer?.play()
        guard phase == .ready, let player else { return }
        player.play()
        player.volume = voiceVolume
        isPlaying = true
        UIApplication.shared.isIdleTimerDisabled = true
        updateNowPlaying()
    }

    func seek(to seconds: TimeInterval) {
        guard let player else { return }
        let clamped = max(0, min(seconds, max(0, displayDuration - 0.5)))
        currentTime = clamped
        lastTickTime = nil // don't count jumps as listened time
        player.seek(to: CMTime(seconds: clamped, preferredTimescale: 600), toleranceBefore: .zero, toleranceAfter: .zero)
        if duration > 0, clamped < duration - 10 { restoreAmbienceVolume() }
        if didFinish, clamped < duration - 1 { didFinish = false }
        updateNowPlaying()
    }

    func skip(by delta: TimeInterval) {
        seek(to: currentTime + delta)
    }

    /// Stops and unloads the session (mini player disappears).
    func stop() {
        stop(keepPresentation: false, releasingFocus: true)
    }

    func setAmbience(_ newAmbience: AudioAmbience?) {
        guard let session = currentSession else { return }
        GuidedSessionProgressStore.saveAmbienceChoice(newAmbience?.rawValue ?? "", for: session.id)
        startAmbience(newAmbience)
        if !(isPlaying || (isPreparing && wantsPlayback)) { ambiencePlayer?.pause() }
    }

    func setSleepTimer(_ option: SleepTimerOption) {
        sleepTimerTask?.cancel()
        sleepTimerTask = nil
        sleepTimer = option
        sleepTimerRemaining = nil

        guard case .minutes(let minutes) = option else { return }
        let end = Date().addingTimeInterval(TimeInterval(minutes * 60))
        sleepTimerRemaining = TimeInterval(minutes * 60)
        sleepTimerTask = Task { [weak self] in
            while !Task.isCancelled {
                let remaining = end.timeIntervalSinceNow
                await MainActor.run { self?.sleepTimerRemaining = max(0, remaining) }
                if remaining <= 0 { break }
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
            guard !Task.isCancelled else { return }
            await self?.sleepTimerFired()
        }
    }

    func resolvedAmbience(for session: GuidedSession) -> AudioAmbience? {
        if let choice = GuidedSessionProgressStore.ambienceChoice(for: session.id) {
            return AudioAmbience(rawValue: choice)
        }
        return session.defaultAmbience
    }

    // MARK: - Loading

    private func loadAudio(for session: GuidedSession, isRetry: Bool = false) async {
        let url: URL
        if let recorded = session.recordedAudioURL() {
            usesSynthesizedVoice = false
            url = recorded
        } else if let script {
            usesSynthesizedVoice = true
            do {
                url = try await NarrationRenderer.shared.render(
                    script,
                    targetDuration: TimeInterval(session.durationMinutes * 60)
                ) { [weak self] value in
                    Task { @MainActor in
                        guard self?.currentSession?.id == session.id else { return }
                        self?.preparationProgress = value
                    }
                }
            } catch {
                // Our own cancellation (stop / another session): nothing to report.
                if Task.isCancelled { return }
                guard currentSession?.id == session.id else { return }
                failPreparation(error.localizedDescription)
                return
            }
        } else {
            failPreparation(LanguageManager.shared.localizedString(for: "audio.error.unavailable"))
            return
        }

        guard !Task.isCancelled, currentSession?.id == session.id else { return }

        // A truncated / corrupt render would "play" as pure silence: check it first,
        // drop it and render again once.
        if url.isFileURL {
            let asset = AVURLAsset(url: url)
            let playable = (try? await asset.load(.isPlayable)) ?? false
            let length = (try? await asset.load(.duration))?.seconds ?? 0
            guard !Task.isCancelled, currentSession?.id == session.id else { return }
            if !playable || !(length > 1) {
                if usesSynthesizedVoice, !isRetry {
                    NarrationRenderer.shared.discard(url)
                    await loadAudio(for: session, isRetry: true)
                } else {
                    failPreparation(LanguageManager.shared.localizedString(for: "audio.error.unavailable"))
                }
                return
            }
        }
        await preparePlayer(url: url, session: session)
    }

    private func failPreparation(_ message: String) {
        phase = .failed(message)
        ambiencePlayer?.pause()
        AudioFocus.release(.guidedSession)
    }

    private func preparePlayer(url: URL, session: GuidedSession) async {
        let item = AVPlayerItem(url: url)
        item.audioTimePitchAlgorithm = .timeDomain
        let newPlayer = AVPlayer(playerItem: item)
        newPlayer.volume = voiceVolume
        newPlayer.automaticallyWaitsToMinimizeStalling = true
        player = newPlayer

        if let loaded = try? await item.asset.load(.duration), loaded.isNumeric {
            duration = loaded.seconds
        }
        guard currentSession?.id == session.id, player === newPlayer else { return }

        // Playback errors after start (stream lost, unreadable file): report instead of
        // leaving the user in front of a "playing" session with no sound.
        itemStatusObserver = item.observe(\.status, options: [.new]) { [weak self] item, _ in
            guard item.status == .failed else { return }
            Task { @MainActor in
                guard let self, self.player?.currentItem === item else { return }
                if self.usesSynthesizedVoice { NarrationRenderer.shared.discard(url) }
                self.player?.pause()
                self.isPlaying = false
                UIApplication.shared.isIdleTimerDisabled = false
                self.failPreparation(item.error?.localizedDescription
                    ?? LanguageManager.shared.localizedString(for: "audio.error.unavailable"))
                self.updateNowPlaying()
            }
        }

        timeObserver = newPlayer.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.5, preferredTimescale: 600),
            queue: .main
        ) { [weak self] time in
            MainActor.assumeIsolated { self?.tick(time.seconds) }
        }
        endObserver = NotificationCenter.default.addObserver(
            forName: AVPlayerItem.didPlayToEndTimeNotification,
            object: item,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.handleFinished() }
        }

        // Resume where the user left off.
        let resumeAt = GuidedSessionProgressStore.resumePosition(for: session.id)
        if resumeAt > 10, duration == 0 || resumeAt < duration - 20 {
            await newPlayer.seek(to: CMTime(seconds: resumeAt, preferredTimescale: 600), toleranceBefore: .zero, toleranceAfter: .zero)
            currentTime = resumeAt
        }

        phase = .ready
        preparationProgress = 1
        if wantsPlayback {
            // The session may have been deactivated meanwhile (call, Siri, other app):
            // play() on an inactive session is silent.
            AudioFocus.acquire(.guidedSession)
            newPlayer.play()
            ambiencePlayer?.play()
            isPlaying = true
            UIApplication.shared.isIdleTimerDisabled = true
        }
        updateNowPlaying()
    }

    // MARK: - Time tracking

    private func tick(_ time: TimeInterval) {
        guard time.isFinite else { return }
        if let item = player?.currentItem, duration <= 0, item.duration.isNumeric {
            duration = item.duration.seconds
        }
        currentTime = time

        if isPlaying, let last = lastTickTime {
            let delta = time - last
            if delta > 0, delta < 2 { listenedSeconds += delta }
        }
        lastTickTime = isPlaying ? time : nil

        // Completion: at least 50% actually listened.
        if !completionRecorded, duration > 0, listenedSeconds >= duration * 0.5 {
            recordCompletion()
        }

        // Fade the ambience out during the last seconds.
        if duration > 0, duration - time < 8, !isAmbienceFadingOut, let ambiencePlayer {
            isAmbienceFadingOut = true
            ambiencePlayer.setVolume(0, fadeDuration: max(1, duration - time))
        }

        saveResumePosition(force: false)
    }

    private func handleFinished() {
        guard let session = currentSession else { return }
        isPlaying = false
        didFinish = true
        currentTime = duration
        if !completionRecorded, listenedSeconds >= duration * 0.5 { recordCompletion() }
        GuidedSessionProgressStore.clearResumePosition(for: session.id)
        UIApplication.shared.isIdleTimerDisabled = false

        isAmbienceFadingOut = true
        ambiencePlayer?.setVolume(0, fadeDuration: 3)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.2) { [weak self] in
            guard let self, self.didFinish else { return }
            self.ambiencePlayer?.stop()
            self.ambiencePlayer = nil
            // Session over: let the user's music app resume (taken again on replay).
            AudioFocus.release(.guidedSession)
        }

        if sleepTimer == .endOfSession { setSleepTimer(.off) }
        updateNowPlaying()
    }

    private func recordCompletion() {
        guard let session = currentSession, !completionRecorded else { return }
        completionRecorded = true
        GuidedSessionProgressStore.markCompleted(session.id)
        guard recordsSession else { return }
        let seconds = Int((duration > 0 ? duration : TimeInterval(session.durationMinutes * 60)).rounded())
        ExerciseSessionRecorder.shared.record(
            exerciseID: session.id,
            category: .meditation,
            durationSeconds: seconds,
            source: "audio_session"
        )
        AnalyticsManager.shared.track(event: "audio_session_completed", properties: [
            "session_id": session.id,
            "category": session.category.rawValue,
            "duration_seconds": seconds,
            "synthesized_voice": usesSynthesizedVoice
        ])
    }

    private func saveResumePosition(force: Bool) {
        guard let session = currentSession, phase == .ready, !didFinish else { return }
        guard force || Date().timeIntervalSince(lastResumeSave) > 5 else { return }
        lastResumeSave = Date()
        if duration > 0, currentTime > duration - 20 {
            GuidedSessionProgressStore.clearResumePosition(for: session.id)
        } else {
            GuidedSessionProgressStore.saveResumePosition(currentTime, for: session.id)
        }
    }

    // MARK: - Stop

    private func stop(keepPresentation: Bool, releasingFocus: Bool) {
        loadTask?.cancel()
        loadTask = nil
        saveResumePosition(force: true)

        if let timeObserver { player?.removeTimeObserver(timeObserver) }
        timeObserver = nil
        if let endObserver { NotificationCenter.default.removeObserver(endObserver) }
        endObserver = nil
        itemStatusObserver = nil
        player?.pause()
        player = nil

        ambiencePlayer?.stop()
        ambiencePlayer = nil
        isAmbienceFadingOut = false

        let hadSession = currentSession != nil
        currentSession = nil
        script = nil
        phase = .idle
        isPlaying = false
        didFinish = false
        currentTime = 0
        duration = 0
        ambience = nil
        setSleepTimer(.off)
        if !keepPresentation { isFullPlayerPresented = false }

        if hadSession {
            UIApplication.shared.isIdleTimerDisabled = false
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            setSkipCommandsEnabled(false)
        }
        if releasingFocus { AudioFocus.release(.guidedSession) }
    }

    // MARK: - Ambience

    private func startAmbience(_ newAmbience: AudioAmbience?) {
        ambiencePlayer?.stop()
        ambiencePlayer = nil
        isAmbienceFadingOut = false
        ambience = newAmbience

        guard let newAmbience, let url = newAmbience.url,
              let loop = try? AVAudioPlayer(contentsOf: url) else { return }
        loop.numberOfLoops = -1
        loop.volume = 0
        loop.prepareToPlay()
        loop.play()
        loop.setVolume(ambienceVolume, fadeDuration: 1.5)
        ambiencePlayer = loop
    }

    private func restoreAmbienceVolume() {
        guard isAmbienceFadingOut else { return }
        isAmbienceFadingOut = false
        ambiencePlayer?.setVolume(ambienceVolume, fadeDuration: 0.6)
    }

    // MARK: - Sleep timer

    private func sleepTimerFired() async {
        sleepTimer = .off
        sleepTimerRemaining = nil
        guard isPlaying, let player else { return }

        // Gentle 5 s fade on both layers, then pause.
        ambiencePlayer?.setVolume(0, fadeDuration: 5)
        let start = player.volume
        for step in 1...20 {
            try? await Task.sleep(nanoseconds: 250_000_000)
            player.volume = start * (1 - Float(step) / 20)
        }
        pause()
        player.volume = voiceVolume
        ambiencePlayer?.volume = ambienceVolume
    }

    // MARK: - Audio session (see AudioFocus)

    private func setupNotifications() {
        NotificationCenter.default.publisher(for: AVAudioSession.interruptionNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] note in self?.handleInterruption(note) }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: AVAudioSession.routeChangeNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] note in self?.handleRouteChange(note) }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: LanguageManager.languageDidChangeNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.updateNowPlaying() }
            .store(in: &cancellables)
    }

    private func handleInterruption(_ note: Notification) {
        guard currentSession != nil,
              let raw = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: raw) else { return }
        switch type {
        case .began:
            if isPlaying {
                wasInterrupted = true
                pause()
            }
        case .ended:
            let optionsRaw = note.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
            if wasInterrupted, AVAudioSession.InterruptionOptions(rawValue: optionsRaw).contains(.shouldResume) {
                resume()
            }
            wasInterrupted = false
        @unknown default:
            break
        }
    }

    private func handleRouteChange(_ note: Notification) {
        guard currentSession != nil,
              let raw = note.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: raw) else { return }
        if reason == .oldDeviceUnavailable, isPlaying {
            pause() // headphones unplugged / Bluetooth disconnected
        }
    }

    // MARK: - Lock screen / Control Center

    private func setupRemoteCommands() {
        let center = MPRemoteCommandCenter.shared()

        center.playCommand.addTarget { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self, self.currentSession != nil else { return .noActionableNowPlayingItem }
                self.resume()
                return .success
            }
        }
        center.pauseCommand.addTarget { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self, self.currentSession != nil else { return .noActionableNowPlayingItem }
                self.pause()
                return .success
            }
        }
        center.togglePlayPauseCommand.addTarget { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self, self.currentSession != nil else { return .noActionableNowPlayingItem }
                self.togglePlayPause()
                return .success
            }
        }

        center.skipForwardCommand.preferredIntervals = [15]
        center.skipForwardCommand.addTarget { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self, self.currentSession != nil else { return .noActionableNowPlayingItem }
                self.skip(by: 15)
                return .success
            }
        }
        center.skipBackwardCommand.preferredIntervals = [15]
        center.skipBackwardCommand.addTarget { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self, self.currentSession != nil else { return .noActionableNowPlayingItem }
                self.skip(by: -15)
                return .success
            }
        }
        center.changePlaybackPositionCommand.addTarget { [weak self] event in
            MainActor.assumeIsolated {
                guard let self, self.currentSession != nil,
                      let event = event as? MPChangePlaybackPositionCommandEvent else { return .noActionableNowPlayingItem }
                self.seek(to: event.positionTime)
                return .success
            }
        }
        setSkipCommandsEnabled(false)
    }

    private func setSkipCommandsEnabled(_ enabled: Bool) {
        let center = MPRemoteCommandCenter.shared()
        center.skipForwardCommand.isEnabled = enabled
        center.skipBackwardCommand.isEnabled = enabled
        center.changePlaybackPositionCommand.isEnabled = enabled
    }

    private func updateNowPlaying() {
        guard let session = currentSession else { return }
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: session.localizedTitle,
            MPMediaItemPropertyArtist: "CortiFree",
            MPMediaItemPropertyAlbumTitle: session.category.title.localized,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: currentTime,
            MPMediaItemPropertyPlaybackDuration: displayDuration,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0,
            MPNowPlayingInfoPropertyDefaultPlaybackRate: 1.0,
            MPNowPlayingInfoPropertyMediaType: MPNowPlayingInfoMediaType.audio.rawValue
        ]
        if let nowPlayingArtwork { info[MPMediaItemPropertyArtwork] = nowPlayingArtwork }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    private func makeArtwork(for session: GuidedSession) -> MPMediaItemArtwork? {
        let image: UIImage?
        if let name = session.artwork.imageName, let asset = UIImage(named: name) {
            image = asset
        } else {
            let renderer = ImageRenderer(content: SessionArtworkView(session: session, cornerRadius: 0, showsSymbol: true)
                .frame(width: 600, height: 600))
            renderer.scale = 1
            image = renderer.uiImage
        }
        guard let image else { return nil }
        return MPMediaItemArtwork(boundsSize: image.size) { _ in image }
    }
}
