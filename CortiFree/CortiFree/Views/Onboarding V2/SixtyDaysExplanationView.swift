//
//  SixtyDaysExplanationView.swift
//  CortiFree
//
//  Created by Claude on 10/11/2025.
//  Premier écran: Explication des 66 jours avec statistiques
//

import SwiftUI

struct SixtyDaysExplanationView: View {
    let onContinue: () -> Void

    var body: some View {
        ZStack {
            // Galaxy background
            GalaxyBackgroundView(intensity: 1.0)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Title with gradient on "66 jours"
                    VStack(spacing: 6) {
                        // Première partie
                        Text("Des études scientifiques le confirment : ")
                            .font(.custom("Poppins-Regular", size: 16))
                            .foregroundColor(Color(hex: "B794F6").opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 32)
                    .padding(.top, 100)
                    .padding(.bottom, 12)

                    // "66 jours" - Grande police avec gradient
                    Text("66 jours")
                        .font(.custom("Faro-BoldLucky", size: 64))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(hex: "D4B4FF"),
                                    Color(hex: "B794F6"),
                                    Color(hex: "9775D5")
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .multilineTextAlignment(.center)
                        .shadow(color: Color(hex: "B794F6").opacity(0.8), radius: 30, x: 0, y: 0)
                        .padding(.bottom, 12)

                    // Deuxième partie
                    VStack(spacing: 6) {
                        Text("c'est le temps nécessaire pour ancrer une ")
                            .font(.custom("Poppins-Regular", size: 16))
                            .foregroundColor(Color(hex: "B794F6").opacity(0.8))
                            .multilineTextAlignment(.center)

                        Text(" habitude et transformer réellement sa vie.")
                            .font(.custom("Poppins-Regular", size: 16))
                            .foregroundColor(Color(hex: "B794F6").opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 32)

                    // Stats Grid
                    VStack(spacing: 16) {
                        HStack(spacing: 16) {
                            BenefitStatCard(
                                title: "Boostez votre énergie",
                                percentage: "38%",
                                color: Color(hex: "B794F6")
                            )

                            BenefitStatCard(
                                title: "Réduisez la fatigue",
                                percentage: "15%",
                                color: Color(hex: "B794F6")
                            )
                        }

                        HStack(spacing: 16) {
                            BenefitStatCard(
                                title: "Gagnez en sérénité",
                                percentage: "27%",
                                color: Color(hex: "B794F6")
                            )

                            BenefitStatCard(
                                title: "Améliorez votre focus",
                                percentage: "24%",
                                color: Color(hex: "B794F6")
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)

                    // Scientific Research Section
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Recherche scientifique")
                            .font(.custom("Poppins-SemiBold", size: 20))
                            .foregroundColor(.white)

                        Spacer()
                            .frame(height: 16)

                        VStack(spacing: 8) {
                            ScientificLinkRow(
                                logoImage: "logo_psycnet",
                                title: "How are habits formed: Modelling habit formation...",
                                source: "psycnet.apa.org"
                            )

                            ScientificLinkRow(
                                logoImage: "logo_nih",
                                title: "Making health habitual: the psychology of habit...",
                                source: "pmc.ncbi.nlm.nih.gov"
                            )

                            ScientificLinkRow(
                                logoImage: "logo_nih",
                                title: "Time to Form a Habit: A Systematic Review and...",
                                source: "pubmed.ncbi.nlm.nih.gov"
                            )

                            ScientificLinkRow(
                                logoImage: "logo_ucl",
                                title: "How long does it really take to form a habit...",
                                source: "blogs.ucl.ac.uk"
                            )

                            ScientificLinkRow(
                                logoImage: "logo_nih",
                                title: "'Little by Little' Supports Habit Formation...",
                                source: "nihrecord.nih.gov"
                            )

                            ScientificLinkRow(
                                logoImage: "logo_guardian",
                                title: "66 days to build better sleep habits research...",
                                source: "theguardian.com"
                            )
                        }
                    }
                    .padding(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
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

// MARK: - Benefit Stat Card

struct BenefitStatCard: View {
    let title: String
    let percentage: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.custom("Poppins-Regular", size: 13))
                .foregroundColor(.white.opacity(0.8))
                .lineLimit(2)
                .minimumScaleFactor(0.8)

            HStack(spacing: 4) {
                Text(percentage)
                    .font(.custom("HankenGrotesk-Bold", size: 28))
                    .foregroundColor(.white)

                Image(systemName: "arrow.up")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "B794F6").opacity(0.2),
                            Color(hex: "B794F6").opacity(0.4)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        )
    }
}

// MARK: - Scientific Link Row

struct ScientificLinkRow: View {
    let logoImage: String
    let title: String
    let source: String

    var body: some View {
        HStack(spacing: 8) {
            Image(logoImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 20, height: 20)

            Text(title)
                .font(.custom("Poppins-Medium", size: 12))
                .foregroundColor(.white)
                .lineLimit(1)
                .truncationMode(.tail)

            Text("• \(source)")
                .font(.custom("Poppins-Regular", size: 11))
                .foregroundColor(.white.opacity(0.6))
                .lineLimit(1)
                .truncationMode(.tail)
        }
    }
}

#Preview {
    SixtyDaysExplanationView(onContinue: {})
        .onAppear {
            FontManager.registerFonts()
        }
}
