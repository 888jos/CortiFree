//
//  HomeView.swift
//  CortiFree
//
//  Created by Claude on 22/10/2025.
//  Updated with exact design specs
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @StateObject private var motivationalVM = MotivationalMessageViewModel()
    @Binding var isScrolling: Bool
    @Binding var scrollTimer: Timer?

    @State private var showBreathingList = false
    @State private var showMeditationList = false
    @State private var showSoundsList = false
    @State private var showJournal = false
    @State private var showSettings = false
    @State private var currentTime = Date() // For countdown updates

    // Smart scroll detection
    @State private var lastScrollOffset: CGFloat = 0
    @State private var scrollVelocity: CGFloat = 0
    @State private var scrollOffset: CGFloat = 0 // For parallax effect

    // Routine tracking
    private var routineStartDate: Date {
        UserDefaults.standard.object(forKey: AppConstants.UserDefaultsKeys.routineStartDate) as? Date ?? Date()
    }

    private var selectedRoutineTitle: String {
        UserDefaults.standard.string(forKey: AppConstants.UserDefaultsKeys.selectedRoutineTitle) ?? "ton objectif"
    }

    private var daysRemaining: Int {
        let daysPassed = Calendar.current.dateComponents([.day], from: routineStartDate, to: Date()).day ?? 0
        return max(0, AppConstants.Routine.totalDays - daysPassed)
    }

    private var timeRemaining: (days: Int, hours: Int, minutes: Int, seconds: Int) {
        let endDate = Calendar.current.date(byAdding: .day, value: AppConstants.Routine.totalDays, to: routineStartDate) ?? currentTime
        let components = Calendar.current.dateComponents([.day, .hour, .minute, .second], from: currentTime, to: endDate)
        return (
            max(0, components.day ?? 0),
            max(0, components.hour ?? 0),
            max(0, components.minute ?? 0),
            max(0, components.second ?? 0)
        )
    }

    // Generate personalized phrase based on routine title
    private var personalizedPhrase: String {
        switch selectedRoutineTitle.lowercased() {
        case let title where title.contains("anxiété") || title.contains("anxiety"):
            return NSLocalizedString("home.goal.anxiety", comment: "")
        case let title where title.contains("sommeil") || title.contains("sleep"):
            return NSLocalizedString("home.goal.sleep", comment: "")
        case let title where title.contains("concentration") || title.contains("focus"):
            return NSLocalizedString("home.goal.concentration", comment: "")
        case let title where title.contains("fatigue"):
            return NSLocalizedString("home.goal.fatigue", comment: "")
        case let title where title.contains("tension"):
            return NSLocalizedString("home.goal.tension", comment: "")
        case let title where title.contains("contrôle") || title.contains("control"):
            return NSLocalizedString("home.goal.control", comment: "")
        case let title where title.contains("énergie") || title.contains("energy"):
            return NSLocalizedString("home.goal.energy", comment: "")
        case let title where title.contains("émotions") || title.contains("emotions"):
            return NSLocalizedString("home.goal.emotions", comment: "")
        default:
            return NSLocalizedString("home.goal.default", comment: "")
        }
    }

    var body: some View {
        ZStack {
            // Galaxy animated background
            GalaxyBackgroundView(intensity: 1.0)

            if viewModel.isLoading {
                ProgressView()
                    .tint(Color.appTheme)
            } else {
                GeometryReader { _ in
                    VStack(spacing: 0) {
                        // Header Navigation (60px)
                        headerNavigation
                            .frame(height: 60)
                            .padding(.horizontal, AppConstants.Layout.paddingLarge)

                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 0) {
                                GeometryReader { geo in
                                    Color.clear.preference(
                                        key: ScrollOffsetPreferenceKey.self,
                                        value: geo.frame(in: .named("scroll")).minY
                                    )
                                }
                                .frame(height: 0)


                                // Motivational Message Card with parallax (slower)
                                MotivationalMessageCard(viewModel: motivationalVM)
                                    .padding(.top, 20)
                                    .offset(y: scrollOffset * 0.3)

                                // Avatar Progress Card - 66 days grid
                                AvatarProgressCard()
                                    .padding(.top, 20)
                                    .offset(y: scrollOffset * 0.4)

                                // Quick Actions - descendre with parallax (faster)
                                quickActionsRow
                                    .padding(.top, 20)
                                    .offset(y: scrollOffset * 0.6)

                                // Anti-Stress Button - rapprocher
                                antiStressButton
                                    .padding(.top, 16)

                                Spacer(minLength: 150)
                            }
                            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                                handleScroll(offset: value)
                            }
                        }
                        .coordinateSpace(name: "scroll")
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $viewModel.showAntiStressView) {
            AntiStressSituationView()
        }
        .fullScreenCover(isPresented: $showBreathingList) {
            BreathingListView()
        }
        .fullScreenCover(isPresented: $showMeditationList) {
            MeditationListView()
        }
        .fullScreenCover(isPresented: $showSoundsList) {
            SoundsListView()
        }
        .fullScreenCover(isPresented: $showJournal) {
            JournalHomeView()
        }
        .fullScreenCover(isPresented: $showSettings) {
            SettingsView()
        }
        .onAppear {
            // Refresh motivational message to pick up any name changes from profile edit
            motivationalVM.refreshMessage()

            // Initialize program start date if this is the first time HomeView is opened (after paywall)
            initializeProgramStartDateIfNeeded()
        }
    }

    // MARK: - Smart Scroll Handling

    private func handleScroll(offset: CGFloat) {
        // Calculate scroll velocity (direction and speed)
        scrollVelocity = offset - lastScrollOffset
        lastScrollOffset = offset
        scrollOffset = offset // Track for parallax

        // Threshold pour détecter un scroll significatif
        let scrollThreshold: CGFloat = 5

        // En haut de la page (offset proche de 0) → footer toujours visible
        if offset > -50 {
            withAnimation(.easeInOut(duration: AppConstants.Animation.standardDuration)) {
                isScrolling = false
            }
            return
        }

        // Scroll vers le bas (velocity negative) → masquer le footer
        if scrollVelocity < -scrollThreshold {
            scrollTimer?.invalidate()
            withAnimation(.easeOut(duration: 0.2)) {
                isScrolling = true
            }
        }
        // Scroll vers le haut (velocity positive) → afficher le footer
        else if scrollVelocity > scrollThreshold {
            scrollTimer?.invalidate()
            withAnimation(.easeInOut(duration: AppConstants.Animation.standardDuration)) {
                isScrolling = false
            }
        }
    }

    // MARK: - Header Navigation

    private var headerNavigation: some View {
        HStack {
            Text("CortiFree")
                .font(Font.Poppins.custom(.semiBold, size: AppConstants.FontSize.largeTitle))
                .foregroundColor(.white)

            Spacer()

            // Settings button
            Button(action: {
                HapticManager.light()
                showSettings = true
            }) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
            }
        }
    }

    // MARK: - Weekly Status

    private var weeklyStatusView: some View {
        let dayLetters = ["L", "Ma", "Me", "J", "V", "S", "D"]
        let displayLabels = ["L", "M", "M", "J", "V", "S", "D"]
        let weekDays = dayLetters.enumerated().map { index, _ in
            DayProgress(
                label: displayLabels[index],
                status: viewModel.weekProgress[index] ? .completed : .none,
                dayIndex: index
            )
        }

        return WeeklyStatusView(weekDays: weekDays) { selectedDay in
            // Toggle completion using the unique dayIndex
            viewModel.toggleDayCompletion(at: selectedDay.dayIndex)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, AppConstants.Layout.paddingLarge)
    }


    // MARK: - Quick Actions

    private var quickActionsRow: some View {
        HStack(spacing: 24) {
            QuickActionButtonNew(
                icon: "wind",
                title: NSLocalizedString("quickaction.breathing", comment: ""),
                hapticStyle: .light
            ) {
                showBreathingList = true
            }

            QuickActionButtonNew(
                icon: "figure.mind.and.body",
                title: NSLocalizedString("quickaction.meditation", comment: ""),
                hapticStyle: .light
            ) {
                showMeditationList = true
            }

            QuickActionButtonNew(
                icon: "waveform",
                title: NSLocalizedString("quickaction.sounds", comment: ""),
                hapticStyle: .light
            ) {
                showSoundsList = true
            }

            QuickActionButtonNew(
                icon: "book.fill",
                title: NSLocalizedString("quickaction.journal", comment: ""),
                hapticStyle: .light
            ) {
                showJournal = true
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, AppConstants.Layout.paddingLarge)
    }

    // MARK: - Routine Countdown

    private var routineCountdownView: some View {
        let time = timeRemaining

        return VStack(spacing: 0) {
            VStack(spacing: 12) {
                // First line: "Continue de briller"
                Text(NSLocalizedString(StringKeys.Home.keepShining, comment: ""))
                    .font(.custom("Poppins-SemiBold", size: 16))
                    .foregroundColor(.white)

                // Second line: "Tu atteindras [objectif] dans :"
                Text(String(format: NSLocalizedString(StringKeys.Home.routineCountdown, comment: ""), selectedRoutineTitle))
                    .font(.custom("Poppins-Regular", size: 14))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)

                // Time countdown in dark background
                VStack(spacing: 4) {
                    HStack(spacing: 8) {
                        // Days
                        TimeUnitView(value: time.days, unit: time.days > 1 ? NSLocalizedString(StringKeys.Common.days, comment: "") : NSLocalizedString(StringKeys.Common.day, comment: ""))

                        // Hours
                        TimeUnitView(value: time.hours, unit: time.hours > 1 ? NSLocalizedString(StringKeys.Common.hours, comment: "") : NSLocalizedString(StringKeys.Common.hour, comment: ""))
                    }

                    HStack(spacing: 8) {
                        // Minutes
                        TimeUnitView(value: time.minutes, unit: time.minutes > 1 ? NSLocalizedString(StringKeys.Common.minutes, comment: "") : NSLocalizedString(StringKeys.Common.minute, comment: ""))

                        // Seconds
                        TimeUnitView(value: time.seconds, unit: time.seconds > 1 ? NSLocalizedString(StringKeys.Common.seconds, comment: "") : NSLocalizedString(StringKeys.Common.second, comment: ""))
                    }
                }
                .padding(AppConstants.Layout.paddingMedium)
                .background(
                    RoundedRectangle(cornerRadius: AppConstants.Layout.cornerRadius)
                        .fill(AppConstants.Colors.darkBackground)
                )
                .shadow(color: Color.black.opacity(0.25), radius: 4, x: 1, y: 3)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 30)
    }

    // MARK: - Progress Level Bar
    // Removed - no longer using XP/Levels system

    // MARK: - Level Name Helper

    private func getLevelName(_ level: Int) -> String {
        switch level {
        case 1: return NSLocalizedString(StringKeys.Levels.beginnerSerene, comment: "")
        case 2: return NSLocalizedString(StringKeys.Levels.noviceCalm, comment: "")
        case 3: return NSLocalizedString(StringKeys.Levels.apprenticeZen, comment: "")
        case 4: return NSLocalizedString(StringKeys.Levels.practitionerAwakened, comment: "")
        case 5: return NSLocalizedString(StringKeys.Levels.confirmedMeditator, comment: "")
        case 6: return NSLocalizedString(StringKeys.Levels.expertCalm, comment: "")
        case 7: return NSLocalizedString(StringKeys.Levels.masterCalm, comment: "")
        case 8: return NSLocalizedString(StringKeys.Levels.peacefulGuru, comment: "")
        case 9: return NSLocalizedString(StringKeys.Levels.enlightenedSage, comment: "")
        case 10: return NSLocalizedString(StringKeys.Levels.immortalLegend, comment: "")
        default: return level > 10 ? NSLocalizedString(StringKeys.Levels.supremeMaster, comment: "") : NSLocalizedString(StringKeys.Levels.novice, comment: "")
        }
    }

    // MARK: - Anti-Stress Button

    private var antiStressButton: some View {
        Button(action: {
            viewModel.triggerAntiStress()
        }) {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white)

                Text(NSLocalizedString(StringKeys.Home.antiStressButton, comment: ""))
                    .font(.custom("Poppins-Medium", size: 16))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: 320, minHeight: 54)
            .background(
                RoundedRectangle(cornerRadius: 60)
                    .fill(Color(hex: "4A0000").opacity(0.66))
                    .overlay(
                        RoundedRectangle(cornerRadius: 60)
                            .stroke(Color(hex: "9B0003"), lineWidth: 2)
                    )
            )
            .modifier(AntiStressPulseModifier())
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, AppConstants.Layout.paddingLarge)
    }

    // MARK: - Program Start Date Initialization

    private func initializeProgramStartDateIfNeeded() {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        Task {
            do {
                // Try to fetch existing settings
                if let existingSettings = try await FirebaseManager.shared.fetchUserSettings(uid: userId) {
                    print("✅ User settings already exist, start date: \(existingSettings.programStartDate)")
                    return
                }

                // No settings found - this is first time after paywall
                // Fetch onboarding score from user document
                let userDoc = try await Firestore.firestore()
                    .collection("users")
                    .document(userId)
                    .getDocument()

                let onboardingScore = userDoc.data()?["onboardingScore"] as? Int ?? 50

                // Create settings with smart start date calculation
                let settings = UserSettings(
                    onboardingScore: onboardingScore
                )

                // Save settings
                try await FirebaseManager.shared.saveUserSettings(uid: userId, settings: settings)

                // Initialize habit tracking
                try await FirebaseManager.shared.initializeHabitTracking(uid: userId)

                print("✅ User settings initialized with start date: \(settings.programStartDate)")
            } catch {
                print("❌ Error initializing user settings: \(error)")
            }
        }
    }
}

