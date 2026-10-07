//
//  NarrationRenderer.swift
//  CortiFree
//
//  Fallback narration: renders a session script on-device with AVSpeechSynthesizer
//  into a real, seekable audio file (AAC .m4a, or .caf fallback) in Caches.
//
//  Two passes:
//   1. every spoken passage is synthesized to PCM in memory (AVSpeechSynthesizer.write);
//   2. the timeline is written to disk: lead-in, passages, and real silence for each
//      `[pause Ns]` marker. Pauses are scaled (within limits) so the track length lands
//      close to the session's target duration whatever the voice's speaking speed.
//

import AVFoundation
import AVFAudio
import CryptoKit

final class NarrationRenderer: NSObject {
    static let shared = NarrationRenderer()

    /// Bump to invalidate every cached render (e.g. after tuning rate / gaps).
    static let renderVersion = 2

    /// Calm, slower than default speech.
    let speechRate: Float = AVSpeechUtteranceDefaultSpeechRate * 0.8
    let pitch: Float = 0.96
    /// Silence between two consecutive passages without an explicit pause.
    let passageGap: TimeInterval = 0.8
    let leadIn: TimeInterval = 1.5
    let tail: TimeInterval = 4.0
    /// Limits for pause scaling when fitting the target duration.
    let minPauseScale = 0.8
    let maxPauseScale = 1.8

    enum RenderError: LocalizedError {
        case noVoice
        case emptyScript
        case noAudioProduced
        case timeout

        var errorDescription: String? {
            switch self {
            case .noVoice: return "No speech voice installed for this language."
            case .emptyScript: return "Empty narration script."
            case .noAudioProduced: return "The speech synthesizer produced no audio."
            case .timeout: return "Speech rendering timed out."
            }
        }
    }

    private override init() { super.init() }

    // MARK: - Voice selection

    /// Best installed voice for a narration language: premium > enhanced > default quality,
    /// preferred region first, novelty / personal voices excluded.
    static func bestVoice(for language: String) -> AVSpeechSynthesisVoice? {
        let preferredRegions: [String] = language == "fr" ? ["fr-FR", "fr-CA"] : ["en-US", "en-GB", "en-AU", "en-IE"]
        let candidates = AVSpeechSynthesisVoice.speechVoices().filter { voice in
            guard voice.language.lowercased().hasPrefix(language.lowercased()) else { return false }
            if voice.voiceTraits.contains(.isNoveltyVoice) || voice.voiceTraits.contains(.isPersonalVoice) { return false }
            return true
        }

        func score(_ voice: AVSpeechSynthesisVoice) -> Int {
            var value = 0
            switch voice.quality {
            case .premium: value += 300
            case .enhanced: value += 200
            default: value += 100
            }
            if let index = preferredRegions.firstIndex(of: voice.language) {
                value += 50 - index * 10
            }
            return value
        }

        return candidates.max { score($0) < score($1) } ?? AVSpeechSynthesisVoice(language: preferredRegions[0])
    }

    // MARK: - Cache

