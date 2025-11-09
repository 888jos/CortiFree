//
//  DailyTodo.swift
//  CortiFree
//
//  Created by Claude on 23/10/2025.
//  Modèle pour les tâches quotidiennes matin/soir
//

import Foundation
import FirebaseFirestore

struct DailyTodo: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    let userId: String
    let title: String
    let createdAt: Date
    var isCompleted: Bool // Simple checkbox
    var isActive: Bool // User can delete/archive todos
}
