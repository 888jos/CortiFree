//
//  ProfileView.swift
//  CortiFree
//
//  Created by Claude on 22/10/2025.
//

import SwiftUI
import Combine

struct ProfileView: View {
    @Binding var selectedTab: ContentView.Tab
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = ProfileViewModel()
    @StateObject private var progress = ProgressViewModel()
    @ObservedObject private var planStore = PersonalPlanStore.shared
    @ObservedObject private var achievementService = AchievementService.shared
    @ObservedObject private var habitBadgeService = HabitBadgeService.shared
    // Re-render (localized strings) right after a language change in Settings
    @ObservedObject private var languageManager = LanguageManager.shared
    @State private var showSettings = false
    @State private var showEditProfile = false
    @State private var showAchievements = false
    @State private var showJournal = false
    @State private var showJournalHistory = false
    @State private var showAssistant = false
    @State private var firstName: String = ""
    @State private var todayDone = 0

    var body: some View {
        ZStack {
            // Galaxy animated background
            GalaxyBackgroundView(intensity: 0.75)
                .ignoresSafeArea()

            ZStack(alignment: .top) {
                // Scrollable content: starts just below the banner and scrolls UNDER it
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        ProfileStatsStrip(
                            streak: max(progress.data.currentStreak, UserPersistence.streakDays),
                            calmMinutes: calmMinutes,
                            unlockedBadges: totalUnlockedBadges,
                            totalBadges: totalBadges,
                            action: { selectedTab = .progress }
                        )
                        .cascadeAppear(index: 0, totalCount: 7, baseDelay: 0.05)

                        if let plan = planStore.plan {
                            ProfileWhyCard(plan: plan)
                                .cascadeAppear(index: 1, totalCount: 7, baseDelay: 0.05)

                            ProfilePlanCard(plan: plan, todayDone: todayDone, action: { selectedTab = .tasks })
                                .cascadeAppear(index: 2, totalCount: 7, baseDelay: 0.05)
                        }

                        ProfileSessionsSection(explore: { selectedTab = .library })
                            .cascadeAppear(index: 3, totalCount: 7, baseDelay: 0.05)

                        ProfileMoodCard(
                            days: lastSevenDays,
                            write: { showJournal = true },
                            history: { showJournalHistory = true }
                        )
                        .cascadeAppear(index: 4, totalCount: 7, baseDelay: 0.05)

                        ProfileBadgesShowcase(achievements: streakAchievements, seeAll: { showAchievements = true })
                            .cascadeAppear(index: 5, totalCount: 7, baseDelay: 0.05)

                        ProfileShortcutsSection(openMilo: { showAssistant = true })
                            .cascadeAppear(index: 6, totalCount: 7, baseDelay: 0.05)

                        Spacer(minLength: 120)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 168)
                }

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
        .fullScreenCover(isPresented: $showAchievements) {
            AchievementsView()
        }
        .fullScreenCover(isPresented: $showJournal) {
            JournalHomeView()
        }
        .fullScreenCover(isPresented: $showJournalHistory) {
            JournalHistoryView()
        }
        .sheet(isPresented: $showAssistant) {
            AssistantChatView()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .onAppear {
            firstName = getUserFirstName()
            refreshTodayDone()
            Task {
                await viewModel.loadProfilePhoto()
                await planStore.ensurePlan()
                refreshTodayDone()
                await progress.loadIfNeeded()
                await achievementService.loadAchievements()
                await habitBadgeService.loadHabitBadges()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("TaskValidated"))) { _ in
            refreshTodayDone()
            Task { await progress.refresh() }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("DailyCheckInSaved"))) { _ in
            Task { await progress.refresh() }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("TaskSkippedAfterValidation"))) { _ in
            refreshTodayDone()
            Task { await progress.refresh() }
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

    // MARK: - Data

    private var calmMinutes: Int {
        progress.data.activities.reduce(0) { $0 + $1.durationSeconds } / 60
    }

    /// Last seven days (oldest first), padded so the mood row always shows a full week.
    private var lastSevenDays: [ProgressDay] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (0..<7).reversed().compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            return progress.data.days.first { calendar.isDate($0.date, inSameDayAs: date) }
                ?? ProgressDay(date: date, completionCount: 0, moodScore: nil)
        }
    }

    private var streakAchievements: [Achievement] {
        achievementService.achievements.filter { $0.category == .streak }
    }

    private var totalUnlockedBadges: Int {
        achievementService.unlockedCount + habitBadgeService.unlockedBadgesCount
    }

    private var totalBadges: Int {
        achievementService.totalCount + habitBadgeService.totalBadgesCount
    }

    /// Plan items of today validated today (local completions, available offline).
    private func refreshTodayDone() {
        guard let plan = planStore.plan, !plan.isFinished,
              let day = plan.day(plan.dayIndex()) else {
            todayDone = 0
            return
        }
        let keys = Set(day.items.map(\.statusKey))
        let userID = Auth.auth().currentUser?.uid ?? UserPersistence.localUserID
        todayDone = Set(
            LocalProgressStore.load(for: userID)
                .filter { Calendar.current.isDateInToday($0.completedAt) && keys.contains($0.taskID) }
                .map(\.taskID)
        ).count
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
}

#Preview {
    ProfileView(selectedTab: .constant(.profile))
        .environment(\.locale, Locale(identifier: "en"))
}
