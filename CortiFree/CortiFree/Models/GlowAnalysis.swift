//
//  GlowAnalysis.swift
//  CortiFree
//
//  Local wellness snapshot used by the Glow Scan onboarding experience.
//

import Foundation

struct GlowInsight: Codable, Equatable, Identifiable {
    let id: String
    let title: String
    let detail: String
}

struct GlowAnalysis: Codable, Equatable, Identifiable {
    let id: UUID
    let createdAt: Date
    let overallScore: Int
    let recoveryScore: Int
    let underEyeScore: Int
    let skinClarityScore: Int
    let puffinessScore: Int
    let insights: [GlowInsight]

    var scoreBucket: String {
        switch overallScore {
        case 80...: return "high"
        case 60..<80: return "mid"
        default: return "starting"
        }
    }
}

struct GlowOnboardingContext {
    let primaryGoal: String
    let appearanceConcern: String
    let symptoms: [String]
    let reasons: [String]
    let domainScore: Int?

    static let empty = GlowOnboardingContext(
        primaryGoal: "balance",
        appearanceConcern: "",
        symptoms: [],
        reasons: [],
        domainScore: nil
    )

    init(
        primaryGoal: String,
        appearanceConcern: String,
        symptoms: [String],
        reasons: [String],
        domainScore: Int? = nil
    ) {
        self.primaryGoal = primaryGoal
        self.appearanceConcern = appearanceConcern
        self.symptoms = symptoms
        self.reasons = reasons
        self.domainScore = domainScore
    }
}
