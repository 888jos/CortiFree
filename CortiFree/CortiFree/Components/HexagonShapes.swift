//
//  HexagonShapes.swift
//  CortiFree
//
//  Decorative hexagon radar shapes (grid + filled polygon)
//

import SwiftUI

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
