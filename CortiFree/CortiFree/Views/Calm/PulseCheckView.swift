//
//  PulseCheckView.swift
//  CortiFree
//
//  « Watch my heart slow down »: measure the pulse with the camera, do a 60-second
//  nervous system reset picked by Milo, measure again, see the difference.
//  Shown in the onboarding (before the plan) and from Home / Milo.
//

import SwiftUI

/// Last calm check, for Milo's context and the Home tile.
struct PulseCheckRecord: Codable, Equatable {
    let before: Int
    let after: Int
    let mode: NervousResetMode
    let date: Date

    static let storageKey = "calm.pulse.last.v1"

    static var last: PulseCheckRecord? {
        UserDefaults.standard.data(forKey: storageKey).flatMap { try? JSONDecoder().decode(PulseCheckRecord.self, from: $0) }
    }

    func save() {
        if let data = try? JSONEncoder().encode(self) { UserDefaults.standard.set(data, forKey: Self.storageKey) }
    }

    var contextLine: String {
        "Last calm check (\(date.formatted(date: .abbreviated, time: .shortened))): heart rate \(before) bpm before, \(after) bpm after a 60-second \(mode.rawValue) reset."
    }
}

struct PulseCheckView: View {
    enum Context { case standalone, onboarding }

    var context: Context = .standalone
    /// Onboarding: called by « Continue » or « Skip ».
    var onContinue: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @StateObject private var meter = PulseCameraMeter()

    private enum Phase: Equatable {
        case intro
        case measureBefore
        case beforeResult(Int)
        case reset(before: Int, mode: NervousResetMode)
        case measureAfter(before: Int, mode: NervousResetMode)
        case final(before: Int, after: Int, mode: NervousResetMode)
    }

    @State private var phase: Phase = .intro
    @State private var mode = NervousResetMode.sigh
    @AppStorage("pulse.firstUseGuideSeen.v1") private var hasSeenFirstUseGuide = false
    @State private var firstUseGuidePage = 0
    /// A doubtful reading in this check (too high/low at rest, irregular signal).
    @State private var beforeDoubtful = false
    @State private var afterDoubtful = false

    private func t(_ key: String) -> String { LanguageManager.shared.localizedString(for: key) }

