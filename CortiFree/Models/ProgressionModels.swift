//
//  ProgressionModels.swift
//  CortiFree
//
//  Système de progression et XP
//

import SwiftUI

// MARK: - Level Model
struct Level: Identifiable, Equatable {
    let id: Int
    let name: String
    let description: String
    let requiredXP: Int

    static let allLevels: [Level] = [
        Level(id: 1, name: "Stress initial", description: "Tu débutes ton chemin vers l'apaisement.", requiredXP: 0),
        Level(id: 2, name: "Éveil du calme", description: "Tu découvres tes premiers réflexes anti-stress.", requiredXP: 150),
        Level(id: 3, name: "Respiration consciente", description: "Tu apprends à réguler ton souffle.", requiredXP: 400),
        Level(id: 4, name: "Premier ancrage", description: "Tu commences à ressentir de la stabilité intérieure.", requiredXP: 700),
        Level(id: 5, name: "Sérénité active", description: "Tu gères mieux ton stress quotidien.", requiredXP: 1100),
        Level(id: 6, name: "Sommeil retrouvé", description: "Tes nuits deviennent plus réparatrices.", requiredXP: 1600),
        Level(id: 7, name: "Concentration fluide", description: "Ton esprit se clarifie.", requiredXP: 2200),
        Level(id: 8, name: "Corps détendu", description: "Tes tensions physiques diminuent.", requiredXP: 3000),
        Level(id: 9, name: "Stabilité émotionnelle", description: "Tu réagis avec plus de calme.", requiredXP: 4000),
        Level(id: 10, name: "Harmonie intérieure", description: "Tes journées s'équilibrent naturellement.", requiredXP: 5200),
        Level(id: 11, name: "Maîtrise du rythme", description: "Tu adaptes ton énergie au bon moment.", requiredXP: 6800),
        Level(id: 12, name: "Sérénité durable", description: "Le calme devient ton état par défaut.", requiredXP: 8600),
        Level(id: 13, name: "Ancrage profond", description: "Tu restes serein face aux imprévus.", requiredXP: 10800),
        Level(id: 14, name: "Présence maîtrisée", description: "Tes pensées se stabilisent.", requiredXP: 13200),
        Level(id: 15, name: "Calme réflexe", description: "Tes réactions sont douces et mesurées.", requiredXP: 16000),
        Level(id: 16, name: "Esprit clair", description: "Tu anticipes sans anxiété.", requiredXP: 19200),
        Level(id: 17, name: "Équilibre stable", description: "Ton humeur devient régulière.", requiredXP: 22800),
        Level(id: 18, name: "Paix active", description: "Tu restes calme même sous pression.", requiredXP: 26800),
        Level(id: 19, name: "Sérénité profonde", description: "Tu incarnes ton équilibre.", requiredXP: 31200),
        Level(id: 20, name: "Harmonie complète", description: "Ton corps et ton esprit fonctionnent en paix.", requiredXP: 36000)
    ]

    static func level(for xp: Int) -> Level {
        let unlocked = allLevels.filter { xp >= $0.requiredXP }
        return unlocked.last ?? allLevels[0]
    }

    static func nextLevel(for currentLevel: Level) -> Level? {
        guard let currentIndex = allLevels.firstIndex(of: currentLevel),
              currentIndex < allLevels.count - 1 else {
            return nil
        }
        return allLevels[currentIndex + 1]
    }

    static func progressToNextLevel(currentXP: Int, currentLevel: Level) -> (current: Int, required: Int, percentage: Double) {
        guard let nextLevel = nextLevel(for: currentLevel) else {
            return (0, 0, 1.0) // Max level reached
        }

        let xpInCurrentLevel = currentXP - currentLevel.requiredXP
        let xpNeededForNextLevel = nextLevel.requiredXP - currentLevel.requiredXP
        let percentage = Double(xpInCurrentLevel) / Double(xpNeededForNextLevel)

        return (xpInCurrentLevel, xpNeededForNextLevel, percentage)
    }
}

// MARK: - XP Actions
enum XPAction: String, CaseIterable {
    case breathingComplete = "Respiration guidée complète"
    case meditationComplete = "Méditation terminée"
    case dailyMissionComplete = "Mission journalière validée"
    case sosUsed = "Bouton SOS utilisé"
    case streak3Days = "3 jours consécutifs"
    case streak7Days = "7 jours consécutifs"
    case weeklyReport = "Rapport de progrès envoyé"
    case weeklyGoalReached = "Objectif hebdo atteint"

    var xpValue: Int {
        switch self {
        case .breathingComplete: return 10
        case .meditationComplete: return 15
        case .dailyMissionComplete: return 20
        case .sosUsed: return 5
        case .streak3Days: return 25
        case .streak7Days: return 50
        case .weeklyReport: return 10
        case .weeklyGoalReached: return 75
        }
    }

    var iconName: String {
        switch self {
        case .breathingComplete: return "wind"
        case .meditationComplete: return "figure.mind.and.body"
        case .dailyMissionComplete: return "checkmark.circle.fill"
        case .sosUsed: return "cross.circle.fill"
        case .streak3Days, .streak7Days: return "flame.fill"
        case .weeklyReport: return "chart.bar.fill"
        case .weeklyGoalReached: return "trophy.fill"
        }
    }
}
