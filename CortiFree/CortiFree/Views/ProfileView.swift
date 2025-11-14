//
//  ProfileView.swift
//  CortiFree
//
//  Created by Claude on 22/10/2025.
//  Amélioré avec évaluation CortiFree compacte
//

import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @StateObject private var planetSettings = PlanetSettings.shared
    @StateObject private var progressionManager = ProgressionManager.shared
    @State private var showPlanetSettings = false
    @State private var showSettings = false
    @State private var showProgression = false
    @State private var showPotentialScores = false
    @State private var selectedTab: ProfileTab = .score

    enum ProfileTab {
        case score
        case habits
    }

    // Mock scores data - 5 domain scores
    private let domainScores: [Double] = [0.52, 0.38, 0.41, 0.35, 0.44] // Sérénité, Sommeil, Énergie, Focus, Équilibre
    private let potentialDomainScores: [Double] = [0.92, 0.78, 0.81, 0.75, 0.84]

    // Mock habits data - 8 habits
    private let habits: [(name: String, icon: String, progress: Double, color: Color)] = [
        ("Méditation", "brain.head.profile", 0.75, Color(hex: "9B59B6")),
        ("Respiration", "wind", 0.82, Color(hex: "1ABC9C")),
        ("Journal", "book.fill", 0.64, Color(hex: "E74C3C")),
        ("Sport", "figure.run", 0.58, Color(hex: "2ECC71")),
        ("Eau", "drop.fill", 0.88, Color(hex: "3498DB")),
        ("Nature", "leaf.fill", 0.45, Color(hex: "27AE60")),
        ("Sommeil", "moon.fill", 0.70, Color(hex: "E67E22")),
        ("Social", "person.2.fill", 0.52, Color(hex: "F39C12"))
    ]

    // Calculate global score (average of 5 domains)
    private var globalScore: Int {
        let scores = showPotentialScores ? potentialDomainScores : domainScores
        let average = scores.reduce(0, +) / Double(scores.count)
        return Int(round(average * 100))
    }

    // Full 6-domain array for radar chart (Global + 5 domains)
    private var radarScores: [Double] {
        let scores = showPotentialScores ? potentialDomainScores : domainScores
        let global = scores.reduce(0, +) / Double(scores.count)
        return [global] + scores
    }

    // Domain colors
    private let domainColors: [Color] = [
        Color(hex: "9B59B6"), // Sérénité - Dark Purple
        Color(hex: "E74C3C"), // Sommeil - Red
        Color(hex: "1ABC9C"), // Énergie - Teal
        Color(hex: "2ECC71"), // Focus - Green
        Color(hex: "3498DB")  // Équilibre - Blue
    ]

    private let domainIcons: [String] = [
        "leaf.fill",    // Sérénité
        "moon.fill",    // Sommeil
        "bolt.fill",    // Énergie
        "target",       // Focus
        "heart.fill"    // Équilibre
    ]

    private let domainNames: [String] = [
        "Sérénité",
        "Sommeil",
        "Énergie",
        "Focus",
        "Équilibre"
    ]

    var body: some View {
        ZStack {
            // Galaxy animated background
            GalaxyBackgroundView(intensity: 1.0)
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Header avec contenu du profil
                    profileHeader
                        .padding(.horizontal, 24)
                        .padding(.top, 60)

                    // Tab selector
                    tabSelector
                        .padding(.horizontal, 24)

                    // Content based on selected tab with smooth transition
                    ZStack {
                        if selectedTab == .score {
                            // CortiFree Score Section (Compact)
                            cortiFreeScoreSection
                                .padding(.horizontal, 24)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .leading).combined(with: .opacity),
                                    removal: .move(edge: .trailing).combined(with: .opacity)
                                ))
                        } else {
                            // Habits Section
                            habitsSection
                                .padding(.horizontal, 24)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)
                                ))
                        }
                    }
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selectedTab)

                    Spacer(minLength: 100)
                }
            }
        }
        .ignoresSafeArea(edges: .top)
        .ignoresSafeArea(.keyboard)
        .sheet(isPresented: $showPlanetSettings) {
            PlanetSettingsView()
        }
        .fullScreenCover(isPresented: $showSettings) {
            SettingsView()
        }
    }

    // MARK: - Profile Header

    private var profileHeader: some View {
        HStack(spacing: 16) {
            // Avatar with selected planet image
            Image(planetSettings.selectedPlanet.imageName)
                .resizable()
                .scaledToFill()
                .frame(width: 80, height: 80)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(planetSettings.selectedPlanet.haloColor.opacity(0.3), lineWidth: 2)
                )

            // User Info
            VStack(alignment: .leading, spacing: 6) {
                // Name with edit icon
                HStack(spacing: 8) {
                    Text("Gabriel")
                        .font(.custom("HankenGrotesk-Bold", size: 20))
                        .foregroundColor(.white)

                    Button(action: {
                        HapticManager.light()
                    }) {
                        Image(systemName: "pencil")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }

                // Level
                Text("\(progressionManager.currentLevel.name)")
                    .font(.custom("Poppins-Medium", size: 13))
                    .foregroundColor(planetSettings.selectedPlanet.haloColor)
            }

            Spacer()

            // Settings button
            Button(action: {
                HapticManager.light()
                showSettings = true
            }) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 44, height: 44)

                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }
            }
        }
    }

    // MARK: - Tab Selector

    private var tabSelector: some View {
        HStack(spacing: 2) {
            // Score CortiFree tab
            Button(action: {
                HapticManager.light()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    selectedTab = .score
                }
            }) {
                Text("Score CortiFree")
                    .font(.custom(selectedTab == .score ? "Poppins-SemiBold" : "Poppins-Regular", size: 12))
                    .foregroundColor(selectedTab == .score ? .black : .white.opacity(0.7))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(selectedTab == .score ? .white : Color.clear)
                    )
            }

            // Habitudes tab
            Button(action: {
                HapticManager.light()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    selectedTab = .habits
                }
            }) {
                Text("Habitudes")
                    .font(.custom(selectedTab == .habits ? "Poppins-SemiBold" : "Poppins-Regular", size: 12))
                    .foregroundColor(selectedTab == .habits ? .black : .white.opacity(0.7))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(selectedTab == .habits ? .white : Color.clear)
                    )
            }
        }
        .padding(2)
        .background(
            RoundedRectangle(cornerRadius: 7)
                .fill(Color.white.opacity(0.2))
        )
        .frame(maxWidth: 230)
    }

    // MARK: - CortiFree Score Section (Compact)

    private var cortiFreeScoreSection: some View {
        VStack(spacing: 20) {
            // Header with toggle
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Score CortiFree")
                        .font(.custom("HankenGrotesk-Bold", size: 20))
                        .foregroundColor(.white)

                    Text(showPotentialScores ? "Potentiel (J66)" : "Actuel")
                        .font(.custom("Poppins-Regular", size: 12))
                        .foregroundColor(.white.opacity(0.6))
                }

                Spacer()

                // Toggle button
                Button(action: {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        showPotentialScores.toggle()
                    }
                }) {
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.15))
                        )
                        .rotationEffect(.degrees(showPotentialScores ? 180 : 0))
                }
            }

            // Hexagon with scores around it
            ZStack {
                // Larger hexagon radar
                HexagonRadarChart(
                    progress: radarScores,
                    color: planetSettings.selectedPlanet.haloColor,
                    size: 256, // 160 * 1.6
                    showLabels: false
                )
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showPotentialScores)

                // Position the 6 scores around the hexagon (Global + 5 domains)

                // Global - Top (0°)
                SimpleDomainScore(
                    icon: "star.fill",
                    title: "Global",
                    value: globalScore,
                    color: Color(hex: "B794F6")
                )
                .offset(x: 0, y: -155)
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showPotentialScores)

                // Sérénité - Top right (60°)
                SimpleDomainScore(
                    icon: domainIcons[0],
                    title: domainNames[0],
                    value: showPotentialScores ? Int(potentialDomainScores[0] * 100) : Int(domainScores[0] * 100),
                    color: domainColors[0]
                )
                .offset(x: 145, y: -75)
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showPotentialScores)

                // Sommeil - Bottom right (120°)
                SimpleDomainScore(
                    icon: domainIcons[1],
                    title: domainNames[1],
                    value: showPotentialScores ? Int(potentialDomainScores[1] * 100) : Int(domainScores[1] * 100),
                    color: domainColors[1]
                )
                .offset(x: 145, y: 75)
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showPotentialScores)

                // Énergie - Bottom (180°)
                SimpleDomainScore(
                    icon: domainIcons[2],
                    title: domainNames[2],
                    value: showPotentialScores ? Int(potentialDomainScores[2] * 100) : Int(domainScores[2] * 100),
                    color: domainColors[2]
                )
                .offset(x: 0, y: 155)
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showPotentialScores)

                // Focus - Bottom left (240°)
                SimpleDomainScore(
                    icon: domainIcons[3],
                    title: domainNames[3],
                    value: showPotentialScores ? Int(potentialDomainScores[3] * 100) : Int(domainScores[3] * 100),
                    color: domainColors[3]
                )
                .offset(x: -145, y: 75)
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showPotentialScores)

                // Équilibre - Top left (300°)
                SimpleDomainScore(
                    icon: domainIcons[4],
                    title: domainNames[4],
                    value: showPotentialScores ? Int(potentialDomainScores[4] * 100) : Int(domainScores[4] * 100),
                    color: domainColors[4]
                )
                .offset(x: -145, y: -75)
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showPotentialScores)
            }
            .frame(height: 380)
        }
    }

    // MARK: - Habits Section

    private var habitsSection: some View {
        VStack(spacing: 20) {
            // Grid of vertical habit bars
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(Array(habits.enumerated()), id: \.offset) { index, habit in
                    VerticalHabitBar(
                        icon: habit.icon,
                        title: habit.name,
                        progress: habit.progress,
                        color: habit.color
                    )
                }
            }
        }
    }

}