    var body: some View {
        ZStack {
            GalaxyBackgroundView(intensity: 0.85).ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                Spacer(minLength: 0)
                content
                    .transition(.opacity)
                Spacer(minLength: 0)
                bottomBar
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.88), value: phase)
        .preferredColorScheme(.dark)
        .onChange(of: meter.state) { _, state in
            guard case .done(let bpm) = state else { return }
            let doubtful = meter.lastReading.map { PulsePlausibility.doubt(for: $0) != nil } ?? false
            switch phase {
            case .measureBefore:
                beforeDoubtful = doubtful
                WeeklyPulseStore.shared.recordRestingPulse(bpm)
                mode = NervousResetMode.recommended(bpm: bpm)
                phase = .beforeResult(bpm)
            case .measureAfter(let before, let mode):
                afterDoubtful = doubtful
                PulseCheckRecord(before: before, after: bpm, mode: mode, date: Date()).save()
                AnalyticsManager.shared.track(event: "calm_check_completed", properties: ["mode": mode.rawValue])
                phase = .final(before: before, after: bpm, mode: mode)
            default: break
            }
        }
        .onDisappear { meter.stop() }
    }

    // MARK: Bars

    private var topBar: some View {
        HStack {
            Spacer()
            if context == .onboarding {
                Button(t("calm.common.skip")) {
                    meter.stop()
                    onContinue?()
                }
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.white.opacity(0.7))
            } else {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 38, height: 38)
                        .cfGlassCircle()
                }
                .buttonStyle(.plain)
                .accessibilityLabel(t("common.close"))
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .frame(height: 56)
    }

    @ViewBuilder
    private var bottomBar: some View {
        if showsFirstUseGuide {
            VStack(spacing: 12) {
                HStack(spacing: 7) {
                    ForEach(0..<firstUseGuidePages.count, id: \.self) { page in
                        Capsule()
                            .fill(page == firstUseGuidePage ? AudioPalette.accent : Color.white.opacity(0.22))
                            .frame(width: page == firstUseGuidePage ? 20 : 7, height: 7)
                    }
                }
                primary(t("calm.common.continue")) {
                    if firstUseGuidePage < firstUseGuidePages.count - 1 {
                        withAnimation(.easeInOut(duration: 0.22)) { firstUseGuidePage += 1 }
                    } else {
                        hasSeenFirstUseGuide = true
                    }
                }
            }
        } else {
            switch phase {
            case .intro:
                primary(t("calm.pulse.intro.cta")) { startMeasure(.measureBefore) }
            case .beforeResult(let bpm):
                VStack(spacing: 12) {
                    NervousResetModePicker(selection: $mode)
                    primary(t("calm.pulse.reset.cta")) { phase = .reset(before: bpm, mode: mode) }
                }
            case .final:
                primary(t(context == .onboarding ? "calm.common.continue" : "calm.common.done")) {
                    if context == .onboarding { onContinue?() } else { dismiss() }
                }
            default:
                Color.clear.frame(height: 72)
            }
        }
    }

    private func primary(_ title: String, action: @escaping () -> Void) -> some View {
        Button {
            HapticManager.light()
            action()
        } label: {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AudioPalette.backgroundDeep)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(AudioPalette.accent, in: Capsule())
        }
        .buttonStyle(PressableCardStyle())
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }

    private func startMeasure(_ next: Phase) {
        #if targetEnvironment(simulator)
        if case .measureAfter(let before, _) = next { meter.simulatedBPM = Double(max(58, before - 14)) }
        #endif
        phase = next
        meter.start()
    }

    // MARK: Content

    @ViewBuilder
    private var content: some View {
        if showsFirstUseGuide {
            firstUseGuide
        } else {
            switch phase {
            case .intro:
                VStack(spacing: 16) {
                    PulseHeart(beating: true, bpm: 70).frame(width: 150, height: 150)
                    Text(t(context == .onboarding ? "calm.pulse.intro.title_onboarding" : "calm.pulse.intro.title"))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                    Text(t("calm.pulse.intro.subtitle"))
                        .font(.system(size: 15))
                        .foregroundStyle(AudioPalette.secondaryText)
                        .multilineTextAlignment(.center)
                    Label(t("calm.pulse.intro.how"), systemImage: "camera.fill")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.85))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .background(Color.white.opacity(0.1), in: Capsule())
                }
                .padding(.horizontal, 28)

            case .measureBefore, .measureAfter:
                measuring(after: { if case .measureAfter = phase { return true } else { return false } }())

            case .beforeResult(let bpm):
                VStack(spacing: 14) {
                Text(t("calm.pulse.before.label").uppercased())
                    .font(.system(size: 12, weight: .semibold))
                    .tracking(1)
                    .foregroundStyle(AudioPalette.accent)
                bpmText(bpm)
                if beforeDoubtful {
                    VStack(spacing: 8) {
                        Text(t("onboarding_v2.pulse.doubt_title"))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color(hex: "FFB86B"))
                        Text(t("onboarding_v2.pulse.doubt_tip"))
                            .font(.system(size: 13))
                            .foregroundStyle(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                        Button(t("onboarding_v2.pulse.remeasure")) { startMeasure(.measureBefore) }
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(AudioPalette.accent)
                    }
                    .padding(.horizontal, 28)
                }
                Text(String(format: t("calm.pulse.before.milo"), t(mode.titleKey)))
                    .font(.system(size: 15))
                    .foregroundStyle(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
                }

            case .reset(let before, let mode):
                NervousResetSession(mode: mode) {
                    startMeasure(.measureAfter(before: before, mode: mode))
                }

            case .final(let before, let after, _):
                finalView(before: before, after: after)
            }
        }
    }

    private var showsFirstUseGuide: Bool {
        context == .standalone && !hasSeenFirstUseGuide
    }

    private var firstUseGuidePages: [(icon: String, title: String, body: String)] {
        [
            ("camera.fill", t("calm.pulse.intro.how"), t("onboarding_v2.pulse.step_finger")),
            ("hand.point.up.left.fill", t("onboarding_v2.pulse.title"), t("onboarding_v2.pulse.step_pressure")),
            ("timer", t("calm.pulse.measure.title"), t("onboarding_v2.pulse.step_still"))
        ]
    }

    private var firstUseGuide: some View {
        let page = firstUseGuidePages[firstUseGuidePage]
        return VStack(spacing: 20) {
            Image(systemName: page.icon)
                .font(.system(size: 54, weight: .semibold))
                .foregroundStyle(AudioPalette.accent)
                .frame(width: 118, height: 118)
                .background(Color.white.opacity(0.08), in: Circle())
            Text(page.title)
                .font(.system(size: 27, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
            Text(page.body)
                .font(.system(size: 16))
                .foregroundStyle(AudioPalette.secondaryText)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .id(firstUseGuidePage)
        .transition(.opacity.combined(with: .scale(scale: 0.98)))
        .padding(.horizontal, 32)
    }

    private func measuring(after: Bool) -> some View {
        PulseMeasuringView(meter: meter, title: t(after ? "calm.pulse.measure.again" : "calm.pulse.measure.title"))
    }

    private func finalView(before: Int, after: Int) -> some View {
        let delta = before - after
        let unreliable = beforeDoubtful || afterDoubtful || abs(delta) > PulsePlausibility.maxCredibleChange
        return VStack(spacing: 18) {
            HStack(alignment: .bottom, spacing: 18) {
                column(t("calm.pulse.final.before"), before, dim: true)
                Image(systemName: "arrow.right")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(AudioPalette.accent)
                    .padding(.bottom, 26)
                column(t("calm.pulse.final.after"), after, dim: false)
            }
            Text(unreliable ? t("onboarding_v2.pulse.unreliable_title")
                 : delta > 0 ? String(format: t("calm.pulse.final.slowed"), delta) : t("calm.pulse.final.steady"))
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
            Text(t(unreliable ? "onboarding_v2.pulse.unreliable_message"
                   : delta > 0 ? "calm.pulse.final.milo_down" : "calm.pulse.final.milo_steady"))
                .font(.system(size: 15))
                .foregroundStyle(AudioPalette.secondaryText)
                .multilineTextAlignment(.center)
            Text(t("calm.pulse.disclaimer"))
                .font(.system(size: 11))
                .foregroundStyle(AudioPalette.secondaryText.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 28)
    }

    private func column(_ label: String, _ bpm: Int, dim: Bool) -> some View {
        VStack(spacing: 6) {
            Text(label.uppercased())
                .font(.system(size: 12, weight: .semibold))
                .tracking(1)
                .foregroundStyle(dim ? AudioPalette.secondaryText : AudioPalette.accent)
            Text(verbatim: "\(bpm)")
                .font(.system(size: dim ? 44 : 64, weight: .bold, design: .rounded))
                .foregroundStyle(dim ? .white.opacity(0.6) : .white)
            Text(verbatim: "BPM")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AudioPalette.secondaryText)
        }
    }

    private func bpmText(_ bpm: Int) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(verbatim: "\(bpm)")
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text(verbatim: "BPM")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AudioPalette.secondaryText)
        }
    }
}

