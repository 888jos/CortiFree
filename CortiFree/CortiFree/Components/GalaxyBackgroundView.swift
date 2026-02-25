//
//  GalaxyBackgroundView.swift
//  CortiFree
//
//  Created by Claude on 22/10/2025.
//  Optimized galaxy background with static stars and lightweight twinkle animations
//

import SwiftUI

// MARK: - Galaxy Background View

struct GalaxyBackgroundView: View {
    let intensity: Double

    @State private var staticStars: [StaticStar] = []
    @State private var twinklingStars: [TwinklingStar] = []
    @State private var shootingStars: [ShootingStar] = []

    init(intensity: Double = 1.0) {
        self.intensity = max(0.5, min(2.0, intensity))
    }

    var body: some View {
        ZStack {
            // Deep space gradient background
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

            // Static stars - drawn once, never re-rendered
            Canvas { context, size in
                for star in staticStars {
                    let rect = CGRect(
                        x: star.x * size.width - star.size / 2,
                        y: star.y * size.height - star.size / 2,
                        width: star.size,
                        height: star.size
                    )
                    context.fill(
                        Path(ellipseIn: rect),
                        with: .color(.white.opacity(star.opacity))
                    )
                }
            }
            .ignoresSafeArea()
            .drawingGroup()

            // Twinkling stars - lightweight SwiftUI opacity animations
            ForEach(twinklingStars) { star in
                TwinklingStarView(star: star)
            }
            .ignoresSafeArea()

            // Shooting stars - rare, minimal cost
            ShootingStarsLayer(shootingStars: $shootingStars)
                .ignoresSafeArea()
        }
        .onAppear {
            generateStars()
            scheduleShootingStars()
        }
    }

    // MARK: - Star Generation

    private func generateStars() {
        let staticCount = Int(30.0 * intensity)
        let twinkleCount = Int(10.0 * intensity)

        staticStars = (0..<staticCount).map { _ in
            StaticStar(
                x: Double.random(in: 0...1),
                y: Double.random(in: 0...1),
                size: Double.random(in: 0.5...2.0),
                opacity: Double.random(in: 0.4...0.8)
            )
        }

        twinklingStars = (0..<twinkleCount).map { _ in
            TwinklingStar(
                x: Double.random(in: 0...1),
                y: Double.random(in: 0...1),
                size: Double.random(in: 1.0...2.5),
                minOpacity: Double.random(in: 0.2...0.4),
                maxOpacity: Double.random(in: 0.7...1.0),
                duration: Double.random(in: 2...4)
            )
        }
    }

    // MARK: - Shooting Stars

    private func scheduleShootingStars() {
        Timer.scheduledTimer(withTimeInterval: Double.random(in: 10...15), repeats: true) { _ in
            addShootingStar()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 3...8)) {
            addShootingStar()
        }
    }

    private func addShootingStar() {
        let shootingStar = ShootingStar(
            startTime: Date().timeIntervalSinceReferenceDate,
            duration: Double.random(in: 0.3...0.6),
            startX: Double.random(in: 0.3...0.7),
            startY: Double.random(in: 0.1...0.3),
            angle: Double.random(in: .pi/4...(.pi/2.5)),
            length: Double.random(in: 25...45),
            thickness: Double.random(in: 0.8...1.2)
        )

        shootingStars.append(shootingStar)

        DispatchQueue.main.asyncAfter(deadline: .now() + shootingStar.duration + 0.5) {
            shootingStars.removeAll { $0.id == shootingStar.id }
        }
    }
}

// MARK: - Static Star Model

private struct StaticStar {
    let x: Double
    let y: Double
    let size: Double
    let opacity: Double
}

// MARK: - Twinkling Star Model

private struct TwinklingStar: Identifiable {
    let id = UUID()
    let x: Double
    let y: Double
    let size: Double
    let minOpacity: Double
    let maxOpacity: Double
    let duration: Double
}

// MARK: - Twinkling Star View (GPU-accelerated opacity animation)

private struct TwinklingStarView: View {
    let star: TwinklingStar
    @State private var isGlowing = false

    var body: some View {
        GeometryReader { geo in
            Circle()
                .fill(.white)
                .frame(width: star.size, height: star.size)
                .opacity(isGlowing ? star.maxOpacity : star.minOpacity)
                .position(
                    x: star.x * geo.size.width,
                    y: star.y * geo.size.height
                )
        }
        .onAppear {
            withAnimation(
                .easeInOut(duration: star.duration)
                .repeatForever(autoreverses: true)
            ) {
                isGlowing = true
            }
        }
    }
}

// MARK: - Shooting Stars Layer

private struct ShootingStarsLayer: View {
    @Binding var shootingStars: [ShootingStar]

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.05)) { timeline in
            Canvas { context, size in
                let currentTime = timeline.date.timeIntervalSinceReferenceDate

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
        .allowsHitTesting(false)
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

    func calculatePath(at time: TimeInterval, in size: CGSize) -> Path? {
        let elapsed = time - startTime
        guard elapsed >= 0 && elapsed <= duration else { return nil }

        let progress = elapsed / duration
        let travelDistance = 0.8
        let currentX = startX + cos(angle) * progress * travelDistance
        let currentY = startY + sin(angle) * progress * travelDistance

        let headPoint = CGPoint(
            x: currentX * size.width,
            y: currentY * size.height
        )

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
        if progress < 0.15 {
            return progress / 0.15
        } else if progress > 0.75 {
            return 1.0 - ((progress - 0.75) / 0.25)
        } else {
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
                .font(Font.Poppins.custom(.bold, size: 48))
                .foregroundColor(.white)

            Text("Galaxy Background")
                .font(.custom("Poppins-Regular", size: 18))
                .foregroundColor(.white.opacity(0.7))
        }
    }
}
