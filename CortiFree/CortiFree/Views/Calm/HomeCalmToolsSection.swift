//
//  HomeCalmToolsSection.swift
//  CortiFree
//
//  Home: this morning's body stress (Apple Watch) and three quick calm tools —
//  the heart-rate calm check, the 60-second reset and « breathe before TikTok ».
//

import SwiftUI

struct HomeCalmToolsSection: View {
    @ObservedObject private var health = HealthKitService.shared
    @ObservedObject private var faceStore = FaceScanStore.shared
    @State private var signals: BodySignals?
    @State private var loaded = false
    @State private var showPulse = false
    @State private var showReset = false
    @State private var showPauseSetup = false
    @State private var showFaceScan = false
    /// « No Apple Watch » (asked at the first pulse measure, changed in Profile): no watch prompts.
    @AppStorage(AppleWatchPreference.storageKey) private var appleWatch = ""

    private func t(_ key: String) -> String { LanguageManager.shared.localizedString(for: key) }

    var body: some View {
        VStack(spacing: 12) {
            bodyStressCard
            faceCheckCard

            HStack(spacing: 10) {
                tile(icon: "heart.fill", title: t("calm.home.pulse"), subtitle: lastPulseSubtitle) { showPulse = true }
                tile(icon: "bolt.heart.fill", title: t("calm.home.reset"), subtitle: t("calm.home.reset.subtitle")) { showReset = true }
                tile(icon: "hand.raised.fill", title: t("calm.home.pause"), subtitle: t("calm.home.pause.subtitle")) { showPauseSetup = true }
            }
        }
        .padding(.horizontal, AppConstants.Layout.paddingLarge)
        .task { await refresh() }
        .fullScreenCover(isPresented: $showPulse) { PulseCheckView() }
        .fullScreenCover(isPresented: $showReset) { NervousResetView() }
        .sheet(isPresented: $showPauseSetup) { BreathePauseSetupView().presentationDetents([.large]) }
        .fullScreenCover(isPresented: $showFaceScan) { FaceScanView() }
    }

    private var lastPulseSubtitle: String {
        guard let last = PulseCheckRecord.last else { return t("calm.home.pulse.subtitle") }
        return "\(last.before) → \(last.after) bpm"
    }

    private func refresh() async {
        signals = await health.bodySignals()
        loaded = true
    }

    // MARK: Body stress

    @ViewBuilder
    private var bodyStressCard: some View {
        if let signals, let score = signals.score {
            HStack(spacing: 14) {
                ZStack {
                    Circle().stroke(Color.white.opacity(0.1), lineWidth: 6)
                    Circle()
                        .trim(from: 0, to: Double(score) / 100)
                        .stroke(color(for: signals.level), style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Text(verbatim: "\(score)")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
                .frame(width: 58, height: 58)
                VStack(alignment: .leading, spacing: 4) {
                    Text(t("calm.body.title").uppercased())
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(0.8)
                        .foregroundStyle(AudioPalette.accent)
                    Text(t("calm.body.level.\(signals.level.rawValue)"))
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                    Text(details(signals))
                        .font(.system(size: 12))
                        .foregroundStyle(AudioPalette.secondaryText)
                        .lineLimit(2)
                }
                Spacer(minLength: 0)
            }
            .padding(14)
            .cfGlass(cornerRadius: 20)
        } else if loaded, health.isAvailable, !health.bodySignalsRequested, appleWatch != AppleWatchPreference.no {
            Button {
                HapticManager.light()
                Task {
                    if await health.enableBodySignals() { await refresh() }
                }
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: "applewatch")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(AudioPalette.accent)
                        .frame(width: 44, height: 44)
                        .background(AudioPalette.accent.opacity(0.15), in: Circle())
                    VStack(alignment: .leading, spacing: 3) {
                        Text(t("calm.body.connect.title"))
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.leading)
                        Text(t("calm.body.connect.subtitle"))
                            .font(.system(size: 12))
                            .foregroundStyle(AudioPalette.secondaryText)
                            .multilineTextAlignment(.leading)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AudioPalette.secondaryText)
                }
                .padding(14)
                .cfGlass(cornerRadius: 20, interactive: true)
            }
            .buttonStyle(PressableCardStyle())
        }
    }

    private func details(_ signals: BodySignals) -> String {
        var parts: [String] = []
        if let change = signals.hrvChange { parts.append(String(format: t("calm.body.hrv"), "\(change >= 0 ? "+" : "")\(change)")) }
        if let rhr = signals.restingHR { parts.append(String(format: t("calm.body.rhr"), Int(rhr))) }
        if let sleep = signals.sleepHours { parts.append(String(format: t("calm.body.sleep"), String(format: "%.1f", sleep))) }
        return parts.joined(separator: " · ")
    }

    private func color(for level: BodySignals.Level) -> Color {
        switch level {
        case .calm: return Color(hex: "6FE3B4")
        case .balanced: return AudioPalette.accent
        case .elevated: return Color(hex: "FFB86B")
        case .high: return Color(hex: "FF6B6B")
        }
    }

    // MARK: Weekly face check

    private var faceCheckCard: some View {
        let due = faceStore.isDue
        let last = faceStore.currentCycleRecords.last
        return Button {
            HapticManager.light()
            showFaceScan = true
        } label: {
            HStack(spacing: 14) {
                Image(systemName: due ? "camera.viewfinder" : "checkmark.seal.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(due ? AudioPalette.backgroundDeep : AudioPalette.accent)
                    .frame(width: 44, height: 44)
                    .background(due ? AudioPalette.accent : AudioPalette.accent.opacity(0.15), in: Circle())
                VStack(alignment: .leading, spacing: 3) {
                    Text(String(format: t(due ? "calm.face.card.due" : "calm.face.card.done"), faceStore.currentSlot + 1))
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.leading)
                    Text(last.map { String(format: t("calm.face.card.last"), $0.result.restedScore) } ?? t("calm.face.card.subtitle"))
                        .font(.system(size: 12))
                        .foregroundStyle(AudioPalette.secondaryText)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AudioPalette.secondaryText)
            }
            .padding(14)
            .cfGlass(cornerRadius: 20, interactive: true)
        }
        .buttonStyle(PressableCardStyle())
    }

    // MARK: Tiles

    private func tile(icon: String, title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button {
            HapticManager.light()
            action()
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AudioPalette.accent)
                    .frame(width: 34, height: 34)
                    .background(AudioPalette.accent.opacity(0.15), in: Circle())
                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(AudioPalette.secondaryText)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            .padding(12)
            .frame(maxWidth: .infinity, minHeight: 128, alignment: .topLeading)
            .cfGlass(cornerRadius: 18, interactive: true)
        }
        .buttonStyle(PressableCardStyle())
    }
}
