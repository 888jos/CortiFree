//
//  LibraryView.swift
//  CortiFree
//
//  Created by Claude on 22/10/2025.
//  Updated with exact design specs
//

import SwiftUI

struct LibraryView: View {
    @StateObject private var viewModel = LibraryViewModel()
    @ObservedObject private var soundPlayer = SoundPlayer.shared

    @State private var selectedBreathingPattern: BreathingPattern?

    @State private var showAllBreathing = false
    @State private var showAllMeditation = false
    @State private var showAllSounds = false

    @State private var selectedMeditationSupport: MeditationSupport?

    @State private var showJournal = false

    var body: some View {
        ZStack {
            // Galaxy animated background
            GalaxyBackgroundView(intensity: 1.2)
                .ignoresSafeArea(edges: .top)

            VStack(spacing: 0) {
                // Fixed Library Header with icon navigation
                LibraryHeaderView { section in
                    handleLibrarySection(section)
                }
                .zIndex(10)

                // Scrollable content
                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            // Spacer to account for header overlap (icons extend down)
                            Spacer()
                                .frame(height: 50)

                            // Category Buttons Grid
                            categoryButtonsGrid
                                .padding(.top, 10)

                            // Sons Relaxants
                            sonsRelaxantsSection
                                .padding(.top, 48)

                            // Exercices de Respiration
                            exercicesRespirationSection
                                .padding(.top, 48)
                                .id("respiration")

                            // Exercices de Méditation
                            exercicesMeditationSection
                                .padding(.top, 48)
                                .id("meditation")

                            Spacer(minLength: soundPlayer.currentExercise != nil ? 180 : 100)
                        }
                        .padding(.horizontal, 24)
                    }
                    .onChange(of: viewModel.scrollToSection) { _, section in
                        if let section = section {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                proxy.scrollTo(section, anchor: .top)
                            }
                            // Reset after scrolling
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                                viewModel.scrollToSection = nil
                            }
                        }
                    }
                }
            }
        }
        .ignoresSafeArea(edges: .top)
        .sheet(item: $selectedBreathingPattern) { pattern in
            BreathingExerciseDetailView(pattern: pattern)
                .presentationBackground(.clear)
        }
        .sheet(item: $selectedMeditationSupport) { support in
            MeditationSupportView(support: support)
                .presentationBackground(.clear)
        }
        .sheet(isPresented: $showJournal) {
            JournalHomeView()
        }
    }

    // MARK: - Header Navigation

    private var headerNavigation: some View {
        HStack {
            Text("Librairie")
                .font(.custom("Poppins-Bold", size: 24))
                .foregroundColor(.white)

            Spacer()

            HStack(spacing: 16) {
                Button(action: {
                    // Navigate to ProfileView
                }) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }

                Button(action: {
                    // Navigate to SettingsView
                }) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }
            }
        }
    }

    // MARK: - Quick Navigation Icons

    private var quickNavigationIcons: some View {
        HStack(spacing: 20) {
            QuickNavIcon(
                icon: "wind",
                title: "Respiration",
                color: Color(hex: "F2D5FF")
            ) {
                // Navigate to Respiration section
            }

            QuickNavIcon(
                icon: "message.fill",
                title: "Psychology",
                color: Color(hex: "F2D5FF")
            ) {
                // Navigate to Psychology section
            }

            QuickNavIcon(
                icon: "figure.mind.and.body",
                title: "Meditation",
                color: Color(hex: "F2D5FF")
            ) {
                // Navigate to Meditation section
            }

            QuickNavIcon(
                icon: "book.fill",
                title: "Recherches",
                color: Color(hex: "F2D5FF")
            ) {
                // Navigate to Research section
            }
        }
    }

    // MARK: - Category Buttons Grid

    private var categoryButtonsGrid: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                CategoryButton(
                    title: "Apprendre",
                    backgroundImage: "button_apprendre",
                    strokeColor: Color(hex: "894208")
                ) {
                    // Navigate to Learning section
                }

                CategoryButton(
                    title: "Blog",
                    backgroundImage: "button_blog",
                    strokeColor: Color(hex: "27154D")
                ) {
                    // Navigate to Blog
                }
            }

            HStack(spacing: 16) {
                CategoryButton(
                    title: "Conseils",
                    backgroundImage: "button_conseil",
                    strokeColor: Color(hex: "842F6C")
                ) {
                    // Navigate to Tips
                }

                CategoryButton(
                    title: "Études",
                    backgroundImage: "button_etudes",
                    strokeColor: Color(hex: "155AAF")
                ) {
                    // Open PDF file
                    openPDF()
                }
            }
        }
    }

    // MARK: - Sons Relaxants Section

    private var sonsRelaxantsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Sons Relaxants")
                    .font(.custom("Poppins-SemiBold", size: 18))
                    .foregroundColor(.white)

                Text("Aide ton coeur à se réguler lors d'une situation stressante")
                    .font(.custom("Poppins-Regular", size: 12))
                    .foregroundColor(Color(hex: "B0B8D4"))
            }

            // Sound Options Grid (2x2 or more)
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    SoundItem(
                        icon: "cloud.rain.fill",
                        title: "Pluie",
                        isPlaying: soundPlayer.currentExercise?.id == "rain" && soundPlayer.isPlaying
                    ) {
                        playSound(id: "rain", title: "Pluie")
                    }

                    SoundItem(
                        icon: "water.waves",
                        title: "Ocean",
                        isPlaying: soundPlayer.currentExercise?.id == "ocean" && soundPlayer.isPlaying
                    ) {
                        playSound(id: "ocean", title: "Ocean")
                    }
                }

                HStack(spacing: 12) {
                    SoundItem(
                        icon: "flame.fill",
                        title: "Feu",
                        isPlaying: soundPlayer.currentExercise?.id == "fire" && soundPlayer.isPlaying
                    ) {
                        playSound(id: "fire", title: "Feu")
                    }

                    SoundItem(
                        icon: "waveform",
                        title: "Bruit Blanc",
                        isPlaying: soundPlayer.currentExercise?.id == "whitenoise" && soundPlayer.isPlaying
                    ) {
                        playSound(id: "whitenoise", title: "Bruit Blanc")
                    }
                }

                if showAllSounds {
                    HStack(spacing: 12) {
                        SoundItem(
                            icon: "sunrise.fill",
                            title: "Matinée",
                            isPlaying: soundPlayer.currentExercise?.id == "wind" && soundPlayer.isPlaying
                        ) {
                            playSound(id: "wind", title: "Matinée")
                        }

                        SoundItem(
                            icon: "leaf.fill",
                            title: "Forêt",
                            isPlaying: soundPlayer.currentExercise?.id == "forest" && soundPlayer.isPlaying
                        ) {
                            playSound(id: "forest", title: "Forêt")
                        }
                    }

                    HStack(spacing: 12) {
                        SoundItem(
                            icon: "drop.fill",
                            title: "Ruisseau",
                            isPlaying: soundPlayer.currentExercise?.id == "stream" && soundPlayer.isPlaying
                        ) {
                            playSound(id: "stream", title: "Ruisseau")
                        }

                        SoundItem(
                            icon: "moon.stars.fill",
                            title: "Nuit d'été",
                            isPlaying: soundPlayer.currentExercise?.id == "night" && soundPlayer.isPlaying
                        ) {
                            playSound(id: "night", title: "Nuit d'été")
                        }
                    }
                }
            }

            // Voir plus/moins button - Version compacte
            HStack {
                Spacer()
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showAllSounds.toggle()
                    }
                }) {
                    HStack(spacing: 6) {
                        Text(showAllSounds ? "Voir moins" : "Voir plus")
                            .font(.custom("Poppins-Medium", size: 13))
                            .foregroundColor(Color.appTheme)

                        Image(systemName: showAllSounds ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(Color.appTheme)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.appTheme.opacity(0.15))
                    )
                }
            }
            .padding(.top, 8)
        }
    }

    // MARK: - Exercices de Respiration Section

    private var exercicesRespirationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Exercices de Respiration Guidés")
                    .font(.custom("Poppins-SemiBold", size: 18))
                    .foregroundColor(.white)

                Text("Techniques de respiration pour gérer le stress")
                    .font(.custom("Poppins-Regular", size: 12))
                    .foregroundColor(Color(hex: "B0B8D4"))
            }

            // Breathing Options Grid (2x2 or more)
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    SoundItem(
                        icon: "wind",
                        title: "4-7-8",
                        isPlaying: false
                    ) {
                        startBreathingExercise(.fourSevenEight)
                    }

                    SoundItem(
                        icon: "square.dashed",
                        title: "Box Breathing",
                        isPlaying: false
                    ) {
                        startBreathingExercise(.boxBreathing)
                    }
                }

                HStack(spacing: 12) {
                    SoundItem(
                        icon: "heart.fill",
                        title: "Cohérence",
                        isPlaying: false
                    ) {
                        startBreathingExercise(.coherence)
                    }

                    SoundItem(
                        icon: "figure.mind.and.body",
                        title: "Deep Relax",
                        isPlaying: false
                    ) {
                        startBreathingExercise(.deepAbdominal)
                    }
                }

                if showAllBreathing {
                    HStack(spacing: 12) {
                        SoundItem(
                            icon: "bolt.fill",
                            title: "Energizing",
                            isPlaying: false
                        ) {
                            startBreathingExercise(.kapalabhati)
                        }

                        SoundItem(
                            icon: "moon.fill",
                            title: "Sommeil",
                            isPlaying: false
                        ) {
                            startBreathingExercise(.fourSevenEight)
                        }
                    }

                    HStack(spacing: 12) {
                        SoundItem(
                            icon: "sparkles",
                            title: "Clarté Mentale",
                            isPlaying: false
                        ) {
                            startBreathingExercise(.boxBreathing)
                        }

                        SoundItem(
                            icon: "sun.max.fill",
                            title: "Éveil",
                            isPlaying: false
                        ) {
                            startBreathingExercise(.bhastrika)
                        }
                    }
                }
            }

            // Voir plus/moins button - Version compacte
            HStack {
                Spacer()
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showAllBreathing.toggle()
                    }
                }) {
                    HStack(spacing: 6) {
                        Text(showAllBreathing ? "Voir moins" : "Voir plus")
                            .font(.custom("Poppins-Medium", size: 13))
                            .foregroundColor(Color.appTheme)

                        Image(systemName: showAllBreathing ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(Color.appTheme)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.appTheme.opacity(0.15))
                    )
                }
            }
            .padding(.top, 8)
        }
    }

    // MARK: - Exercices de Méditation Section

    private var exercicesMeditationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Exercices de Méditation Guidés")
                    .font(.custom("Poppins-SemiBold", size: 18))
                    .foregroundColor(.white)

                Text("Méditations guidées pour la relaxation profonde")
                    .font(.custom("Poppins-Regular", size: 12))
                    .foregroundColor(Color(hex: "B0B8D4"))
            }

            // Meditation Options Grid (2x2 or more)
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    SoundItem(
                        icon: "leaf.fill",
                        title: "Scan Corporel",
                        isPlaying: soundPlayer.currentExercise?.id == "body-scan" && soundPlayer.isPlaying
                    ) {
                        playMeditation(id: "body-scan", title: "Scan Corporel")
                    }

                    SoundItem(
                        icon: "heart.text.square.fill",
                        title: "Gratitude",
                        isPlaying: soundPlayer.currentExercise?.id == "gratitude" && soundPlayer.isPlaying
                    ) {
                        playMeditation(id: "gratitude", title: "Gratitude")
                    }
                }

                HStack(spacing: 12) {
                    SoundItem(
                        icon: "sunrise.fill",
                        title: "Pleine Conscience",
                        isPlaying: soundPlayer.currentExercise?.id == "mindfulness" && soundPlayer.isPlaying
                    ) {
                        playMeditation(id: "mindfulness", title: "Pleine Conscience")
                    }

                    SoundItem(
                        icon: "sparkles",
                        title: "Visualisation",
                        isPlaying: soundPlayer.currentExercise?.id == "visualization" && soundPlayer.isPlaying
                    ) {
                        playMeditation(id: "visualization", title: "Visualisation")
                    }
                }

                if showAllMeditation {
                    HStack(spacing: 12) {
                        SoundItem(
                            icon: "heart.fill",
                            title: "Auto-Compassion",
                            isPlaying: soundPlayer.currentExercise?.id == "compassion" && soundPlayer.isPlaying
                        ) {
                            playMeditation(id: "compassion", title: "Auto-Compassion")
                        }

                        SoundItem(
                            icon: "brain.head.profile",
                            title: "Clarté",
                            isPlaying: soundPlayer.currentExercise?.id == "clarity" && soundPlayer.isPlaying
                        ) {
                            playMeditation(id: "clarity", title: "Clarté")
                        }
                    }

                    HStack(spacing: 12) {
                        SoundItem(
                            icon: "figure.walk",
                            title: "Marche Méditative",
                            isPlaying: soundPlayer.currentExercise?.id == "walking" && soundPlayer.isPlaying
                        ) {
                            playMeditation(id: "walking", title: "Marche Méditative")
                        }

                        SoundItem(
                            icon: "star.fill",
                            title: "Ancrage",
                            isPlaying: soundPlayer.currentExercise?.id == "grounding" && soundPlayer.isPlaying
                        ) {
                            playMeditation(id: "grounding", title: "Ancrage")
                        }
                    }
                }
            }

            // Voir plus/moins button - Version compacte
            HStack {
                Spacer()
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showAllMeditation.toggle()
                    }
                }) {
                    HStack(spacing: 6) {
                        Text(showAllMeditation ? "Voir moins" : "Voir plus")
                            .font(.custom("Poppins-Medium", size: 13))
                            .foregroundColor(Color.appTheme)

                        Image(systemName: showAllMeditation ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(Color.appTheme)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.appTheme.opacity(0.15))
                    )
                }
            }
            .padding(.top, 8)
        }
    }

    // MARK: - Helper Functions

    private func playSound(id: String, title: String) {
        if let exercise = Exercise.sounds.first(where: { $0.id == id }) {
            viewModel.playExercise(exercise)
        }
    }

    private func playMeditation(id: String, title: String) {
        // Ouvrir le support de méditation au lieu de lancer directement le player
        if let support = MeditationSupport.support(for: id) {
            selectedMeditationSupport = support
        }
    }

    private func startBreathingExercise(_ pattern: BreathingPattern) {
        selectedBreathingPattern = pattern
    }

    private func handleLibrarySection(_ section: LibrarySection) {
        switch section {
        case .respiration:
            // Scroll to breathing section
            viewModel.scrollToSection = "respiration"
        case .meditation:
            // Scroll to meditation section
            viewModel.scrollToSection = "meditation"
        case .journal:
            // Open journal
            showJournal = true
        case .recherches:
            // Open PDF file
            openPDF()
        }
    }

    private func openPDF() {
        // First try from bundle (if added to Xcode project)
        if let pdfPath = Bundle.main.path(forResource: "Études CortiFree", ofType: "pdf") {
            let url = URL(fileURLWithPath: pdfPath)
            UIApplication.shared.open(url)
        } else {
            // Fallback: try from Resources folder directly
            let resourcesURL = Bundle.main.bundleURL.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("CortiFree/Resources/Études CortiFree.pdf")
            if FileManager.default.fileExists(atPath: resourcesURL.path) {
                UIApplication.shared.open(resourcesURL)
            } else {
                // Last fallback: try from Downloads
                let downloadsPath = "/Users/jos/Downloads/assets cortifree dev/Études CortiFree.pdf"
                if FileManager.default.fileExists(atPath: downloadsPath) {
                    let url = URL(fileURLWithPath: downloadsPath)
                    UIApplication.shared.open(url)
                } else {
                    print("❌ PDF file not found at any location")
                }
            }
        }
    }
}