// MARK: - Anti-Stress Pulse Modifier

struct AntiStressPulseModifier: ViewModifier {
    @State private var isPulsing = false

    func body(content: Content) -> some View {
        content
            .shadow(
                color: Color(red: 255/255, green: 68/255, blue: 68/255, opacity: isPulsing ? 0.7 : 0.4),
                radius: isPulsing ? 20 : 16,
                y: 4
            )
            .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isPulsing)
            .onAppear {
                isPulsing = true
            }
    }
}

// MARK: - Quick Action Button (New Design)

struct QuickActionButtonNew: View {
    let icon: String
    let title: String
    let hapticStyle: UIImpactFeedbackGenerator.FeedbackStyle
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: hapticStyle)
            generator.impactOccurred()
            action()
        }) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
                    .background(
                        Circle()
                            .fill(AppConstants.Colors.darkBackground)
                    )
                    .shadow(color: Color.black.opacity(0.25), radius: 4, x: 1, y: 3)

                Text(title)
                    .font(.custom("Poppins-Regular", size: 12))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(width: 70, height: 32)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(width: 70)
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity) {
            // Press action
        } onPressingChanged: { pressing in
            isPressed = pressing
        }
    }
}

// MARK: - Anti-Stress View

struct AntiStressView: View {
    @Environment(\.dismiss) var dismiss
    @State private var breatheIn = false
    @State private var scale: CGFloat = 1.0

