//
//  RoutineProgram.swift
//  CortiFree
//
//  Created by Claude on 10/11/2025.
//  Système de routines 66 jours
//

import Foundation
import SwiftUI

// MARK: - Day Time of Day
enum DayTimeOfDay: String, Codable {
    case morning = "morning"
    case afternoon = "afternoon"
    case evening = "evening"
    case any = "any"

    var displayName: String {
        switch self {
        case .morning: return "Matin"
        case .afternoon: return "Après-midi"
        case .evening: return "Soir"
        case .any: return "Flexible"
        }
    }

    var icon: String {
        switch self {
        case .morning: return "sunrise.fill"
        case .afternoon: return "sun.max.fill"
        case .evening: return "moon.stars.fill"
        case .any: return "clock.fill"
        }
    }
}

// MARK: - Routine Exercise Type
enum RoutineExerciseType: String, Codable {
    case breathing = "breathing"
    case meditation = "meditation"
    case journal = "journal"
    case tcc = "tcc"
    case exposure = "exposure"
    case sound = "sound"

    var displayName: String {
        switch self {
        case .breathing: return "Respiration"
        case .meditation: return "Méditation"
        case .journal: return "Journal"
        case .tcc: return "TCC"
        case .exposure: return "Exposition"
        case .sound: return "Son"
        }
    }

    var icon: String {
        switch self {
        case .breathing: return "wind"
        case .meditation: return "figure.mind.and.body"
        case .journal: return "book.fill"
        case .tcc: return "brain.head.profile"
        case .exposure: return "figure.walk"
        case .sound: return "speaker.wave.2.fill"
        }
    }
}

// MARK: - Daily Exercise
struct DailyExercise: Identifiable, Codable {
    let id: String
    let type: RoutineExerciseType
    let title: String
    let description: String
    let durationMinutes: Int
    let exerciseId: String? // Reference to Exercise.id for breathing/meditation/sound
    let xpReward: Int
    let isOptional: Bool

    init(id: String = UUID().uuidString,
         type: RoutineExerciseType,
         title: String,
         description: String,
         durationMinutes: Int,
         exerciseId: String? = nil,
         xpReward: Int,
         isOptional: Bool = false) {
        self.id = id
        self.type = type
        self.title = title
        self.description = description
        self.durationMinutes = durationMinutes
        self.exerciseId = exerciseId
        self.xpReward = xpReward
        self.isOptional = isOptional
    }
}

// MARK: - Checkpoint
struct RoutineCheckpoint: Identifiable, Codable {
    let id: String
    let day: Int
    let title: String
    let description: String
    let badgeIcon: String
    let badgeColor: String // Hex color
    let bonusXP: Int

    init(id: String = UUID().uuidString,
         day: Int,
         title: String,
         description: String,
         badgeIcon: String,
         badgeColor: String,
         bonusXP: Int) {
        self.id = id
        self.day = day
        self.title = title
        self.description = description
        self.badgeIcon = badgeIcon
        self.badgeColor = badgeColor
        self.bonusXP = bonusXP
    }
}

// MARK: - Daily Program
struct DailyProgram: Identifiable, Codable {
    let id: String
    let day: Int
    let title: String
    let theme: String
    let timeOfDay: DayTimeOfDay
    let exercises: [DailyExercise]
    let checkpoint: RoutineCheckpoint?
    let guidance: String // Daily guidance/motivation text

    var totalXP: Int {
        exercises.reduce(0) { $0 + $1.xpReward } + (checkpoint?.bonusXP ?? 0)
    }

    var totalDuration: Int {
        exercises.reduce(0) { $0 + $1.durationMinutes }
    }

    init(id: String = UUID().uuidString,
         day: Int,
         title: String,
         theme: String,
         timeOfDay: DayTimeOfDay,
         exercises: [DailyExercise],
         checkpoint: RoutineCheckpoint? = nil,
         guidance: String) {
        self.id = id
        self.day = day
        self.title = title
        self.theme = theme
        self.timeOfDay = timeOfDay
        self.exercises = exercises
        self.checkpoint = checkpoint
        self.guidance = guidance
    }
}

// MARK: - Routine Cycle
struct RoutineCycle: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let startDay: Int
    let endDay: Int
    let color: String // Hex color
    let days: [DailyProgram]

    var totalXP: Int {
        days.reduce(0) { $0 + $1.totalXP }
    }

    init(id: String = UUID().uuidString,
         name: String,
         description: String,
         startDay: Int,
         endDay: Int,
         color: String,
         days: [DailyProgram]) {
        self.id = id
        self.name = name
        self.description = description
        self.startDay = startDay
        self.endDay = endDay
        self.color = color
        self.days = days
    }
}

// MARK: - Routine Program
struct RoutineProgram: Identifiable, Codable {
    let id: String
    let title: String
    let subtitle: String
    let description: String
    let planet: String
    let duration: Int // Total days (66)
    let difficulty: String
    let icon: String
    let color: String // Hex color
    let cycles: [RoutineCycle]

    var totalXP: Int {
        cycles.reduce(0) { $0 + $1.totalXP }
    }

    var allDays: [DailyProgram] {
        cycles.flatMap { $0.days }.sorted { $0.day < $1.day }
    }

    func day(_ dayNumber: Int) -> DailyProgram? {
        allDays.first { $0.day == dayNumber }
    }

    func cycle(forDay dayNumber: Int) -> RoutineCycle? {
        cycles.first { $0.startDay <= dayNumber && dayNumber <= $0.endDay }
    }

    init(id: String,
         title: String,
         subtitle: String,
         description: String,
         planet: String,
         duration: Int,
         difficulty: String,
         icon: String,
         color: String,
         cycles: [RoutineCycle]) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.description = description
        self.planet = planet
        self.duration = duration
        self.difficulty = difficulty
        self.icon = icon
        self.color = color
        self.cycles = cycles
    }

    // MARK: - Static Programs

    static let masterMind = RoutineProgram(
        id: "master-mind",
        title: "🧠 Maîtriser son esprit",
        subtitle: "Calmer l'anxiété et les pensées en boucle",
        description: "Programme de 66 jours pour reprendre le contrôle de ton mental et apaiser les pensées anxieuses.",
        planet: "Terre",
        duration: 66,
        difficulty: "Intermédiaire",
        icon: "brain.head.profile",
        color: "4A90E2",
        cycles: [
            // CYCLE 1: OBSERVER (J1-22)
            RoutineCycle(
                name: "Cycle 1 : Observer",
                description: "Comprendre ton anxiété et tes mécanismes de pensée",
                startDay: 1,
                endDay: 22,
                color: "4A90E2",
                days: masterMindCycle1Days()
            ),
            // CYCLE 2: DÉCONSTRUIRE (J23-44)
            RoutineCycle(
                name: "Cycle 2 : Déconstruire",
                description: "Changer tes schémas de pensée et réduire l'anxiété",
                startDay: 23,
                endDay: 44,
                color: "5BA3E2",
                days: masterMindCycle2Days()
            ),
            // CYCLE 3: MAÎTRISER (J45-66)
            RoutineCycle(
                name: "Cycle 3 : Maîtriser",
                description: "Vivre sereinement avec une nouvelle relation à tes pensées",
                startDay: 45,
                endDay: 66,
                color: "6CB3F2",
                days: masterMindCycle3Days()
            )
        ]
    )

    static let allPrograms: [RoutineProgram] = [
        masterMind
        // Additional routines (sleep, energy, stress) can be added here
    ]

    static func program(forId id: String) -> RoutineProgram? {
        allPrograms.first { $0.id == id }
    }
}

