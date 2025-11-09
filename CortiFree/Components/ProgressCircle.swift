//
//  ProgressCircle.swift
//  CortiFree
//
//  Created by Claude on 22/10/2025.
//

import SwiftUI

struct ProgressCircle: View {
    let progress: Double // 0.0 to 1.0
    let lineWidth: CGFloat
    let size: CGFloat

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: lineWidth)

            // Progress circle
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(
                        colors: [Color.appTheme, Color.appThemeSecondary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    ZStack {
        Color.black
        VStack(spacing: 30) {
            ProgressCircle(progress: 0.3, lineWidth: 8, size: 100)
            ProgressCircle(progress: 0.7, lineWidth: 12, size: 150)
        }
    }
}