    var body: some View {
        ZStack {
            // Galaxy animated background
            GalaxyBackgroundView(intensity: 0.8)

            VStack(spacing: 60) {
                VStack(spacing: 12) {
                    Text(NSLocalizedString(StringKeys.Home.breatheDeeply, comment: ""))
                        .font(.custom("Poppins-SemiBold", size: 28))
                        .foregroundColor(.white)

                    Text(breatheIn ? NSLocalizedString(StringKeys.Home.breatheIn, comment: "") : NSLocalizedString(StringKeys.Home.breatheOut, comment: ""))
                        .font(.custom("Poppins-Regular", size: 18))
                        .foregroundColor(AppConstants.Colors.textSecondary)
                }
                .padding(.top, 60)

                // Breathing orb
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(hex: "FF6B9D"),
                                Color(hex: "00E5FF"),
                                Color.appTheme
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 120
                        )
                    )
                    .frame(width: breatheIn ? 240 : 120, height: breatheIn ? 240 : 120)
                    .blur(radius: 20)
                    .scaleEffect(scale)
                    .animation(.easeInOut(duration: 4).repeatForever(autoreverses: true), value: breatheIn)
                    .onAppear {
                        breatheIn = true
                        withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                            scale = 1.1
                        }
                    }

                Spacer()

