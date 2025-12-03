//
//  BaselineService.swift
//  CortiFree
//
//  Service pour la collecte et gestion des données de baseline
//  Empêche la régression en maintenant les habitudes au minimum du niveau actuel
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

class BaselineService {
    static let shared = BaselineService()
    private let db = Firestore.firestore()

    private init() {}

    // MARK: - Save Baseline from Quiz

    func saveBaselineFromQuiz(_ result: HabitsQuizResult) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw BaselineError.userNotAuthenticated
        }

        let baseline = result.baselineData

        // Structure Firestore pour le baseline
        let baselineData: [String: Any] = [
            "collectedAt": FieldValue.serverTimestamp(),
            "method": "quiz", // vs "tracking" for 7-day collection
            "isValidated": false, // Will be true after 7-day validation

            // Current habits
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

            // User preferences
            "preferences": [
                "availableTime": baseline.availableTime,
                "preferredIntensity": baseline.preferredIntensity,
                "hasPhysicalLimitations": false, // Removed from quiz
                "preferredTimeOfDay": "morning", // Default value
                "primaryGoal": result.primaryGoal
            ],

            // Domain scores at baseline
            "domainScores": [
                "serenity": result.serenityScore,
                "sleep": result.sleepScore,
                "energy": result.energyScore,
                "focus": result.focusScore,
                "habits": result.habitsScore,
                "global": result.globalScore
            ],

            // Quiz answers for reference
            "quizAnswers": result.answers
        ]

        // Save to Firestore
        try await db.collection("users").document(userId)
            .collection("baseline").document("initial")
            .setData(baselineData)

        // Also save to user document for quick access
        try await db.collection("users").document(userId)
            .updateData([
                "hasBaseline": true,
                "baselineCollectedAt": FieldValue.serverTimestamp()
            ])
    }

    // MARK: - 7-Day Baseline Collection

    func startBaselineCollection() async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw BaselineError.userNotAuthenticated
        }

        let collectionData: [String: Any] = [
            "startDate": FieldValue.serverTimestamp(),
            "status": "collecting", // collecting, complete, validated
            "daysCollected": 0,
            "targetDays": 7
        ]

        try await db.collection("users").document(userId)
            .collection("baseline").document("collection")
            .setData(collectionData)
    }

    func recordDailyBaseline(habits: DailyHabitsRecord) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw BaselineError.userNotAuthenticated
        }

        let dayNumber = try await getCurrentCollectionDay()

        guard dayNumber <= 7 else {
            throw BaselineError.collectionPeriodComplete
        }

        let dailyData: [String: Any] = [
            "date": FieldValue.serverTimestamp(),
            "dayNumber": dayNumber,

            "actualHabits": [
                "wakeTime": habits.wakeTime,
                "bedTime": habits.bedTime,
                "sleepHours": habits.sleepHours,
                "waterLiters": habits.waterLiters,
                "exerciseMinutes": habits.exerciseMinutes,
                "meditationMinutes": habits.meditationMinutes,
                "breathingMinutes": habits.breathingMinutes,
                "journalEntry": habits.journalEntry,
                "natureMinutes": habits.natureMinutes,
                "socialInteractions": habits.socialInteractions
            ],

            "mood": habits.mood,
            "stressLevel": habits.stressLevel,
            "energyLevel": habits.energyLevel
        ]

        // Save daily record
        try await db.collection("users").document(userId)
            .collection("baseline").document("collection")
            .collection("days").document("day_\(dayNumber)")
            .setData(dailyData)

        // Update collection status
        try await db.collection("users").document(userId)
            .collection("baseline").document("collection")
            .updateData([
                "daysCollected": dayNumber,
                "lastRecordedAt": FieldValue.serverTimestamp()
            ])

        // If 7 days complete, calculate validated baseline
        if dayNumber == 7 {
            try await calculateValidatedBaseline()
        }
    }

    // MARK: - Calculate Validated Baseline

    private func calculateValidatedBaseline() async throws {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        // Fetch all 7 days of data
        let snapshot = try await db.collection("users").document(userId)
            .collection("baseline").document("collection")
            .collection("days").getDocuments()

        var wakeTimesMinutes: [Int] = []
        var sleepHours: [Double] = []
        var waterIntakes: [Double] = []
        var exerciseMinutes: [Int] = []
        var meditationMinutes: [Int] = []

        for document in snapshot.documents {
            if let habits = document.data()["actualHabits"] as? [String: Any] {
                // Convert wake time to minutes for averaging
                if let wakeTime = habits["wakeTime"] as? String {
                    let components = wakeTime.split(separator: ":")
                    if components.count == 2,
                       let hours = Int(components[0]),
                       let minutes = Int(components[1]) {
                        wakeTimesMinutes.append(hours * 60 + minutes)
                    }
                }

                if let sleep = habits["sleepHours"] as? Double {
                    sleepHours.append(sleep)
                }

                if let water = habits["waterLiters"] as? Double {
                    waterIntakes.append(water)
                }

                if let exercise = habits["exerciseMinutes"] as? Int {
                    exerciseMinutes.append(exercise)
                }

                if let meditation = habits["meditationMinutes"] as? Int {
                    meditationMinutes.append(meditation)
                }
            }
        }

        // Calculate averages and create validated baseline
        let validatedBaseline: [String: Any] = [
            "createdAt": FieldValue.serverTimestamp(),
            "method": "7_day_tracking",
            "isValidated": true,

            "averageHabits": [
                "wakeTimeMinutes": wakeTimesMinutes.average(),
                "sleepHours": sleepHours.average(),
                "waterLiters": waterIntakes.average(),
                "exerciseMinutesPerDay": exerciseMinutes.average(),
                "meditationMinutesPerDay": meditationMinutes.average()
            ],

            "minimumTargets": [
                // Never go below these values
                "wakeTime": formatMinutesToTime(wakeTimesMinutes.min() ?? 420), // Default 7:00
                "minSleepHours": sleepHours.min() ?? 6.0,
                "minWaterLiters": waterIntakes.min() ?? 1.0,
                "minExercisePerWeek": (exerciseMinutes.filter { $0 > 0 }.count),
                "minMeditationPerWeek": (meditationMinutes.filter { $0 > 0 }.count)
            ]
        ]

        // Save validated baseline
        try await db.collection("users").document(userId)
            .collection("baseline").document("validated")
            .setData(validatedBaseline)

        // Update collection status
        try await db.collection("users").document(userId)
            .collection("baseline").document("collection")
            .updateData([
                "status": "validated",
                "validatedAt": FieldValue.serverTimestamp()
            ])
    }

    // MARK: - Get Baseline for Plan Generation

    func getBaselineForPlanGeneration() async throws -> ValidatedBaseline {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw BaselineError.userNotAuthenticated
        }

        // Try to get validated baseline first
        let validatedDoc = try await db.collection("users").document(userId)
            .collection("baseline").document("validated")
            .getDocument()

        if validatedDoc.exists,
           let data = validatedDoc.data(),
           let minimumTargets = data["minimumTargets"] as? [String: Any] {

            return ValidatedBaseline(
                wakeTime: minimumTargets["wakeTime"] as? String ?? "07:00",
                minSleepHours: minimumTargets["minSleepHours"] as? Double ?? 6.0,
                minWaterLiters: minimumTargets["minWaterLiters"] as? Double ?? 1.0,
                minExercisePerWeek: minimumTargets["minExercisePerWeek"] as? Int ?? 0,
                minMeditationPerWeek: minimumTargets["minMeditationPerWeek"] as? Int ?? 0,
                isValidated: true
            )
        }

        // Fallback to quiz baseline
        let quizDoc = try await db.collection("users").document(userId)
            .collection("baseline").document("initial")
            .getDocument()

        if quizDoc.exists,
           let data = quizDoc.data(),
           let currentHabits = data["currentHabits"] as? [String: Any] {

            return ValidatedBaseline(
                wakeTime: currentHabits["wakeTime"] as? String ?? "07:00",
                minSleepHours: currentHabits["sleepDuration"] as? Double ?? 6.0,
                minWaterLiters: currentHabits["waterIntake"] as? Double ?? 1.0,
                minExercisePerWeek: currentHabits["exerciseFrequency"] as? Int ?? 0,
                minMeditationPerWeek: currentHabits["meditationFrequency"] as? Int ?? 0,
                isValidated: false
            )
        }

        throw BaselineError.noBaselineFound
    }

    // MARK: - Helper Methods

    private func getCurrentCollectionDay() async throws -> Int {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw BaselineError.userNotAuthenticated
        }

        let doc = try await db.collection("users").document(userId)
            .collection("baseline").document("collection")
            .getDocument()

        if let data = doc.data(),
           let daysCollected = data["daysCollected"] as? Int {
            return daysCollected + 1
        }

        return 1
    }

    private func formatMinutesToTime(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        return String(format: "%02d:%02d", hours, mins)
    }
}

