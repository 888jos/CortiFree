//
//  GalaxyBackgroundView.swift
//  CortiFree
//
//  Created by Claude on 22/10/2025.
//  Animated galaxy background with twinkling stars and shooting stars
//

import SwiftUI

// MARK: - Galaxy Background View

struct GalaxyBackgroundView: View {
    let intensity: Double

    @State private var stars: [Star] = []
    @State private var shootingStars: [ShootingStar] = []

    init(intensity: Double = 1.0) {
        self.intensity = max(0.5, min(2.0, intensity))
    }

    var body: some View {
        ZStack {
            // Deep space gradient background
            LinearGradient(
                colors: [
                    Color(hex: "1F0140"), // Top - Purple deep
                    Color(hex: "0B011B"), // Middle - Very dark purple
                    Color(hex: "01000C")  // Bottom - Almost black
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Stars layer
            TimelineView(.animation) { timeline in
                Canvas { context, size in
                    let currentTime = timeline.date.timeIntervalSinceReferenceDate

                    // Draw static and twinkling stars
                    for star in stars {
                        let opacity = star.calculateOpacity(at: currentTime)
                        let position = star.calculatePosition(at: currentTime, in: size)

                        let rect = CGRect(
                            x: position.x - star.size / 2,
                            y: position.y - star.size / 2,
                            width: star.size,
                            height: star.size
                        )

                        context.fill(
                            Path(ellipseIn: rect),
                            with: .color(.white.opacity(opacity))
                        )
                    }

                    // Draw shooting stars
                    for shootingStar in shootingStars {
                        if let path = shootingStar.calculatePath(at: currentTime, in: size) {
                            let opacity = shootingStar.calculateOpacity(at: currentTime)

                            context.stroke(
                                path,
                                with: .color(.white.opacity(opacity)),
                                lineWidth: shootingStar.thickness
                            )
                        }
                    }
                }
            }
            .ignoresSafeArea()
        }
        .onAppear {
            generateStars()
            scheduleShootingStars()
        }
    }

    // MARK: - Star Generation

    private func generateStars() {
        let baseCount = 150
        let starCount = Int(Double(baseCount) * intensity)

        stars = (0..<starCount).map { index in
            Star(
                id: index,
                x: Double.random(in: 0...1),
                y: Double.random(in: 0...1),
                size: Double.random(in: 0.5...2.5),
                twinkleDuration: Double.random(in: 2...4),
                twinkling: Bool.random(),
                driftSpeed: Double.random(in: 0.0001...0.0003),
                driftAngle: Double.random(in: 0...(2 * .pi)),
                phaseOffset: Double.random(in: 0...(2 * .pi))
            )
        }
    }

    // MARK: - Shooting Stars

    private func scheduleShootingStars() {
        Timer.scheduledTimer(withTimeInterval: Double.random(in: 10...15), repeats: true) { _ in
            addShootingStar()
        }

        // Add first shooting star after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 3...8)) {
            addShootingStar()
        }
    }

    private func addShootingStar() {
        let shootingStar = ShootingStar(
            startTime: Date().timeIntervalSinceReferenceDate,
            duration: Double.random(in: 0.3...0.6), // Beaucoup plus rapide !
            startX: Double.random(in: 0.3...0.7),
            startY: Double.random(in: 0.1...0.3),
            angle: Double.random(in: .pi/4...(.pi/2.5)), // 45° to 72° (plus naturel)
            length: Double.random(in: 25...45), // Plus court !
            thickness: Double.random(in: 0.8...1.2) // Plus fin
        )

        shootingStars.append(shootingStar)

        // Remove after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + shootingStar.duration + 0.5) {
            shootingStars.removeAll { $0.id == shootingStar.id }
        }
    }
}

// MARK: - Star Model

private struct Star {
    let id: Int
    let x: Double // Normalized 0-1
    let y: Double // Normalized 0-1
    let size: Double
    let twinkleDuration: Double
    let twinkling: Bool
    let driftSpeed: Double
    let driftAngle: Double
    let phaseOffset: Double

    func calculateOpacity(at time: TimeInterval) -> Double {
        guard twinkling else { return 0.8 }

        let cycle = (time + phaseOffset) / twinkleDuration
        let phase = cycle.truncatingRemainder(dividingBy: 1.0)

        // Smooth sine wave for twinkling
        let opacity = 0.3 + 0.5 * (1 + sin(phase * 2 * .pi)) / 2
        return opacity
    }

    func calculatePosition(at time: TimeInterval, in size: CGSize) -> CGPoint {
        // Very subtle parallax drift
        let driftX = cos(driftAngle) * driftSpeed * time
        let driftY = sin(driftAngle) * driftSpeed * time

        // Ensure values stay in 0-1 range (wrapping)
        var finalX = (x + driftX).truncatingRemainder(dividingBy: 1.0)
        var finalY = (y + driftY).truncatingRemainder(dividingBy: 1.0)

        // Handle negative remainders
        if finalX < 0 { finalX += 1.0 }
        if finalY < 0 { finalY += 1.0 }

        return CGPoint(
            x: finalX * size.width,
            y: finalY * size.height
        )
    }
}

// MARK: - Shooting Star Model

private struct ShootingStar: Identifiable {
    let id = UUID()
    let startTime: TimeInterval
    let duration: TimeInterval
    let startX: Double
    let startY: Double
    let angle: Double
    let length: Double
    let thickness: Double

    var startPoint: CGPoint {
        CGPoint(x: startX, y: startY)
    }

    var endPoint: CGPoint {
        CGPoint(
            x: startX + cos(angle) * (length / 1000),
            y: startY + sin(angle) * (length / 1000)
        )
    }

    func calculatePath(at time: TimeInterval, in size: CGSize) -> Path? {
        let elapsed = time - startTime

        guard elapsed >= 0 && elapsed <= duration else { return nil }

        let progress = elapsed / duration

        // Mouvement rapide et fluide - beaucoup plus de distance parcourue !
        let travelDistance = 0.8 // 80% de l'écran parcouru
        let currentX = startX + cos(angle) * progress * travelDistance
        let currentY = startY + sin(angle) * progress * travelDistance

        // Tête de l'étoile filante
        let headPoint = CGPoint(
            x: currentX * size.width,
            y: currentY * size.height
        )

        // Queue de l'étoile filante (beaucoup plus courte maintenant)
        let tailLength = length / size.width
        let tailPoint = CGPoint(
            x: (currentX - cos(angle) * tailLength) * size.width,
            y: (currentY - sin(angle) * tailLength) * size.height
        )

        var path = Path()
        path.move(to: headPoint)
        path.addLine(to: tailPoint)

        return path
    }

    func calculateOpacity(at time: TimeInterval) -> Double {
        let elapsed = time - startTime

        guard elapsed >= 0 && elapsed <= duration else { return 0 }

        let progress = elapsed / duration

        // Fade naturel: apparition rapide, disparition rapide
        if progress < 0.15 {
            // Fade in très rapide (15% du temps)
            return progress / 0.15
        } else if progress > 0.75 {
            // Fade out rapide (25% du temps)
            return 1.0 - ((progress - 0.75) / 0.25)
        } else {
            // Pleine intensité au milieu
            return 1.0
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        GalaxyBackgroundView(intensity: 1.0)

        VStack {
            Text("CortiFree")
                .font(.custom("SF Pro Rounded-Bold", size: 48))
                .foregroundColor(.white)

            Text("Galaxy Background")
                .font(.custom("Poppins-Regular", size: 18))
                .foregroundColor(.white.opacity(0.7))
        }
    }
}