// MARK: - Master Mind Cycle 1 (Days 1-22)
private func masterMindCycle1Days() -> [DailyProgram] {
    return [
        // SEMAINE 1: Introduction
        DailyProgram(
            day: 1,
            title: "Bienvenue dans ton programme",
            theme: "Découverte",
            timeOfDay: .morning,
            exercises: [
                DailyExercise(
                    type: .breathing,
                    title: "4-7-8 (5 min)",
                    description: "Première respiration apaisante",
                    durationMinutes: 5,
                    exerciseId: "478",
                    xpReward: 25
                ),
                DailyExercise(
                    type: .meditation,
                    title: "Méditation guidée : Ancrage",
                    description: "Se connecter au moment présent",
                    durationMinutes: 10,
                    exerciseId: "grounding",
                    xpReward: 25
                ),
                DailyExercise(
                    type: .journal,
                    title: "Journal de réflexion",
                    description: "Quelles situations déclenchent ton anxiété en ce moment ?",
                    durationMinutes: 10,
                    xpReward: 25
                )
            ],
            checkpoint: RoutineCheckpoint(
                day: 1,
                title: "Premier pas vers la sérénité",
                description: "Tu as commencé ton voyage !",
                badgeIcon: "flag.fill",
                badgeColor: "4A90E2",
                bonusXP: 50
            ),
            guidance: "Aujourd'hui, tu commences un voyage vers une vie plus apaisée. Chaque exercice compte, même s'il te semble simple."
        ),

        DailyProgram(
            day: 2,
            title: "Observer sans juger",
            theme: "Pleine conscience",
            timeOfDay: .morning,
            exercises: [
                DailyExercise(
                    type: .breathing,
                    title: "Cohérence cardiaque (5 min)",
                    description: "5 sec inspire, 5 sec expire",
                    durationMinutes: 5,
                    exerciseId: "coherence",
                    xpReward: 25
                ),
                DailyExercise(
                    type: .meditation,
                    title: "Scan corporel",
                    description: "Détecter les zones de tension",
                    durationMinutes: 10,
                    exerciseId: "body-scan",
                    xpReward: 25
                ),
                DailyExercise(
                    type: .journal,
                    title: "Sensations physiques",
                    description: "Où ressens-tu l'anxiété dans ton corps ?",
                    durationMinutes: 10,
                    xpReward: 25
                )
            ],
            guidance: "Ton corps te parle. Apprends à écouter ses signaux sans les juger."
        ),

        DailyProgram(
            day: 3,
            title: "La respiration comme refuge",
            theme: "Ancrage respiratoire",
            timeOfDay: .morning,
            exercises: [
                DailyExercise(
                    type: .breathing,
                    title: "4-7-8 (7 min)",
                    description: "Allonger la pratique",
                    durationMinutes: 7,
                    exerciseId: "478",
                    xpReward: 30
                ),
                DailyExercise(
                    type: .meditation,
                    title: "Pleine conscience",
                    description: "Rester dans l'instant présent",
                    durationMinutes: 10,
                    exerciseId: "mindfulness",
                    xpReward: 25
                ),
                DailyExercise(
                    type: .journal,
                    title: "Moments d'anxiété",
                    description: "Note 3 moments anxieux aujourd'hui et leur intensité (1-10)",
                    durationMinutes: 10,
                    xpReward: 25
                )
            ],
            checkpoint: RoutineCheckpoint(
                day: 3,
                title: "3 jours de suite !",
                description: "Ta régularité commence à payer",
                badgeIcon: "flame.fill",
                badgeColor: "FF6B6B",
                bonusXP: 30
            ),
            guidance: "La respiration est ton outil le plus puissant. Reviens-y à chaque moment de doute."
        ),

        DailyProgram(
            day: 4,
            title: "Identifier les pensées automatiques",
            theme: "TCC - Observation",
            timeOfDay: .afternoon,
            exercises: [
                DailyExercise(
                    type: .breathing,
                    title: "Box Breathing (5 min)",
                    description: "4 temps égaux",
                    durationMinutes: 5,
                    exerciseId: "box",
                    xpReward: 25
                ),
                DailyExercise(
                    type: .tcc,
                    title: "Chasse aux pensées",
                    description: "Identifie 3 pensées automatiques négatives qui surgissent dans la journée",
                    durationMinutes: 15,
                    xpReward: 30
                ),
                DailyExercise(
                    type: .journal,
                    title: "Tableau ABC",
                    description: "A (situation), B (pensée), C (émotion/réaction). Note 2 exemples",
                    durationMinutes: 10,
                    xpReward: 30
                )
            ],
            guidance: "Tes pensées ne sont pas des faits. Commence à les observer comme un scientifique observe un phénomène."
        ),

        DailyProgram(
            day: 5,
            title: "La défusion cognitive",
            theme: "TCC - Distance",
            timeOfDay: .afternoon,
            exercises: [
                DailyExercise(
                    type: .breathing,
                    title: "4-7-8 (5 min)",
                    description: "Retour au calme",
                    durationMinutes: 5,
                    exerciseId: "478",
                    xpReward: 25
                ),
                DailyExercise(
                    type: .tcc,
                    title: "Exercice de défusion",
                    description: "Répète une pensée anxieuse 20 fois pour la désactiver émotionnellement",
                    durationMinutes: 10,
                    xpReward: 35
                ),
                DailyExercise(
                    type: .meditation,
                    title: "Visualisation : Les pensées comme des nuages",
                    description: "Observer les pensées passer sans s'y accrocher",
                    durationMinutes: 10,
                    exerciseId: "visualization",
                    xpReward: 25
                ),
                DailyExercise(
                    type: .journal,
                    title: "Distance cognitive",
                    description: "Reformule 2 pensées anxieuses en prenant du recul",
                    durationMinutes: 10,
                    xpReward: 25
                )
            ],
            guidance: "Tu n'es pas tes pensées. Elles passent, comme des nuages dans le ciel."
        ),

        DailyProgram(
            day: 6,
            title: "Introduction à l'exposition",
            theme: "Affronter doucement",
            timeOfDay: .any,
            exercises: [
                DailyExercise(
                    type: .breathing,
                    title: "Cohérence cardiaque (5 min)",
                    description: "Préparer le corps",
                    durationMinutes: 5,
                    exerciseId: "coherence",
                    xpReward: 25
                ),
                DailyExercise(
                    type: .exposure,
                    title: "Exposition imaginaire (niveau 1)",
                    description: "Visualise une situation anxiogène mineure pendant 5 min. Reste avec l'inconfort.",
                    durationMinutes: 10,
                    xpReward: 40
                ),
                DailyExercise(
                    type: .journal,
                    title: "Échelle d'anxiété",
                    description: "Note ton niveau d'anxiété avant (1-10) et après (1-10) l'exposition",
                    durationMinutes: 5,
                    xpReward: 25
                )
            ],
            guidance: "L'évitement nourrit l'anxiété. L'exposition, même imaginaire, l'affaiblit."
        ),

        DailyProgram(
            day: 7,
            title: "Bilan de la semaine 1",
            theme: "Consolidation",
            timeOfDay: .evening,
            exercises: [
                DailyExercise(
                    type: .breathing,
                    title: "4-7-8 libre (10 min)",
                    description: "À ton rythme, sans guide",
                    durationMinutes: 10,
                    exerciseId: "478",
                    xpReward: 30
                ),
                DailyExercise(
                    type: .meditation,
                    title: "Gratitude",
                    description: "Reconnaissance pour le chemin parcouru",
                    durationMinutes: 8,
                    exerciseId: "gratitude",
                    xpReward: 25
                ),
                DailyExercise(
                    type: .journal,
                    title: "Rétrospective de semaine",
                    description: "Qu'as-tu appris cette semaine ? Quelle technique t'a le plus aidé ?",
                    durationMinutes: 15,
                    xpReward: 30
                )
            ],
            checkpoint: RoutineCheckpoint(
                day: 7,
                title: "Première semaine complétée !",
                description: "7 jours consécutifs de pratique",
                badgeIcon: "star.fill",
                badgeColor: "FFD700",
                bonusXP: 100
            ),
            guidance: "Tu as posé les bases. La régularité crée le changement."
        ),

        // SEMAINE 2: TCC approfondie
        DailyProgram(
            day: 8,
            title: "Les distorsions cognitives",
            theme: "TCC - Reconnaissance",
            timeOfDay: .afternoon,
            exercises: [
                DailyExercise(
                    type: .breathing,
                    title: "Box Breathing (5 min)",
                    description: "Centrage",
                    durationMinutes: 5,
                    exerciseId: "box",
                    xpReward: 25
                ),
                DailyExercise(
                    type: .tcc,
                    title: "Liste des distorsions",
                    description: "Apprends 5 distorsions : catastrophisme, pensée tout-ou-rien, surgénéralisation, lecture de pensées, personnalisation",
                    durationMinutes: 15,
                    xpReward: 35
                ),
                DailyExercise(
                    type: .journal,
                    title: "Mes distorsions",
                    description: "Identifie 3 de tes pensées récentes et nomme leur distorsion",
                    durationMinutes: 10,
                    xpReward: 30
                )
            ],
            guidance: "Ton esprit a des filtres déformants. Apprendre à les reconnaître, c'est déjà les affaiblir."
        ),

        DailyProgram(
            day: 9,
            title: "Questionnement socratique",
            theme: "TCC - Restructuration",
            timeOfDay: .afternoon,
            exercises: [
                DailyExercise(
                    type: .breathing,
                    title: "4-7-8 (5 min)",
                    description: "Calmer avant de questionner",
                    durationMinutes: 5,
                    exerciseId: "478",
                    xpReward: 25
                ),
                DailyExercise(
                    type: .tcc,
                    title: "Les 5 questions",
                    description: "Face à une pensée anxieuse, pose-toi : 1) Est-ce un fait ou une opinion ? 2) Quelles preuves ? 3) Autre explication ? 4) Que dirais-je à un ami ? 5) Pire scénario réaliste ?",
                    durationMinutes: 15,
                    xpReward: 40
                ),
                DailyExercise(
                    type: .journal,
                    title: "Restructuration",
                    description: "Applique les 5 questions à 2 pensées anxieuses",
                    durationMinutes: 15,
                    xpReward: 35
                )
            ],
            guidance: "Questionne tes pensées comme un avocat questionne un témoin. La vérité émerge."
        ),

        DailyProgram(
            day: 10,
            title: "Ancrage dans le présent",
            theme: "Pleine conscience avancée",
            timeOfDay: .morning,
            exercises: [
                DailyExercise(
                    type: .breathing,
                    title: "Cohérence cardiaque (7 min)",
                    description: "Ancrer le système nerveux",
                    durationMinutes: 7,
                    exerciseId: "coherence",
                    xpReward: 30
                ),
                DailyExercise(
                    type: .meditation,
                    title: "Marche méditative",
                    description: "10 min de marche en pleine conscience",
                    durationMinutes: 10,
                    exerciseId: "walking",
                    xpReward: 30
                ),
                DailyExercise(
                    type: .journal,
                    title: "5-4-3-2-1",
                    description: "Technique d'ancrage : 5 choses que tu vois, 4 que tu touches, 3 que tu entends, 2 que tu sens, 1 que tu goûtes",
                    durationMinutes: 10,
                    xpReward: 25
                )
            ],
            guidance: "L'anxiété vit dans le futur. Le présent est ton refuge."
        ),

        DailyProgram(
            day: 11,
            title: "Exposition niveau 2",
            theme: "Affronter progressivement",
            timeOfDay: .any,
            exercises: [
                DailyExercise(
                    type: .breathing,
                    title: "4-7-8 (5 min)",
                    description: "Préparation",
                    durationMinutes: 5,
                    exerciseId: "478",
                    xpReward: 25
                ),
                DailyExercise(
                    type: .exposure,
                    title: "Exposition imaginaire (niveau 2)",
                    description: "Situation anxiogène modérée. Reste 10 min avec l'inconfort.",
                    durationMinutes: 15,
                    xpReward: 50
                ),
                DailyExercise(
                    type: .journal,
                    title: "Analyse de l'exposition",
                    description: "Niveau d'anxiété avant/pendant/après. Qu'as-tu appris ?",
                    durationMinutes: 10,
                    xpReward: 30
                )
            ],
            guidance: "Chaque exposition renforce ton courage. L'anxiété diminue toujours si tu restes."
        ),

        DailyProgram(
            day: 12,
            title: "Pensées alternatives",
            theme: "TCC - Remplacement",
            timeOfDay: .afternoon,
            exercises: [
                DailyExercise(
                    type: .breathing,
                    title: "Box Breathing (5 min)",
                    description: "Clarifier l'esprit",
                    durationMinutes: 5,
                    exerciseId: "box",
                    xpReward: 25
                ),
                DailyExercise(
                    type: .tcc,
                    title: "Générer des alternatives",
                    description: "Pour chaque pensée anxieuse, trouve 3 pensées alternatives plus réalistes",
                    durationMinutes: 15,
                    xpReward: 40
                ),
                DailyExercise(
                    type: .journal,
                    title: "Tableau de remplacement",
                    description: "Pensée anxieuse → 3 alternatives → Émotion ressentie après",
                    durationMinutes: 15,
                    xpReward: 35
                )
            ],
            guidance: "Tu n'as pas à croire chaque pensée qui passe. Tu peux en choisir de meilleures."
        ),

        DailyProgram(
            day: 13,
            title: "Respiration & mouvement",
            theme: "Corps et esprit",
            timeOfDay: .morning,
            exercises: [
                DailyExercise(
                    type: .breathing,
                    title: "Anulom-Vilom (7 min)",
                    description: "Respiration alternée",
                    durationMinutes: 7,
                    exerciseId: "anulom",
                    xpReward: 30
                ),
                DailyExercise(
                    type: .meditation,
                    title: "Scan corporel profond",
                    description: "Détendre chaque partie du corps",
                    durationMinutes: 10,
                    exerciseId: "body-scan",
                    xpReward: 25
                ),
                DailyExercise(
                    type: .journal,
                    title: "Corps libéré",
                    description: "Quelles tensions as-tu pu relâcher aujourd'hui ?",
                    durationMinutes: 8,
                    xpReward: 25
                )
            ],
            guidance: "Ton corps stocke l'anxiété. Libère-le consciemment."
        ),

        DailyProgram(
            day: 14,
            title: "Bilan semaine 2",
            theme: "Consolidation",
            timeOfDay: .evening,
            exercises: [
                DailyExercise(
                    type: .breathing,
                    title: "Respiration libre (10 min)",
                    description: "Choisis ta technique préférée",
                    durationMinutes: 10,
                    xpReward: 30
                ),
                DailyExercise(
                    type: .meditation,
                    title: "Auto-compassion",
                    description: "Bienveillance envers soi-même",
                    durationMinutes: 8,
                    exerciseId: "compassion",
                    xpReward: 25
                ),
                DailyExercise(
                    type: .journal,
                    title: "Progrès de la semaine",
                    description: "Tes distorsions cognitives préférées ? Qu'as-tu restructuré ?",
                    durationMinutes: 15,
                    xpReward: 30
                )
            ],
            checkpoint: RoutineCheckpoint(
                day: 14,
                title: "2 semaines accomplies !",
                description: "Tu as doublé ton engagement",
                badgeIcon: "checkmark.seal.fill",
                badgeColor: "4A90E2",
                bonusXP: 100
            ),
            guidance: "Deux semaines, c'est déjà un changement neurologique. Continue."
        ),

        // SEMAINE 3: Consolidation cycle 1
        DailyProgram(
            day: 15,
            title: "Exposition réelle (niveau 1)",
            theme: "Action concrète",
            timeOfDay: .any,
            exercises: [
                DailyExercise(
                    type: .breathing,
                    title: "4-7-8 (5 min)",
                    description: "Courage respiratoire",
                    durationMinutes: 5,
                    exerciseId: "478",
                    xpReward: 25
                ),
                DailyExercise(
                    type: .exposure,
                    title: "Exposition in vivo (facile)",
                    description: "Affronte une situation réelle peu anxiogène (ex: appeler un ami, aller dans un lieu public calme)",
                    durationMinutes: 20,
                    xpReward: 60
                ),
                DailyExercise(
                    type: .journal,
                    title: "Victoire du jour",
                    description: "Décris ta réussite. Niveau d'anxiété avant/après. Fierté ressentie.",
                    durationMinutes: 10,
                    xpReward: 30
                )
            ],
            guidance: "Chaque petit pas dans le réel est une victoire monumentale. Célèbre-la."
        ),

        DailyProgram(
            day: 16,
            title: "Méditation anti-rumination",
            theme: "Stop aux pensées en boucle",
            timeOfDay: .morning,
            exercises: [
                DailyExercise(
                    type: .breathing,
                    title: "Cohérence cardiaque (7 min)",
                    description: "Calmer le système",
                    durationMinutes: 7,
                    exerciseId: "coherence",
                    xpReward: 30
                ),
                DailyExercise(
                    type: .meditation,
                    title: "Clarté mentale",
                    description: "Laisser passer les ruminations",
                    durationMinutes: 12,
                    exerciseId: "clarity",
                    xpReward: 30
                ),
                DailyExercise(
                    type: .tcc,
                    title: "Technique STOP",
                    description: "S (Stop), T (Take a breath), O (Observe), P (Proceed). Pratique 5 fois dans la journée.",
                    durationMinutes: 10,
                    xpReward: 35
                ),
                DailyExercise(
                    type: .journal,
                    title: "Efficacité du STOP",
                    description: "Note quand tu l'as utilisé et l'effet obtenu",
                    durationMinutes: 8,
                    xpReward: 25
                )
            ],
            guidance: "Tu peux interrompre une rumination. STOP est ton bouton pause."
        ),

        DailyProgram(
            day: 17,
            title: "Liberté de choix",
            theme: "TCC - Empowerment",
            timeOfDay: .afternoon,
            exercises: [
                DailyExercise(
                    type: .breathing,
                    title: "Box Breathing (5 min)",
                    description: "Équilibre intérieur",
                    durationMinutes: 5,
                    exerciseId: "box",
                    xpReward: 25
                ),
                DailyExercise(
                    type: .tcc,
                    title: "Réponse vs réaction",
                    description: "Face à 3 situations anxiogènes, note : réaction automatique vs réponse choisie",
                    durationMinutes: 15,
                    xpReward: 40
                ),
                DailyExercise(
                    type: .journal,
                    title: "Pouvoir personnel",
                    description: "Dans quelles situations as-tu repris du pouvoir cette semaine ?",
                    durationMinutes: 10,
                    xpReward: 30
                )
            ],
            guidance: "Entre le stimulus et la réponse, il y a un espace. Dans cet espace, tu as le choix."
        ),

        DailyProgram(
            day: 18,
            title: "Pratique combinée",
            theme: "Synergie des outils",
            timeOfDay: .any,
            exercises: [
                DailyExercise(
                    type: .breathing,
                    title: "4-7-8 (5 min)",
                    description: "Base apaisante",
                    durationMinutes: 5,
                    exerciseId: "478",
                    xpReward: 25
                ),
                DailyExercise(
                    type: .meditation,
                    title: "Pleine conscience",
                    description: "Présence totale",
                    durationMinutes: 10,
                    exerciseId: "mindfulness",
                    xpReward: 25
                ),
                DailyExercise(
                    type: .tcc,
                    title: "Chaîne complète",
                    description: "Situation → Pensée → Distorsion → Restructuration → Nouvelle émotion. Fais l'exercice complet 2 fois.",
                    durationMinutes: 20,
                    xpReward: 50
                ),
                DailyExercise(
                    type: .journal,
                    title: "Synthèse",
                    description: "Comment les outils se complètent-ils ?",
                    durationMinutes: 10,
                    xpReward: 25
                )
            ],
            guidance: "La magie opère quand tu combines les outils. Tu deviens une machine à calmer."
        ),

        DailyProgram(
            day: 19,
            title: "Exposition niveau 3",
            theme: "Courage renforcé",
            timeOfDay: .any,
            exercises: [
                DailyExercise(
                    type: .breathing,
                    title: "Cohérence cardiaque (7 min)",
                    description: "Armure respiratoire",
                    durationMinutes: 7,
                    exerciseId: "coherence",
                    xpReward: 30
                ),
                DailyExercise(
                    type: .exposure,
                    title: "Exposition in vivo (modérée)",
                    description: "Situation réelle moyennement anxiogène (ex: prendre la parole, lieu bondé)",
                    durationMinutes: 25,
                    xpReward: 70
                ),
                DailyExercise(
                    type: .journal,
                    title: "Analyse courage",
                    description: "Anxiété avant/pendant/après. Pensées automatiques pendant l'exposition. Restructuration après.",
                    durationMinutes: 15,
                    xpReward: 35
                )
            ],
            guidance: "Ton courage grandit à chaque exposition. L'anxiété perd du terrain."
        ),

        DailyProgram(
            day: 20,
            title: "Auto-bienveillance",
            theme: "Douceur envers soi",
            timeOfDay: .evening,
            exercises: [
                DailyExercise(
                    type: .breathing,
                    title: "4-7-8 (5 min)",
                    description: "Douceur respiratoire",
                    durationMinutes: 5,
                    exerciseId: "478",
                    xpReward: 25
                ),
                DailyExercise(
                    type: .meditation,
                    title: "Auto-compassion profonde",
                    description: "Cultiver l'amour de soi",
                    durationMinutes: 12,
                    exerciseId: "compassion",
                    xpReward: 30
                ),
                DailyExercise(
                    type: .journal,
                    title: "Lettre à soi-même",
                    description: "Écris une lettre bienveillante à ton moi anxieux",
                    durationMinutes: 15,
                    xpReward: 35
                )
            ],
            guidance: "Traite-toi comme tu traiterais ton meilleur ami. Tu mérites cette douceur."
        ),

        DailyProgram(
            day: 21,
            title: "Liberté mentale",
            theme: "Synthèse du cycle",
            timeOfDay: .any,
            exercises: [
                DailyExercise(
                    type: .breathing,
                    title: "Respiration libre (10 min)",
                    description: "Technique de ton choix",
                    durationMinutes: 10,
                    xpReward: 30
                ),
                DailyExercise(
                    type: .meditation,
                    title: "Visualisation de liberté",
                    description: "Visualise-toi maîtrisant ton anxiété",
                    durationMinutes: 10,
                    exerciseId: "visualization",
                    xpReward: 30
                ),
                DailyExercise(
                    type: .journal,
                    title: "Bilan 3 semaines",
                    description: "Liste 10 changements que tu as observés. Quel outil marche le mieux pour toi ?",
                    durationMinutes: 20,
                    xpReward: 40
                )
            ],
            checkpoint: RoutineCheckpoint(
                day: 21,
                title: "3 semaines de transformation !",
                description: "21 jours, le début d'une nouvelle habitude",
                badgeIcon: "star.circle.fill",
                badgeColor: "FFD700",
                bonusXP: 150
            ),
            guidance: "21 jours. Ton cerveau a commencé sa restructuration. Continue, le meilleur arrive."
        ),

        DailyProgram(
            day: 22,
            title: "Fin du Cycle 1",
            theme: "Célébration",
            timeOfDay: .evening,
            exercises: [
                DailyExercise(
                    type: .breathing,
                    title: "Célébration respiratoire (10 min)",
                    description: "Toute technique, en conscience",
                    durationMinutes: 10,
                    xpReward: 35
                ),
                DailyExercise(
                    type: .meditation,
                    title: "Gratitude profonde",
                    description: "Reconnaissance pour le chemin parcouru",
                    durationMinutes: 10,
                    exerciseId: "gratitude",
                    xpReward: 30
                ),
                DailyExercise(
                    type: .journal,
                    title: "Rétrospective Cycle 1",
                    description: "Ton niveau d'anxiété J1 vs J22 ? Quelle est ta plus grande victoire ? Prêt pour le Cycle 2 ?",
                    durationMinutes: 20,
                    xpReward: 40
                )
            ],
            checkpoint: RoutineCheckpoint(
                day: 22,
                title: "Cycle 1 terminé : Observateur conscient",
                description: "Tu as appris à observer ton anxiété sans la subir",
                badgeIcon: "eye.fill",
                badgeColor: "4A90E2",
                bonusXP: 200
            ),
            guidance: "Tu n'es plus victime de ton anxiété. Tu es devenu son observateur. Place au Cycle 2."
        )
    ]
}

