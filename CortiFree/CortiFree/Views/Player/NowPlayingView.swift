//
//  NowPlayingView.swift
//  CortiFree
//
//  Spotify-style full-screen player for guided audio sessions.
//

import SwiftUI

struct NowPlayingView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var player = GuidedSessionPlayer.shared
    @ObservedObject private var clock = GuidedSessionPlayer.shared.clock
    @ObservedObject private var languageManager = LanguageManager.shared
    @ObservedObject private var library = SessionLibraryStore.shared

    @State private var dragOffset: CGFloat = 0
    @State private var scrubValue: Double?
    @State private var showScript = false
    @State private var showAmbienceSheet = false
    /// End-of-session rating, asked once per finished playback.
    @State private var showRating = false
    /// Survives the player being closed and reopened on the same finished playback.
    private static var promptedSessionID: String?

    private func t(_ key: String) -> String { languageManager.localizedString(for: key) }

    var body: some View {
        ZStack {
            background

            if let session = player.currentSession {
                VStack(spacing: 0) {
                    topBar(session)
                        .padding(.top, 8)

                    // Artwork, or the script in its place (like lyrics).
                    Group {
                        if showScript, player.script != nil {
                            scriptPanel
                        } else {
                            artwork(session)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.vertical, 20)

                    titleBlock(session)

                    Group {
                        if player.isPreparing {
                            preparingBlock
                        } else if case .failed(let message) = player.phase {
                            failedBlock(message, session: session)
                        } else {
                            scrubber
                        }
                    }
                    .padding(.top, 18)

                    transportControls
                        .padding(.top, 14)

                    secondaryControls(session)
                        .padding(.top, 18)
                        .padding(.bottom, 12)
                }
                .padding(.horizontal, 24)
            } else {
                emptyState
            }
        }
        .offset(y: dragOffset)
        .gesture(dismissDrag)
        .environment(\.colorScheme, .dark)
        .sheet(isPresented: $showAmbienceSheet) {
            AmbienceMixerSheet()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationBackground(.ultraThinMaterial)
        }
        .onChange(of: player.currentSession == nil) { _, isEmpty in
            if isEmpty { dismiss() }
        }
        .onChange(of: player.didFinish) { _, finished in
            if finished { askRatingIfNeeded() } else { Self.promptedSessionID = nil }
        }
        .onAppear { if player.didFinish { askRatingIfNeeded() } }
        .fullScreenCover(isPresented: $showRating) {
            if let session = player.currentSession {
                SessionEndView(
                    content: RatedContent(type: .meditation, id: session.id, title: session.localizedTitle),
                    title: t("session.end.meditation.title"),
                    summary: "\(session.localizedTitle) · \(session.durationLabel)",
                    durationSeconds: Int(player.duration),
                    secondaryAction: (t("breathing.v2.again"), "arrow.counterclockwise", {
                        showRating = false
                        player.play(session)
                    }),
                    onDone: {
                        showRating = false
                        dismiss()
                    }
                )
            }
        }
    }

    private func askRatingIfNeeded() {
        guard let session = player.currentSession, Self.promptedSessionID != session.id else { return }
        Self.promptedSessionID = session.id
        showRating = true
    }

    // MARK: - Background

    private var background: some View {
        ZStack {
            AudioPalette.backgroundGradient
            if let session = player.currentSession {
                SessionArtworkView(session: session, cornerRadius: 0, showsSymbol: false)
                    .blur(radius: 60)
                    .opacity(0.55)
                    .scaleEffect(1.3)
                LinearGradient(colors: [.black.opacity(0.15), AudioPalette.background.opacity(0.85), AudioPalette.background],
                               startPoint: .top, endPoint: .bottom)
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Top bar

    private func topBar(_ session: GuidedSession) -> some View {
        HStack {
            Button {
                HapticManager.light()
                dismiss()
            } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .cfGlassCircle()
            }
            .buttonStyle(.plain)
            .accessibilityLabel(t("audio.close_player"))

            VStack(alignment: .leading, spacing: 2) {
                Text(t("audio.now_playing").uppercased())
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1.2)
                    .foregroundStyle(AudioPalette.secondaryText)
                Text(session.category.title.localized)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
            }
            .padding(.leading, 6)

            Spacer(minLength: 8)

            favoriteButton(session)
            downloadButton(session)

            Menu {
                Button(role: .destructive) {
                    HapticManager.light()
                    player.stop()
                } label: {
                    Label(t("audio.stop_session"), systemImage: "stop.fill")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .cfGlassCircle()
            }
        }
    }

    private func favoriteButton(_ session: GuidedSession) -> some View {
        let isFavorite = library.isFavorite(session)
        return Button {
            HapticManager.light()
            library.toggleFavorite(session)
        } label: {
            Image(systemName: isFavorite ? "heart.fill" : "heart")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(isFavorite ? Color(hex: "F472B6") : .white)
                .contentTransition(.symbolEffect(.replace))
                .frame(width: 44, height: 44)
                .cfGlassCircle()
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isFavorite)
        .accessibilityLabel(t(isFavorite ? "library.v2.unfavorite" : "library.v2.favorite"))
    }

    private func downloadButton(_ session: GuidedSession) -> some View {
        let state = library.downloadState(session)
        return Button {
            HapticManager.light()
            library.toggleDownload(session)
        } label: {
            Group {
                if state == .downloading {
                    ProgressView().controlSize(.small).tint(.white)
                } else {
                    Image(systemName: state == .downloaded ? "checkmark.circle.fill" : "arrow.down.circle")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(state == .downloaded ? AudioPalette.accent : .white)
                        .contentTransition(.symbolEffect(.replace))
                }
            }
            .frame(width: 44, height: 44)
            .cfGlassCircle()
        }
        .buttonStyle(.plain)
        .disabled(state == .downloading)
        .accessibilityLabel(t(LibraryDownloadButton.labelKey(state)))
    }

    // MARK: - Artwork

    private func artwork(_ session: GuidedSession) -> some View {
        SessionArtworkView(session: session, cornerRadius: 28)
            .aspectRatio(1, contentMode: .fit)
            .frame(maxWidth: 380, maxHeight: 380)
            .overlay(alignment: .bottomLeading) {
                if player.didFinish {
                    Label(t("audio.completed"), systemImage: "checkmark.seal.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .cfGlassCapsule()
                        .padding(16)
                }
            }
            .shadow(color: (session.artwork.colors.first ?? .black).opacity(0.45), radius: 30, y: 18)
            .scaleEffect(player.isPlaying || player.isPreparing ? 1 : 0.9)
            .animation(.spring(response: 0.5, dampingFraction: 0.75), value: player.isPlaying)
    }

    // MARK: - Title

    private func titleBlock(_ session: GuidedSession) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(session.localizedTitle)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
            Text(session.localizedSubtitle)
                .font(.system(size: 15))
                .foregroundStyle(AudioPalette.secondaryText)
                .lineLimit(2)
            if !session.hasNarrationInCurrentLanguage {
                // No narration in the app language yet: the English version plays.
                Label(t("audio.script.english_narration"), systemImage: "globe")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AudioPalette.secondaryText)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().stroke(Color.white.opacity(0.3)))
                    .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Preparing / failed

    private var preparingBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                ProgressView()
                    .tint(AudioPalette.accent)
                Text(t("audio.preparing"))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                Spacer()
                Text("\(Int(clock.preparationProgress * 100))%")
                    .font(.system(size: 13, weight: .medium).monospacedDigit())
                    .foregroundStyle(AudioPalette.secondaryText)
            }
            ProgressView(value: clock.preparationProgress)
                .tint(AudioPalette.accent)
            Text(t("audio.preparing_hint"))
                .font(.system(size: 12))
                .foregroundStyle(AudioPalette.secondaryText)
        }
        .padding(16)
        .cfGlass(cornerRadius: 20)
    }

    private func failedBlock(_ message: String, session: GuidedSession) -> some View {
        VStack(spacing: 12) {
            Label(t("audio.error.unavailable"), systemImage: "exclamationmark.triangle.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
            Text(message)
                .font(.system(size: 12))
                .foregroundStyle(AudioPalette.secondaryText)
                .multilineTextAlignment(.center)
            Button(t("audio.retry")) {
                player.play(session)
            }
            .cfGlassButtonStyle()
            .tint(AudioPalette.accent)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .cfGlass(cornerRadius: 20)
    }

    // MARK: - Scrubber

    private var scrubber: some View {
        let total = max(1, player.displayDuration)
        let value = scrubValue ?? clock.currentTime
        return VStack(spacing: 8) {
            GeometryReader { geo in
                let fraction = CGFloat(min(1, max(0, value / total)))
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.18))
                        .frame(height: scrubValue == nil ? 5 : 8)
                    Capsule()
                        .fill(LinearGradient(colors: [AudioPalette.accent, .white], startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(5, geo.size.width * fraction), height: scrubValue == nil ? 5 : 8)
                    Circle()
                        .fill(.white)
                        .frame(width: scrubValue == nil ? 12 : 20, height: scrubValue == nil ? 12 : 20)
                        .shadow(color: .black.opacity(0.3), radius: 4)
                        .offset(x: geo.size.width * fraction - (scrubValue == nil ? 6 : 10))
                }
                .frame(height: 24)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { gesture in
                            let f = min(1, max(0, gesture.location.x / geo.size.width))
                            scrubValue = Double(f) * total
                        }
                        .onEnded { _ in
                            if let scrubValue { player.seek(to: scrubValue) }
                            HapticManager.light()
                            scrubValue = nil
                        }
                )
                .animation(.easeOut(duration: 0.15), value: scrubValue == nil)
            }
            .frame(height: 24)

            HStack {
                Text(PlayerFormat.time(value))
                Spacer()
                Text("-" + PlayerFormat.time(max(0, total - value)))
            }
            .font(.system(size: 12, weight: .medium).monospacedDigit())
            .foregroundStyle(AudioPalette.secondaryText)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(t("audio.position"))
        .accessibilityValue("\(PlayerFormat.time(clock.currentTime)) / \(PlayerFormat.time(total))")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: player.skip(by: 15)
            case .decrement: player.skip(by: -15)
            @unknown default: break
            }
        }
    }

    // MARK: - Transport

    private var transportControls: some View {
        HStack(spacing: 36) {
            Button {
                HapticManager.light()
                player.skip(by: -15)
            } label: {
                Image(systemName: "gobackward.15")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 60, height: 60)
            }
            .buttonStyle(.plain)
            .disabled(player.phase != .ready)
            .opacity(player.phase == .ready ? 1 : 0.4)
            .accessibilityLabel(t("audio.back_15"))

            Button {
                HapticManager.medium()
                player.togglePlayPause()
            } label: {
                ZStack {
                    Circle()
                        .fill(.white)
                        .frame(width: 84, height: 84)
                        .shadow(color: AudioPalette.accent.opacity(0.5), radius: 20, y: 8)
                    Image(systemName: playIcon)
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(AudioPalette.backgroundDeep)
                        .offset(x: playIcon == "play.fill" ? 3 : 0)
                        .contentTransition(.symbolEffect(.replace))
                }
            }
            .buttonStyle(PressableCardStyle())
            .accessibilityLabel(player.isPlaying ? t("audio.pause") : t("audio.play"))

            Button {
                HapticManager.light()
                player.skip(by: 15)
            } label: {
                Image(systemName: "goforward.15")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 60, height: 60)
            }
            .buttonStyle(.plain)
            .disabled(player.phase != .ready)
            .opacity(player.phase == .ready ? 1 : 0.4)
            .accessibilityLabel(t("audio.forward_15"))
        }
    }

    private var playIcon: String {
        if player.didFinish { return "arrow.counterclockwise" }
        return player.isPlaying ? "pause.fill" : "play.fill"
    }

    // MARK: - Secondary controls

    private func secondaryControls(_ session: GuidedSession) -> some View {
        HStack(spacing: 12) {
            Menu {
                Picker(t("audio.sleep_timer"), selection: Binding(
                    get: { player.sleepTimer },
                    set: { player.setSleepTimer($0) }
                )) {
                    ForEach(SleepTimerOption.allOptions) { option in
                        Text(option.label).tag(option)
                    }
                }
            } label: {
                controlChip(
                    icon: player.sleepTimer == .off ? "moon.zzz" : "moon.zzz.fill",
                    title: sleepTimerTitle,
                    highlighted: player.sleepTimer != .off
                )
            }

            Button {
                HapticManager.light()
                showAmbienceSheet = true
            } label: {
                controlChip(
                    icon: player.ambience?.symbol ?? "speaker.wave.2",
                    title: player.ambience?.localizedTitle ?? t("audio.ambience"),
                    highlighted: player.ambience != nil
                )
            }
            .buttonStyle(.plain)


            if player.script != nil {
                Button {
                    HapticManager.light()
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { showScript.toggle() }
                } label: {
                    controlChip(icon: "text.quote", title: t("audio.script"), highlighted: showScript)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var sleepTimerTitle: String {
        switch player.sleepTimer {
        case .off: return t("audio.sleep_timer")
        case .endOfSession: return SleepTimerOption.endOfSession.label
        case .minutes:
            if let remaining = player.sleepTimerRemaining { return PlayerFormat.time(remaining) }
            return player.sleepTimer.label
        }
    }

    private func controlChip(icon: String, title: String, highlighted: Bool) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(highlighted ? AudioPalette.accent : .white)
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white.opacity(0.85))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 64)
        .cfGlass(cornerRadius: 18, interactive: true)
    }

    // MARK: - Script

    @ViewBuilder
    private var scriptPanel: some View {
        if let script = player.script {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    if script.language == "en", languageManager.currentLanguage != .english {
                        Text(t("audio.script.english_narration"))
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(AudioPalette.secondaryText)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().stroke(Color.white.opacity(0.3)))
                    }
                    ForEach(Array(script.displayParagraphs.enumerated()), id: \.offset) { _, paragraph in
                        Text(paragraph)
                            .font(.system(size: 19, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.88))
                            .lineSpacing(5)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(20)
            }
            .cfGlass(cornerRadius: 28)
            .transition(.opacity.combined(with: .scale(scale: 0.96)))
        }
    }

    // MARK: - Empty

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "waveform")
                .font(.system(size: 40))
                .foregroundStyle(AudioPalette.accent)
            Button(t("audio.done")) { dismiss() }
                .cfGlassButtonStyle()
        }
    }

    // MARK: - Swipe down to dismiss

    private var dismissDrag: some Gesture {
        DragGesture(minimumDistance: 20, coordinateSpace: .global)
            .onChanged { value in
                guard scrubValue == nil, value.translation.height > 0,
                      abs(value.translation.height) > abs(value.translation.width) else { return }
                dragOffset = value.translation.height
            }
            .onEnded { value in
                if dragOffset > 140 || value.predictedEndTranslation.height > 400 {
                    dismiss()
                } else {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { dragOffset = 0 }
                }
            }
    }
}