// MARK: - Quick Nav Icon

struct QuickNavIcon: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticManager.light()
            action()
        }) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 30))
                    .foregroundColor(color)

                Text(title)
                    .font(.custom("Poppins-Regular", size: 12))
                    .foregroundColor(Color(hex: "E1AFF8"))
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Category Button

struct CategoryButton: View {
    let title: String
    let backgroundImage: String
    let strokeColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticManager.light()
            action()
        }) {
            ZStack {
                // Background image
                Image(backgroundImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: 56)
                    .clipped()

                // Dark overlay for better text readability
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.black.opacity(0.4))

                // Title
                Text(title)
                    .font(.custom("Poppins-Medium", size: 16))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(strokeColor, lineWidth: 2)
            )
        }
    }
}

// MARK: - Sound Item

struct SoundItem: View {
    let icon: String
    let title: String
    let isPlaying: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticManager.light()
            action()
        }) {
            HStack(spacing: 12) {
                // SF Symbol in circle (left)
                ZStack {
                    Circle()
                        .fill(Color(hex: "0E0530"))
                        .frame(width: 45, height: 45)

                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }

                // Title (right)
                Text(title)
                    .font(.custom("Poppins-Medium", size: 14))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Play/Pause indicator
                if isPlaying {
                    Image(systemName: "pause.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Color.appTheme)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isPlaying ? Color.white.opacity(0.1) : Color.white.opacity(0.05))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Breathing Exercise Item

struct BreathingExerciseItem: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            HapticManager.light()
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                    isPressed = false
                }
            }
            action()
        }) {
            VStack(spacing: 8) {
                // SF Symbol in circle
                ZStack {
                    Circle()
                        .fill(Color(hex: "0E0530"))
                        .frame(width: 45, height: 45)

                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }

                Text(title)
                    .font(.custom("Poppins-Medium", size: 13))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 90)
            .padding(.horizontal, 8)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: "49288C").opacity(0.4),
                                Color(hex: "2A2B5A").opacity(0.6)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.appTheme.opacity(0.3),
                                        Color.appThemeSecondary.opacity(0.3)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    LibraryView()
}
