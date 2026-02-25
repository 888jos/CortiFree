//
//  WidgetDataStore.swift
//  CortiFree
//
//  Modèle partagé entre l'app et le widget via AppGroup.
//  Ce fichier doit être ajouté aux deux targets : CortiFree + CortiFreeWidget
//  AppGroup: group.com.solstys.cortifree
//

import Foundation
import WidgetKit

// MARK: - Modèle de tâche simplifié pour le widget

struct WidgetTask: Codable, Identifiable {
    let id: String
    let title: String
    let emoji: String       // conservé pour compatibilité
    let sfSymbol: String    // icône SF Symbols utilisée dans le widget
    let completed: Bool
    let cancelled: Bool
    let recommendedTime: String?
    var habitId: String?    // pour grouper les sous-tâches (ex: sleep_morning + sleep_night → "sleep")
}

// MARK: - Persistance partagée via AppGroup

struct WidgetDataStore {
    static let appGroupID = "group.com.solstys.cortifree"
    static let tasksKey = "widget_tasks"
    static let programStartDateKey = "widget_programStartDate"
    static let programDayKey = "widget_programDay"

    static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    /// Sauvegarde les tâches + le jour calculé depuis l'app principale
    /// Le jour est passé directement (calculé par UserSettings.currentProgramDay)
    /// pour éviter tout décalage de recalcul dans le widget.
    static func saveTasks(_ tasks: [WidgetTask], programDay: Int? = nil) {
        guard let defaults = sharedDefaults else { return }
        if let encoded = try? JSONEncoder().encode(tasks) {
            defaults.set(encoded, forKey: tasksKey)
        }
        // Sauvegarde le jour exact tel que calculé dans l'app
        if let day = programDay {
            defaults.set(day, forKey: programDayKey)
        }
        // Sauvegarde aussi la startDate pour le recalcul à minuit
        if let startDate = UserDefaults.standard.object(forKey: "programStartDate") as? Date {
            defaults.set(startDate, forKey: programStartDateKey)
        }
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// Lit les tâches depuis le widget
    static func loadTasks() -> [WidgetTask] {
        guard let defaults = sharedDefaults,
              let data = defaults.data(forKey: tasksKey),
              let tasks = try? JSONDecoder().decode([WidgetTask].self, from: data)
        else { return [] }
        return tasks
    }

    /// Lit le jour actuel du programme (1-based, heure locale user).
    /// Priorité : jour sauvegardé par l'app → recalcul depuis startDate → fallback 1.
    static func currentProgramDay() -> Int {
        guard let defaults = sharedDefaults else { return 1 }
        // Si l'app a sauvegardé le jour calculé aujourd'hui, on l'utilise tel quel
        let savedDay = defaults.integer(forKey: programDayKey)
        if savedDay > 0 {
            // Vérifier que le jour sauvegardé correspond toujours au bon jour calendaire
            // (cas : minuit passé depuis le dernier sync app → +1)
            if let startDate = defaults.object(forKey: programStartDateKey) as? Date {
                let recalculated = max(1, (Calendar.current.dateComponents([.day], from: startDate, to: Date()).day ?? 0) + 1)
                return recalculated
            }
            return savedDay
        }
        // Fallback : recalcul depuis startDate
        guard let startDate = defaults.object(forKey: programStartDateKey) as? Date else { return 1 }
        let days = Calendar.current.dateComponents([.day], from: startDate, to: Date()).day ?? 0
        return max(1, days + 1)
    }
}
