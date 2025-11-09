//
//  SoundPlayer.swift
//  CortiFree
//
//  Created by Claude on 22/10/2025.
//

import Foundation
import AVFoundation
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
        setupAudioSession()
    }

    private func setupAudioSession() {
        do {
            // Configure pour la lecture en arrière-plan
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .default,
                options: [.mixWithOthers]
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error.localizedDescription)")
        }
    }

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

        // Stop current if playing
        stop()

        currentExercise = exercise

        guard let audioFileName = exercise.audioFileName else {
            print("No audio file for this exercise")
            return
        }

        // Load audio file
        guard let url = Bundle.main.url(forResource: audioFileName.replacingOccurrences(of: ".mp3", with: ""), withExtension: "mp3") else {
            print("Audio file not found: \(audioFileName)")
            return
        }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.numberOfLoops = -1 // Loop indefinitely
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()

            isPlaying = true
            playStartTime = Date()  // Commencer à tracker le temps
            accumulatedPlayTime = 0  // Réinitialiser le temps accumulé
            totalPlayTime = 0
            startTimer()
            triggerHaptic(.light)
        } catch {
            print("Failed to play audio: \(error.localizedDescription)")
        }
    }

    func pause() {
        audioPlayer?.pause()
        isPlaying = false

        // Accumuler le temps écoulé
        if let startTime = playStartTime {
            accumulatedPlayTime += Date().timeIntervalSince(startTime)
            totalPlayTime = accumulatedPlayTime
        }
        playStartTime = nil

        stopTimer()
        triggerHaptic(.light)
    }

    func resume() {
        audioPlayer?.play()
        isPlaying = true
        playStartTime = Date()  // Redémarrer le compteur
        startTimer()
        triggerHaptic(.light)
    }

    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        currentExercise = nil
        progress = 0.0
        currentTime = 0
        totalPlayTime = 0
        accumulatedPlayTime = 0
        playStartTime = nil
        selectedDuration = nil
        stopTimer()
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let player = self.audioPlayer else { return }

            self.currentTime = player.currentTime

            if player.duration > 0 {
                self.progress = player.currentTime / player.duration
            }

            // Calculer le temps total de lecture
            if let startTime = self.playStartTime {
                self.totalPlayTime = self.accumulatedPlayTime + Date().timeIntervalSince(startTime)
            }

            // Vérifier si la durée sélectionnée est atteinte
            if let duration = self.selectedDuration, self.totalPlayTime >= duration {
                self.stop()
            }
        }
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
