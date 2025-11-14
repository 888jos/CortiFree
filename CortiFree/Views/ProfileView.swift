//
//  ProfileView.swift
//  CortiFree
//
//  Created by Claude on 22/10/2025.
//  Updated with exact design specs
//

import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @StateObject private var planetSettings = PlanetSettings.shared
    @StateObject private var progressionManager = ProgressionManager.shared
    @State private var showPlanetSettings = false
    @State private var showSettings = false
    @State private var showProgression = false
    @State private var selectedPeriod: StatsPeriod = .sevenDays

    enum StatsPeriod: String, CaseIterable {
        case sevenDays = "7j"
        case thirtyDays = "30j"
        case ninetyDays = "90j"

        var days: Int {
            switch self {
            case .sevenDays: return 7
            case .thirtyDays: return 30
            case .ninetyDays: return 90
            }
        }

        // Returns (interval in days, number of points)
        var chartConfig: (interval: Int, pointCount: Int) {
            switch self {
            case .sevenDays: return (1, 7)      // 1 point per day, 7 points total
            case .thirtyDays: return (5, 7)     // 1 point every 5 days, 7 points total
            case .ninetyDays: return (15, 7)    // 1 point every 15 days, 7 points total
            }
        }
    }

    var body: some View {
        ZStack {
            // Galaxy animated background
            GalaxyBackgroundView(intensity: 1.0)
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Header avec contenu du profil uniquement (sans image)
                    profileHeader
                        .padding(.horizontal, 24)
                        .padding(.top, 60)

                    // Stats Section
                    statsSection
                        .padding(.top, 24)
                        .padding(.horizontal, 24)

                    // Achievement Section
                    achievementSection
                        .padding(.top, 20)
                        .padding(.horizontal, 24)

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
            // Avatar with selected planet image (122px = 94 * 1.3) - LEFT
            Image(planetSettings.selectedPlanet.imageName)
                .resizable()
                .scaledToFill()
                .frame(width: 122, height: 122)
                .clipShape(Circle())

            // User Info - CENTER
            VStack(alignment: .leading, spacing: 8) {
                // Name with edit icon
                HStack(spacing: 8) {
                    Text("Gabriel")
                        .font(.custom("Poppins-Medium", size: 16))
                        .foregroundColor(.white)

                    Button(action: {
                        // Edit profile
                        HapticManager.light()
                    }) {
                        Image(systemName: "pencil")
                            .font(.system(size: 10))
                            .foregroundColor(.white)
                    }
                }

                // Level badge
                HStack(spacing: 4) {
                    Text("Niveau \(viewModel.user?.level ?? 1)")
                        .font(.custom("Poppins-Regular", size: 12))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .frame(width: 150, height: 30)
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color(hex: "130C57").opacity(0.8))
                )

                // Stress label
                Text("Stress initial")
                    .font(.custom("Poppins-Regular", size: 12))
                    .foregroundColor(.white)
            }

            Spacer()

            // Settings button - RIGHT
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
                        .foregroundColor(Color.appTheme)
                }
            }
        }
        .frame(maxWidth: 332)
    }

    // MARK: - Stats Section

    private var statsSection: some View {
        VStack(spacing: 16) {
            // Section Header (outside the card, centered)
            Text("Accomplissement des tâches")
                .font(.custom("Poppins-SemiBold", size: 20))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .center)

            // Period selector (outside the card, centered)
            HStack(spacing: 0) {
                ForEach(Array(StatsPeriod.allCases.enumerated()), id: \.element) { index, period in
                    Button(action: {
                        HapticManager.light()
                        withAnimation(.spring(response: 0.3)) {
                            selectedPeriod = period
                        }
                    }) {
                        Text(period.rawValue)
                            .font(.custom("Poppins-Medium", size: 14))
                            .foregroundColor(selectedPeriod == period ? .white : .white.opacity(0.6))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(
                                Group {
                                    if selectedPeriod == period {
                                        // Rounded background that matches the corners
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.appTheme)
                                            .padding(.horizontal, index == 0 ? 0 : 1)
                                            .padding(.trailing, index == StatsPeriod.allCases.count - 1 ? 0 : 1)
                                    } else {
                                        Color.clear
                                    }
                                }
                            )
                    }

                    // Vertical separator (except after last item)
                    if index < StatsPeriod.allCases.count - 1 {
                        Rectangle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 1)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.1))
            )
            .frame(width: 200)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // Stats Chart card (with background)
            VStack {
                StatsChart(
                    data: generateChartData(for: selectedPeriod),
                    period: selectedPeriod.days
                )
                .frame(height: 200)
                .padding(.horizontal, 8)
                .padding(.vertical, 16)
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
            )
            .frame(maxWidth: 332)
        }
    }

    // Generate chart data based on selected period
    private func generateChartData(for period: StatsPeriod) -> [(date: Date, rate: Double)] {
        var data: [(date: Date, rate: Double)] = []

        // Determine interval and number of points based on period
        let (interval, pointCount) = period.chartConfig

        // Position actuelle sera au centre (index 3 pour 7 points)
        let centerIndex = pointCount / 2

        // Générer les points: 3 jours avant le jour actuel, le jour actuel, 3 jours après
        for i in 0..<pointCount {
            let daysOffset = (i - centerIndex) * interval
            let date = Calendar.current.date(byAdding: .day, value: daysOffset, to: Date()) ?? Date()
            let rate = Double.random(in: 0.5...0.95)
            data.append((date, rate))
        }

        return data
    }

    // MARK: - Achievement Section

    private var achievementSection: some View {
        Button(action: {
            HapticManager.light()
            showProgression = true
        }) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Ta progression")
                        .font(.custom("Poppins-SemiBold", size: 20))
                        .foregroundColor(.white)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))
                }

                HStack(spacing: 12) {
                    // Level badge
                    ZStack {
                        Circle()
                            .fill(planetSettings.selectedPlanet.haloColor.opacity(0.2))
                            .frame(width: 50, height: 50)

                        Image(systemName: "star.fill")
                            .font(.system(size: 22))
                            .foregroundColor(planetSettings.selectedPlanet.haloColor)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Niveau \(progressionManager.currentLevel.id)")
                            .font(.custom("Poppins-SemiBold", size: 16))
                            .foregroundColor(.white)

                        Text(progressionManager.currentLevel.name)
                            .font(.custom("Poppins-Medium", size: 14))
                            .foregroundColor(planetSettings.selectedPlanet.haloColor)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(progressionManager.currentXP) XP")
                            .font(.custom("Poppins-SemiBold", size: 14))
                            .foregroundColor(.white)

                        if progressionManager.streakDays > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(.orange)
                                Text("\(progressionManager.streakDays)j")
                                    .font(.custom("Poppins-Medium", size: 12))
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
            )
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showProgression) {
            ProgressionView()
        }
        .frame(maxWidth: 332)
    }
}

// MARK: - Achievement Badge

struct AchievementBadge: View {
    let icon: String
    let title: String
    let isUnlocked: Bool

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(
                        isUnlocked ?
                            LinearGradient(
                                colors: [Color.appTheme, Color.appThemeSecondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            LinearGradient(colors: [Color.white.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 60, height: 60)

                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(isUnlocked ? .white : .white.opacity(0.3))
            }

            Text(title)
                .font(.custom("Poppins-Regular", size: 12))
                .foregroundColor(isUnlocked ? .white : .white.opacity(0.5))
        }
        .opacity(isUnlocked ? 1.0 : 0.6)
    }
}

#Preview {
    ProfileView()
}
