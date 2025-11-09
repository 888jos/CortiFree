//
//  ProgressionView.swift
//  CortiFree
//
//  Vue de progression avec système de niveaux
//

import SwiftUI

struct ProgressionView: View {
    @StateObject private var progressionManager = ProgressionManager.shared
    @StateObject private var planetSettings = PlanetSettings.shared
    @State private var selectedTab: ProgressionTab = .current

    enum ProgressionTab: String, CaseIterable {
        case current = "Mon niveau"
        case all = "Tous les niveaux"
    }

    var body: some View {
        ZStack {
            // Background
            GalaxyBackgroundView(intensity: 1.0)

            VStack(spacing: 0) {
                // Header
                VStack(spacing: 12) {
                    headerSection
                        .frame(height: 60)
                        .padding(.horizontal, 24)

                    // Tab selector
                    tabSelector
                        .padding(.horizontal, 24)
                }

                // Content
                ScrollView(showsIndicators: false) {
                    if selectedTab == .current {
                        currentLevelView
                            .padding(.top, 24)
                    } else {
                        allLevelsView
                            .padding(.top, 24)
                    }
                }
            }

            // Level up popup
            if progressionManager.showLevelUpPopup, let newLevel = progressionManager.newlyUnlockedLevel {
                LevelUpPopupView(level: newLevel, isPresented: $progressionManager.showLevelUpPopup)
            }
        }
    }

