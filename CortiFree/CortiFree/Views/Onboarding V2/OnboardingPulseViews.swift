//
//  OnboardingPulseViews.swift
//  CortiFree
//
//  Onboarding breathing exercise, measured: heart rate with the flash before, the breathing,
//  heart rate again, then the comparison (confetti when the heart slowed down). Camera
//  readings can be wrong (finger moving, pressing too hard), so doubtful numbers are flagged
//  and can be measured again instead of being shown as facts.
//

import SwiftUI

/// Can a reading taken at rest be trusted?
enum PulsePlausibility {
    static let restingRange = 45...115
    /// Beyond this, a change in one minute of breathing is a measuring error, not the heart.
    static let maxCredibleChange = 25

    enum Doubt { case tooHigh, tooLow, unstable }

    static func doubt(for reading: PulseCameraMeter.Reading) -> Doubt? {
        if reading.bpm > restingRange.upperBound { return .tooHigh }
        if reading.bpm < restingRange.lowerBound { return .tooLow }
        return reading.reliable ? nil : .unstable
    }
}

// MARK: - Measure

struct OnboardingPulseMeasureView: View {
    @ObservedObject var meter: PulseCameraMeter
    /// Second measure, right after the breathing: no instructions screen.
    let isAfter: Bool
    /// nil when the user skipped the measure.
    let onFinish: (PulseCameraMeter.Reading?) -> Void
    var onBack: (() -> Void)?
    /// When set, an implausible reading never shows the "measure again" screen: the flow
    /// simply carries on without a number (the onboarding must never feel like an error).
    var onUnclear: (() -> Void)?
    #if targetEnvironment(simulator)
    var simulatedBPM: Double = 84
    #endif

    private enum Phase: Equatable {
        case instructions
        case measuring
        case doubtful(PulseCameraMeter.Reading)
        case result(PulseCameraMeter.Reading)
    }

    @State private var phase: Phase = .instructions
    @State private var hasStarted = false

