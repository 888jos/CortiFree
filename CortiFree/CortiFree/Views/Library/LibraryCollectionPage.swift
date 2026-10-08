//
//  LibraryCollectionPage.swift
//  CortiFree
//
//  Library > Downloads or Favorites: meditations, breathing exercises and
//  (for downloads) sounds, grouped by kind. Pushed from the Library header.
//

import SwiftUI

struct LibraryCollectionPage: View {
    let collection: SessionLibrary
    let play: (GuidedSession) -> Void
    @ObservedObject private var library = SessionLibraryStore.shared
    @ObservedObject private var soundPlayer = SoundPlayer.shared
    @State private var selectedBreathing: BreathingPattern?
    @State private var runningBreathing: BreathingPattern?

    var body: some View {
        let isDownloads = collection == .downloads
        let sessions = library.sessions(in: collection)
        let breathing = isDownloads ? library.downloadedBreathing : library.favoriteBreathing
        let sounds = isDownloads ? library.downloadedSounds : []
        ZStack {
            GalaxyBackgroundView(intensity: 0.75)
                .ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    if sessions.isEmpty && breathing.isEmpty && sounds.isEmpty && library.preparingIDs.isEmpty {
                        emptyState
                    } else {
                        if isDownloads {
                            Text(libraryText("library.downloads.subtitle"))
                                .font(.system(size: 15))
                                .foregroundStyle(AudioPalette.secondaryText)
                        }
                        if !sessions.isEmpty {
                            section("library.v2.meditations", count: sessions.count) {
                                ForEach(sessions) { session in
                                    LibrarySessionRow(session: session, open: { play(session) }, play: { play(session) })
                                        .contextMenu { if isDownloads { removeButton { library.toggleDownload(session) } } }
                                }
                            }
                        }
                        if !breathing.isEmpty {
                            section("library.v2.breathing", count: breathing.count) {
                                ForEach(breathing) { pattern in
                                    LibraryBreathingRow(pattern: pattern, open: { selectedBreathing = pattern }, start: { runningBreathing = pattern })
                                        .contextMenu {
                                            if isDownloads {
                                                removeButton { library.toggleDownload(pattern) }
                                            } else {
                                                Button(role: .destructive) { library.toggleFavorite(pattern) } label: {
                                                    Label(libraryText("library.v2.unfavorite"), systemImage: "heart.slash")
                                                }
                                            }
                                        }
                                }
                            }
                        }
                        if !sounds.isEmpty {
                            section("library.v2.sounds", count: sounds.count) {
                                ForEach(sounds) { sound in soundRow(sound) }
                            }
                        }
                    }
                }
                .padding(.horizontal, LibraryMetrics.horizontalPadding)
                .padding(.top, 8)
                .padding(.bottom, 180)
            }
        }
        .navigationTitle(libraryText(collection.titleKey))
        .navigationBarTitleDisplayMode(.large)
        .toolbar(.visible, for: .navigationBar)
        .toolbarBackground(.hidden, for: .navigationBar)
        .sheet(item: $selectedBreathing) { BreathingExerciseDetailView(pattern: $0) }
        .fullScreenCover(item: $runningBreathing) { pattern in
            BreathingDetailFlowView(pattern: pattern, duration: TimeInterval(pattern.defaultMinutes * 60)) {
                runningBreathing = nil
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: collection == .downloads ? "arrow.down.circle" : "heart")
                .font(.system(size: 30))
                .foregroundStyle(AudioPalette.accent)
            Text(libraryText(collection.emptyKey))
                .font(.system(size: 15))
                .foregroundStyle(AudioPalette.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .padding(.horizontal, 20)
        .cfGlass(cornerRadius: LibraryMetrics.cardRadius)
    }

    private func removeButton(_ action: @escaping () -> Void) -> some View {
        Button(role: .destructive, action: action) {
            Label(libraryText("library.downloaded.remove"), systemImage: "trash")
        }
    }

    private func section<Content: View>(_ titleKey: String, count: Int, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            LibrarySectionTitle(title: libraryText(titleKey), count: count)
            content()
        }
    }

    private func soundRow(_ sound: Exercise) -> some View {
        let playing = soundPlayer.currentExercise?.id == sound.id && soundPlayer.isPlaying
        return HStack(spacing: 10) {
            Button {
                HapticManager.light()
                soundPlayer.play(exercise: sound)
            } label: {
                HStack(spacing: 14) {
                    LibraryImage(name: sound.soundImageName)
                        .frame(width: 60, height: 56)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    VStack(alignment: .leading, spacing: 4) {
                        Text(sound.title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                        HStack(spacing: 6) {
                            if playing { EqualizerBars(isAnimating: true) }
                            Text(libraryText("library.downloads.sound_loop"))
                                .font(.system(size: 13))
                                .foregroundStyle(AudioPalette.secondaryText)
                        }
                    }
                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            LibraryDownloadButton(state: .downloaded) { library.toggleDownload(sound) }

            Button {
                HapticManager.light()
                soundPlayer.play(exercise: sound)
            } label: {
                Image(systemName: playing ? "pause.fill" : "play.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(AudioPalette.backgroundDeep)
                    .frame(width: LibraryMetrics.playSize, height: LibraryMetrics.playSize)
                    .background(Circle().fill(AudioPalette.accent))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(sound.title)
        }
        .padding(.vertical, 8)
        .overlay(alignment: .bottom) { LibrarySeparator() }
    }
}
