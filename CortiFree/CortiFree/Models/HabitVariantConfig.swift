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

    // MARK: - Sleep Variants (progression par semaine)

    /// Retourne le titre du réveil selon la semaine
    static func wakeUpTitle(for week: Int) -> String {
        switch week {
        case 1:
            return "Se lever avant 8h30"
        case 2, 3:
            return "Se lever avant 8h"
        case 4, 5:
            return "Se lever avant 7h30"
        default: // 6-10
            return "Se lever avant 7h"
        }
    }

    /// Retourne le titre du coucher selon la semaine
    static func bedtimeTitle(for week: Int) -> String {
        switch week {
        case 1:
            return "Se coucher avant 23h30"
        case 2, 3:
            return "Se coucher avant 23h"
        case 4, 5:
            return "Se coucher avant 22h30"
        default: // 6-10
            return "Se coucher avant 22h"
        }
    }

    /// Retourne les variantes de sommeil avec titres dynamiques selon la semaine
    static func getSleepVariants(for week: Int) -> [HabitVariantInfo] {
        return [
            HabitVariantInfo(
                imageName: "habit_sleep_morning",
                title: wakeUpTitle(for: week),
                frequency: "frequency.daily"
            ),
            HabitVariantInfo(
                imageName: "habit_sleep_night",
                title: bedtimeTitle(for: week),
                frequency: "frequency.daily"
            )
        ]
    }

    // Legacy - pour compatibilité (utilise semaine 10 par défaut)
    static let sleepVariants: [HabitVariantInfo] = [
        HabitVariantInfo(
            imageName: "habit_sleep_morning",
            title: "Se lever avant 7h",
            frequency: "frequency.daily"
        ),
        HabitVariantInfo(
            imageName: "habit_sleep_night",
            title: "Se coucher avant 22h",
            frequency: "frequency.daily"
        )
    ]

    // MARK: - Single Variants (1 seule variante)

    static let breathingVariant = HabitVariantInfo(
        imageName: "habit_breathe",
        title: "Retrouver son souffle",
        frequency: "frequency.daily"
    )

    static let meditationVariant = HabitVariantInfo(
        imageName: "habit_meditate",
        title: "Méditer en pleine conscience",
        frequency: "frequency.daily"
    )

    static let journalVariant = HabitVariantInfo(
        imageName: "habit_journal",
        title: "Journaling quotidien",
        frequency: "frequency.daily"
    )

    /// Retourne l'objectif d'eau selon la semaine
    static func waterTarget(for week: Int) -> String {
        switch week {
        case 1:
            return "1L"
        case 2, 3:
            return "1,5L"
        case 4, 5:
            return "2L"
        default: // 6-10
            return "2,5L"
        }
    }

    /// Retourne la variante eau avec titre dynamique selon la semaine
    static func getWaterVariant(for week: Int) -> HabitVariantInfo {
        return HabitVariantInfo(
            imageName: "habit_water",
            title: "Boire au moins \(waterTarget(for: week)) d'eau",
            frequency: "frequency.daily"
        )
    }

    /// Retourne la variante eau avec progression selon le jour
    static func getWaterVariant(forDay day: Int) -> HabitVariantInfo {
        let week = WeeklyHabitProgression.currentWeek(for: day)
        return getWaterVariant(for: week)
    }

    // Legacy - pour compatibilité
    static let waterVariant = HabitVariantInfo(
        imageName: "habit_water",
        title: "Boire au moins 2,5L d'eau",
        frequency: "frequency.daily"
    )

    // MARK: - Nature Variants

    static let natureVariants: [HabitVariantInfo] = [
        HabitVariantInfo(
            imageName: "habit_nature_balade",
            title: "Balade en plein air",
            frequency: "frequency.2x_week"
        ),
        HabitVariantInfo(
            imageName: "habit_nature_randonnee",
            title: "Trek nature",
            frequency: "frequency.2x_week"
        ),
        HabitVariantInfo(
            imageName: "habit_nature_velo",
            title: "Rouler au grand air",
            frequency: "frequency.2x_week"
        )
    ]

    // MARK: - Sport Variants

    static let sportVariants: [HabitVariantInfo] = [
        HabitVariantInfo(
            imageName: "habit_sport_boxe",
            title: "Séance de boxe",
            frequency: "frequency.3x_week"
        ),
        HabitVariantInfo(
            imageName: "habit_sport_corde",
            title: "Cardio corde",
            frequency: "frequency.3x_week"
        ),
        HabitVariantInfo(
            imageName: "habit_sport_dance",
            title: "Se libérer en dansant",
            frequency: "frequency.3x_week"
        ),
        HabitVariantInfo(
            imageName: "habit_sport_etirements",
            title: "S'étirer en profondeur",
            frequency: "frequency.3x_week"
        ),
        HabitVariantInfo(
            imageName: "habit_sport_natation",
            title: "Session piscine",
            frequency: "frequency.3x_week"
        ),
        HabitVariantInfo(
            imageName: "habit_sport_renforcement",
            title: "Renforcement musculaire",
            frequency: "frequency.3x_week"
        ),
        HabitVariantInfo(
            imageName: "habit_sport_courir",
            title: "Courir librement",
            frequency: "frequency.3x_week"
        )
    ]

    // MARK: - Social Variants

    static let socialVariants: [HabitVariantInfo] = [
        HabitVariantInfo(
            imageName: "habit_social_creative",
            title: "Moment créatif partagé",
            frequency: "frequency.3x_week"
        ),
        HabitVariantInfo(
            imageName: "habit_social_appel",
            title: "Appeler un proche",
            frequency: "frequency.3x_week"
        ),
        HabitVariantInfo(
            imageName: "habit_social_cuisiner",
            title: "Repas convivial",
            frequency: "frequency.3x_week"
        ),
        HabitVariantInfo(
            imageName: "habit_social_film",
            title: "Soirée film",
            frequency: "frequency.3x_week"
        ),
        HabitVariantInfo(
            imageName: "habit_social_jeu",
            title: "Soirée jeux",
            frequency: "frequency.3x_week"
        ),
        HabitVariantInfo(
            imageName: "habit_social_verre",
            title: "Verre entre amis",
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

    /// Retourne les 2 variantes de sommeil (sans progression - legacy)
    static func getSleepVariants() -> [HabitVariantInfo] {
        return sleepVariants
    }

    /// Retourne les variantes de sommeil avec progression selon le jour
    static func getSleepVariants(forDay day: Int) -> [HabitVariantInfo] {
        let week = WeeklyHabitProgression.currentWeek(for: day)
        return getSleepVariants(for: week)
    }

    /// Retourne la variante unique pour respiration
    static func getBreathingVariant() -> HabitVariantInfo {
        return breathingVariant
    }

    /// Retourne la variante unique pour méditation
    static func getMeditationVariant() -> HabitVariantInfo {
        return meditationVariant
    }

    /// Retourne la variante unique pour journal
    static func getJournalVariant() -> HabitVariantInfo {
        return journalVariant
    }

    /// Retourne la variante unique pour eau/hydratation
    static func getWaterVariant() -> HabitVariantInfo {
        return waterVariant
    }
}