    // MARK: - Header
    private var headerSection: some View {
        HStack {
            Text("Progression")
                .font(.custom("SF Pro Rounded-Bold", size: 28))
                .foregroundColor(.white)

            Spacer()

            // XP indicator
            HStack(spacing: 6) {
                Image(systemName: "star.fill")
                    .font(.system(size: 14))
                    .foregroundColor(planetSettings.selectedPlanet.haloColor)

                Text("\(progressionManager.currentXP) XP")
                    .font(.custom("SF Pro Rounded-Semibold", size: 14))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.1))
            .cornerRadius(16)
        }
    }

    // MARK: - Tab Selector
    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(ProgressionTab.allCases, id: \.self) { tab in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedTab = tab
                    }
                    HapticManager.light()
                }) {
                    Text(tab.rawValue)
                        .font(.custom("Poppins-SemiBold", size: 14))
                        .foregroundColor(selectedTab == tab ? .white : .white.opacity(0.6))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selectedTab == tab ? planetSettings.selectedPlanet.haloColor : Color.clear)
                        )
                }

                if tab != ProgressionTab.allCases.last {
                    Rectangle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 1, height: 20)
                }
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.1))
        )
        .frame(width: 280)
    }

    // MARK: - Current Level View
    private var currentLevelView: some View {
        VStack(spacing: 24) {
            // Progress circle
            let progressInfo = progressionManager.progressInfo()
            ProgressCircleView(
                level: progressionManager.currentLevel,
                currentXP: progressionManager.currentXP,
                progress: progressInfo.percentage,
                size: 200
            )
            .padding(.top, 8)

            // Progress text
            if Level.nextLevel(for: progressionManager.currentLevel) != nil {
                Text("Tu es à \(Int(progressInfo.percentage * 100))% du niveau suivant")
                    .font(.custom("Poppins-Medium", size: 14))
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.horizontal, 32)
            } else {
                Text("Tu as atteint le niveau maximum !")
                    .font(.custom("Poppins-SemiBold", size: 16))
                    .foregroundColor(planetSettings.selectedPlanet.haloColor)
                    .padding(.horizontal, 32)
            }

            // XP Actions section
            xpActionsSection
                .padding(.top, 16)

            // Streak indicator
            streakSection
                .padding(.top, 8)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 100)
    }

    // MARK: - XP Actions Section
    private var xpActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Gagne de l'XP")
                .font(.custom("Poppins-Bold", size: 18))
                .foregroundColor(.white)
                .padding(.horizontal, 8)

            // Top 3 actions
            let topActions: [XPAction] = [.dailyMissionComplete, .meditationComplete, .breathingComplete]

            ForEach(topActions, id: \.self) { action in
                HStack(spacing: 12) {
                    // Icon
                    Image(systemName: action.iconName)
                        .font(.system(size: 18))
                        .foregroundColor(planetSettings.selectedPlanet.haloColor)
                        .frame(width: 32, height: 32)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)

                    // Description
                    Text(action.rawValue)
                        .font(.custom("Poppins-Medium", size: 14))
                        .foregroundColor(.white)

                    Spacer()

                    // XP value
                    Text("+\(action.xpValue) XP")
                        .font(.custom("SF Pro Rounded-Semibold", size: 14))
                        .foregroundColor(planetSettings.selectedPlanet.haloColor)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)
            }
        }
        .padding(.horizontal, 8)
    }

    // MARK: - Streak Section
    private var streakSection: some View {
        HStack(spacing: 12) {
            Image(systemName: "flame.fill")
                .font(.system(size: 20))
                .foregroundColor(.orange)

            VStack(alignment: .leading, spacing: 2) {
                Text("Série actuelle")
                    .font(.custom("Poppins-Medium", size: 12))
                    .foregroundColor(.white.opacity(0.7))

                Text("\(progressionManager.streakDays) jour\(progressionManager.streakDays > 1 ? "s" : "")")
                    .font(.custom("SF Pro Rounded-Bold", size: 16))
                    .foregroundColor(.white)
            }

            Spacer()

            if progressionManager.streakDays >= 3 {
                Text("Bonus activé !")
                    .font(.custom("Poppins-SemiBold", size: 12))
                    .foregroundColor(.orange)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.2))
                    .cornerRadius(8)
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
        .padding(.horizontal, 8)
    }

    // MARK: - All Levels View
    private var allLevelsView: some View {
        VStack(spacing: 16) {
            ForEach(Level.allLevels) { level in
                levelCard(level: level)
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 100)
    }

    // MARK: - Level Card
    private func levelCard(level: Level) -> some View {
        let isUnlocked = progressionManager.currentXP >= level.requiredXP
        let isCurrent = level.id == progressionManager.currentLevel.id

        return HStack(spacing: 16) {
            // Badge
            ZStack {
                Circle()
                    .fill(isUnlocked ? planetSettings.selectedPlanet.haloColor.opacity(0.2) : Color.white.opacity(0.05))
                    .frame(width: 50, height: 50)

                if isUnlocked {
                    Image(systemName: isCurrent ? "star.fill" : "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(planetSettings.selectedPlanet.haloColor)
                } else {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.3))
                }
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Niveau \(level.id)")
                        .font(.custom("SF Pro Rounded-Bold", size: 16))
                        .foregroundColor(isUnlocked ? .white : .white.opacity(0.5))

                    if isCurrent {
                        Text("Actuel")
                            .font(.custom("Poppins-SemiBold", size: 10))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(planetSettings.selectedPlanet.haloColor)
                            .cornerRadius(8)
                    }
                }

                Text(level.name)
                    .font(.custom("Poppins-Medium", size: 14))
                    .foregroundColor(isUnlocked ? planetSettings.selectedPlanet.haloColor : .white.opacity(0.4))

                Text(level.description)
                    .font(.custom("Poppins-Regular", size: 12))
                    .foregroundColor(isUnlocked ? .white.opacity(0.7) : .white.opacity(0.3))
                    .lineLimit(2)

                if level.id > 1 {
                    Text("\(level.requiredXP) XP requis")
                        .font(.custom("SF Pro Rounded-Medium", size: 11))
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.top, 2)
                }
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isCurrent ? Color.white.opacity(0.08) : Color.white.opacity(0.03))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isCurrent ? planetSettings.selectedPlanet.haloColor.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }
}

// MARK: - Preview
#Preview {
    ProgressionView()
}