// MARK: - Simple Domain Score Component (positioned around hexagon)

struct SimpleDomainScore: View {
    let icon: String
    let title: String
    let value: Int
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.custom("Poppins-Medium", size: 11))
                    .foregroundColor(.white.opacity(0.8))

                Text("\(value)")
                    .font(.custom("HankenGrotesk-Bold", size: 20))
                    .foregroundColor(.white)
            }
        }
    }
}

// MARK: - Vertical Habit Bar Component

struct VerticalHabitBar: View {
    let icon: String
    let title: String
    let progress: Double
    let color: Color

    private let barHeight: CGFloat = 180

    var body: some View {
        VStack(spacing: 8) {
            // Progress percentage
            Text("\(Int(progress * 100))")
                .font(.custom("HankenGrotesk-Bold", size: 16))
                .foregroundColor(.white)

            // Vertical bar
            ZStack(alignment: .bottom) {
                // Background bar
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 44, height: barHeight)

                // Progress fill
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        LinearGradient(
                            colors: [
                                color.opacity(0.8),
                                color
                            ],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(width: 44, height: barHeight * progress)

                // Icon at bottom of filled area
                VStack {
                    Spacer()
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.bottom, 8)
                }
                .frame(height: barHeight * progress)
            }

            // Title
            Text(title)
                .font(.custom("Poppins-Medium", size: 11))
                .foregroundColor(.white.opacity(0.8))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }
}

#Preview {
    ProfileView()
}