                Button(action: {
                    dismiss()
                }) {
                    Text(NSLocalizedString(StringKeys.Common.close, comment: ""))
                        .font(.custom("Poppins-Medium", size: 16))
                        .foregroundColor(Color.appTheme)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 30)
                                .stroke(Color.appTheme, lineWidth: 2)
                        )
                }
                .padding(.bottom, 60)
            }
        }
    }
}

// MARK: - Routine Details View

struct RoutineDetailsView: View {
    @Environment(\.dismiss) var dismiss
    let routineTitle: String
    let daysRemaining: Int

    // Scientific evidence data based on routine
    private var scientificEvidence: [(title: String, description: String)] {
        // For now, generic evidence. Can be customized per routine later
        return [
            (
                title: NSLocalizedString(StringKeys.Home.neuroplasticity, comment: ""),
                description: NSLocalizedString(StringKeys.Home.neuroplasticityDesc, comment: "")
            ),
            (
                title: "Réduction du cortisol",
                description: "Une pratique quotidienne de 10-20 minutes peut réduire les niveaux de cortisol de 25-30% en moyenne après 66 jours, selon une méta-analyse de 2019."
            ),
            (
                title: "Amélioration du système nerveux",
                description: "La pratique régulière active le système nerveux parasympathique, responsable de la relaxation et de la récupération, créant un équilibre durable."
            ),
            (
                title: "Effets durables",
                description: "Les bénéfices d'un programme de 66 jours persistent jusqu'à 6 mois après, créant de nouvelles habitudes neuronales automatiques."
            )
        ]
    }

    var body: some View {
        ZStack {
            // Galaxy background
            GalaxyBackgroundView(intensity: 0.8)

            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Text(NSLocalizedString(StringKeys.Home.why66Days, comment: ""))
                            .font(.custom("Poppins-Bold", size: 28))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)

                        Text(NSLocalizedString(StringKeys.Home.scientificEvidence, comment: ""))
                            .font(.custom("Poppins-Regular", size: 16))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.top, 40)

