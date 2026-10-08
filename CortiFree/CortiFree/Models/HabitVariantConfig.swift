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
            return LanguageManager.shared.localizedString(for: "habit.wake_before_8h30")
        case 2, 3:
            return LanguageManager.shared.localizedString(for: "habit.wake_before_8h")
        case 4, 5:
            return LanguageManager.shared.localizedString(for: "habit.wake_before_7h30")
        default: // 6-10
            return LanguageManager.shared.localizedString(for: "habit.wake_before_7h")
        }
    }

    /// Retourne le titre du coucher selon la semaine
    static func bedtimeTitle(for week: Int) -> String {
        switch week {
        case 1:
            return LanguageManager.shared.localizedString(for: "habit.sleep_before_23h30")
        case 2, 3:
            return LanguageManager.shared.localizedString(for: "habit.sleep_before_23h")
        case 4, 5:
            return LanguageManager.shared.localizedString(for: "habit.sleep_before_22h30")
        default: // 6-10
            return LanguageManager.shared.localizedString(for: "habit.sleep_before_22h")
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
                title: LanguageManager.shared.localizedString(for: "habit.wake_before_7h"),
                frequency: "frequency.daily"
            ),
            HabitVariantInfo(
                imageName: "habit_sleep_night",
                title: LanguageManager.shared.localizedString(for: "habit.sleep_before_22h"),
                frequency: "frequency.daily"
            )
        ]
    }

    // MARK: - Single Variants (1 seule variante)

    static var breathingVariant: HabitVariantInfo {
        HabitVariantInfo(
            imageName: "habit_breathe",
            title: LanguageManager.shared.localizedString(for: "habit.breathing_title"),
            frequency: "frequency.daily"
        )
    }

    static var meditationVariant: HabitVariantInfo {
        HabitVariantInfo(
            imageName: "habit_meditate",
            title: LanguageManager.shared.localizedString(for: "habit.meditation_title"),
            frequency: "frequency.daily"
        )
    }

    static var journalVariant: HabitVariantInfo {
        HabitVariantInfo(
            imageName: "habit_journal",
            title: LanguageManager.shared.localizedString(for: "habit.journal_title"),
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
            title: String(format: LanguageManager.shared.localizedString(for: "habit.water_title"), waterTarget(for: week)),
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
            title: LanguageManager.shared.localizedString(for: "habit.water_title_legacy"),
            frequency: "frequency.daily"
        )
    }

    // MARK: - Nature Variants

    static var natureVariants: [HabitVariantInfo] {
        [
            HabitVariantInfo(
                imageName: "habit_nature_balade",
                title: LanguageManager.shared.localizedString(for: "habit.nature_walk"),
                frequency: "frequency.2x_week"
            ),
            HabitVariantInfo(
                imageName: "habit_nature_randonnee",
                title: LanguageManager.shared.localizedString(for: "habit.nature_trek"),
                frequency: "frequency.2x_week"
            ),
            HabitVariantInfo(
                imageName: "habit_nature_velo",
                title: LanguageManager.shared.localizedString(for: "habit.nature_bike"),
                frequency: "frequency.2x_week"
            )
        ]
    }

    // MARK: - Sport Variants

    static var sportVariants: [HabitVariantInfo] {
        [
            HabitVariantInfo(
                imageName: "habit_sport_corde",
                title: LanguageManager.shared.localizedString(for: "habit.sport_jump_rope"),
                frequency: "frequency.3x_week"
            ),
            HabitVariantInfo(
                imageName: "habit_sport_dance",
                title: LanguageManager.shared.localizedString(for: "habit.sport_dance"),
                frequency: "frequency.3x_week"
            ),
            HabitVariantInfo(
                imageName: "habit_sport_etirements",
                title: LanguageManager.shared.localizedString(for: "habit.sport_stretching"),
                frequency: "frequency.3x_week"
            ),
            HabitVariantInfo(
                imageName: "habit_sport_natation",
                title: LanguageManager.shared.localizedString(for: "habit.sport_swimming"),
                frequency: "frequency.3x_week"
            ),
            HabitVariantInfo(
                imageName: "habit_sport_renforcement",
                title: LanguageManager.shared.localizedString(for: "habit.sport_strength"),
                frequency: "frequency.3x_week"
            ),
            HabitVariantInfo(
                imageName: "habit_sport_courir",
                title: LanguageManager.shared.localizedString(for: "habit.sport_running"),
                frequency: "frequency.3x_week"
            )
        ]
    }

    // MARK: - Social Variants

    static var socialVariants: [HabitVariantInfo] {
        [
            HabitVariantInfo(
                imageName: "habit_social_creative",
                title: LanguageManager.shared.localizedString(for: "habit.social_creative"),
                frequency: "frequency.3x_week"
            ),
            HabitVariantInfo(
                imageName: "habit_social_appel",
                title: LanguageManager.shared.localizedString(for: "habit.social_call"),
                frequency: "frequency.3x_week"
            ),
            HabitVariantInfo(
                imageName: "habit_social_cuisiner",
                title: LanguageManager.shared.localizedString(for: "habit.social_meal"),
                frequency: "frequency.3x_week"
            ),
            HabitVariantInfo(
                imageName: "habit_social_film",
                title: LanguageManager.shared.localizedString(for: "habit.social_movie"),
                frequency: "frequency.3x_week"
            ),
            HabitVariantInfo(
                imageName: "habit_social_jeu",
                title: LanguageManager.shared.localizedString(for: "habit.social_games"),
                frequency: "frequency.3x_week"
            ),
            HabitVariantInfo(
                imageName: "habit_social_verre",
                title: LanguageManager.shared.localizedString(for: "habit.social_drinks"),
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
