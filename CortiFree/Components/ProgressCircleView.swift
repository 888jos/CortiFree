//
//  ProgressCircleView.swift
//  CortiFree
//
//  Cercle de progression pour afficher le niveau et l'avancement
//

import SwiftUI

struct ProgressCircleView: View {
    let level: Level
    let currentXP: Int
    let progress: Double
    let size: CGFloat

    @StateObject private var planetSettings = PlanetSettings.shared

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: 12)
                .frame(width: size, height: size)

            // Progress circle
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    planetSettings.selectedPlanet.haloColor,
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 1.0), value: progress)

            // Content
            VStack(spacing: 4) {
                Text("Niveau \(level.id)")
                    .font(.custom("SF Pro Rounded-Bold", size: 24))
                    .foregroundColor(.white)

                Text(level.name)
                    .font(.custom("Poppins-Medium", size: 14))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.horizontal, 8)

                if Level.nextLevel(for: level) != nil {
                    let progressInfo = Level.progressToNextLevel(currentXP: currentXP, currentLevel: level)
                    Text("\(progressInfo.current) / \(progressInfo.required) XP")
                        .font(.custom("SF Pro Rounded-Regular", size: 12))
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.top, 2)
                } else {
                    Text("Niveau max")
                        .font(.custom("SF Pro Rounded-Regular", size: 12))
                        .foregroundColor(planetSettings.selectedPlanet.haloColor)
                        .padding(.top, 2)
                }
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        ProgressCircleView(
            level: Level.allLevels[6],
            currentXP: 2500,
            progress: 0.68,
            size: 180
        )
    }
}
