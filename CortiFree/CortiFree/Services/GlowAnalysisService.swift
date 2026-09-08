//
//  GlowAnalysisService.swift
//  CortiFree
//
//  The service boundary keeps the UI ready for a future on-device model. The
//  current implementation is deterministic and wellness-only: it uses the
//  onboarding context and never infers a medical condition from an image.
//

import Foundation
import UIKit

protocol GlowAnalyzing {
    func analyze(image: UIImage?, context: GlowOnboardingContext) -> GlowAnalysis
}

struct LocalGlowAnalysisService: GlowAnalyzing {
    func analyze(image: UIImage?, context: GlowOnboardingContext) -> GlowAnalysis {
        let concern = context.appearanceConcern.lowercased()
        let symptoms = context.symptoms.joined(separator: " ").lowercased()
        let reasons = context.reasons.joined(separator: " ").lowercased()
        let goal = context.primaryGoal.lowercased()

        var baseline = 68
        if concern.contains("fatigue") || concern.contains("cernes") {
            baseline -= 8
        }
        if symptoms.contains("sleep") || symptoms.contains("fatigue") || reasons.contains("exhaust") {
            baseline -= 5
        }
        if goal.contains("sleep") || goal.contains("stress") {
            baseline -= 2
        }
        if image != nil {
            baseline += 2
        }

        let recovery = clamp(baseline + (goal.contains("sleep") ? 5 : 0))
        let underEye = clamp(baseline - (concern.contains("cernes") ? 8 : 0))
        let clarity = clamp(baseline + (goal.contains("energy") ? 4 : 0))
        let puffiness = clamp(baseline - (symptoms.contains("sleep") ? 4 : 0))
        let overall = clamp((recovery + underEye + clarity + puffiness) / 4)

        return GlowAnalysis(
            id: UUID(),
            createdAt: Date(),
            overallScore: overall,
            recoveryScore: recovery,
            underEyeScore: underEye,
            skinClarityScore: clarity,
            puffinessScore: puffiness,
            insights: [
                GlowInsight(
                    id: "recovery",
                    title: NSLocalizedString("glow.insight.recovery.title", comment: ""),
                    detail: NSLocalizedString("glow.insight.recovery.detail", comment: "")
                ),
                GlowInsight(
                    id: "routine",
                    title: NSLocalizedString("glow.insight.routine.title", comment: ""),
                    detail: NSLocalizedString("glow.insight.routine.detail", comment: "")
                ),
                GlowInsight(
                    id: "consistency",
                    title: NSLocalizedString("glow.insight.consistency.title", comment: ""),
                    detail: NSLocalizedString("glow.insight.consistency.detail", comment: "")
                )
            ]
        )
    }

    private func clamp(_ value: Int) -> Int {
        min(max(value, 0), 100)
    }
}
