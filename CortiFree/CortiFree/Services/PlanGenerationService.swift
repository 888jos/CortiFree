//
//  PlanGenerationService.swift
//  CortiFree
//
//  Service de génération de plan personnalisé avec anti-régression
//  Garantit que l'utilisateur ne régresse jamais par rapport à son baseline
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

class PlanGenerationService {
    static let shared = PlanGenerationService()
    private let db = Firestore.firestore()
    private let baselineService = BaselineService.shared

    private init() {}

    // MARK: - Generate Personalized Plan

    func generatePersonalizedPlan(quizResult: HabitsQuizResult) async throws -> PersonalizedPlan {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw PlanError.userNotAuthenticated
        }

        // Get validated baseline
        let baseline = try await baselineService.getBaselineForPlanGeneration()

        // Determine focus habits based on lowest scores
        let focusHabits = determineFocusHabits(from: quizResult)

        // Calculate adaptation level (1-10)
        let adaptationLevel = calculateAdaptationLevel(
            intensity: quizResult.baselineData.preferredIntensity,
            availableTime: quizResult.baselineData.availableTime
        )

        // Generate weekly targets with anti-regression
        let weeklyTargets = generateWeeklyTargets(
            baseline: baseline,
            quizResult: quizResult,
            adaptationLevel: adaptationLevel,
            focusHabits: focusHabits
        )

        // Create plan
        let plan = PersonalizedPlan(
            userId: userId,
            createdAt: Date(),
            adaptationLevel: adaptationLevel,
            focusHabits: focusHabits,
            weeklyTargets: weeklyTargets,
            rules: PlanRules(
                noRegression: true,
                minCompletionToAdvance: 70,
                adaptationTriggers: ["weekly_review", "performance_drop"]
            ),
            baseline: baseline
        )

        // Save to Firestore
        try await savePlanToFirestore(plan)

