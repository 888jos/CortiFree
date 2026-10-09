//
//  HomeView.swift
//  CortiFree
//
//  Created by Claude on 22/10/2025.
//  Updated with exact design specs
//

import SwiftUI
import SuperwallKit

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @StateObject private var motivationalVM = MotivationalMessageViewModel()
    @Binding var isScrolling: Bool
    @Binding var scrollTimer: Timer?

    @State private var showBreathingList = false
    @State private var showMeditationList = false
    @State private var showSoundsList = false
    @State private var showJournal = false
    @State private var showDailyCheckIn = false
    @State private var showDailyCheckInShortcut = false
    @State private var showSettings = false
    @State private var showOnboarding = false
    @State private var showCustomPaywall = false
    @State private var showRatingSocialProofDebug = false
    @State private var showCelebrationsGalleryDebug = false
    @State private var currentTime = Date() // For countdown updates
    @State private var didInitProgram = false

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
            return LanguageManager.shared.localizedString(for: "home.goal.anxiety")
        case let title where title.contains("sommeil") || title.contains("sleep"):
            return LanguageManager.shared.localizedString(for: "home.goal.sleep")
        case let title where title.contains("concentration") || title.contains("focus"):
            return LanguageManager.shared.localizedString(for: "home.goal.concentration")
        case let title where title.contains("fatigue"):
            return LanguageManager.shared.localizedString(for: "home.goal.fatigue")
        case let title where title.contains("tension"):
            return LanguageManager.shared.localizedString(for: "home.goal.tension")
        case let title where title.contains("contrôle") || title.contains("control"):
            return LanguageManager.shared.localizedString(for: "home.goal.control")
        case let title where title.contains("énergie") || title.contains("energy"):
            return LanguageManager.shared.localizedString(for: "home.goal.energy")
        case let title where title.contains("émotions") || title.contains("emotions"):
            return LanguageManager.shared.localizedString(for: "home.goal.emotions")
        default:
            return LanguageManager.shared.localizedString(for: "home.goal.default")
        }
    }

    var body: some View {
        ZStack {
            // Galaxy animated background (calmer so glass surfaces read well)
            GalaxyBackgroundView(intensity: 0.75)

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

                                if showDailyCheckInShortcut {
                                    dailyCheckInShortcut
                                        .padding(.top, 14)
                                        .offset(y: scrollOffset * 0.35)
                                }

                                // Avatar Progress Card - 66 days grid
                                AvatarProgressCard()
                                    .padding(.top, 20)
                                    .offset(y: scrollOffset * 0.4)

                                // Quick Actions - descendre with parallax (faster)
                                quickActionsRow
                                    .padding(.top, 20)
                                    .offset(y: scrollOffset * 0.6)


                                // Anti-Stress Button
                                antiStressButton
                                    .padding(.top, 16)

                                #if DEBUG
                                VStack(spacing: 12) {
                                    Button(action: { showOnboarding = true }) {
                                        Text("🛠 Preview Onboarding")
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(.white.opacity(0.5))
                                    }
                                    Button(action: restartOnboardingFromBeginning) {
                                        Text("↻ Restart Onboarding From Start")
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(.white.opacity(0.5))
                                    }
                                    Button(action: {
                                        launchOnboardingFromAuthDebug()
                                    }) {
                                        Text("🛠 Current Flow From Auth")
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(.white.opacity(0.5))
                                    }
                                    Button(action: { showCustomPaywall = true }) {
                                        Text("💳 Custom Paywall")
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(.white.opacity(0.5))
                                    }
                                    Button(action: { showCelebrationsGalleryDebug = true }) {
                                        Text("🎉 Celebrations gallery")
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(.white.opacity(0.5))
                                    }
                                    Button(action: { showRatingSocialProofDebug = true }) {
                                        Text("⭐ Rating Social Proof")
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(.white.opacity(0.5))
                                    }
                                    Button(action: {
                                        triggerSuperwallDebugPlacement("campaign_trigger")
                                    }) {
                                        Text("🚀 Superwall campaign_trigger")
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(.white.opacity(0.5))
                                    }
                                    Button(action: {
                                        triggerSuperwallDebugPlacement("winback_cancelled_trial")
                                    }) {
                                        Text("↩️ Superwall winback_cancelled_trial")
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(.white.opacity(0.5))
                                    }
                                }
                                .padding(.top, 24)
                                #endif

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
        .sheet(isPresented: $showDailyCheckIn) {
            DailyCheckInView(targetDate: DailyCheckInService.shared.previousDay())
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(28)
        }
        .fullScreenCover(isPresented: $showSettings) {
            SettingsView()
        }
        .fullScreenCover(isPresented: $showCustomPaywall) {
            CustomPaywallView(
                onComplete: { showCustomPaywall = false },
                onPurchase: { _ in },
                onRestore: { showCustomPaywall = false }
            )
        }
        #if DEBUG
        // Debug-only: Onboarding preview (excluded from production builds)
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingV2FlowView(enablesLiveActivityWhenAlreadyCompleted: true)
        }
        .fullScreenCover(isPresented: $showCelebrationsGalleryDebug) {
            CelebrationsGalleryView()
        }
        .fullScreenCover(isPresented: $showRatingSocialProofDebug) {
            RatingSocialProofView {
                showRatingSocialProofDebug = false
            }
        }
        #endif
        .onAppear {
            // Refresh motivational message to pick up any name changes from profile edit
            motivationalVM.refreshMessage()

            // Initialize program start date ONCE (avoid repeated Firestore reads on tab switches)
            if !didInitProgram {
                didInitProgram = true
                initializeProgramStartDateIfNeeded()
            }

            // Track app session for rating and check day 7
            AppRatingService.shared.trackAppSession()
            let currentDay = AppConstants.Routine.totalDays - daysRemaining + 1
            if currentDay == 7 {
                AppRatingService.shared.trackProgramDay7()
            }

            refreshDailyCheckInShortcut()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("DailyCheckInSaved"))) { _ in
            showDailyCheckInShortcut = false
        }
    }

    // MARK: - Smart Scroll Handling

    private var dailyCheckInShortcut: some View {
        Button {
            HapticManager.light()
            showDailyCheckIn = true
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "checkmark.message.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 42, height: 42)
                    .background(
                        LinearGradient(
                            colors: [Color.appTheme, Color.appThemeSecondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: Circle()
                    )

                VStack(alignment: .leading, spacing: 3) {
                    Text("home.daily_checkin.title".localized)
                        .font(.custom("Poppins-SemiBold", size: 15))
                        .foregroundColor(.white)
                    Text("home.daily_checkin.subtitle".localized)
                        .font(.custom("Poppins-Regular", size: 12))
                        .foregroundColor(.white.opacity(0.62))
                }

                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color.appThemeSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .glassCard(cornerRadius: 18, tint: Color.appTheme, interactive: true)
        }
        .buttonStyle(ScaleButtonStyle())
        .padding(.horizontal, AppConstants.Layout.paddingLarge)
        .accessibilityLabel("home.daily_checkin.title".localized)
    }

    private func refreshDailyCheckInShortcut() {
        showDailyCheckInShortcut = DailyCheckInService.shared.shouldShowHomeShortcut()
    }

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

    #if DEBUG
    private func triggerSuperwallDebugPlacement(_ placement: String) {
        print("🧪 Triggering Superwall debug placement: \(placement)")
        Superwall.shared.register(placement: placement)
    }

    private func launchOnboardingFromAuthDebug() {
        let defaults = UserDefaults.standard
        defaults.set(true, forKey: "debugStartOnboardingFromAuth")
        defaults.removeObject(forKey: "onboardingCheckpoint")
        defaults.removeObject(forKey: "last_onboarding_checkpoint")
        defaults.set(false, forKey: "hasSeenPaywall")
        defaults.set(false, forKey: "saw_paywall_without_accepting")
        showOnboarding = true
    }

    private func restartOnboardingFromBeginning() {
        let defaults = UserDefaults.standard
        defaults.set(false, forKey: "onboardingV2Completed")
        defaults.removeObject(forKey: "onboardingCheckpoint")
        defaults.removeObject(forKey: "last_onboarding_checkpoint")
        defaults.set(false, forKey: "hasSeenPaywall")
        defaults.set(false, forKey: "saw_paywall_without_accepting")
        defaults.set(false, forKey: "onboarding_session_active")
        defaults.set(false, forKey: "debugSkipOnboardingToHome")
        OnboardingLiveActivityManager.shared.end()
        showOnboarding = true
    }
    #endif

    // MARK: - Header Navigation

    private var headerNavigation: some View {
        HStack {
            Text("CortiFree")
                .font(.faroSemiBold(AppConstants.FontSize.largeTitle))
                .foregroundColor(.white)

            Spacer()

            // Settings button
            Button(action: {
                HapticManager.light()
                showSettings = true
            }) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .glassCircle(interactive: true)
            .accessibleButton(label: AccessibilityLabels.settings, hint: LanguageManager.shared.localizedString(for: "accessibility.hint.open_settings"))
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
        GlassGroup(spacing: 22) {
        HStack(spacing: 22) {
            QuickActionButtonNew(
                icon: "wind",
                title: LanguageManager.shared.localizedString(for: "quickaction.breathing"),
                hapticStyle: .light
            ) {
                showBreathingList = true
            }

            QuickActionButtonNew(
                icon: "figure.mind.and.body",
                title: LanguageManager.shared.localizedString(for: "quickaction.meditation"),
                hapticStyle: .light
            ) {
                showMeditationList = true
            }

            QuickActionButtonNew(
                icon: "waveform",
                title: LanguageManager.shared.localizedString(for: "quickaction.sounds"),
                hapticStyle: .light
            ) {
                showSoundsList = true
            }

            QuickActionButtonNew(
                icon: "book.fill",
                title: LanguageManager.shared.localizedString(for: "quickaction.journal"),
                hapticStyle: .light
            ) {
                showJournal = true
            }
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
                Text(LanguageManager.shared.localizedString(for: StringKeys.Home.keepShining))
                    .font(.custom("Poppins-SemiBold", size: 16))
                    .foregroundColor(.white)

                // Second line: "Tu atteindras [objectif] dans :"
                Text(String(format: LanguageManager.shared.localizedString(for: StringKeys.Home.routineCountdown), selectedRoutineTitle))
                    .font(.custom("Poppins-Regular", size: 14))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)

                // Time countdown in dark background
                VStack(spacing: 4) {
                    HStack(spacing: 8) {
                        // Days
                        TimeUnitView(value: time.days, unit: time.days > 1 ? LanguageManager.shared.localizedString(for: StringKeys.Common.days) : LanguageManager.shared.localizedString(for: StringKeys.Common.day))

                        // Hours
                        TimeUnitView(value: time.hours, unit: time.hours > 1 ? LanguageManager.shared.localizedString(for: StringKeys.Common.hours) : LanguageManager.shared.localizedString(for: StringKeys.Common.hour))
                    }

                    HStack(spacing: 8) {
                        // Minutes
                        TimeUnitView(value: time.minutes, unit: time.minutes > 1 ? LanguageManager.shared.localizedString(for: StringKeys.Common.minutes) : LanguageManager.shared.localizedString(for: StringKeys.Common.minute))

                        // Seconds
                        TimeUnitView(value: time.seconds, unit: time.seconds > 1 ? LanguageManager.shared.localizedString(for: StringKeys.Common.seconds) : LanguageManager.shared.localizedString(for: StringKeys.Common.second))
                    }
                }
                .padding(AppConstants.Layout.paddingMedium)
                .glassCard(cornerRadius: AppConstants.Layout.cornerRadius + 4)
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
        case 1: return LanguageManager.shared.localizedString(for: StringKeys.Levels.beginnerSerene)
        case 2: return LanguageManager.shared.localizedString(for: StringKeys.Levels.noviceCalm)
        case 3: return LanguageManager.shared.localizedString(for: StringKeys.Levels.apprenticeZen)
        case 4: return LanguageManager.shared.localizedString(for: StringKeys.Levels.practitionerAwakened)
        case 5: return LanguageManager.shared.localizedString(for: StringKeys.Levels.confirmedMeditator)
        case 6: return LanguageManager.shared.localizedString(for: StringKeys.Levels.expertCalm)
        case 7: return LanguageManager.shared.localizedString(for: StringKeys.Levels.masterCalm)
        case 8: return LanguageManager.shared.localizedString(for: StringKeys.Levels.peacefulGuru)
        case 9: return LanguageManager.shared.localizedString(for: StringKeys.Levels.enlightenedSage)
        case 10: return LanguageManager.shared.localizedString(for: StringKeys.Levels.immortalLegend)
        default: return level > 10 ? LanguageManager.shared.localizedString(for: StringKeys.Levels.supremeMaster) : LanguageManager.shared.localizedString(for: StringKeys.Levels.novice)
        }
    }

    // MARK: - Anti-Stress Button

    private var antiStressButton: some View {
        ZStack {
            // Background violet glow
            Ellipse()
                .fill(Color(hex: "9333EA").opacity(0.25))
                .frame(maxWidth: 300, maxHeight: 40)
                .blur(radius: 28)
                .offset(y: 16)

            Button(action: {
                HapticManager.medium()
                viewModel.triggerAntiStress()
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)

                    Text(LanguageManager.shared.localizedString(for: StringKeys.Home.antiStressButton))
                        .font(.custom("Poppins-SemiBold", size: 16))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: 320, minHeight: 54)
                .contentShape(Capsule())
            }
            .buttonStyle(.glassPrimary(tint: Color(hex: "9333EA")))
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
                // Create settings with smart start date calculation
                let settings = UserSettings()

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
                    .responsiveFrame(width: 60, height: 60)
                    .glassCircle(interactive: true)

                Text(title)
                    .font(.custom("Poppins-Regular", size: 12))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .responsiveFrame(width: 70, height: 32)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .responsiveWidth(70)
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
                    Text(LanguageManager.shared.localizedString(for: StringKeys.Home.breatheDeeply))
                        .font(.faroSemiBold(28))
                        .foregroundColor(.white)

                    Text(breatheIn ? LanguageManager.shared.localizedString(for: StringKeys.Home.breatheIn) : LanguageManager.shared.localizedString(for: StringKeys.Home.breatheOut))
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
                    Text(LanguageManager.shared.localizedString(for: StringKeys.Common.close))
                        .font(.custom("Poppins-Medium", size: 16))
                        .foregroundColor(Color.appTheme)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.glassSecondary)
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
                title: LanguageManager.shared.localizedString(for: StringKeys.Home.neuroplasticity),
                description: LanguageManager.shared.localizedString(for: StringKeys.Home.neuroplasticityDesc)
            ),
            (
                title: "Réduction du cortisol",
                description: "Une pratique quotidienne de 10-20 minutes peut réduire les niveaux de cortisol en quelques semaines, selon une méta-analyse de 2019."
            ),
            (
                title: "Amélioration du système nerveux",
                description: "La pratique régulière active le système nerveux parasympathique, responsable de la relaxation et de la récupération, créant un équilibre durable."
            ),
            (
                title: "Effets durables",
                description: "Les bénéfices d'une pratique régulière durent plusieurs mois et créent de nouvelles habitudes neuronales automatiques."
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
                        Text(LanguageManager.shared.localizedString(for: StringKeys.Home.why66Days))
                            .font(.faroBold(28))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)

                        Text(LanguageManager.shared.localizedString(for: StringKeys.Home.scientificEvidence))
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
                            .font(.faroSemiBold(20))
                            .foregroundColor(.white)

                        Text("dans")
                            .font(.custom("Poppins-Regular", size: 14))
                            .foregroundColor(.white.opacity(0.7))

                        HStack(spacing: 6) {
                            Text("\(daysRemaining)")
                                .font(.faroBold(36))
                                .foregroundColor(.white)

                            Text(daysRemaining > 1 ? LanguageManager.shared.localizedString(for: StringKeys.Common.days) : LanguageManager.shared.localizedString(for: StringKeys.Common.day))
                                .font(.custom("Poppins-Medium", size: 18))
                                .foregroundColor(.white.opacity(0.9))
                                .offset(y: 6)
                        }
                    }
                    .padding(.vertical, 20)
                    .frame(maxWidth: .infinity)
                    .glassCard(cornerRadius: AppConstants.Layout.cornerRadiusLarge)
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
                        Text(LanguageManager.shared.localizedString(for: StringKeys.Common.close))
                            .font(.custom("Poppins-Medium", size: 16))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .contentShape(Capsule())
                    }
                    .buttonStyle(.glassPrimary)
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
                .font(.faroBold(20))
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
                    .font(.faroSemiBold(16))
                    .foregroundColor(.white)

                Text(description)
                    .font(.custom("Poppins-Regular", size: 14))
                    .foregroundColor(.white.opacity(0.8))
                    .lineSpacing(4)
            }
        }
        .padding(AppConstants.Layout.spacingXLarge)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(cornerRadius: AppConstants.Layout.cornerRadius + 4)
    }
}

// MARK: - Time Unit View

struct TimeUnitView: View {
    let value: Int
    let unit: String

    var body: some View {
        VStack(spacing: 2) {
            Text("\(value)")
                .font(.faroBold(24))
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
                .font(.faroBold(36))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, Color(hex: "B794F6")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 70, alignment: .trailing)

            Text(unit)
                .font(.faroSemiBold(14))
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
