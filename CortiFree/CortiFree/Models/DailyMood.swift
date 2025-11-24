//
//  DailyMood.swift
//  CortiFree
//
//  Created by Claude on 24/11/2025.
//  Model for tracking daily mood selections
//

import Foundation

struct DailyMood: Codable, Identifiable {
    var id: String // Format: "YYYY-MM-DD"
    let date: Date
    let mood: Mood
    let timestamp: Date

    init(date: Date = Date(), mood: Mood) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        self.id = formatter.string(from: date)
        self.date = date
        self.mood = mood
        self.timestamp = Date()
    }

    // Firestore dictionary representation
    func toDictionary() -> [String: Any] {
        return [
            "date": date,
            "mood": mood.rawValue,
            "timestamp": timestamp
        ]
    }

    // Initialize from Firestore
    init?(from dictionary: [String: Any]) {
        guard let date = dictionary["date"] as? Date,
              let moodString = dictionary["mood"] as? String,
              let mood = Mood(rawValue: moodString),
              let timestamp = dictionary["timestamp"] as? Date else {
            return nil
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        self.id = formatter.string(from: date)
        self.date = date
        self.mood = mood
        self.timestamp = timestamp
    }
}
