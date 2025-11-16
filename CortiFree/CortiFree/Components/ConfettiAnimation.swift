//
//  ConfettiAnimation.swift
//  CortiFree
//
//  Premium confetti animation for task validation
//

import SwiftUI

struct ConfettiAnimation: View {
    @State private var particles: [ConfettiParticle] = []
    let trigger: Bool
    let colors: [Color] = [
        Color(hex: "B794F6"),
        Color(hex: "9B59B6"),
        Color(hex: "E74C3C"),
        Color(hex: "1ABC9C"),
        Color(hex: "2ECC71"),
        Color(hex: "3498DB"),
        Color(hex: "F39C12")
    ]

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    ConfettiParticleView(particle: particle)
                }
            }
            .onChange(of: trigger) { oldValue, newValue in
                if newValue {
                    createConfetti(in: geometry)
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func createConfetti(in geometry: GeometryProxy) {
        particles = []

        for _ in 0..<50 {
            let particle = ConfettiParticle(
                x: CGFloat.random(in: 0...geometry.size.width),
                startY: geometry.size.height * 0.5,
                color: colors.randomElement()!,
                size: CGFloat.random(in: 6...12),
                rotation: Double.random(in: 0...360),
                velocity: CGFloat.random(in: -200...200),
                gravity: CGFloat.random(in: 300...500)
            )
            particles.append(particle)
        }

        // Clear particles after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            particles = []
        }
    }
}

struct ConfettiParticle: Identifiable {
    let id = UUID()
    let x: CGFloat
    let startY: CGFloat
    let color: Color
    let size: CGFloat
    let rotation: Double
    let velocity: CGFloat
    let gravity: CGFloat
}

struct ConfettiParticleView: View {
    let particle: ConfettiParticle
    @State private var offset = CGSize.zero
    @State private var rotation: Double = 0
    @State private var opacity: Double = 1

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(particle.color)
            .frame(width: particle.size, height: particle.size * 1.5)
            .rotationEffect(.degrees(rotation))
            .offset(offset)
            .opacity(opacity)
            .position(x: particle.x, y: particle.startY)
            .onAppear {
                withAnimation(.easeOut(duration: 2.5)) {
                    offset = CGSize(
                        width: particle.velocity * 2,
                        height: -particle.gravity
                    )
                    rotation = particle.rotation + 360
                    opacity = 0
                }
            }
    }
}

// MARK: - Success Validation View

struct SuccessValidationView: View {
    @Binding var isPresented: Bool
    let taskTitle: String
    let scoreIncrease: Int
    let streak: Int
    @State private var animateIn = false

    var body: some View {
        ZStack {
            // Background blur
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .opacity(animateIn ? 1 : 0)

            // Success card
            VStack(spacing: 24) {
                // Success icon with pulse
                ZStack {
                    // Pulsing circles
                    Circle()
                        .fill(Color.green.opacity(0.2))
                        .frame(width: 120, height: 120)
                        .scaleEffect(animateIn ? 1.5 : 0.8)
                        .opacity(animateIn ? 0 : 1)

                    Circle()
                        .fill(Color.green.opacity(0.3))
                        .frame(width: 100, height: 100)
                        .scaleEffect(animateIn ? 1.3 : 0.9)

                    // Checkmark
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                        .scaleEffect(animateIn ? 1 : 0.5)
                        .rotationEffect(.degrees(animateIn ? 0 : -180))
                }

                // Text content
                VStack(spacing: 12) {
                    Text("Bien joué !")
                        .font(.custom("HankenGrotesk-Bold", size: 28))
                        .foregroundColor(.white)

                    Text(taskTitle)
                        .font(.custom("Poppins-Medium", size: 16))
                        .foregroundColor(.white.opacity(0.8))

                    // Stats
                    HStack(spacing: 32) {
                        VStack(spacing: 4) {
                            Text("+\(scoreIncrease)")
                                .font(.custom("HankenGrotesk-Bold", size: 24))
                                .foregroundColor(.green)
                            Text("Score")
                                .font(.custom("Poppins-Regular", size: 12))
                                .foregroundColor(.white.opacity(0.6))
                        }

                        VStack(spacing: 4) {
                            HStack(spacing: 4) {
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.orange)
                                Text("\(streak)")
                                    .font(.custom("HankenGrotesk-Bold", size: 24))
                                    .foregroundColor(.white)
                            }
                            Text("Série")
                                .font(.custom("Poppins-Regular", size: 12))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                }

                // Continue button
                Button(action: {
                    HapticManager.light()
                    withAnimation(.spring()) {
                        animateIn = false
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        isPresented = false
                    }
                }) {
                    Text("Continuer")
                        .font(.custom("Poppins-SemiBold", size: 16))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.white)
                        .cornerRadius(12)
                }
                .bouncePress()
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(hex: "1A1A2E"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.green.opacity(0.3), lineWidth: 2)
                    )
            )
            .padding(.horizontal, 40)
            .scaleEffect(animateIn ? 1 : 0.8)
            .opacity(animateIn ? 1 : 0)
        }
        .onAppear {
            HapticManager.success()
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                animateIn = true
            }
        }
    }
}

// MARK: - Usage Helper

extension View {
    func confettiOverlay(trigger: Bool) -> some View {
        self.overlay(
            ConfettiAnimation(trigger: trigger)
                .allowsHitTesting(false)
        )
    }
}