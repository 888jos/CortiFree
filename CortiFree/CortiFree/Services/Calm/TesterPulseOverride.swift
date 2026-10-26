//
//  TesterPulseOverride.swift
//  CortiFree
//
//  Testers and TestFlight builds only (TesterAccess.canForceBPM): « forced BPM » for the pulse checks,
//  so creators filming a demo get a predictable result. The measure keeps its normal screens,
//  ring and duration; only the number is replaced (preset ± 5, live readout ± 3 around it).
//  Real users never see the selector and `preset` is always nil for them.
//

import SwiftUI

enum TesterPulseOverride {
    static let presets = [112, 78, 60]
    /// 0 = real measure. Only written from tester-gated controls.
    static let storageKey = "tester.pulse.forcedBPM"

    /// The chosen preset, nil for a real measure (always nil without access, so App Store builds).
    /// Kept in video mode: creators pick it in Settings → Filming, then film without any debug tool.
    static var preset: Int? {
        guard TesterAccess.canForceBPMNow else { return nil }
        let value = UserDefaults.standard.integer(forKey: storageKey)
        return presets.contains(value) ? value : nil
    }

    /// Final number of a forced measure.
    static func finalBPM(around preset: Int) -> Int {
        preset + Int.random(in: -5...5)
    }

    /// Live readout while a forced measure runs: hovers around the final number.
    static func liveBPM(around target: Int) -> Int {
        target + Int.random(in: -3...3)
    }
}

/// « Real · ≈112 · ≈78 · ≈60 » row, in English for the creators. Shows nothing without access.
struct TesterBPMPicker: View {
    @ObservedObject private var testerAccess = TesterAccess.shared
    @AppStorage(TesterPulseOverride.storageKey) private var forced = 0

    var body: some View {
        if testerAccess.canForceBPM {
            HStack(spacing: 6) {
                Text(verbatim: "TEST")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white.opacity(0.45))
                option(0, label: "Real")
                ForEach(TesterPulseOverride.presets, id: \.self) { preset in
                    option(preset, label: "≈\(preset)")
                }
            }
            .padding(4)
            .background(Color.white.opacity(0.06), in: Capsule())
        }
    }

    private func option(_ value: Int, label: String) -> some View {
        Button {
            HapticManager.light()
            forced = value
        } label: {
            Text(verbatim: label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(forced == value ? .black : .white.opacity(0.7))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(forced == value ? Color.white.opacity(0.85) : Color.clear, in: Capsule())
        }
        .buttonStyle(.plain)
    }
}
