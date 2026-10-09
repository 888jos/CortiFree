//
//  BreathePauseView.swift
//  CortiFree
//
//  The 30-second pause shown before TikTok / Instagram (Shortcuts automation), and the
//  guide that explains how to set the automation up.
//

import SwiftUI

struct BreathePauseView: View {
    let app: PauseApp

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var start = Date()
    @State private var finished = false
    @State private var lastToken = -1
    /// 4 s in, 8 s out: slow exhales bring the heart rate down. Same curve as the sessions.
    private static let timeline = BreathingTimeline(pattern: .extendedExhale)
    private let duration: TimeInterval = 30

    private func t(_ key: String) -> String { LanguageManager.shared.localizedString(for: key) }

    var body: some View {
        ZStack {
            GalaxyBackgroundView(intensity: 0.85, isAnimated: false).ignoresSafeArea()

            VStack(spacing: 24) {
                Text(String(format: t("calm.pause.about_to_open"), app.name))
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AudioPalette.secondaryText)
                    .padding(.top, 40)

                Spacer(minLength: 0)

                if finished {
                    Text(t("calm.pause.done"))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .transition(.opacity)
                } else {
                    TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { context in
                        let elapsed = context.date.timeIntervalSince(start)
                        let position = Self.timeline.position(at: elapsed)
                        VStack(spacing: 22) {
                            Text(position.step.localizedLabel)
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                            BreathingWaveView(
                                timeline: Self.timeline,
                                elapsed: elapsed,
                                accent: AudioPalette.accent,
                                reduceMotion: reduceMotion
                            )
                            .frame(height: 220)
                            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                            .padding(.horizontal, 20)
                            ProgressView(value: min(elapsed / duration, 1))
                                .tint(AudioPalette.accent)
                                .padding(.horizontal, 60)
                        }
                        .onChange(of: position.token) { _, token in
                            guard token != lastToken else { return }
                            lastToken = token
                            HapticManager.light()
                        }
                        .onChange(of: elapsed >= duration) { _, done in
                            guard done, !finished else { return }
                            withAnimation(.easeInOut(duration: 0.3)) { finished = true }
                            HapticManager.success()
                        }
                    }
                }

                Spacer(minLength: 0)

                if finished {
                    VStack(spacing: 10) {
                        Button {
                            HapticManager.light()
                            BreathePauseCenter.shared.finish(app, openApp: false)
                        } label: {
                            Text(t("calm.pause.stay_calm"))
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(AudioPalette.backgroundDeep)
                                .frame(maxWidth: .infinity, minHeight: 52)
                                .background(AudioPalette.accent, in: Capsule())
                        }
                        .buttonStyle(PressableCardStyle())
                        Button(String(format: t("calm.pause.open_anyway"), app.name)) {
                            BreathePauseCenter.shared.finish(app, openApp: true)
                        }
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))
                        .frame(minHeight: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                    .transition(.opacity)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear { start = Date() }
    }
}

/// How to make TikTok (or any app) open CortiFree first.
struct BreathePauseSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

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
                            .cfGlassCircle(interactive: false)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(t("common.close"))
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        Image("cortifree_assistant_avatar").resizable().scaledToFit().frame(width: 64, height: 64)
                        Text(t("calm.pause.setup.title"))
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text(t("calm.pause.setup.subtitle"))
                            .font(.system(size: 15))
                            .foregroundStyle(AudioPalette.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)

                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(1...3, id: \.self) { step in
                                HStack(alignment: .top, spacing: 12) {
                                    Text(verbatim: "\(step)")
                                        .font(.system(size: 13, weight: .bold, design: .rounded))
                                        .foregroundStyle(AudioPalette.backgroundDeep)
                                        .frame(width: 24, height: 24)
                                        .background(AudioPalette.accent, in: Circle())
                                    Text(t("calm.pause.setup.step\(step)"))
                                        .font(.system(size: 15))
                                        .foregroundStyle(.white.opacity(0.9))
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                        .padding(16)
                        .cfGlass(cornerRadius: 22)

                        Text(t("calm.pause.setup.note"))
                            .font(.system(size: 12))
                            .foregroundStyle(AudioPalette.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(20)
                }

                Button {
                    HapticManager.light()
                    if let url = URL(string: "shortcuts://") { openURL(url) }
                } label: {
                    Label(t("calm.pause.setup.open_shortcuts"), systemImage: "square.stack.3d.up.fill")
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
        .preferredColorScheme(.dark)
    }
}
