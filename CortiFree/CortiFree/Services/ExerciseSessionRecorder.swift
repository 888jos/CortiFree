import Foundation
import FirebaseAuth
import FirebaseFirestore

final class ExerciseSessionRecorder {
    static let shared = ExerciseSessionRecorder()

    private let db = Firestore.firestore()

    private init() {}

    func record(
        exerciseID: String,
        category: ProgressActivityCategory,
        durationSeconds: Int,
        source: String
    ) {
        let userID = Auth.auth().currentUser?.uid ?? UserPersistence.localUserID
        guard let localSessionID = LocalActivitySessionStore.record(
            exerciseID: exerciseID,
            category: category,
            durationSeconds: durationSeconds,
            source: source,
            userID: userID
        ) else { return }

        guard Auth.auth().currentUser != nil else { return }

        let data: [String: Any] = [
            "exerciseId": exerciseID,
            "exerciseType": category.rawValue,
            "completedAt": Timestamp(),
            "duration": durationSeconds,
            "source": source,
            "localSessionId": localSessionID
        ]

        db.collection("users")
            .document(userID)
            .collection("exercises_done")
            .addDocument(data: data) { error in
                #if DEBUG
                if let error {
                    print("Progress session save failed: \(error.localizedDescription)")
                }
                #endif
            }
    }
}
