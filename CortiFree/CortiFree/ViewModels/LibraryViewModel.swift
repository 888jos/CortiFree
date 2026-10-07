//
//  LibraryViewModel.swift
//  CortiFree
//
//  Created by Claude on 22/10/2025.
//

import Foundation
import Combine

@MainActor
class LibraryViewModel: ObservableObject {
    @Published var breathingExercises: [Exercise] = Exercise.breathingExercises
    @Published var sounds: [Exercise] = Exercise.sounds
    @Published var selectedCategory: ExerciseType = .breathing
    @Published var scrollToSection: String?

    private let soundPlayer = SoundPlayer.shared
    private var languageChangeObserver: NSObjectProtocol?

    init() {
        languageChangeObserver = NotificationCenter.default.addObserver(
            forName: LanguageManager.languageDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.reloadLocalizedExercises()
            }
        }
    }

    deinit {
        if let languageChangeObserver {
            NotificationCenter.default.removeObserver(languageChangeObserver)
        }
    }

    private func reloadLocalizedExercises() {
        breathingExercises = Exercise.breathingExercises
        sounds = Exercise.sounds
    }

    func playExercise(_ exercise: Exercise) {
        soundPlayer.play(exercise: exercise)
    }

    /// Starts a guided audio session and opens the global full-screen player.
    func playSession(_ session: GuidedSession) {
        GuidedSessionPlayer.shared.play(session, presentFullPlayer: true)
    }

    func quickAccess(type: ExerciseType) {
        selectedCategory = type
    }
}
