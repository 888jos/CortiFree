//
//  GradientOrb.swift
//  CortiFree
//
//  Created by Claude on 22/10/2025.
//

import SwiftUI

struct GradientOrb: View {
    let size: CGFloat
    @State private var rotation: Double = 0

    var body: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [
                        Color.appTheme,
                        Color.appThemeSecondary,
                        Color.appTheme
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: size, height: size)
            .blur(radius: size * 0.2)
            .rotationEffect(.degrees(rotation))
            .onAppear {
                withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }
    }
}

#Preview {
    ZStack {
        Color.black
        GradientOrb(size: 200)
    }
}
