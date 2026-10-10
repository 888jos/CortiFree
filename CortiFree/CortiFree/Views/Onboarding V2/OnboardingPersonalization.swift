//
//  OnboardingPersonalization.swift
//  CortiFree
//
//  What the user lived during the onboarding, reused on the screens that follow it:
//  the heart-rate drop of the first breathing exercise, the first name and the plan
//  (also sent to Superwall so the paywall template can show them), and real App Store reviews.
//

import SwiftUI
import SuperwallKit

// MARK: - Breathing pulse result

/// Heart rate before / after the onboarding breathing, kept only when it clearly slowed down
/// (same rule as the "Ton cœur a ralenti" result screen).
enum OnboardingPulseResult {
    private static let beforeKey = "onboarding_pulse_recap_before"
    private static let afterKey = "onboarding_pulse_recap_after"

    static func save(before: Int, after: Int) {
        UserDefaults.standard.set(before, forKey: beforeKey)
        UserDefaults.standard.set(after, forKey: afterKey)
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: beforeKey)
        UserDefaults.standard.removeObject(forKey: afterKey)
    }

    /// (before, after, drop) when the breathing slowed the heart down.
    static var current: (before: Int, after: Int, drop: Int)? {
        let defaults = UserDefaults.standard
        guard let before = defaults.object(forKey: beforeKey) as? Int,
              let after = defaults.object(forKey: afterKey) as? Int,
              before > after else { return nil }
        return (before, after, before - after)
    }
}

/// "−9 BPM" capsule followed by a sentence, shown on the quiz result, the plan and the pre-paywall.
struct OnboardingPulseRecap: View {
    let text: String
    let drop: Int
    var accent: Color = Color(hex: "6FE3B4")

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Text(verbatim: "−\(drop) BPM")
                .font(.poppinsSemiBold(14))
                .foregroundStyle(Color(hex: "071B22"))
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(accent, in: Capsule())
                .fixedSize()
            Text(text)
                .font(.poppinsMedium(14))
                .foregroundStyle(.white.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .glassCard(cornerRadius: 18)
    }
}

// MARK: - First name & plan

@MainActor
enum OnboardingPersonalization {
    /// First name typed in the onboarding, else the account's first name. Empty when unknown.
    static var firstName: String {
        if let typed = UserPersistence.userFirstName?.trimmingCharacters(in: .whitespacesAndNewlines), !typed.isEmpty {
            return typed
        }
        if let displayName = Auth.auth().currentUser?.displayName?.trimmingCharacters(in: .whitespacesAndNewlines),
           let first = displayName.components(separatedBy: " ").first, !first.isEmpty {
            return first
        }
        return ""
    }

    /// Lets the Superwall paywall template show {{ user.firstName }}, {{ user.planName }}
    /// and {{ user.pulseDrop }} (empty / absent when unknown).
    static func sendToSuperwall(plan: PersonalPlan?) {
        var attributes: [String: Any?] = [
            "firstName": firstName.isEmpty ? nil : firstName,
            "planName": plan?.localizedTitle,
            "planGoal": plan?.goal.rawValue,
            "pulseBefore": nil,
            "pulseAfter": nil,
            "pulseDrop": nil
        ]
        if let pulse = OnboardingPulseResult.current {
            attributes["pulseBefore"] = pulse.before
            attributes["pulseAfter"] = pulse.after
            attributes["pulseDrop"] = pulse.drop
        }
        Superwall.shared.setUserAttributes(attributes)
    }
}

// MARK: - App Store reviews

/// Real App Store reviews (France storefront, checked on 2026-10-10: 4.9/5, 9 ratings).
/// Translated in the other languages, with a note saying so. Update the texts and the
/// rating together when new reviews come in.
struct OnboardingAppStoreReviews: View {
    private struct Review: Identifiable {
        let id: Int
        let author: String
        var titleKey: String { "paywall_custom.reviews.r\(id)_title" }
        var textKey: String { "paywall_custom.reviews.r\(id)_text" }
    }

    private let reviews = [Review(id: 1, author: "Nb_manivelle"), Review(id: 2, author: "Bertouilleee")]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("paywall_custom.reviews.title".localized)
                .font(.faroBold(22))
                .foregroundColor(.white)
                .padding(.horizontal, 4)

            HStack(spacing: 8) {
                stars(size: 15)
                Text("paywall_custom.reviews.rating".localized)
                    .font(.poppinsSemiBold(14))
                    .foregroundColor(.white.opacity(0.85))
            }
            .padding(.horizontal, 4)

            ForEach(reviews) { review in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        stars(size: 11)
                        Spacer()
                        Text(verbatim: review.author)
                            .font(.poppinsRegular(12))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    Text(review.titleKey.localized)
                        .font(.poppinsSemiBold(15))
                        .foregroundColor(.white)
                    Text(review.textKey.localized)
                        .font(.poppinsRegular(14))
                        .foregroundColor(.white.opacity(0.75))
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.05)))
            }

            let note = "paywall_custom.reviews.translated".localized
            if !note.isEmpty {
                Text(note)
                    .font(.poppinsRegular(11))
                    .foregroundColor(.white.opacity(0.4))
                    .padding(.horizontal, 4)
            }
        }
    }

    private func stars(size: CGFloat) -> some View {
        HStack(spacing: 2) {
            ForEach(0..<5, id: \.self) { _ in
                Image(systemName: "star.fill")
                    .font(.system(size: size))
                    .foregroundColor(Color(hex: "FFC94D"))
            }
        }
        .accessibilityHidden(true)
    }
}
