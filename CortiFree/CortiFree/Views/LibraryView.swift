//
//  LibraryView.swift
//  CortiFree
//
//  Library tab: search, quick start, "for you now", themes, every guided
//  meditation, breathing exercises and ambient sounds.
//  Themes and personal libraries are pushed pages; a session opens as a sheet.
//

import SwiftUI

struct LibraryView: View {
    @StateObject private var viewModel = LibraryViewModel()
    @ObservedObject private var soundPlayer = SoundPlayer.shared
    @ObservedObject private var player = GuidedSessionPlayer.shared
    @ObservedObject private var languageManager = LanguageManager.shared
    @ObservedObject private var library = SessionLibraryStore.shared

    @State private var query = ""
    @State private var durationFilter: DurationFilter = .all
    @State private var categoryFilter: AudioSessionCategory?
    @State private var shownMeditations = LibraryView.pageSize
    @State private var shownBreathing = 4

    @State private var path = NavigationPath()
    @State private var selectedSession: GuidedSession?
    @State private var selectedBreathing: BreathingPattern?
    @State private var runningBreathing: BreathingPattern?

    @State private var showSounds = false

    private static let pageSize = 6

    /// Quick-start goals (2 columns × 3 rows).
    private let quickStartCategories: [AudioSessionCategory] = [.stressSOS, .sleep, .anxiety, .workBreak, .morning, .focus]

    private func t(_ key: String) -> String { languageManager.localizedString(for: key) }

    private enum Route: Hashable {
        case theme(AudioSessionCategory)
        case library(SessionLibrary)
        case allThemes
    }

