//
//  AntiStressBodyScanDetailView.swift
//  CortiFree
//
//  Created by Claude on 22/11/2025.
//  Body scan exercise detail view for Anti-Stress flow
//

import SwiftUI

struct AntiStressBodyScanDetailView: View {
    let exerciseType: AntiStressExerciseType
    let situation: StressSituation
    @ObservedObject var viewModel: AntiStressViewModel
    @Environment(\.dismiss) var dismiss

    @State private var showGuidedSession = false
    @State private var pulseAnimation = false
    @State private var showHowItWorks = true
    @State private var showScience = false

    var body: some View {
        ZStack {
            // Galaxy background uniforme
            GalaxyBackgroundView(intensity: 0.8)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Custom animated header
                animatedHeader

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Titre compact en haut
                        compactTitleSection

                        // Comment ça marche - EXPANDABLE CARD
                        howItWorksExpandableCard

                        // Bienfaits avec badges
                        benefitsSection

                        // Données scientifiques - EXPANDABLE
                        scientificEvidenceCard

                        // Spacer to push button to bottom
                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 140) // Space for fixed bottom section
                }

                // FIXED BOTTOM SECTION - Button
                fixedBottomSection
            }
        }
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                pulseAnimation = true
            }
        }
        .fullScreenCover(isPresented: $showGuidedSession) {
            InstructionExerciseView(
                exerciseType: .bodyScan,
                situation: situation,
                viewModel: viewModel
            )
        }
    }

    // MARK: - Animated Header

    private var animatedHeader: some View {
        ZStack(alignment: .topLeading) {
            // Gradient header background - Uses exercise type color
            LinearGradient(
                colors: [
                    exerciseType.headerGradientColor.opacity(0.3),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 120)
            .ignoresSafeArea(edges: .top)

            HStack {
                Button(action: {
                    HapticManager.light()
                    dismiss()
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.15))
                            .frame(width: 40, height: 40)
                            .blur(radius: 8)

                        Circle()
                            .fill(Color(hex: "1A1B3A").opacity(0.8))
                            .frame(width: 40, height: 40)

                        Image(systemName: "chevron.left")
                            .font(.custom("Poppins-SemiBold", size: 16))
                            .foregroundColor(.white)
                    }
                }

                Spacer()

                // Category badge
                HStack(spacing: 6) {
                    Image(systemName: "figure.stand")
                        .font(.system(size: 12))
                    Text(NSLocalizedString("antistress.body_scan.category_badge", comment: ""))
                        .font(.custom("Poppins-Bold", size: 11))
                }
                .foregroundColor(Color.appTheme)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.appTheme.opacity(0.2))
                        .overlay(
                            Capsule()
                                .stroke(Color.appTheme.opacity(0.5), lineWidth: 1)
                        )
                )
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
        }
    }

    // MARK: - Compact Title Section

    private var compactTitleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title
            Text(NSLocalizedString("antistress.body_scan.title", comment: ""))
                .font(.faroBold(28))
                .foregroundColor(.white)

            // Description courte
            Text(NSLocalizedString("antistress.body_scan.subtitle", comment: ""))
                .font(.custom("Poppins-Regular", size: 15))
                .foregroundColor(.white.opacity(0.8))
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - How It Works - EXPANDABLE CARD

    private var howItWorksExpandableCard: some View {
        Button(action: {
            HapticManager.light()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                showHowItWorks.toggle()
            }
        }) {
            VStack(alignment: .leading, spacing: 0) {
                // Header - Always visible
                HStack {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Color.appTheme)

                    Text(NSLocalizedString("antistress.how_it_works", comment: ""))
                        .font(.custom("Poppins-SemiBold", size: 18))
                        .foregroundColor(.white)

                    Spacer()

                    Image(systemName: showHowItWorks ? "chevron.up" : "chevron.down")
                        .font(.custom("Poppins-SemiBold", size: 14))
                        .foregroundColor(Color.white.opacity(0.6))
                }
                .padding(20)

                // Description - Expandable
                if showHowItWorks {
                    Text(NSLocalizedString("antistress.body_scan.how_it_works_text", comment: ""))
                        .font(.custom("Poppins-Regular", size: 15))
                        .foregroundColor(Color(hex: "E5E5E5"))
                        .lineSpacing(8)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hex: "1A1B3A").opacity(0.8),
                                    Color(hex: "2A2B5A").opacity(0.6)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.appTheme.opacity(0.3),
                                    Color.appThemeSecondary.opacity(0.3)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Données scientifiques

    private var scientificEvidenceCard: some View {
        Button(action: {
            HapticManager.light()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                showScience.toggle()
            }
        }) {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Image(systemName: "flask.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Color.appTheme)

                    Text(NSLocalizedString("antistress.scientific_evidence", comment: ""))
                        .font(.custom("Poppins-SemiBold", size: 18))
                        .foregroundColor(.white)

                    Spacer()

                    Image(systemName: showScience ? "chevron.up" : "chevron.down")
                        .font(.custom("Poppins-SemiBold", size: 14))
                        .foregroundColor(Color.white.opacity(0.6))
                }
                .padding(20)

                if showScience {
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(scientificEvidences, id: \.self) { evidence in
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(Color.appTheme)
                                    .frame(width: 24)

                                Text(evidence)
                                    .font(.custom("Poppins-Regular", size: 14))
                                    .foregroundColor(.white.opacity(0.9))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }

                        // Sources scientifiques (3 sources)
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(scientificSources, id: \.self) { source in
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "doc.text.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(.white.opacity(0.5))
                                        .frame(width: 16)

                                    Text(source)
                                        .font(.custom("Poppins-Regular", size: 11))
                                        .foregroundColor(.white.opacity(0.6))
                                        .italic()
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hex: "1A1B3A").opacity(0.8),
                                    Color(hex: "2A2B5A").opacity(0.6)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.appTheme.opacity(0.3),
                                    Color.appThemeSecondary.opacity(0.3)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var scientificEvidences: [String] {
        return [
            NSLocalizedString("antistress.body_scan.evidence_1", comment: ""),
            NSLocalizedString("antistress.body_scan.evidence_2", comment: ""),
            NSLocalizedString("antistress.body_scan.evidence_3", comment: "")
        ]
    }

    private var scientificSources: [String] {
        return [NSLocalizedString("antistress.body_scan.source", comment: "")]
    }

    // MARK: - Benefits Section

    private var benefitsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "heart.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Color.appTheme)

                Text(NSLocalizedString("antistress.benefits", comment: ""))
                    .font(.custom("Poppins-SemiBold", size: 18))
                    .foregroundColor(.white)
            }

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(Array(benefits.enumerated()), id: \.offset) { index, benefit in
                    MeditationBenefitBadge(benefit: benefit, index: index)
                }
            }
        }
    }

    private var benefits: [String] {
        return [
            NSLocalizedString("antistress.body_scan.benefit_1", comment: ""),
            NSLocalizedString("antistress.body_scan.benefit_2", comment: ""),
            NSLocalizedString("antistress.body_scan.benefit_3", comment: ""),
            NSLocalizedString("antistress.body_scan.benefit_4", comment: "")
        ]
    }

    // MARK: - FIXED BOTTOM SECTION (Button only)

    private var fixedBottomSection: some View {
        VStack(spacing: 16) {
            // Launch Button
            launchButton
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(
            ZStack {
                // Blur background
                LinearGradient(
                    colors: [
                        Color(hex: "01000C"),
                        Color(hex: "01000C").opacity(0.95)
                    ],
                    startPoint: .bottom,
                    endPoint: .top
                )
                .ignoresSafeArea(edges: .bottom)
            }
        )
    }

    // MARK: - Launch Button

    private var launchButton: some View {
        Button(action: {
            HapticManager.success()
            showGuidedSession = true
        }) {
            HStack(spacing: 12) {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 24))

                Text(NSLocalizedString("antistress.start_button", comment: ""))
                    .font(.custom("Poppins-Bold", size: 18))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 64)
            .background(
                ZStack {
                    // Shadow layer
                    RoundedRectangle(cornerRadius: 32)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.appTheme,
                                    Color.appThemeSecondary
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .blur(radius: 20)
                        .offset(y: 8)

                    // Main button
                    RoundedRectangle(cornerRadius: 32)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.appTheme,
                                    Color.appThemeSecondary
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

#Preview {
    NavigationStack {
        AntiStressBodyScanDetailView(
            exerciseType: .bodyScan,
            situation: .overwhelmed,
            viewModel: AntiStressViewModel()
        )
    }
}
