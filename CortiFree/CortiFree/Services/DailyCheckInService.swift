import FirebaseAuth
import FirebaseFirestore
import Foundation

@MainActor
final class DailyCheckInService {
    static let shared = DailyCheckInService()

    private let db = Firestore.firestore()
    private let promptedDayKey = "daily_check_in_last_prompted_day"
    private let completedDayKey = "daily_check_in_last_completed_day"

    private init() {}

    func shouldPresent(on date: Date = Date()) -> Bool {
        guard UserPersistence.hasCompletedOnboarding,
              Auth.auth().currentUser != nil else { return false }
        if let settings = UserSettings.loadFromUserDefaults(),
           Calendar.current.startOfDay(for: settings.programStartDate) >= Calendar.current.startOfDay(for: date) {
            return false
        }
        return UserDefaults.standard.string(forKey: promptedDayKey) != dayKey(for: date)
    }

    func markPrompted(on date: Date = Date()) {
        UserDefaults.standard.set(dayKey(for: date), forKey: promptedDayKey)
    }

    func save(
        mood: Mood,
        stress: Int,
        sleep: Int,
        energy: Int,
        note: String,
        for date: Date
    ) async throws {
        guard let userID = Auth.auth().currentUser?.uid else {
            throw NSError(
                domain: "DailyCheckInService",
                code: 401,
                userInfo: [NSLocalizedDescriptionKey: "error.auth.not_connected".localized]
            )
        }

        let record = DailyCheckInRecord(
            id: dayKey(for: date),
            date: Calendar.current.startOfDay(for: date),
            mood: mood,
            stress: min(max(stress, 1), 5),
            sleep: min(max(sleep, 1), 5),
            energy: min(max(energy, 1), 5),
            note: note.trimmingCharacters(in: .whitespacesAndNewlines),
            createdAt: Date()
        )

        let batch = db.batch()
        let checkInReference = db.collection("users").document(userID)
            .collection("daily_checkins").document(record.id)
        let moodReference = db.collection("users").document(userID)
            .collection("daily_moods").document(record.id)

        batch.setData([
            "date": Timestamp(date: record.date),
            "mood": record.mood.rawValue,
            "stress": record.stress,
            "sleep": record.sleep,
            "energy": record.energy,
            "note": record.note,
            "createdAt": Timestamp(date: record.createdAt)
        ], forDocument: checkInReference, merge: true)
        batch.setData([
            "date": Timestamp(date: record.date),
            "mood": record.mood.rawValue,
            "timestamp": Timestamp(date: record.createdAt)
        ], forDocument: moodReference, merge: true)
        try await batch.commit()

        if !record.note.isEmpty {
            let journalEntry = JournalEntry(
                id: nil,
                content: record.note,
                createdAt: record.date,
                userId: userID,
                mood: record.mood,
                photoURL: nil,
                wordCount: record.note.split(whereSeparator: \.isWhitespace).count,
                meditationId: nil,
                meditationType: "daily_checkin",
                prompt: "daily_checkin.reflection_prompt".localized,
                tags: ["daily_checkin"],
                isFavorite: false
            )
            try await JournalService.shared.saveEntry(journalEntry)
        }

        UserDefaults.standard.set(dayKey(for: Date()), forKey: completedDayKey)
        NotificationCenter.default.post(name: NSNotification.Name("DailyCheckInSaved"), object: nil)
    }

    func previousDay(relativeTo date: Date = Date()) -> Date {
        Calendar.current.date(byAdding: .day, value: -1, to: Calendar.current.startOfDay(for: date)) ?? date
    }

    private func dayKey(for date: Date) -> String {
        Self.dayFormatter.string(from: date)
    }

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = .current
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
