//
//  LevelDetailsView.swift
//  CortiFree
//
//  Created by Claude on 24/10/2025.
//  Vue modale pour afficher les détails des niveaux et XP
//

import SwiftUI

struct LevelDetailsView: View {
    @Environment(\.dismiss) var dismiss
    let currentLevel: Int
    let currentPercentage: Double

    var body: some View {
        ZStack {
            // Galaxy background
            GalaxyBackgroundView(intensity: 0.8)

            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.custom("Poppins-SemiBold", size: 18))
                            .foregroundColor(.white.opacity(0.7))
                            .frame(width: 32, height: 32)
                            .background(
                                Circle()
                                    .fill(Color.white.opacity(0.1))
                            )
                    }

                    Spacer()

                    Text("Système de niveaux")
                        .font(.custom("Poppins-SemiBold", size: 18))
                        .foregroundColor(.white)

                    Spacer()

                    // Invisible pour équilibrer
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 32, height: 32)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 24)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Niveau actuel - Carte principale
                        currentLevelCard

                        // Prochain niveau
                        nextLevelCard

                        // Comment gagner des XP
                        xpGainSection

                        // Liste de tous les niveaux
                        allLevelsSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
    }

    // MARK: - Current Level Card

    private var currentLevelCard: some View {
        VStack(spacing: 16) {
            // Badge étoile
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.appTheme.opacity(0.3),
                                Color.appTheme.opacity(0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 50
                        )
                    )
                    .frame(width: 100, height: 100)

                Image(systemName: "star.fill")
                    .font(.system(size: 40))
                    .foregroundColor(Color.appTheme)
            }

            VStack(spacing: 8) {
                Text("Niveau \(currentLevel)")
                    .font(.custom("Poppins-Bold", size: 28))
                    .foregroundColor(.white)

                Text(getLevelName(currentLevel))
                    .font(.custom("Poppins-Medium", size: 16))
                    .foregroundColor(Color.appTheme)
            }

            // Progression
            VStack(spacing: 8) {
                HStack {
                    Text("Progression")
                        .font(.custom("Poppins-Regular", size: 13))
                        .foregroundColor(Color(hex: "B0B8D4"))

                    Spacer()

                    Text("\(Int(currentPercentage * 100))%")
                        .font(.custom("Poppins-SemiBold", size: 13))
                        .foregroundColor(Color.appTheme)
                        .monospacedDigit()
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 8)

                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color.appTheme, Color.appThemeSecondary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * currentPercentage, height: 8)
                    }
                }
                .frame(height: 8)
            }
            .padding(.top, 8)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.appTheme.opacity(0.3), lineWidth: 1)
                )
        )
    }

    // MARK: - Next Level Card

    private var nextLevelCard: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Prochain niveau")
                        .font(.custom("Poppins-SemiBold", size: 14))
                        .foregroundColor(Color(hex: "B0B8D4"))

                    Text("Niveau \(currentLevel + 1)")
                        .font(.custom("Poppins-Bold", size: 20))
                        .foregroundColor(.white)

                    Text(getLevelName(currentLevel + 1))
                        .font(.custom("Poppins-Medium", size: 14))
                        .foregroundColor(Color.appTheme)
                }

                Spacer()

                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 36))
                    .foregroundColor(Color.appTheme.opacity(0.5))
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }

    // MARK: - XP Gain Section

    private var xpGainSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Comment gagner de l'XP")
                .font(.custom("Poppins-SemiBold", size: 16))
                .foregroundColor(.white)

            VStack(spacing: 12) {
                XPGainRow(icon: "wind", title: "Exercice de respiration", xp: "+10 XP")
                XPGainRow(icon: "figure.mind.and.body", title: "Méditation complétée", xp: "+15 XP")
                XPGainRow(icon: "waveform", title: "Session de sons", xp: "+8 XP")
                XPGainRow(icon: "book.fill", title: "Entrée dans le journal", xp: "+12 XP")
                XPGainRow(icon: "checkmark.circle.fill", title: "Tâche complétée", xp: "+5 XP")
                XPGainRow(icon: "flame.fill", title: "Série quotidienne", xp: "+20 XP")
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }

    // MARK: - All Levels Section

    private var allLevelsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Tous les niveaux")
                .font(.custom("Poppins-SemiBold", size: 16))
                .foregroundColor(.white)

            VStack(spacing: 10) {
                ForEach(1...10, id: \.self) { level in
                    LevelListRow(
                        level: level,
                        levelName: getLevelName(level),
                        isCurrent: level == currentLevel,
                        isCompleted: level < currentLevel
                    )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }

    // MARK: - Helper

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
}

// MARK: - XP Gain Row

struct XPGainRow: View {
    let icon: String
    let title: String
    let xp: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(Color.appTheme)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(Color.appTheme.opacity(0.15))
                )

            Text(title)
                .font(.custom("Poppins-Regular", size: 14))
                .foregroundColor(.white)

            Spacer()

            Text(xp)
                .font(.custom("Poppins-SemiBold", size: 13))
                .foregroundColor(Color.appTheme)
                .monospacedDigit()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Level List Row

struct LevelListRow: View {
    let level: Int
    let levelName: String
    let isCurrent: Bool
    let isCompleted: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Indicateur de statut
            ZStack {
                Circle()
                    .fill(
                        isCurrent ? Color.appTheme.opacity(0.2) :
                        isCompleted ? Color.appTheme.opacity(0.1) :
                        Color.white.opacity(0.05)
                    )
                    .frame(width: 36, height: 36)

                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.custom("Poppins-Bold", size: 14))
                        .foregroundColor(Color.appTheme)
                } else if isCurrent {
                    Text("\(level)")
                        .font(.custom("Poppins-Bold", size: 14))
                        .foregroundColor(Color.appTheme)
                } else {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.3))
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Niveau \(level)")
                    .font(.custom("Poppins-SemiBold", size: 14))
                    .foregroundColor(isCurrent ? .white : .white.opacity(0.7))

                Text(levelName)
                    .font(.custom("Poppins-Regular", size: 12))
                    .foregroundColor(isCurrent ? Color.appTheme : Color(hex: "B0B8D4"))
            }

            Spacer()

            if isCurrent {
                Image(systemName: "star.fill")
                    .font(.system(size: 16))
                    .foregroundColor(Color.appTheme)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isCurrent ? Color.appTheme.opacity(0.1) : Color.clear)
        )
    }
}

#Preview {
    LevelDetailsView(currentLevel: 5, currentPercentage: 0.65)
}
