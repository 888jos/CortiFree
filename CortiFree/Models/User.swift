//
//  User.swift
//  CortiFree
//
//  Created by Claude on 22/10/2025.
//

import Foundation
import FirebaseFirestore

struct User: Codable, Identifiable {
    @DocumentID var id: String?
    var name: String
    var level: Int
    var xp: Int
    var goalType: String
    var tasksCompletedThisWeek: Int
    var createdAt: Timestamp

    init(id: String? = nil,
         name: String = "",
         level: Int = 1,
         xp: Int = 0,
         goalType: String = "equilibre",
         tasksCompletedThisWeek: Int = 0,
         createdAt: Timestamp = Timestamp()) {
        self.id = id
        self.name = name
        self.level = level
        self.xp = xp
        self.goalType = goalType
        self.tasksCompletedThisWeek = tasksCompletedThisWeek
        self.createdAt = createdAt
    }

    var xpProgress: Double {
        let xpInCurrentLevel = xp % 100
        return Double(xpInCurrentLevel) / 100.0
    }

    var xpToNextLevel: Int {
        return 100 - (xp % 100)
    }
}
