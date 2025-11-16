//
//  HabitVariantConfig.swift
//  CortiFree
//
//  Created by Claude on 15/11/2025.
//  Configuration détaillée des variantes d'habitudes avec titres spécifiques
//

import Foundation

struct HabitVariantInfo {
    let imageName: String
    let title: String
    let frequency: String
}

struct HabitVariantConfig {

    // MARK: - Sleep Variants (toujours les 2)

    static let sleepVariants: [HabitVariantInfo] = [
        HabitVariantInfo(
            imageName: "habit_sleep_morning",
            title: "Se lever avant 7h",
            frequency: "frequency.daily"
        ),
        HabitVariantInfo(
            imageName: "habit_sleep_night",
            title: "Se coucher avant 23h",
            frequency: "frequency.daily"
        )
    ]

    // MARK: - Nature Variants

    static let natureVariants: [HabitVariantInfo] = [
        HabitVariantInfo(
            imageName: "habit_nature_balade",
            title: "Explorer la nature",
            frequency: "frequency.2x_week"
        ),
        HabitVariantInfo(
            imageName: "habit_nature_randonnee",
            title: "Conquérir un sommet",
            frequency: "frequency.2x_week"
        ),
        HabitVariantInfo(
            imageName: "habit_nature_velo",
            title: "S'évader à vélo",
            frequency: "frequency.2x_week"
        )
    ]

    // MARK: - Sport Variants

    static let sportVariants: [HabitVariantInfo] = [
        HabitVariantInfo(
            imageName: "habit_sport_boxe",
            title: "Libérer l'énergie en boxe",
            frequency: "frequency.3x_week"
        ),
        HabitVariantInfo(
            imageName: "habit_sport_corde",
            title: "Défier la corde à sauter",
            frequency: "frequency.3x_week"
        ),
        HabitVariantInfo(
            imageName: "habit_sport_dance",
            title: "Danser et s'exprimer",
            frequency: "frequency.3x_week"
        ),
        HabitVariantInfo(
            imageName: "habit_sport_etirements",
            title: "S'étirer en profondeur",
            frequency: "frequency.3x_week"
        ),
        HabitVariantInfo(
            imageName: "habit_sport_natation",
            title: "Nager vers la sérénité",
            frequency: "frequency.3x_week"
        ),
        HabitVariantInfo(
            imageName: "habit_sport_renforcement",
            title: "Sculpter son corps",
            frequency: "frequency.3x_week"
        ),
        HabitVariantInfo(
            imageName: "habit_sport_courir",
            title: "Courir vers ses objectifs",
            frequency: "frequency.3x_week"
        )
    ]

    // MARK: - Social Variants

    static let socialVariants: [HabitVariantInfo] = [
        HabitVariantInfo(
            imageName: "habit_social_creative",
            title: "Créer ensemble",
            frequency: "frequency.3x_week"
        ),
        HabitVariantInfo(
            imageName: "habit_social_appel",
            title: "Renouer les liens",
            frequency: "frequency.3x_week"
        ),
        HabitVariantInfo(
            imageName: "habit_social_cuisiner",
            title: "Partager un repas",
            frequency: "frequency.3x_week"
        ),
        HabitVariantInfo(
            imageName: "habit_social_film",
            title: "Soirée cinéma",
            frequency: "frequency.3x_week"
        ),
        HabitVariantInfo(
            imageName: "habit_social_jeu",
            title: "Défis ludiques",
            frequency: "frequency.3x_week"
        ),
        HabitVariantInfo(
            imageName: "habit_social_verre",
            title: "Moment convivial",
            frequency: "frequency.3x_week"
        )
    ]

    // MARK: - Get Variant for Day

    /// Retourne la variante appropriée en fonction du jour (varie chaque jour dans la semaine)
    static func variantForDay(_ day: Int, habitType: String) -> HabitVariantInfo? {
        switch habitType {
        case "nature":
            // Rotation quotidienne entre les variantes
            let variantIndex = (day - 1) % natureVariants.count
            return natureVariants[variantIndex]

        case "sport":
            // Rotation quotidienne entre les variantes
            let variantIndex = (day - 1) % sportVariants.count
            return sportVariants[variantIndex]

        case "social":
            // Rotation quotidienne entre les variantes
            let variantIndex = (day - 1) % socialVariants.count
            return socialVariants[variantIndex]

        default:
            return nil
        }
    }

    /// Retourne les variantes qui doivent être affichées selon la fréquence hebdomadaire
    static func getActiveVariantsForWeek(_ day: Int, habitType: String, frequencyPerWeek: Int) -> [HabitVariantInfo] {
        guard frequencyPerWeek > 0 && frequencyPerWeek < 7 else {
            // Si quotidien, retourne la variante du jour
            if let variant = variantForDay(day, habitType: habitType) {
                return [variant]
            }
            return []
        }

        // Pour les habitudes non-quotidiennes, sélectionner différentes variantes
        let weekNumber = (day - 1) / 7
        var selectedVariants: [HabitVariantInfo] = []

        switch habitType {
        case "nature":
            let startIndex = (weekNumber * frequencyPerWeek) % natureVariants.count
            for i in 0..<min(frequencyPerWeek, natureVariants.count) {
                let index = (startIndex + i) % natureVariants.count
                selectedVariants.append(natureVariants[index])
            }

        case "sport":
            let startIndex = (weekNumber * frequencyPerWeek) % sportVariants.count
            for i in 0..<min(frequencyPerWeek, sportVariants.count) {
                let index = (startIndex + i) % sportVariants.count
                selectedVariants.append(sportVariants[index])
            }

        case "social":
            let startIndex = (weekNumber * frequencyPerWeek) % socialVariants.count
            for i in 0..<min(frequencyPerWeek, socialVariants.count) {
                let index = (startIndex + i) % socialVariants.count
                selectedVariants.append(socialVariants[index])
            }

        default:
            break
        }

        return selectedVariants
    }

    /// Retourne les 2 variantes de sommeil (toujours les deux)
    static func getSleepVariants() -> [HabitVariantInfo] {
        return sleepVariants
    }
}
