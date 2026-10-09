//
//  NervousResetView.swift
//  CortiFree
//
//  60-second nervous system reset: the four techniques people share on TikTok, guided
//  with animation and haptics. Milo picks one for the moment (heart rate, time of day),
//  the user can switch. Used on its own and between the two pulse measures.
//

import SwiftUI

enum NervousResetMode: String, CaseIterable, Identifiable, Codable {
    case sigh, humming, butterfly, grounding

    var id: String { rawValue }
    var icon: String {
        switch self {
        case .sigh: return "wind"
        case .humming: return "waveform"
        case .butterfly: return "hands.sparkles.fill"
        case .grounding: return "hand.raised.fingers.spread.fill"
        }
    }
    var titleKey: String { "calm.reset.mode.\(rawValue).title" }
    var whyKey: String { "calm.reset.mode.\(rawValue).why" }

    /// Milo's pick: a racing heart gets the fastest down-shift, nights get humming,
    /// evenings the butterfly hug, daytime overthinking the 5-4-3-2-1.
    static func recommended(bpm: Int? = nil, date: Date = Date()) -> NervousResetMode {
        if let bpm, bpm >= 90 { return .sigh }
        switch Calendar.current.component(.hour, from: date) {
        case 21..<24, 0..<5: return .humming
        case 17..<21: return .butterfly
        case 11..<17: return .grounding
        default: return .sigh
        }
    }
}

struct NervousResetSession: View {
    let mode: NervousResetMode
    var duration: TimeInterval = 60
    let onFinish: () -> Void

    @State private var start = Date()
    @State private var finished = false
    @State private var lastCue = ""
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private func t(_ key: String) -> String { LanguageManager.shared.localizedString(for: key) }

