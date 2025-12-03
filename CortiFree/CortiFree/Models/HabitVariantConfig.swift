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
            return NSLocalizedString("habit.wake_before_8h30", comment: "")
        case 2, 3:
            return NSLocalizedString("habit.wake_before_8h", comment: "")
        case 4, 5:
            return NSLocalizedString("habit.wake_before_7h30", comment: "")
        default: // 6-10
            return NSLocalizedString("habit.wake_before_7h", comment: "")
        }
    }

    /// Retourne le titre du coucher selon la semaine
    static func bedtimeTitle(for week: Int) -> String {
        switch week {
        case 1:
            return NSLocalizedString("habit.sleep_before_23h30", comment: "")
        case 2, 3:
            return NSLocalizedString("habit.sleep_before_23h", comment: "")
        case 4, 5:
            return NSLocalizedString("habit.sleep_before_22h30", comment: "")
        default: // 6-10
            return NSLocalizedString("habit.sleep_before_22h", comment: "")
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
    static var sleepVariants: [HabitVariantInfo] {
        [
            HabitVariantInfo(
                imageName: "habit_sleep_morning",
                title: NSLocalizedString("habit.wake_before_7h", comment: ""),
                frequency: "frequency.daily"
            ),
            HabitVariantInfo(
                imageName: "habit_sleep_night",
                title: NSLocalizedString("habit.sleep_before_22h", comment: ""),
                frequency: "frequency.daily"
            )
        ]
    }

    // MARK: - Single Variants (1 seule variante)

    static var breathingVariant: HabitVariantInfo {
        HabitVariantInfo(
            imageName: "habit_breathe",
            title: NSLocalizedString("habit.breathing_title", comment: ""),
            frequency: "frequency.daily"
        )
    }

    static var meditationVariant: HabitVariantInfo {
        HabitVariantInfo(
            imageName: "habit_meditate",
            title: NSLocalizedString("habit.meditation_title", comment: ""),
            frequency: "frequency.daily"
        )
    }

    static var journalVariant: HabitVariantInfo {
        HabitVariantInfo(
            imageName: "habit_journal",
            title: NSLocalizedString("habit.journal_title", comment: ""),
            frequency: "frequency.daily"
        )
    }

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
            title: String(format: NSLocalizedString("habit.water_title", comment: ""), waterTarget(for: week)),
            frequency: "frequency.daily"
        )
    }

    /// Retourne la variante eau avec progression selon le jour
    static func getWaterVariant(forDay day: Int) -> HabitVariantInfo {
        let week = WeeklyHabitProgression.currentWeek(for: day)
        return getWaterVariant(for: week)
    }

    // Legacy - pour compatibilité
    static var waterVariant: HabitVariantInfo {
        HabitVariantInfo(
            imageName: "habit_water",
            title: NSLocalizedString("habit.water_title_legacy", comment: ""),
            frequency: "frequency.daily"
        )
    }

    // MARK: - Nature Variants

    static var natureVariants: [HabitVariantInfo] {
        [
            HabitVariantInfo(
                imageName: "habit_nature_balade",
                title: NSLocalizedString("habit.nature_walk", comment: ""),
                frequency: "frequency.2x_week"
            ),
            HabitVariantInfo(
                imageName: "habit_nature_randonnee",
                title: NSLocalizedString("habit.nature_trek", comment: ""),
                frequency: "frequency.2x_week"
            ),
            HabitVariantInfo(
                imageName: "habit_nature_velo",
                title: NSLocalizedString("habit.nature_bike", comment: ""),
                frequency: "frequency.2x_week"
            )
        ]
    }

    // MARK: - Sport Variants

    static var sportVariants: [HabitVariantInfo] {
        [
            HabitVariantInfo(
                imageName: "habit_sport_boxe",
                title: NSLocalizedString("habit.sport_boxing", comment: ""),
                frequency: "frequency.3x_week"
            ),
            HabitVariantInfo(
                imageName: "habit_sport_corde",
                title: NSLocalizedString("habit.sport_jump_rope", comment: ""),
                frequency: "frequency.3x_week"
            ),
            HabitVariantInfo(
                imageName: "habit_sport_dance",
                title: NSLocalizedString("habit.sport_dance", comment: ""),
                frequency: "frequency.3x_week"
            ),
            HabitVariantInfo(
                imageName: "habit_sport_etirements",
                title: NSLocalizedString("habit.sport_stretching", comment: ""),
                frequency: "frequency.3x_week"
            ),
            HabitVariantInfo(
                imageName: "habit_sport_natation",
                title: NSLocalizedString("habit.sport_swimming", comment: ""),
                frequency: "frequency.3x_week"
            ),
            HabitVariantInfo(
                imageName: "habit_sport_renforcement",
                title: NSLocalizedString("habit.sport_strength", comment: ""),
                frequency: "frequency.3x_week"
            ),
            HabitVariantInfo(
                imageName: "habit_sport_courir",
                title: NSLocalizedString("habit.sport_running", comment: ""),
                frequency: "frequency.3x_week"
            )
        ]
    }

    // MARK: - Social Variants

    static var socialVariants: [HabitVariantInfo] {
        [
            HabitVariantInfo(
                imageName: "habit_social_creative",
                title: NSLocalizedString("habit.social_creative", comment: ""),
                frequency: "frequency.3x_week"
            ),
            HabitVariantInfo(
                imageName: "habit_social_appel",
                title: NSLocalizedString("habit.social_call", comment: ""),
                frequency: "frequency.3x_week"
            ),
            HabitVariantInfo(
                imageName: "habit_social_cuisiner",
                title: NSLocalizedString("habit.social_meal", comment: ""),
                frequency: "frequency.3x_week"
            ),
            HabitVariantInfo(
                imageName: "habit_social_film",
                title: NSLocalizedString("habit.social_movie", comment: ""),
                frequency: "frequency.3x_week"
            ),
            HabitVariantInfo(
                imageName: "habit_social_jeu",
                title: NSLocalizedString("habit.social_games", comment: ""),
                frequency: "frequency.3x_week"
            ),
            HabitVariantInfo(
                imageName: "habit_social_verre",
                title: NSLocalizedString("habit.social_drinks", comment: ""),
                frequency: "frequency.3x_week"
            )
        ]
    }

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