    static var cacheDirectory: URL {
        let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let dir = base.appendingPathComponent("NarrationAudio", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    func cacheKey(for script: NarrationScript, voice: AVSpeechSynthesisVoice, targetDuration: TimeInterval?) -> String {
        let material = "v\(Self.renderVersion)|\(script.language)|\(voice.identifier)|\(speechRate)|\(pitch)|\(Int(targetDuration ?? 0))|\(script.rawText)"
        let digest = SHA256.hash(data: Data(material.utf8))
        return String(digest.map { String(format: "%02x", $0) }.joined().prefix(32))
    }

    func cachedFile(for script: NarrationScript, targetDuration: TimeInterval?) -> URL? {
        guard let voice = Self.bestVoice(for: script.language) else { return nil }
        let key = cacheKey(for: script, voice: voice, targetDuration: targetDuration)
        for ext in ["m4a", "caf"] {
            let url = Self.cacheDirectory.appendingPathComponent("\(key).\(ext)")
            if FileManager.default.fileExists(atPath: url.path) { return url }
        }
        return nil
    }

    /// Removes every cached render (e.g. from a settings/debug screen).
    static func clearCache() {
        try? FileManager.default.removeItem(at: cacheDirectory)
    }

    // MARK: - Render

    private enum TimelineItem {
        case silence(TimeInterval, scalable: Bool)
        case clip(Int)
    }

    /// Renders (or returns the cached render of) a script.
    /// - Parameters:
    ///   - targetDuration: desired track length in seconds (pauses are stretched/shrunk to fit).
    ///   - progress: called on the main queue (0...1).
    func render(_ script: NarrationScript,
                targetDuration: TimeInterval? = nil,
                progress: @escaping @Sendable (Double) -> Void) async throws -> URL {
        if let cached = cachedFile(for: script, targetDuration: targetDuration) { return cached }
        guard let voice = Self.bestVoice(for: script.language) else { throw RenderError.noVoice }

        let segments = script.segments
        let totalChars = segments.reduce(0) { sum, seg in
            if case .speech(let text) = seg { return sum + text.count }
            return sum
        }
        guard totalChars > 0 else { throw RenderError.emptyScript }

        let synth = SpeechClipSynthesizer(voice: voice, rate: speechRate, pitch: pitch)

        // Pass 1: synthesize every passage, build the timeline.
        var timeline: [TimelineItem] = [.silence(leadIn, scalable: false)]
        var doneChars = 0
        var previousWasSpeech = false
        for segment in segments {
            try Task.checkCancellation()
            switch segment {
            case .pause(let seconds):
                timeline.append(.silence(seconds, scalable: true))
                previousWasSpeech = false
            case .speech(let text):
                if previousWasSpeech { timeline.append(.silence(passageGap, scalable: false)) }
                let index = try await synth.synthesize(text)
                timeline.append(.clip(index))
                previousWasSpeech = true
                doneChars += text.count
                let fraction = 0.92 * Double(doneChars) / Double(totalChars)
                DispatchQueue.main.async { progress(fraction) }
            }
        }
        timeline.append(.silence(tail, scalable: false))

        guard let format = synth.format, synth.totalFrames > 0 else { throw RenderError.noAudioProduced }

        // Fit the target duration by scaling the explicit pauses.
        var pauseScale = 1.0
        if let targetDuration, targetDuration > 0 {
            var fixed = Double(synth.totalFrames) / format.sampleRate
            var scalable = 0.0
            for item in timeline {
                if case .silence(let s, let isScalable) = item {
                    if isScalable { scalable += s } else { fixed += s }
                }
            }
            if scalable > 0 {
                pauseScale = min(maxPauseScale, max(minPauseScale, (targetDuration - fixed) / scalable))
            }
        }

        // Pass 2: write the file.
        try Task.checkCancellation()
        let key = cacheKey(for: script, voice: voice, targetDuration: targetDuration)
        let url = try writeTimeline(timeline, clips: synth.clips, format: format, pauseScale: pauseScale, key: key)
        DispatchQueue.main.async { progress(1) }
        return url
    }

    private func writeTimeline(_ timeline: [TimelineItem], clips: [[AVAudioPCMBuffer]],
                               format: AVAudioFormat, pauseScale: Double, key: String) throws -> URL {
        let directory = Self.cacheDirectory
        var partialURL = directory.appendingPathComponent("\(key).partial.m4a")
        try? FileManager.default.removeItem(at: partialURL)

        var file: AVAudioFile?
        let aacSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: format.sampleRate,
            AVNumberOfChannelsKey: format.channelCount,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        file = try? AVAudioFile(forWriting: partialURL, settings: aacSettings,
                                commonFormat: format.commonFormat, interleaved: format.isInterleaved)
        if file == nil {
            // Fallback: uncompressed CAF with the synthesizer's own format.
            partialURL = directory.appendingPathComponent("\(key).partial.caf")
            try? FileManager.default.removeItem(at: partialURL)
            file = try AVAudioFile(forWriting: partialURL, settings: format.settings,
                                   commonFormat: format.commonFormat, interleaved: format.isInterleaved)
        }
        guard let output = file else { throw RenderError.noAudioProduced }

        let silenceChunk: AVAudioFrameCount = 8192
        guard let silence = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: silenceChunk) else {
            throw RenderError.noAudioProduced
        }
        silence.frameLength = silenceChunk
        for buffer in UnsafeMutableAudioBufferListPointer(silence.mutableAudioBufferList) {
            if let data = buffer.mData { memset(data, 0, Int(buffer.mDataByteSize)) }
        }

        func writeSilence(_ seconds: TimeInterval) throws {
            var remaining = AVAudioFrameCount(max(0, seconds) * format.sampleRate)
            while remaining > 0 {
                let frames = min(silenceChunk, remaining)
                silence.frameLength = frames
                try output.write(from: silence)
                remaining -= frames
            }
        }

        for item in timeline {
            switch item {
            case .silence(let seconds, let scalable):
                try writeSilence(scalable ? seconds * pauseScale : seconds)
            case .clip(let index):
                for buffer in clips[index] {
                    try output.write(from: buffer)
                }
            }
        }

        file = nil // closes / finalizes the file
        let finalURL = directory.appendingPathComponent("\(key).\(partialURL.pathExtension)")
        try? FileManager.default.removeItem(at: finalURL)
        try FileManager.default.moveItem(at: partialURL, to: finalURL)
        return finalURL
    }
}

// MARK: - Speech → PCM clips

/// Synthesizes passages one after another into in-memory PCM buffers.
private final class SpeechClipSynthesizer: NSObject, AVSpeechSynthesizerDelegate {
    private let synthesizer = AVSpeechSynthesizer()
    private let voice: AVSpeechSynthesisVoice
    private let rate: Float
    private let pitch: Float