// MARK: - Master Mind Cycle 2 (Days 23-44)
private func masterMindCycle2Days() -> [DailyProgram] {
    return [
        // SEMAINE 4: TCC Avancée
        DailyProgram(
            day: 23,
            title: "Bienvenue au Cycle 2 : Déconstruire",
            theme: "Nouveau niveau",
            timeOfDay: .morning,
            exercises: [
                DailyExercise(
                    type: .breathing,
                    title: "4-7-8 puissant (10 min)",
                    description: "Ancrage renforcé",
                    durationMinutes: 10,
                    exerciseId: "478",
                    xpReward: 35
                ),
                DailyExercise(
                    type: .meditation,
                    title: "Intention du cycle",
                    description: "Pose ton intention : déconstruire les schémas limitants",
                    durationMinutes: 10,
                    exerciseId: "mindfulness",
                    xpReward: 30
                ),
                DailyExercise(
                    type: .journal,
                    title: "Schémas à déconstruire",
                    description: "Identifie 3 schémas de pensée que tu veux transformer ce cycle",
                    durationMinutes: 15,
                    xpReward: 35
                )
            ],
            guidance: "Le Cycle 2 est celui de la transformation profonde. Tes schémas vont se défaire."
        ),

        DailyProgram(
            day: 24,
            title: "Croyances fondamentales",
            theme: "TCC - Schémas profonds",
            timeOfDay: .afternoon,
            exercises: [
                DailyExercise(
                    type: .breathing,
                    title: "Cohérence cardiaque (7 min)",
                    description: "Clarté mentale",
                    durationMinutes: 7,
                    exerciseId: "coherence",
                    xpReward: 30
                ),
                DailyExercise(
                    type: .tcc,
                    title: "Flèche descendante",
                    description: "Choisis une pensée anxieuse. Demande 'Et si c'était vrai, qu'est-ce que ça signifierait ?' 5 fois jusqu'à la croyance fondamentale",
                    durationMinutes: 20,
                    xpReward: 50
                ),
                DailyExercise(
                    type: .journal,
                    title: "Croyances racines",
                    description: "Note les croyances fondamentales découvertes. Sont-elles vraies ?",
                    durationMinutes: 15,
                    xpReward: 40
                )
            ],
            guidance: "Sous tes anxiétés se cachent des croyances profondes. Trouve-les pour les défaire."
        ),

        DailyProgram(
            day: 25,
            title: "Exposition graduelle avancée",
            theme: "Courage croissant",
            timeOfDay: .any,
            exercises: [
                DailyExercise(
                    type: .breathing,
                    title: "4-7-8 (7 min)",
                    description: "Préparation courage",
                    durationMinutes: 7,
                    exerciseId: "478",
                    xpReward: 30
                ),
                DailyExercise(
                    type: .exposure,
                    title: "Exposition in vivo niveau 4",
                    description: "Situation réelle anxiogène (ex: présentation, lieu très fréquenté)",
                    durationMinutes: 30,
                    xpReward: 80
                ),
                DailyExercise(
                    type: .journal,
                    title: "Analyse exposition",
                    description: "Pensées avant/pendant/après. Restructuration appliquée.",
                    durationMinutes: 15,
                    xpReward: 40
                )
            ],
            guidance: "Chaque exposition te rend plus fort. Ton courage est maintenant une compétence."
        ),

        DailyProgram(
            day: 26,
            title: "Acceptation radicale",
            theme: "TCC - Lâcher-prise",
            timeOfDay: .afternoon,
            exercises: [
                DailyExercise(
                    type: .breathing,
                    title: "Cohérence cardiaque (10 min)",
                    description: "Ouverture intérieure",
                    durationMinutes: 10,
                    exerciseId: "coherence",
                    xpReward: 35
                ),
                DailyExercise(
                    type: .tcc,
                    title: "Pratique d'acceptation",
                    description: "Au lieu de combattre une anxiété, accueille-la complètement pendant 10 min. Observe ce qui se passe.",
                    durationMinutes: 15,
                    xpReward: 45
                ),
                DailyExercise(
                    type: .meditation,
                    title: "Méditation d'acceptation",
                    description: "Tout est bienvenu",
                    durationMinutes: 12,
                    exerciseId: "mindfulness",
                    xpReward: 30
                ),
                DailyExercise(
                    type: .journal,
                    title: "Pouvoir de l'acceptation",
                    description: "Qu'as-tu ressenti en acceptant plutôt qu'en combattant ?",
                    durationMinutes: 10,
                    xpReward: 30
                )
            ],
            guidance: "Ce que tu résistes persiste. Ce que tu acceptes se transforme."
        ),

        DailyProgram(
            day: 27,
            title: "Pensée flexible",
            theme: "TCC - Nuances",
            timeOfDay: .afternoon,
            exercises: [
                DailyExercise(
                    type: .breathing,
                    title: "Box Breathing (7 min)",
                    description: "Équilibre mental",
                    durationMinutes: 7,
                    exerciseId: "box",
                    xpReward: 30
                ),
                DailyExercise(
                    type: .tcc,
                    title: "Échelle de gris",
                    description: "Pour 3 pensées tout-ou-rien, trouve 5 nuances intermédiaires sur l'échelle 0-100",
                    durationMinutes: 20,
                    xpReward: 45
                ),
                DailyExercise(
                    type: .journal,
                    title: "Flexibilité cognitive",
                    description: "Comment penser en nuances change ton anxiété ?",
                    durationMinutes: 12,
                    xpReward: 35
                )
            ],
            guidance: "Le monde n'est pas noir ou blanc. Dans les nuances de gris se cache ta liberté."
        ),

        DailyProgram(
            day: 28,
            title: "Checkpoint Semaine 4",
            theme: "Consolidation",
            timeOfDay: .evening,
            exercises: [
                DailyExercise(
                    type: .breathing,
                    title: "Respiration libre (10 min)",
                    description: "Ta technique favorite",
                    durationMinutes: 10,
                    xpReward: 35
                ),
                DailyExercise(
                    type: .meditation,
                    title: "Scan profond",
                    description: "Corps et esprit unifiés",
                    durationMinutes: 12,
                    exerciseId: "body-scan",
                    xpReward: 30
                ),
                DailyExercise(
                    type: .journal,
                    title: "Bilan semaine 4",
                    description: "Quelles croyances as-tu challengées ? Progrès ressenti ?",
                    durationMinutes: 15,
                    xpReward: 35
                )
            ],
            checkpoint: RoutineCheckpoint(
                day: 28,
                title: "4 semaines de maîtrise !",
                description: "Un mois de transformation continue",
                badgeIcon: "calendar.circle.fill",
                badgeColor: "4A90E2",
                bonusXP: 150
            ),
            guidance: "Un mois. Ton cerveau se recâble. Tes anxiétés perdent du pouvoir."
        ),

        DailyProgram(
            day: 29,
            title: "Ancrage profond",
            theme: "Présence renforcée",
            timeOfDay: .morning,
            exercises: [
                DailyExercise(
                    type: .breathing,
                    title: "Anulom-Vilom (10 min)",
                    description: "Équilibre des hémisphères",
                    durationMinutes: 10,
                    exerciseId: "anulom",
                    xpReward: 35
                ),
                DailyExercise(
                    type: .meditation,
                    title: "Ancrage profond",
                    description: "Racines dans la terre",
                    durationMinutes: 15,
                    exerciseId: "grounding",
                    xpReward: 35
                ),
                DailyExercise(
                    type: .journal,
                    title: "Stabilité intérieure",
                    description: "Comment te sens-tu ancré maintenant vs J1 ?",
                    durationMinutes: 10,
                    xpReward: 30
                )
            ],
            guidance: "Ton ancrage s'approfondit. Tu deviens inébranlable."
        ),

        DailyProgram(
            day: 30,
            title: "Résilience mentale",
            theme: "Force intérieure",
            timeOfDay: .any,
            exercises: [
                DailyExercise(
                    type: .breathing,
                    title: "4-7-8 (10 min)",
                    description: "Force tranquille",
                    durationMinutes: 10,
                    exerciseId: "478",
                    xpReward: 35
                ),
                DailyExercise(
                    type: .tcc,
                    title: "Journal de résilience",
                    description: "Liste 10 fois où tu as surmonté l'anxiété ces 30 jours",
                    durationMinutes: 20,
                    xpReward: 45
                ),
                DailyExercise(
                    type: .meditation,
                    title: "Force intérieure",
                    description: "Visualisation de ta résilience",
                    durationMinutes: 12,
                    exerciseId: "visualization",
                    xpReward: 30
                )
            ],
            checkpoint: RoutineCheckpoint(
                day: 30,
                title: "30 jours de transformation !",
                description: "Un mois complet de maîtrise",
                badgeIcon: "trophy.fill",
                badgeColor: "FFD700",
                bonusXP: 200
            ),
            guidance: "30 jours. Tu as bâti une résilience mentale. Continue."
        ),

        DailyProgram(
            day: 31,
            title: "Métacognition",
            theme: "Penser sur ta pensée",
            timeOfDay: .afternoon,
            exercises: [
                DailyExercise(
                    type: .breathing,
                    title: "Cohérence cardiaque (10 min)",
                    description: "Clarté maximale",
                    durationMinutes: 10,
                    exerciseId: "coherence",
                    xpReward: 35
                ),
                DailyExercise(
                    type: .tcc,
                    title: "Observer l'observateur",
                    description: "Prends conscience de comment tu penses. Note les schémas.",
                    durationMinutes: 20,
                    xpReward: 50
                ),
                DailyExercise(
                    type: .journal,
                    title: "Conscience de la conscience",
                    description: "Décris comment tu observes maintenant tes pensées",
                    durationMinutes: 15,
                    xpReward: 35
                )
            ],
            guidance: "Tu ne penses plus seulement. Tu observes comment tu penses. C'est la vraie maîtrise."
        ),

        DailyProgram(
            day: 32,
            title: "Exposition niveau 5",
            theme: "Courage maximal",
            timeOfDay: .any,
            exercises: [
                DailyExercise(
                    type: .breathing,
                    title: "Préparation respiratoire (10 min)",
                    description: "Toute technique combinée",
                    durationMinutes: 10,
                    xpReward: 35
                ),
                DailyExercise(
                    type: .exposure,
                    title: "Exposition in vivo maximale",
                    description: "Affronte ta situation la plus anxiogène (avec sécurité)",
                    durationMinutes: 40,
                    xpReward: 100
                ),
                DailyExercise(
                    type: .journal,
                    title: "Victoire ultime",
                    description: "Tu l'as fait ! Décris cette victoire en détail.",
                    durationMinutes: 20,
                    xpReward: 50
                )
            ],
            guidance: "Tu viens d'accomplir quelque chose d'extraordinaire. Ton courage est maintenant une force."
        ),

        DailyProgram(
            day: 33,
            title: "Auto-compassion avancée",
            theme: "Amour de soi",
            timeOfDay: .evening,
            exercises: [
                DailyExercise(
                    type: .breathing,
                    title: "Respiration douce (10 min)",
                    description: "Tendresse respiratoire",
                    durationMinutes: 10,
                    xpReward: 35
                ),
                DailyExercise(
                    type: .meditation,
                    title: "Loving-kindness",
                    description: "Compassion pour soi et les autres",
                    durationMinutes: 15,
                    exerciseId: "compassion",
                    xpReward: 35
                ),
                DailyExercise(
                    type: .journal,
                    title: "Lettre d'amour à soi",
                    description: "Écris pourquoi tu es fier de toi après 33 jours",
                    durationMinutes: 15,
                    xpReward: 35
                )
            ],
            guidance: "Tu mérites ta propre compassion. Tu as accompli tellement."
        ),

        DailyProgram(
            day: 34,
            title: "Intégration corps-esprit",
            theme: "Unité",
            timeOfDay: .morning,
            exercises: [
                DailyExercise(
                    type: .breathing,
                    title: "Cohérence cardiaque avancée (15 min)",
                    description: "Union parfaite",
                    durationMinutes: 15,
                    xpReward: 40
                ),
                DailyExercise(
                    type: .meditation,
                    title: "Body-mind unity",
                    description: "Sentir l'unité corps-esprit",
                    durationMinutes: 15,
                    exerciseId: "body-scan",
                    xpReward: 35
                ),
                DailyExercise(
                    type: .journal,
                    title: "Unification",
                    description: "Comment ton corps et ton esprit communiquent-ils maintenant ?",
                    durationMinutes: 10,
                    xpReward: 30
                )
            ],
            guidance: "Ton corps et ton esprit ne font qu'un. L'anxiété perd son emprise."
        ),

        DailyProgram(
            day: 35,
            title: "Checkpoint Semaine 5",
            theme: "Mi-chemin du Cycle 2",
            timeOfDay: .evening,
            exercises: [
                DailyExercise(
                    type: .breathing,
                    title: "Respiration célébration (15 min)",
                    description: "Ta signature personnelle",
                    durationMinutes: 15,
                    xpReward: 40
                ),
                DailyExercise(
                    type: .meditation,
                    title: "Gratitude profonde",
                    description: "5 semaines de chemin",
                    durationMinutes: 12,
                    exerciseId: "gratitude",
                    xpReward: 35
                ),
                DailyExercise(
                    type: .journal,
                    title: "Bilan 5 semaines",
                    description: "Niveau d'anxiété général J1 vs J35 ? Plus grandes victoires ?",
                    durationMinutes: 20,
                    xpReward: 40
                )
            ],
            checkpoint: RoutineCheckpoint(
                day: 35,
                title: "5 semaines de maîtrise !",
                description: "Plus de la moitié du chemin parcouru",
                badgeIcon: "star.leadinghalf.filled",
                badgeColor: "4A90E2",
                bonusXP: 150
            ),
            guidance: "Plus de la moitié. Ton anxiété n'est plus la même. Continue."
        ),

        DailyProgram(
            day: 36,
            title: "Défusion avancée",
            theme: "Distance totale",
            timeOfDay: .afternoon,
            exercises: [
                DailyExercise(
                    type: .breathing,
                    title: "4-7-8 (10 min)",
                    description: "Espace mental",
                    durationMinutes: 10,
                    exerciseId: "478",
                    xpReward: 35
                ),
                DailyExercise(
                    type: .tcc,
                    title: "Pensées comme passagers",
                    description: "Visualise tes pensées anxieuses comme des passagers dans un bus. Tu es le conducteur.",
                    durationMinutes: 15,
                    xpReward: 45
                ),
                DailyExercise(
                    type: .meditation,
                    title: "Observateur pur",
                    description: "Être simplement conscient",
                    durationMinutes: 15,
                    exerciseId: "mindfulness",
                    xpReward: 35
                ),
                DailyExercise(
                    type: .journal,
                    title: "Je ne suis pas mes pensées",
                    description: "Explique cette phrase avec tes propres mots après 36 jours",
                    durationMinutes: 12,
                    xpReward: 30
                )
            ],
            guidance: "Tu n'es pas tes pensées. Tu es la conscience qui les observe."
        ),

        DailyProgram(
            day: 37,
            title: "Valeurs et direction",
            theme: "Vie alignée",
            timeOfDay: .any,
            exercises: [
                DailyExercise(
                    type: .breathing,
                    title: "Cohérence cardiaque (10 min)",
                    description: "Clarté de valeurs",
                    durationMinutes: 10,
                    exerciseId: "coherence",
                    xpReward: 35
                ),
                DailyExercise(
                    type: .tcc,
                    title: "Définir tes valeurs",
                    description: "Liste tes 5 valeurs fondamentales. Comment l'anxiété t'empêchait de les vivre ?",
                    durationMinutes: 20,
                    xpReward: 45
                ),
                DailyExercise(
                    type: .journal,
                    title: "Vie de valeurs",
                    description: "Comment peux-tu vivre plus aligné avec tes valeurs maintenant ?",
                    durationMinutes: 15,
                    xpReward: 35
                )
            ],
            guidance: "L'anxiété te détournait de tes valeurs. Maintenant, tu peux les vivre."
        ),

        DailyProgram(
            day: 38,
            title: "Pratique intégrée",
            theme: "Tout ensemble",
            timeOfDay: .any,
            exercises: [
                DailyExercise(
                    type: .breathing,
                    title: "Routine respiratoire complète (15 min)",
                    description: "Tous les types de respiration",
                    durationMinutes: 15,
                    xpReward: 40
                ),
                DailyExercise(
                    type: .meditation,
                    title: "Méditation totale",
                    description: "Tous les aspects : scan, pleine conscience, compassion",
                    durationMinutes: 20,
                    xpReward: 45
                ),
                DailyExercise(
                    type: .tcc,
                    title: "TCC complète",
                    description: "Situation → Pensée → Distorsion → Questionnement → Alternatives → Acceptation → Action",
                    durationMinutes: 25,
                    xpReward: 55
                ),
                DailyExercise(
                    type: .journal,
                    title: "Synthèse totale",
                    description: "Comment tous les outils s'imbriquent-ils ?",
                    durationMinutes: 15,
                    xpReward: 35
                )
            ],
            guidance: "Tous les outils ensemble. Tu es une machine à maîtriser l'anxiété."
        ),

        DailyProgram(
            day: 39,
            title: "Maintien de la sérénité",
            theme: "Prévention rechute",
            timeOfDay: .any,
            exercises: [
                DailyExercise(
                    type: .breathing,
                    title: "Respiration préventive (10 min)",
                    description: "Ancrage quotidien",
                    durationMinutes: 10,
                    xpReward: 35
                ),
                DailyExercise(
                    type: .tcc,
                    title: "Plan de prévention",
                    description: "Liste les signaux d'alerte précoce. Crée ton plan d'action si l'anxiété revient.",
                    durationMinutes: 20,
                    xpReward: 50
                ),
                DailyExercise(
                    type: .journal,
                    title: "Stratégies de maintien",
                    description: "Quelle routine quotidienne vas-tu garder après les 66 jours ?",
                    durationMinutes: 15,
                    xpReward: 35
                )
            ],
            guidance: "Prévenir vaut mieux que guérir. Tu construis ton bouclier permanent."
        ),

        DailyProgram(
            day: 40,
            title: "Liberté émotionnelle",
            theme: "Acceptation totale",
            timeOfDay: .evening,
            exercises: [
                DailyExercise(
                    type: .breathing,
                    title: "Respiration d'ouverture (12 min)",
                    description: "Accueillir toutes les émotions",
                    durationMinutes: 12,
                    xpReward: 35
                ),
                DailyExercise(
                    type: .meditation,
                    title: "Toutes les émotions bienvenues",
                    description: "Méditation d'acceptation émotionnelle",
                    durationMinutes: 15,
                    exerciseId: "mindfulness",
                    xpReward: 35
                ),
                DailyExercise(
                    type: .journal,
                    title: "Palette émotionnelle",
                    description: "Toutes tes émotions sont valides. Décris ta relation avec elles maintenant.",
                    durationMinutes: 15,
                    xpReward: 35
                )
            ],
            guidance: "Tu n'as plus peur de tes émotions. Elles passent comme des vagues."
        ),

        DailyProgram(
            day: 41,
            title: "Action engagée",
            theme: "Vivre pleinement",
            timeOfDay: .any,
            exercises: [
                DailyExercise(
                    type: .breathing,
                    title: "Respiration de courage (10 min)",
                    description: "Force pour l'action",
                    durationMinutes: 10,
                    xpReward: 35
                ),
                DailyExercise(
                    type: .exposure,
                    title: "Action alignée avec tes valeurs",
                    description: "Fais quelque chose que tu évitais qui est important pour toi",
                    durationMinutes: 30,
                    xpReward: 80
                ),
                DailyExercise(
                    type: .journal,
                    title: "Vie riche",
                    description: "Comment agir malgré l'anxiété enrichit ta vie ?",
                    durationMinutes: 15,
                    xpReward: 35
                )
            ],
            guidance: "Tu n'attends plus que l'anxiété parte pour vivre. Tu vis malgré elle."
        ),

        DailyProgram(
            day: 42,
            title: "Checkpoint Semaine 6",
            theme: "Fin du Cycle 2 approche",
            timeOfDay: .evening,
            exercises: [
                DailyExercise(
                    type: .breathing,
                    title: "Respiration libre (15 min)",
                    description: "À ta façon",
                    durationMinutes: 15,
                    xpReward: 40
                ),
                DailyExercise(
                    type: .meditation,
                    title: "Clarté et gratitude",
                    description: "6 semaines de transformation",
                    durationMinutes: 15,
                    exerciseId: "clarity",
                    xpReward: 35
                ),
                DailyExercise(
                    type: .journal,
                    title: "Bilan 6 semaines",
                    description: "Tes schémas déconstruits ? Quelle personne deviens-tu ?",
                    durationMinutes: 20,
                    xpReward: 40
                )
            ],
            checkpoint: RoutineCheckpoint(
                day: 42,
                title: "6 semaines accomplies !",
                description: "Tu approches de la maîtrise totale",
                badgeIcon: "bolt.fill",
                badgeColor: "FFD700",
                bonusXP: 150
            ),
            guidance: "6 semaines. Tu as déconstruit tellement. Le Cycle 3 sera celui de ta maîtrise totale."
        ),

        DailyProgram(
            day: 43,
            title: "Préparation au Cycle 3",
            theme: "Autonomie proche",
            timeOfDay: .any,
            exercises: [
                DailyExercise(
                    type: .breathing,
                    title: "Respiration personnalisée (15 min)",
                    description: "Crée ton propre protocole",
                    durationMinutes: 15,
                    xpReward: 40
                ),
                DailyExercise(
                    type: .meditation,
                    title: "Méditation libre",
                    description: "Sans guide, en pleine autonomie",
                    durationMinutes: 15,
                    xpReward: 35
                ),
                DailyExercise(
                    type: .journal,
                    title: "Vision du Cycle 3",
                    description: "Que veux-tu accomplir dans le Cycle 3 ? Comment veux-tu vivre après les 66 jours ?",
                    durationMinutes: 20,
                    xpReward: 40
                )
            ],
            guidance: "Le Cycle 3 sera ton cycle. Tu es prêt pour l'autonomie totale."
        ),

        DailyProgram(
            day: 44,
            title: "Fin du Cycle 2",
            theme: "Célébration de la déconstruction",
            timeOfDay: .evening,
            exercises: [
                DailyExercise(
                    type: .breathing,
                    title: "Respiration de victoire (15 min)",
                    description: "Toutes techniques combinées",
                    durationMinutes: 15,
                    xpReward: 40
                ),
                DailyExercise(
                    type: .meditation,
                    title: "Gratitude transformatrice",
                    description: "Reconnaissance pour les schémas défaits",
                    durationMinutes: 12,
                    exerciseId: "gratitude",
                    xpReward: 35
                ),
                DailyExercise(
                    type: .journal,
                    title: "Rétrospective Cycle 2",
                    description: "Comparaison J1 vs J44. Quels schémas as-tu déconstruits ? Comment ton anxiété a-t-elle changé ?",
                    durationMinutes: 25,
                    xpReward: 50
                )
            ],
            checkpoint: RoutineCheckpoint(
                day: 44,
                title: "Cycle 2 achevé : Architecte mental",
                description: "Tu as déconstruit et reconstruit ton rapport à l'anxiété",
                badgeIcon: "hammer.fill",
                badgeColor: "5BA3E2",
                bonusXP: 250
            ),
            guidance: "Tu as déconstruit tes anciens schémas. Place maintenant à la maîtrise totale."
        )
    ]
}

