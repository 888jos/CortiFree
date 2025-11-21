//
//  BadgeEvolutionView.swift
//  CortiFree
//
//  Célébration quand un badge d'habitude est débloqué
//

import SwiftUI

struct BadgeEvolutionView: View {

    let badge: HabitBadge
    @Binding var isPresented: Bool
    @State private var showBadge = false
    @State private var showTitle = false
    @State private var showDescription = false
    @State private var showConfetti = false

    var body: some View {
        ZStack {
            // Galaxy background
            GalaxyBackgroundView()
                .ignoresSafeArea()

            // Confetti
            if showConfetti {
                ConfettiAnimation(trigger: showConfetti)
            }

            VStack(spacing: 24) {
                Spacer()

                // Large badge with glow
                ZStack {
                    // Animated glow
                    Circle()
                        .fill(Color(hex: badge.level.color).opacity(0.4))
                        .frame(width: 180, height: 180)
                        .blur(radius: 40)
                        .scaleEffect(showBadge ? 1.2 : 0.8)
                        .animation(
                            Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                            value: showBadge
                        )

                    // Badge circle
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hex: badge.level.color),
                                    Color(hex: badge.level.color).opacity(0.7)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 140, height: 140)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.3), lineWidth: 4)
                        )
                        .shadow(color: Color(hex: badge.level.color).opacity(0.6), radius: 20, x: 0, y: 10)
                        .scaleEffect(showBadge ? 1 : 0.5)
                        .opacity(showBadge ? 1 : 0)

                    // Badge emoji
                    Text(badge.level.emoji)
                        .font(.system(size: 70))
                        .scaleEffect(showBadge ? 1 : 0.5)
                        .opacity(showBadge ? 1 : 0)

                    // Stars around badge (for diamond)
                    if badge.level == .diamond {
                        ForEach(0..<8) { index in
                            Image(systemName: "star.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.8))
                                .offset(
                                    x: cos(Double(index) * .pi / 4) * 100,
                                    y: sin(Double(index) * .pi / 4) * 100
                                )
                                .opacity(showBadge ? 1 : 0)
                                .animation(.easeOut(duration: 0.6).delay(0.3 + Double(index) * 0.05), value: showBadge)
                        }
                    }
                }
                .padding(.vertical, 20)

                // Title
                VStack(spacing: 8) {
                    Text("Badge Débloqué !")
                        .font(.custom("Poppins-Bold", size: 28))
                        .foregroundColor(.white)
                        .opacity(showTitle ? 1 : 0)
                        .offset(y: showTitle ? 0 : 20)

                    Text("\(HabitBadge.habitDisplayName(badge.habitId)) - \(badge.level.displayName)")
                        .font(.custom("Poppins-SemiBold", size: 20))
                        .foregroundColor(Color(hex: badge.level.color))
                        .opacity(showTitle ? 1 : 0)
                        .offset(y: showTitle ? 0 : 20)
                }

                // Description
                Text("Tu as complété \(badge.requirement) tâches de \(HabitBadge.habitDisplayName(badge.habitId))")
                    .font(.custom("Poppins-Regular", size: 16))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .opacity(showDescription ? 1 : 0)
                    .offset(y: showDescription ? 0 : 20)

                // Level indicator
                HStack(spacing: 4) {
                    ForEach(0..<badge.level.starCount, id: \.self) { _ in
                        Image(systemName: "star.fill")
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: badge.level.color))
                    }
                }
                .opacity(showDescription ? 1 : 0)

                Spacer()

                // Continue button
                Button(action: {
                    withAnimation(.spring(response: 0.3)) {
                        isPresented = false
                    }
                }) {
                    Text("Continuer")
                        .font(.custom("Poppins-SemiBold", size: 18))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(hex: badge.level.color),
                                            Color(hex: badge.level.color).opacity(0.8)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .shadow(color: Color(hex: badge.level.color).opacity(0.5), radius: 15, x: 0, y: 8)
                        )
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
                .opacity(showDescription ? 1 : 0)
            }
        }
        .onAppear {
            // Haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)

            // Sequence of animations
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                showBadge = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeOut(duration: 0.4)) {
                    showTitle = true
                }
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeOut(duration: 0.4)) {
                    showDescription = true
                }
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                showConfetti = true
            }
        }
    }
}

// MARK: - Preview

struct BadgeEvolutionView_Previews: PreviewProvider {
    static var previews: some View {
        BadgeEvolutionView(
            badge: HabitBadge(
                id: "meditation_gold",
                habitId: "meditation",
                level: .gold,
                requirement: 36,
                progress: 36,
                unlockedAt: Date()
            ),
            isPresented: .constant(true)
        )
    }
}