    private let queue = DispatchQueue(label: "cortifree.narration.render")
    private var continuation: CheckedContinuation<Void, Error>?
    private var currentClip: [AVAudioPCMBuffer] = []

    private(set) var clips: [[AVAudioPCMBuffer]] = []
    private(set) var format: AVAudioFormat?
    private(set) var totalFrames: AVAudioFramePosition = 0

    init(voice: AVSpeechSynthesisVoice, rate: Float, pitch: Float) {
        self.voice = voice
        self.rate = rate
        self.pitch = pitch
        super.init()
        synthesizer.delegate = self
        #if os(iOS)
        // Rendering to a buffer must not touch the app's audio session / playback.
        synthesizer.usesApplicationAudioSession = false
        #endif
    }

    /// Returns the index of the synthesized clip in `clips`.
    func synthesize(_ text: String) async throws -> Int {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = voice
        utterance.rate = rate
        utterance.pitchMultiplier = pitch
        utterance.volume = 1
        utterance.preUtteranceDelay = 0
        utterance.postUtteranceDelay = 0

        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            queue.sync {
                self.currentClip = []
                self.continuation = cont
            }

            let timeout = DispatchWorkItem { [weak self] in
                self?.resumeIfNeeded(NarrationRenderer.RenderError.timeout)
            }
            queue.asyncAfter(deadline: .now() + 45, execute: timeout)

            synthesizer.write(utterance) { [weak self] buffer in
                guard let self, let pcm = buffer as? AVAudioPCMBuffer else { return }
                if pcm.frameLength == 0 {
                    timeout.cancel()
                    self.queue.async { self.resumeIfNeeded(nil) }
                    return
                }
                let copy = Self.copy(pcm)
                self.queue.async { self.append(copy) }
            }
        }

        return queue.sync {
            clips.append(currentClip)
            currentClip = []
            return clips.count - 1
        }
    }

    // Some OS versions never send the empty terminating buffer: didFinish covers that.
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        queue.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.resumeIfNeeded(nil)
        }
    }

    /// Must be called on `queue`.
    private func append(_ buffer: AVAudioPCMBuffer?) {
        guard let buffer else { return }
        if format == nil { format = buffer.format }
        guard let format, buffer.format == format else { return } // same voice → same format
        currentClip.append(buffer)
        totalFrames += AVAudioFramePosition(buffer.frameLength)
    }

    /// Must be called on `queue`.
    private func resumeIfNeeded(_ error: Error?) {
        guard let cont = continuation else { return }
        continuation = nil
        if let error { cont.resume(throwing: error) } else { cont.resume() }
    }

    private static func copy(_ buffer: AVAudioPCMBuffer) -> AVAudioPCMBuffer? {
        guard let copy = AVAudioPCMBuffer(pcmFormat: buffer.format, frameCapacity: buffer.frameLength) else { return nil }
        copy.frameLength = buffer.frameLength
        let src = UnsafeMutableAudioBufferListPointer(UnsafeMutablePointer(mutating: buffer.audioBufferList))
        let dst = UnsafeMutableAudioBufferListPointer(copy.mutableAudioBufferList)
        for (s, d) in zip(src, dst) {
            guard let sData = s.mData, let dData = d.mData else { continue }
            memcpy(dData, sData, Int(min(s.mDataByteSize, d.mDataByteSize)))
        }
        return copy
    }
}
