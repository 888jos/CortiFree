//
//  PersonalPlanGenerator.swift
//  CortiFree
//
//  Deterministic generation of the personalized 28-day plan.
//
//  Inputs (PlanProfile) → analysis (goal weights, flags) → 28 days, each with
//  1 breathing exercise + 1 guided audio session (+ short alternative)
//  + 2–3 habits weighted toward the goals (+ an evening wind-down for sleep).
//
//  Same inputs + same goal + same cycle ⇒ same plan (seeded RNG, no dictionary-order
//  dependence). Quiz scores are only used internally to find the weakest areas.
//

import Foundation

// MARK: - Analysis

struct PlanAnalysis {
    enum GoalOrigin: String { case reason, quiz, answers, user, fallback }

    var weights: [PlanGoal: Double]
    var primary: PlanGoal
    var primaryOrigin: GoalOrigin
    var secondary: PlanGoal
    var gentle: Bool
    var compact: Bool
    var recent: Bool
    // Flags from symptoms / answers
    var tension: Bool
    var palpitations: Bool
    var sleepIssue: Bool
    var nightWaking: Bool
    var racingMind: Bool
    var fatigue: Bool
    var isolation: Bool
    var senior: Bool
    /// Latest GAD-7 band (on-device only, never stored in the plan).
    var anxiety: AnxietySeverity?
    /// Content the user asked not to see again (PlanPreferences.excludedRefIDs).
    var excluded: Set<String> = []
}

enum PersonalPlanGenerator {

    // MARK: Public API

    static func generate(
        profile: PlanProfile,
        overrideGoal: PlanGoal? = nil,
        anxiety: AnxietySeverity? = nil,
        startDate: Date = Date(),
        cycle: Int = 1,
        excluded: Set<String> = [],
        variation: Int = 0
    ) -> PersonalPlan {
        var analysis = analyze(profile, overrideGoal: overrideGoal, anxiety: anxiety)
        analysis.excluded = excluded
        let seedString = "\(fingerprint(profile))|\(analysis.primary.rawValue)|\(analysis.secondary.rawValue)|\(cycle)|\(anxiety?.rawValue ?? "-")" + (variation > 0 ? "|v\(variation)" : "")
        var rng = SeededGenerator(seed: seedString)

        var audioHistory = UsageHistory()
        var breathingHistory = UsageHistory()
        var habitHistory = UsageHistory()
        var days: [PlanDay] = []

        // Daily anchor habit: sport / social are not daily-friendly, so they never anchor.
        let ranked = rankedHabits(analysis)
        let anchorHabit = ranked.first { $0 != "sport" && $0 != "social" } ?? ranked.first ?? "water"

        for dayNumber in 1...PersonalPlan.length {
            let week = (dayNumber - 1) / 7 + 1
            let theme = PlanWeekTheme.forWeek(week)
            // Day slot: secondary goal every 3rd day, primary otherwise.
            let slotGoal: PlanGoal = (dayNumber % 3 == 0 && analysis.secondary != analysis.primary) ? analysis.secondary : analysis.primary
            var items: [PlanItem] = []

            // (a) Breathing
            let breathing = pickBreathing(day: dayNumber, week: week, goal: slotGoal, theme: theme, analysis: analysis, cycle: cycle, history: &breathingHistory, rng: &rng)
            items.append(breathing)

            // Evening wind-down first (so the daytime session can avoid duplicating it)
            var eveningID: String?
            if hasEvening(day: dayNumber, analysis: analysis) {
                let evening = pickEvening(day: dayNumber, week: week, analysis: analysis, cycle: cycle, history: &audioHistory, rng: &rng)
                eveningID = evening.refID
                // (b) daytime audio
                let audio = pickAudio(day: dayNumber, week: week, goal: slotGoal, theme: theme, analysis: analysis, cycle: cycle, excluding: eveningID, eveningPresent: true, history: &audioHistory, rng: &rng)
                items.append(audio)
                // (c) habits, then evening last
                items.append(contentsOf: pickHabits(day: dayNumber, week: week, analysis: analysis, anchor: anchorHabit, history: &habitHistory, rng: &rng))
                items.append(evening)
            } else {
                let audio = pickAudio(day: dayNumber, week: week, goal: slotGoal, theme: theme, analysis: analysis, cycle: cycle, excluding: nil, eveningPresent: false, history: &audioHistory, rng: &rng)
                items.append(audio)
                items.append(contentsOf: pickHabits(day: dayNumber, week: week, analysis: analysis, anchor: anchorHabit, history: &habitHistory, rng: &rng))
            }

            days.append(PlanDay(dayNumber: dayNumber, week: week, items: items))
        }

        return PersonalPlan(
            goal: analysis.primary,
            secondaryGoal: analysis.secondary,
            gentle: analysis.gentle,
            compact: analysis.compact,
            startDate: Calendar.current.startOfDay(for: startDate),
            cycle: cycle,
            days: days,
            profile: profile,
            insights: insights(for: analysis, profile: profile, anchorHabit: anchorHabit),
            generatedAt: Date(),
            goalChosenByUser: overrideGoal != nil
        )
    }

