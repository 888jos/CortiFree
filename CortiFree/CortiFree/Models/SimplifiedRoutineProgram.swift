//
//  SimplifiedRoutineProgram.swift
//  CortiFree
//
//  Created by Claude on 10/11/2025.
//  Simplified 66-day routine using task IDs from JSON database
//

import Foundation
import SwiftUI

// MARK: - Simplified Daily Program

struct SimplifiedDailyProgram: Identifiable, Codable {
    let id: Int  // Day number (1-66)
    let week: Int  // Week number (1-10)
    let taskIds: [String]  // References to tasks in TASKS_DATABASE.json
    let focusArea: String  // Focus of the day
    let checkpointDay: Bool  // Is this a checkpoint day?
    let bonusXP: Int  // Bonus XP if all tasks completed

    init(id: Int, week: Int, taskIds: [String], focusArea: String, checkpointDay: Bool = false, bonusXP: Int = 0) {
        self.id = id
        self.week = week
        self.taskIds = taskIds
        self.focusArea = focusArea
        self.checkpointDay = checkpointDay
        self.bonusXP = bonusXP
    }
}

// MARK: - Simplified Routine Program

struct SimplifiedRoutineProgram {
    let days: [SimplifiedDailyProgram]

    // Get program for specific day
    func getDayProgram(_ day: Int) -> SimplifiedDailyProgram? {
        return days.first { $0.id == day }
    }

    // Get week programs
    func getWeekPrograms(_ week: Int) -> [SimplifiedDailyProgram] {
        return days.filter { $0.week == week }
    }
}

// MARK: - Weekly Objectives

enum WeeklyObjective: Int, CaseIterable {
    case week1 = 1
    case week2 = 2
    case week3 = 3
    case week4 = 4
    case week5 = 5
    case week6 = 6
    case week7 = 7
    case week8 = 8
    case week9 = 9
    case week10 = 10

    var title: String {
        switch self {
        case .week1: return "Fondations de la Respiration"
        case .week2: return "Calmer l'Anxiété"
        case .week3: return "Améliorer le Sommeil"
        case .week4: return "Gérer le Stress Quotidien"
        case .week5: return "Boost d'Énergie"
        case .week6: return "Concentration et Focus"
        case .week7: return "Auto-compassion et Émotions"
        case .week8: return "Nature et Ressourcement"
        case .week9: return "Créativité et Expression"
        case .week10: return "Intégration et Maîtrise"
        }
    }

    var description: String {
        switch self {
        case .week1: return "Apprendre les bases de la respiration consciente pour calmer le système nerveux"
        case .week2: return "Techniques pour apaiser l'anxiété et les pensées en boucle"
        case .week3: return "Créer une routine de sommeil réparateur et profond"
        case .week4: return "Outils quotidiens pour prévenir et gérer le stress"
        case .week5: return "Retrouver motivation, vitalité et énergie durable"
        case .week6: return "Développer concentration et clarté mentale"
        case .week7: return "Cultiver bienveillance envers soi et régulation émotionnelle"
        case .week8: return "Se reconnecter à la nature pour se ressourcer"
        case .week9: return "Exprimer sa créativité et cultiver le flow"
        case .week10: return "Consolider toutes les pratiques et autonomie complète"
        }
    }

    var icon: String {
        switch self {
        case .week1: return "wind"
        case .week2: return "brain.head.profile"
        case .week3: return "moon.stars.fill"
        case .week4: return "shield.fill"
        case .week5: return "bolt.fill"
        case .week6: return "target"
        case .week7: return "heart.fill"
        case .week8: return "leaf.fill"
        case .week9: return "paintbrush.fill"
        case .week10: return "star.fill"
        }
    }

    var color: Color {
        switch self {
        case .week1: return Color(hex: "3498DB")
        case .week2: return Color(hex: "9B59B6")
        case .week3: return Color(hex: "34495E")
        case .week4: return Color(hex: "E74C3C")
        case .week5: return Color(hex: "FFA500")
        case .week6: return Color(hex: "1ABC9C")
        case .week7: return Color(hex: "E91E63")
        case .week8: return Color(hex: "27AE60")
        case .week9: return Color(hex: "F39C12")
        case .week10: return Color(hex: "FFD700")
        }
    }
}

// MARK: - Routine Program Generator

class RoutineProgramGenerator {
    static let shared = RoutineProgramGenerator()

    // Generate universal 66-day program with weekly objectives
    func generateUniversalProgram() -> SimplifiedRoutineProgram {
        return generateProgram()
    }

    // MARK: - Universal Program

