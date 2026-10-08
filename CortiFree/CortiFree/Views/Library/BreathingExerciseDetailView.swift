//
//  BreathingExerciseDetailView.swift
//  CortiFree
//
//  Breathing exercise sheet: full-bleed artwork, title, one line of metadata,
//  three quiet actions, the duration and a floating start button. Everything
//  else waits behind « En savoir plus » so the screen invites a tap on start.
//

import SwiftUI

struct BreathingExerciseDetailView: View {
    let pattern: BreathingPattern
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var languageManager = LanguageManager.shared
    @ObservedObject private var preferences = BreathingPreferences.shared
    @ObservedObject private var voiceOverManager = VoiceOverManager.shared
    @ObservedObject private var library = SessionLibraryStore.shared
    @State private var selectedMinutes: Int
    @State private var detailsExpanded = false
    @State private var showsAmbiences = false
    @State private var showBreathingExercise = false

    private let heroHeight: CGFloat = 430

    init(pattern: BreathingPattern) {
        self.pattern = pattern
        _selectedMinutes = State(initialValue: pattern.defaultMinutes)
    }

    private func t(_ key: String) -> String { languageManager.localizedString(for: key) }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            GalaxyBackgroundView(intensity: 0.75)
                .ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    hero
                    VStack(alignment: .leading, spacing: 24) {
                        Text(pattern.localizedBenefit)
                            .font(.system(size: 19, weight: .regular, design: .rounded))
                            .foregroundStyle(.white.opacity(0.92))
                            .fixedSize(horizontal: false, vertical: true)
                        if pattern.requiresCaution {
                            Label(t("breathing.detail.caution"), systemImage: "exclamationmark.triangle.fill")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundStyle(Color(hex: "FFD36B"))
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(14)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color(hex: "FFD36B").opacity(0.10)))
                        }
                        actions
                        if pattern.durationChoices.count > 1 { durationPicker }
                        details
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    // Room for the floating start button.
                    .padding(.bottom, 120)
                }
            }
            .coordinateSpace(name: "breathingDetail")
            .scrollIndicators(.hidden)
            .ignoresSafeArea(edges: .top)

            topActions
        }
        .safeAreaInset(edge: .bottom, spacing: 0) { startButton }
        .sheet(isPresented: $showsAmbiences) {
            BreathingAmbiencePicker()
                .presentationDetents([.height(290)])
                .presentationDragIndicator(.visible)
                .presentationBackground(.ultraThinMaterial)
        }
        .fullScreenCover(isPresented: $showBreathingExercise) {
            BreathingDetailFlowView(pattern: pattern, duration: Double(selectedMinutes * 60)) {
                showBreathingExercise = false
                dismiss()
            }
        }
        .environment(\.colorScheme, .dark)
    }

    // MARK: Hero

    /// Artwork that stretches when pulled down, with the title on its fading lower edge.
    private var hero: some View {
        GeometryReader { proxy in
            let pull = max(proxy.frame(in: .named("breathingDetail")).minY, 0)
            BreathingArtwork(pattern: pattern)
                .frame(width: proxy.size.width, height: heroHeight + pull)
                .clipped()
                .offset(y: -pull)
                // Fade the artwork into the galaxy background instead of a solid colour,
                // so there is no visible seam under the hero.
                .mask(
                    LinearGradient(
                        stops: [.init(color: .black, location: 0), .init(color: .black, location: 0.55), .init(color: .clear, location: 1)],
                        startPoint: .top, endPoint: .bottom
                    )
                    .offset(y: -pull)
                )
                .overlay {
                    LinearGradient(colors: [.black.opacity(0.25), .clear], startPoint: .top, endPoint: .center)
                        .offset(y: -pull)
                }
        }
        .frame(height: heroHeight)
        .overlay(alignment: .bottomLeading) {
            VStack(alignment: .leading, spacing: 8) {
                Text(pattern.localizedTitle)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
                    .shadow(color: .black.opacity(0.35), radius: 12, y: 4)
                Text("\(selectedMinutes) min · \(pattern.rhythmLabel) · \(t("breathing.v2.type"))")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white.opacity(0.75))
                    .monospacedDigit()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 4)
        }
        .accessibilityElement(children: .combine)
    }

    /// Like, download and close, top right over the artwork.
    private var topActions: some View {
        let isFavorite = library.isFavorite(pattern)
        let isDownloaded = library.isDownloaded(pattern)
        return HStack(spacing: 0) {
            topButton(isFavorite ? "heart.fill" : "heart",
                      tint: isFavorite ? Color(hex: "F472B6") : .white,
                      label: t(isFavorite ? "library.v2.unfavorite" : "library.v2.favorite")) {
                library.toggleFavorite(pattern)
            }
            .sensoryFeedback(.selection, trigger: isFavorite)
            topButton(isDownloaded ? "checkmark.circle.fill" : "arrow.down.circle",
                      tint: isDownloaded ? AudioPalette.accent : .white,
                      label: t(isDownloaded ? "library.downloaded.remove" : "library.download")) {
                library.toggleDownload(pattern)
            }
            .sensoryFeedback(.success, trigger: isDownloaded)
            topButton("xmark", tint: .white, label: t("breathing.session.close")) { dismiss() }
        }
        .padding(.top, 14)
        .padding(.trailing, 10)
    }

    private func topButton(_ symbol: String, tint: Color, label: String, action: @escaping () -> Void) -> some View {
        Button {
            HapticManager.light()
            action()
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(tint)
                .contentTransition(.symbolEffect(.replace))
                .frame(width: 34, height: 34)
                .background(.ultraThinMaterial, in: Circle())
                .frame(width: 44, height: 44)
        }
        .buttonStyle(PressableCardStyle())
        .accessibilityLabel(label)
    }

    // MARK: Actions

    private var actions: some View {
        HStack(alignment: .top, spacing: 0) {
            BreathingRoundAction(
                title: preferences.ambience?.localizedTitle ?? t("breathing.v2.ambience"),
                icon: preferences.ambience?.symbol ?? "speaker.wave.2",
                isActive: preferences.ambience != nil
            ) { showsAmbiences = true }
            BreathingRoundAction(
                title: t("breathing.v2.voice"),
                icon: voiceOverManager.isEnabled ? "person.wave.2.fill" : "person.wave.2",
                isActive: voiceOverManager.isEnabled
            ) { voiceOverManager.isEnabled.toggle() }
            BreathingRoundAction(
                title: t("breathing.v2.haptics"),
                icon: preferences.hapticsEnabled ? "iphone.radiowaves.left.and.right" : "iphone.slash",
                isActive: preferences.hapticsEnabled
            ) { preferences.hapticsEnabled.toggle() }
        }
        .frame(maxWidth: .infinity)
        .sensoryFeedback(.selection, trigger: preferences.hapticsEnabled)
    }

    private var durationPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(t("breathing.v2.duration"))
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AudioPalette.secondaryText)
            Picker(t("breathing.v2.duration"), selection: $selectedMinutes) {
                ForEach(pattern.durationChoices.sorted(), id: \.self) { Text("\($0) min").tag($0) }
            }
            .pickerStyle(.segmented)
        }
    }

    // MARK: Details

    private var details: some View {
        VStack(alignment: .leading, spacing: 0) {
            Divider().overlay(Color.white.opacity(0.08))
            Button {
                withAnimation(.easeInOut(duration: 0.25)) { detailsExpanded.toggle() }
            } label: {
                HStack {
                    Text(t("breathing.v2.learn_more"))
                        .font(.system(size: 17, weight: .semibold))
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 13, weight: .semibold))
                        .rotationEffect(.degrees(detailsExpanded ? 180 : 0))
                }
                .foregroundStyle(.white)
                .padding(.vertical, 16)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(.isHeader)

            if detailsExpanded {
                VStack(alignment: .leading, spacing: 22) {
                    detailBlock(t("breathing.v2.when")) {
                        Text(pattern.localizedWhenToUse)
                            .font(.system(size: 15))
                            .foregroundStyle(AudioPalette.secondaryText)
                            .lineSpacing(4)
                    }
                    if !pattern.localizedScience.isEmpty {
                        detailBlock(t("breathing.v2.science")) {
                            Text(pattern.localizedScience)
                                .font(.system(size: 15))
                                .foregroundStyle(AudioPalette.secondaryText)
                                .lineSpacing(4)
                        }
                    }
                    detailBlock(t("breathing.v2.steps")) {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(Array(pattern.steps.enumerated()), id: \.offset) { index, step in
                                HStack(alignment: .center, spacing: 12) {
                                    Text("\(index + 1)")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(AudioPalette.accent)
                                        .frame(width: 24, height: 24)
                                        .overlay(Circle().strokeBorder(AudioPalette.accent.opacity(0.5), lineWidth: 1))
                                    Text(step.localizedLabel)
                                        .font(.system(size: 15))
                                        .foregroundStyle(.white.opacity(0.85))
                                    Spacer()
                                    Text(stepDuration(step.duration))
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundStyle(AudioPalette.secondaryText)
                                        .monospacedDigit()
                                }
                            }
                        }
                    }
                }
                .padding(.bottom, 16)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
            Divider().overlay(Color.white.opacity(0.08))
        }
    }

    private func detailBlock<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.system(size: 12, weight: .bold))
                .tracking(0.8)
                .foregroundStyle(AudioPalette.secondaryText)
            content()
        }
    }

    private func stepDuration(_ seconds: Double) -> String {
        seconds == seconds.rounded() ? "\(Int(seconds)) s" : String(format: "%.1f s", seconds)
    }

    // MARK: Start button

    /// The start button floats above the content, with the background fading in behind it.
    private var startButton: some View {
        Button {
            HapticManager.medium()
            showBreathingExercise = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "play.fill").font(.system(size: 16, weight: .semibold))
                Text(t("breathing.v2.start")).font(.system(size: 17, weight: .semibold))
            }
            .foregroundStyle(AudioPalette.backgroundDeep)
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(AudioPalette.accent, in: Capsule())
            .overlay(Capsule().strokeBorder(.white.opacity(0.35), lineWidth: 0.5))
            .shadow(color: AudioPalette.accent.opacity(0.4), radius: 18, y: 8)
        }
        .buttonStyle(PressableCardStyle())
        .padding(.horizontal, 20)
        .padding(.top, 28)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity)
        .background {
            LinearGradient(colors: [AudioPalette.background.opacity(0), AudioPalette.background.opacity(0.92)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
                .allowsHitTesting(false)
        }
    }
}