// MARK: - Ambience mixer

struct AmbienceMixerSheet: View {
    @ObservedObject private var player = GuidedSessionPlayer.shared
    @ObservedObject private var languageManager = LanguageManager.shared
    @Environment(\.dismiss) private var dismiss

    private func t(_ key: String) -> String { languageManager.localizedString(for: key) }

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text(t("audio.ambience"))
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.top, 24)

                LazyVGrid(columns: columns, spacing: 12) {
                    ambienceTile(nil)
                    ForEach(AudioAmbience.allCases) { ambience in
                        ambienceTile(ambience)
                    }
                }

                VStack(alignment: .leading, spacing: 16) {
                    volumeRow(title: t("audio.ambience_volume"), icon: "leaf.fill", value: $player.ambienceVolume)
                        .disabled(player.ambience == nil)
                        .opacity(player.ambience == nil ? 0.4 : 1)
                    volumeRow(title: t("audio.voice_volume"), icon: "person.wave.2.fill", value: $player.voiceVolume)
                }
                .padding(18)
                .cfGlass(cornerRadius: 22)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
        }
        .environment(\.colorScheme, .dark)
    }

    private func ambienceTile(_ ambience: AudioAmbience?) -> some View {
        let selected = player.ambience == ambience
        return Button {
            HapticManager.light()
            player.setAmbience(ambience)
        } label: {
            VStack(spacing: 8) {
                Image(systemName: ambience?.symbol ?? "speaker.slash.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(selected ? AudioPalette.accent : .white)
                Text(ambience?.localizedTitle ?? t("audio.ambience.none"))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 78)
            .cfGlass(cornerRadius: 18, interactive: true)
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(selected ? AudioPalette.accent : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private func volumeRow(title: String, icon: String, value: Binding<Float>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.85))
            HStack(spacing: 10) {
                Image(systemName: "speaker.fill").font(.system(size: 12)).foregroundStyle(.white.opacity(0.5))
                Slider(value: value, in: 0...1)
                    .tint(AudioPalette.accent)
                Image(systemName: "speaker.wave.3.fill").font(.system(size: 12)).foregroundStyle(.white.opacity(0.5))
            }
        }
    }
}

// MARK: - Presentation helper

extension View {
    /// Local full-screen "Now Playing" cover, for views that are themselves presented modally
    /// (the global one in ContentView cannot present above an open sheet).
    func nowPlayingCover(isPresented: Binding<Bool>) -> some View {
        fullScreenCover(isPresented: isPresented) {
            NowPlayingView()
                .presentationBackground(.clear)
        }
    }
}
