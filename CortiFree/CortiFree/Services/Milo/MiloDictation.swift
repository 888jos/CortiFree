//
//  MiloDictation.swift
//  CortiFree
//
//  Voice dictation for the Milo composer. Apple's Speech framework streams a live
//  transcript into the composer while the user speaks. The same audio is recorded, and
//  when the user stops (and has accepted Milo's AI disclosure), it is sent to the
//  server, which has OpenAI transcribe it: that more accurate text replaces the live
//  one. Offline or on any error, Apple's transcript stays. The user still reviews the
//  text and taps send.
//
//  Language: the user may not speak the app's language. The same audio goes to up to three
//  recognizers (last language detected, app language, iPhone keyboard languages) and the
//  most confident transcript wins when the user stops. A long press on the mic forces any
//  language Apple supports.
//

import AVFoundation
import Speech
import SwiftUI

@MainActor
final class MiloDictation: ObservableObject {
    enum Failure: Equatable {
        case denied
        case unavailable
    }

    @Published private(set) var isRecording = false
    /// The recording is being transcribed by the server (after the user stopped).
    @Published private(set) var isTranscribing = false
    /// Mic level 0…1, for the pulsing ring.
    @Published private(set) var level: CGFloat = 0
    @Published var failure: Failure?

    /// One recognizer per candidate language, all fed the same audio. The user may speak
    /// another language than the app's: when they stop, the most confident transcript wins.
    private final class Channel {
        let locale: Locale
        let recognizer: SFSpeechRecognizer
        let request: SFSpeechAudioBufferRecognitionRequest
        var task: SFSpeechRecognitionTask?
        var text = ""
        var confidence: Double?
        var done = false

        init(locale: Locale, recognizer: SFSpeechRecognizer, request: SFSpeechAudioBufferRecognitionRequest) {
            self.locale = locale
            self.recognizer = recognizer
            self.request = request
        }
    }

    private let audioEngine = AVAudioEngine()
    private var channels: [Channel] = []
    /// The channel shown live in the composer (the last language detected, else the app's).
    private var primary = 0
    private var finishing = false
    private var finishDeadline: Timer?
    private var silenceTimer: Timer?
    /// Text already in the composer when the dictation started.
    private var prefix = ""
    private var onText: ((String) -> Void)?
    /// Recording of the dictation, sent for the accurate transcript (nil = Apple only).
    private var recordingFile: AVAudioFile?
    private var recordingURL: URL?
    private var useCloud = false
    /// Bumped by cancel(): a late server transcript must not refill the composer.
    private var generation = 0

    /// Apple stops a recognition after about a minute; we stop a bit before.
    private let maxDuration: TimeInterval = 55
    /// A pause to think should not end the dictation.
    private let silenceTimeout: TimeInterval = 4
    private var startedAt = Date()

    /// - Parameter useCloud: send the recording for the accurate transcript (needs Milo's consent).
    func toggle(currentText: String, useCloud: Bool = false, onText: @escaping (String) -> Void) {
        if isRecording { stop() } else { start(currentText: currentText, useCloud: useCloud, onText: onText) }
    }

    func start(currentText: String, useCloud: Bool = false, onText: @escaping (String) -> Void) {
        guard !isRecording, !finishing, !isTranscribing else { return }
        failure = nil
        self.useCloud = useCloud
        Task {
            guard await Self.requestPermissions() else {
                failure = .denied
                return
            }
            begin(currentText: currentText, onText: onText)
        }
    }

    /// The user stopped (or paused): wait for each language's final transcript, keep the best.
    func stop() {
        guard isRecording else { return }
        endRecording()
        finishing = true
        channels.forEach { $0.request.endAudio() }
        finishDeadline = Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { [weak self] _ in
            Task { @MainActor in self?.finish() }
        }
        finishIfReady()
    }

    /// Leaving Milo or sending the message: drop everything, late results must not refill the composer.
    func cancel() {
        if isRecording { endRecording() }
        channels.forEach { $0.task?.cancel() }
        generation += 1
        isTranscribing = false
        cleanUp()
        discardRecording()
    }

    // MARK: - Private

