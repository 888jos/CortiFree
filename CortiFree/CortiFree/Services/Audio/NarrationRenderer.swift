//
//  NarrationRenderer.swift
//  CortiFree
//
//  Fallback narration: renders a session script on-device with AVSpeechSynthesizer
//  into a real, seekable audio file (AAC .m4a, or .caf fallback).
//
//  Two passes:
//   1. every spoken passage is synthesized to PCM in memory (AVSpeechSynthesizer.write),
//      with the voice's own leading / trailing silence trimmed;
//   2. the timeline is written to disk: lead-in, passages, and real silence for each
//      `[pause Ns]` marker. Pauses are scaled (within tight limits) so the track length
//      lands close to the session's target duration whatever the voice's speaking speed.
//
//  Renders are kept in Application Support (excluded from backup, LRU-capped) rather than
//  Caches, so the sessions listed in Library › Downloads stay available offline.
//  Concurrent requests for the same render share one job.
//

import AVFoundation
import AVFAudio
import CryptoKit

final class NarrationRenderer: NSObject {
    static let shared = NarrationRenderer()

    /// Bump to invalidate every cached render (e.g. after tuning rate / gaps).
    static let renderVersion = 4

    /// Calm, slower than default speech.
    let speechRate: Float = AVSpeechUtteranceDefaultSpeechRate // ≈150 spoken words/min, matching the script length rule
    let pitch: Float = 0.96
    /// Silence between two consecutive passages without an explicit pause.
    let passageGap: TimeInterval = 0.8
    let leadIn: TimeInterval = 1.5
    let tail: TimeInterval = 4.0
    /// Limits for pause scaling when fitting the target duration. Kept tight: scripts are
    /// mostly continuous speech, so stretched pauses were heard as unexpected long silences.
    let minPauseScale = 0.8
    let maxPauseScale = 1.25
    /// No single scaled pause may exceed this.
    let maxPauseSeconds: TimeInterval = 8
    /// Renders kept on the device (oldest played first evicted above this).
    let storageLimitBytes: Int64 = 400 * 1024 * 1024

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

    /// One render shared by every caller asking for the same file.
    private final class Job {
        var task: Task<URL, Error>?
        var handlers: [UUID: @Sendable (Double) -> Void] = [:]
        /// A download keeps rendering even if the player that asked for it goes away.
        var keepIfAbandoned = false
        var lastProgress: Double = 0
    }

    private var jobs: [String: Job] = [:]
    private let lock = NSLock()

    private override init() {
        super.init()
        Self.migrateAndCleanStorage()
    }

    // MARK: - Voice selection

    private static var voiceCache: [String: AVSpeechSynthesisVoice] = [:]
    private static let voiceLock = NSLock()

    /// Best installed voice for a narration language: premium > enhanced > default quality,
    /// preferred region first, novelty / personal voices excluded.
    /// Cached per language: `speechVoices()` is slow and the Library asks for every row.
    static func bestVoice(for language: String) -> AVSpeechSynthesisVoice? {
        voiceLock.lock()
        defer { voiceLock.unlock() }
        if let cached = voiceCache[language] { return cached }

        let regions: [String: [String]] = [
            "fr": ["fr-FR", "fr-CA"],
            "en": ["en-US", "en-GB", "en-AU", "en-IE"],
            "de": ["de-DE", "de-AT", "de-CH"],
            "es": ["es-ES", "es-MX", "es-US"],
            "ja": ["ja-JP"],
            "ko": ["ko-KR"],
        ]
        let preferredRegions = regions[language] ?? ["en-US"]
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

        let voice = candidates.max { score($0) < score($1) } ?? AVSpeechSynthesisVoice(language: preferredRegions[0])
        if let voice { voiceCache[language] = voice }
        return voice
    }

    // MARK: - Storage