// MARK: - Ambience picker

/// Ambience under the exercise: a "None" tile, the 8 loops and the volume.
struct BreathingAmbiencePicker: View {
    @ObservedObject private var preferences = BreathingPreferences.shared
    @ObservedObject private var languageManager = LanguageManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(languageManager.localizedString(for: "breathing.v2.ambience"))
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    tile(title: languageManager.localizedString(for: "breathing.v2.none"), icon: "speaker.slash", selected: preferences.ambience == nil) {
                        preferences.ambience = nil
                    }
                    ForEach(AudioAmbience.allCases) { ambience in
                        tile(title: ambience.localizedTitle, icon: ambience.symbol, selected: preferences.ambience == ambience) {
                            preferences.ambience = ambience
                        }
                    }
                }
            }
            HStack(spacing: 12) {
                Image(systemName: "speaker.fill").foregroundStyle(AudioPalette.secondaryText)
                Slider(value: Binding(get: { preferences.ambienceVolume }, set: { preferences.ambienceVolume = $0 }), in: 0...1)
                    .tint(AudioPalette.accent)
                Image(systemName: "speaker.wave.3.fill").foregroundStyle(AudioPalette.secondaryText)
            }
            .disabled(preferences.ambience == nil)
            .opacity(preferences.ambience == nil ? 0.4 : 1)
        }
        .padding(20)
        .environment(\.colorScheme, .dark)
    }

    private func tile(title: String, icon: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button {
            HapticManager.light()
            action()
        } label: {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(selected ? AudioPalette.accent : .white)
            .frame(width: 82, height: 82)
            .background(selected ? AudioPalette.accent.opacity(0.16) : Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(selected ? AudioPalette.accent.opacity(0.6) : Color.white.opacity(0.1), lineWidth: 1))
        }
        .buttonStyle(PressableCardStyle())
    }
}

// MARK: - Benefit badge (used by the anti-stress detail screens)

struct BenefitBadge: View {
    let benefit: String
    let index: Int

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(Circle().fill(AudioPalette.accent))
            Text(benefit)
                .font(.faroSemiBold(14))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .glassCard(cornerRadius: 16)
    }
}
