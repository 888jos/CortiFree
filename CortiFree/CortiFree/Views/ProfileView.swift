//
//  ProfileView.swift
//  CortiFree
//
//  Created by Claude on 22/10/2025.
//  Amélioré avec évaluation CortiFree compacte
//

import SwiftUI
import FirebaseAuth
import Combine

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = ProfileViewModel()
    @ObservedObject private var achievementService = AchievementService.shared
    @ObservedObject private var habitBadgeService = HabitBadgeService.shared
    @State private var showSettings = false
    @State private var showProgression = false
    @State private var showPotentialScores = false
    @State private var showEditProfile = false
    @State private var showAchievementsView = false
    @State private var selectedTab: ProfileTab = .score
    @State private var firstName: String = ""

    enum ProfileTab {
        case score
        case habits
        case achievements
    }

    // Computed habits data from ViewModel
    private var habits: [(name: String, icon: String, progress: Double, color: Color)] {
        [
            (
                NSLocalizedString("profile.habit.meditation", comment: ""),
                "brain.head.profile",
                calculateProgress(habitId: "meditation"),
                Color(hex: "9B59B6")
            ),
            (
                NSLocalizedString("profile.habit.breathing", comment: ""),
                "wind",
                calculateProgress(habitId: "breathing"),
                Color(hex: "1ABC9C")
            ),
            (
                NSLocalizedString("profile.habit.journal", comment: ""),
                "book.fill",
                calculateProgress(habitId: "journal"),
                Color(hex: "E74C3C")
            ),
            (
                NSLocalizedString("profile.habit.sport", comment: ""),
                "figure.run",
                calculateProgress(habitId: "sport"),
                Color(hex: "2ECC71")
            ),
            (
                NSLocalizedString("profile.habit.water", comment: ""),
                "drop.fill",
                calculateProgress(habitId: "water"),
                Color(hex: "3498DB")
            ),
            (
                NSLocalizedString("profile.habit.nature", comment: ""),
                "leaf.fill",
                calculateProgress(habitId: "nature"),
                Color(hex: "27AE60")
            ),
            (
                NSLocalizedString("profile.habit.sleep", comment: ""),
                "moon.fill",
                calculateProgress(habitId: "sleep"),
                Color(hex: "E67E22")
            ),
            (
                NSLocalizedString("profile.habit.social", comment: ""),
                "person.2.fill",
                calculateProgress(habitId: "social"),
                Color(hex: "F39C12")
            )
        ]
    }

    // Calculate progress percentage for a habit (completed / total)
    private func calculateProgress(habitId: String) -> Double {
        guard let stats = viewModel.habitProgress[habitId] else { return 0.0 }
        guard stats.total > 0 else { return 0.0 }
        return Double(stats.completed) / Double(stats.total)
    }

    // Calculate global score (average of 5 domains) - Using real data from ViewModel
    private var globalScore: Int {
        let scores = showPotentialScores ? viewModel.potentialScores : viewModel.domainScores
        guard !scores.isEmpty, scores.count > 0 else { return 0 }
        let average = scores.reduce(0, +) / Double(scores.count)
        // Validate against NaN
        guard !average.isNaN && average.isFinite else { return 0 }
        // Scores are already 0-100, no need to multiply by 100
        return Int(round(average))
    }

    // Full 6-domain array for radar chart (Global + 5 domains) - Using real data from ViewModel
    // Radar chart expects values 0-1, so divide by 100
    private var radarScores: [Double] {
        let scores = showPotentialScores ? viewModel.potentialScores : viewModel.domainScores
        guard !scores.isEmpty, scores.count > 0 else { return [0.0, 0.0, 0.0, 0.0, 0.0, 0.0] }
        let global = scores.reduce(0, +) / Double(scores.count)
        // Validate against NaN and normalize to 0-1 range
        let validGlobal = (global.isNaN || !global.isFinite) ? 0.0 : global / 100.0
        let validScores = scores.map { score in
            let valid = (score.isNaN || !score.isFinite) ? 0.0 : score
            return valid / 100.0  // Normalize to 0-1 range
        }
        return [validGlobal] + validScores
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

    private var domainNames: [String] {
        [
            NSLocalizedString("profile.domain.serenity", comment: ""),
            NSLocalizedString("profile.domain.sleep", comment: ""),
            NSLocalizedString("profile.domain.energy", comment: ""),
            NSLocalizedString("profile.domain.focus", comment: ""),
            NSLocalizedString("profile.domain.balance", comment: "")
        ]
    }

    var body: some View {
        ZStack {
            // Galaxy animated background
            GalaxyBackgroundView(intensity: 1.0)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Fixed header (banner + profile elements) - stays on top
                ZStack(alignment: .center) {
                    // Banner image
                    profileBanner
                        .offset(y: -65)

                    // Profile header elements
                    VStack {
                        Spacer()
                        profileHeader
                            .padding(.horizontal, 24)
                            .offset(y: -45)
                        Spacer()
                    }
                }
                .frame(height: 220)
                .zIndex(1) // Ensure header stays on top

                // Scrollable content: tabs and sections (scroll UNDER the header)
                VStack(spacing: 0) {
                    // Tab selector
                    tabSelector
                        .padding(.horizontal, 32)
                        .offset(y: -32) // Remonter les tabs pour réduire l'espace avec la bannière

                    // Content based on selected tab with smooth transition
                    TabView(selection: $selectedTab) {
                        // CortiFree Score Section (scrollable)
                        ScrollView(showsIndicators: false) {
                            cortiFreeScoreSection
                                .padding(.horizontal, 32)
                                .padding(.top, 12)

                            Spacer(minLength: 100)
                        }
                        .tag(ProfileTab.score)

                        // Habits Section (scrollable)
                        ScrollView(showsIndicators: false) {
                            habitsSection
                                .padding(.horizontal, 32)
                                .padding(.top, 24)

                            Spacer(minLength: 100)
                        }
                        .tag(ProfileTab.habits)

                        // Achievements Section (scrollable)
                        achievementsSection
                            .padding(.horizontal, 32)
                            .padding(.top, 24)
                            .tag(ProfileTab.achievements)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .animation(.appSpring, value: selectedTab)
                    .offset(y: -32) // Remonter le contenu pour suivre les tabs
                }
            }
        }
        .ignoresSafeArea(.keyboard)
        .fullScreenCover(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(authViewModel)
        }
        .fullScreenCover(isPresented: $showEditProfile) {
            EditProfileView()
                .environmentObject(authViewModel)
        }
        .onAppear {
            // Initialize firstName
            firstName = getUserFirstName()
            // Refresh profile data when view appears
            Task {
                await viewModel.refreshProfile()
                // Load habit badges immediately
                await habitBadgeService.loadHabitBadges()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("TaskValidated"))) { _ in
            // Refresh habit progress when a task is validated
            Task {
                await viewModel.refreshProfile()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ProfileUpdated"))) { _ in
            // Refresh firstName when profile is updated
            firstName = getUserFirstName()
        }
    }

    // MARK: - Profile Banner

    private var profileBanner: some View {
        ZStack(alignment: .top) {
            // Background image
            Image("profile_banner")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity)
                .frame(height: 220)
                .clipped()
                .overlay(
                    // Gradient fade from transparent to dark at bottom
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color.clear,
                            Color(hex: "01000C").opacity(0.3),
                            Color(hex: "01000C")
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
        .frame(height: 220)
    }

    // MARK: - Profile Header

    private var profileHeader: some View {
        HStack(spacing: 16) {
            // Avatar with user initials and edit button
            ZStack(alignment: .bottomLeading) {
                // Main avatar
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [Color(hex: "B794F6"), Color(hex: "9B59B6")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 80, height: 80)

                    Text(String((firstName.isEmpty ? getUserFirstName() : firstName).prefix(1)).uppercased())
                        .font(.faroBold(32))
                        .foregroundColor(.white)
                }
                .overlay(
                    Circle()
                        .stroke(Color(hex: "01000C"), lineWidth: 2)
                )

                // Edit button overlay (bottom left)
                Button(action: {
                    HapticManager.light()
                    showEditProfile = true
                }) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: "B794F6"))
                            .frame(width: 28, height: 28)

                        Circle()
                            .stroke(Color(hex: "01000C"), lineWidth: 2)
                            .frame(width: 28, height: 28)

                        Image(systemName: "pencil")
                            .font(.system(size: 12))
                            .foregroundColor(.white)
                    }
                }
                .offset(x: -2, y: 2)
            }

            // User Info
            VStack(alignment: .leading, spacing: 6) {
                // Name
                Text(firstName.isEmpty ? getUserFirstName() : firstName)
                    .font(.faroBold(20))
                    .foregroundColor(.white)

                // Removed level display - no longer using XP/Levels system
            }

            Spacer()

            // Settings button (sans rond)
            Button(action: {
                HapticManager.light()
                showSettings = true
            }) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
            }
        }
    }

    // MARK: - Tab Selector

    private var tabSelector: some View {
        HStack(spacing: 2) {
            // Score CortiFree tab
            Button(action: {
                HapticManager.light()
                withAnimation(.appSpring) {
                    selectedTab = .score
                }
            }) {
                Text(NSLocalizedString("profile.tab.score", comment: ""))
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
                withAnimation(.appSpring) {
                    selectedTab = .habits
                }
            }) {
                Text(NSLocalizedString("profile.tab.habits", comment: ""))
                    .font(.custom(selectedTab == .habits ? "Poppins-SemiBold" : "Poppins-Regular", size: 12))
                    .foregroundColor(selectedTab == .habits ? .black : .white.opacity(0.7))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(selectedTab == .habits ? .white : Color.clear)
                    )
            }

            // Achievements tab
            Button(action: {
                HapticManager.light()
                withAnimation(.appSpring) {
                    selectedTab = .achievements
                }
            }) {
                Text(NSLocalizedString("profile.tab.badges", comment: ""))
                    .font(.custom(selectedTab == .achievements ? "Poppins-SemiBold" : "Poppins-Regular", size: 12))
                    .foregroundColor(selectedTab == .achievements ? .black : .white.opacity(0.7))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(selectedTab == .achievements ? .white : Color.clear)
                    )
            }
        }
        .padding(2)
        .background(
            RoundedRectangle(cornerRadius: 7)
                .fill(Color.white.opacity(0.2))
        )
        .frame(maxWidth: 300)
    }

    // MARK: - CortiFree Score Section (Compact)

    private var cortiFreeScoreSection: some View {
        VStack(spacing: 24) { // Increased spacing between elements
            // Header with toggle
            HStack {
                VStack(alignment: .leading, spacing: 2) { // Reduced from 4 to 2
                    Text(NSLocalizedString("profile.score.title", comment: ""))
                        .font(.faroBold(18))
                        .foregroundColor(.white)

                    Text(showPotentialScores ? NSLocalizedString("profile.score.potential", comment: "") : NSLocalizedString("profile.score.current", comment: ""))
                        .font(.custom("Poppins-Regular", size: 11)) // Reduced from 12 to 11
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
                // Larger hexagon radar - reduced size
                HexagonRadarChart(
                    progress: radarScores,
                    color: Color(hex: "B794F6"),
                    size: 220, // Reduced from 256 to 220
                    showLabels: false
                )
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showPotentialScores)

                // Position the 6 scores around the hexagon (Global + 5 domains) - adjusted offsets

                // Global - Top (0°)
                SimpleDomainScore(
                    icon: "star.fill",
                    title: NSLocalizedString("profile.score.global", comment: ""),
                    value: globalScore,
                    color: Color(hex: "B794F6"),
                    scoreDifference: viewModel.onboardingGlobalScore > 0 ? globalScore - viewModel.onboardingGlobalScore : nil
                )
                .offset(x: 0, y: -135) // Reduced from -155 to -135
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showPotentialScores)

                // Sérénité - Top right (60°)
                SimpleDomainScore(
                    icon: domainIcons[0],
                    title: domainNames[0],
                    value: showPotentialScores ? Int(round(viewModel.potentialScores[safe: 0] ?? 0.0)) : Int(round(viewModel.domainScores[safe: 0] ?? 0.0)),
                    color: domainColors[0],
                    scoreDifference: viewModel.onboardingDomainScores[safe: 0] ?? 0 > 0 ? (showPotentialScores ? Int(round(viewModel.potentialScores[safe: 0] ?? 0.0)) : Int(round(viewModel.domainScores[safe: 0] ?? 0.0))) - Int(round(viewModel.onboardingDomainScores[safe: 0] ?? 0.0)) : nil
                )
                .offset(x: 125, y: -65) // Reduced from 145/-75 to 125/-65
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showPotentialScores)

                // Sommeil - Bottom right (120°)
                SimpleDomainScore(
                    icon: domainIcons[1],
                    title: domainNames[1],
                    value: showPotentialScores ? Int(round(viewModel.potentialScores[safe: 1] ?? 0.0)) : Int(round(viewModel.domainScores[safe: 1] ?? 0.0)),
                    color: domainColors[1],
                    scoreDifference: viewModel.onboardingDomainScores[safe: 1] ?? 0 > 0 ? (showPotentialScores ? Int(round(viewModel.potentialScores[safe: 1] ?? 0.0)) : Int(round(viewModel.domainScores[safe: 1] ?? 0.0))) - Int(round(viewModel.onboardingDomainScores[safe: 1] ?? 0.0)) : nil
                )
                .offset(x: 125, y: 65) // Reduced from 145/75 to 125/65
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showPotentialScores)

                // Énergie - Bottom (180°)
                SimpleDomainScore(
                    icon: domainIcons[2],
                    title: domainNames[2],
                    value: showPotentialScores ? Int(round(viewModel.potentialScores[safe: 2] ?? 0.0)) : Int(round(viewModel.domainScores[safe: 2] ?? 0.0)),
                    color: domainColors[2],
                    scoreDifference: viewModel.onboardingDomainScores[safe: 2] ?? 0 > 0 ? (showPotentialScores ? Int(round(viewModel.potentialScores[safe: 2] ?? 0.0)) : Int(round(viewModel.domainScores[safe: 2] ?? 0.0))) - Int(round(viewModel.onboardingDomainScores[safe: 2] ?? 0.0)) : nil
                )
                .offset(x: 0, y: 135) // Reduced from 155 to 135
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showPotentialScores)

                // Focus - Bottom left (240°)
                SimpleDomainScore(
                    icon: domainIcons[3],
                    title: domainNames[3],
                    value: showPotentialScores ? Int(round(viewModel.potentialScores[safe: 3] ?? 0.0)) : Int(round(viewModel.domainScores[safe: 3] ?? 0.0)),
                    color: domainColors[3],
                    scoreDifference: viewModel.onboardingDomainScores[safe: 3] ?? 0 > 0 ? (showPotentialScores ? Int(round(viewModel.potentialScores[safe: 3] ?? 0.0)) : Int(round(viewModel.domainScores[safe: 3] ?? 0.0))) - Int(round(viewModel.onboardingDomainScores[safe: 3] ?? 0.0)) : nil
                )
                .offset(x: -125, y: 65) // Reduced from -145/75 to -125/65
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showPotentialScores)

                // Équilibre - Top left (300°)
                SimpleDomainScore(
                    icon: domainIcons[4],
                    title: domainNames[4],
                    value: showPotentialScores ? Int(round(viewModel.potentialScores[safe: 4] ?? 0.0)) : Int(round(viewModel.domainScores[safe: 4] ?? 0.0)),
                    color: domainColors[4],
                    scoreDifference: viewModel.onboardingDomainScores[safe: 4] ?? 0 > 0 ? (showPotentialScores ? Int(round(viewModel.potentialScores[safe: 4] ?? 0.0)) : Int(round(viewModel.domainScores[safe: 4] ?? 0.0))) - Int(round(viewModel.onboardingDomainScores[safe: 4] ?? 0.0)) : nil
                )
                .offset(x: -125, y: -65) // Reduced from -145/-75 to -125/-65
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showPotentialScores)
            }
            .frame(height: 330) // Reduced from 380 to 330
        }
    }

    // MARK: - Habits Section

    private var habitsSection: some View {
        VStack(spacing: 20) {
            // List of horizontal habit bars
            ForEach(Array(habits.enumerated()), id: \.offset) { index, habit in
                let habitId = getHabitId(from: habit.name)
                let stats = viewModel.habitProgress[habitId]
                HorizontalHabitBar(
                    icon: habit.icon,
                    title: habit.name,
                    progress: habit.progress,
                    color: habit.color,
                    completed: stats?.completed ?? 0,
                    total: stats?.total ?? 0,
                    animationTrigger: selectedTab == .habits
                )
                .cascadeAppear(index: index, totalCount: habits.count, baseDelay: 0.05)
            }
        }
    }

    // MARK: - Helper Methods

    private func getUserFirstName() -> String {
        if let user = Auth.auth().currentUser {
            if let displayName = user.displayName {
                return displayName.components(separatedBy: " ").first ?? NSLocalizedString(StringKeys.Common.defaultUserName, comment: "")
            } else if let email = user.email {
                return email.components(separatedBy: "@").first ?? NSLocalizedString(StringKeys.Common.defaultUserName, comment: "")
            }
        }
        return NSLocalizedString(StringKeys.Common.defaultUserName, comment: "")
    }

    private func getHabitId(from habitName: String) -> String {
        switch habitName {
        case NSLocalizedString("profile.habit.meditation", comment: ""): return "meditation"
        case NSLocalizedString("profile.habit.breathing", comment: ""): return "breathing"
        case NSLocalizedString("profile.habit.journal", comment: ""): return "journal"
        case NSLocalizedString("profile.habit.sport", comment: ""): return "sport"
        case NSLocalizedString("profile.habit.water", comment: ""): return "water"
        case NSLocalizedString("profile.habit.nature", comment: ""): return "nature"
        case NSLocalizedString("profile.habit.sleep", comment: ""): return "sleep"
        case NSLocalizedString("profile.habit.social", comment: ""): return "social"
        default: return "unknown"
        }
    }

    // MARK: - Achievements Section

    private var achievementsSection: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Global Progress Header
                globalBadgeProgress

                // SECTION 1: Streak Achievements (3x3 grid)
                VStack(spacing: 16) {
                    // Section header
                    HStack(spacing: 12) {
                        Text(NSLocalizedString("profile.achievements.streaks", comment: ""))
                            .font(.faroSemiBold(16))
                            .foregroundColor(.white)

                        Spacer()

                        Text("\(streakAchievements.filter { $0.isUnlocked }.count)/\(streakAchievements.count)")
                            .font(.custom("Poppins-Regular", size: 14))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, 12)

                    // Grid 3 colonnes pour streaks
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 16),
                        GridItem(.flexible(), spacing: 16),
                        GridItem(.flexible(), spacing: 16)
                    ], spacing: 20) {
                        ForEach(Array(streakAchievements.enumerated()), id: \.element.id) { index, achievement in
                            AchievementBadge(
                                achievement: achievement,
                                size: .medium
                            )
                            .cascadeAppear(index: index, totalCount: streakAchievements.count, baseDelay: 0.05)
                        }
                    }
                }

                // Divider horizontal
                Rectangle()
                    .fill(Color.white.opacity(0.15))
                    .frame(height: 1)
                    .padding(.vertical, 20)

                // SECTION 2: Habit Badges (3 per row)
                VStack(spacing: 16) {
                    // Section header
                    HStack(spacing: 12) {
                        Text(NSLocalizedString("profile.achievements.habits", comment: ""))
                            .font(.faroSemiBold(16))
                            .foregroundColor(.white)

                        Spacer()

                        Text("\(habitBadgeService.unlockedBadgesCount)/\(habitBadgeService.totalBadgesCount)")
                            .font(.custom("Poppins-Regular", size: 14))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, 12)

                    // Grid 3 colonnes pour habits avec animation staggered
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 16),
                        GridItem(.flexible(), spacing: 16),
                        GridItem(.flexible(), spacing: 16)
                    ], spacing: 20) {
                        ForEach(Array(HabitBadge.allHabitIds.enumerated()), id: \.element) { index, habitId in
                            SingleEvolvingHabitBadge(
                                habitId: habitId,
                                badges: habitBadgeService.badges(for: habitId),
                                currentProgress: getHabitProgress(habitId),
                                totalTasks: getHabitTotal(habitId)
                            )
                            .cascadeAppear(index: index, totalCount: HabitBadge.allHabitIds.count, baseDelay: 0.05)
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
        }
        .fullScreenCover(isPresented: $showAchievementsView) {
            AchievementsView()
        }
        .overlay(
            Group {
                // Habit badge unlock popup
                if habitBadgeService.showBadgePopup, let badge = habitBadgeService.newlyUnlockedBadge {
                    BadgeEvolutionView(badge: badge, isPresented: $habitBadgeService.showBadgePopup)
                        .transition(.opacity)
                }
            }
        )
    }

    // MARK: - Global Badge Progress

    private var globalBadgeProgress: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(NSLocalizedString("profile.achievements.badges_title", comment: ""))
                        .font(.faroBold(24))
                        .foregroundColor(.white)

                    Text("\(totalUnlockedBadges)/\(totalBadges) \(NSLocalizedString("profile.achievements.unlocked", comment: ""))")
                        .font(.custom("Poppins-Regular", size: 14))
                        .foregroundColor(.white.opacity(0.7))
                }

                Spacer()
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 8)

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "B794F6"), Color(hex: "9B59B6")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * globalBadgePercentage, height: 8)
                }
            }
            .frame(height: 8)

            Text("\(Int(globalBadgePercentage * 100))% \(NSLocalizedString("profile.achievements.complete", comment: ""))")
                .font(.custom("Poppins-Regular", size: 12))
                .foregroundColor(.white.opacity(0.6))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Helper Computed Properties

    private var streakAchievements: [Achievement] {
        achievementService.achievements.filter { $0.category == .streak }
    }

    private var totalUnlockedBadges: Int {
        achievementService.unlockedCount + habitBadgeService.unlockedBadgesCount
    }

    private var totalBadges: Int {
        achievementService.totalCount + habitBadgeService.totalBadgesCount
    }

    private var globalBadgePercentage: Double {
        guard totalBadges > 0 else { return 0 }
        return Double(totalUnlockedBadges) / Double(totalBadges)
    }

    private func getHabitProgress(_ habitId: String) -> Int {
        let stats = viewModel.habitProgress[habitId]
        return stats?.completed ?? 0
    }

    private func getHabitTotal(_ habitId: String) -> Int {
        let stats = viewModel.habitProgress[habitId]
        return stats?.total ?? 0
    }
}

#Preview {
    ProfileView()
        .environment(\.locale, Locale(identifier: "en"))
}
