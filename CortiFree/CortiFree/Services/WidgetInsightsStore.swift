//
//  WidgetInsightsStore.swift
//  CortiFree
//
//  Données partagées app ↔ widgets « viraux » (Milo, Respire, Planète, Cortisol, Humeur,
//  Message de Milo, Streak) via l'AppGroup de WidgetDataStore.
//  Fichier membre des deux targets : CortiFree + CortiFreeWidgetExtension.
//

import Foundation
import WidgetKit

// MARK: - Humeur (miroir de `Mood`, qui n'est pas dans la target widget)

enum WidgetMood: String, CaseIterable, Codable {
    case awful, angry, low, okay, good, amazing

    var emoji: String {
        switch self {
        case .awful: return "😭"
        case .angry: return "😤"
        case .low: return "😔"
        case .okay: return "😐"
        case .good: return "🙂"
        case .amazing: return "😊"
        }
    }

    /// Même palette que `Mood.color`.
    var hex: UInt32 {
        switch self {
        case .awful: return 0xE63946
        case .angry: return 0xF77F00
        case .low: return 0xFCBF49
        case .okay: return 0x90E0EF
        case .good: return 0x06D6A0
        case .amazing: return 0x7209B7
        }
    }

    /// Effet sur l'estimation de cortisol (points).
    fileprivate var cortisolImpact: Double {
        switch self {
        case .awful: return 14
        case .angry: return 12
        case .low: return 6
        case .okay: return 0
        case .good: return -6
        case .amazing: return -10
        }
    }
}

// MARK: - États de Milo

enum MiloState: String, CaseIterable {
    case sleeping, stressed, tired, proud, morning, chill

    var overlaySymbol: String {
        switch self {
        case .sleeping: return "zzz"
        case .stressed: return "bolt.heart.fill"
        case .tired: return "battery.25percent"
        case .proud: return "sparkles"
        case .morning: return "sun.max.fill"
        case .chill: return "leaf.fill"
        }
    }

    var quoteCount: Int { 3 }
}

// MARK: - Instantané calculé pour les widgets

struct WidgetInsights {
    let date: Date
    let streak: Int
    let bestStreak: Int
    let programDay: Int
    let todayProgress: Double          // 0…1, tâches du jour
    let breathsToday: Int
    let moods: [String: WidgetMood]    // "yyyy-MM-dd" → humeur
    let lastStress: Int?               // 1…5, check-in récent
    let dayProgress: [String: Double]  // "yyyy-MM-dd" → 0…1

    var todayMood: WidgetMood? { moods[WidgetInsightsStore.dayKey(date)] }

    // MARK: Météo intérieure (score ludique tiré des check-ins, jamais affiché comme une mesure)

    var cortisolLevel: Int {
        var level = 52.0
        if let lastStress { level += Double(lastStress - 3) * 10 }
        if let todayMood { level += todayMood.cortisolImpact }
        level -= todayProgress * 26
        level -= Double(min(breathsToday, 3)) * 6
        let hour = Calendar.current.component(.hour, from: date)
        if (6..<10).contains(hour) { level += 8 }      // pic matinal naturel
        if hour >= 20 || hour < 2 { level -= 5 }
        return Int(min(95, max(8, level)).rounded())
    }

    /// 0 = zen, 1 = sous contrôle, 2 = ça monte, 3 = alerte
    var cortisolTier: Int {
        switch cortisolLevel {
        case ..<30: return 0
        case ..<55: return 1
        case ..<75: return 2
        default: return 3
        }
    }

    // MARK: Milo

    var miloState: MiloState {
        let hour = Calendar.current.component(.hour, from: date)
        if hour >= 23 || hour < 6 { return .sleeping }
        if todayProgress >= 0.8 { return .proud }
        if cortisolLevel >= 72 { return .stressed }
        if hour >= 18 && todayProgress < 0.2 && breathsToday == 0 { return .tired }
        if hour < 11 { return .morning }
        return .chill
    }

