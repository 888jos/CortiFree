import Foundation

/// Transitional name kept so existing onboarding call sites remain compatible.
/// Persistence is handled entirely by Convex.
@MainActor
final class OptimizedFirebaseService {
    static let shared = OptimizedFirebaseService()
    private init() {}

    func saveQuizDataInBackground(_ result: HabitsQuizResult, overallData: OverallQuizData?) {
        guard Auth.auth().currentUser != nil else { return }
        let baseline = result.baselineData
        var args: [String: Any] = [
            "baseline": [
                "method": "quiz",
                "currentHabits": [
                    "wakeTime": baseline.wakeTime,
                    "sleepDuration": baseline.sleepDuration,
                    "waterIntake": baseline.waterIntake,
                    "exerciseFrequency": baseline.exerciseFrequency,
                    "exerciseDuration": baseline.exerciseDuration,
                    "meditationFrequency": baseline.meditationFrequency,
                    "meditationDuration": baseline.meditationDuration,
                    "breathingFrequency": baseline.breathingFrequency,
                ],
                "preferences": [
                    "availableTime": baseline.availableTime,
                    "preferredIntensity": baseline.preferredIntensity,
                    "hasPhysicalLimitations": false,
                    "preferredTimeOfDay": "morning",
                    "primaryGoal": result.primaryGoal,
                ],
                "quizAnswers": result.answers,
            ],
        ]
        if let overallData { args["profile"] = Self.profileAnswers(overallData) }

        Task {
            do {
                let _: JSONValue = try await ConvexBackend.shared.call(
                    .mutation, path: "baseline:saveInitial", args: args
                )
                #if DEBUG
                print("✅ Onboarding baseline saved to Convex")
                #endif
            } catch {
                #if DEBUG
                print("⚠️ Convex onboarding save failed: \(error.localizedDescription)")
                #endif
            }
        }
    }

    static func profileAnswers(_ data: OverallQuizData) -> [String: Any] {
        var answers: [String: Any] = [
            "age": data.age,
            "gender": data.gender,
            "genderCode": data.genderCode,
            "stressReasons": data.reasons,
            "stressDuration": data.duration,
        ]
        if let channel = data.acquisitionChannel, !channel.isEmpty {
            answers["acquisitionChannel"] = channel
        }
        return answers
    }
}

extension OnboardingV2FlowView {
    func optimizedSaveData(result: HabitsQuizResult, overallData: OverallQuizData?) {
        OptimizedFirebaseService.shared.saveQuizDataInBackground(result, overallData: overallData)
    }
}
