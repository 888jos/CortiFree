//
//  MulticolorOrb.swift
//  CortiFree
//
//  Created by Claude on 22/10/2025.
//

import SwiftUI

struct MulticolorOrb: View {
    let size: CGFloat
    @State private var rotation: Double = 0

    var body: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.appTheme.opacity(0.4),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: size * 0.3,
                        endRadius: size * 0.6
                    )
                )
                .frame(width: size + 40, height: size + 40)
                .blur(radius: 20)

            // Main orb with radial gradient
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(hex: "FF6B9D"), // Center: Rose
                            Color(hex: "00E5FF"), // Middle: Cyan
                            Color.appTheme  // Outer: Vert
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: size / 2
                    )
                )
                .frame(width: size, height: size)
                .blur(radius: 2)
                .rotationEffect(.degrees(rotation))
                .onAppear {
                    withAnimation(.linear(duration: 60).repeatForever(autoreverses: false)) {
                        rotation = 360
                    }
                }
        }
    }
}

#Preview {
    ZStack {
        Color.black
        MulticolorOrb(size: 220)
    }
}