    // MARK: - Analysis

    static func analyze(_ profile: PlanProfile, overrideGoal: PlanGoal? = nil, anxiety: AnxietySeverity? = nil) -> PlanAnalysis {
        var weights: [PlanGoal: Double] = Dictionary(uniqueKeysWithValues: PlanGoal.allCases.map { ($0, 0) })
        let symptoms = Set(profile.symptomIDs)
        let answers = profile.quizAnswers ?? []

        // 1. Reasons (strongest explicit signal)
        var reasonGoals: [PlanGoal: Double] = [:]
        for code in profile.reasonCodes {
            switch code {
            case "sleep": reasonGoals[.sleep, default: 0] += 3
            case "anxiety": reasonGoals[.stress, default: 0] += 3
            case "energy": reasonGoals[.energy, default: 0] += 3
            case "focus": reasonGoals[.focus, default: 0] += 3
            case "mental": reasonGoals[.stress, default: 0] += 2; reasonGoals[.emotional, default: 0] += 1
            case "difficult": reasonGoals[.emotional, default: 0] += 3
            case "habits": reasonGoals[.stress, default: 0] += 1; reasonGoals[.energy, default: 0] += 1
            default: break
            }
        }
        for (goal, value) in reasonGoals { weights[goal, default: 0] += value }

        // 2. Explicit improvement goal (habits quiz Q11)
        var quizGoal: PlanGoal?
        let goalCodes = ["sleep", "stress", "energy", "focus", "balance"]
        let improvement = answers.count > 10 ? goalCodes[safe: answers[10]] : profile.improvementGoal
        switch improvement {
        case "sleep": quizGoal = .sleep
        case "stress": quizGoal = .stress
        case "energy": quizGoal = .energy
        case "focus": quizGoal = .focus
        case "balance": weights[.stress, default: 0] += 1; weights[.emotional, default: 0] += 1
        default: break
        }
        if let quizGoal { weights[quizGoal, default: 0] += 2 }

        // 3. Weakest domains (internal use only)
        let scores = domainScores(answers)
        if let s = scores.stress, s < 60 { weights[.stress, default: 0] += Double(60 - s) / 20 }
        if let s = scores.sleep, s < 60 { weights[.sleep, default: 0] += Double(60 - s) / 20 }
        if let s = scores.energy, s < 60 { weights[.energy, default: 0] += Double(60 - s) / 20 }
        if let s = scores.focus, s < 60 { weights[.focus, default: 0] += Double(60 - s) / 20 }

        // 4. Symptoms
        let symptomWeights: [(String, PlanGoal, Double)] = [
            ("mental.1", .stress, 1), ("mental.2", .focus, 1), ("mental.3", .emotional, 1),
            ("mental.4", .emotional, 0.5), ("mental.4", .stress, 0.5), ("mental.5", .focus, 1),
            ("mental.6", .energy, 1), ("physical.1", .sleep, 1), ("physical.2", .energy, 1),
            ("physical.3", .stress, 0.5), ("physical.4", .stress, 1), ("physical.5", .stress, 0.5),
            ("physical.6", .stress, 1), ("social.1", .emotional, 1), ("social.2", .emotional, 0.5),
            ("social.3", .emotional, 0.5), ("social.3", .energy, 0.5), ("social.4", .emotional, 0.5),
            ("social.5", .stress, 0.5)
        ]
        for (id, goal, value) in symptomWeights where symptoms.contains(id) {
            weights[goal, default: 0] += value
        }

        // 5. GAD-7 anxiety check (measured, so it outweighs a single symptom)
        switch anxiety {
        case .mild: weights[.stress, default: 0] += 0.5
        case .moderate: weights[.stress, default: 0] += 1.5; weights[.emotional, default: 0] += 0.5
        case .severe: weights[.stress, default: 0] += 2.5; weights[.emotional, default: 0] += 1
        case .minimal, nil: break
        }

        // Primary goal: user override > reasons > Q11 > weights > stress
        let order = PlanGoal.allCases
        func best(_ candidates: [PlanGoal]) -> PlanGoal? {
            candidates.max { a, b in
                let wa = weights[a] ?? 0, wb = weights[b] ?? 0
                if wa != wb { return wa < wb }
                // Stable tie-break: earlier in `order` wins
                return (order.firstIndex(of: a) ?? 0) > (order.firstIndex(of: b) ?? 0)
            }
        }

        var primary: PlanGoal = .stress
        var origin: PlanAnalysis.GoalOrigin = .fallback
        if let overrideGoal {
            primary = overrideGoal; origin = .user
        } else if !reasonGoals.isEmpty, let goal = best(order.filter { reasonGoals[$0] != nil }) {
            primary = goal; origin = .reason
        } else if let quizGoal {
            primary = quizGoal; origin = .quiz
        } else if let goal = best(order), (weights[goal] ?? 0) > 0 {
            primary = goal; origin = .answers
        }

        let secondaryCandidates = order.filter { $0 != primary }
        var secondary = best(secondaryCandidates) ?? .stress
        if (weights[secondary] ?? 0) <= 0 { secondary = primary == .stress ? .sleep : .stress }

        // Chronicity & availability
        let duration = profile.durationCode ?? ""
        let gentle = duration == "1_year_plus" || duration == "years" || (scores.global.map { $0 < 30 } ?? false) || anxiety == .severe
        let availableMinutes: Int? = answers.count > 11 ? [10, 22, 37, 52, 75][safe: answers[11]] : profile.availableMinutes
        let compact = (availableMinutes ?? 22) < 15

        return PlanAnalysis(
            weights: weights,
            primary: primary,
            primaryOrigin: origin,
            secondary: secondary,
            gentle: gentle,
            compact: compact,
            recent: duration == "weeks",
            tension: symptoms.contains("physical.4") || (answers[safe: 3].map { $0 <= 1 } ?? false),
            palpitations: symptoms.contains("physical.6"),
            sleepIssue: symptoms.contains("physical.1") || (scores.sleep.map { $0 < 45 } ?? false),
            nightWaking: answers[safe: 2].map { $0 <= 1 } ?? false,
            racingMind: symptoms.contains("mental.3") || symptoms.contains("mental.1"),
            fatigue: symptoms.contains("physical.2") || (scores.energy.map { $0 < 40 } ?? false),
            isolation: symptoms.contains("social.1") || symptoms.contains("social.3"),
            senior: profile.ageCode == "55_plus",
            anxiety: anxiety
        )
    }

