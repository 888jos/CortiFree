//
//  OnboardingAudience.swift
//  CortiFree
//
//  Who is doing the onboarding (ideal customer profile), from the profile quiz: age range,
//  daily life (works with kids / works / student / retired / other) and gender. Every
//  « show this to this kind of person » rule of the onboarding lives here, so screens ask
//  `OnboardingAudience` instead of testing ages themselves.
//
//  Wording variants: a screen asks `text("onboarding_v2.habits.q1")`, which returns
//  « onboarding_v2.habits.q1.parent » for a parent when that key exists in the current
//  language, the usual text otherwise (no gap when a variant isn't translated).
//
//  Half of new users get the variants (`isPersonalized`), the other half the usual
//  onboarding, so Amplitude can compare trials and purchases. Hiding the « my AI answers »
//  choice for 55+ applies to everyone (Jos, 08/11/2026).
//

import Foundation
import SuperwallKit

/// Daily life answered in the profile quiz.
enum OnboardingLifeStage: String, CaseIterable {
    case parent      // works and has kids
    case worker      // works, no kids at home
    case student
    case retired
    case other

    var titleKey: String { "onboarding_v2.overall.life_\(rawValue)" }
}

/// The ICP the onboarding speaks to.
enum OnboardingSegment: String {
    case youngAdult = "young_adult"
    case parent
    case worker
    case senior
    case general

    /// Suffix of the wording variants (« onboarding_v2.habits.q1.parent »).
    var variantSuffix: String? { self == .general ? nil : rawValue }
}

enum OnboardingAudience {
    private static let lifeKey = "onboarding_life_stage"
    private static let ageKey = "onboarding_age_code"
    private static let variantKey = "onboarding_personalized_variant"

    // MARK: Answers

    static var ageCode: String? { UserDefaults.standard.string(forKey: ageKey) }

    static var lifeStage: OnboardingLifeStage? {
        UserDefaults.standard.string(forKey: lifeKey).flatMap(OnboardingLifeStage.init(rawValue:))
    }

    /// Saved as soon as the profile quiz is answered (and on a draft restore).
    static func save(ageCode: String?, lifeCode: String?) {
        let defaults = UserDefaults.standard
        if let ageCode { defaults.set(ageCode, forKey: ageKey) } else { defaults.removeObject(forKey: ageKey) }
        if let lifeCode { defaults.set(lifeCode, forKey: lifeKey) } else { defaults.removeObject(forKey: lifeKey) }
    }

    // MARK: Segment

    /// Retired or 55+ first, then parents, then the young (under 25 or students), then workers.
    static func segment(ageCode: String?, life: OnboardingLifeStage?) -> OnboardingSegment {
        if ageCode == "55_plus" || life == .retired { return .senior }
        if life == .parent { return .parent }
        if ageCode == "under_18" || ageCode == "18_24" || life == .student { return .youngAdult }
        if life == .worker { return .worker }
        return .general
    }

    static var segment: OnboardingSegment { segment(ageCode: ageCode, life: lifeStage) }

    // MARK: Rules

    /// « My AI answers for me » before the habit questions: not shown to 55+.
    static var showsAIQuizChoice: Bool { ageCode != "55_plus" }

    /// 50/50 test of the personalized wording, drawn once per install.
    static var isPersonalized: Bool {
        let defaults = UserDefaults.standard
        if defaults.object(forKey: variantKey) == nil {
            defaults.set(Bool.random(), forKey: variantKey)
        }
        return defaults.bool(forKey: variantKey)
    }

    /// The segment's wording when it exists and the user is in the personalized half,
    /// the usual text otherwise.
    static func text(_ key: String) -> String {
        if isPersonalized, let suffix = segment.variantSuffix {
            let variantKey = "\(key).\(suffix)"
            let variant = variantKey.localized
            if variant != variantKey, !variant.isEmpty { return variant }
        }
        return key.localized
    }

    /// An optional sentence for the segment (« "" » when there is none or the user is in the
    /// usual half).
    static func optionalText(_ key: String) -> String {
        guard isPersonalized, let suffix = segment.variantSuffix else { return "" }
        let variantKey = "\(key).\(suffix)"
        let value = variantKey.localized
        return value == variantKey ? "" : value
    }

    // MARK: Analytics & paywall

    /// Amplitude user properties and Superwall attributes, so dashboards and paywall
    /// audiences can split by ICP.
    @MainActor
    static func publish() {
        let properties: [String: Any] = [
            "icp_life": lifeStage?.rawValue ?? "unknown",
            "icp_segment": segment.rawValue,
            "onboarding_personalized": isPersonalized
        ]
        AmplitudeManager.shared.setUserProperties(properties)
        Superwall.shared.setUserAttributes([
            "lifeStage": lifeStage?.rawValue,
            "segment": segment.rawValue,
            "ageCode": ageCode,
            "onboardingPersonalized": isPersonalized
        ])
    }
}
