import Foundation

@MainActor
final class ExerciseSessionRecorder {
    static let shared = ExerciseSessionRecorder()
    private init() {}

    func record(exerciseID: String, category: ProgressActivityCategory, durationSeconds: Int, source: String) {
        let userID = UnifiedFirebaseService.shared.auth.currentUser?.uid ?? UserPersistence.localUserID
        guard let localSessionID = LocalActivitySessionStore.record(
            exerciseID: exerciseID,
            category: category,
            durationSeconds: durationSeconds,
            source: source,
            userID: userID
        ) else { return }
        ProgressAnalyticsService.shared.invalidateDashboardCache()
        if category == .breathing || category == .meditation {
            Task { await HealthKitService.shared.saveMindfulSession(durationSeconds: durationSeconds) }
        }
        guard UnifiedFirebaseService.shared.auth.currentUser != nil else { return }
        Task {
            let _: String? = try? await ConvexBackend.shared.call(.mutation, path: "progress:recordExerciseSession", args: [
                "exerciseId": exerciseID,
                "exerciseType": category.rawValue,
                "durationSeconds": durationSeconds,
                "source": source,
                "localSessionId": localSessionID,
            ])
        }
    }
}
