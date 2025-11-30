//
//  AvatarProgressCard.swift
//  CortiFree
//
//  Carte avatar minimaliste avec grille de progression 66 jours
//

import SwiftUI
import FirebaseAuth
import Combine

struct AvatarProgressCard: View {
    @State private var daysElapsed: Int = 0 // Nombre de jours écoulés depuis le début
    @State private var isPressed: Bool = false
    @State private var isFlipped: Bool = false
    @State private var startDate: Date = Date()
    @State private var currentStreak: Int = 0
    @State private var bestStreak: Int = 0
    @State private var showBadgesScreen: Bool = false
    @State private var firstName: String = ""

    private let totalDays = 66
    private let columns = 8   // 8 colonnes pour cellules plus grandes
    private let rows = 9      // 9 lignes (72 cases, on n'affiche que 66)

    var body: some View {
        ZStack {
            // RECTO - Avatar with grid
            frontCard
                .opacity(isFlipped ? 0 : 1)
                .rotation3DEffect(
                    .degrees(isFlipped ? 180 : 0),
                    axis: (x: 0, y: 1, z: 0)
                )

            // VERSO - Stats motivantes
            backCard
                .opacity(isFlipped ? 1 : 0)
                .rotation3DEffect(
                    .degrees(isFlipped ? 0 : -180),
                    axis: (x: 0, y: 1, z: 0)
                )
        }
        .frame(width: 216, height: 320)  // 240 * 0.90 = 216 (réduction de 10%)
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .onTapGesture {
            HapticManager.light()
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                isFlipped.toggle()
            }
        }
        .onAppear {
            loadProgress()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("StreakUpdated"))) { _ in
            // Reload streak when updated from TasksV2View
            currentStreak = UserDefaults.standard.integer(forKey: "streakDays")
            bestStreak = UserDefaults.standard.integer(forKey: "bestStreak")
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ProfileUpdated"))) { _ in
            // Refresh first name when profile is updated
            firstName = getUserFirstName()
        }
        .fullScreenCover(isPresented: $showBadgesScreen) {
            BadgesListView()
        }
    }

    // MARK: - Front Card (Recto)

    private var frontCard: some View {
        ZStack(alignment: .bottom) {
            // Avatar image
            Image("profile_avatar")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 216)
                .frame(height: 320)
                .clipShape(RoundedRectangle(cornerRadius: 14))

            // Grid overlay INSIDE the image, in the last quarter
            VStack(spacing: 0) {
                // Grid of 66 days (no animation)
                LazyVGrid(columns: Array(repeating: GridItem(.fixed(12), spacing: 3), count: columns), spacing: 3) {
                    ForEach(0..<totalDays, id: \.self) { day in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(dayColor(for: day))
                            .frame(width: 12, height: 12)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.top, 12)

                // Date and username row
                HStack {
                    Text(formatStartDate(startDate))
                        .font(.custom("Poppins-Medium", size: 10))
                        .foregroundColor(.white.opacity(0.8))

                    Spacer()

                    Text(firstName.isEmpty ? getUserFirstName() : firstName)
                        .font(.custom("Poppins-SemiBold", size: 10))
                        .foregroundColor(.white.opacity(0.9))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
            }
            .padding(.bottom, 8)
        }
        .frame(width: 216, height: 320)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
    }

    // MARK: - Back Card (Verso) - Redesigned

    private var backCard: some View {
        VStack(spacing: 0) {
            // Header redesigné avec icônes
            HStack(spacing: 8) {
                Image(systemName: "star.fill")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "B794F6"))

                Text(NSLocalizedString("avatar.my_progress", comment: ""))
                    .font(.custom("Poppins-Medium", size: 13))
                    .foregroundColor(.white.opacity(0.8))

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "FF8800"))

                    Text("\(currentStreak)")
                        .font(Font.Poppins.custom(.bold, size: 14))
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)

            Spacer()

            // Stat principale - Jours complétés avec gradient blanc-violet (aligné à gauche)
            VStack(spacing: 4) {
                Text("\(daysElapsed)/\(totalDays)")
                    .font(Font.Poppins.custom(.bold, size: 56))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color.white,
                                Color(hex: "B794F6")
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                Text(NSLocalizedString("avatar.days", comment: ""))
                    .font(.custom("Poppins-Regular", size: 14))
                    .foregroundColor(.white.opacity(0.6))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)

            Spacer()

            // Message motivationnel
            Text(motivationalMessage)
                .font(.custom("Poppins-Medium", size: 12))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)

            Spacer().frame(height: 12)

            // Badge milestone avec preview cliquable
            if let badgeInfo = nextBadgeInfo {
                Button(action: {
                    HapticManager.light()
                    showBadgesScreen = true
                }) {
                    HStack(spacing: 10) {
                        // Preview du badge
                        ZStack {
                            Circle()
                                .fill(Color(hex: "B794F6").opacity(0.2))
                                .frame(width: 40, height: 40)

                            Image(systemName: "flame.fill")
                                .font(.system(size: 18))
                                .foregroundColor(Color(hex: "B794F6"))
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(badgeInfo.title)
                                .font(.custom("Poppins-SemiBold", size: 13))
                                .foregroundColor(.white)

                            Text(String(format: NSLocalizedString("avatar.next_badge", comment: ""), badgeInfo.daysLeft, badgeInfo.daysLeft > 1 ? NSLocalizedString("avatar.next_badge.plural", comment: "") : NSLocalizedString("avatar.next_badge.singular", comment: "")))
                                .font(.custom("Poppins-Regular", size: 11))
                                .foregroundColor(Color(hex: "B794F6"))
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color(hex: "B794F6"))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white.opacity(0.05))
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal, 20)
            }

            Spacer().frame(height: 20)
        }
        .frame(width: 216, height: 320)
        .background(
            LinearGradient(
                colors: [
                    Color(hex: "1A1B3A"),
                    Color(hex: "0D0E1F")
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
    }

    private func dayColor(for day: Int) -> Color {
        if day < daysElapsed {
            // Jours terminés - Violet plein
            return Color(hex: "B794F6")
        } else if day == daysElapsed {
            // Jour en cours - Violet à 50% d'opacité
            return Color(hex: "B794F6").opacity(0.5)
        } else {
            // Jours à venir - Gris
            return Color.white.opacity(0.2)
        }
    }

    private func loadProgress() {
        // Load program start date from UserDefaults
        if let savedStartDate = UserDefaults.standard.object(forKey: "programStartDate") as? Date {
            startDate = savedStartDate

            // Calculate days elapsed since start
            let calendar = Calendar.current
            let startOfToday = calendar.startOfDay(for: Date())
            let startOfProgramDay = calendar.startOfDay(for: savedStartDate)

            if let daysDifference = calendar.dateComponents([.day], from: startOfProgramDay, to: startOfToday).day {
                daysElapsed = min(daysDifference, 66) // Cap at 66 days
            }
        } else {
            // If no start date, use default
            daysElapsed = 0
        }

        // Load current streak from UserDefaults
        currentStreak = UserDefaults.standard.integer(forKey: "streakDays")

        // Load best streak from UserDefaults
        bestStreak = UserDefaults.standard.integer(forKey: "bestStreak")

        // Load first name
        firstName = getUserFirstName()

        print("📊 AvatarProgressCard loaded: Days elapsed: \(daysElapsed)/\(totalDays), Streak: \(currentStreak)")
    }

    private func getUserFirstName() -> String {
        if let user = Auth.auth().currentUser {
            if let displayName = user.displayName {
                return displayName.components(separatedBy: " ").first ?? "Champion"
            } else if let email = user.email {
                return email.components(separatedBy: "@").first ?? "Champion"
            }
        }
        return "Champion"
    }

    private func formatStartDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM"
        return formatter.string(from: date)
    }

    private func formatFullDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: date)
    }

    // MARK: - Computed Properties for Back Card

    private var progressPercentage: Int {
        guard totalDays > 0 else { return 0 }
        return Int((Double(daysElapsed) / Double(totalDays)) * 100)
    }

    private var endDate: Date {
        Calendar.current.date(byAdding: .day, value: totalDays, to: startDate) ?? startDate
    }

    private var motivationalMessage: String {
        let percentage = progressPercentage
        if percentage < 10 {
            return NSLocalizedString("avatar.motivation.0_10", comment: "")
        } else if percentage < 25 {
            return NSLocalizedString("avatar.motivation.10_25", comment: "")
        } else if percentage < 50 {
            return String(format: NSLocalizedString("avatar.motivation.25_50", comment: ""), percentage)
        } else if percentage < 75 {
            return NSLocalizedString("avatar.motivation.50_75", comment: "")
        } else if percentage < 100 {
            return NSLocalizedString("avatar.motivation.75_100", comment: "")
        } else {
            return NSLocalizedString("avatar.motivation.100", comment: "")
        }
    }

    private var nextBadgeInfo: (title: String, daysLeft: Int)? {
        let milestones = [3, 7, 14, 21, 30, 40, 50, 60, 66]
        let badgeTitles = [
            NSLocalizedString("avatar.badge.beginner", comment: ""),
            NSLocalizedString("avatar.badge.motivated", comment: ""),
            NSLocalizedString("avatar.badge.determined", comment: ""),
            NSLocalizedString("avatar.badge.engaged", comment: ""),
            NSLocalizedString("avatar.badge.assiduous", comment: ""),
            NSLocalizedString("avatar.badge.champion", comment: ""),
            NSLocalizedString("avatar.badge.invincible", comment: ""),
            NSLocalizedString("avatar.badge.legend", comment: ""),
            NSLocalizedString("avatar.badge.master", comment: "")
        ]

        for (index, milestone) in milestones.enumerated() {
            if daysElapsed < milestone {
                let daysLeft = milestone - daysElapsed
                return (title: badgeTitles[index], daysLeft: daysLeft)
            }
        }

        return nil // All badges unlocked
    }
}

