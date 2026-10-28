//
//  FilmingOverrides.swift
//  CortiFree
//
//  Testers and TestFlight builds only (TesterAccess.canForceBPM), set in Settings → Filming:
//  predictable numbers for the UGC scripts, like the forced BPM (TesterPulseOverride).
//  - Quiz result: the stress load shown on « Your quiz result » (N/100).
//  - Plan: the plan the onboarding replay picks on « Your plan is ready ».
//  Real users never see the selectors and every value is nil for them.
//

import SwiftUI

enum FilmingOverride {
    static let quizScores = [45, 72, 85]
    /// 0 = the score from the answers. Only written from tester-gated controls.
    static let quizScoreKey = "tester.filming.quizScore"
    /// "" = the plan the answers pick.
    static let planGoalKey = "tester.filming.planGoal"

    /// The stress load to show instead of the answers' one, nil for the real one.
    static var quizScore: Int? {
        guard TesterAccess.canForceBPMNow else { return nil }
        let value = UserDefaults.standard.integer(forKey: quizScoreKey)
        return quizScores.contains(value) ? value : nil
    }

    /// The plan the onboarding replay builds, nil for the one the answers pick. Replay only: a
    /// real onboarding always follows the answers.
    static var planGoal: PlanGoal? {
        guard TesterAccess.canForceBPMNow, OnboardingReplay.isActiveNow else { return nil }
        return UserDefaults.standard.string(forKey: planGoalKey).flatMap(PlanGoal.init(rawValue:))
    }

    /// English names for the creators (the app's own names are localized).
    static func label(for goal: PlanGoal) -> String {
        switch goal {
        case .stress: return "Stress"
        case .sleep: return "Sleep"
        case .energy: return "Energy"
        case .focus: return "Focus"
        case .emotional: return "Balance"
        }
    }
}

/// « TEST · Real · 45 · 72 … » capsule row, same look as TesterBPMPicker. Scrolls when it is wider
/// than the row. Shows nothing without access.
struct FilmingOptionPicker<Value: Hashable>: View {
    @Binding var selection: Value
    let options: [(value: Value, label: String)]

    @ObservedObject private var testerAccess = TesterAccess.shared

    var body: some View {
        if testerAccess.canForceBPM {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    Text(verbatim: "TEST")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white.opacity(0.45))
                        .padding(.leading, 6)
                    ForEach(options.indices, id: \.self) { index in
                        option(options[index].value, label: options[index].label)
                    }
                }
                .padding(4)
            }
            .background(Color.white.opacity(0.06), in: Capsule())
            .clipShape(Capsule())
        }
    }

    private func option(_ value: Value, label: String) -> some View {
        Button {
            HapticManager.light()
            selection = value
        } label: {
            Text(verbatim: label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(selection == value ? .black : .white.opacity(0.7))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(selection == value ? Color.white.opacity(0.85) : Color.clear, in: Capsule())
        }
        .buttonStyle(.plain)
    }
}
