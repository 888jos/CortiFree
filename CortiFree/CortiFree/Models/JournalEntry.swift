//
//  JournalEntry.swift
//  CortiFree
//
//  Created by Claude on 23/10/2025.
//  Modèle pour les entrées de journal/carnet
//

import Foundation
import FirebaseFirestore

struct JournalEntry: Identifiable, Codable {
    @DocumentID var id: String?
    let content: String         // Le contenu écrit par l'user
    let createdAt: Date
    let userId: String
    var mood: Mood?             // Humeur associée
    var photoURL: String?       // URL de la photo dans Firebase Storage
    var wordCount: Int?         // Nombre de mots

    // Legacy fields (kept for backward compatibility but not used in new simplified journal)
    var meditationId: String?
    var meditationType: String?
    var prompt: String?
    var tags: [String]?
    var isFavorite: Bool?

    enum CodingKeys: String, CodingKey {
        case id
        case content
        case createdAt
        case userId
        case mood
        case photoURL
        case wordCount
        case meditationId
        case meditationType
        case prompt
        case tags
        case isFavorite
    }
}

// MARK: - Mood Enum
enum Mood: String, Codable, CaseIterable {
    case awful = "awful"
    case angry = "angry"
    case low = "low"
    case okay = "okay"
    case good = "good"
    case amazing = "amazing"

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

    var displayName: String {
        switch self {
        case .awful: return "Terrible"
        case .angry: return "Colère"
        case .low: return "Faible"
        case .okay: return "Neutre"
        case .good: return "Bien"
        case .amazing: return "Génial"
        }
    }

    var pastelColor: String {
        switch self {
        case .awful: return "FF9999"        // Pastel Red
        case .angry: return "FFB366"        // Pastel Orange
        case .low: return "FFD699"          // Pastel Yellow-Orange
        case .okay: return "FFEB99"         // Pastel Yellow
        case .good: return "B3E6B3"         // Pastel Green
        case .amazing: return "99E699"      // Pastel Bright Green
        }
    }

    var color: String {
        switch self {
        case .awful: return "E63946"        // Bright Red
        case .angry: return "F77F00"        // Vivid Orange
        case .low: return "FCBF49"          // Golden Yellow
        case .okay: return "90E0EF"         // Sky Blue
        case .good: return "06D6A0"         // Turquoise Green
        case .amazing: return "7209B7"      // Vibrant Purple
        }
    }
}

// Types de journaling
enum JournalType: String, CaseIterable {
    case gratitude = "gratitude"
    case clarity = "clarity"
    case reflection = "reflection"
    case general = "general"

    var displayName: String {
        switch self {
        case .gratitude: return "Gratitude"
        case .clarity: return "Clarté"
        case .reflection: return "Réflexion"
        case .general: return "Journal"
        }
    }

    var icon: String {
        switch self {
        case .gratitude: return "heart.text.square.fill"
        case .clarity: return "brain.head.profile"
        case .reflection: return "sparkles"
        case .general: return "book.fill"
        }
    }
}

// MARK: - Daily Prompts
struct DailyPrompt {
    static let prompts: [String: [String]] = [
        "gratitude": [
            "Aujourd'hui, je suis reconnaissant pour...",
            "Trois choses qui m'ont fait sourire aujourd'hui :",
            "Une personne à qui je voudrais dire merci et pourquoi :",
            "Un moment simple de bonheur aujourd'hui :",
            "Ce que j'apprécie dans ma vie en ce moment :"
        ],
        "clarity": [
            "Comment puis-je mieux gérer mon stress aujourd'hui ?",
            "Qu'est-ce qui occupe mon esprit en ce moment ?",
            "Une décision que je dois prendre et mes réflexions :",
            "Comment me sens-je mentalement sur une échelle de 1 à 10 et pourquoi ?",
            "Qu'ai-je appris sur moi aujourd'hui ?"
        ],
        "reflection": [
            "Qu'est-ce que j'ai accompli aujourd'hui ?",
            "Une leçon que j'ai apprise récemment :",
            "Comment puis-je m'améliorer demain ?",
            "Ce qui m'a marqué aujourd'hui :",
            "Un moment dont je suis fier aujourd'hui :"
        ],
        "goals": [
            "Mon objectif principal cette semaine :",
            "Les étapes pour atteindre mon objectif :",
            "Ce qui me motive à réussir :",
            "Les obstacles à surmonter :",
            "Ma vision pour les 3 prochains mois :"
        ],
        "general": [
            "Comment s'est passée ma journée ?",
            "Qu'est-ce que je ressens en ce moment ?",
            "Un défi que j'ai rencontré et comment je l'ai géré :",
            "Mes pensées et émotions du jour :",
            "Ce dont je veux me souvenir de cette journée :"
        ]
    ]

    static func getRandomPrompt(for typeString: String) -> String {
        guard let prompts = prompts[typeString] else {
            return "Que ressentez-vous aujourd'hui ?"
        }
        return prompts.randomElement() ?? prompts[0]
    }

    static func getDailyPrompt(for typeString: String) -> String {
        guard let prompts = prompts[typeString] else {
            return "Que ressentez-vous aujourd'hui ?"
        }
        // Use day of year to get consistent daily prompt
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
        let index = dayOfYear % prompts.count
        return prompts[index]
    }
}

// MARK: - Popular Tags
struct PopularTags {
    static let tags = [
        "travail", "famille", "amis", "santé", "sport",
        "créativité", "apprentissage", "détente", "voyage", "nature"
    ]
}