/// Live measure: progress ring, beating heart with the live BPM, waveform and finger hints.
struct PulseMeasuringView: View {
    @ObservedObject var meter: PulseCameraMeter
    let title: String

    private func t(_ key: String) -> String { LanguageManager.shared.localizedString(for: key) }

    /// Live coaching under the ring: what to fix, else the default instruction.
    private var hintKey: String {
        switch meter.hint {
        case .coverFlash: return "calm.pulse.hint.cover_flash"
        case .placeFinger: return "calm.pulse.measure.place_finger"
        case .holdStill: return "calm.pulse.hint.hold_still"
        case .almostDone: return "calm.pulse.hint.almost_done"
        case nil: return meter.state == .waitingForFinger ? "calm.pulse.measure.place_finger" : "calm.pulse.measure.hold_still"
        }
    }

    var body: some View {
        VStack(spacing: 22) {
            Text(title)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            ZStack {
                Circle()
                    .trim(from: 0, to: meter.progress)
                    .stroke(AudioPalette.accent, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Circle().stroke(Color.white.opacity(0.1), lineWidth: 6)
                VStack(spacing: 4) {
                    PulseHeart(beating: meter.state == .measuring, bpm: meter.liveBPM ?? 70).frame(width: 70, height: 70)
                    Text(meter.liveBPM.map { "\($0)" } ?? "--")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                    Text(verbatim: "BPM")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AudioPalette.secondaryText)
                }
            }
            .frame(width: 210, height: 210)

            PulseWaveform(values: meter.waveform)
                .frame(height: 60)
                .padding(.horizontal, 32)

            Group {
                switch meter.state {
                case .failed(let message):
                    VStack(spacing: 10) {
                        Text(message)
                        Button(t("calm.pulse.retry")) { meter.start() }
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(AudioPalette.accent)
                    }
                default:
                    Text(t(hintKey))
                        .contentTransition(.opacity)
                }
            }
            .font(.system(size: 15))
            .foregroundStyle(meter.hint == .coverFlash || meter.hint == .holdStill ? Color(hex: "FFC56B") : .white.opacity(0.8))
            .multilineTextAlignment(.center)
            .padding(.horizontal, 32)
            .frame(minHeight: 44, alignment: .top)
            .animation(.easeInOut(duration: 0.25), value: meter.hint)
        }
    }
}

/// Heart that beats at the measured pace.
struct PulseHeart: View {
    let beating: Bool
    let bpm: Int

    var body: some View {
        TimelineView(.animation(paused: !beating)) { context in
            let period = 60 / Double(max(40, bpm))
            let phase = context.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: period) / period
            let pulse = phase < 0.15 ? 1 + 0.18 * sin(phase / 0.15 * .pi) : 1
            Image(systemName: "heart.fill")
                .resizable()
                .scaledToFit()
                .foregroundStyle(LinearGradient(colors: [Color(hex: "FF6B9A"), AudioPalette.accent], startPoint: .top, endPoint: .bottom))
                .scaleEffect(beating ? pulse : 1)
                .shadow(color: Color(hex: "FF6B9A").opacity(0.5), radius: 18)
        }
    }
}

/// Live photoplethysmography trace.
struct PulseWaveform: View {
    let values: [Double]

    var body: some View {
        GeometryReader { geo in
            Path { path in
                guard values.count > 1 else { return }
                let step = geo.size.width / CGFloat(values.count - 1)
                for (index, value) in values.enumerated() {
                    let point = CGPoint(x: CGFloat(index) * step, y: geo.size.height * (1 - CGFloat(value)))
                    if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
                }
            }
            .stroke(LinearGradient(colors: [Color(hex: "FF6B9A"), AudioPalette.accent], startPoint: .leading, endPoint: .trailing),
                    style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
        }
    }
}