    /// Application Support/NarrationAudio, excluded from iCloud / iTunes backup.
    static var cacheDirectory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        var dir = base.appendingPathComponent("NarrationAudio", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            var values = URLResourceValues()
            values.isExcludedFromBackup = true
            try? dir.setResourceValues(values)
        }
        return dir
    }

    /// Former location (purgeable by iOS, which emptied the Downloads list).
    private static var legacyCacheDirectory: URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("NarrationAudio", isDirectory: true)
    }

    /// Moves renders from the old Caches folder and removes half-written files left by a
    /// render that was interrupted (app killed, crash).
    private static func migrateAndCleanStorage() {
        let fm = FileManager.default
        let dir = cacheDirectory
        if let legacy = try? fm.contentsOfDirectory(at: legacyCacheDirectory, includingPropertiesForKeys: nil) {
            for url in legacy where !url.lastPathComponent.contains(".partial.") {
                let target = dir.appendingPathComponent(url.lastPathComponent)
                if !fm.fileExists(atPath: target.path) { try? fm.moveItem(at: url, to: target) }
            }
            try? fm.removeItem(at: legacyCacheDirectory)
        }
        for url in (try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)) ?? []
        where url.lastPathComponent.contains(".partial.") {
            try? fm.removeItem(at: url)
        }
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

    /// True while a render for this script is running (e.g. a download in progress).
    func isRendering(_ script: NarrationScript, targetDuration: TimeInterval?) -> Bool {
        guard let voice = Self.bestVoice(for: script.language) else { return false }
        let key = cacheKey(for: script, voice: voice, targetDuration: targetDuration)
        lock.lock()
        defer { lock.unlock() }
        return jobs[key] != nil
    }

    /// Deletes one render that turned out unplayable, so the next play renders it again.
    func discard(_ url: URL) {
        guard url.deletingLastPathComponent().standardizedFileURL == Self.cacheDirectory.standardizedFileURL else { return }
        try? FileManager.default.removeItem(at: url)
    }

    /// Marks a render as just used (LRU eviction order).
    func touch(_ url: URL) {
        try? FileManager.default.setAttributes([.modificationDate: Date()], ofItemAtPath: url.path)
    }

    // MARK: Pinned renders (user downloads)

    private static let pinnedKey = "narration.pinnedRenders.v1"

    /// Pinned renders (sessions the user downloaded) are never evicted by the storage cap.
    func setPinned(_ pinned: Bool, script: NarrationScript, targetDuration: TimeInterval?) {
        guard let voice = Self.bestVoice(for: script.language) else { return }
        let key = cacheKey(for: script, voice: voice, targetDuration: targetDuration)
        var keys = Set(UserDefaults.standard.stringArray(forKey: Self.pinnedKey) ?? [])
        if pinned { keys.insert(key) } else { keys.remove(key) }
        UserDefaults.standard.set(Array(keys), forKey: Self.pinnedKey)
    }

    private var pinnedKeys: Set<String> {
        Set(UserDefaults.standard.stringArray(forKey: Self.pinnedKey) ?? [])
    }

    /// Removes every cached render (e.g. from a settings/debug screen).
    static func clearCache() {
        try? FileManager.default.removeItem(at: cacheDirectory)
    }

    /// Keeps the folder under `storageLimitBytes`, oldest played first.
    private func enforceStorageLimit(keeping kept: URL) {
        let fm = FileManager.default
        let keys: [URLResourceKey] = [.fileSizeKey, .contentModificationDateKey]
        guard let files = try? fm.contentsOfDirectory(at: Self.cacheDirectory, includingPropertiesForKeys: keys) else { return }
        var entries = files.compactMap { url -> (url: URL, size: Int64, date: Date)? in
            guard !url.lastPathComponent.contains(".partial."),
                  let values = try? url.resourceValues(forKeys: Set(keys)) else { return nil }
            return (url, Int64(values.fileSize ?? 0), values.contentModificationDate ?? .distantPast)
        }
        var total = entries.reduce(Int64(0)) { $0 + $1.size }
        guard total > storageLimitBytes else { return }
        entries.sort { $0.date < $1.date }
        let pinned = pinnedKeys
        for entry in entries where total > storageLimitBytes && entry.url != kept
            && !pinned.contains(entry.url.deletingPathExtension().lastPathComponent) {
            try? fm.removeItem(at: entry.url)
            total -= entry.size
        }
    }

    // MARK: - Render

    private enum TimelineItem {
        case silence(TimeInterval, scalable: Bool)
        case clip(Int)
    }

    /// Renders (or returns the cached render of) a script.
    /// - Parameters:
    ///   - targetDuration: desired track length in seconds (pauses are stretched/shrunk to fit).
    ///   - keepIfAbandoned: true for downloads: the render finishes even if the caller is
    ///     cancelled. Otherwise it is cancelled once nobody waits for it anymore.
    ///   - progress: called on the main queue (0...1).
    func render(_ script: NarrationScript,
                targetDuration: TimeInterval? = nil,
                keepIfAbandoned: Bool = false,
                progress: @escaping @Sendable (Double) -> Void) async throws -> URL {
        if let cached = cachedFile(for: script, targetDuration: targetDuration) {
            touch(cached)
            return cached
        }
        guard let voice = Self.bestVoice(for: script.language) else { throw RenderError.noVoice }
        let key = cacheKey(for: script, voice: voice, targetDuration: targetDuration)
        let token = UUID()

        let (job, task, startProgress) = join(key: key, token: token, keepIfAbandoned: keepIfAbandoned, progress: progress) {
            [weak self] job in
            Task.detached(priority: .userInitiated) { () throws -> URL in
                guard let self else { throw CancellationError() }
                defer { self.finishJob(key, job) }
                return try await self.performRender(script, voice: voice, key: key, job: job,
                                                    targetDuration: targetDuration)
            }
        }
        if startProgress > 0 { DispatchQueue.main.async { progress(startProgress) } }

        guard let task else { throw CancellationError() }
        defer { leave(job, token: token, cancelled: false) }
        return try await withTaskCancellationHandler {
            let url = try await task.value
            try Task.checkCancellation()
            return url
        } onCancel: {
            self.leave(job, token: token, cancelled: true)
        }
    }

    /// Joins the running job for this file, or starts one with `start`.
    private func join(key: String, token: UUID, keepIfAbandoned: Bool,
                      progress: @escaping @Sendable (Double) -> Void,
                      start: (Job) -> Task<URL, Error>) -> (Job, Task<URL, Error>?, Double) {
        lock.lock()
        defer { lock.unlock() }
        let job: Job
        if let running = jobs[key], running.task?.isCancelled == false {
            job = running
        } else {
            // (A job cancelled a moment ago may not be removed yet: start a fresh one.)
            job = Job()
            jobs[key] = job
            job.task = start(job)
        }
        job.handlers[token] = progress
        job.keepIfAbandoned = job.keepIfAbandoned || keepIfAbandoned
        return (job, job.task, job.lastProgress)
    }

    private func leave(_ job: Job, token: UUID, cancelled: Bool) {
        lock.lock()
        defer { lock.unlock() }
        guard job.handlers.removeValue(forKey: token) != nil else { return }
        if cancelled, job.handlers.isEmpty, !job.keepIfAbandoned {
            job.task?.cancel()
        }
    }

    private func finishJob(_ key: String, _ job: Job) {
        lock.lock()
        if jobs[key] === job { jobs[key] = nil }
        lock.unlock()
    }

    private func report(_ value: Double, job: Job) {
        lock.lock()
        job.lastProgress = value
        let handlers = Array(job.handlers.values)
        lock.unlock()
        DispatchQueue.main.async { handlers.forEach { $0(value) } }
    }

    private func performRender(_ script: NarrationScript, voice: AVSpeechSynthesisVoice, key: String, job: Job,
                               targetDuration: TimeInterval?) async throws -> URL {
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
                report(0.92 * Double(doneChars) / Double(totalChars), job: job)
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
        let url = try writeTimeline(timeline, clips: synth.clips, format: format, pauseScale: pauseScale, key: key)
        enforceStorageLimit(keeping: url)
        report(1, job: job)
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

        do {
            for item in timeline {
                switch item {
                case .silence(let seconds, let scalable):
                    try writeSilence(scalable ? min(seconds * pauseScale, max(seconds, maxPauseSeconds)) : seconds)
                case .clip(let index):
                    for buffer in clips[index] {
                        try output.write(from: buffer)
                    }
                }
            }
        } catch {
            file = nil
            try? FileManager.default.removeItem(at: partialURL)
            throw error
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
    /// Utterance being synthesized. Callbacks from an earlier utterance (late didFinish,
    /// stale timeout, trailing buffers) are ignored: they used to end the *next* passage
    /// early and shift the audio, leaving holes of silence in the track.
    private var currentUtterance: AVSpeechUtterance?
    private var currentClip: [AVAudioPCMBuffer] = []
    private var converter: AVAudioConverter?

    private(set) var clips: [[AVAudioPCMBuffer]] = []
    private(set) var format: AVAudioFormat?
    private(set) var totalFrames: AVAudioFramePosition = 0

    /// Below this level (≈ -50 dBFS) a frame counts as silence when trimming.
    private static let silenceThreshold: Float = 0.003
    private static let keepBefore: TimeInterval = 0.05
    private static let keepAfter: TimeInterval = 0.15

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

        // Long passages / first use of a voice can be slow on older devices.
        let timeoutSeconds = 45 + Double(text.count) / 10

        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            queue.sync {
                self.currentClip = []
                self.currentUtterance = utterance
                self.continuation = cont
            }

            queue.asyncAfter(deadline: .now() + timeoutSeconds) { [weak self] in
                guard let self, self.currentUtterance === utterance else { return }
                self.synthesizer.stopSpeaking(at: .immediate)
                self.resume(for: utterance, error: NarrationRenderer.RenderError.timeout)
            }

            synthesizer.write(utterance) { [weak self] buffer in
                guard let self, let pcm = buffer as? AVAudioPCMBuffer else { return }
                if pcm.frameLength == 0 {
                    self.queue.async { self.resume(for: utterance, error: nil) }
                    return
                }
                let copy = Self.copy(pcm)
                self.queue.async {
                    guard self.currentUtterance === utterance else { return }
                    self.append(copy)
                }
            }
        }

        return queue.sync {
            let clip = Self.trimSilence(currentClip)
            totalFrames += clip.reduce(AVAudioFramePosition(0)) { $0 + AVAudioFramePosition($1.frameLength) }
            clips.append(clip)
            currentClip = []
            return clips.count - 1
        }
    }

    // Some OS versions never send the empty terminating buffer: didFinish covers that.
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        queue.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.resume(for: utterance, error: nil)
        }
    }

    /// Must be called on `queue`.
    private func append(_ buffer: AVAudioPCMBuffer?) {
        guard let buffer else { return }
        if format == nil { format = buffer.format }
        guard let format else { return }
        if buffer.format == format {
            currentClip.append(buffer)
        } else if let converted = convert(buffer, to: format) {
            // Some voices switch format mid-render: convert instead of dropping the audio.
            currentClip.append(converted)
        }
    }

    /// Must be called on `queue`. Ignores callbacks that belong to another utterance.
    private func resume(for utterance: AVSpeechUtterance, error: Error?) {
        guard currentUtterance === utterance, let cont = continuation else { return }
        continuation = nil
        currentUtterance = nil
        if let error { cont.resume(throwing: error) } else { cont.resume() }
    }

    private func convert(_ buffer: AVAudioPCMBuffer, to format: AVAudioFormat) -> AVAudioPCMBuffer? {
        if converter?.inputFormat != buffer.format || converter?.outputFormat != format {
            converter = AVAudioConverter(from: buffer.format, to: format)
        }
        guard let converter else { return nil }
        let ratio = format.sampleRate / buffer.format.sampleRate
        let capacity = AVAudioFrameCount(Double(buffer.frameLength) * ratio) + 1024
        guard let output = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: capacity) else { return nil }
        var consumed = false
        var error: NSError?
        let status = converter.convert(to: output, error: &error) { _, inputStatus in
            if consumed {
                inputStatus.pointee = .noDataNow
                return nil
            }
            consumed = true
            inputStatus.pointee = .haveData
            return buffer
        }
        guard status != .error, error == nil, output.frameLength > 0 else { return nil }
        return output
    }

    // MARK: Silence trimming

    /// Removes the voice's own silence before and after a passage (often 0.3–1 s), keeping a
    /// short margin. The renderer then inserts controlled gaps, so the pauses heard are the
    /// ones written in the script.
    private static func trimSilence(_ clip: [AVAudioPCMBuffer]) -> [AVAudioPCMBuffer] {
        guard let first = clip.first, clip.allSatisfy(canMeasure) else { return clip }
        let sampleRate = first.format.sampleRate
        // Locate the first and last loud frames across the whole clip.
        var startBuffer: Int?
        var startFrame = 0
        var endBuffer = 0
        var endFrame = 0
        for (index, buffer) in clip.enumerated() {
            guard let range = loudRange(buffer) else { continue }
            if startBuffer == nil {
                startBuffer = index
                startFrame = range.lowerBound
            }
            endBuffer = index
            endFrame = range.upperBound
        }
        guard let startBuffer else { return clip } // all silent (or unmeasurable): keep as is

        // Margins, measured in frames, possibly reaching into neighbouring buffers.
        var before = Int(keepBefore * sampleRate)
        var sIndex = startBuffer
        var sFrame = startFrame
        while before > 0 {
            if sFrame >= before { sFrame -= before; before = 0 }
            else if sIndex > 0 { before -= sFrame; sIndex -= 1; sFrame = Int(clip[sIndex].frameLength) }
            else { sFrame = 0; before = 0 }
        }
        var after = Int(keepAfter * sampleRate)
        var eIndex = endBuffer
        var eFrame = endFrame
        while after > 0 {
            let length = Int(clip[eIndex].frameLength)
            if length - eFrame >= after { eFrame += after; after = 0 }
            else if eIndex < clip.count - 1 { after -= length - eFrame; eIndex += 1; eFrame = 0 }
            else { eFrame = length; after = 0 }
        }

        var result: [AVAudioPCMBuffer] = []
        for index in sIndex...eIndex {
            let buffer = clip[index]
            let from = index == sIndex ? sFrame : 0
            let to = index == eIndex ? eFrame : Int(buffer.frameLength)
            guard to > from else { continue }
            if from == 0, to == Int(buffer.frameLength) {
                result.append(buffer)
            } else if let slice = slice(buffer, from: from, to: to) {
                result.append(slice)
            }
        }
        return result.isEmpty ? clip : result
    }

    private static func canMeasure(_ buffer: AVAudioPCMBuffer) -> Bool {
        buffer.floatChannelData != nil || buffer.int16ChannelData != nil || buffer.int32ChannelData != nil
    }

    /// Frames [first loud, last loud + 1) of a buffer, nil if silent or unmeasurable.
    private static func loudRange(_ buffer: AVAudioPCMBuffer) -> Range<Int>? {
        let frames = Int(buffer.frameLength)
        guard frames > 0 else { return nil }
        let channels = Int(buffer.format.channelCount)
        let pointers = buffer.format.isInterleaved ? 1 : channels
        let perPointer = buffer.format.isInterleaved ? channels : 1
        let stride = buffer.stride

        func amplitude(_ frame: Int) -> Float {
            var peak: Float = 0
            for p in 0..<pointers {
                for k in 0..<perPointer {
                    let i = frame * stride + k
                    if let data = buffer.floatChannelData {
                        peak = max(peak, abs(data[p][i]))
                    } else if let data = buffer.int16ChannelData {
                        peak = max(peak, abs(Float(data[p][i])) / 32768)
                    } else if let data = buffer.int32ChannelData {
                        peak = max(peak, abs(Float(data[p][i])) / 2_147_483_648)
                    }
                }
            }
            return peak
        }

        guard canMeasure(buffer) else { return nil }
        guard let first = (0..<frames).first(where: { amplitude($0) > silenceThreshold }) else { return nil }
        let last = (first..<frames).reversed().first(where: { amplitude($0) > silenceThreshold }) ?? first
        return first..<(last + 1)
    }

    private static func slice(_ buffer: AVAudioPCMBuffer, from: Int, to: Int) -> AVAudioPCMBuffer? {
        let count = to - from
        guard count > 0,
              let copy = AVAudioPCMBuffer(pcmFormat: buffer.format, frameCapacity: AVAudioFrameCount(count)) else { return nil }
        copy.frameLength = AVAudioFrameCount(count)
        let bytesPerFrame = Int(buffer.format.streamDescription.pointee.mBytesPerFrame)
        let src = UnsafeMutableAudioBufferListPointer(UnsafeMutablePointer(mutating: buffer.audioBufferList))
        let dst = UnsafeMutableAudioBufferListPointer(copy.mutableAudioBufferList)
        for (s, d) in zip(src, dst) {
            guard let sData = s.mData, let dData = d.mData else { continue }
            memcpy(dData, sData.advanced(by: from * bytesPerFrame), count * bytesPerFrame)
        }
        return copy
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