    var body: some View {
        TimelineView(.animation) { context in
            let elapsed = context.date.timeIntervalSince(start)
            let remaining = max(0, Int(ceil(duration - elapsed)))
            let cue = cue(at: elapsed)

            VStack(spacing: 28) {
                Text(t(mode.titleKey).uppercased())
                    .font(.system(size: 12, weight: .semibold))
                    .tracking(1)
                    .foregroundStyle(AudioPalette.accent)

                visual(at: elapsed)
                    .frame(height: 240)

                VStack(spacing: 8) {
                    Text(cue.text)
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .contentTransition(.opacity)
                        .animation(.easeInOut(duration: 0.25), value: cue.text)
                    Text(String(format: t("calm.reset.remaining"), remaining))
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(AudioPalette.secondaryText)
                        .monospacedDigit()
                }

                Text(t(mode.whyKey))
                    .font(.system(size: 13))
                    .foregroundStyle(AudioPalette.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .onChange(of: cue.text) { _, text in
                guard text != lastCue else { return }
                lastCue = text
                if cue.haptic { HapticManager.light() }
            }
            .onChange(of: remaining) { _, value in
                if value == 0, !finished {
                    finished = true
                    HapticManager.success()
                    onFinish()
                }
            }
        }
        .onAppear { start = Date() }
    }

    // MARK: Cues

    private struct Cue { let text: String; let haptic: Bool }

    private func cue(at time: TimeInterval) -> Cue {
        switch mode {
        case .sigh:
            // Double inhale (2 s + 1 s), long exhale (6 s).
            let phase = time.truncatingRemainder(dividingBy: 9)
            if phase < 2 { return Cue(text: t("calm.reset.cue.inhale"), haptic: true) }
            if phase < 3 { return Cue(text: t("calm.reset.cue.inhale_more"), haptic: true) }
            return Cue(text: t("calm.reset.cue.long_exhale"), haptic: true)
        case .humming:
            // 4 s in, 7 s humming out: the same rhythm as the « Humming » curve.
            let phase = time.truncatingRemainder(dividingBy: 11)
            return phase < 4 ? Cue(text: t("calm.reset.cue.inhale"), haptic: true) : Cue(text: t("calm.reset.cue.hum"), haptic: true)
        case .butterfly:
            let beat = Int(time / 0.8)
            return Cue(text: t(beat % 2 == 0 ? "calm.reset.cue.left" : "calm.reset.cue.right"), haptic: true)
        case .grounding:
            let step = min(4, Int(time / (duration / 5)))
            return Cue(text: t("calm.reset.cue.ground\(5 - step)"), haptic: true)
        }
    }

    // MARK: Visuals

    @ViewBuilder
    private func visual(at time: TimeInterval) -> some View {
        switch mode {
        case .sigh:
            // Never an orb: the « roller coaster » curve used by every breathing session.
            wave(.physiologicalSigh, at: time)
        case .humming:
            wave(.humming, at: time)
        case .butterfly:
            let left = Int(time / 0.8) % 2 == 0
            HStack(spacing: 24) {
                wing(active: left).scaleEffect(x: -1)
                wing(active: !left)
            }
            .frame(width: 240, height: 240)
        case .grounding:
            let step = min(4, Int(time / (duration / 5)))
            ZStack {
                Circle().fill(AudioPalette.accent.opacity(0.16))
                Text(verbatim: "\(5 - step)")
                    .font(.system(size: 110, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                    .animation(.spring, value: step)
            }
            .frame(width: 240, height: 240)
        }
    }

    private func wave(_ pattern: BreathingPattern, at time: TimeInterval) -> some View {
        BreathingWaveView(
            timeline: BreathingTimeline(pattern: pattern),
            elapsed: time,
            accent: AudioPalette.accent,
            reduceMotion: reduceMotion
        )
        .frame(height: 220)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .padding(.horizontal, 20)
    }

    private func wing(active: Bool) -> some View {
        Image(systemName: "hand.raised.fill")
            .font(.system(size: 64, weight: .semibold))
            .foregroundStyle(active ? AudioPalette.accent : .white.opacity(0.25))
            .scaleEffect(active ? 1.15 : 0.9)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: active)
    }
}

/// Standalone « 60-second reset »: Milo's pick first, other techniques one tap away.
struct NervousResetView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var mode = NervousResetMode.recommended()
    @State private var running = false
    @State private var done = false

    private func t(_ key: String) -> String { LanguageManager.shared.localizedString(for: key) }

    var body: some View {
        ZStack {
            GalaxyBackgroundView(intensity: 0.85).ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Spacer()
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
                .padding(.horizontal, 16)
                .padding(.top, 14)

                Spacer(minLength: 0)
                if running {
                    NervousResetSession(mode: mode) {
                        running = false
                        done = true
                    }
                    .id(mode)
                } else if done {
                    VStack(spacing: 14) {
                        Image("cortifree_assistant_avatar").resizable().scaledToFit().frame(width: 84, height: 84)
                        Text(t("calm.reset.done.title"))
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text(t("calm.reset.done.subtitle"))
                            .font(.system(size: 15))
                            .foregroundStyle(AudioPalette.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 28)
                } else {
                    intro
                }
                Spacer(minLength: 0)

                if !running {
                    Button {
                        HapticManager.light()
                        if done { dismiss() } else { running = true }
                    } label: {
                        Text(t(done ? "calm.common.done" : "calm.reset.start"))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(AudioPalette.backgroundDeep)
                            .frame(maxWidth: .infinity, minHeight: 52)
                            .background(AudioPalette.accent, in: Capsule())
                    }
                    .buttonStyle(PressableCardStyle())
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var intro: some View {
        VStack(spacing: 18) {
            Image("cortifree_assistant_avatar").resizable().scaledToFit().frame(width: 84, height: 84)
            Text(t("calm.reset.title"))
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
            Text(String(format: t("calm.reset.milo_pick"), t(mode.titleKey)))
                .font(.system(size: 15))
                .foregroundStyle(AudioPalette.secondaryText)
                .multilineTextAlignment(.center)
            NervousResetModePicker(selection: $mode)
        }
        .padding(.horizontal, 24)
    }
}

/// Four capsules to switch technique.
struct NervousResetModePicker: View {
    @Binding var selection: NervousResetMode

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            ForEach(NervousResetMode.allCases) { mode in
                Button {
                    HapticManager.light()
                    selection = mode
                } label: {
                    Label(LanguageManager.shared.localizedString(for: mode.titleKey), systemImage: mode.icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(selection == mode ? AudioPalette.backgroundDeep : .white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(selection == mode ? AudioPalette.accent : Color.white.opacity(0.1), in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }
}
