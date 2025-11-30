//
//  AntiStressViewModel.swift
//  CortiFree
//
//  Created by Claude on 22/10/2025.
//  ViewModel for Anti-Stress flow coordination
//

import Foundation
import Combine
import FirebaseFirestore

@MainActor
class AntiStressViewModel: ObservableObject {
    @Published var currentSituation: StressSituation?
    @Published var currentExercise: AntiStressExerciseType?
    @Published var isExerciseComplete = false

    private let firebaseService = FirebaseService.shared
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Situation Selection

    func selectSituation(_ situation: StressSituation) {
        currentSituation = situation
        saveLastSituation(situation)
    }

    private func saveLastSituation(_ situation: StressSituation) {
        Task {
            guard let userId = firebaseService.currentUserId else { return }

            let db = Firestore.firestore()
            try? await db.collection("users").document(userId).updateData([
                "lastSituation": situation.rawValue,
                "lastSituationTimestamp": Timestamp()
            ])
        }
    }

    // MARK: - Exercise Selection

    func startExercise(_ exerciseType: AntiStressExerciseType) {
        currentExercise = exerciseType
        isExerciseComplete = false
    }

    // MARK: - Exercise Completion

    func completeExercise() async {
        guard let situation = currentSituation,
              let exerciseType = currentExercise else { return }

        do {
            // Save exercise completion (XP removed)
            try await saveExerciseCompletion(
                exerciseType: exerciseType,
                situation: situation,
                duration: exerciseType.duration
            )

            isExerciseComplete = true
        } catch {
            print("Error completing exercise: \(error.localizedDescription)")
        }
    }

    private func saveExerciseCompletion(
        exerciseType: AntiStressExerciseType,
        situation: StressSituation,
        duration: Int
    ) async throws {
        guard let userId = firebaseService.currentUserId else { return }

        let db = Firestore.firestore()
        let completion = ExerciseCompletion(
            exerciseType: exerciseType,
            situation: situation,
            completedAt: Timestamp(),
            duration: duration
        )

        // Save to exercises_done subcollection (XP removed)
        try await db.collection("users")
            .document(userId)
            .collection("exercises_done")
            .addDocument(data: [
                "exerciseType": exerciseType.rawValue,
                "situation": situation.rawValue,
                "completedAt": completion.completedAt,
                "duration": duration
            ])

        // Update user stats
        try await db.collection("users").document(userId).updateData([
            "lastExerciseType": exerciseType.rawValue,
            "lastExerciseDate": Timestamp(),
            "totalExercisesCompleted": FieldValue.increment(Int64(1))
        ])
    }

    // MARK: - Reset

    func reset() {
        currentSituation = nil
        currentExercise = nil
        isExerciseComplete = false
    }
}