        return plan
    }

    // MARK: - Determine Focus Habits

    private func determineFocusHabits(from result: HabitsQuizResult) -> [String] {
        var habitScores: [(habit: String, score: Int)] = []

        // Map domain scores to habits
        if result.serenityScore < 50 {
            habitScores.append(("breathing", 100 - result.serenityScore))
            habitScores.append(("meditation", 100 - result.serenityScore))
        }

        if result.sleepScore < 50 {
            habitScores.append(("sleep", 100 - result.sleepScore))
        }

        if result.energyScore < 50 {
            habitScores.append(("water", 100 - result.energyScore))
            habitScores.append(("sport", 100 - result.energyScore))
        }

        if result.focusScore < 50 {
            habitScores.append(("journal", 100 - result.focusScore))
            habitScores.append(("nature", 100 - result.focusScore))
        }

        // Add social if balance score is low
        if result.balanceScore < 50 {
            habitScores.append(("social", 100 - result.balanceScore))
        }

        // Sort by priority (lower score = higher priority)
        habitScores.sort { $0.score > $1.score }

        // Return top 4-5 habits as focus
        let topHabits = habitScores.prefix(5).map { $0.habit }

        // Ensure at least 3 habits
        if topHabits.count < 3 {
            return ["breathing", "meditation", "water"]
        }

        return Array(topHabits)
    }

    // MARK: - Calculate Adaptation Level

    private func calculateAdaptationLevel(intensity: String, availableTime: Int) -> Int {
        var level = 5 // Default moderate

        // Adjust based on intensity preference
        switch intensity {
        case "very_gentle":
            level = 2
        case "gentle":
            level = 3
        case "moderate":
            level = 5
        case "intensive":
            level = 7
        case "very_intensive":
            level = 9
        default:
            level = 5
        }

        // Adjust based on available time
        if availableTime < 20 {
            level = max(1, level - 2)
        } else if availableTime > 60 {
            level = min(10, level + 1)
        }

        return level
    }

    // MARK: - Generate Weekly Targets with Anti-Regression

    private func generateWeeklyTargets(
        baseline: ValidatedBaseline,
        quizResult: HabitsQuizResult,
        adaptationLevel: Int,
        focusHabits: [String]
    ) -> [WeeklyTarget] {

        var weeklyTargets: [WeeklyTarget] = []
        let progressionSpeed = Double(adaptationLevel) / 10.0

        for week in 1...10 {
            var habitTargets: [String: HabitTarget] = [:]

            // BREATHING - Never below baseline
            let breathingBaseline = quizResult.baselineData.breathingFrequency
            let breathingFreq = max(breathingBaseline, calculateProgression(
                baseline: breathingBaseline,
                week: week,
                speed: progressionSpeed,
                maxTarget: 7,
                isFocusHabit: focusHabits.contains("breathing")
            ))

            habitTargets["breathing"] = HabitTarget(
                frequency: breathingFreq,
                duration: calculateDuration(base: 5, week: week, speed: progressionSpeed, max: 10),
                isRequired: focusHabits.contains("breathing")
            )

            // MEDITATION - Never below baseline
            let meditationBaseline = quizResult.baselineData.meditationFrequency
            let meditationFreq = max(meditationBaseline, calculateProgression(
                baseline: meditationBaseline,
                week: week,
                speed: progressionSpeed,
                maxTarget: 7,
                isFocusHabit: focusHabits.contains("meditation")
            ))

            habitTargets["meditation"] = HabitTarget(
                frequency: meditationFreq,
                duration: max(quizResult.baselineData.meditationDuration,
                             calculateDuration(base: 5, week: week, speed: progressionSpeed, max: 15)),
                isRequired: focusHabits.contains("meditation")
            )

            // WATER - Never below baseline
            let waterBaseline = quizResult.baselineData.waterIntake
            let waterTarget = max(waterBaseline, calculateWaterProgression(
                baseline: waterBaseline,
                week: week,
                speed: progressionSpeed
            ))

            habitTargets["water"] = HabitTarget(
                frequency: 7, // Daily
                duration: Int(waterTarget * 10), // Store as x10 for integer
                isRequired: focusHabits.contains("water")
            )

            // SPORT - Never below baseline
            let exerciseBaseline = quizResult.baselineData.exerciseFrequency
            let exerciseFreq = max(exerciseBaseline, calculateProgression(
                baseline: exerciseBaseline,
                week: week,
                speed: progressionSpeed,
                maxTarget: 5,
                isFocusHabit: focusHabits.contains("sport")
            ))

            habitTargets["sport"] = HabitTarget(
                frequency: exerciseFreq,
                duration: max(quizResult.baselineData.exerciseDuration,
                             calculateDuration(base: 20, week: week, speed: progressionSpeed, max: 60)),
                isRequired: focusHabits.contains("sport")
            )

            // JOURNAL
            habitTargets["journal"] = HabitTarget(
                frequency: calculateProgression(
                    baseline: 2,
                    week: week,
                    speed: progressionSpeed,
                    maxTarget: 7,
                    isFocusHabit: focusHabits.contains("journal")
                ),
                duration: 10,
                isRequired: focusHabits.contains("journal")
            )

            // SLEEP - Never regress on wake time
            let currentWakeTime = baseline.wakeTime
            habitTargets["sleep"] = HabitTarget(
                frequency: 7, // Daily routine
                duration: 0, // Wake time stored separately
                isRequired: focusHabits.contains("sleep"),
                metadata: ["wakeTime": currentWakeTime, "targetHours": "\(baseline.minSleepHours)"]
            )

            // NATURE
            habitTargets["nature"] = HabitTarget(
                frequency: calculateProgression(
                    baseline: 1,
                    week: week,
                    speed: progressionSpeed,
                    maxTarget: 4,
                    isFocusHabit: focusHabits.contains("nature")
                ),
                duration: calculateDuration(base: 30, week: week, speed: progressionSpeed, max: 90),
                isRequired: focusHabits.contains("nature")
            )

            // SOCIAL
            habitTargets["social"] = HabitTarget(
                frequency: calculateProgression(
                    baseline: 2,
                    week: week,
                    speed: progressionSpeed,
                    maxTarget: 5,
                    isFocusHabit: focusHabits.contains("social")
                ),
                duration: calculateDuration(base: 30, week: week, speed: progressionSpeed, max: 60),
                isRequired: focusHabits.contains("social")
            )

            weeklyTargets.append(WeeklyTarget(
                weekNumber: week,
                habits: habitTargets,
                minimumCompletionRate: 0.7, // 70% to advance
                adaptationAllowed: week > 2 // Allow adaptation after week 2
            ))
        }

        return weeklyTargets
    }

    // MARK: - Progression Calculations

    private func calculateProgression(
        baseline: Int,
        week: Int,
        speed: Double,
        maxTarget: Int,
        isFocusHabit: Bool
    ) -> Int {
        // Focus habits progress faster
        let multiplier = isFocusHabit ? 1.3 : 1.0

        // Gentle progression formula
        let progressionRate = 0.15 * speed * multiplier
        let targetValue = Double(baseline) + (Double(week - 1) * progressionRate * Double(maxTarget - baseline) / 9.0)

        return min(maxTarget, Int(round(targetValue)))
    }

    private func calculateDuration(base: Int, week: Int, speed: Double, max: Int) -> Int {
        let progressionRate = 0.1 * speed
        let targetValue = Double(base) + (Double(week - 1) * progressionRate * Double(max - base) / 9.0)
        return min(max, Int(round(targetValue)))
    }

    private func calculateWaterProgression(baseline: Double, week: Int, speed: Double) -> Double {
        let maxTarget = 2.5
        let progressionRate = 0.1 * speed
        let targetValue = baseline + (Double(week - 1) * progressionRate * (maxTarget - baseline) / 9.0)
        return min(maxTarget, targetValue)
    }

    // MARK: - Save to Firestore

    private func savePlanToFirestore(_ plan: PersonalizedPlan) async throws {
        let planData: [String: Any] = [
            "generatedAt": FieldValue.serverTimestamp(),
            "adaptationLevel": plan.adaptationLevel,
            "focusHabits": plan.focusHabits,
            "rules": [
                "noRegression": plan.rules.noRegression,
                "minCompletionToAdvance": plan.rules.minCompletionToAdvance,
                "adaptationTriggers": plan.rules.adaptationTriggers
            ],
            "baselineWakeTime": plan.baseline.wakeTime,
            "baselineMinSleepHours": plan.baseline.minSleepHours,
            "baselineMinWaterLiters": plan.baseline.minWaterLiters
        ]

        // Save main plan document
        try await db.collection("users").document(plan.userId)
            .collection("personalized_plan").document("current")
            .setData(planData)

        // Save weekly targets
        for weeklyTarget in plan.weeklyTargets {
            var habitData: [String: [String: Any]] = [:]

            for (habitName, target) in weeklyTarget.habits {
                habitData[habitName] = [
                    "frequency": target.frequency,
                    "duration": target.duration,
                    "isRequired": target.isRequired,
                    "metadata": target.metadata
                ]
            }

            let weekData: [String: Any] = [
                "weekNumber": weeklyTarget.weekNumber,
                "habits": habitData,
                "minimumCompletionRate": weeklyTarget.minimumCompletionRate,
                "adaptationAllowed": weeklyTarget.adaptationAllowed
            ]

            try await db.collection("users").document(plan.userId)
                .collection("personalized_plan").document("current")
                .collection("weeklyTargets").document("week_\(weeklyTarget.weekNumber)")
                .setData(weekData)
        }
    }
}

// MARK: - Models

struct PersonalizedPlan {
    let userId: String
    let createdAt: Date
    let adaptationLevel: Int
    let focusHabits: [String]
    let weeklyTargets: [WeeklyTarget]
    let rules: PlanRules
    let baseline: ValidatedBaseline
}

struct WeeklyTarget {
    let weekNumber: Int
    let habits: [String: HabitTarget]
    let minimumCompletionRate: Double
    let adaptationAllowed: Bool
}

struct HabitTarget {
    let frequency: Int // times per week
    let duration: Int // minutes (or x10 for water liters)
    let isRequired: Bool
    var metadata: [String: String] = [:]
}

struct PlanRules {
    let noRegression: Bool
    let minCompletionToAdvance: Int // percentage
    let adaptationTriggers: [String]
}

// MARK: - Errors

enum PlanError: LocalizedError {
    case userNotAuthenticated
    case baselineRequired
    case planGenerationFailed

    var errorDescription: String? {
        switch self {
        case .userNotAuthenticated:
            return "User must be authenticated to generate plan"
        case .baselineRequired:
            return "Baseline data is required before generating plan"
        case .planGenerationFailed:
            return "Failed to generate personalized plan"
        }
    }
}