    private func begin(currentText: String, onText: @escaping (String) -> Void) {
        let locales = Self.candidateLocales()
        let built: [Channel] = locales.compactMap { locale in
            // Never the iPhone's default recognizer: French speech went through the English
            // one and came out as unrelated English words.
            guard let recognizer = SFSpeechRecognizer(locale: locale), recognizer.isAvailable else { return nil }
            let request = SFSpeechAudioBufferRecognitionRequest()
            request.shouldReportPartialResults = true
            request.addsPunctuation = true
            if recognizer.supportsOnDeviceRecognition { request.requiresOnDeviceRecognition = true }
            return Channel(locale: locale, recognizer: recognizer, request: request)
        }
        guard !built.isEmpty else {
            failure = .unavailable
            return
        }

        AudioFocus.acquire(.dictation)
        let input = audioEngine.inputNode
        let format = input.outputFormat(forBus: 0)
        guard format.sampleRate > 0 else {
            AudioFocus.release(.dictation)
            failure = .unavailable
            return
        }
        let requests = built.map(\.request)
        let file = useCloud ? makeRecordingFile(format: format) : nil
        input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            requests.forEach { $0.append(buffer) }
            try? file?.write(from: buffer)
            let rms = Self.rms(buffer)
            Task { @MainActor in self?.level = rms }
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            input.removeTap(onBus: 0)
            AudioFocus.release(.dictation)
            discardRecording()
            failure = .unavailable
            return
        }

        let trimmed = currentText.trimmingCharacters(in: .whitespacesAndNewlines)
        prefix = trimmed.isEmpty ? "" : trimmed + " "
        self.onText = onText
        channels = built
        primary = 0
        startedAt = Date()
        isRecording = true
        HapticManager.light()
        armSilenceTimer(timeout: 6)

