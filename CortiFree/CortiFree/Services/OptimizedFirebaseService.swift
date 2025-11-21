//
//  OptimizedFirebaseService.swift
//  CortiFree
//
//  Service Firebase optimisé pour performance mobile
//  Utilise des opérations asynchrones et batch pour éviter les blocages UI
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

class OptimizedFirebaseService {
    static let shared = OptimizedFirebaseService()
    private let db = Firestore.firestore()
    private let queue = DispatchQueue(label: "firebase.queue", qos: .background)

    private init() {
        // DO NOT configure Firestore settings - causes crash
        // Firestore uses default settings
    }

    // MARK: - Optimized Save Operations

    /// Save quiz data in background without blocking UI
    func saveQuizDataInBackground(_ result: HabitsQuizResult, overallData: OverallQuizData?) {
        queue.async { [weak self] in
            guard let self = self,
                  let userId = Auth.auth().currentUser?.uid else { return }

            // Prepare all data first
            let batch = self.db.batch()

            // 1. Baseline data
            let baselineRef = self.db.collection("users").document(userId)
                .collection("baseline").document("initial")

            let baselineData = self.prepareBaselineData(result)
            batch.setData(baselineData, forDocument: baselineRef)

            // 2. User profile (if available)
            if let overallData = overallData {
                let profileRef = self.db.collection("users").document(userId)
                let profileData = self.prepareProfileData(overallData)
                batch.setData(profileData, forDocument: profileRef, merge: true)
            }

            // 3. Execute batch write (single network call)
            batch.commit { error in
                if let error = error {
                    print("❌ Batch write error: \(error)")
                } else {
                    print("✅ Data saved successfully in background")

                    // Generate plan asynchronously after save
                    self.generatePlanInBackground(result)
                }
            }
        }
    }

    // MARK: - Lightweight Plan Generation

    private func generatePlanInBackground(_ result: HabitsQuizResult) {
        queue.async { [weak self] in
            guard let self = self,
                  let userId = Auth.auth().currentUser?.uid else { return }

            // Simple plan generation without heavy computation
            let focusHabits = self.quickDetermineFocusHabits(result)
            let adaptationLevel = self.quickCalculateAdaptationLevel(result)

            // Save minimal plan data
            let planData: [String: Any] = [
                "generatedAt": FieldValue.serverTimestamp(),
                "focusHabits": focusHabits,
                "adaptationLevel": adaptationLevel,
                "baselineWakeTime": result.baselineData.wakeTime,
                "status": "active"
            ]

            self.db.collection("users").document(userId)
                .collection("personalized_plan").document("current")
                .setData(planData) { error in
                    if error == nil {
                        print("✅ Plan generated in background")
                    }
                }
        }
    }

    // MARK: - Helper Methods

    private func prepareBaselineData(_ result: HabitsQuizResult) -> [String: Any] {
        let baseline = result.baselineData

        return [
            "collectedAt": FieldValue.serverTimestamp(),
            "method": "quiz",
            "currentHabits": [
                "wakeTime": baseline.wakeTime,
                "sleepDuration": baseline.sleepDuration,
                "waterIntake": baseline.waterIntake,
                "exerciseFrequency": baseline.exerciseFrequency,
                "exerciseDuration": baseline.exerciseDuration,
                "meditationFrequency": baseline.meditationFrequency,
                "meditationDuration": baseline.meditationDuration,
                "breathingFrequency": baseline.breathingFrequency
            ],
            "preferences": [
                "availableTime": baseline.availableTime,
                "preferredIntensity": baseline.preferredIntensity,
                "hasPhysicalLimitations": result.hasPhysicalLimitations,
                "preferredTimeOfDay": result.preferredTimeOfDay,
                "primaryGoal": result.primaryGoal
            ],
            "domainScores": [
                "serenity": result.serenityScore,
                "sleep": result.sleepScore,
                "energy": result.energyScore,
                "focus": result.focusScore,
                "habits": result.habitsScore,
                "global": result.globalScore
            ]
        ]
    }

    private func prepareProfileData(_ data: OverallQuizData) -> [String: Any] {
        return [
            "firstName": data.firstName,
            "age": data.age,
            "gender": data.gender,
            "stressReasons": data.reasons,
            "stressDuration": data.duration,
            "onboardingCompletedAt": Date(),
            "hasBaseline": true
        ]
    }

    private func quickDetermineFocusHabits(_ result: HabitsQuizResult) -> [String] {
        var habits: [String] = []

        // Quick determination based on lowest scores
        if result.serenityScore < 50 {
            habits.append(contentsOf: ["breathing", "meditation"])
        }
        if result.sleepScore < 50 {
            habits.append("sleep")
        }
        if result.energyScore < 50 {
            habits.append(contentsOf: ["water", "sport"])
        }

        // Return top 4 habits
        return Array(habits.prefix(4))
    }

    private func quickCalculateAdaptationLevel(_ result: HabitsQuizResult) -> Int {
        switch result.baselineData.preferredIntensity {
        case "very_gentle": return 2
        case "gentle": return 3
        case "moderate": return 5
        case "intensive": return 7
        case "very_intensive": return 9
        default: return 5
        }
    }
}

// MARK: - Simplified Onboarding Integration

extension OnboardingV2FlowView {
    func optimizedSaveData(result: HabitsQuizResult, overallData: OverallQuizData?) {
        // Save in background without blocking UI
        OptimizedFirebaseService.shared.saveQuizDataInBackground(result, overallData: overallData)
    }
}