    private struct DomainScores {
        var stress: Int?, sleep: Int?, energy: Int?, focus: Int?
        var global: Int? {
            let all = [stress, sleep, energy, focus].compactMap { $0 }
            return all.isEmpty ? nil : all.reduce(0, +) / all.count
        }
    }

    /// Same scoring as HabitsQuizResult (Q1–Q8: option index → 15/40/70/100, higher = better).
    private static func domainScores(_ answers: [Int]) -> DomainScores {
        guard answers.count >= 8 else { return DomainScores() }
        let scale = [15, 40, 70, 100]
        func score(_ idx: [Int]) -> Int {
            idx.map { scale[safe: answers[$0]] ?? 40 }.reduce(0, +) / idx.count
        }
        return DomainScores(stress: score([0, 3, 5]), sleep: score([2, 6]), energy: score([1, 7]), focus: score([4]))
    }

    // MARK: - Durations

    /// Main audio cap per week (minutes).
    private static func audioCap(week: Int, analysis: PlanAnalysis, cycle: Int) -> Int {
        let w = min(4, week + (cycle > 1 ? 1 : 0)) - 1
        var caps = analysis.gentle ? [4, 6, 8, 10] : [5, 7, 10, 12]
        if analysis.compact { caps = zip(caps, [4, 5, 6, 8]).map { min($0, $1) } }
        return caps[max(0, min(3, w))]
    }

    private static func breathingTarget(week: Int, analysis: PlanAnalysis, cycle: Int) -> Int {
        let w = min(4, week + (cycle > 1 ? 1 : 0)) - 1
        let targets = analysis.gentle || analysis.compact ? [2, 2, 3, 4] : [2, 3, 4, 5]
        return targets[max(0, min(3, w))]
    }

    // MARK: - Breathing

