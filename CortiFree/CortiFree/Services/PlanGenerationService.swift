//
//  PlanGenerationService.swift
//  CortiFree
//
//  Entry point kept for compatibility. The legacy 10-week "anti-regression" targets
//  (never wired to the UI) were replaced by the personalized 28-day plan:
//  - generation: Services/Plan/PersonalPlanGenerator.swift
//  - storage / Firestore (users/{uid}/personalized_plan/current): Services/Plan/PersonalPlanStore.swift
//

import Foundation

@MainActor
final class PlanGenerationService {
    static let shared = PlanGenerationService()

    private init() {}

    /// Generates and stores the personalized plan from the onboarding answers.
    @discardableResult
    func generatePersonalizedPlan(quizResult: HabitsQuizResult, overallData: OverallQuizData?, symptoms: Set<String>) -> PersonalPlan? {
        let profile = PlanProfile(
            reasonCodes: overallData?.reasonCodes ?? [],
            durationCode: overallData?.durationCode,
            ageCode: overallData?.ageCode,
            genderCode: overallData?.genderCode,
            quizAnswers: quizResult.answers,
            symptomIDs: PlanLocalizationLookup.symptomIDs(from: symptoms),
            source: "onboarding"
        )
        PersonalPlanStore.shared.createPlanFromOnboarding(profile)
        return PersonalPlanStore.shared.plan
    }
}