// MARK: - Models

struct DailyHabitsRecord {
    let wakeTime: String
    let bedTime: String
    let sleepHours: Double
    let waterLiters: Double
    let exerciseMinutes: Int
    let meditationMinutes: Int
    let breathingMinutes: Int
    let journalEntry: Bool
    let natureMinutes: Int
    let socialInteractions: Int
    let mood: Int // 1-10
    let stressLevel: Int // 1-10
    let energyLevel: Int // 1-10
}

struct ValidatedBaseline {
    let wakeTime: String
    let minSleepHours: Double
    let minWaterLiters: Double
    let minExercisePerWeek: Int
    let minMeditationPerWeek: Int
    let isValidated: Bool
}

// MARK: - Errors

enum BaselineError: LocalizedError {
    case userNotAuthenticated
    case collectionPeriodComplete
    case noBaselineFound

    var errorDescription: String? {
        switch self {
        case .userNotAuthenticated:
            return "User must be authenticated to save baseline"
        case .collectionPeriodComplete:
            return "7-day collection period is already complete"
        case .noBaselineFound:
            return "No baseline data found for user"
        }
    }
}

// MARK: - Array Extensions

extension Array where Element == Int {
    func average() -> Int {
        guard !isEmpty else { return 0 }
        return reduce(0, +) / count
    }
}

extension Array where Element == Double {
    func average() -> Double {
        guard !isEmpty else { return 0 }
        return reduce(0, +) / Double(count)
    }
}