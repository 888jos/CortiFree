//
//  HabitVariant.swift
//  CortiFree
//
//  Created by Claude on 15/11/2025.
//  Gestion des variantes d'images pour les habitudes
//

import Foundation

struct HabitVariant {
    let habitType: String
    let variants: [String]

    // Get a random variant for a habit type
    static func randomVariant(for habitType: String) -> String {
        let variantMap: [String: [String]] = [
            "habit_breathe": ["habit_breathe"],
            "habit_meditate": ["habit_meditate"],
            "habit_journal": ["habit_journal"],
            "habit_water": ["habit_water"],
            "habit_sleep": ["habit_sleep_morning", "habit_sleep_night"],
            "habit_nature": [
                "habit_nature_balade",
                "habit_nature_randonnee",
                "habit_nature_velo"
            ],
            "habit_sport": [
                "habit_sport_boxe",
                "habit_sport_corde",
                "habit_sport_dance",
                "habit_sport_etirements",
                "habit_sport_natation",
                "habit_sport_renforcement",
                "habit_sport_courir"
            ],
            "habit_social": [
                "habit_social_creative",
                "habit_social_appel",
                "habit_social_cuisiner",
                "habit_social_film",
                "habit_social_jeu",
                "habit_social_verre"
            ]
        ]

        guard let variants = variantMap[habitType], !variants.isEmpty else {
            return habitType
        }

        return variants.randomElement() ?? habitType
    }

    // Get all variants for a habit type
    static func allVariants(for habitType: String) -> [String] {
        let variantMap: [String: [String]] = [
            "habit_breathe": ["habit_breathe"],
            "habit_meditate": ["habit_meditate"],
            "habit_journal": ["habit_journal"],
            "habit_water": ["habit_water"],
            "habit_sleep": ["habit_sleep_morning", "habit_sleep_night"],
            "habit_nature": [
                "habit_nature_balade",
                "habit_nature_randonnee",
                "habit_nature_velo"
            ],
            "habit_sport": [
                "habit_sport_boxe",
                "habit_sport_corde",
                "habit_sport_dance",
                "habit_sport_etirements",
                "habit_sport_natation",
                "habit_sport_renforcement",
                "habit_sport_courir"
            ],
            "habit_social": [
                "habit_social_creative",
                "habit_social_appel",
                "habit_social_cuisiner",
                "habit_social_film",
                "habit_social_jeu",
                "habit_social_verre"
            ]
        ]

        return variantMap[habitType] ?? [habitType]
    }
}
