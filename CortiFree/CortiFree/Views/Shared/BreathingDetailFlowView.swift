//
//  BreathingDetailFlowView.swift
//  CortiFree
//
//  Created by Claude on 30/11/2025.
//  Guided breathing session — "roller coaster" curve driven by elapsed time.
//

import SwiftUI
import UIKit

struct BreathingDetailFlowView: View {
    let pattern: BreathingPattern
    let duration: TimeInterval
    let onComplete: () -> Void

    @Environment(\.dismiss) var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ObservedObject private var languageManager = LanguageManager.shared
    @ObservedObject private var voiceOverManager = VoiceOverManager.shared
    @ObservedObject private var preferences = BreathingPreferences.shared
    @State private var ambiencePlayer = BreathingAmbiencePlayer()

    private static let leadIn: Double = 3

    // Elapsed-time clock: elapsed = baseElapsed + (now - anchorDate) while running.
    @State private var baseElapsed: Double = -BreathingDetailFlowView.leadIn
    @State private var anchorDate: Date?
    @State private var isPaused = false
    @State private var isFinished = false
    @State private var didRecordCompletion = false
    @State private var lastToken: Int = -1
    @State private var breathedSeconds: Double = 0

    private let timeline: BreathingTimeline

    init(pattern: BreathingPattern, duration: TimeInterval = 180, onComplete: @escaping () -> Void = {}) {
        self.pattern = pattern
        self.duration = duration
        self.onComplete = onComplete
        self.timeline = BreathingTimeline(pattern: pattern)
    }

    /// Session length rounded up to complete the last cycle.
    private var plannedTotal: Double {
        let cycle = timeline.cycleDuration
        return max(cycle, ceil(max(duration, 1) / cycle - 0.001) * cycle)
    }

    private var accent: Color { AudioPalette.accent }

    var body: some View {
        ZStack {
            GalaxyBackgroundView(intensity: 0.7)
                .ignoresSafeArea()

            TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: isPaused || isFinished || anchorDate == nil)) { context in
                let elapsed = currentElapsed(at: context.date)
                sessionContent(elapsed: elapsed)
                    .onChange(of: phaseToken(for: elapsed)) { _, newToken in
                        handlePhaseChange(token: newToken, elapsed: elapsed)
                    }
                    .onChange(of: elapsed >= plannedTotal) { _, done in
                        if done { finishSession() }
                    }
            }
            .opacity(isFinished ? 0 : 1)

