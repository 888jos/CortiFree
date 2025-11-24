//
//  ModernExerciseCard.swift
//  CortiFree
//
//  Created by Claude on 21/11/2025.
//  Modern glassmorphic design for exercise recommendation cards
//

import SwiftUI

struct ModernExerciseCard: View {
    let exercise: ExerciseRecommendation
    let isTopMatch: Bool
    let onTap: () -> Void

    @State private var isPressed = false

    // Exercise-specific background color
    private var exerciseBackgroundColor: Color {
        switch exercise.exerciseType {
        case .guidedBreathing, .boxBreathing, .consciousBreathing, .alternateBreathing, .cardiacCoherence:
            return Color(hex: "16233A") // Respiration background
        case .meditation2Min:
            return Color(hex: "2A1E47") // Méditation background
        default:
            return Color(hex: "2A1E47") // Violet background (same as meditation)
        }
    }

    // Exercise-specific icon color
    private var exerciseIconColor: Color {
        switch exercise.exerciseType {
        case .guidedBreathing, .boxBreathing, .consciousBreathing, .alternateBreathing, .cardiacCoherence:
            return Color(hex: "E4F9FF") // Respiration icon
        case .meditation2Min:
            return Color(hex: "F4EFFF") // Méditation icon
        default:
            return Color(hex: "F4EFFF") // Violet icon (same as meditation)
        }
    }

    // Exercise-specific icons
    private var exerciseIcon: String {
        switch exercise.exerciseType {
        case .guidedBreathing, .boxBreathing, .consciousBreathing, .alternateBreathing, .cardiacCoherence:
            return "wind"
        case .meditation2Min:
            return "sparkles"
        case .grounding5Senses, .anchoring54321:
            return "leaf.fill"
        case .positiveMantra, .visualMicroBreak:
            return "eye.fill"
        case .bodyScan:
            return "figure.stand"
        case .consciousStretching, .slowWalk:
            return "figure.walk"
        case .audioRelaxation, .whiteNoise:
            return "waveform.path.ecg"
        }
    }

    var body: some View {
        Button(action: {
            HapticManager.medium()
            onTap()
        }) {
            ZStack {
                // Main card content - CENTERED ICON
                exerciseIconView

                // Percentage badge - TOP LEFT WITH SPACING
                VStack {
                    HStack {
                        percentageBadge
                            .padding(.leading, 8)
                            .padding(.top, 8)
                        Spacer()
                    }
                    Spacer()
                }

                // Exercise name with star - BOTTOM CENTER
                VStack {
                    Spacer()
                    HStack(spacing: 6) {
                        Spacer()
                        Image(systemName: "star.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.white)
                        Text(exercise.exerciseType.displayName)
                            .font(.custom("Poppins-SemiBold", size: 12))
                            .foregroundColor(.white)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                        Spacer()
                    }
                    .padding(.horizontal, 8)
                    .padding(.bottom, isTopMatch ? 16 : 12)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: isTopMatch ? 180 : 160)
            .aspectRatio(isTopMatch ? nil : 1, contentMode: .fit)
            .background(exerciseBackgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        exerciseIconColor.opacity(0.3),
                        lineWidth: 1
                    )
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = pressing
            }
        }, perform: {})
    }

    // MARK: - Subviews

    private var percentageBadge: some View {
        Text(isTopMatch ? "Recommandé à \(exercise.matchPercentage)%" : "\(exercise.matchPercentage)%")
            .font(.custom("Poppins-SemiBold", size: isTopMatch ? 12 : 13))
            .foregroundColor(.black)
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(.white.opacity(0.8))
            )
    }

    private var exerciseIconView: some View {
        Image(systemName: exerciseIcon)
            .font(.system(size: 32, weight: .semibold))
            .foregroundColor(exerciseIconColor)
    }

    // MARK: - Helper Functions

    private func formatDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        return "\(minutes) min"
    }

}

// MARK: - Floating Particles Component

struct FloatingParticles: View {
    let colors: [Color]
    let particleCount: Int

    @State private var particles: [Particle] = []

    struct Particle: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var size: CGFloat
        var opacity: Double
        var color: Color
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size)
                        .opacity(particle.opacity)
                        .blur(radius: particle.size / 2)
                        .position(x: particle.x, y: particle.y)
                }
            }
            .onAppear {
                generateParticles(in: geometry.size)
                animateParticles()
            }
        }
    }

    private func generateParticles(in size: CGSize) {
        particles = (0..<particleCount).map { _ in
            Particle(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: 0...size.height),
                size: CGFloat.random(in: 4...12),
                opacity: Double.random(in: 0.2...0.5),
                color: colors.randomElement() ?? colors[0]
            )
        }
    }

    private func animateParticles() {
        for index in particles.indices {
            withAnimation(
                .easeInOut(duration: Double.random(in: 3...6))
                .repeatForever(autoreverses: true)
                .delay(Double.random(in: 0...2))
            ) {
                particles[index].y += CGFloat.random(in: -20...20)
                particles[index].opacity = Double.random(in: 0.1...0.6)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        GalaxyBackgroundView(intensity: 1.0)

        VStack(spacing: 20) {
            // Top match (hero card)
            ModernExerciseCard(
                exercise: ExerciseRecommendation(
                    exerciseType: .guidedBreathing,
                    matchPercentage: 100
                ),
                isTopMatch: true,
                onTap: {}
            )
            .frame(height: 220)

            HStack(spacing: 16) {
                // Regular cards
                ModernExerciseCard(
                    exercise: ExerciseRecommendation(
                        exerciseType: .meditation2Min,
                        matchPercentage: 85
                    ),
                    isTopMatch: false,
                    onTap: {}
                )

                ModernExerciseCard(
                    exercise: ExerciseRecommendation(
                        exerciseType: .grounding5Senses,
                        matchPercentage: 75
                    ),
                    isTopMatch: false,
                    onTap: {}
                )
            }
            .frame(height: 180)
        }
        .padding()
    }
}