    /// Phrase du jour stable sur la journée (change avec l'état de Milo).
    var miloQuoteKey: String {
        let state = miloState
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: date) ?? 0
        return "widget.quote.\(state.rawValue).\(dayOfYear % state.quoteCount)"
    }

    // MARK: Streak

    static let milestones = [3, 7, 14, 21, 30, 50, 66, 100, 200, 365]

    var nextMilestone: Int { Self.milestones.first { $0 > streak } ?? (streak + 100) }

    // MARK: Données de démo (simulateur, galerie Réglages, placeholder)

    static var sample: WidgetInsights {
        let cal = Calendar.current
        let today = Date()
        var moods: [String: WidgetMood] = [:]
        var progress: [String: Double] = [:]
        let cycle: [WidgetMood] = [.good, .okay, .amazing, .low, .good, .good, .angry, .amazing, .okay, .good]
        for offset in 0..<40 {
            guard let day = cal.date(byAdding: .day, value: -offset, to: today) else { continue }
            moods[WidgetInsightsStore.dayKey(day)] = cycle[offset % cycle.count]
            progress[WidgetInsightsStore.dayKey(day)] = [1, 0.75, 0.5, 1, 0.85, 0.6, 1][offset % 7]
        }
        return WidgetInsights(date: today, streak: 12, bestStreak: 21, programDay: 12,
                              todayProgress: 0.6, breathsToday: 1, moods: moods,
                              lastStress: 3, dayProgress: progress)
    }
}

// MARK: - Store AppGroup

enum WidgetInsightsStore {
    private static let streakKey = "insights_streak"
    private static let bestStreakKey = "insights_bestStreak"
    private static let moodsKey = "insights_moods"
    private static let stressKey = "insights_lastStress"
    private static let stressDateKey = "insights_lastStressDate"
    private static let breathsKey = "insights_breaths"            // [dayKey: count]
    private static let breathStartKey = "insights_breathStart"
    private static let dayProgressKey = "insights_dayProgress"    // [dayKey: Double]
    static let languageKey = "insights_language"

    /// Durée d'une session « Respire » : 4 cycles de respiration carrée 4-4-4-4.
    static let breathPhaseSeconds: TimeInterval = 4
    static let breathSessionSeconds: TimeInterval = 64

    private static var defaults: UserDefaults? { WidgetDataStore.sharedDefaults }

    // MARK: Lecture

    static func load(at date: Date = Date()) -> WidgetInsights {
        let defaults = defaults
        let moodsRaw = defaults?.dictionary(forKey: moodsKey) as? [String: String] ?? [:]
        let moods = moodsRaw.compactMapValues(WidgetMood.init(rawValue:))
        let breaths = defaults?.dictionary(forKey: breathsKey) as? [String: Int] ?? [:]
        let progress = defaults?.dictionary(forKey: dayProgressKey) as? [String: Double] ?? [:]

        var lastStress: Int?
        if let stressDate = defaults?.object(forKey: stressDateKey) as? Date,
           date.timeIntervalSince(stressDate) < 36 * 3600 {
            let value = defaults?.integer(forKey: stressKey) ?? 0
            lastStress = value > 0 ? value : nil
        }

        let tasks = WidgetDataStore.loadTasks()
        return WidgetInsights(
            date: date,
            streak: defaults?.integer(forKey: streakKey) ?? 0,
            bestStreak: defaults?.integer(forKey: bestStreakKey) ?? 0,
            programDay: WidgetDataStore.currentProgramDay(),
            todayProgress: tasks.isEmpty ? (progress[dayKey(date)] ?? 0) : taskProgress(tasks),
            breathsToday: breaths[dayKey(date)] ?? 0,
            moods: moods,
            lastStress: lastStress,
            dayProgress: progress
        )
    }

    static var breathStart: Date? { defaults?.object(forKey: breathStartKey) as? Date }

    // MARK: Écriture (app)

    static func setStreak(_ streak: Int, best: Int) {
        defaults?.set(streak, forKey: streakKey)
        defaults?.set(max(best, streak), forKey: bestStreakKey)
        reload()
    }