        for (index, channel) in built.enumerated() {
            channel.task = channel.recognizer.recognitionTask(with: channel.request) { [weak self] result, error in
                let text = result?.bestTranscription.formattedString
                let segments = result?.bestTranscription.segments ?? []
                let isFinal = result?.isFinal ?? false
                Task { @MainActor in
                    guard let self, index < self.channels.count, self.channels[index] === channel else { return }
                    if let text { channel.text = text }
                    if isFinal, !segments.isEmpty {
                        channel.confidence = segments.map { Double($0.confidence) }.reduce(0, +) / Double(segments.count)
                    }
                    if isFinal || error != nil { channel.done = true }

                    if self.isRecording {
                        if text != nil { self.armSilenceTimer() }
                        if index == self.primary, let text { self.onText?(self.prefix + text) }
                        // Every language gave up (e.g. on-device model missing): stop cleanly.
                        if self.channels.allSatisfy(\.done) { self.stop() }
                    } else if self.finishing {
                        self.finishIfReady()
                    }
                }
            }
        }
    }

    private func finishIfReady() {
        if channels.allSatisfy(\.done) { finish() }
    }

    /// Keeps the most confident transcript and remembers its language for next time, then
    /// replaces it with the server transcript of the recording when there is one.
    private func finish() {
        guard finishing else { return }
        let heard = channels.filter { !$0.text.trimmingCharacters(in: .whitespaces).isEmpty }
        let best = heard.max { ($0.confidence ?? 0) < ($1.confidence ?? 0) } ?? heard.first
        AnalyticsManager.shared.track(event: "milo_dictation_used", properties: [
            "language": best?.locale.identifier ?? "",
            "candidates": channels.map(\.locale.identifier).joined(separator: ","),
            "auto_detected": best.map { $0 !== channels.first } ?? false,
            "heard": best != nil,
            "server_transcript": recordingURL != nil,
            "seconds": Int(Date().timeIntervalSince(startedAt))
        ])
        if let best {
            onText?(prefix + best.text)
            if heard.count > 1, let code = best.locale.language.languageCode?.identifier {
                UserDefaults.standard.set(code, forKey: Self.lastLanguageKey)
            }
        }
        let onText = onText
        let prefix = prefix
        channels.forEach { $0.task?.finish() }
        cleanUp()

        // Closing the file flushes the encoder; then the server transcript replaces Apple's.
        recordingFile = nil
        guard let url = recordingURL, Date().timeIntervalSince(startedAt) > 0.8 else {
            discardRecording()
            return
        }
        recordingURL = nil
        let chosen = UserDefaults.standard.string(forKey: Self.localeKey) ?? ""
        let language = chosen.isEmpty ? nil : Locale(identifier: chosen).language.languageCode?.identifier
        let token = generation
        isTranscribing = true
        Task {
            let text = try? await MiloTranscription.transcribe(fileURL: url, language: language)
            try? FileManager.default.removeItem(at: url)
            guard token == self.generation else { return }
            self.isTranscribing = false
            if let text, !text.isEmpty { onText?(prefix + text) }
        }
    }

    // MARK: - Recording (server transcript)

    /// AAC file at the mic's own rate and channel count (AVAudioFile writes PCM buffers of
    /// the file's rate): ~48 kbit/s, ~330 KB for the longest dictation.
    private func makeRecordingFile(format: AVAudioFormat) -> AVAudioFile? {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("milo-dictation-\(UUID().uuidString).m4a")
        var settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: format.sampleRate,
            AVNumberOfChannelsKey: format.channelCount,
            AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue
        ]
        if format.channelCount == 1 { settings[AVEncoderBitRateKey] = 48_000 }
        guard let file = try? AVAudioFile(forWriting: url, settings: settings,
                                          commonFormat: format.commonFormat, interleaved: format.isInterleaved) else { return nil }
        recordingFile = file
        recordingURL = url
        return file
    }

    private func discardRecording() {
        recordingFile = nil
        if let url = recordingURL { try? FileManager.default.removeItem(at: url) }
        recordingURL = nil
    }

    private func endRecording() {
        isRecording = false
        level = 0
        silenceTimer?.invalidate()
        silenceTimer = nil
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        AudioFocus.release(.dictation)
    }

    private func cleanUp() {
        finishing = false
        finishDeadline?.invalidate()
        finishDeadline = nil
        channels = []
        onText = nil
    }

    /// Stops after a pause in speech, or near Apple's one-minute limit.
    /// Before the first words the user gets a longer delay to start speaking.
    private func armSilenceTimer(timeout: TimeInterval? = nil) {
        silenceTimer?.invalidate()
        let remaining = maxDuration - Date().timeIntervalSince(startedAt)
        silenceTimer = Timer.scheduledTimer(withTimeInterval: min(timeout ?? silenceTimeout, max(remaining, 0.1)), repeats: false) { [weak self] _ in
            Task { @MainActor in self?.stop() }
        }
    }

    // MARK: - Language

    /// "" = the app's language, otherwise the speech locale the user picked (long press on the mic).
    static let localeKey = "milo.dictation.locale"

    /// Speech recognition works per locale (« fr-FR », not « fr »): « fr » alone matched no
    /// recognizer and the iPhone's default language was used instead.
    static func speechLocale() -> Locale {
        let supported = SFSpeechRecognizer.supportedLocales()
        let chosen = UserDefaults.standard.string(forKey: localeKey) ?? ""
        if !chosen.isEmpty, let match = supported.first(where: { $0.identifier == chosen }) { return match }
        return bestLocale(for: LanguageManager.shared.currentLanguage.rawValue, in: supported)
    }

    /// Language of the last multi-language dictation that won: shown live first next time.
    static let lastLanguageKey = "milo.dictation.lastLanguage"

    /// The languages to listen for: the picked one only, or the last detected language, the
    /// app's language and the languages of the iPhone keyboards (at most 3 at once).
    static func candidateLocales() -> [Locale] {
        let supported = SFSpeechRecognizer.supportedLocales()
        let chosen = UserDefaults.standard.string(forKey: localeKey) ?? ""
        if !chosen.isEmpty { return [speechLocale()] }
        let keyboards = UITextInputMode.activeInputModes
            .compactMap(\.primaryLanguage)
            .compactMap { Locale(identifier: $0).language.languageCode?.identifier }
        let ordered = [UserDefaults.standard.string(forKey: lastLanguageKey), LanguageManager.shared.currentLanguage.rawValue] + keyboards
        var languages: [String] = []
        for case let code? in ordered where !languages.contains(code) && supported.contains(where: { $0.language.languageCode?.identifier == code }) {
            languages.append(code)
        }
        return languages.prefix(3).map { bestLocale(for: $0, in: supported) }
    }

    private static let defaultRegions = ["fr": "FR", "en": "US", "es": "ES", "de": "DE", "ja": "JP", "ko": "KR"]

    static func bestLocale(for language: String, in supported: Set<Locale>) -> Locale {
        let candidates = supported
            .filter { $0.language.languageCode?.identifier == language }
            .sorted { $0.identifier < $1.identifier }
        let region = Locale.current.region?.identifier
        return candidates.first { $0.region?.identifier == region }
            ?? candidates.first { $0.region?.identifier == defaultRegions[language] }
            ?? candidates.first
            ?? Locale(identifier: language)
    }

    /// Every language Apple can transcribe, named in the app's language.
    static func languageChoices() -> [(id: String, name: String)] {
        let display = Locale(identifier: LanguageManager.shared.currentLanguage.rawValue)
        return SFSpeechRecognizer.supportedLocales()
            .map { (id: $0.identifier, name: display.localizedString(forIdentifier: $0.identifier) ?? $0.identifier) }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private static func requestPermissions() async -> Bool {
        let speech = await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
            SFSpeechRecognizer.requestAuthorization { continuation.resume(returning: $0 == .authorized) }
        }
        guard speech else { return false }
        return await AVAudioApplication.requestRecordPermission()
    }

    private nonisolated static func rms(_ buffer: AVAudioPCMBuffer) -> CGFloat {
        guard let data = buffer.floatChannelData?[0], buffer.frameLength > 0 else { return 0 }
        let count = Int(buffer.frameLength)
        var sum: Float = 0
        for i in 0..<count { sum += data[i] * data[i] }
        let value = sqrt(sum / Float(count))
        return CGFloat(min(max(value * 12, 0), 1))
    }
}

