//
//  AntiStressViewModel.swift
//  CortiFree
//
//  Created by Claude on 22/10/2025.
//  ViewModel for Anti-Stress flow coordination
//

import Foundation
import Combine

@MainActor
class AntiStressViewModel: ObservableObject {
    @Published var currentSituation: StressSituation?
    @Published var currentExercise: AntiStressExerciseType?
    @Published var isExerciseComplete = false

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Situation Selection

    func selectSituation(_ situation: StressSituation) {
        currentSituation = situation
        saveLastSituation(situation)
    }

    private func saveLastSituation(_ situation: StressSituation) {
        Task {
            guard Auth.auth().currentUser != nil else { return }
            let _: JSONValue? = try? await ConvexBackend.shared.call(
                .mutation,
                path: "profile:recordSituation",
                args: ["situation": situation.rawValue]
            )
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
            #if DEBUG
            print("Error completing exercise: \(error.localizedDescription)")
            #endif
        }
    }

    private func saveExerciseCompletion(
        exerciseType: AntiStressExerciseType,
        situation: StressSituation,
        duration: Int
    ) async throws {
        guard Auth.auth().currentUser != nil else { return }
        let _: String = try await ConvexBackend.shared.call(
            .mutation,
            path: "progress:recordExerciseSession",
            args: [
                "exerciseType": exerciseType.rawValue,
                "situation": situation.rawValue,
                "durationSeconds": duration,
                "source": "anti_stress",
            ]
        )
    }

    // MARK: - Reset

    func reset() {
        currentSituation = nil
        currentExercise = nil
        isExerciseComplete = false
    }
}
