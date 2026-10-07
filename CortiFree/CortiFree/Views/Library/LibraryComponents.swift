//
//  LibraryComponents.swift
//  CortiFree
//
//  Building blocks of the Library tab: header buttons, quick-start tiles,
//  theme cards, session and breathing rows, and the pushed list pages.
//

import SwiftUI

// MARK: - Shared bits

enum LibraryMetrics {
    static let horizontalPadding: CGFloat = 20
    static let tileRadius: CGFloat = 18
    static let cardRadius: CGFloat = 22
    static let playSize: CGFloat = 36
}

func libraryText(_ key: String) -> String { LanguageManager.shared.localizedString(for: key) }

func librarySessionCount(_ count: Int) -> String {
    String(format: libraryText(count == 1 ? "library.v2.session_count_one" : "library.v2.session_count"), count)
}

extension AudioSessionCategory {
    /// Photo used for theme cards and quick-start tiles.
    var libraryImage: String {
        switch self {
        case .stressSOS: return "situation_stresse"
        case .workBreak: return "situation_submerge"
        case .sleep: return "situation_dormir"
        case .morning: return "situation_energie"
        case .bodyRelax: return "situation_tendu"
        case .anxiety: return "situation_anxiete"
        case .selfCompassion: return "situation_epuise"
        case .focus: return "situation_recentrer"
        }
    }

    /// Short label for the quick-start grid ("Stress", "Sommeil", …).
    var quickStartLabel: String { libraryText("library.v2.quick.\(rawValue)") }
}

struct LibrarySeparator: View {
    var body: some View {
        Rectangle()
            .fill(Color.white.opacity(0.08))
            .frame(height: 1)
    }
}

struct LibrarySectionTitle: View {
    let title: String
    var count: Int?
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Spacer()
            if let actionTitle, let action {
                Button(action: action) {
                    HStack(spacing: 4) {
                        Text(actionTitle)
                        Image(systemName: "chevron.right").font(.system(size: 12, weight: .semibold))
                    }
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
            } else if let count {
                Text(verbatim: "\(count)")
                    .font(.system(size: 15))
                    .foregroundStyle(AudioPalette.accent)
            }
        }
    }
}

/// Small glass image used as session artwork in rows.
struct LibraryImage: View {
    let name: String
    var body: some View {
        Color.clear
            .overlay { Image(name).resizable().scaledToFill() }
            .clipped()
    }
}

// MARK: - Header button

/// Square glass icon button of the Library header (recent, downloads, favourites).
struct LibraryCollectionButton: View {
    let library: SessionLibrary
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button {
            HapticManager.light()
            action()
        } label: {
            Image(systemName: library.symbol)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 44, height: 44)
                .cfGlass(cornerRadius: 14, interactive: true)
        }
        .buttonStyle(PressableCardStyle())
        .accessibilityLabel(libraryText(library.titleKey))
    }
}

// MARK: - Continue card (full width)

struct LibraryContinueCard: View {
    let session: GuidedSession
    let action: () -> Void

    private var fraction: Double {
        let total = TimeInterval(session.durationMinutes * 60)
        return min(1, GuidedSessionProgressStore.resumePosition(for: session.id) / max(1, total))
    }