    private static func breathingWeights(goal: PlanGoal, theme: PlanWeekTheme, analysis: PlanAnalysis) -> [BreathingCategory: Double] {
        var w: [BreathingCategory: Double]
        switch goal {
        case .stress: w = [.calm: 3, .sos: 2, .sleep: 0.5, .focus: 0.5]
        case .sleep: w = [.calm: 2.5, .sleep: 2.5, .sos: 0.5]
        case .energy: w = [.energy: 3, .calm: 1.5, .focus: 1.5]
        case .focus: w = [.focus: 3, .calm: 1.5, .energy: 0.5]
        case .emotional: w = [.calm: 3, .sos: 1.5, .sleep: 0.5]
        }
        if theme == .soothe { w[.sos, default: 0] += 0.5; w[.calm, default: 0] += 0.5 }
        if analysis.gentle || analysis.palpitations { w[.sos, default: 0] += 0.5; w[.energy] = (w[.energy] ?? 0) * 0.3 }
        if let anxiety = analysis.anxiety, anxiety >= .moderate { w[.calm, default: 0] += 0.5; w[.sos, default: 0] += 0.5 }
        return w
    }

    private static func pickBreathing(day: Int, week: Int, goal: PlanGoal, theme: PlanWeekTheme, analysis: PlanAnalysis, cycle: Int, history: inout UsageHistory, rng: inout SeededGenerator) -> PlanItem {
        let weights = breathingWeights(goal: goal, theme: theme, analysis: analysis)
        // Stimulating techniques are excluded when they may not be appropriate.
        let excludeIntense = analysis.gentle || analysis.palpitations || analysis.senior || week == 1
        let candidates = BreathingPattern.allPatterns
            .filter { !(excludeIntense && $0.key == "kapalabhati") && !analysis.excluded.contains($0.key) }
            .sorted { $0.key < $1.key }

        var bestPattern: BreathingPattern?
        var bestScore = -Double.infinity
        for pattern in candidates {
            let base = weights[pattern.category] ?? 0
            guard base > 0 else { continue }
            var score = base + history.penalty(pattern.key, day: day, recentWindow: 3, recentPenalty: 3, countPenalty: 0.35)
            score += rng.nextUnit() * 0.8
            if score > bestScore { bestScore = score; bestPattern = pattern }
        }
        let pattern = bestPattern ?? BreathingPattern.allPatterns.first ?? .deepAbdominal
        history.use(pattern.key, day: day)

        let target = breathingTarget(week: week, analysis: analysis, cycle: cycle)
        let choices = pattern.durationChoices.isEmpty ? [pattern.defaultMinutes] : pattern.durationChoices.sorted()
        // Nearest available duration to the weekly target (ties → the longer one).
        let minutes = choices.min { a, b in
            let da = abs(a - target), db = abs(b - target)
            return da != db ? da < db : a > b
        } ?? max(1, pattern.defaultMinutes)
        let shortMinutes = choices.first ?? 1

        return PlanItem(id: "breathing", kind: .breathing, refID: pattern.key, minutes: minutes,
                        shortRefID: nil, shortMinutes: shortMinutes < minutes ? shortMinutes : nil, variant: nil)
    }

    // MARK: - Audio

    private static func audioWeights(goal: PlanGoal, theme: PlanWeekTheme, analysis: PlanAnalysis, eveningPresent: Bool) -> [AudioSessionCategory: Double] {
        var w: [AudioSessionCategory: Double]
        switch goal {
        case .stress: w = [.stressSOS: 3, .bodyRelax: 2.5, .anxiety: 2, .workBreak: 2, .selfCompassion: 0.5, .morning: 0.5]
        case .sleep: w = [.bodyRelax: 3, .anxiety: 2, .stressSOS: 1.5, .workBreak: 1, .selfCompassion: 1]
        case .energy: w = [.morning: 3.5, .workBreak: 2, .bodyRelax: 1.5, .focus: 1, .stressSOS: 0.5]
        case .focus: w = [.focus: 3.5, .workBreak: 2.5, .morning: 1.5, .stressSOS: 0.5, .anxiety: 0.5]
        case .emotional: w = [.selfCompassion: 3.5, .anxiety: 2.5, .stressSOS: 1.5, .bodyRelax: 1, .morning: 0.5]
        }
        if goal == .sleep && !eveningPresent { w[.sleep] = 2.5 }
        switch theme {
        case .soothe: w[.stressSOS, default: 0] += 1; w[.bodyRelax, default: 0] += 0.5
        case .rituals: w[.morning, default: 0] += 1; w[.workBreak, default: 0] += 1
        case .deepen: w[.anxiety, default: 0] += 1; w[.selfCompassion, default: 0] += 0.5; w[.bodyRelax, default: 0] += 0.5
        case .anchor: w[.selfCompassion, default: 0] += 1; w[.morning, default: 0] += 0.5
        }
        if analysis.gentle { w[.selfCompassion, default: 0] += 1; w[.stressSOS, default: 0] += 0.5 }
        if analysis.tension { w[.bodyRelax, default: 0] += 1 }
        if analysis.racingMind { w[.anxiety, default: 0] += 0.5 }
        if let anxiety = analysis.anxiety, anxiety >= .moderate { w[.anxiety, default: 0] += 1; w[.stressSOS, default: 0] += 0.5 }
        return w
    }

