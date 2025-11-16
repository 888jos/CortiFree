//
//  TaskCard.swift
//  CortiFree
//
//  Created by Claude on 14/11/2025.
//  Carte de tâche d'habitude avec image de fond et informations
//

import SwiftUI

struct HabitTaskCard: View {
    let title: String
    let duration: String  // Ex: "30 min" or "2.5L" for water
    let frequencyText: String  // Ex: "3x/sem" or "Quotidien"
    let difficulty: Int // 1, 2, or 3
    let streak: Int
    let imageName: String
    let action: () -> Void
    let onValidate: () -> Void
    let onSkip: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            HapticManager.light()
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                    isPressed = false
                }
            }
            action()
        }) {
            ZStack(alignment: .topLeading) {
                // Background image
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 345, height: 180)
                    .clipped()

                // Gradient overlay pour la lisibilité
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.3),
                        Color.clear,
                        Color.black.opacity(0.2)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                // Gradient noir sur la partie inférieure (50%)
                VStack {
                    Spacer()
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0),
                            Color.black.opacity(0.25),
                            Color.black.opacity(0.5),
                            Color.black.opacity(0.75)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 90) // 50% of 180px
                }

                // Content overlay
                VStack(alignment: .leading, spacing: 0) {
                    // Top section: Streak (left) + Info icon (right)
                    HStack {
                        // Streak badge (flamme)
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 12))
                                .foregroundColor(Color(hex: "FF8800"))

                            Text("\(streak)")
                                .font(.custom("Poppins-SemiBold", size: 13))
                                .foregroundColor(.white)
                        }
                        .frame(width: 40, height: 20)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(hex: "FF8800").opacity(0.4))
                        )

                        Spacer()

                        // Info icon
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.black.opacity(0.4))
                    }
                    .padding(.top, 12)
                    .padding(.horizontal, 12)

                    Spacer()

                    // Middle info - centered vertically
                    VStack(alignment: .leading, spacing: 8) {
                        Text(title)
                            .font(.custom("HankenGrotesk-Bold", size: 20))
                            .foregroundColor(.white)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)

                        HStack(spacing: 16) {
                            // Duration with clock icon
                            if !duration.isEmpty {
                                HStack(spacing: 4) {
                                    Image(systemName: "clock")
                                        .font(.system(size: 12))
                                        .foregroundColor(.white)

                                    Text(duration)
                                        .font(.custom("Poppins-Regular", size: 13))
                                        .foregroundColor(.white.opacity(0.7))
                                }
                            }

                            // Frequency with repeat icon
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white)

                                Text(frequencyText)
                                    .font(.custom("Poppins-Regular", size: 13))
                                    .foregroundColor(.white.opacity(0.7))
                            }

                            // Difficulty bars
                            HStack(spacing: 4) {
                                HStack(alignment: .bottom, spacing: 2) {
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(difficulty >= 1 ? Color.white : Color(hex: "8B8B8B"))
                                        .frame(width: 3, height: 6)

                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(difficulty >= 2 ? Color.white : Color(hex: "8B8B8B"))
                                        .frame(width: 3, height: 9)

                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(difficulty >= 3 ? Color.white : Color(hex: "8B8B8B"))
                                        .frame(width: 3, height: 12)
                                }

                                Text("Difficulté")
                                    .font(.custom("Poppins-Regular", size: 13))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                    }
                    .padding(.horizontal, 16)

                    Spacer()
                }
            }
            .frame(width: 345, height: 180)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
            .scaleEffect(isPressed ? 0.97 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ZStack {
        GalaxyBackgroundView(intensity: 1.0)

        VStack(spacing: 24) {
            HabitTaskCard(
                title: "S'hydrater régulièrement",
                duration: "2.5L",
                frequencyText: "Quotidien",
                difficulty: 1,
                streak: 17,
                imageName: "habit_water",
                action: {
                    print("Tapped")
                },
                onValidate: {
                    print("Validated")
                },
                onSkip: {
                    print("Skipped")
                }
            )

            HabitTaskCard(
                title: "Méditer en pleine conscience",
                duration: "10 min",
                frequencyText: "3x/sem",
                difficulty: 3,
                streak: 24,
                imageName: "habit_meditate",
                action: {
                    print("Tapped")
                },
                onValidate: {
                    print("Validated")
                },
                onSkip: {
                    print("Skipped")
                }
            )
        }
    }
}
