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
    private var currentLanguage: String = "fr-FR"

    private override init() {
        super.init()
        synthesizer.delegate = self
        detectLanguage()
        configureAudioSession()
    }

    // MARK: - Configuration

    private func detectLanguage() {
        let languageCode = Locale.current.languageCode ?? "fr"
        currentLanguage = languageCode == "en" ? "en-US" : "fr-FR"
    }

    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("❌ VoiceOver: Failed to configure audio session - \(error)")
        }
    }

    // MARK: - Public Methods

    func speak(_ text: String, rate: Float = 0.5) {
        guard isEnabled else { return }

        // Stop any ongoing speech
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: currentLanguage)
        utterance.rate = rate // 0.0 to 1.0 (default 0.5 = normal speed)
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0

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
        let announcement = String(format: NSLocalizedString("voiceover.step_of", comment: ""), current, total)
        speak(announcement)
    }

    func announceCompletion() {
        let announcement = NSLocalizedString("voiceover.completed", comment: "")
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
        }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = false
        }
    }
}
