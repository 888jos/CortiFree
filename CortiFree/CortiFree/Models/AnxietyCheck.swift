//
//  AnxietyCheck.swift
//  CortiFree
//
//  GAD-7 anxiety questionnaire results (Spitzer et al., 2006), imported from Apple Health.
//  7 answers about the last 2 weeks, each 0–3; total 0–21. A screening tool, never a diagnosis.
//

import Foundation

/// Standard GAD-7 bands: 0–4 minimal, 5–9 mild, 10–14 moderate, 15–21 severe.
enum AnxietySeverity: String, Codable, CaseIterable, Comparable {
    case minimal, mild, moderate, severe

    init(score: Int) {
        switch score {
        case ..<5: self = .minimal
        case 5..<10: self = .mild
        case 10..<15: self = .moderate
        default: self = .severe
        }
    }

    static func < (lhs: AnxietySeverity, rhs: AnxietySeverity) -> Bool {
        allCases.firstIndex(of: lhs)! < allCases.firstIndex(of: rhs)!
    }
}

struct AnxietyCheckResult: Codable, Equatable, Identifiable {
    enum Source: String, Codable {
        /// Taken in CortiFree.
        case app
        /// Imported from Apple Health (Health app or another app).
        case health
    }

    var id: Date { date }
    let date: Date
    let answers: [Int]
    let source: Source

    var score: Int { answers.reduce(0, +) }
    var severity: AnxietySeverity { AnxietySeverity(score: score) }
}