            if isFinished {
                BreathingSessionEndView(
                    pattern: pattern,
                    breathedSeconds: breathedSeconds,
                    cycles: max(1, Int((breathedSeconds / timeline.cycleDuration).rounded(.up))),
                    onDone: {
                        dismiss()
                        onComplete()
                    },
                    onRestart: restart
                )
                .transition(.opacity.combined(with: .scale(scale: 0.96)))
            }
        }
        .environment(\.colorScheme, .dark)
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
            if anchorDate == nil && !isPaused { anchorDate = Date() }
            ambiencePlayer.start(preferences.ambience, volume: preferences.ambienceVolume)
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
            voiceOverManager.stop()
            ambiencePlayer.stop()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active && !isPaused && !isFinished { pause() }
        }
    }

    // MARK: - Clock

    private func currentElapsed(at date: Date) -> Double {
        guard let anchorDate, !isPaused else { return baseElapsed }
        return baseElapsed + date.timeIntervalSince(anchorDate)
    }

    private func pause() {
        baseElapsed = currentElapsed(at: Date())
        anchorDate = nil
        isPaused = true
        ambiencePlayer.pause()
    }

    private func resume() {
        anchorDate = Date()
        isPaused = false
        ambiencePlayer.resume()
    }

    private func togglePause() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.8)
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            if isPaused { resume() } else { pause() }
        }
    }

    private func restart() {
        withAnimation(.easeInOut(duration: 0.4)) {
            baseElapsed = -Self.leadIn
            anchorDate = Date()
            isPaused = false
            isFinished = false
            didRecordCompletion = false
            lastToken = -1
        }
        ambiencePlayer.start(preferences.ambience, volume: preferences.ambienceVolume)
    }

    private func phaseToken(for elapsed: Double) -> Int {
        elapsed < 0 ? -10 - Int(ceil(-elapsed)) : timeline.position(at: elapsed).token
    }

    private func handlePhaseChange(token: Int, elapsed: Double) {
        guard token != lastToken, !isFinished else { return }
        lastToken = token
        guard elapsed >= 0 else {
            if preferences.hapticsEnabled { UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.4) }
            return
        }
        let position = timeline.position(at: elapsed)
        if preferences.hapticsEnabled {
            let style: UIImpactFeedbackGenerator.FeedbackStyle = (position.step.kind == .inhale) ? .soft : .light
            UIImpactFeedbackGenerator(style: style).impactOccurred(intensity: position.step.duration < 1.5 ? 0.45 : 0.75)
        }
        if position.step.duration >= 1.5 {
            voiceOverManager.announceBreathingPhase(phaseLabel(for: position))
        }
    }

    private func finishSession() {
        guard !isFinished else { return }
        breathedSeconds = min(plannedTotal, max(0, currentElapsed(at: Date())))
        baseElapsed = plannedTotal
        anchorDate = nil
        voiceOverManager.stop()
        ambiencePlayer.stop()
        HapticManager.success()
        if !didRecordCompletion && breathedSeconds >= min(30, plannedTotal - 0.5) {
            didRecordCompletion = true
            ExerciseSessionRecorder.shared.record(
                exerciseID: pattern.name,
                category: .breathing,
                durationSeconds: Int(breathedSeconds.rounded()),
                source: "breathing_flow"
            )
        }
        withAnimation(.easeInOut(duration: 0.6)) {
            isFinished = true
        }
    }

    // MARK: - Labels

    private func phaseLabel(for position: BreathingTimeline.Position) -> String {
        let base = position.step.localizedLabel
        guard pattern.isAlternateNostril else { return base }
        // Even cycles: in left / out right. Odd cycles: in right / out left.
        let leftFirst = position.cycle % 2 == 0
        let side: String
        switch position.step.kind {
        case .inhale, .inhaleTopUp:
            side = leftFirst ? "breathing.nostril.left" : "breathing.nostril.right"
        case .exhale:
            side = leftFirst ? "breathing.nostril.right" : "breathing.nostril.left"
        default:
            return base
        }
        return base + " · " + languageManager.localized(side)
    }

    private func formatTime(_ seconds: Double) -> String {
        let s = max(0, Int(ceil(seconds)))
        return String(format: "%d:%02d", s / 60, s % 60)
    }

    // MARK: - Content

    /// Full screen: the phase in large type, a wide roller-coaster track under a
    /// glowing marker and a light that swells with each breath.
    @ViewBuilder
    private func sessionContent(elapsed: Double) -> some View {
        let inLeadIn = elapsed < 0
        let position = timeline.position(at: max(0, elapsed))
        let label = inLeadIn ? languageManager.localized("breathing.session.get_ready") : phaseLabel(for: position)
        let countdown = inLeadIn ? Int(ceil(-elapsed)) : max(1, Int(ceil(position.stepRemaining - 0.001)))
        let level = timeline.level(at: elapsed)

        ZStack {
            breathingLight(level: level)
            VStack(spacing: 0) {
                topBar(remaining: plannedTotal - max(0, elapsed))
                Spacer(minLength: 12)
                phaseHeader(label: label, countdown: countdown)
                Spacer(minLength: 20)
                BreathingTrack(timeline: timeline, elapsed: elapsed, accent: accent, reduceMotion: reduceMotion)
                    .frame(height: 260)
                Spacer(minLength: 20)
                bottomBar(cycle: inLeadIn ? 0 : position.cycle + 1, progress: min(1, max(0, elapsed) / plannedTotal))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }

    /// A soft violet light that grows on the inhale and fades on the exhale.
    private func breathingLight(level: Double) -> some View {
        RadialGradient(
            colors: [accent.opacity(0.10 + 0.18 * level), Color(hex: "7C3AED").opacity(0.06 * level), .clear],
            center: .center, startRadius: 10, endRadius: reduceMotion ? 320 : 220 + 180 * level
        )
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    private func topBar(remaining: Double) -> some View {
        HStack {
            Button {
                voiceOverManager.stop()
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(Color.white.opacity(0.08), in: Circle())
                    .overlay(Circle().strokeBorder(Color.white.opacity(0.12), lineWidth: 1))
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(PressableCardStyle())
            .accessibilityLabel(languageManager.localized("breathing.session.close"))
            Spacer()
            Text(pattern.localizedTitle)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AudioPalette.secondaryText)
                .lineLimit(1)
            Spacer()
            Text(formatTime(remaining))
                .font(.system(size: 15, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(AudioPalette.secondaryText)
                .frame(width: 56, alignment: .trailing)
        }
        .padding(.top, 8)
    }

    private func phaseHeader(label: String, countdown: Int) -> some View {
        VStack(spacing: 10) {
            Text(label)
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
                .id(label)
                .transition(.asymmetric(insertion: .opacity.combined(with: .offset(y: 10)), removal: .opacity))
            Text("\(countdown)")
                .font(.system(size: 34, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(accent)
                .contentTransition(.numericText(countsDown: true))
        }
        .animation(.easeInOut(duration: 0.45), value: label)
        .animation(.easeOut(duration: 0.25), value: countdown)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.updatesFrequently)
    }

    private func bottomBar(cycle: Int, progress: Double) -> some View {
        VStack(spacing: 22) {
            HStack {
                Text(cycle > 0 ? String(format: languageManager.localized("breathing.v2.cycle"), cycle) : " ")
                Spacer()
                Text(pattern.rhythmLabel)
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(AudioPalette.secondaryText)
            .monospacedDigit()

            GeometryReader { proxy in
                Capsule().fill(Color.white.opacity(0.1))
                    .overlay(alignment: .leading) {
                        Capsule().fill(accent).frame(width: proxy.size.width * progress)
                    }
            }
            .frame(height: 4)

            Button(action: togglePause) {
                Image(systemName: isPaused ? "play.fill" : "pause.fill")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(AudioPalette.backgroundDeep)
                    .frame(width: 76, height: 76)
                    .background(accent, in: Circle())
                    .overlay(Circle().strokeBorder(.white.opacity(0.35), lineWidth: 0.5))
                    .shadow(color: accent.opacity(0.45), radius: 20)
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(PressableCardStyle())
            .accessibilityLabel(languageManager.localized(isPaused ? "breathing.session.resume" : "breathing.session.pause"))
        }
    }
}

// MARK: - End screen

struct BreathingSessionEndView: View {
    let pattern: BreathingPattern
    let breathedSeconds: Double
    let cycles: Int
    let onDone: () -> Void
    let onRestart: () -> Void

    @ObservedObject private var languageManager = LanguageManager.shared
    @State private var feeling: String?
    @State private var appear = false

    private let feelings: [(id: String, icon: String)] = [("better", "face.smiling"), ("same", "minus.circle"), ("worse", "cloud.rain")]

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            ZStack {
                Circle()
                    .fill(AudioPalette.accent.opacity(0.25))
                    .frame(width: 140, height: 140)
                    .blur(radius: 24)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 76, weight: .regular))
                    .foregroundStyle(.white, AudioPalette.accent)
                    .symbolEffect(.bounce, value: appear)
            }

            VStack(spacing: 8) {
                Text(languageManager.localized("breathing.completion.title"))
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                Text("\(pattern.localizedTitle) · \(minutesText) min · \(cycles) \(languageManager.localized("breathing.session.cycles"))")
                    .font(.system(size: 15))
                    .foregroundStyle(AudioPalette.secondaryText)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)

            VStack(spacing: 14) {
                Text(languageManager.localized("breathing.v2.feeling.title"))
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                HStack(spacing: 10) {
                    ForEach(feelings, id: \.id) { item in
                        let selected = feeling == item.id
                        Button {
                            HapticManager.light()
                            feeling = item.id
                        } label: {
                            VStack(spacing: 8) {
                                Image(systemName: item.icon).font(.system(size: 22, weight: .medium))
                                Text(languageManager.localized("breathing.v2.feeling.\(item.id)"))
                                    .font(.system(size: 13, weight: .medium))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                            }
                            .foregroundStyle(selected ? AudioPalette.accent : .white)
                            .frame(maxWidth: .infinity, minHeight: 84)
                            .background(selected ? AudioPalette.accent.opacity(0.16) : Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(selected ? AudioPalette.accent.opacity(0.6) : Color.white.opacity(0.1), lineWidth: 1))
                        }
                        .buttonStyle(PressableCardStyle())
                    }
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            VStack(spacing: 14) {
                Button {
                    HapticManager.light()
                    if let feeling {
                        AnalyticsManager.shared.track(event: "breathing_feedback", properties: ["exercise": pattern.name, "feeling": feeling])
                    }
                    onDone()
                } label: {
                    Text(languageManager.localized("breathing.v2.finish"))
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(AudioPalette.backgroundDeep)
                        .frame(maxWidth: .infinity, minHeight: 56)
                        .background(AudioPalette.accent, in: Capsule())
                }
                .buttonStyle(PressableCardStyle())

                Button {
                    HapticManager.light()
                    onRestart()
                } label: {
                    Label(languageManager.localized("breathing.v2.again"), systemImage: "arrow.counterclockwise")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .onAppear { appear = true }
    }

    private var minutesText: String {
        let minutes = breathedSeconds / 60
        return minutes < 1 ? String(format: "%.1f", minutes) : "\(Int(minutes.rounded()))"
    }
}

// MARK: - Completion Overlay (legacy, kept for compatibility)

struct BreathingCompletionOverlay: View {
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(Color.appTheme)

                Text(LanguageManager.shared.localizedString(for: "breathing.completion.title"))
                    .font(.faroSemiBold(28))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Button(action: {
                    HapticManager.light()
                    onDismiss()
                }) {
                    Text(LanguageManager.shared.localizedString(for: "common.continue"))
                        .font(.custom("Poppins-SemiBold", size: 18))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(colors: [Color.appTheme, Color.appThemeSecondary],
                                           startPoint: .leading, endPoint: .trailing)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 40)
                .padding(.top, 8)
            }
            .padding(40)
        }
    }
}

#Preview {
    BreathingDetailFlowView(pattern: .physiologicalSigh, duration: 60)
}
