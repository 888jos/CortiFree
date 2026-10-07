//
//  GuidedSessionDetailView.swift
//  CortiFree
//
//  Session page (album-like): hero artwork, info, play button. Plays through the shared
//  GuidedSessionPlayer and opens its own "Now Playing" cover (works inside sheets).
//

import SwiftUI

struct GuidedSessionDetailView: View {
    let session: GuidedSession
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var player = GuidedSessionPlayer.shared
    @ObservedObject private var languageManager = LanguageManager.shared
    @State private var showPlayer = false

    private func t(_ key: String) -> String { languageManager.localizedString(for: key) }

    private var isCurrent: Bool { player.currentSession?.id == session.id }

    var body: some View {
        ZStack(alignment: .top) {
            AudioPalette.backgroundGradient.ignoresSafeArea()

            SessionArtworkView(session: session, cornerRadius: 0, showsSymbol: false)
                .frame(height: 420)
                .blur(radius: 50)
                .opacity(0.5)
                .mask(LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom))
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    SessionArtworkView(session: session, cornerRadius: 28)
                        .frame(width: 250, height: 250)
                        .shadow(color: (session.artwork.colors.first ?? .black).opacity(0.5), radius: 28, y: 16)
                        .padding(.top, 64)

                    VStack(spacing: 8) {
                        Text(session.category.title.localized.uppercased())
                            .font(.system(size: 12, weight: .semibold))
                            .tracking(1.2)
                            .foregroundStyle(AudioPalette.accent)
                        Text(session.localizedTitle)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                        Text(session.localizedSubtitle)
                            .font(.system(size: 15))
                            .foregroundStyle(AudioPalette.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 24)

                    HStack(spacing: 10) {
                        infoPill(icon: "clock", text: session.durationLabel)
                        if let ambience = player.resolvedAmbience(for: session) {
                            infoPill(icon: ambience.symbol, text: ambience.localizedTitle)
                        }
                        if GuidedSessionProgressStore.isCompleted(session.id) {
                            infoPill(icon: "checkmark.seal.fill", text: t("audio.listened"))
                        }
                    }

                    Button {
                        HapticManager.success()
                        player.play(session)
                        showPlayer = true
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: isCurrent && player.isPlaying ? "waveform" : "play.fill")
                                .symbolEffect(.variableColor.iterative, isActive: isCurrent && player.isPlaying)
                            Text(playLabel)
                        }
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(AudioPalette.backgroundDeep)
                        .frame(maxWidth: .infinity)
                        .frame(height: 58)
                        .background(Capsule().fill(.white))
                        .shadow(color: AudioPalette.accent.opacity(0.45), radius: 18, y: 8)
                    }
                    .buttonStyle(PressableCardStyle())
                    .padding(.horizontal, 24)
                    .padding(.top, 6)

                    Text(t("audio.headphones_hint"))
                        .font(.system(size: 12))
                        .foregroundStyle(AudioPalette.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)

                    Spacer(minLength: 40)
                }
            }

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
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
        }
        .environment(\.colorScheme, .dark)
        .nowPlayingCover(isPresented: $showPlayer)
    }

    private var playLabel: String {
        if isCurrent && player.isPlaying { return t("audio.open_player") }
        if GuidedSessionProgressStore.resumePosition(for: session.id) > 10 { return t("library.audio.continue") }
        return t("audio.play")
    }

    private func infoPill(icon: String, text: String) -> some View {
        Label(text, systemImage: icon)
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .cfGlassCapsule()
    }
}

/// Starts a session on appear and shows the full player (used where a meditation used to
/// open step-by-step slides: routines, anti-stress flow).
struct GuidedSessionAutoPlayView: View {
    let session: GuidedSession?

    var body: some View {
        NowPlayingView()
            .onAppear {
                if let session { GuidedSessionPlayer.shared.play(session) }
            }
    }
}
