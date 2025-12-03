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
    @ObservedObject var languageManager = LanguageManager.shared

    // Ordre: Respiration, Méditation, Journal, Sport, Eau, Nature, Sommeil, Social
    private let habits: [(image: String, icon: String)] = [
        ("habit_breathe", "wind"),               // Respiration
        ("habit_meditate", "figure.mind.and.body"), // Méditation
        ("habit_journal", "book.fill"),          // Journal
        ("habit_sport", "figure.run"),           // Sport
        ("habit_water", "drop.fill"),            // Eau
        ("habit_nature", "leaf.fill"),           // Nature
        ("habit_sleep", "moon.zzz.fill"),        // Sommeil
        ("habit_social", "person.2.fill")        // Social
    ]

    var body: some View {
        ZStack {
            // Dark background
            Color(hex: "0A0A0A")
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Title
                Text("onboarding_v2.eight_habits.intro_title".localized)
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
                        Text("onboarding_v2.eight_habits.intro_studies".localized)
                            .font(.custom("Poppins-Regular", size: 16))
                            .foregroundColor(.white)
                        Text("onboarding_v2.eight_habits.intro_reset".localized)
                            .font(.custom("Poppins-Regular", size: 16))
                            .foregroundColor(.white)
                    }

                    HStack(spacing: 4) {
                        Text("onboarding_v2.eight_habits.intro_life".localized)
                            .font(.custom("Poppins-Regular", size: 16))
                            .foregroundColor(.white)

                        Text("onboarding_v2.eight_habits.intro_fundamental".localized)
                            .font(.custom("Poppins-SemiBold", size: 16))
                            .foregroundColor(Color(hex: "B794F6"))
                    }

                    Text("onboarding_v2.eight_habits.intro_below".localized)
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
                Text("onboarding_v2.eight_habits.intro_see_change".localized)
                    .font(.custom("Poppins-Regular", size: 16))
                    .foregroundColor(.white)
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

                        Text(StringKeys.Common.continueButton)
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
    }
}

#Preview {
    EightHabitsIntroView(onContinue: {})
}
