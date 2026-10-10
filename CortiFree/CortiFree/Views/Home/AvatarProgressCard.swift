//
//  AvatarProgressCard.swift
//  CortiFree
//
//  Carte avatar minimaliste avec la grille du plan personnel (28 jours, une ligne par semaine)
//

import SwiftUI
import Combine

struct AvatarProgressCard: View {
    @ObservedObject private var planStore = PersonalPlanStore.shared
    @State private var isPressed: Bool = false
    @State private var isFlipped: Bool = false
    @State private var currentStreak: Int = 0
    @State private var bestStreak: Int = 0
    @State private var showBadgesScreen: Bool = false
    @State private var firstName: String = ""
    @State private var didLoadProgress: Bool = false

    private let totalDays = PersonalPlan.length

    /// Jour du plan (1...28), même source que l'onglet Plan.
    private var currentProgramDay: Int { min(planStore.todayIndex, totalDays) }
    private var startDate: Date { planStore.plan?.startDate ?? Date() }

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
            guard !didLoadProgress else { return }
            didLoadProgress = true
            loadProgress()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("StreakUpdated"))) { _ in
            currentStreak = StreakService.current
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
        AvatarCardFront(
            firstName: firstName.isEmpty ? getUserFirstName() : firstName,
            startDate: startDate,
            currentDay: currentProgramDay,
            streak: currentStreak
        )
    }

    // MARK: - Back Card (Verso) - Redesigned

    private var backCard: some View {
        VStack(spacing: 0) {
            // Header redesigné avec icônes
            HStack(spacing: 8) {
                Image(systemName: "star.fill")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "B794F6"))

                Text(LanguageManager.shared.localizedString(for: "avatar.my_progress"))
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

            // Stat principale - Jours complétés avec gradient blanc-violet (aligné à gauche avec l'étoile)
            VStack(alignment: .leading, spacing: 4) {
                Text("\(currentProgramDay)/\(totalDays)")
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

                Text(LanguageManager.shared.localizedString(for: "avatar.days"))
                    .font(.custom("Poppins-Regular", size: 14))
                    .foregroundColor(.white.opacity(0.6))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)

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

                            Text(String(format: LanguageManager.shared.localizedString(for: "avatar.next_badge"), badgeInfo.daysLeft, badgeInfo.daysLeft > 1 ? LanguageManager.shared.localizedString(for: "avatar.next_badge.plural") : LanguageManager.shared.localizedString(for: "avatar.next_badge.singular")))
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
        .glassCard(cornerRadius: 14, tint: Color(hex: "B794F6"))
    }

    private func loadProgress() {
        // Le plan est déjà chargé par l'onglet Plan ; on s'assure qu'il existe si l'accueil s'ouvre en premier.
        Task { await planStore.ensurePlan() }

        currentStreak = StreakService.current
        bestStreak = UserDefaults.standard.integer(forKey: "bestStreak")
        firstName = getUserFirstName()
    }

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

    private func formatFullDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: date)
    }

    // MARK: - Computed Properties for Back Card

    private var progressPercentage: Int {
        guard totalDays > 0 else { return 0 }
        return Int((Double(currentProgramDay) / Double(totalDays)) * 100)
    }

    private var endDate: Date {
        Calendar.current.date(byAdding: .day, value: totalDays, to: startDate) ?? startDate
    }

    private var motivationalMessage: String {
        let percentage = progressPercentage
        if percentage < 10 {
            return LanguageManager.shared.localizedString(for: "avatar.motivation.0_10")
        } else if percentage < 25 {
            return LanguageManager.shared.localizedString(for: "avatar.motivation.10_25")
        } else if percentage < 50 {
            return String(format: LanguageManager.shared.localizedString(for: "avatar.motivation.25_50"), percentage)
        } else if percentage < 75 {
            return LanguageManager.shared.localizedString(for: "avatar.motivation.50_75")
        } else if percentage < 100 {
            return LanguageManager.shared.localizedString(for: "avatar.motivation.75_100")
        } else {
            return LanguageManager.shared.localizedString(for: "avatar.motivation.100")
        }
    }

    /// Next streak achievement (same milestones as AchievementService), counted on the streak.
    private var nextBadgeInfo: (title: String, daysLeft: Int)? {
        let milestones = [3, 7, 14, 21, 30, 40, 50, 60, 66]
        guard let next = milestones.first(where: { currentStreak < $0 }) else { return nil }
        return (title: LanguageManager.shared.localizedString(for: "achievement.streak_\(next).title"),
                daysLeft: next - currentStreak)
    }
}

// MARK: - Badges List View

