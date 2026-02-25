//
//  WidgetTaskEntry.swift
//  CortiFreeWidget
//

import Foundation
import WidgetKit

struct CortiFreeWidgetEntry: TimelineEntry {
    let date: Date
    let tasks: [WidgetTask]
    let completedCount: Int
    let totalCount: Int
    let programDay: Int

    static var placeholder: CortiFreeWidgetEntry {
        // sleep_morning + sleep_night partagent le même habitId "sleep" → comptent comme 1
        let tasks: [WidgetTask] = [
            WidgetTask(id: "1", title: "Se lever avant 7h",    emoji: "🌅", sfSymbol: "sunrise.fill",          completed: true,  cancelled: false, recommendedTime: "07:00", habitId: "sleep"),
            WidgetTask(id: "2", title: "Méditer 5 minutes",    emoji: "🧘", sfSymbol: "figure.mind.and.body",  completed: true,  cancelled: false, recommendedTime: "08:00", habitId: "meditation"),
            WidgetTask(id: "3", title: "Boire un verre d'eau", emoji: "💧", sfSymbol: "drop.fill",             completed: false, cancelled: false, recommendedTime: "12:00", habitId: "water"),
            WidgetTask(id: "4", title: "S'étirer doucement",   emoji: "🤸", sfSymbol: "figure.run",            completed: false, cancelled: true,  recommendedTime: "15:00", habitId: "sport"),
            WidgetTask(id: "5", title: "Écrire son journal",   emoji: "📓", sfSymbol: "book.fill",             completed: false, cancelled: false, recommendedTime: "18:00", habitId: "journal"),
            WidgetTask(id: "6", title: "Marche en nature",     emoji: "🌿", sfSymbol: "leaf.fill",             completed: false, cancelled: false, recommendedTime: "19:00", habitId: "nature"),
            WidgetTask(id: "7", title: "Se coucher avant 23h", emoji: "🌙", sfSymbol: "moon.zzz.fill",         completed: false, cancelled: false, recommendedTime: "23:00", habitId: "sleep"),
            WidgetTask(id: "8", title: "Appeler un ami",       emoji: "🤝", sfSymbol: "person.2.fill",         completed: false, cancelled: false, recommendedTime: "20:00", habitId: "social"),
        ]
        // Grouper par habitId — validé seulement si TOUTES les sous-tâches sont complétées
        var groups = [String: [WidgetTask]]()
        for task in tasks {
            let key = task.habitId ?? task.id
            groups[key, default: []].append(task)
        }
        let totalCount = groups.count
        let completedCount = groups.values.filter { $0.allSatisfy { $0.completed } }.count
        return CortiFreeWidgetEntry(
            date: Date(),
            tasks: tasks,
            completedCount: completedCount,
            totalCount: totalCount,
            programDay: 12
        )
    }
}