    var body: some View {
        NavigationStack(path: $path) {
            page
                .toolbar(.hidden, for: .navigationBar)
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .theme(let category):
                        LibrarySessionListPage(
                            title: category.title.localized,
                            subtitle: category.subtitle.localized,
                            emptyMessage: t("library.v2.no_results"),
                            sessions: { GuidedSessionCatalog.sessions(in: category) },
                            play: play
                        )
                    case .library(let item):
                        LibrarySessionListPage(
                            title: t(item.titleKey),
                            subtitle: nil,
                            emptyMessage: t(item.emptyKey),
                            sessions: { library.sessions(in: item) },
                            play: play
                        )
                    case .allThemes:
                        LibraryAllThemesPage { path.append(Route.theme($0)) }
                    }
                }
        }
        .tint(AudioPalette.accent)
        .environment(\.colorScheme, .dark)
    }

    private var page: some View {
        ZStack {
            GalaxyBackgroundView(intensity: 0.75)
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                content
                    .padding(.horizontal, LibraryMetrics.horizontalPadding)
                    .padding(.top, 8)
                    .padding(.bottom, (soundPlayer.currentExercise != nil || player.currentSession != nil) ? 200 : 130)
            }
            .scrollDismissesKeyboard(.immediately)
            .id(languageManager.refreshID)
        }
        .sheet(item: $selectedSession) { GuidedSessionDetailView(session: $0) }
        .sheet(item: $selectedBreathing) { BreathingExerciseDetailView(pattern: $0) }
        .fullScreenCover(item: $runningBreathing) { pattern in
            BreathingDetailFlowView(pattern: pattern, duration: TimeInterval(pattern.defaultMinutes * 60)) {
                runningBreathing = nil
            }
        }
        .fullScreenCover(isPresented: $showSounds) { SoundsListView() }
        .onChange(of: durationFilter) { _, _ in shownMeditations = Self.pageSize }
        .onChange(of: categoryFilter) { _, _ in shownMeditations = Self.pageSize }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 24) {
            header
            searchField
            if query.isEmpty {
                if let session = continueSession {
                    LibraryContinueCard(session: session) { play(session) }
                }
                quickStart
                LibrarySeparator()
                forYouNow
                LibrarySeparator()
                themes
                LibrarySeparator()
                meditations
                LibrarySeparator()
                breathing
                LibrarySeparator()
                sounds
            } else {
                meditations
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center, spacing: 8) {
            Text(t("library.v2.title"))
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Spacer(minLength: 8)
            LibraryCollectionButton(library: .recent, tint: .white) { path.append(Route.library(.recent)) }
            LibraryCollectionButton(library: .downloads, tint: AudioPalette.accent) { path.append(Route.library(.downloads)) }
            LibraryCollectionButton(library: .favorites, tint: Color(hex: "F472B6")) { path.append(Route.library(.favorites)) }
        }
    }

    private var searchField: some View {
        HStack {
            Image(systemName: "magnifyingglass")
            TextField("", text: $query, prompt: Text(t("library.v2.search")).foregroundStyle(AudioPalette.secondaryText))
                .foregroundStyle(.white)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            if !query.isEmpty {
                Button { query = "" } label: { Image(systemName: "xmark.circle.fill") }
                    .buttonStyle(.plain)
            }
        }
        .padding(13)
        .foregroundStyle(AudioPalette.secondaryText)
        .cfGlass(cornerRadius: 14)
    }

    // MARK: - Continue

    private var continueSession: GuidedSession? {
        GuidedSessionProgressStore.recentSessionIDs
            .compactMap(GuidedSessionCatalog.session(id:))
            .first { GuidedSessionProgressStore.resumePosition(for: $0.id) > 10 && $0.id != player.currentSession?.id }
    }

    // MARK: - Quick start

    private var quickStart: some View {
        VStack(alignment: .leading, spacing: 12) {
            LibrarySectionTitle(title: t("library.v2.quick_start"))
            // A fixed (non-lazy) grid: a LazyVGrid inside the ScrollView can keep a stale
            // estimated height and leave a large empty gap below it.
            Grid(horizontalSpacing: 10, verticalSpacing: 10) {
                ForEach(0..<(quickStartCategories.count + 1) / 2, id: \.self) { row in
                    GridRow {
                        ForEach(quickStartCategories[(row * 2)..<min(row * 2 + 2, quickStartCategories.count)]) { category in
                            QuickStartTile(category: category) { quickStart(category) }
                        }
                    }
                }
            }
        }
    }

    /// Plays the shortest session of the goal, one the user hasn't just heard if possible.
    private func quickStart(_ category: AudioSessionCategory) {
        let sessions = GuidedSessionCatalog.sessions(in: category).sorted { $0.durationMinutes < $1.durationMinutes }
        let lastPlayed = GuidedSessionProgressStore.recentSessionIDs.first
        guard let session = sessions.first(where: { $0.id != lastPlayed }) ?? sessions.first else { return }
        play(session)
    }

    // MARK: - For you now

    private var forYouNow: some View {
        let moment = TimeOfDayMoment.current
        let sessions = moment.categories
            .flatMap { GuidedSessionCatalog.sessions(in: $0) }
            .sorted { lhs, rhs in
                // Not-yet-completed sessions first, then shorter ones.
                let l = GuidedSessionProgressStore.isCompleted(lhs.id), r = GuidedSessionProgressStore.isCompleted(rhs.id)
                return l == r ? lhs.durationMinutes < rhs.durationMinutes : !l
            }
        return VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                LibrarySectionTitle(title: t("library.v2.for_you"))
                Text(t(moment.reasonKey))
                    .font(.system(size: 15))
                    .foregroundStyle(AudioPalette.secondaryText)
            }
            ForEach(sessions.prefix(3)) { session in row(session) }
        }
    }

    // MARK: - Themes

    private var themes: some View {
        VStack(alignment: .leading, spacing: 12) {
            LibrarySectionTitle(title: t("library.v2.themes"), actionTitle: t("library.v2.see_all")) {
                path.append(Route.allThemes)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 12) {
                    ForEach(AudioSessionCategory.allCases) { category in
                        LibraryThemeCard(category: category, count: GuidedSessionCatalog.sessions(in: category).count) {
                            path.append(Route.theme(category))
                        }
                    }
                }
                .padding(.trailing, LibraryMetrics.horizontalPadding)
            }
            .padding(.trailing, -LibraryMetrics.horizontalPadding)
        }
    }

    // MARK: - Meditations

    private enum DurationFilter: String, CaseIterable, Identifiable {
        case all, short, medium, long
        var id: String { rawValue }
        var titleKey: String { "library.v2.duration.\(rawValue)" }

        func matches(_ minutes: Int) -> Bool {
            switch self {
            case .all: return true
            case .short: return minutes <= 5
            case .medium: return (6...10).contains(minutes)
            case .long: return minutes > 10
            }
        }
    }

    private var hasActiveFilters: Bool { durationFilter != .all || categoryFilter != nil }

    private func filteredSessions(duration: DurationFilter? = nil, category: AudioSessionCategory?? = nil) -> [GuidedSession] {
        let duration = duration ?? durationFilter
        let category = category ?? categoryFilter
        let needle = query.trimmingCharacters(in: .whitespaces).folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
        return GuidedSessionCatalog.all.filter { session in
            guard duration.matches(session.durationMinutes) else { return false }
            if let category, session.category != category { return false }
            guard !needle.isEmpty else { return true }
            let haystack = [session.localizedTitle, session.localizedSubtitle, session.category.title.localized]
                .joined(separator: " ")
                .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
            return haystack.contains(needle)
        }
    }

    private var meditations: some View {
        let sessions = filteredSessions()
        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                LibrarySectionTitle(title: t(query.isEmpty && !hasActiveFilters ? "library.v2.meditations" : "library.v2.results"))
                if hasActiveFilters {
                    Button(t("library.v2.clear")) {
                        durationFilter = .all
                        categoryFilter = nil
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AudioPalette.accent)
                }
                Text(verbatim: "\(sessions.count)")
                    .font(.system(size: 15))
                    .foregroundStyle(AudioPalette.accent)
            }
            ScrollView(.horizontal, showsIndicators: false) { filters }
                .padding(.bottom, 4)
            if sessions.isEmpty {
                Text(t("library.v2.no_results"))
                    .font(.system(size: 15))
                    .foregroundStyle(AudioPalette.secondaryText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 28)
            } else {
                ForEach(sessions.prefix(shownMeditations)) { session in row(session) }
                if sessions.count > shownMeditations {
                    LibrarySeeMoreButton { withAnimation(.easeOut(duration: 0.25)) { shownMeditations += 10 } }
                }
            }
        }
    }

    private var filters: some View {
        HStack(spacing: 8) {
            Menu {
                ForEach(DurationFilter.allCases) { value in
                    Button {
                        durationFilter = value
                    } label: {
                        if durationFilter == value { Label(t(value.titleKey), systemImage: "checkmark") } else { Text(t(value.titleKey)) }
                        Text(verbatim: "\(filteredSessions(duration: value).count)")
                    }
                    .disabled(filteredSessions(duration: value).isEmpty && durationFilter != value)
                }
            } label: {
                filterChip(String(format: t("library.v2.filter.duration"), t(durationFilter.titleKey)))
            }
            Menu {
                Button {
                    categoryFilter = nil
                } label: {
                    if categoryFilter == nil { Label(t("library.v2.filter.all_themes"), systemImage: "checkmark") } else { Text(t("library.v2.filter.all_themes")) }
                }
                ForEach(AudioSessionCategory.allCases) { category in
                    Button {
                        categoryFilter = category
                    } label: {
                        if categoryFilter == category { Label(category.title.localized, systemImage: "checkmark") } else { Text(category.title.localized) }
                        Text(verbatim: "\(filteredSessions(category: .some(category)).count)")
                    }
                    .disabled(filteredSessions(category: .some(category)).isEmpty && categoryFilter != category)
                }
            } label: {
                filterChip(String(format: t("library.v2.filter.theme"), categoryFilter?.title.localized ?? t("library.v2.filter.all")))
            }
            Spacer(minLength: 0)
        }
    }

    private func filterChip(_ title: String) -> some View {
        HStack(spacing: 6) {
            Text(title).font(.system(size: 13, weight: .medium))
            Image(systemName: "chevron.down").font(.system(size: 11, weight: .semibold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .frame(height: 38)
        .cfGlass(cornerRadius: 12, interactive: true)
    }

    private func row(_ session: GuidedSession) -> some View {
        LibrarySessionRow(session: session, open: { selectedSession = session }, play: { play(session) })
    }

    // MARK: - Breathing

    private var breathing: some View {
        let exercises = BreathingPattern.allPatterns
        return VStack(alignment: .leading, spacing: 10) {
            LibrarySectionTitle(title: t("library.v2.breathing"), count: exercises.count)
            ForEach(exercises.prefix(shownBreathing)) { pattern in
                LibraryBreathingRow(pattern: pattern, open: { selectedBreathing = pattern }, start: { runningBreathing = pattern })
            }
            if exercises.count > shownBreathing {
                LibrarySeeMoreButton { withAnimation(.easeOut(duration: 0.25)) { shownBreathing = exercises.count } }
            }
        }
    }

    // MARK: - Sounds

    private var soundItems: [(exercise: Exercise, image: String)] {
        let images = ["rain": "sound_rain", "ocean": "sound_ocean", "fire": "sound_fire", "whitenoise": "sound_whitenoise",
                      "wind": "sound_morning", "forest": "sound_forest", "stream": "sound_stream", "night": "sound_night"]
        return viewModel.sounds.map { ($0, images[$0.id] ?? "sound_rain") }
    }

    private var sounds: some View {
        VStack(alignment: .leading, spacing: 12) {
            LibrarySectionTitle(title: t("library.v2.sounds"), actionTitle: t("library.v2.see_all")) { showSounds = true }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(soundItems, id: \.exercise.id) { item in
                        soundTile(item.exercise, image: item.image)
                    }
                }
                .padding(.trailing, LibraryMetrics.horizontalPadding)
            }
            .padding(.trailing, -LibraryMetrics.horizontalPadding)
        }
    }

    private func soundTile(_ exercise: Exercise, image: String) -> some View {
        let playing = soundPlayer.currentExercise?.id == exercise.id && soundPlayer.isPlaying
        return Button {
            HapticManager.light()
            viewModel.playExercise(exercise)
        } label: {
            ZStack(alignment: .bottomLeading) {
                LibraryImage(name: image)
                    .frame(width: 112, height: 112)
                LinearGradient(colors: [.clear, .black.opacity(0.7)], startPoint: .center, endPoint: .bottom)
                HStack(spacing: 6) {
                    Image(systemName: playing ? "pause.fill" : exercise.icon)
                        .font(.system(size: 11, weight: .bold))
                    Text(exercise.title)
                        .font(.system(size: 13, weight: .semibold))
                        .lineLimit(1)
                }
                .foregroundStyle(.white)
                .padding(10)
            }
            .frame(width: 112, height: 112)
            .clipShape(RoundedRectangle(cornerRadius: LibraryMetrics.tileRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: LibraryMetrics.tileRadius, style: .continuous)
                    .stroke(playing ? AudioPalette.accent : Color.white.opacity(0.12), lineWidth: playing ? 2 : 1)
            )
        }
        .buttonStyle(PressableCardStyle())
        .accessibilityLabel(exercise.title)
        .accessibilityAddTraits(playing ? .isSelected : [])
    }

    // MARK: - Actions

    private func play(_ session: GuidedSession) {
        viewModel.playSession(session)
    }
}

// MARK: - Time of day

/// Picks the themes suggested in « Pour toi maintenant ».
private enum TimeOfDayMoment {
    case morning, midday, evening, night

    static var current: TimeOfDayMoment {
        switch Calendar.current.component(.hour, from: Date()) {
        case 5..<11: return .morning
        case 11..<17: return .midday
        case 17..<22: return .evening
        default: return .night
        }
    }

    var categories: [AudioSessionCategory] {
        switch self {
        case .morning: return [.morning, .focus]
        case .midday: return [.workBreak, .stressSOS]
        case .evening: return [.bodyRelax, .anxiety, .selfCompassion]
        case .night: return [.sleep]
        }
    }

    var reasonKey: String {
        switch self {
        case .morning: return "library.v2.for_you.morning"
        case .midday: return "library.v2.for_you.midday"
        case .evening: return "library.v2.for_you.evening"
        case .night: return "library.v2.for_you.night"
        }
    }
}

#Preview {
    LibraryView()
}