    var body: some View {
        VStack(spacing: 0) {
            header
            Spacer(minLength: 0)
            Group {
                switch phase {
                case .instructions: instructions
                case .measuring:
                    PulseMeasuringView(
                        meter: meter,
                        title: (isAfter ? "onboarding_v2.pulse.measure_after" : "onboarding_v2.pulse.measure_before").localized
                    )
                case .doubtful(let reading): doubtful(reading)
                case .result(let reading): result(reading)
                }
            }
            .transition(.opacity)
            Spacer(minLength: 0)
            bottomBar
                .padding(.horizontal, 24)
                .padding(.bottom, 34)
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.88), value: phase)
        .onAppear {
            guard !hasStarted else { return }
            hasStarted = true
            if isAfter { measure() }
        }
        .onChange(of: meter.state) { _, state in
            if phase == .measuring, case .failed = state, let onUnclear {
                AnalyticsManager.shared.track(event: "onboarding_pulse_unclear", properties: ["has_reading": false, "after": isAfter])
                onUnclear()
                return
            }
            guard phase == .measuring, case .done = state, let reading = meter.lastReading else { return }
            if PulsePlausibility.doubt(for: reading) != nil, let onUnclear {
                AnalyticsManager.shared.track(event: "onboarding_pulse_unclear", properties: ["has_reading": true, "after": isAfter])
                onUnclear()
            } else if PulsePlausibility.doubt(for: reading) != nil {
                HapticManager.warning()
                phase = .doubtful(reading)
            } else if isAfter {
                onFinish(reading)
            } else {
                phase = .result(reading)
            }
        }
        .onDisappear { meter.stop() }
    }

    private func measure() {
        #if targetEnvironment(simulator)
        meter.simulatedBPM = simulatedBPM
        #endif
        phase = .measuring
        meter.start()
    }

    private func skip() {
        HapticManager.light()
        meter.stop()
        onFinish(nil)
    }

    // MARK: Bars

    private var header: some View {
        HStack {
            if let onBack, !isAfter {
                Button {
                    HapticManager.light()
                    meter.stop()
                    onBack()
                } label: {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 21, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("common.back".localized)
            }
            Spacer()
            Button("onboarding_v2.skip".localized, action: skip)
                .font(.poppinsMedium(14))
                .foregroundStyle(.white.opacity(0.72))
                .buttonStyle(.plain)
        }
        .padding(.horizontal, 18)
        .padding(.top, 14)
        .frame(height: 58)
    }

    @ViewBuilder
    private var bottomBar: some View {
        switch phase {
        case .instructions:
            primaryButton("onboarding_v2.pulse.cta_measure".localized, action: measure)
        case .doubtful(let reading):
            VStack(spacing: 12) {
                primaryButton("onboarding_v2.pulse.remeasure".localized, action: measure)
                Button("onboarding_v2.pulse.keep".localized) {
                    HapticManager.light()
                    AnalyticsManager.shared.track(event: "onboarding_pulse_doubt_kept", properties: ["after": isAfter])
                    if isAfter { onFinish(reading) } else { phase = .result(reading) }
                }
                .font(.poppinsMedium(14))
                .foregroundStyle(.white.opacity(0.62))
                .buttonStyle(.plain)
            }
        case .result(let reading):
            primaryButton("onboarding_v2.pulse.cta_breathe".localized) { onFinish(reading) }
        case .measuring:
            Color.clear.frame(height: 56)
        }
    }

    private func primaryButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button {
            HapticManager.light()
            action()
        } label: {
            Text(title)
                .font(.poppinsSemiBold(17))
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .contentShape(Capsule())
        }
        .buttonStyle(.glassPrimary)
    }

    // MARK: Content

    private var instructions: some View {
        VStack(spacing: 16) {
            Image("pulse_camera_instruction")
                .resizable()
                .scaledToFit()
                .frame(width: 180, height: 190)
                .accessibilityHidden(true)
            Text("onboarding_v2.pulse.title".localized)
                .font(.faroBold(29))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .balancedLines()
            Text("onboarding_v2.pulse.subtitle".localized)
                .font(.poppinsRegular(16))
                .foregroundStyle(.white.opacity(0.72))
                .multilineTextAlignment(.center)
                .balancedLines()
            VStack(alignment: .leading, spacing: 12) {
                step("camera.fill", "onboarding_v2.pulse.step_finger")
                step("hand.point.up.left.fill", "onboarding_v2.pulse.step_pressure")
                step("timer", "onboarding_v2.pulse.step_still")
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassCard(cornerRadius: 20)
            Text("onboarding_v2.pulse.flash_note".localized)
                .font(.poppinsRegular(12))
                .foregroundStyle(.white.opacity(0.5))
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 24)
    }

    private func step(_ icon: String, _ key: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AudioPalette.accent)
                .frame(width: 22)
            Text(key.localized)
                .font(.poppinsRegular(14))
                .foregroundStyle(.white.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func doubtful(_ reading: PulseCameraMeter.Reading) -> some View {
        let key: String
        switch PulsePlausibility.doubt(for: reading) {
        case .tooHigh: key = "onboarding_v2.pulse.doubt_high"
        case .tooLow: key = "onboarding_v2.pulse.doubt_low"
        default: key = "onboarding_v2.pulse.doubt_unstable"
        }
        return VStack(spacing: 14) {
            Image(systemName: "questionmark.circle.fill")
                .font(.system(size: 46, weight: .semibold))
                .foregroundStyle(Color(hex: "FFB86B"))
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(verbatim: "\(reading.bpm)")
                    .font(.faroBold(56))
                    .foregroundStyle(.white.opacity(0.55))
                    .strikethrough(true, color: .white.opacity(0.4))
                Text(verbatim: "BPM")
                    .font(.poppinsSemiBold(14))
                    .foregroundStyle(.white.opacity(0.5))
            }
            Text("onboarding_v2.pulse.doubt_title".localized)
                .font(.faroBold(26))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
            Text(String(format: key.localized, reading.bpm))
                .font(.poppinsRegular(15))
                .foregroundStyle(.white.opacity(0.75))
                .multilineTextAlignment(.center)
                .balancedLines()
            Text("onboarding_v2.pulse.doubt_tip".localized)
                .font(.poppinsMedium(13))
                .foregroundStyle(.white.opacity(0.85))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .glassCard(cornerRadius: 16)
        }
        .padding(.horizontal, 28)
    }

    private func result(_ reading: PulseCameraMeter.Reading) -> some View {
        VStack(spacing: 14) {
            Text("onboarding_v2.pulse.before_label".localized.uppercased())
                .font(.poppinsSemiBold(12))
                .tracking(1)
                .foregroundStyle(AudioPalette.accent)
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(verbatim: "\(reading.bpm)")
                    .font(.faroBold(72))
                    .foregroundStyle(.white)
                Text(verbatim: "BPM")
                    .font(.poppinsSemiBold(16))
                    .foregroundStyle(.white.opacity(0.6))
            }
            Text("onboarding_v2.pulse.before_next".localized)
                .font(.poppinsRegular(16))
                .foregroundStyle(.white.opacity(0.75))
                .multilineTextAlignment(.center)
                .balancedLines()
        }
        .padding(.horizontal, 28)
    }
}

// MARK: - Comparison