    var body: some View {
        Button {
            HapticManager.light()
            action()
        } label: {
            HStack(spacing: 14) {
                LibraryImage(name: session.category.libraryImage)
                    .frame(width: 58, height: 58)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                VStack(alignment: .leading, spacing: 6) {
                    Text(libraryText("library.v2.continue").uppercased())
                        .font(.system(size: 11, weight: .bold))
                        .tracking(0.8)
                        .foregroundStyle(AudioPalette.accent)
                    Text(session.localizedTitle)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    ProgressView(value: fraction)
                        .tint(AudioPalette.accent)
                }
                Spacer(minLength: 0)
                Image(systemName: "play.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(AudioPalette.backgroundDeep)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(.white))
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .cfGlass(cornerRadius: LibraryMetrics.cardRadius, interactive: true)
        }
        .buttonStyle(PressableCardStyle())
    }
}

// MARK: - Quick start tile (thin rectangle, 2 columns)

struct QuickStartTile: View {
    let category: AudioSessionCategory
    let action: () -> Void

    var body: some View {
        Button {
            HapticManager.light()
            action()
        } label: {
            HStack(spacing: 12) {
                LibraryImage(name: category.libraryImage)
                    .frame(width: 46, height: 46)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                Text(category.quickStartLabel)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer(minLength: 0)
            }
            .padding(7)
            .frame(maxWidth: .infinity, minHeight: 60, alignment: .leading)
            .cfGlass(cornerRadius: LibraryMetrics.tileRadius, interactive: true)
        }
        .buttonStyle(PressableCardStyle())
        .accessibilityHint(libraryText("library.v2.quick_hint"))
    }
}

// MARK: - Theme card (portrait, horizontal row)

struct LibraryThemeCard: View {
    static let size = CGSize(width: 210, height: 290)

    let category: AudioSessionCategory
    let count: Int
    let action: () -> Void

    var body: some View {
        Button {
            HapticManager.light()
            action()
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                LibraryImage(name: category.libraryImage)
                    .frame(width: Self.size.width, height: 150)
                VStack(alignment: .leading, spacing: 6) {
                    Text(category.title.localized)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                    Text(category.subtitle.localized)
                        .font(.system(size: 13))
                        .foregroundStyle(AudioPalette.secondaryText)
                        .lineLimit(3)
                    Spacer(minLength: 0)
                    Text(librarySessionCount(count))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AudioPalette.accent)
                }
                .padding(14)
                .frame(width: Self.size.width, height: Self.size.height - 150, alignment: .topLeading)
            }
            .frame(width: Self.size.width, height: Self.size.height)
            .cfGlass(cornerRadius: LibraryMetrics.cardRadius)
            .clipShape(RoundedRectangle(cornerRadius: LibraryMetrics.cardRadius, style: .continuous))
        }
        .buttonStyle(PressableCardStyle())
    }
}

// MARK: - Session row

struct LibrarySessionRow: View {
    let session: GuidedSession
    let open: () -> Void
    let play: () -> Void
    @ObservedObject private var library = SessionLibraryStore.shared
    @ObservedObject private var player = GuidedSessionPlayer.shared

    var body: some View {
        let isFavorite = library.isFavorite(session)
        let isCurrent = player.currentSession?.id == session.id && player.isPlaying
        HStack(spacing: 12) {
            Button(action: open) {
                HStack(spacing: 12) {
                    SessionArtworkView(session: session, cornerRadius: 12)
                        .frame(width: 68, height: 56)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(session.localizedTitle)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        HStack(spacing: 6) {
                            if isCurrent { EqualizerBars(isAnimating: true) }
                            Text("\(session.durationLabel) · \(session.category.title.localized)")
                                .font(.system(size: 13))
                                .foregroundStyle(AudioPalette.secondaryText)
                                .lineLimit(1)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button {
                library.toggleFavorite(session)
            } label: {
                Image(systemName: isFavorite ? "heart.fill" : "heart")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(isFavorite ? Color(hex: "F472B6") : AudioPalette.secondaryText)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.plain)
            .sensoryFeedback(.selection, trigger: isFavorite)
            .accessibilityLabel(libraryText(isFavorite ? "library.v2.unfavorite" : "library.v2.favorite"))

            Button {
                HapticManager.light()
                play()
            } label: {
                Image(systemName: "play.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(AudioPalette.backgroundDeep)
                    .frame(width: LibraryMetrics.playSize, height: LibraryMetrics.playSize)
                    .background(Circle().fill(AudioPalette.accent))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(session.localizedTitle)
        }
        .padding(.vertical, 8)
        .overlay(alignment: .bottom) { LibrarySeparator() }
    }
}

// MARK: - Breathing row (roller-coaster preview)

struct LibraryBreathingRow: View {
    let pattern: BreathingPattern
    let open: () -> Void
    let start: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Button(action: open) {
                HStack(spacing: 14) {
                    BreathingPatternPreview(pattern: pattern)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 10)
                        .frame(width: 84, height: 58)
                        .background(Color.black.opacity(0.25), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Color.white.opacity(0.08), lineWidth: 1))
                    VStack(alignment: .leading, spacing: 4) {
                        Text(pattern.localizedTitle)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                        Text("\(pattern.rhythmLabel) · \(pattern.defaultMinutes) min")
                            .font(.system(size: 13))
                            .foregroundStyle(AudioPalette.secondaryText)
                            .monospacedDigit()
                    }
                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(PressableCardStyle())

            Button {
                HapticManager.light()
                start()
            } label: {
                Image(systemName: "play.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(AudioPalette.backgroundDeep)
                    .frame(width: LibraryMetrics.playSize, height: LibraryMetrics.playSize)
                    .background(Circle().fill(AudioPalette.accent))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(pattern.localizedTitle)
        }
        .padding(10)
        .cfGlass(cornerRadius: LibraryMetrics.tileRadius)
    }
}

// MARK: - "Voir plus"

struct LibrarySeeMoreButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(libraryText("library.v2.see_more"))
                Image(systemName: "chevron.down").font(.system(size: 12, weight: .semibold))
            }
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(AudioPalette.accent)
            .frame(maxWidth: .infinity, minHeight: 46)
            .cfGlassCapsule()
        }
        .buttonStyle(PressableCardStyle())
        .padding(.top, 4)
    }
}

// MARK: - Pushed list page (theme or personal library)

struct LibrarySessionListPage: View {
    let title: String
    let subtitle: String?
    let emptyMessage: String
    let sessions: () -> [GuidedSession]
    let play: (GuidedSession) -> Void
    @State private var selected: GuidedSession?
    @ObservedObject private var library = SessionLibraryStore.shared

