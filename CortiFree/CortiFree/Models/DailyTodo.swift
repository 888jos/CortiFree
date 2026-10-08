//
//  DailyTodo.swift
//  CortiFree
//
//  Created by Claude on 23/10/2025.
//  Modèle pour les tâches quotidiennes matin/soir
//

import Foundation

struct DailyTodo: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    let userId: String
    let title: String
    let createdAt: Date
    var isCompleted: Bool // Simple checkbox
    var isActive: Bool // User can delete/archive todos

    init(id: String? = nil, userId: String, title: String, createdAt: Date, isCompleted: Bool, isActive: Bool) {
        self._id = DocumentID(wrappedValue: id)
        self.userId = userId
        self.title = title
        self.createdAt = createdAt
        self.isCompleted = isCompleted
        self.isActive = isActive
    }
}
