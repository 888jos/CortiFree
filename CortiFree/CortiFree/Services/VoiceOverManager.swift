//
//  VoiceOverManager.swift
//  CortiFree
//
//  Created by Claude on 23/11/2025.
//  Service pour gérer la synthèse vocale des instructions d'exercices
//

import Foundation
import AVFoundation

class VoiceOverManager: NSObject, ObservableObject {
    static let shared = VoiceOverManager()

    @Published var isSpeaking = false
    @Published var isEnabled = false

    private let synthesizer = AVSpeechSynthesizer()
    private override init() {
        super.init()
        synthesizer.delegate = self
    }

    // The audio session is only taken while a cue is spoken (ducking the user's music),
    // then released so the music comes back to full volume (see AudioFocus).
    private func releaseAudioFocusIfIdle() {
        guard !synthesizer.isSpeaking else { return }
        AudioFocus.release(.voiceCues)
    }

    // MARK: - Public Methods

    func speak(_ text: String, rate: Float = 0.5) {
        guard isEnabled else { return }

        // Stop any ongoing speech
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(
            language: LanguageManager.shared.currentLanguage.locale.identifier
        )
        utterance.rate = rate // 0.0 to 1.0 (default 0.5 = normal speed)
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0

        AudioFocus.acquire(.voiceCues)
        synthesizer.speak(utterance)
    }

    func pause() {
        guard synthesizer.isSpeaking else { return }
        synthesizer.pauseSpeaking(at: .immediate)
    }

    func resume() {
        guard synthesizer.isPaused else { return }
        synthesizer.continueSpeaking()
    }

    func stop() {
        guard synthesizer.isSpeaking else { return }
        synthesizer.stopSpeaking(at: .immediate)
    }

    func toggle() {
        isEnabled.toggle()
        if !isEnabled {
            stop()
        }
    }

    // MARK: - Helper Methods

    func announceStep(current: Int, total: Int) {
        let announcement = String(format: LanguageManager.shared.localizedString(for: "voiceover.step_of"), current, total)
        speak(announcement)
    }

    func announceCompletion() {
        let announcement = LanguageManager.shared.localizedString(for: "voiceover.completed")
        speak(announcement)
    }

    func announceBreathingPhase(_ phase: String) {
        // Le texte de la phase est déjà localisé
        speak(phase, rate: 0.4) // Slower for breathing instructions
    }
}

// MARK: - AVSpeechSynthesizerDelegate

extension VoiceOverManager: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = true
        }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = false
            self.releaseAudioFocusIfIdle()
        }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = false
            self.releaseAudioFocusIfIdle()
        }
    }
}