    var body: some View {
        let items = sessions()
        ZStack {
            GalaxyBackgroundView(intensity: 0.75)
                .ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 8) {
                    if let subtitle {
                        Text(subtitle)
                            .font(.system(size: 15))
                            .foregroundStyle(AudioPalette.secondaryText)
                            .padding(.bottom, 8)
                    }
                    if items.isEmpty {
                        VStack(spacing: 10) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 28))
                                .foregroundStyle(AudioPalette.accent)
                            Text(emptyMessage)
                                .font(.system(size: 15))
                                .foregroundStyle(AudioPalette.secondaryText)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                        .padding(.horizontal, 20)
                        .cfGlass(cornerRadius: LibraryMetrics.cardRadius)
                    } else {
                        ForEach(items) { session in
                            LibrarySessionRow(session: session, open: { selected = session }, play: { play(session) })
                        }
                    }
                }
                .padding(.horizontal, LibraryMetrics.horizontalPadding)
                .padding(.top, 8)
                .padding(.bottom, 180)
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.large)
        .toolbar(.visible, for: .navigationBar)
        .toolbarBackground(.hidden, for: .navigationBar)
        .sheet(item: $selected) { GuidedSessionDetailView(session: $0) }
    }
}

/// Every theme as a 2-column grid, pushed from « Tout voir ».
struct LibraryAllThemesPage: View {
    let open: (AudioSessionCategory) -> Void

    var body: some View {
        ZStack {
            GalaxyBackgroundView(intensity: 0.75)
                .ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                    ForEach(AudioSessionCategory.allCases) { category in
                        Button { open(category) } label: {
                            VStack(alignment: .leading, spacing: 0) {
                                LibraryImage(name: category.libraryImage)
                                    .frame(height: 110)
                                    .frame(maxWidth: .infinity)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(category.title.localized)
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundStyle(.white)
                                        .lineLimit(2)
                                        .fixedSize(horizontal: false, vertical: true)
                                    Text(librarySessionCount(GuidedSessionCatalog.sessions(in: category).count))
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(AudioPalette.accent)
                                }
                                .padding(11)
                                .frame(maxWidth: .infinity, minHeight: 66, alignment: .topLeading)
                            }
                            .cfGlass(cornerRadius: LibraryMetrics.tileRadius)
                            .clipShape(RoundedRectangle(cornerRadius: LibraryMetrics.tileRadius, style: .continuous))
                        }
                        .buttonStyle(PressableCardStyle())
                    }
                }
                .padding(.horizontal, LibraryMetrics.horizontalPadding)
                .padding(.top, 8)
                .padding(.bottom, 180)
            }
        }
        .navigationTitle(libraryText("library.v2.themes"))
        .navigationBarTitleDisplayMode(.large)
        .toolbar(.visible, for: .navigationBar)
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}
