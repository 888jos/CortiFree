//
//  HexagonRadarChart.swift
//  CortiFree
//
//  Created by Claude on 14/11/2025.
//  Composant réutilisable pour afficher un graphique radar hexagonal
//

import SwiftUI

struct HexagonRadarChart: View {
    let progress: [Double] // Array of 6 progress values [0.0-1.0]
    let color: Color
    let size: CGFloat
    let showLabels: Bool

    init(
        progress: [Double],
        color: Color = Color(hex: "B794F6"),
        size: CGFloat = 238,
        showLabels: Bool = true
    ) {
        self.progress = progress
        self.color = color
        self.size = size
        self.showLabels = showLabels
    }

    var body: some View {
        ZStack {
            // Background hexagon grid
            HexagonRadarGrid()
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                .frame(width: size, height: size)

            // Filled hexagon based on progress with gradient
            HexagonRadarFill(progress: progress)
                .fill(
                    LinearGradient(
                        colors: [
                            color.opacity(0.7),
                            color.opacity(0.4)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: size, height: size)

            // Stroke around the filled hexagon
            HexagonRadarFill(progress: progress)
                .stroke(
                    color.opacity(0.5),
                    lineWidth: 3
                )
                .frame(width: size, height: size)

            // Labels at hexagon vertices
            if showLabels {
                RadarLabels(size: size)
            }
        }
    }
}

struct RadarLabels: View {
    let size: CGFloat

    private var labelOffset: CGFloat {
        size * 0.6
    }

    private var sideOffset: CGFloat {
        size * 0.528
    }

    private var verticalOffset: CGFloat {
        size * 0.293
    }

    private var fontSize: CGFloat {
        size > 250 ? 16 : 12
    }

    private var iconSize: CGFloat {
        size > 250 ? 14 : 12
    }

    var body: some View {
        ZStack {
            // Global - Top
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .font(.system(size: iconSize))
                Text("Global")
                    .font(.custom("Poppins-SemiBold", size: fontSize))
            }
            .foregroundColor(.white)
            .offset(x: 0, y: -labelOffset)

            // Sérénité - Top right
            HStack(spacing: 4) {
                Image(systemName: "leaf.fill")
                    .font(.system(size: iconSize))
                Text("Sérénité")
                    .font(.custom("Poppins-SemiBold", size: fontSize))
            }
            .foregroundColor(.white)
            .offset(x: sideOffset, y: -verticalOffset)

            // Sommeil - Bottom right
            HStack(spacing: 4) {
                Image(systemName: "moon.fill")
                    .font(.system(size: iconSize))
                Text("Sommeil")
                    .font(.custom("Poppins-SemiBold", size: fontSize))
            }
            .foregroundColor(.white)
            .offset(x: sideOffset, y: verticalOffset)

            // Énergie - Bottom
            HStack(spacing: 4) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: iconSize))
                Text("Énergie")
                    .font(.custom("Poppins-SemiBold", size: fontSize))
            }
            .foregroundColor(.white)
            .offset(x: 0, y: labelOffset)

            // Focus - Bottom left
            HStack(spacing: 4) {
                Image(systemName: "target")
                    .font(.system(size: iconSize))
                Text("Focus")
                    .font(.custom("Poppins-SemiBold", size: fontSize))
            }
            .foregroundColor(.white)
            .offset(x: -sideOffset, y: verticalOffset)

            // Équilibre - Top left
            HStack(spacing: 4) {
                Image(systemName: "heart.fill")
                    .font(.system(size: iconSize))
                Text("Équilibre")
                    .font(.custom("Poppins-SemiBold", size: fontSize))
            }
            .foregroundColor(.white)
            .offset(x: -sideOffset, y: -verticalOffset)
        }
    }
}

// MARK: - Hexagon Radar Grid

struct HexagonRadarGrid: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2

        // Draw 3 concentric hexagons
        for scale in [0.33, 0.66, 1.0] {
            let scaledRadius = radius * scale
            let hexPath = hexagonPath(center: center, radius: scaledRadius)
            path.addPath(hexPath)
        }

        // Draw lines from center to each vertex
        for i in 0..<6 {
            let angle = Double(i) * .pi / 3 - .pi / 2
            let point = CGPoint(
                x: center.x + radius * CGFloat(cos(angle)),
                y: center.y + radius * CGFloat(sin(angle))
            )
            path.move(to: center)
            path.addLine(to: point)
        }

        return path
    }

    private func hexagonPath(center: CGPoint, radius: CGFloat) -> Path {
        var path = Path()
        for i in 0..<6 {
            let angle = Double(i) * .pi / 3 - .pi / 2
            let point = CGPoint(
                x: center.x + radius * CGFloat(cos(angle)),
                y: center.y + radius * CGFloat(sin(angle))
            )
            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }
}

// MARK: - Hexagon Radar Fill

struct HexagonRadarFill: Shape {
    let progress: [Double] // Array of 6 progress values, one for each vertex

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let baseRadius = min(rect.width, rect.height) / 2

        for i in 0..<6 {
            let angle = Double(i) * .pi / 3 - .pi / 2
            let individualProgress = progress.count > i ? progress[i] : 0.5
            let radius = baseRadius * CGFloat(individualProgress)
            let point = CGPoint(
                x: center.x + radius * CGFloat(cos(angle)),
                y: center.y + radius * CGFloat(sin(angle))
            )

            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        GalaxyBackgroundView(intensity: 1.0)

        VStack(spacing: 40) {
            // Full size with labels
            HexagonRadarChart(
                progress: [0.75, 0.65, 0.45, 0.80, 0.55, 0.70],
                color: Color(hex: "B794F6"),
                size: 280,
                showLabels: true
            )

            // Smaller without labels
            HexagonRadarChart(
                progress: [0.50, 0.70, 0.60, 0.45, 0.75, 0.65],
                color: Color(hex: "1ABC9C"),
                size: 180,
                showLabels: false
            )
        }
    }
}