    private static func pickAudio(day: Int, week: Int, goal: PlanGoal, theme: PlanWeekTheme, analysis: PlanAnalysis, cycle: Int, excluding: String?, eveningPresent: Bool, history: inout UsageHistory, rng: inout SeededGenerator) -> PlanItem {
        var weights = audioWeights(goal: goal, theme: theme, analysis: analysis, eveningPresent: eveningPresent)
        // Long-lasting stress: a self-compassion / SOS moment every 4 days.
        if analysis.gentle && day % 4 == 2 { weights[.selfCompassion, default: 0] += 3 }
        if eveningPresent { weights[.sleep] = 0 }

        let cap = audioCap(week: week, analysis: analysis, cycle: cycle)
        let catalog = GuidedSessionCatalog.all.filter { !analysis.excluded.contains($0.id) }.sorted { $0.id < $1.id }
        var fitting = catalog.filter { $0.durationMinutes <= cap && $0.id != excluding && (weights[$0.category] ?? 0) > 0 }
        if fitting.isEmpty {
            fitting = catalog.filter { $0.id != excluding && (weights[$0.category] ?? 0) > 0 }
                .sorted { $0.durationMinutes < $1.durationMinutes }
                .prefix(3).map { $0 }
        }

        var best: GuidedSession?
        var bestScore = -Double.infinity
        for session in fitting {
            var score = weights[session.category] ?? 0
            // Ramp: prefer sessions close to this week's cap.
            score += 1.5 * Double(session.durationMinutes) / Double(max(cap, 1))
            score += history.penalty(session.id, day: day, recentWindow: 6, recentPenalty: 6, countPenalty: 2)
            score += rng.nextUnit() * 0.6
            if score > bestScore { bestScore = score; best = session }
        }
        let session = best ?? GuidedSessionCatalog.session(id: "sos-reset-3") ?? catalog.first
        let id = session?.id ?? "sos-reset-3"
        let minutes = session?.durationMinutes ?? 3
        history.use(id, day: day)

        // Short version for busy days
        var shortID: String?
        var shortMinutes: Int?
        if minutes > 4 {
            let shortPool: [String]
            switch goal {
            case .energy: shortPool = ["morning-energy-4", "work-desk-reset-3", "sos-reset-3"]
            case .focus: shortPool = ["focus-before-task-4", "work-desk-reset-3", "sos-reset-3"]
            case .emotional: shortPool = ["compassion-kind-pause-5", "sos-reset-3", "sos-panic-anchor-4"]
            case .sleep: shortPool = ["body-shoulders-jaw-5", "sos-reset-3", "work-desk-reset-3"]
            case .stress: shortPool = analysis.palpitations
                ? ["sos-panic-anchor-4", "sos-reset-3", "work-desk-reset-3"]
                : ["sos-reset-3", "work-desk-reset-3", "sos-panic-anchor-4"]
            }
            let available = shortPool.compactMap(GuidedSessionCatalog.session(id:)).filter { $0.id != id }
            if !available.isEmpty {
                let pick = available[(day - 1) % available.count]
                if pick.durationMinutes < minutes {
                    shortID = pick.id
                    shortMinutes = pick.durationMinutes
                }
            }
        }

        return PlanItem(id: "meditation", kind: .audio, refID: id, minutes: minutes,
                        shortRefID: shortID, shortMinutes: shortMinutes, variant: nil)
    }

    // MARK: - Evening wind-down (sleep goal)

    private static func hasEvening(day: Int, analysis: PlanAnalysis) -> Bool {
        if analysis.primary == .sleep { return true }
        if analysis.secondary == .sleep { return day % 2 == 1 }
        return false
    }