// MARK: - Master Mind Cycle 3 (Days 45-66)
private func masterMindCycle3Days() -> [DailyProgram] {
    return [
        // SEMAINE 7: Autonomie et personnalisation
        DailyProgram(
            day: 45,
            title: "Bienvenue au Cycle 3 : Maîtriser",
            theme: "Autonomie",
            timeOfDay: .morning,
            exercises: [
                DailyExercise(
                    type: .breathing,
                    title: "Ta routine respiratoire personnalisée",
                    description: "Crée ton propre enchaînement de 15 min",
                    durationMinutes: 15,
                    xpReward: 40
                ),
                DailyExercise(
                    type: .meditation,
                    title: "Méditation libre",
                    description: "Sans guide, en pleine autonomie",
                    durationMinutes: 15,
                    xpReward: 35
                ),
                DailyExercise(
                    type: .journal,
                    title: "Ma routine idéale",
                    description: "Conçois ta routine quotidienne anti-anxiété personnalisée",
                    durationMinutes: 20,
                    xpReward: 40
                )
            ],
            guidance: "Le Cycle 3 est celui de l'autonomie. Tu es maintenant ton propre maître."
        ),

        DailyProgram(
            day: 46,
            title: "Autonomie respiratoire",
            theme: "Ta signature",
            timeOfDay: .morning,
            exercises: [
                DailyExercise(
                    type: .breathing,
                    title: "Protocole personnalisé (20 min)",
                    description: "Crée et exécute ton propre protocole unique",
                    durationMinutes: 20,
                    xpReward: 45
                ),
                DailyExercise(
                    type: .journal,
                    title: "Manuel personnel",
                    description: "Documente ton protocole respiratoire unique",
                    durationMinutes: 15,
                    xpReward: 35
                )
            ],
            guidance: "Tu n'as plus besoin de guide. Tu es devenu le maître."
        ),

        DailyProgram(
            day: 47,
            title: "Méditation maîtrisée",
            theme: "Autonomie contemplative",
            timeOfDay: .any,
            exercises: [
                DailyExercise(
                    type: .meditation,
                    title: "Méditation autonome (25 min)",
                    description: "Sans audio, sans guide. Pure présence.",
                    durationMinutes: 25,
                    xpReward: 50
                ),
                DailyExercise(
                    type: .journal,
                    title: "État méditatif",
                    description: "Décris ton expérience méditative aujourd'hui",
                    durationMinutes: 12,
                    xpReward: 30
                )
            ],
            guidance: "La méditation est maintenant un état naturel pour toi."
        ),

        DailyProgram(
            day: 48,
            title: "Vie quotidienne consciente",
            theme: "Intégration totale",
            timeOfDay: .any,
            exercises: [
                DailyExercise(
                    type: .tcc,
                    title: "Pratique continue",
                    description: "Applique tes outils TCC à 5 moments de la journée",
                    durationMinutes: 30,
                    xpReward: 50
                ),
                DailyExercise(
                    type: .journal,
                    title: "Mindful living",
                    description: "Comment vis-tu maintenant en pleine conscience ?",
                    durationMinutes: 15,
                    xpReward: 35
                )
            ],
            guidance: "Tes outils ne sont plus des exercices. Ils sont qui tu es."
        ),

        DailyProgram(
            day: 49,
            title: "Checkpoint Semaine 7",
            theme: "7 semaines de maîtrise",
            timeOfDay: .evening,
            exercises: [
                DailyExercise(
                    type: .breathing,
                    title: "Célébration respiratoire (20 min)",
                    description: "Ton protocole signature",
                    durationMinutes: 20,
                    xpReward: 45
                ),
                DailyExercise(
                    type: .meditation,
                    title: "Gratitude profonde",
                    description: "7 semaines de transformation",
                    durationMinutes: 15,
                    exerciseId: "gratitude",
                    xpReward: 35
                ),
                DailyExercise(
                    type: .journal,
                    title: "Bilan 7 semaines",
                    description: "Qui étais-tu J1 ? Qui es-tu maintenant ?",
                    durationMinutes: 25,
                    xpReward: 45
                )
            ],
            checkpoint: RoutineCheckpoint(
                day: 49,
                title: "7 semaines accomplies !",
                description: "L'autonomie est tienne",
                badgeIcon: "star.circle.fill",
                badgeColor: "FFD700",
                bonusXP: 200
            ),
            guidance: "7 semaines. Tu es devenu autonome. Continue ton chemin."
        ),

        DailyProgram(
            day: 50,
            title: "Partage et transmission",
            theme: "Aider les autres",
            timeOfDay: .any,
            exercises: [
                DailyExercise(
                    type: .breathing,
                    title: "Respiration personnalisée (15 min)",
                    description: "Ta pratique quotidienne",
                    durationMinutes: 15,
                    xpReward: 40
                ),
                DailyExercise(
                    type: .journal,
                    title: "Lettre à ton moi anxieux du J1",
                    description: "Que lui dirais-tu maintenant ? Quels conseils ?",
                    durationMinutes: 25,
                    xpReward: 50
                )
            ],
            guidance: "Tu peux maintenant aider d'autres à trouver leur chemin."
        ),

        DailyProgram(
            day: 51,
            title: "Ancrage inébranlable",
            theme: "Stabilité totale",
            timeOfDay: .morning,
            exercises: [
                DailyExercise(
                    type: .breathing,
                    title: "Ancrage respiratoire (20 min)",
                    description: "Racines profondes",
                    durationMinutes: 20,
                    xpReward: 45
                ),
                DailyExercise(
                    type: .meditation,
                    title: "Ancrage total",
                    description: "Inébranlable face à tout",
                    durationMinutes: 20,
                    exerciseId: "grounding",
                    xpReward: 40
                ),
                DailyExercise(
                    type: .journal,
                    title: "Ma stabilité",
                    description: "Décris ta stabilité intérieure maintenant",
                    durationMinutes: 15,
                    xpReward: 35
                )
            ],
            guidance: "Rien ne peut plus te déstabiliser profondément. Tu es ancré."
        ),

        DailyProgram(
            day: 52,
            title: "Exposition libre",
            theme: "Courage naturel",
            timeOfDay: .any,
            exercises: [
                DailyExercise(
                    type: .breathing,
                    title: "Préparation (10 min)",
                    description: "Respiration de courage",
                    durationMinutes: 10,
                    xpReward: 35
                ),
                DailyExercise(
                    type: .exposure,
                    title: "Exposition choisie",
                    description: "Choisis une situation que tu veux affronter",
                    durationMinutes: 30,
                    xpReward: 70
                ),
                DailyExercise(
                    type: .journal,
                    title: "Courage acquis",
                    description: "Le courage est maintenant une seconde nature",
                    durationMinutes: 15,
                    xpReward: 35
                )
            ],
            guidance: "Tu n'évites plus. Tu choisis d'affronter."
        ),

        DailyProgram(
            day: 53,
            title: "Pratique libre",
            theme: "Totale autonomie",
            timeOfDay: .any,
            exercises: [
                DailyExercise(
                    type: .breathing,
                    title: "Respiration libre (temps libre)",
                    description: "Pratique selon ton besoin",
                    durationMinutes: 15,
                    xpReward: 40
                ),
                DailyExercise(
                    type: .meditation,
                    title: "Méditation libre (temps libre)",
                    description: "À ta façon, à ton rythme",
                    durationMinutes: 15,
                    xpReward: 35
                ),
                DailyExercise(
                    type: .journal,
                    title: "Réflexion libre",
                    description: "Écris librement sur ton évolution",
                    durationMinutes: 20,
                    xpReward: 40
                )
            ],
            guidance: "Tu n'as plus besoin d'instructions. Tu sais ce dont tu as besoin."
        ),

        DailyProgram(
            day: 54,
            title: "Sagesse acquise",
            theme: "Intégration profonde",
            timeOfDay: .evening,
            exercises: [
                DailyExercise(
                    type: .meditation,
                    title: "Méditation de sagesse",
                    description: "Contempler le chemin parcouru",
                    durationMinutes: 25,
                    exerciseId: "mindfulness",
                    xpReward: 45
                ),
                DailyExercise(
                    type: .journal,
                    title: "Mes apprentissages",
                    description: "Liste 20 choses que tu as apprises sur toi",
                    durationMinutes: 25,
                    xpReward: 45
                )
            ],
            guidance: "Tu as acquis une sagesse que peu possèdent."
        ),

        DailyProgram(
            day: 55,
            title: "Nouvelle identité",
            theme: "Transformation complète",
            timeOfDay: .any,
            exercises: [
                DailyExercise(
                    type: .breathing,
                    title: "Respiration d'identité (20 min)",
                    description: "Respire dans ta nouvelle identité",
                    durationMinutes: 20,
                    xpReward: 45
                ),
                DailyExercise(
                    type: .journal,
                    title: "Qui suis-je devenu ?",
                    description: "Décris en détail ta nouvelle identité",
                    durationMinutes: 30,
                    xpReward: 55
                )
            ],
            guidance: "Tu n'es plus la même personne. Embrasse qui tu es devenu."
        ),

        DailyProgram(
            day: 56,
            title: "Checkpoint Semaine 8",
            theme: "8 semaines de transformation",
            timeOfDay: .evening,
            exercises: [
                DailyExercise(
                    type: .breathing,
                    title: "Protocole signature (25 min)",
                    description: "Ta marque unique",
                    durationMinutes: 25,
                    xpReward: 50
                ),
                DailyExercise(
                    type: .meditation,
                    title: "Gratitude ultime",
                    description: "8 semaines de chemin",
                    durationMinutes: 20,
                    exerciseId: "gratitude",
                    xpReward: 40
                ),
                DailyExercise(
                    type: .journal,
                    title: "Bilan 8 semaines",
                    description: "Rétrospective complète. Mesure tes progrès.",
                    durationMinutes: 30,
                    xpReward: 50
                )
            ],
            checkpoint: RoutineCheckpoint(
                day: 56,
                title: "8 semaines accomplies !",
                description: "Transformation profonde réalisée",
                badgeIcon: "sparkles",
                badgeColor: "FFD700",
                bonusXP: 250
            ),
            guidance: "8 semaines. La science dit que ton cerveau a changé. Tu le sais."
        ),

        DailyProgram(
            day: 57,
            title: "Vision du futur",
            theme: "Après les 66 jours",
            timeOfDay: .any,
            exercises: [
                DailyExercise(
                    type: .meditation,
                    title: "Visualisation du futur",
                    description: "Visualise ta vie après le programme",
                    durationMinutes: 20,
                    exerciseId: "visualization",
                    xpReward: 45
                ),
                DailyExercise(
                    type: .journal,
                    title: "Plan de maintien",
                    description: "Crée ton plan de routine post-66 jours",
                    durationMinutes: 30,
                    xpReward: 50
                )
            ],
            guidance: "Les 66 jours sont un début. Planifie ta vie post-programme."
        ),

        DailyProgram(
            day: 58,
            title: "Maîtrise respiratoire",
            theme: "Expert du souffle",
            timeOfDay: .morning,
            exercises: [
                DailyExercise(
                    type: .breathing,
                    title: "Session complète (30 min)",
                    description: "Tous tes outils respiratoires",
                    durationMinutes: 30,
                    xpReward: 55
                ),
                DailyExercise(
                    type: .journal,
                    title: "Expert respiratoire",
                    description: "Comment la respiration a changé ta vie ?",
                    durationMinutes: 20,
                    xpReward: 40
                )
            ],
            guidance: "Tu es maintenant un expert de la respiration. C'est une compétence à vie."
        ),

        DailyProgram(
            day: 59,
            title: "Méditation profonde",
            theme: "Maître méditatif",
            timeOfDay: .any,
            exercises: [
                DailyExercise(
                    type: .meditation,
                    title: "Session profonde (40 min)",
                    description: "Méditation autonome prolongée",
                    durationMinutes: 40,
                    xpReward: 70
                ),
                DailyExercise(
                    type: .journal,
                    title: "État méditatif permanent",
                    description: "Comment la méditation imprègne ta vie ?",
                    durationMinutes: 15,
                    xpReward: 35
                )
            ],
            guidance: "La méditation n'est plus une pratique. C'est un état d'être."
        ),

        DailyProgram(
            day: 60,
            title: "Liberté totale",
            theme: "Vivre sans peur",
            timeOfDay: .any,
            exercises: [
                DailyExercise(
                    type: .breathing,
                    title: "Respiration de liberté (20 min)",
                    description: "Souffle libre",
                    durationMinutes: 20,
                    xpReward: 45
                ),
                DailyExercise(
                    type: .exposure,
                    title: "Action libre",
                    description: "Fais quelque chose que tu n'aurais jamais fait avant",
                    durationMinutes: 40,
                    xpReward: 80
                ),
                DailyExercise(
                    type: .journal,
                    title: "Célébration de liberté",
                    description: "Célèbre ta liberté nouvellement trouvée",
                    durationMinutes: 20,
                    xpReward: 45
                )
            ],
            checkpoint: RoutineCheckpoint(
                day: 60,
                title: "60 jours de maîtrise !",
                description: "Tu es libre. Tu as maîtrisé.",
                badgeIcon: "bird.fill",
                badgeColor: "00D4FF",
                bonusXP: 300
            ),
            guidance: "60 jours. Tu es libre. L'anxiété ne te contrôle plus."
        ),

        DailyProgram(
            day: 61,
            title: "Dernière ligne droite",
            theme: "Vers l'accomplissement",
            timeOfDay: .any,
            exercises: [
                DailyExercise(
                    type: .breathing,
                    title: "Protocole personnel (25 min)",
                    description: "Ta signature respiratoire",
                    durationMinutes: 25,
                    xpReward: 50
                ),
                DailyExercise(
                    type: .meditation,
                    title: "Méditation profonde (25 min)",
                    description: "Présence totale",
                    durationMinutes: 25,
                    xpReward: 45
                ),
                DailyExercise(
                    type: .journal,
                    title: "Presque là",
                    description: "Réflexion sur les 5 derniers jours à venir",
                    durationMinutes: 20,
                    xpReward: 40
                )
            ],
            guidance: "Plus que 5 jours. Tu vas accomplir quelque chose d'extraordinaire."
        ),

        DailyProgram(
            day: 62,
            title: "Force intérieure",
            theme: "Résilience totale",
            timeOfDay: .any,
            exercises: [
                DailyExercise(
                    type: .breathing,
                    title: "Respiration de force (20 min)",
                    description: "Ta force intérieure",
                    durationMinutes: 20,
                    xpReward: 45
                ),
                DailyExercise(
                    type: .meditation,
                    title: "Force et sérénité",
                    description: "L'union de la force et de la paix",
                    durationMinutes: 20,
                    exerciseId: "mindfulness",
                    xpReward: 40
                ),
                DailyExercise(
                    type: .journal,
                    title: "Ma résilience",
                    description: "Décris la force que tu as bâtie",
                    durationMinutes: 20,
                    xpReward: 40
                )
            ],
            guidance: "Ta résilience est maintenant inébranlable."
        ),

        DailyProgram(
            day: 63,
            title: "Checkpoint Semaine 9",
            theme: "9 semaines de maîtrise",
            timeOfDay: .evening,
            exercises: [
                DailyExercise(
                    type: .breathing,
                    title: "Célébration respiratoire (30 min)",
                    description: "Grand protocole",
                    durationMinutes: 30,
                    xpReward: 55
                ),
                DailyExercise(
                    type: .meditation,
                    title: "Gratitude immense",
                    description: "9 semaines de chemin",
                    durationMinutes: 25,
                    exerciseId: "gratitude",
                    xpReward: 50
                ),
                DailyExercise(
                    type: .journal,
                    title: "Rétrospective 9 semaines",
                    description: "Compare J1 et J63. Mesure l'immensité du changement.",
                    durationMinutes: 35,
                    xpReward: 60
                )
            ],
            checkpoint: RoutineCheckpoint(
                day: 63,
                title: "9 semaines accomplies !",
                description: "L'accomplissement approche",
                badgeIcon: "flag.checkered",
                badgeColor: "FFD700",
                bonusXP: 250
            ),
            guidance: "9 semaines. Plus que 3 jours. Tu vas bientôt accomplir les 66 jours."
        ),

        DailyProgram(
            day: 64,
            title: "Avant-dernier jour",
            theme: "Presque accompli",
            timeOfDay: .any,
            exercises: [
                DailyExercise(
                    type: .breathing,
                    title: "Protocole signature (25 min)",
                    description: "Ta marque unique",
                    durationMinutes: 25,
                    xpReward: 50
                ),
                DailyExercise(
                    type: .meditation,
                    title: "Méditation contemplative (30 min)",
                    description: "Contempler le chemin parcouru",
                    durationMinutes: 30,
                    xpReward: 55
                ),
                DailyExercise(
                    type: .journal,
                    title: "Presque là",
                    description: "Plus que 2 jours. Comment te sens-tu ?",
                    durationMinutes: 25,
                    xpReward: 45
                )
            ],
            guidance: "Demain sera le dernier jour. Savoure ce moment."
        ),

        DailyProgram(
            day: 65,
            title: "Dernier jour de pratique",
            theme: "Veille de l'accomplissement",
            timeOfDay: .any,
            exercises: [
                DailyExercise(
                    type: .breathing,
                    title: "Session respiratoire complète (35 min)",
                    description: "Toutes tes techniques",
                    durationMinutes: 35,
                    xpReward: 60
                ),
                DailyExercise(
                    type: .meditation,
                    title: "Méditation d'achèvement (30 min)",
                    description: "Prépare-toi à l'accomplissement",
                    durationMinutes: 30,
                    xpReward: 55
                ),
                DailyExercise(
                    type: .journal,
                    title: "Veille de l'accomplissement",
                    description: "Demain, tu auras accompli 66 jours. Écris ce que tu ressens.",
                    durationMinutes: 30,
                    xpReward: 55
                )
            ],
            guidance: "Demain, tu accompliras quelque chose que peu de personnes accomplissent. Sois fier."
        ),

        DailyProgram(
            day: 66,
            title: "Accomplissement Final",
            theme: "Célébration ultime",
            timeOfDay: .any,
            exercises: [
                DailyExercise(
                    type: .breathing,
                    title: "Respiration de maîtrise (20 min)",
                    description: "Ta signature respiratoire",
                    durationMinutes: 20,
                    xpReward: 50
                ),
                DailyExercise(
                    type: .meditation,
                    title: "Méditation de gratitude ultime",
                    description: "66 jours de chemin parcouru",
                    durationMinutes: 20,
                    exerciseId: "gratitude",
                    xpReward: 50
                ),
                DailyExercise(
                    type: .journal,
                    title: "Rétrospective complète",
                    description: "J1 vs J66. Tu as parcouru quel chemin ? Qui es-tu devenu ? Comment vas-tu maintenir cette maîtrise ?",
                    durationMinutes: 30,
                    xpReward: 60
                )
            ],
            checkpoint: RoutineCheckpoint(
                day: 66,
                title: "🏆 MAÎTRE DE TON ESPRIT",
                description: "66 jours accomplis. Tu as maîtrisé ton anxiété. Tu es transformé.",
                badgeIcon: "crown.fill",
                badgeColor: "FFD700",
                bonusXP: 500
            ),
            guidance: "TU AS RÉUSSI. 66 jours. Tu n'es plus la même personne. Tu as maîtrisé ton esprit. Continue cette pratique, c'est désormais qui tu es."
        )
    ]
}
