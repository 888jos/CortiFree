//
//  LevelProgressBarView.swift
//  CortiFree
//
//  Created by Claude on 22/10/2025.
//  Redesigned to match Figma specifications
//

import SwiftUI

struct LevelProgressBarView: View {
    let level: Int
    let levelName: String
    let percentage: Double // 0.0 to 1.0

    @State private var animatedPercentage: Double = 0
    @State private var isPulsing = false
    @State private var showLevelDetails = false

    var body: some View {
        VStack(spacing: 8) {
                // Titre compact et centré
                Text("Continue à briller")
                    .font(.custom("Poppins-SemiBold", size: 18))
                    .foregroundColor(.white)

                // Niveau et progression dans une ligne compacte
                VStack(spacing: 6) {
                    HStack(spacing: 8) {
                        // Badge niveau
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                                .foregroundColor(Color.appTheme)

                            Text("Nv. \(level)")
                                .font(.custom("Poppins-SemiBold", size: 13))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(Color.appTheme.opacity(0.15))
                        )

                        // Nom du niveau
                        Text(levelName)
                            .font(.custom("Poppins-Medium", size: 13))
                            .foregroundColor(Color(hex: "B0B8D4"))

                        Spacer()

                        // Pourcentage
                        Text("\(Int(animatedPercentage * 100))%")
                            .font(.custom("Poppins-SemiBold", size: 13))
                            .foregroundColor(Color.appTheme)
                            .monospacedDigit()

                        // Icône pour indiquer que c'est cliquable
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(Color.appTheme.opacity(0.6))
                    }

                    // Barre de progression fine
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Background
                            Capsule()
                                .fill(Color.white.opacity(0.1))
                                .frame(height: 6)

                            // Gradient fill
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.appTheme,
                                            Color.appThemeSecondary
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(
                                    width: geometry.size.width * animatedPercentage,
                                    height: 6
                                )
                                .animation(.easeInOut(duration: 0.4), value: animatedPercentage)
                        }
                    }
                    .frame(height: 6)
                }
                .padding(.horizontal, 13)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    Color.appTheme.opacity(0.3),
                                    lineWidth: 1
                                )
                        )
                )
            }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.4)) {
                animatedPercentage = percentage
            }
        }
        .onChange(of: percentage) { _, newValue in
            withAnimation(.easeInOut(duration: 0.4)) {
                animatedPercentage = newValue
            }

            if newValue >= 1.0 {
                triggerLevelUpEffects()
            }
        }
    }

    // MARK: - Level Up Effects

    private func triggerLevelUpEffects() {
        // Haptic feedback
        HapticManager.medium()

        // Pulse animation
        withAnimation(.easeInOut(duration: 0.3)) {
            isPulsing = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeInOut(duration: 0.3)) {
                isPulsing = false
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        // Dark background for preview
        LinearGradient(
            colors: [
                Color(hex: "1F0140"),
                Color(hex: "0B011B"),
                Color(hex: "01000C")
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()

        VStack(spacing: 40) {
            // Example 1: Low progress
            LevelProgressBarView(
                level: 3,
                levelName: "Apprenti Zen",
                percentage: 0.23
            )

            // Example 2: Mid progress
            LevelProgressBarView(
                level: 5,
                levelName: "Méditant Confirmé",
                percentage: 0.58
            )

            // Example 3: High progress
            LevelProgressBarView(
                level: 7,
                levelName: "Maître du Calme",
                percentage: 0.78
            )

            // Example 4: Nearly complete
            LevelProgressBarView(
                level: 9,
                levelName: "Sage Éclairé",
                percentage: 0.95
            )
        }
        .padding()
    }
}
