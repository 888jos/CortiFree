//
//  ScientificPlanView.swift
//  CortiFree
//
//  Created by Claude on 10/11/2025.
//  Deuxième écran: Le plan scientifique avec citations
//

import SwiftUI

struct ScientificPlanView: View {
    let onContinue: () -> Void

    var body: some View {
        ZStack {
            // Galaxy background
            GalaxyBackgroundView(intensity: 1.0)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Title
                    Text("L'approche scientifique de CortiFree")
                        .font(.custom("HankenGrotesk-Bold", size: 28))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, Color(hex: "B794F6")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .padding(.top, 80)
                        .padding(.bottom, 40)

                    // Scientific Citations
                    VStack(spacing: 24) {
                        // Harvard Quote
                        ScientificQuoteCard(
                            logoImage: "logo_harvard",
                            quote: "Les habitudes se forment par des actions répétées dans des contextes stables, et il faut des semaines, voire des mois, pour qu'elles deviennent automatiques.",
                            highlightedText: "actions répétées dans des contextes stables",
                            source: "Wood, W., & Rünger, D. (2016). Psychology of Habit. Annual Review of Psychology,"
                        )

                        // UCL Quote
                        ScientificQuoteCard(
                            logoImage: "logo_ucl",
                            quote: "96 participants ont adopté un comportement quotidien, et l'automaticité a été modélisée pour atteindre un plateau à une moyenne de 66 jours, avec une plage de 18 à 254 jours.",
                            highlightedText: "moyenne de 66 jours, avec une plage de 18 à 254 jours",
                            source: "Lally, P., et al. (2010). How are habits formed: Modelling habit formation in the real world. European Journal of Social Psychology."
                        )

                        // Atomic Habits Quote
                        ScientificQuoteCard(
                            logoImage: "logo_atomic_habits",
                            quote: "En moyenne, il faut plus de deux mois avant qu'un nouveau comportement ne devienne automatique — 66 jours pour être exact.",
                            highlightedText: "plus de deux mois",
                            source: "Clear, J. (2018). Atomic Habits: An Easy & Proven Way to Build Good Habits & Break Bad Ones. Avery."
                        )
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)

                    // Badges
                    HStack(spacing: 16) {
                        BadgeView(text: "+1 500 citations\nGoogle Scholar")
                        BadgeView(text: "+1 000 000\nexemplaires vendus")
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 120)
                }
            }

            // Bottom button
            VStack {
                Spacer()

                Button(action: {
                    HapticManager.medium()
                    onContinue()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)

                        Text("Suivant")
                            .font(.custom("Poppins-SemiBold", size: 18))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 28)
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "B794F6"), Color(hex: "D4B4FF")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Scientific Quote Card

struct ScientificQuoteCard: View {
    let logoImage: String
    let quote: String
    let highlightedText: String
    let source: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Top section: Logo left, Quote right with first gradient
            HStack(alignment: .top, spacing: 12) {
                // Logo
                Image(logoImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                // Quote with guillemets
                Text("\"\(attributedQuote)\"")
                    .font(.custom("Poppins-Regular", size: 14))
                    .foregroundColor(.white)
                    .lineSpacing(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(16)
            .background(
                LinearGradient(
                    colors: [
                        Color(hex: "B794F6").opacity(0.3),
                        Color(hex: "B794F6").opacity(0.05)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )

            // Divider
            Rectangle()
                .fill(Color.white.opacity(0.3))
                .frame(height: 1)

            // Source section with second gradient
            Text(source)
                .font(.custom("Poppins-Regular", size: 11))
                .foregroundColor(.white.opacity(0.6))
                .lineSpacing(3)
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    LinearGradient(
                        colors: [
                            Color(hex: "B794F6").opacity(0.3),
                            Color(hex: "B794F6").opacity(0.05)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
        )
    }

    private var attributedQuote: AttributedString {
        var attributedString = AttributedString(quote)

        if let range = attributedString.range(of: highlightedText) {
            attributedString[range].foregroundColor = Color(hex: "B794F6")
        }

        return attributedString
    }
}

// MARK: - Badge View

struct BadgeView: View {
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            // Laurier gauche
            Image(systemName: "laurel.leading")
                .font(.system(size: 28))
                .foregroundColor(.white)

            Text(text)
                .font(.custom("Poppins-SemiBold", size: 10))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            // Laurier droit
            Image(systemName: "laurel.trailing")
                .font(.system(size: 28))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

#Preview {
    ScientificPlanView(onContinue: {})
}