/// Mic button of the Milo composer: tap to dictate, tap again (or pause) to stop.
struct MiloDictationButton: View {
    @ObservedObject var dictation: MiloDictation
    var action: () -> Void
    /// Long press: dictate in another language than the app's (any language Apple supports).
    @AppStorage(MiloDictation.localeKey) private var chosenLocale = ""

    private func t(_ key: String) -> String { LanguageManager.shared.localizedString(for: key) }

    var body: some View {
        Button(action: action) {
            ZStack {
                if dictation.isRecording {
                    Circle()
                        .fill(Color(hex: "FF6B8A").opacity(0.28))
                        .scaleEffect(1 + dictation.level * 0.45)
                        .animation(.easeOut(duration: 0.12), value: dictation.level)
                }
                if dictation.isTranscribing {
                    ProgressView()
                        .tint(.white)
                        .frame(width: 34, height: 34)
                        .background(Color.white.opacity(0.10), in: Circle())
                } else {
                Image(systemName: dictation.isRecording ? "stop.fill" : "mic.fill")
                    .font(.system(size: dictation.isRecording ? 13 : 15, weight: .semibold))
                    .foregroundStyle(dictation.isRecording ? .white : .white.opacity(0.85))
                    .frame(width: 34, height: 34)
                    .background(dictation.isRecording ? Color(hex: "FF6B8A") : Color.white.opacity(0.10), in: Circle())
                    .contentTransition(.symbolEffect(.replace))
                }
            }
            .frame(width: 34, height: 34)
            .overlay(alignment: .bottomTrailing) {
                // A custom dictation language shows as a small code under the mic (« ES »).
                if !chosenLocale.isEmpty, !dictation.isRecording {
                    Text(verbatim: Locale(identifier: chosenLocale).language.languageCode?.identifier.uppercased() ?? "")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 3)
                        .padding(.vertical, 1)
                        .background(Color(hex: "FF6B8A"), in: Capsule())
                        .offset(x: 4, y: 3)
                }
            }
        }
        .buttonStyle(.plain)
        .contextMenu {
            Picker(t("milo.dictation.language"), selection: $chosenLocale) {
                Text(String(format: t("milo.dictation.language.app"), currentAppLanguageName)).tag("")
                ForEach(MiloDictation.languageChoices(), id: \.id) { choice in
                    Text(choice.name).tag(choice.id)
                }
            }
        }
        .accessibilityLabel(t(dictation.isRecording ? "milo.dictation.stop" : "milo.dictation.start"))
        .accessibilityHint(t("milo.dictation.language.hint"))
    }

    private var currentAppLanguageName: String {
        let code = LanguageManager.shared.currentLanguage.rawValue
        return Locale(identifier: code).localizedString(forLanguageCode: code)?.capitalized ?? code
    }
}

// MARK: - Server transcription

/// Sends a dictation recording to the server (convex/transcribe.ts → OpenAI).
enum MiloTranscription {
    private struct Response: Decodable { let text: String }

    static func transcribe(fileURL: URL, language: String?) async throws -> String {
        let data = try Data(contentsOf: fileURL)
        guard !data.isEmpty, data.count <= 1_500_000 else { throw DeepSeekChatError.invalidResponse }
        var args: [String: Any] = ["audio": data.base64EncodedString(), "mimeType": "audio/mp4"]
        if let language { args["language"] = language }
        let response: Response = try await ConvexBackend.shared.call(.action, path: "transcribe:audio", args: args)
        AnalyticsManager.shared.track(event: "milo_dictation_transcribed", properties: ["bytes": data.count])
        return response.text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