    private func generateProgram() -> SimplifiedRoutineProgram {
        var days: [SimplifiedDailyProgram] = []

        // Week 1: Fondations de la Respiration (Jour 1-7)
        let week1Tasks = [
            "breathing_abdominal",
            "breathing_4_7_8",
            "meditation_breath_awareness",
            "journal_gratitude"
        ]
        for day in 1...7 {
            days.append(SimplifiedDailyProgram(
                id: day,
                week: 1,
                taskIds: selectTasks(from: week1Tasks, count: 3, day: day),
                focusArea: WeeklyObjective.week1.title,
                checkpointDay: day == 7,
                bonusXP: day == 7 ? 50 : 0
            ))
        }

        // Week 2: Calmer l'Anxiété (Jour 8-14)
        let week2Tasks = [
            "breathing_4_7_8",
            "breathing_coherence",
            "meditation_grounding",
            "meditation_mindfulness",
            "journal_emotions"
        ]
        for day in 8...14 {
            days.append(SimplifiedDailyProgram(
                id: day,
                week: 2,
                taskIds: selectTasks(from: week2Tasks, count: 3, day: day),
                focusArea: WeeklyObjective.week2.title,
                checkpointDay: day == 14,
                bonusXP: day == 14 ? 75 : 0
            ))
        }

        // Week 3: Améliorer le Sommeil (Jour 15-21)
        let week3Tasks = [
            "breathing_slow_6_6",
            "meditation_body_scan_short",
            "meditation_sleep",
            "screen_before_bed",
            "screen_bedroom"
        ]
        for day in 15...21 {
            days.append(SimplifiedDailyProgram(
                id: day,
                week: 3,
                taskIds: selectTasks(from: week3Tasks, count: 4, day: day),
                focusArea: WeeklyObjective.week3.title,
                checkpointDay: day == 21,
                bonusXP: day == 21 ? 100 : 0
            ))
        }

        // Week 4: Gérer le Stress Quotidien (Jour 22-28)
        let week4Tasks = [
            "breathing_coherence",
            "breathing_box",
            "meditation_mindfulness",
            "journal_emotions",
            "journal_day_review",
            "movement_stretch_gentle"
        ]
        for day in 22...28 {
            days.append(SimplifiedDailyProgram(
                id: day,
                week: 4,
                taskIds: selectTasks(from: week4Tasks, count: 4, day: day),
                focusArea: WeeklyObjective.week4.title,
                checkpointDay: day == 28,
                bonusXP: day == 28 ? 100 : 0
            ))
        }

        // Week 5: Boost d'Énergie (Jour 29-35)
        let week5Tasks = [
            "breathing_kapalabhati",
            "breathing_bhastrika",
            "movement_walk",
            "movement_yoga_flow",
            "education_podcast",
            "nature_walk"
        ]
        for day in 29...35 {
            days.append(SimplifiedDailyProgram(
                id: day,
                week: 5,
                taskIds: selectTasks(from: week5Tasks, count: 4, day: day),
                focusArea: WeeklyObjective.week5.title,
                checkpointDay: day == 35,
                bonusXP: day == 35 ? 125 : 0
            ))
        }

        // Week 6: Concentration et Focus (Jour 36-42)
        let week6Tasks = [
            "breathing_coherence",
            "meditation_focus",
            "journal_todo",
            "education_reading",
            "screen_social_media",
            "screen_morning"
        ]
        for day in 36...42 {
            days.append(SimplifiedDailyProgram(
                id: day,
                week: 6,
                taskIds: selectTasks(from: week6Tasks, count: 5, day: day),
                focusArea: WeeklyObjective.week6.title,
                checkpointDay: day == 42,
                bonusXP: day == 42 ? 125 : 0
            ))
        }

        // Week 7: Auto-compassion et Émotions (Jour 43-49)
        let week7Tasks = [
            "meditation_self_compassion",
            "meditation_safe_place",
            "journal_emotions",
            "journal_day_review",
            "movement_stretch_full",
            "creativity_draw"
        ]
        for day in 43...49 {
            days.append(SimplifiedDailyProgram(
                id: day,
                week: 7,
                taskIds: selectTasks(from: week7Tasks, count: 5, day: day),
                focusArea: WeeklyObjective.week7.title,
                checkpointDay: day == 49,
                bonusXP: day == 49 ? 150 : 0
            ))
        }

        // Week 8: Nature et Ressourcement (Jour 50-56)
        let week8Tasks = [
            "nature_walk",
            "nature_sit",
            "nature_exercise",
            "nature_breathing",
            "nature_gardening",
            "movement_walk"
        ]
        for day in 50...56 {
            days.append(SimplifiedDailyProgram(
                id: day,
                week: 8,
                taskIds: selectTasks(from: week8Tasks, count: 5, day: day),
                focusArea: WeeklyObjective.week8.title,
                checkpointDay: day == 56,
                bonusXP: day == 56 ? 150 : 0
            ))
        }

        // Week 9: Créativité et Expression (Jour 57-63)
        let week9Tasks = [
            "creativity_draw",
            "creativity_write",
            "creativity_music_listen",
            "creativity_cooking",
            "creativity_photography",
            "journal_free"
        ]
        for day in 57...63 {
            days.append(SimplifiedDailyProgram(
                id: day,
                week: 9,
                taskIds: selectTasks(from: week9Tasks, count: 5, day: day),
                focusArea: WeeklyObjective.week9.title,
                checkpointDay: day == 63,
                bonusXP: day == 63 ? 175 : 0
            ))
        }

        // Week 10: Intégration et Maîtrise (Jour 64-66)
        let week10Tasks = [
            "breathing_coherence",
            "meditation_mindfulness",
            "meditation_self_compassion",
            "journal_day_review",
            "movement_yoga_flow",
            "nature_walk",
            "creativity_music_listen",
            "screen_before_bed"
        ]
        for day in 64...66 {
            days.append(SimplifiedDailyProgram(
                id: day,
                week: 10,
                taskIds: selectTasks(from: week10Tasks, count: 6, day: day),
                focusArea: WeeklyObjective.week10.title,
                checkpointDay: day == 66,
                bonusXP: day == 66 ? 200 : 0
            ))
        }

        return SimplifiedRoutineProgram(days: days)
    }

    // MARK: - Helper: Select Tasks

    private func selectTasks(from pool: [String], count: Int, day: Int) -> [String] {
        // Use day number as seed for deterministic but varied selection
        var selected: [String] = []
        let available = pool

        // Rotate through tasks based on day
        let startIndex = (day - 1) % pool.count

        for i in 0..<min(count, pool.count) {
            let index = (startIndex + i) % available.count
            selected.append(available[index])
        }

        return Array(selected.prefix(count))
    }
}