    private static func pickEvening(day: Int, week: Int, analysis: PlanAnalysis, cycle: Int, history: inout UsageHistory, rng: inout SeededGenerator) -> PlanItem {
        let w = min(4, week + (cycle > 1 ? 1 : 0)) - 1
        let caps = analysis.gentle || analysis.compact ? [8, 10, 10, 12] : [10, 10, 12, 15]
        let cap = caps[max(0, min(3, w))]

        var candidates = GuidedSessionCatalog.sessions(in: .sleep)
        candidates += ["body-pmr-8", "body-scan-10", "body-yoga-nidra-15"].compactMap(GuidedSessionCatalog.session(id:))
        candidates = candidates.filter { !analysis.excluded.contains($0.id) }.sorted { $0.id < $1.id }
        var fitting = candidates.filter { $0.durationMinutes <= cap }
        if fitting.isEmpty { fitting = Array(candidates.sorted { $0.durationMinutes < $1.durationMinutes }.prefix(1)) }

        var best: GuidedSession?
        var bestScore = -Double.infinity
        for session in fitting {
            var score: Double = session.category == .sleep ? 3 : 1.5
            if session.id == "sleep-racing-mind-12" && analysis.racingMind { score += 1 }
            if session.id == "sleep-back-to-sleep-8" && analysis.nightWaking { score += 1 }
            if session.id == "body-pmr-8" && analysis.tension { score += 1 }
            score += 1.0 * Double(session.durationMinutes) / Double(cap)
            score += history.penalty(session.id, day: day, recentWindow: 2, recentPenalty: 4, countPenalty: 0.6)
            score += rng.nextUnit() * 0.6
            if score > bestScore { bestScore = score; best = session }
        }
        let id = best?.id ?? "sleep-wind-down-10"
        history.use(id, day: day)
        return PlanItem(id: "meditation_evening", kind: .evening, refID: id, minutes: best?.durationMinutes ?? 10,
                        shortRefID: nil, shortMinutes: nil, variant: nil)
    }

    // MARK: - Habits

    static let habitIDs = ["sleep", "water", "sport", "nature", "social", "journal"]

    private static func habitWeights(_ goal: PlanGoal) -> [String: Double] {
        switch goal {
        case .stress: return ["nature": 3, "sport": 2, "journal": 2, "social": 1, "water": 1, "sleep": 1]
        case .sleep: return ["sleep": 4, "journal": 2, "nature": 1, "water": 1, "sport": 1]
        case .energy: return ["water": 3, "sport": 3, "nature": 2, "sleep": 2, "social": 1]
        case .focus: return ["nature": 2, "water": 2, "sleep": 2, "journal": 2, "sport": 1]
        case .emotional: return ["journal": 3, "social": 3, "nature": 2, "sleep": 1]
        }
    }

    private static func combinedHabitWeights(_ analysis: PlanAnalysis) -> [String: Double] {
        var w: [String: Double] = [:]
        let p = habitWeights(analysis.primary), s = habitWeights(analysis.secondary)
        for id in habitIDs { w[id] = (p[id] ?? 0) + 0.5 * (s[id] ?? 0) }
        if analysis.sleepIssue { w["sleep", default: 0] += 1 }
        if analysis.fatigue { w["water", default: 0] += 0.5; w["sport", default: 0] += 0.5 }
        if analysis.isolation { w["social", default: 0] += 1 }
        if analysis.tension { w["nature", default: 0] += 0.5 }
        for id in analysis.excluded where w[id] != nil { w[id] = 0 }
        return w
    }

    /// Habits ordered by relevance (stable).
    static func rankedHabits(_ analysis: PlanAnalysis) -> [String] {
        let w = combinedHabitWeights(analysis)
        return habitIDs.filter { !analysis.excluded.contains($0) }.sorted { a, b in
            let wa = w[a] ?? 0, wb = w[b] ?? 0
            return wa != wb ? wa > wb : (habitIDs.firstIndex(of: a)! < habitIDs.firstIndex(of: b)!)
        }
    }

