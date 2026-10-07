//
//  MeditationListView.swift
//  CortiFree
//
//  Created by Claude on 23/10/2025.
//  Full catalogue of guided audio sessions (opened from Home, tasks, assistant).
//

import SwiftUI

struct MeditationListView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var languageManager = LanguageManager.shared
    @ObservedObject private var player = GuidedSessionPlayer.shared

    /// Optional category to pre-select.
    var initialCategory: AudioSessionCategory? = nil

    @State private var selectedCategory: AudioSessionCategory?
    @State private var didApplyInitial = false
    @State private var showPlayer = false

    private let columns = [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]

    private var visibleCategories: [AudioSessionCategory] {
        if let selectedCategory { return [selectedCategory] }
        return AudioSessionCategory.allCases
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            AudioPalette.backgroundGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                header

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 28) {
                        filterChips

                        ForEach(visibleCategories) { category in
                            VStack(alignment: .leading, spacing: 14) {
                                LibrarySectionHeader(title: category.title.localized, subtitle: category.subtitle.localized)
                                    .padding(.horizontal, 20)
                                LazyVGrid(columns: columns, spacing: 20) {
                                    ForEach(GuidedSessionCatalog.sessions(in: category)) { session in
                                        SessionTile(session: session) { start(session) }
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                    }
                    .padding(.top, 8)
                    .padding(.bottom, player.currentSession != nil ? 110 : 40)
                }
                .id(languageManager.refreshID)
            }

            if player.currentSession != nil {
                SessionMiniPlayer(onOpen: { showPlayer = true })
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
            }
        }
        .environment(\.colorScheme, .dark)
        .nowPlayingCover(isPresented: $showPlayer)
        .onAppear {
            if !didApplyInitial {
                selectedCategory = initialCategory
                didApplyInitial = true
            }
        }
    }

    private func start(_ session: GuidedSession) {
        player.play(session)
        showPlayer = true
    }

    private var header: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .cfGlassCircle()
            }
            .buttonStyle(.plain)

            Spacer()

            Text(languageManager.localized("library.audio.meditations"))
                .font(.system(size: 19, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Spacer()

            Color.clear.frame(width: 40, height: 40)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                LibraryFilterChip(title: languageManager.localized("library.audio.filter.all"), isSelected: selectedCategory == nil) {
                    withAnimation(.snappy) { selectedCategory = nil }
                }
                ForEach(AudioSessionCategory.allCases) { category in
                    LibraryFilterChip(title: category.title.localized, icon: category.symbol, isSelected: selectedCategory == category) {
                        withAnimation(.snappy) { selectedCategory = category }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 2)
        }
    }
}

#Preview {
    MeditationListView()
}
