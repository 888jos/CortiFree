//
//  HomeView.swift
//  CortiFree
//
//  Created by Claude on 22/10/2025.
//  Updated with exact design specs
//

import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @StateObject private var planetSettings = PlanetSettings.shared
    @StateObject private var progressionManager = ProgressionManager.shared
    @Binding var isScrolling: Bool
    @Binding var scrollTimer: Timer?

    @State private var showBreathingList = false
    @State private var showMeditationList = false
    @State private var showSoundsList = false
    @State private var showJournal = false
    @State private var showProgression = false
    @State private var haloOpacity: Double = 0.35
    @State private var planetScale: CGFloat = 1.0
    @State private var showOnboardingQuiz = false
    @State private var showSettings = false
    @State private var showRoutineDetails = false
    @State private var currentTime = Date() // For countdown updates

    // TEST: New task system
    @State private var showDailyProgram = false
    @State private var showOnboardingV2 = false

    // Smart scroll detection
    @State private var lastScrollOffset: CGFloat = 0
    @State private var scrollVelocity: CGFloat = 0

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


                                // Subheader - Weekly Status
                                weeklyStatusView
                                    .padding(.top, 16)

                                // Planet + Countdown Combined
                                planetWithCountdownSection
                                    .padding(.top, 0)

                                // Quick Actions - descendre
                                quickActionsRow
                                    .padding(.top, 10)

                                // Anti-Stress Button - rapprocher
                                antiStressButton
                                    .padding(.top, 16)

                                // TEST: Onboarding Quiz Button (temporary)
                                Button(action: {
                                    showOnboardingQuiz = true
                                }) {
                                    Text("🧪 TEST: Onboarding Quiz")
                                        .font(.custom("Poppins-SemiBold", size: 16))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 54)
                                        .background(
                                            LinearGradient(
                                                colors: [Color(hex: "73DE85"), Color(hex: "53D7D9")],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 27))
                                }
                                .padding(.horizontal, AppConstants.Layout.paddingXLarge)
                                .padding(.top, 20)

                                // TEST: Daily Program Button
                                Button(action: {
                                    HapticManager.light()
                                    showDailyProgram = true
                                }) {
                                    Text("📅 TEST: Programme du Jour")
                                        .font(.custom("Poppins-SemiBold", size: 16))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 54)
                                        .background(
                                            LinearGradient(
                                                colors: [Color(hex: "4A90E2"), Color(hex: "9B59B6")],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 27))
                                }
                                .padding(.horizontal, AppConstants.Layout.paddingXLarge)
                                .padding(.top, 16)

                                Spacer(minLength: 40)
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
        .sheet(isPresented: $viewModel.showAntiStressView) {
            AntiStressSituationView()
        }
        .sheet(isPresented: $showBreathingList) {
            BreathingListView()
        }
        .sheet(isPresented: $showMeditationList) {
            MeditationListView()
        }
        .sheet(isPresented: $showSoundsList) {
            SoundsListView()
        }
        .fullScreenCover(isPresented: $showJournal) {
            JournalHomeView()
        }
        .sheet(isPresented: $showProgression) {
            ProgressionView()
        }
        .sheet(isPresented: $showRoutineDetails) {
            RoutineDetailsView(
                routineTitle: selectedRoutineTitle,
                daysRemaining: daysRemaining
            )
        }
        .fullScreenCover(isPresented: $showSettings) {
            SettingsView()
        }
        .fullScreenCover(isPresented: $showOnboardingQuiz) {
            OnboardingFlowView()
        }
        .sheet(isPresented: $showDailyProgram) {
            NavigationView {
                SimplifiedDailyProgramView(
                    routine: RoutinePlan.allPlans[0], // Master Mind
                    dayNumber: 1
                )
            }
        }
        .fullScreenCover(isPresented: $showOnboardingV2) {
            OnboardingFlowView()
        }
        .overlay(alignment: .bottom) {
            // TEST: Bouton Onboarding V2
            Button(action: {
                showOnboardingV2 = true
            }) {
                Text("Test Onboarding V2")
                    .font(.custom(AppConstants.Fonts.semiBold, size: 12))
                    .foregroundColor(.white)
                    .padding(.horizontal, AppConstants.Layout.paddingMedium)
                    .padding(.vertical, AppConstants.Layout.paddingSmall)
                    .background(
                        RoundedRectangle(cornerRadius: AppConstants.Layout.cornerRadiusSmall)
                            .fill(AppConstants.Colors.violetDark.opacity(0.8))
                    )
            }
            .padding(.bottom, 100)
        }
    }

    // MARK: - Smart Scroll Handling

    private func handleScroll(offset: CGFloat) {
        // Calculate scroll velocity (direction and speed)
        scrollVelocity = offset - lastScrollOffset
        lastScrollOffset = offset

        // Threshold pour détecter un scroll significatif
        let scrollThreshold: CGFloat = 5

        // En haut de la page (offset proche de 0) → footer toujours visible
        if offset > -50 {
            withAnimation(.easeOut(duration: 0.3)) {
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
            withAnimation(.easeIn(duration: 0.3)) {
                isScrolling = false
            }
        }
    }

    // MARK: - Header Navigation

    private var headerNavigation: some View {
        HStack {
            Text("CortiFree")
                .font(.custom("SF Pro Rounded-Semibold", size: 32))
                .foregroundColor(.white)

            Spacer()

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

    // MARK: - Central Orb

    private var centralOrbSection: some View {
        // Selected planet with colored halo
        ZStack {
            // Halo coloré personnalisé avec animation d'opacité
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            planetSettings.selectedPlanet.haloColor.opacity(haloOpacity),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 160,
                        endRadius: 185
                    )
                )
                .frame(width: 240, height: 240)
                .onAppear {
                    // Animation d'opacité du halo
                    withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
                        haloOpacity = 0.55
                    }
                }

            // Planète avec animation de pulse subtile
            Image(planetSettings.selectedPlanet.imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 352, height: 352) // Taille originale restaurée
                .shadow(color: planetSettings.selectedPlanet.haloColor.opacity(0.5), radius: 25)
                .scaleEffect(planetScale)
                .onAppear {
                    // Animation de pulse de la planète (très subtile)
                    withAnimation(.easeInOut(duration: 5.0).repeatForever(autoreverses: true)) {
                        planetScale = 1.03
                    }
                }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Planet with Countdown Section

    private var planetWithCountdownSection: some View {
        TimelineView(.periodic(from: Date(), by: 1.0)) { timeline in
            GeometryReader { geometry in
                let time = calculateTimeRemaining(at: timeline.date)

                ZStack(alignment: .leading) {
                    // Planet on the right side (60% visible, 40% cut off)
                    ZStack {
                        // Halo - synchronisé avec la planète
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        planetSettings.selectedPlanet.haloColor.opacity(haloOpacity),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 160,
                                    endRadius: 185
                                )
                            )
                            .frame(width: 240, height: 240)
                            .scaleEffect(planetScale) // Suit l'échelle de la planète
                            .onAppear {
                                withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
                                    haloOpacity = 0.55
                                }
                            }

                        // Planet - taille augmentée x1.1, pulse de 1.0 à 1.08
                        Image(planetSettings.selectedPlanet.imageName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 387, height: 387) // 352 * 1.1 = 387
                            .shadow(color: planetSettings.selectedPlanet.haloColor.opacity(0.5), radius: 25)
                            .scaleEffect(planetScale)
                            .onAppear {
                                withAnimation(.easeInOut(duration: 5.0).repeatForever(autoreverses: true)) {
                                    planetScale = 1.08
                                }
                            }
                    }
                    .offset(x: geometry.size.width * 0.45) // Décalage à droite pour que 60% soit visible

                    // Countdown on the left side
                    VStack(alignment: .leading, spacing: 0) {
                        // "Continue de briller" - au plus haut de la planète visible
                        Text("Continue de briller")
                            .font(.custom("SF Pro Rounded-Bold", size: 22))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white, Color(hex: "B794F6")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .padding(.top, 50) // Baissé de 15px

                        // Phrase personnalisée selon l'objectif
                        Text(personalizedPhrase)
                            .font(.custom("SF Pro Rounded-Bold", size: 16))
                            .foregroundColor(.white.opacity(0.8))
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 8)

                        Spacer()

                        // Countdown vertical (sans fond) - au plus bas de la planète visible
                        VStack(alignment: .leading, spacing: 8) {
                            TimeUnitRowView(value: time.days, unit: time.days > 1 ? "jours" : "jour")
                            TimeUnitRowView(value: time.hours, unit: time.hours > 1 ? "heures" : "heure")
                            TimeUnitRowView(value: time.minutes, unit: time.minutes > 1 ? "minutes" : "minute")
                            TimeUnitRowView(value: time.seconds, unit: time.seconds > 1 ? "secondes" : "seconde")
                        }
                        .padding(.bottom, 50) // Baissé de 15px vers le bas
                    }
                    .frame(maxWidth: geometry.size.width * 0.5, alignment: .leading) // Aligné à gauche
                    .frame(height: 387) // Hauteur de l'image de la planète
                    .padding(.leading, 24)
                    .onTapGesture {
                        HapticManager.light()
                        showRoutineDetails = true
                    }
                }
            }
            .frame(height: 352)
        }
    }

    // Helper function to calculate time remaining
    private func calculateTimeRemaining(at date: Date) -> (days: Int, hours: Int, minutes: Int, seconds: Int) {
        let endDate = Calendar.current.date(byAdding: .day, value: AppConstants.Routine.totalDays, to: routineStartDate) ?? date
        let components = Calendar.current.dateComponents([.day, .hour, .minute, .second], from: date, to: endDate)
        return (
            max(0, components.day ?? 0),
            max(0, components.hour ?? 0),
            max(0, components.minute ?? 0),
            max(0, components.second ?? 0)
        )
    }

    // MARK: - Quick Actions

    private var quickActionsRow: some View {
        HStack(spacing: 24) {
            QuickActionButtonNew(
                icon: "wind",
                title: "Respiration",
                hapticStyle: .light
            ) {
                showBreathingList = true
            }

            QuickActionButtonNew(
                icon: "figure.mind.and.body",
                title: "Méditation",
                hapticStyle: .light
            ) {
                showMeditationList = true
            }

            QuickActionButtonNew(
                icon: "waveform",
                title: "Sons",
                hapticStyle: .light
            ) {
                showSoundsList = true
            }

            QuickActionButtonNew(
                icon: "book.fill",
                title: "Journal",
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

        return Button(action: {
            HapticManager.light()
            showRoutineDetails = true
        }) {
            VStack(spacing: 12) {
                // First line: "Continue de briller"
                Text("Continue de briller")
                    .font(.custom("Poppins-SemiBold", size: 16))
                    .foregroundColor(.white)

                // Second line: "Tu atteindras [objectif] dans :"
                Text("Tu atteindras \(selectedRoutineTitle) dans :")
                    .font(.custom("Poppins-Regular", size: 14))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)

                // Time countdown in dark background
                VStack(spacing: 4) {
                    HStack(spacing: 8) {
                        // Days
                        TimeUnitView(value: time.days, unit: time.days > 1 ? "jours" : "jour")

                        // Hours
                        TimeUnitView(value: time.hours, unit: time.hours > 1 ? "heures" : "heure")
                    }

                    HStack(spacing: 8) {
                        // Minutes
                        TimeUnitView(value: time.minutes, unit: time.minutes > 1 ? "minutes" : "minute")

                        // Seconds
                        TimeUnitView(value: time.seconds, unit: time.seconds > 1 ? "secondes" : "seconde")
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
        .buttonStyle(PlainButtonStyle())
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 30)
    }

    // MARK: - Progress Level Bar

    private var progressLevelBar: some View {
        let progressInfo = progressionManager.progressInfo()

        return Button(action: {
            HapticManager.light()
            showProgression = true
        }) {
            LevelProgressBarView(
                level: progressionManager.currentLevel.id,
                levelName: progressionManager.currentLevel.name,
                percentage: progressInfo.percentage
            )
        }
        .buttonStyle(PlainButtonStyle())
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 30)
    }

    // MARK: - Level Name Helper

    private func getLevelName(_ level: Int) -> String {
        switch level {
        case 1: return "Débutant Serein"
        case 2: return "Novice Apaisé"
        case 3: return "Apprenti Zen"
        case 4: return "Pratiquant Éveillé"
        case 5: return "Méditant Confirmé"
        case 6: return "Expert du Calme"
        case 7: return "Maître du Calme"
        case 8: return "Guru Paisible"
        case 9: return "Sage Éclairé"
        case 10: return "Légende Immortelle"
        default: return level > 10 ? "Maître Suprême" : "Novice"
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

                Text("Bouton Anti-Stress")
                    .font(.custom("Poppins-Medium", size: 16))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: 336, minHeight: 54)
            .background(
                RoundedRectangle(cornerRadius: 60)
                    .fill(Color(hex: "4A0000").opacity(0.66))
                    .overlay(
                        RoundedRectangle(cornerRadius: 60)
                            .stroke(Color(hex: "9B0003"), lineWidth: 2)
                    )
            )
            .shadow(color: Color(red: 255/255, green: 68/255, blue: 68/255, opacity: 0.4), radius: 16, y: 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, AppConstants.Layout.paddingLarge)
    }
}

// MARK: - Quick Action Button (New Design)

struct QuickActionButtonNew: View {
    let icon: String
    let title: String
    let hapticStyle: UIImpactFeedbackGenerator.FeedbackStyle
    let action: () -> Void

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
                    Text("Respirez profondément")
                        .font(.custom("Poppins-SemiBold", size: 28))
                        .foregroundColor(.white)

                    Text(breatheIn ? "Inspirez..." : "Expirez...")
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
                    Text("Fermer")
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
                title: "Neuroplasticité cérébrale",
                description: "Des études montrent que 66 jours de pratique régulière suffisent pour observer des changements structurels dans le cerveau, notamment dans l'hippocampe et le cortex préfrontal."
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
                        Text("Pourquoi 66 jours ?")
                            .font(.custom("Poppins-Bold", size: 28))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)

                        Text("Les preuves scientifiques")
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

                            Text(daysRemaining > 1 ? "jours" : "jour")
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
                        Text("Fermer")
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
                .font(.custom("SF Pro Rounded-Bold", size: 36))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, Color(hex: "B794F6")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 70, alignment: .trailing)

            Text(unit)
                .font(.custom("SF Pro Rounded-Bold", size: 14))
                .foregroundColor(.white.opacity(0.8))
                .frame(maxWidth: .infinity, alignment: .leading)
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
}