    private static func pickHabits(day: Int, week: Int, analysis: PlanAnalysis, anchor: String, history: inout UsageHistory, rng: inout SeededGenerator) -> [PlanItem] {
        let weights = combinedHabitWeights(analysis)
        let count: Int = {
            if analysis.compact { return 2 }
            if week == 1 { return 2 }
            if analysis.gentle && week == 2 { return 2 }
            return 3
        }()
        let weekStart = (week - 1) * 7 + 1
        let sportCap = analysis.gentle ? 2 : 3

        var chosen: [String] = [anchor]
        while chosen.count < count {
            var best: String?
            var bestScore = -Double.infinity
            for id in habitIDs where !chosen.contains(id) {
                let base = weights[id] ?? 0
                guard base > 0 else { continue }
                let usedThisWeek = history.count(id, from: weekStart)
                if id == "sport" && usedThisWeek >= sportCap { continue }
                if id == "social" && usedThisWeek >= 3 { continue }
                let since = Double(history.daysSinceLast(id, day: day) ?? 7)
                var score = base * (1 + min(since, 7) * 0.35)
                if since <= 1 { score *= 0.3 }
                score += rng.nextUnit() * 0.8
                if score > bestScore { bestScore = score; best = id }
            }
            guard let pick = best else { break }
            chosen.append(pick)
        }

        return chosen.map { id in
            let uses = history.totalCount(id)
            history.use(id, day: day)
            var variant: Int?
            switch id {
            case "sport":
                // Gentle plans favour soft activities: dance, stretching, swimming.
                let allowed = analysis.gentle || analysis.palpitations || analysis.senior ? [2, 1, 3] : [2, 5, 1, 4, 3, 0]
                variant = allowed[uses % allowed.count]
            case "nature": variant = uses % 3
            case "social": variant = uses % 6
            default: variant = nil
            }
            return PlanItem(id: "habit_\(id)", kind: .habit, refID: id, minutes: 0,
                            shortRefID: nil, shortMinutes: nil, variant: variant)
        }
    }

    // MARK: - Alternatives (plan editing)

    /// Replacement candidates for one item of a day, best first: same kind, suited to the
    /// plan's goal, not already in the day, not excluded by the user. The returned items keep
    /// the slot id (so completion keys stay stable), except habits which are keyed by habit.
    static func alternatives(for item: PlanItem, in plan: PersonalPlan, dayNumber: Int, anxiety: AnxietySeverity? = nil, limit: Int = 5) -> [PlanItem] {
        guard let day = plan.day(dayNumber) else { return [] }
        var analysis = analyze(plan.profile, overrideGoal: plan.goal, anxiety: anxiety)
        analysis.excluded = plan.excludedRefIDs
        let theme = PlanWeekTheme.forWeek(day.week)
        let usedRefs = Set(day.items.map(\.refID))

        switch item.kind {
        case .breathing:
            let weights = breathingWeights(goal: plan.goal, theme: theme, analysis: analysis)
            let excludeIntense = analysis.gentle || analysis.palpitations || analysis.senior || day.week == 1
            return BreathingPattern.allPatterns
                .filter { !usedRefs.contains($0.key) && !analysis.excluded.contains($0.key) }
                .filter { !(excludeIntense && $0.key == "kapalabhati") }
                .sorted { a, b in
                    let wa = weights[a.category] ?? 0, wb = weights[b.category] ?? 0
                    return wa != wb ? wa > wb : a.key < b.key
                }
                .prefix(limit)
                .map { pattern in
                    let choices = pattern.durationChoices.isEmpty ? [pattern.defaultMinutes] : pattern.durationChoices.sorted()
                    let minutes = choices.min { abs($0 - item.minutes) < abs($1 - item.minutes) } ?? max(1, pattern.defaultMinutes)
                    let shortest = choices.first ?? minutes
                    return PlanItem(id: item.id, kind: .breathing, refID: pattern.key, minutes: minutes,
                                    shortRefID: nil, shortMinutes: shortest < minutes ? shortest : nil, variant: nil)
                }

        case .audio, .evening:
            let pool: [GuidedSession]
            var weights: [AudioSessionCategory: Double]
            if item.kind == .evening {
                pool = GuidedSessionCatalog.sessions(in: .sleep)
                    + ["body-pmr-8", "body-scan-10", "body-yoga-nidra-15"].compactMap(GuidedSessionCatalog.session(id:))
                weights = [.sleep: 3, .bodyRelax: 1.5]
            } else {
                pool = GuidedSessionCatalog.all
                weights = audioWeights(goal: plan.goal, theme: theme, analysis: analysis, eveningPresent: day.items.contains { $0.kind == .evening })
            }
            let cap = max(item.minutes + 3, 5)
            return pool
                .filter { !usedRefs.contains($0.id) && !analysis.excluded.contains($0.id) && (weights[$0.category] ?? 0) > 0 }
                .sorted { a, b in
                    // Relevance first, then closest to the replaced session's length.
                    let sa = (weights[a.category] ?? 0) - (a.durationMinutes > cap ? 2 : 0) - Double(abs(a.durationMinutes - item.minutes)) * 0.15
                    let sb = (weights[b.category] ?? 0) - (b.durationMinutes > cap ? 2 : 0) - Double(abs(b.durationMinutes - item.minutes)) * 0.15
                    return sa != sb ? sa > sb : a.id < b.id
                }
                .prefix(limit)
                .map { PlanItem(id: item.id, kind: item.kind, refID: $0.id, minutes: $0.durationMinutes,
                                shortRefID: nil, shortMinutes: nil, variant: nil) }

        case .habit:
            let used = Set(day.items.filter { $0.kind == .habit }.map(\.refID))
            return rankedHabits(analysis)
                .filter { !used.contains($0) }
                .prefix(limit)
                .map { PlanItem(id: "habit_\($0)", kind: .habit, refID: $0, minutes: 0,
                                shortRefID: nil, shortMinutes: nil, variant: 0) }
        }
    }

