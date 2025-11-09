//
//  DefaultTasks.swift
//  CortiFree
//
//  Created by Claude on 22/10/2025.
//

import Foundation

enum DefaultTasks {
    static let morning: [TaskItem] = [
        TaskItem(
            title: "Respiration guidée 5 min",
            category: .morning,
            goalType: "equilibre"
        ),
        TaskItem(
            title: "Méditation du matin",
            category: .morning,
            goalType: "equilibre"
        ),
        TaskItem(
            title: "3 choses pour lesquelles être reconnaissant",
            category: .morning,
            goalType: "equilibre"
        )
    ]

    static let day: [TaskItem] = [
        TaskItem(
            title: "Pause respiration midi (5 min)",
            category: .day,
            goalType: "equilibre"
        ),
        TaskItem(
            title: "Marche en pleine conscience (10 min)",
            category: .day,
            goalType: "equilibre"
        ),
        TaskItem(
            title: "Cohérence cardiaque (5 min)",
            category: .day,
            goalType: "equilibre"
        ),
        TaskItem(
            title: "Pause écrans (15 min)",
            category: .day,
            goalType: "equilibre"
        )
    ]

    static let night: [TaskItem] = [
        TaskItem(
            title: "Routine du soir (étirements)",
            category: .night,
            goalType: "equilibre"
        ),
        TaskItem(
            title: "Méditation de relaxation",
            category: .night,
            goalType: "equilibre"
        ),
        TaskItem(
            title: "Journal de gratitude",
            category: .night,
            goalType: "equilibre"
        ),
        TaskItem(
            title: "Lecture avant sommeil",
            category: .night,
            goalType: "equilibre"
        )
    ]

    static var all: [TaskItem] {
        morning + day + night
    }
}
