//
//  AnxietyCheck.swift
//  CortiFree
//
//  GAD-7 anxiety questionnaire (Spitzer et al., 2006 — free to use). 7 questions about
//  the last 2 weeks, each answered 0–3; total 0–21. A screening tool, never a diagnosis.
//

import Foundation

enum AnxietyCheck {
    static let questionCount = 7
    /// Answer values 0...3 ("not at all" → "nearly every day").
    static let answerRange = 0...3

    static func questionKey(_ index: Int) -> String { "anxiety_check.q\(index + 1)" }
    static func answerKey(_ value: Int) -> String { "anxiety_check.answer.\(value)" }
}

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

    var localizedName: String { "anxiety_check.severity.\(rawValue)".localized }
    var localizedDescription: String { "anxiety_check.severity.\(rawValue).description".localized }

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