    // MARK: - Insights ("why this plan")

    private static func insights(for analysis: PlanAnalysis, profile: PlanProfile, anchorHabit: String) -> [String] {
        var result: [String] = []
        switch analysis.primaryOrigin {
        case .reason: result.append("primary_reason:\(analysis.primary.rawValue)")
        case .quiz: result.append("primary_quiz:\(analysis.primary.rawValue)")
        case .answers: result.append("primary_answers:\(analysis.primary.rawValue)")
        case .user: result.append("primary_user:\(analysis.primary.rawValue)")
        case .fallback: result.append("primary_default")
        }
        if analysis.secondary != analysis.primary {
            result.append("secondary:\(analysis.secondary.rawValue)")
        }
        if analysis.gentle { result.append("gentle") } else if analysis.recent { result.append("recent") }
        if analysis.compact { result.append("compact") }
        if analysis.tension { result.append("tension") }
        if analysis.palpitations { result.append("palpitations") }
        if analysis.primary == .sleep || analysis.secondary == .sleep { result.append("evening") }
        if analysis.racingMind { result.append("racing_mind") }
        if analysis.isolation { result.append("isolation") }
        // No band in the code: the plan is mirrored to Firestore.
        if analysis.anxiety != nil { result.append("anxiety_check") }
        result.append("anchor:\(anchorHabit)")
        result.append("progression")
        return result
    }

    // MARK: - Helpers

    static func fingerprint(_ profile: PlanProfile) -> String {
        [
            profile.reasonCodes.sorted().joined(separator: ","),
            profile.durationCode ?? "-",
            profile.ageCode ?? "-",
            (profile.quizAnswers ?? []).map(String.init).joined(separator: ","),
            profile.symptomIDs.sorted().joined(separator: ","),
            profile.improvementGoal ?? "-",
            profile.availableMinutes.map(String.init) ?? "-"
        ].joined(separator: "|")
    }
}

// MARK: - Usage history

private struct UsageHistory {
    private var uses: [String: [Int]] = [:]

    mutating func use(_ id: String, day: Int) { uses[id, default: []].append(day) }

    func totalCount(_ id: String) -> Int { uses[id]?.count ?? 0 }

    func count(_ id: String, from day: Int) -> Int { uses[id]?.filter { $0 >= day }.count ?? 0 }

    func daysSinceLast(_ id: String, day: Int) -> Int? { uses[id]?.last.map { day - $0 } }

    /// Negative score: strong penalty if used recently, mild penalty per previous use.
    func penalty(_ id: String, day: Int, recentWindow: Int, recentPenalty: Double, countPenalty: Double) -> Double {
        var p = -Double(totalCount(id)) * countPenalty
        if let since = daysSinceLast(id, day: day), since <= recentWindow {
            p -= recentPenalty * Double(recentWindow - since + 1) / Double(recentWindow)
        }
        return p
    }
}

// MARK: - Seeded RNG (SplitMix64 over FNV-1a; stable across launches)

struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: String) {
        var hash: UInt64 = 0xcbf29ce484222325
        for byte in seed.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x100000001b3
        }
        state = hash
    }

    mutating func next() -> UInt64 {
        state = state &+ 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }

    mutating func nextUnit() -> Double {
        Double(next() >> 11) / Double(1 << 53)
    }
}