struct BadgesListView: View {
    @ObservedObject private var achievementService = AchievementService.shared
    @ObservedObject private var habitBadgeService = HabitBadgeService.shared
    @StateObject private var profileViewModel = ProfileViewModel()
    @Environment(\.dismiss) var dismiss
    @State private var didLoadBackCard: Bool = false

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
        if let completed = stats?.completed { return completed }
        guard let userId = Auth.auth().currentUser?.uid else { return 0 }
        return LocalProgressStore.completedCount(for: habitId, userID: userId)
    }

    private func getHabitTotal(_ habitId: String) -> Int {
        let stats = profileViewModel.habitProgress[habitId]
        return stats?.total ?? TaskStatusService.habitTotals[habitId, default: 0]
    }

    var body: some View {
        ZStack {
            // Galaxy background
            GalaxyBackgroundView(intensity: 0.75)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        HapticManager.light()
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .contentShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .glassCircle(interactive: true)

                    Spacer()

                    Text(LanguageManager.shared.localizedString(for: "avatar.badges_title"))
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
                                    Text(LanguageManager.shared.localizedString(for: "avatar.badges_title"))
                                        .font(Font.Poppins.custom(.bold, size: 24))
                                        .foregroundColor(.white)

                                    Text(String(format: LanguageManager.shared.localizedString(for: "avatar.badges_unlocked"), totalUnlockedBadges, totalBadges))
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

                            Text(String(format: LanguageManager.shared.localizedString(for: "avatar.badges_complete"), Int(globalBadgePercentage * 100)))
                                .font(.custom("Poppins-Regular", size: 12))
                                .foregroundColor(.white.opacity(0.6))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(20)
                        .glassCard()

                        // SECTION 1: Streak Achievements (3x3 grid)
                        VStack(spacing: 16) {
                            // Section header
                            HStack(spacing: 12) {
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(Color(hex: "FF8800"))

                                Text(LanguageManager.shared.localizedString(for: "avatar.streaks_section"))
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

                                Text(LanguageManager.shared.localizedString(for: "avatar.habits_section"))
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
            guard !didLoadBackCard else { return }
            didLoadBackCard = true
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

/// Front of the home avatar card: the avatar, the 28 plan days (one row per week), the plan
/// start date and the first name bottom right. Also shown when the card is unlocked in the onboarding.
struct AvatarCardFront: View {
    let firstName: String
    let startDate: Date
    /// Plan day (1...28); 0 = nothing started yet, every cell grey.
    let currentDay: Int
    /// Current streak, shown top left (nil: no pill, e.g. in the onboarding).
    var streak: Int? = nil

    private let totalDays = PersonalPlan.length
    private let columns = 7
    private let cellSize: CGFloat = 20
    private let cellSpacing: CGFloat = 5

    var body: some View {
        ZStack(alignment: .bottom) {
            // Avatar image
            Image("profile_avatar")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 216)
                .frame(height: 320)
                .clipShape(RoundedRectangle(cornerRadius: 14))

            if let streak {
                VStack {
                    HStack {
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(streak > 0 ? AppConstants.Colors.streakOrange : .white.opacity(0.6))
                            Text("\(streak)")
                                .font(.custom("Poppins-SemiBold", size: 12))
                                .foregroundStyle(.white)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(.black.opacity(0.45)))
                        .overlay(Capsule().stroke(.white.opacity(0.18), lineWidth: 1))
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel(String(format: "avatar.streak.accessibility".localized, streak))
                        Spacer()
                    }
                    Spacer()
                }
                .padding(10)
            }

            // Grid overlay INSIDE the image, in the last quarter
            VStack(spacing: 0) {
                // Grid of the plan days (no animation)
                LazyVGrid(columns: Array(repeating: GridItem(.fixed(cellSize), spacing: cellSpacing), count: columns), spacing: cellSpacing) {
                    ForEach(0..<totalDays, id: \.self) { day in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(dayColor(for: day))
                            .frame(width: cellSize, height: cellSize)
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

                    if !firstName.isEmpty {
                        Text(firstName)
                            .font(.custom("Poppins-SemiBold", size: 10))
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
            }
            .padding(.bottom, 8)
        }
        .frame(width: 216, height: 320)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(
                    LinearGradient(colors: [.white.opacity(0.55), .white.opacity(0.12)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 1
                )
        )
        .shadow(color: .black.opacity(0.3), radius: 16, x: 0, y: 8)
    }

    private func dayColor(for day: Int) -> Color {
        if day < currentDay - 1 {
            return Color(hex: "B794F6")              // done
        } else if day == currentDay - 1 {
            return Color(hex: "B794F6").opacity(0.5) // today
        } else {
            return Color.white.opacity(0.2)          // to come
        }
    }

    private func formatStartDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM"
        return formatter.string(from: date)
    }
}
