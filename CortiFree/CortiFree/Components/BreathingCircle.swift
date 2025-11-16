//
//  BreathingCircle.swift
//  CortiFree
//
//  Cercle animé pour les exercices de respiration
//

import SwiftUI

struct BreathingCircle: View {
    let planet: Planet
    let size: CGFloat  // 160 = petit (exhale), 260 = grand (inhale)
    let haloOpacity: Double

    private var isLarge: Bool {
        size > 200
    }

    // Couleur principale violette de l'app
    private var primaryColor: Color {
        Color(hex: "B794F6")
    }

    private var secondaryColor: Color {
        Color(hex: "D4B4FF")
    }

    var body: some View {
        ZStack {
            // Halo externe large et flou
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            primaryColor.opacity(0.4),
                            primaryColor.opacity(0.2),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: isLarge ? 220 : 140
                    )
                )
                .frame(
                    width: isLarge ? 440 : 280,
                    height: isLarge ? 440 : 280
                )
                .blur(radius: 40)

            // Halo moyen
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            primaryColor.opacity(haloOpacity),
                            primaryColor.opacity(0.15),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: isLarge ? 160 : 100
                    )
                )
                .frame(
                    width: isLarge ? 320 : 200,
                    height: isLarge ? 320 : 200
                )
                .blur(radius: 20)

            // Cercle principal avec anneaux
            mainCircleView
        }
    }

    private var mainCircleView: some View {
        ZStack {
            // Anneau externe décoratif
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            primaryColor.opacity(0.6),
                            secondaryColor.opacity(0.6),
                            primaryColor.opacity(0.6)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 3
                )
                .frame(width: size + 10, height: size + 10)
                .opacity(0.5)

            // Cercle principal avec gradient radial
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            secondaryColor.opacity(0.8),
                            primaryColor.opacity(0.9),
                            primaryColor.opacity(0.6)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: isLarge ? 130 : 80
                    )
                )
                .frame(width: size, height: size)
                .shadow(color: primaryColor.opacity(0.8), radius: 40, x: 0, y: 0)
                .shadow(color: primaryColor.opacity(0.6), radius: 20, x: 0, y: 0)

            // Anneau interne décoratif
            Circle()
                .stroke(
                    secondaryColor.opacity(0.4),
                    lineWidth: 2
                )
                .frame(width: size - 40, height: size - 40)

            // Points décoratifs qui tournent
            decorativeDotsView
        }
    }

    private var decorativeDotsView: some View {
        let radius = size / 2 + 5
        let angleOffset = haloOpacity * .pi * 2

        return ForEach(0..<8, id: \.self) { index in
            let angle = Double(index) * .pi / 4 + angleOffset
            let xPos = radius * cos(angle)
            let yPos = radius * sin(angle)

            Circle()
                .fill(Color.white.opacity(0.6))
                .frame(width: 4, height: 4)
                .offset(x: xPos, y: yPos)
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        BreathingCircle(
            planet: .earth,
            size: 260,
            haloOpacity: 0.5
        )
    }
}