// MARK: - Badges List View

struct BadgesListView: View {
    @StateObject private var achievementService = AchievementService.shared
    @StateObject private var habitBadgeService = HabitBadgeService.shared
    @StateObject private var profileViewModel = ProfileViewModel()
    @Environment(\.dismiss) var dismiss

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
        let stats = profileViewModel.habitProgress[habitId]
        return stats?.completed ?? 0
    }

    private func getHabitTotal(_ habitId: String) -> Int {
        let stats = profileViewModel.habitProgress[habitId]
        return stats?.total ?? 0
    }

    var body: some View {
        ZStack {
            // Galaxy background
            GalaxyBackgroundView(intensity: 1.0)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        HapticManager.light()
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                    }

                    Spacer()

                    Text(NSLocalizedString("avatar.badges_title", comment: ""))
                        .font(.custom("Poppins-Bold", size: 20))
                        .foregroundColor(.white)

                    Spacer()

                    Color.clear.frame(width: 44, height: 44)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                // Content
                ScrollView {
                    VStack(spacing: 32) {
                        // Global Progress Header
                        VStack(spacing: 12) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(NSLocalizedString("avatar.badges_title", comment: ""))
                                        .font(Font.Poppins.custom(.bold, size: 24))
                                        .foregroundColor(.white)

                                    Text(String(format: NSLocalizedString("avatar.badges_unlocked", comment: ""), totalUnlockedBadges, totalBadges))
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

                            Text(String(format: NSLocalizedString("avatar.badges_complete", comment: ""), Int(globalBadgePercentage * 100)))
                                .font(.custom("Poppins-Regular", size: 12))
                                .foregroundColor(.white.opacity(0.6))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        // SECTION 1: Streak Achievements (3x3 grid)
                        VStack(spacing: 16) {
                            // Section header
                            HStack(spacing: 12) {
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(Color(hex: "FF8800"))

                                Text(NSLocalizedString("avatar.streaks_section", comment: ""))
                                    .font(.custom("Poppins-Bold", size: 16))
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
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .font(.system(size: 20))
                                    .foregroundColor(Color(hex: "B794F6"))

                                Text(NSLocalizedString("avatar.habits_section", comment: ""))
                                    .font(.custom("Poppins-Bold", size: 16))
                                    .foregroundColor(.white)

                                Spacer()

                                Text("\(habitBadgeService.unlockedBadgesCount)/\(habitBadgeService.totalBadgesCount)")
                                    .font(.custom("Poppins-Regular", size: 14))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            .padding(.horizontal, 4)
                            .padding(.vertical, 12)

                            // Grid 3 colonnes pour habits
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
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                }
            }
        }
        .onAppear {
            Task {
                await profileViewModel.refreshProfile()
                await habitBadgeService.loadHabitBadges()
            }
        }
    }
}

struct AvatarProgressCard_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            AvatarProgressCard()
                .padding()
                .frame(height: 300)
        }
    }
}