    static func recordCheckIn(moodRaw: String, stress: Int, for date: Date) {
        recordMood(moodRaw, for: date, reload: false)
        defaults?.set(stress, forKey: stressKey)
        defaults?.set(Date(), forKey: stressDateKey)
        reload()
    }

    /// Appelé par WidgetDataStore.saveTasks : garde l'historique de progression par jour.
    static func recordTodayProgress(from tasks: [WidgetTask]) {
        guard let defaults else { return }
        var progress = defaults.dictionary(forKey: dayProgressKey) as? [String: Double] ?? [:]
        progress[dayKey(Date())] = taskProgress(tasks)
        defaults.set(trimmed(progress), forKey: dayProgressKey)
    }

    /// La langue choisie dans l'app, pour que les widgets parlent la même langue.
    static func mirrorLanguage(_ code: String) {
        guard defaults?.string(forKey: languageKey) != code else { return }
        defaults?.set(code, forKey: languageKey)
        reload()
    }

    // MARK: Écriture (widgets interactifs)

    static func recordMood(_ raw: String, for date: Date = Date(), reload shouldReload: Bool = true) {
        guard let defaults, WidgetMood(rawValue: raw) != nil else { return }
        var moods = defaults.dictionary(forKey: moodsKey) as? [String: String] ?? [:]
        moods[dayKey(date)] = raw
        defaults.set(trimmed(moods), forKey: moodsKey)
        if shouldReload { reload() }
    }

    static func startBreathing(at date: Date = Date()) {
        guard let defaults else { return }
        defaults.set(date, forKey: breathStartKey)
        var breaths = defaults.dictionary(forKey: breathsKey) as? [String: Int] ?? [:]
        breaths[dayKey(date), default: 0] += 1
        defaults.set(trimmed(breaths), forKey: breathsKey)
        reload()
    }

    static func stopBreathing() {
        defaults?.removeObject(forKey: breathStartKey)
        reload()
    }

    // MARK: Outils

    static func reload() { WidgetCenter.shared.reloadAllTimelines() }

    static func dayKey(_ date: Date) -> String { dayFormatter.string(from: date) }

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    /// Même règle que le widget tâches : sous-tâches d'une habitude au prorata.
    static func taskProgress(_ tasks: [WidgetTask]) -> Double {
        var groups = [String: [WidgetTask]]()
        for task in tasks { groups[task.habitId ?? task.id, default: []].append(task) }
        guard !groups.isEmpty else { return 0 }
        let score = groups.values.reduce(0.0) { sum, subtasks in
            sum + Double(subtasks.filter(\.completed).count) / Double(subtasks.count)
        }
        return score / Double(groups.count)
    }

    /// Ne garde que ~13 mois d'historique (les clés "yyyy-MM-dd" se trient chronologiquement).
    private static func trimmed<Value>(_ dict: [String: Value]) -> [String: Value] {
        guard dict.count > 400 else { return dict }
        let kept = dict.keys.sorted().suffix(400)
        return dict.filter { kept.contains($0.key) }
    }
}

// MARK: - Localisation partagée

/// Les widgets suivent la langue choisie dans l'app (pas seulement celle du système).
/// Les clés existent dans les Localizable.strings de l'app et du widget.
enum WidgetL10n {
    static func string(_ key: String) -> String {
        let code = WidgetDataStore.sharedDefaults?.string(forKey: WidgetInsightsStore.languageKey)
            ?? UserDefaults.standard.string(forKey: "selectedLanguage")
        for candidate in [code, "en"].compactMap({ $0 }) {
            if let path = Bundle.main.path(forResource: candidate, ofType: "lproj"),
               let bundle = Bundle(path: path) {
                let value = bundle.localizedString(forKey: key, value: nil, table: nil)
                if value != key { return value }
            }
        }
        return NSLocalizedString(key, comment: "")
    }

    static func format(_ key: String, _ args: CVarArg...) -> String {
        String(format: string(key), arguments: args)
    }
}