                    // Countdown reminder
                    VStack(spacing: 8) {
                        Text("Tu atteindras")
                            .font(.custom("Poppins-Regular", size: 14))
                            .foregroundColor(.white.opacity(0.7))

                        Text(routineTitle)
                            .font(.custom("Poppins-SemiBold", size: 20))
                            .foregroundColor(.white)

                        Text("dans")
                            .font(.custom("Poppins-Regular", size: 14))
                            .foregroundColor(.white.opacity(0.7))

                        HStack(spacing: 6) {
                            Text("\(daysRemaining)")
                                .font(.custom("Poppins-Bold", size: 36))
                                .foregroundColor(.white)

                            Text(daysRemaining > 1 ? NSLocalizedString(StringKeys.Common.days, comment: "") : NSLocalizedString(StringKeys.Common.day, comment: ""))
                                .font(.custom("Poppins-Medium", size: 18))
                                .foregroundColor(.white.opacity(0.9))
                                .offset(y: 6)
                        }
                    }
                    .padding(.vertical, 20)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: AppConstants.Layout.cornerRadiusLarge)
                            .fill(AppConstants.Colors.darkBackground.opacity(0.6))
                    )
                    .padding(.horizontal, 24)

                    // Scientific evidence cards
                    VStack(spacing: 16) {
                        ForEach(scientificEvidence.indices, id: \.self) { index in
                            EvidenceCard(
                                number: index + 1,
                                title: scientificEvidence[index].title,
                                description: scientificEvidence[index].description
                            )
                        }
                    }
                    .padding(.horizontal, 24)

                    // Close button
                    Button(action: {
                        dismiss()
                    }) {
                        Text(NSLocalizedString(StringKeys.Common.close, comment: ""))
                            .font(.custom("Poppins-Medium", size: 16))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(
                                LinearGradient(
                                    colors: [
                                        Color(hex: "73DE85"),
                                        Color(hex: "53D7D9")
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 27))
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
            }
        }
    }
}

// MARK: - Evidence Card

struct EvidenceCard: View {
    let number: Int
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Number badge
            Text("\(number)")
                .font(.custom("Poppins-Bold", size: 20))
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hex: "73DE85"),
                                    Color(hex: "53D7D9")
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )

            // Content
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.custom("Poppins-SemiBold", size: 16))
                    .foregroundColor(.white)

                Text(description)
                    .font(.custom("Poppins-Regular", size: 14))
                    .foregroundColor(.white.opacity(0.8))
                    .lineSpacing(4)
            }
        }
        .padding(AppConstants.Layout.spacingXLarge)
        .background(
            RoundedRectangle(cornerRadius: AppConstants.Layout.cornerRadius)
                .fill(AppConstants.Colors.darkBackground.opacity(0.4))
        )
    }
}

// MARK: - Time Unit View

struct TimeUnitView: View {
    let value: Int
    let unit: String

    var body: some View {
        VStack(spacing: 2) {
            Text("\(value)")
                .font(.custom("Poppins-Bold", size: 24))
                .foregroundColor(.white)

            Text(unit)
                .font(.custom("Poppins-Regular", size: 10))
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(minWidth: 70)
    }
}

// MARK: - Time Unit Row View (for vertical countdown)

struct TimeUnitRowView: View {
    let value: Int
    let unit: String

    var body: some View {
        HStack(spacing: 8) {
            Text("\(value)")
                .font(Font.Poppins.custom(.bold, size: 36))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, Color(hex: "B794F6")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 70, alignment: .trailing)

            Text(unit)
                .font(Font.Poppins.custom(.bold, size: 14))
                .foregroundColor(.white.opacity(0.8))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Time Unit Compact View (for horizontal countdown)

struct TimeUnitCompactView: View {
    let value: Int
    let unit: String

    var body: some View {
        VStack(spacing: 4) {
            Text("\(String(format: "%02d", value))")
                .font(Font.Poppins.custom(.bold, size: 28))
                .foregroundColor(.white)

            Text(unit.uppercased())
                .font(.custom("Poppins-Medium", size: 10))
                .foregroundColor(.white.opacity(0.6))
        }
    }
}

// MARK: - Scroll Offset Preference Key

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

#Preview {
    @Previewable @State var isScrolling = false
    @Previewable @State var scrollTimer: Timer? = nil

    HomeView(isScrolling: $isScrolling, scrollTimer: $scrollTimer)
        .environment(\.locale, Locale(identifier: "en"))
}
