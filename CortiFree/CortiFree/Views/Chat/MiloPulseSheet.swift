//
//  MiloPulseSheet.swift
//  CortiFree
//
//  « Measure my pulse » from Milo: read the latest Apple Watch heart rate from Apple Health,
//  or measure it with the flash and a fingertip on the back camera. The result goes back to
//  Milo, which recommends a breathing exercise to bring it down. Wellness only, not medical.
//

import SwiftUI

enum MiloPulseSource: String {
    case watch, camera
}

struct MiloPulseSheet: View {
    let onResult: (Int, MiloPulseSource) -> Void

    @Environment(\.dismiss) private var dismiss
    @StateObject private var meter = PulseCameraMeter()
    @State private var step: Step = .choose
    /// Asked once: without a watch the flash measure starts straight away (Profile changes it).
    @AppStorage(AppleWatchPreference.storageKey) private var appleWatch = ""

    private enum Step: Equatable {
        case choose
        case watchLoading
        case watchResult(bpm: Int, date: Date)
        case watchEmpty
        case camera
        case cameraResult(bpm: Int, reliable: Bool)
    }

    /// A watch sample older than this is shown with a tip to take a fresh one.
    private static let freshness: TimeInterval = 15 * 60

    private func t(_ key: String) -> String { LanguageManager.shared.localizedString(for: key) }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            AudioPalette.backgroundGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 56)
                content
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 24)
                Spacer(minLength: 24)
            }

            Button {
                meter.stop()
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .cfGlassCircle(interactive: false)
            }
            .buttonStyle(.plain)
            .padding(16)
            .accessibilityLabel(t("achievements.close"))
        }
        .environment(\.colorScheme, .dark)
        .onChange(of: meter.state) { _, state in
            guard case .done(let bpm) = state else { return }
            step = .cameraResult(bpm: bpm, reliable: meter.lastReading?.reliable ?? true)
        }
        .onAppear {
            guard step == .choose else { return }
            if appleWatch == AppleWatchPreference.no {
                startCamera()
            } else if appleWatch == AppleWatchPreference.yes {
                readWatch()
            }
        }
        .onDisappear { meter.stop() }
    }

    // MARK: Steps

    @ViewBuilder
    private var content: some View {
        switch step {
        case .choose:
            choose
        case .watchLoading:
            VStack(spacing: 14) {
                ProgressView().tint(.white).controlSize(.large)
                Text(t("milo.pulse.watch.loading"))
                    .font(.system(size: 15))
                    .foregroundStyle(AudioPalette.secondaryText)
            }
        case .watchResult(let bpm, let date):
            watchResult(bpm: bpm, date: date)
        case .watchEmpty:
            message(icon: "applewatch.slash", title: t("milo.pulse.watch.empty.title"), body: t("milo.pulse.watch.empty.body")) {
                primary(t("milo.pulse.use_camera"), icon: "flashlight.on.fill") { startCamera() }
                secondary(t("milo.pulse.watch.refresh")) { readWatch() }
            }
        case .camera:
            PulseMeasuringView(meter: meter, title: t("milo.pulse.camera.title"))
        case .cameraResult(let bpm, let reliable):
            result(bpm: bpm, caption: reliable ? t("milo.pulse.camera.done") : t("milo.pulse.camera.doubtful")) {
                primary(t("milo.pulse.send"), icon: "arrow.up") { finish(bpm, .camera) }
                secondary(t("milo.pulse.again")) { startCamera() }
            }
        }
    }

    private var choose: some View {
        VStack(spacing: 22) {
            PulseHeart(beating: true, bpm: 64)
                .frame(width: 76, height: 76)
            VStack(spacing: 8) {
                Text(t("milo.pulse.title"))
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                Text(t("milo.pulse.subtitle"))
                    .font(.system(size: 15))
                    .foregroundStyle(AudioPalette.secondaryText)
                    .multilineTextAlignment(.center)
            }
            VStack(spacing: 12) {
                option(icon: "applewatch", title: t("milo.pulse.watch"), subtitle: t("milo.pulse.watch.subtitle")) {
                    appleWatch = AppleWatchPreference.yes
                    readWatch()
                }
                option(icon: "flashlight.on.fill", title: t("milo.pulse.no_watch"), subtitle: t("milo.pulse.camera.subtitle")) {
                    appleWatch = AppleWatchPreference.no
                    startCamera()
                }
            }
            Text(t("milo.pulse.disclaimer"))
                .font(.system(size: 12))
                .foregroundStyle(AudioPalette.secondaryText)
                .multilineTextAlignment(.center)
        }
    }

    private func watchResult(bpm: Int, date: Date) -> some View {
        let fresh = Date().timeIntervalSince(date) < Self.freshness
        let ago = date.formatted(.relative(presentation: .named, unitsStyle: .wide))
        return result(bpm: bpm, caption: String(format: t("milo.pulse.watch.measured"), ago)) {
            if !fresh {
                Text(t("milo.pulse.watch.stale"))
                    .font(.system(size: 13))
                    .foregroundStyle(Color(hex: "FFD36B"))
                    .multilineTextAlignment(.center)
            }
            primary(t("milo.pulse.send"), icon: "arrow.up") { finish(bpm, .watch) }
            secondary(fresh ? t("milo.pulse.use_camera") : t("milo.pulse.watch.refresh")) {
                fresh ? startCamera() : readWatch()
            }
        }
    }

    // MARK: Actions

    private func readWatch() {
        meter.stop()
        step = .watchLoading
        Task {
            if let sample = await HealthKitService.shared.latestHeartRate() {
                step = .watchResult(bpm: sample.bpm, date: sample.date)
            } else {
                step = .watchEmpty
            }
        }
    }

    private func startCamera() {
        step = .camera
        meter.start()
    }

    private func finish(_ bpm: Int, _ source: MiloPulseSource) {
        HapticManager.light()
        meter.stop()
        AnalyticsManager.shared.track(event: "milo_pulse_measured", properties: ["source": source.rawValue])
        onResult(bpm, source)
        dismiss()
    }

    // MARK: Building blocks

    private func option(icon: String, title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button {
            HapticManager.light()
            action()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(AudioPalette.accent)
                    .frame(width: 46, height: 46)
                    .background(AudioPalette.accent.opacity(0.15), in: Circle())
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundStyle(AudioPalette.secondaryText)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AudioPalette.secondaryText)
            }
            .padding(14)
            .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(Color.white.opacity(0.08), lineWidth: 1))
        }
        .buttonStyle(PressableCardStyle())
    }

    private func result<Actions: View>(bpm: Int, caption: String, @ViewBuilder actions: () -> Actions) -> some View {
        VStack(spacing: 18) {
            PulseHeart(beating: true, bpm: bpm)
                .frame(width: 80, height: 80)
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(verbatim: "\(bpm)")
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .monospacedDigit()
                Text(verbatim: "BPM")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AudioPalette.secondaryText)
            }
            Text(caption)
                .font(.system(size: 15))
                .foregroundStyle(AudioPalette.secondaryText)
                .multilineTextAlignment(.center)
            VStack(spacing: 10) { actions() }
                .padding(.top, 6)
        }
    }

    private func message<Actions: View>(icon: String, title: String, body: String, @ViewBuilder actions: () -> Actions) -> some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundStyle(AudioPalette.accent)
            Text(title)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
            Text(body)
                .font(.system(size: 15))
                .foregroundStyle(AudioPalette.secondaryText)
                .multilineTextAlignment(.center)
            VStack(spacing: 10) { actions() }
                .padding(.top, 6)
        }
    }

    private func primary(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AudioPalette.backgroundDeep)
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(AudioPalette.accent, in: Capsule())
        }
        .buttonStyle(PressableCardStyle())
    }

    private func secondary(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AudioPalette.accent)
                .frame(maxWidth: .infinity, minHeight: 44)
        }
        .buttonStyle(.plain)
    }
}
