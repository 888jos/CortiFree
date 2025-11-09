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

    func playExercise(_ exercise: Exercise) {
        soundPlayer.play(exercise: exercise)
    }

    func quickAccess(type: ExerciseType) {
        selectedCategory = type
    }
}
