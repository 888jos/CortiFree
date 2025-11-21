//
//  EightHabitsIntroView.swift
//  CortiFree
//
//  Created by Claude on 11/11/2025.
//  Introduction screen showing the 8 key habits with images
//

import SwiftUI

struct EightHabitsIntroView: View {
    let onContinue: () -> Void

    private let habits: [(image: String, icon: String)] = [
        ("habit_breathe", "wind"),
        ("habit_meditate", "figure.mind.and.body"),
        ("habit_journal", "drop.fill"),
        ("habit_sport", "figure.run"),
        ("habit_water", "drop.fill"),
        ("habit_nature", "moon.zzz.fill"),
        ("habit_sleep", "figure.walk"),
        ("habit_social", "person.2.fill")
    ]

    var body: some View {
        ZStack {
            // Dark background
            Color(hex: "0A0A0A")
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Title
                Text("Les 8 habitudes clés")
                    .font(.custom("Poppins-Bold", size: 32))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, Color(hex: "B794F6")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .padding(.top, 92)
                    .padding(.bottom, 16)

                // Description text
                VStack(spacing: 4) {
                    HStack(spacing: 4) {
                        Text("Des études montrent que pour réinitialiser votre")
                            .font(.custom("Poppins-Regular", size: 16))
                            .foregroundColor(.white)
                    }

                    HStack(spacing: 4) {
                        Text("vie, vous avez besoin des")
                            .font(.custom("Poppins-Regular", size: 16))
                            .foregroundColor(.white)

                        Text("8 habitudes")
                            .font(.custom("Poppins-SemiBold", size: 16))
                            .foregroundColor(Color(hex: "B794F6"))
                    }

                    Text("fondamentales ci-dessous.")
                        .font(.custom("Poppins-SemiBold", size: 16))
                        .foregroundColor(Color(hex: "B794F6"))
                }
                .padding(.bottom, 40)

                // Grid of 8 habit images (2 columns x 4 rows)
                VStack(spacing: 20) {
                    ForEach(0..<4, id: \.self) { row in
                        HStack(spacing: 12) {
                            ForEach(0..<2, id: \.self) { col in
                                let index = row * 2 + col
                                if index < habits.count {
                                    HabitImageCard(
                                        imageName: habits[index].image,
                                        iconName: habits[index].icon
                                    )
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)

                Spacer()

                // Bottom text
                VStack(spacing: 4) {
                    Text("Voir comment ta vie changera en 66 jours")
                        .font(.custom("Poppins-Regular", size: 16))
                        .foregroundColor(.white)

                    Text("grâce à ces 8 habitudes :")
                        .font(.custom("Poppins-Regular", size: 16))
                        .foregroundColor(.white)
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .padding(.bottom, 24)

                // Continue button
                Button(action: {
                    HapticManager.medium()
                    MixpanelManager.shared.trackOnboardingEightHabitsIntroContinue()
                    onContinue()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 18, weight: .semibold))

                        Text("Continuer")
                            .font(.custom("Poppins-SemiBold", size: 18))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 28)
                            .fill(Color(hex: "B794F6"))
                    )
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            MixpanelManager.shared.trackOnboardingEightHabitsIntroViewed()
        }
    }
}

// MARK: - Habit Image Card

struct HabitImageCard: View {
    let imageName: String
    let iconName: String

    var body: some View {
        ZStack {
            // Background image
            Image(imageName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: 90)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 16))

            // Very subtle dark overlay
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.35))

            // Darker overlay for contrast
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.25))

            // Icon in center
            Image(systemName: iconName)
                .font(.system(size: 24))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 90)
        .scaleEffect(x: 0.9, y: 1.0)
    }
}

#Preview {
    EightHabitsIntroView(onContinue: {})
}