struct OnboardingPulseComparisonView: View {
    /// nil when that measure was not clear enough: the screen then celebrates the breathing
    /// without showing heart-rate numbers.
    let before: PulseCameraMeter.Reading?
    let after: PulseCameraMeter.Reading?
    let onRemeasure: () -> Void
    let onContinue: () -> Void

    @State private var showConfetti = false

    private enum Outcome { case calmer, steady, faster, breathed }

    private var delta: Int { (before?.bpm ?? 0) - (after?.bpm ?? 0) }

    private var outcome: Outcome {
        guard let before, let after else { return .breathed }
        if PulsePlausibility.doubt(for: before) != nil || PulsePlausibility.doubt(for: after) != nil
            || abs(delta) > PulsePlausibility.maxCredibleChange { return .breathed }
        if delta >= 3 { return .calmer }
        if delta <= -3 { return .faster }
        return .steady
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            VStack(spacing: 20) {
                if outcome != .breathed, let before, let after {
                    HStack(alignment: .bottom, spacing: 18) {
                        column("onboarding_v2.pulse.before".localized, before.bpm, emphasised: false)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(AudioPalette.accent)
                            .padding(.bottom, 26)
                        column("onboarding_v2.pulse.after".localized, after.bpm, emphasised: true)
                    }
                } else {
                    Image(systemName: "wind")
                        .font(.system(size: 52, weight: .semibold))
                        .foregroundStyle(AudioPalette.accent)
                        .frame(width: 112, height: 112)
                        .background(Circle().fill(Color.white.opacity(0.08)))
                }
                if outcome == .calmer {
                    Text(String(format: "onboarding_v2.pulse.calmer_badge".localized, delta))
                        .font(.poppinsSemiBold(15))
                        .foregroundStyle(Color(hex: "071B22"))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color(hex: "6FE3B4"), in: Capsule())
                }
                Text(title)
                    .font(.faroBold(28))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .balancedLines()
                Text(message)
                    .font(.poppinsRegular(15))
                    .foregroundStyle(.white.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .balancedLines()
                if outcome != .breathed {
                    Text("calm.pulse.disclaimer".localized)
                        .font(.poppinsRegular(11))
                        .foregroundStyle(.white.opacity(0.45))
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 28)
            Spacer(minLength: 0)
            VStack(spacing: 12) {
                Button {
                    HapticManager.light()
                    onContinue()
                } label: {
                    Text("onboarding_v2.breath_demo.continue".localized)
                        .font(.poppinsSemiBold(17))
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .contentShape(Capsule())
                }
                .buttonStyle(.glassPrimary)
                if outcome == .faster {
                    Button("onboarding_v2.pulse.remeasure".localized) {
                        HapticManager.light()
                        onRemeasure()
                    }
                    .font(.poppinsMedium(14))
                    .foregroundStyle(.white.opacity(0.62))
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 34)
        }
        // The first exercise is always celebrated, whatever the measure said.
        .overlay {
            if showConfetti { FullScreenConfetti() }
        }
        .onAppear {
            AnalyticsManager.shared.track(event: "onboarding_pulse_compared", properties: [
                "before": before?.bpm ?? -1, "after": after?.bpm ?? -1, "outcome": "\(outcome)",
                "reliable": (before?.reliable ?? false) && (after?.reliable ?? false)
            ])
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                showConfetti = true
                HapticManager.success()
            }
        }
    }

    private var title: String {
        switch outcome {
        case .calmer: return "onboarding_v2.pulse.calmer_title".localized
        case .steady: return "onboarding_v2.pulse.steady_title".localized
        case .faster: return "onboarding_v2.pulse.faster_title".localized
        case .breathed: return "onboarding_v2.pulse.breathed_title".localized
        }
    }

    private var message: String {
        switch outcome {
        case .calmer: return "onboarding_v2.pulse.calmer_message".localized
        case .steady: return "onboarding_v2.pulse.steady_message".localized
        case .faster: return "onboarding_v2.pulse.faster_message".localized
        case .breathed: return "onboarding_v2.pulse.breathed_message".localized
        }
    }

    private func column(_ label: String, _ bpm: Int, emphasised: Bool) -> some View {
        VStack(spacing: 6) {
            Text(label.uppercased())
                .font(.poppinsSemiBold(12))
                .tracking(1)
                .foregroundStyle(emphasised ? AudioPalette.accent : .white.opacity(0.55))
            Text(verbatim: "\(bpm)")
                .font(.faroBold(emphasised ? 64 : 44))
                .foregroundStyle(emphasised ? .white : .white.opacity(0.6))
            Text(verbatim: "BPM")
                .font(.poppinsSemiBold(12))
                .foregroundStyle(.white.opacity(0.5))
        }
    }
}
