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
    @State private var showPlanetSelector = false
    @State private var showOnboardingQuiz = false
    @State private var showSettings = false

    // Smart scroll detection
    @State private var lastScrollOffset: CGFloat = 0
    @State private var scrollVelocity: CGFloat = 0

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
                            .padding(.horizontal, 24)

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

                                // Central Orb - moved up
                                centralOrbSection
                                    .padding(.top, 0)

                                // Progress Level Bar - sous la planète
                                progressLevelBar
                                    .padding(.top, 0)

                                // Quick Actions - moved up
                                quickActionsRow
                                    .padding(.top, 16)

                                // Anti-Stress Button
                                antiStressButton
                                    .padding(.top, 30)

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
                                .padding(.horizontal, 34)
                                .padding(.top, 20)

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
        .sheet(isPresented: $showJournal) {
            JournalHomeView()
        }
        .sheet(isPresented: $showProgression) {
            ProgressionView()
        }
        .fullScreenCover(isPresented: $showSettings) {
            SettingsView()
        }
        .fullScreenCover(isPresented: $showOnboardingQuiz) {
            OnboardingFlowView()
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
        .padding(.horizontal, 24)
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
                .frame(width: 352, height: 352)
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
        .onTapGesture {
            HapticManager.medium()
            showPlanetSelector = true
        }
        .sheet(isPresented: $showPlanetSelector) {
            PlanetSelectorCarouselView()
        }
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
        .padding(.horizontal, 24)
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
        .padding(.horizontal, 24)
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
                            .fill(Color(hex: "130C57"))
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
                        .foregroundColor(Color(hex: "B0B8D4"))
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
