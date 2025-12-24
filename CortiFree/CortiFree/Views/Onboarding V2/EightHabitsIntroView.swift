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

            ScrollView {
                VStack(spacing: 0) {
                    // Title
                    Text("onboarding_v2.eight_habits.intro_title".localized)
                        .font(.custom("Poppins-Bold", size: ResponsiveLayout.fontSize(base: 32)))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, Color(hex: "B794F6")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .responsivePadding(.top, 50)
                        .responsivePadding(.bottom, 8)

                    // Description text - fixed to show on one complete line
                    Text("onboarding_v2.eight_habits.intro_description".localized)
                        .font(.custom("Poppins-Regular", size: 16))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .responsivePadding(.horizontal, 20)
                        .responsivePadding(.bottom, 40)

                    // Grid of 8 habit images (2 columns x 4 rows)
                    VStack(spacing: ResponsiveLayout.spacing(base: 20)) {
                        ForEach(0..<4, id: \.self) { row in
                            HStack(spacing: ResponsiveLayout.spacing(base: 12)) {
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
                    .responsivePadding(.horizontal, 20)
                    .responsivePadding(.bottom, 32)

                    // Bottom text
                    Text("onboarding_v2.eight_habits.intro_see_change".localized)
                        .font(.custom("Poppins-Regular", size: 16))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.9)
                        .fixedSize(horizontal: false, vertical: true)
                        .responsivePadding(.horizontal, 20)
                        .responsivePadding(.bottom, 24)

                    // Continue button
                Button(action: {
                    HapticManager.medium()
                    MixpanelManager.shared.trackOnboardingEightHabitsIntroContinue()
                    onContinue()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.right")
                            .font(.system(size: ResponsiveLayout.fontSize(base: 18), weight: .semibold))

                        Text(StringKeys.Common.continueButton)
                            .font(.custom("Poppins-SemiBold", size: ResponsiveLayout.fontSize(base: 18)))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .responsiveHeight(56)
                    .background(
                        RoundedRectangle(cornerRadius: ResponsiveLayout.padding(base: 28))
                            .fill(Color(hex: "B794F6"))
                    )
                }
                .responsivePadding(.horizontal, 32)
                .responsivePadding(.bottom, 40)
                }
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
                .responsiveHeight(90)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: ResponsiveLayout.padding(base: 16)))

            // Very subtle dark overlay
            RoundedRectangle(cornerRadius: ResponsiveLayout.padding(base: 16))
                .fill(Color.black.opacity(0.35))

            // Darker overlay for contrast
            RoundedRectangle(cornerRadius: ResponsiveLayout.padding(base: 16))
                .fill(Color.black.opacity(0.25))

            // Icon in center
            Image(systemName: iconName)
                .font(.system(size: ResponsiveLayout.fontSize(base: 24)))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .responsiveHeight(90)
    }
}

#Preview {
    EightHabitsIntroView(onContinue: {})
}
