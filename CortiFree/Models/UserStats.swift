//
//  UserStats.swift
//  CortiFree
//
//  Created by Claude on 22/10/2025.
//

import Foundation
import FirebaseFirestore

struct UserStats: Codable {
    var streak: Int
    var lastUpdated: Timestamp
    var history: [String: Double] // Date string: completion rate
    var totalTasksCompleted: Int

    init(streak: Int = 0,
         lastUpdated: Timestamp = Timestamp(),
         history: [String: Double] = [:],
         totalTasksCompleted: Int = 0) {
        self.streak = streak
        self.lastUpdated = lastUpdated
        self.history = history
        self.totalTasksCompleted = totalTasksCompleted
    }

    func historyFor(days: Int) -> [(date: Date, rate: Double)] {
        let calendar = Calendar.current
        let now = Date()

        return (0..<days).compactMap { dayOffset in
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: now) ?? now
            let dateString = dateFormatter.string(from: date)
            let rate = history[dateString] ?? 0.0
            return (date, rate)
        }.reversed()
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }
}

struct DailyProgress {
    let date: Date
    let completionRate: Double
}
