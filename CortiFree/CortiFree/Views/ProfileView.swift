//
//  ProfileView.swift
//  CortiFree
//
//  Created by Claude on 22/10/2025.
//

import SwiftUI
import FirebaseAuth
import Combine

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = ProfileViewModel()
    @ObservedObject private var achievementService = AchievementService.shared
    @ObservedObject private var habitBadgeService = HabitBadgeService.shared
    // Re-render (localized strings) right after a language change in Settings
    @ObservedObject private var languageManager = LanguageManager.shared
    @State private var showSettings = false
    @State private var showEditProfile = false
    @State private var selectedTab: ProfileTab = .habits
    @State private var firstName: String = ""

    enum ProfileTab {
        case habits
        case achievements
    }

    // Computed habits data from ViewModel
    private var habits: [(name: String, icon: String, progress: Double, color: Color)] {
        [
            (
                LanguageManager.shared.localizedString(for: "profile.habit.meditation"),
                "brain.head.profile",
                calculateProgress(habitId: "meditation"),
                Color(hex: "9B59B6")
            ),
            (
                LanguageManager.shared.localizedString(for: "profile.habit.breathing"),
                "wind",
                calculateProgress(habitId: "breathing"),
                Color(hex: "1ABC9C")
            ),
            (
                LanguageManager.shared.localizedString(for: "profile.habit.journal"),
                "book.fill",
                calculateProgress(habitId: "journal"),
                Color(hex: "E74C3C")
            ),
            (
                LanguageManager.shared.localizedString(for: "profile.habit.sport"),
                "figure.run",
                calculateProgress(habitId: "sport"),
                Color(hex: "2ECC71")
            ),
            (
                LanguageManager.shared.localizedString(for: "profile.habit.water"),
                "drop.fill",
                calculateProgress(habitId: "water"),
                Color(hex: "3498DB")
            ),
            (
                LanguageManager.shared.localizedString(for: "profile.habit.nature"),
                "leaf.fill",
                calculateProgress(habitId: "nature"),
                Color(hex: "27AE60")
            ),
            (
                LanguageManager.shared.localizedString(for: "profile.habit.sleep"),
                "moon.fill",
                calculateProgress(habitId: "sleep"),
                Color(hex: "E67E22")
            ),
            (
                LanguageManager.shared.localizedString(for: "profile.habit.social"),
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

    var body: some View {
        ZStack {
            // Galaxy animated background
            GalaxyBackgroundView(intensity: 0.75)
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
                        .padding(.top, 8)
                        .padding(.bottom, 12)

                    // Content based on selected tab with smooth transition
                    TabView(selection: $selectedTab) {
                        // Habits Section (scrollable)
                        ScrollView(showsIndicators: false) {
                            habitsSection
                                .padding(.horizontal, 32)
                                .padding(.top, 8)

                            Spacer(minLength: 100)
                        }
                        .tag(ProfileTab.habits)

                        // Achievements Section (scrollable)
                        ScrollView(showsIndicators: false) {
                            achievementsSection
                                .padding(.horizontal, 32)
                                .padding(.top, 8)

                            Spacer(minLength: 100)
                        }
                        .tag(ProfileTab.achievements)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .animation(.appSpring, value: selectedTab)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                await viewModel.loadProfilePhoto()
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
            // Refresh firstName / photo when profile is updated
            firstName = getUserFirstName()
            Task { await viewModel.loadProfilePhoto() }
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

                    if let photo = viewModel.profilePhoto {
                        Image(uiImage: photo)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                    } else if !(firstName.isEmpty ? getUserFirstName() : firstName).isEmpty {
                        Text(String((firstName.isEmpty ? getUserFirstName() : firstName).prefix(1)).uppercased())
                            .font(.faroBold(32))
                            .foregroundColor(.white)
                    } else {
                        Image(systemName: "person.fill")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundColor(.white)
                    }
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
                if !(firstName.isEmpty ? getUserFirstName() : firstName).isEmpty {
                    Text(firstName.isEmpty ? getUserFirstName() : firstName)
                        .font(.faroBold(20))
                        .foregroundColor(.white)
                }

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
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .glassCircle(interactive: true)
        }
    }

    // MARK: - Tab Selector

    private var tabSelector: some View {
        HStack(spacing: 2) {
            // Habitudes tab
            Button(action: {
                HapticManager.light()
                withAnimation(.appSpring) {
                    selectedTab = .habits
                }
            }) {
                Text(LanguageManager.shared.localizedString(for: "profile.tab.habits"))
                    .font(.custom(selectedTab == .habits ? "Poppins-SemiBold" : "Poppins-Regular", size: 12))
                    .foregroundColor(selectedTab == .habits ? .black : .white.opacity(0.7))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
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
                Text(LanguageManager.shared.localizedString(for: "profile.tab.badges"))
                    .font(.custom(selectedTab == .achievements ? "Poppins-SemiBold" : "Poppins-Regular", size: 12))
                    .foregroundColor(selectedTab == .achievements ? .black : .white.opacity(0.7))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .fill(selectedTab == .achievements ? .white : Color.clear)
                    )
            }
        }
        .padding(3)
        .glassCard(cornerRadius: 12)
        .frame(maxWidth: 300)
        .zIndex(2)
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
        if let storedName = UserPersistence.userFirstName?.trimmingCharacters(in: .whitespacesAndNewlines), !storedName.isEmpty {
            return storedName
        }
        if let user = Auth.auth().currentUser {
            if let displayName = user.displayName, !displayName.isEmpty {
                return displayName.components(separatedBy: " ").first ?? ""
            }
        }
        return ""
    }

    private func getHabitId(from habitName: String) -> String {
        switch habitName {
        case LanguageManager.shared.localizedString(for: "profile.habit.meditation"): return "meditation"
        case LanguageManager.shared.localizedString(for: "profile.habit.breathing"): return "breathing"
        case LanguageManager.shared.localizedString(for: "profile.habit.journal"): return "journal"
        case LanguageManager.shared.localizedString(for: "profile.habit.sport"): return "sport"
        case LanguageManager.shared.localizedString(for: "profile.habit.water"): return "water"
        case LanguageManager.shared.localizedString(for: "profile.habit.nature"): return "nature"
        case LanguageManager.shared.localizedString(for: "profile.habit.sleep"): return "sleep"
        case LanguageManager.shared.localizedString(for: "profile.habit.social"): return "social"
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
                        Text(LanguageManager.shared.localizedString(for: "profile.achievements.streaks"))
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
                        Text(LanguageManager.shared.localizedString(for: "profile.achievements.habits"))
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
                    Text(LanguageManager.shared.localizedString(for: "profile.achievements.badges_title"))
                        .font(.faroBold(24))
                        .foregroundColor(.white)

                    Text("\(totalUnlockedBadges)/\(totalBadges) \(LanguageManager.shared.localizedString(for: "profile.achievements.unlocked"))")
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

            Text("\(Int(globalBadgePercentage * 100))% \(LanguageManager.shared.localizedString(for: "profile.achievements.complete"))")
                .font(.custom("Poppins-Regular", size: 12))
                .foregroundColor(.white.opacity(0.6))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(18)
        .glassCard(cornerRadius: 22)
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
        if let completed = stats?.completed { return completed }
        let userId = Auth.auth().currentUser?.uid ?? UserPersistence.localUserID
        return LocalProgressStore.completedCount(for: habitId, userID: userId)
    }

    private func getHabitTotal(_ habitId: String) -> Int {
        let stats = viewModel.habitProgress[habitId]
        return stats?.total ?? TaskStatusService.habitTotals[habitId, default: 0]
    }
}

#Preview {
    ProfileView()
        .environment(\.locale, Locale(identifier: "en"))
}
