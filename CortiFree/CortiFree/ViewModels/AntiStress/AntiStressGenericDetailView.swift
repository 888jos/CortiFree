//
//  AntiStressGenericDetailView.swift
//  CortiFree
//
//  Created by Claude on 22/11/2025.
//  Generic detail view for remaining Anti-Stress exercises
//

import SwiftUI

struct AntiStressGenericDetailView: View {
    let exerciseType: AntiStressExerciseType
    let situation: StressSituation
    @ObservedObject var viewModel: AntiStressViewModel
    @Environment(\.dismiss) var dismiss

    @State private var showExercise = false
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

                        // Bienfaits avec badges (SANS background général)
                        benefitsSection

                        // Preuves scientifiques (APRÈS les bienfaits)
                        scientificEvidenceCard

                        // Spacer to push button to bottom
                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 120) // Space for fixed bottom section
                }

                // FIXED BOTTOM SECTION - Button only
                fixedBottomSection
            }
        }
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                pulseAnimation = true
            }
        }
        .fullScreenCover(isPresented: $showExercise) {
            InstructionExerciseView(
                exerciseType: exerciseType,
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
                    Image(systemName: "chevron.left")
                        .font(.custom("Poppins-SemiBold", size: 16))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .glassCircle(interactive: true)

                Spacer()

                // Category badge
                HStack(spacing: 6) {
                    Image(systemName: categoryIcon)
                        .font(.system(size: 12))
                    Text(categoryText)
                        .font(.custom("Poppins-Bold", size: 11))
                }
                .foregroundColor(Color.appTheme)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .glassCapsule(tint: Color.appTheme)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
        }
    }

    // MARK: - Compact Title Section

    private var compactTitleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title
            Text(exerciseType.displayName)
                .font(.faroBold(28))
                .foregroundColor(.white)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)

            // Description courte
            Text(exerciseDescription)
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

                    Text(LanguageManager.shared.localizedString(for: "antistress.how_it_works"))
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
                    Text(exerciseType.detailedDescription)
                        .font(.custom("Poppins-Regular", size: 15))
                        .foregroundColor(Color(hex: "E5E5E5"))
                        .lineSpacing(8)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .glassCard(cornerRadius: 20, interactive: true)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Preuves scientifiques

    private var scientificEvidenceCard: some View {
        Button(action: {
            HapticManager.light()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                showScience.toggle()
            }
        }) {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 20))
                        .foregroundColor(Color.appTheme)

                    Text(LanguageManager.shared.localizedString(for: "antistress.scientific_evidence"))
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
                        ForEach(exerciseType.scientificEvidence, id: \.self) { evidence in
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
                            ForEach(exerciseType.scientificSources, id: \.self) { source in
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
            .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .glassCard(cornerRadius: 20, interactive: true)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Benefits Section

    private var benefitsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "heart.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Color.appTheme)

                Text(LanguageManager.shared.localizedString(for: "antistress.benefits"))
                    .font(.custom("Poppins-SemiBold", size: 18))
                    .foregroundColor(.white)
            }

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(Array(exerciseType.benefits.enumerated()), id: \.offset) { index, benefit in
                    BenefitBadge(benefit: benefit, index: index)
                }
            }
        }
    }

    // MARK: - FIXED BOTTOM SECTION

    private var fixedBottomSection: some View {
        VStack(spacing: 16) {
            // Launch Button
            launchButton
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
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
            showExercise = true
        }) {
            HStack(spacing: 12) {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 24))

                Text(LanguageManager.shared.localizedString(for: "antistress.start_button"))
                    .font(.custom("Poppins-Bold", size: 18))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 64)
            .contentShape(Capsule())
        }
        .buttonStyle(.glassPrimary(tint: Color.appTheme))
    }

    // MARK: - Exercise-specific content

    private var categoryIcon: String {
        switch exerciseType {
        case .slowWalk, .consciousStretching:
            return "figure.walk"
        case .audioRelaxation, .whiteNoise:
            return "waveform"
        case .positiveMantra:
            return "sparkles"
        case .visualMicroBreak:
            return "eye.fill"
        default:
            return "star.fill"
        }
    }

    private var categoryText: String {
        switch exerciseType {
        case .slowWalk, .consciousStretching:
            return LanguageManager.shared.localizedString(for: "antistress.category.movement")
        case .audioRelaxation, .whiteNoise:
            return LanguageManager.shared.localizedString(for: "antistress.category.audio")
        case .positiveMantra:
            return LanguageManager.shared.localizedString(for: "antistress.category.mental")
        case .visualMicroBreak:
            return LanguageManager.shared.localizedString(for: "antistress.category.visual")
        default:
            return LanguageManager.shared.localizedString(for: "antistress.category.exercise")
        }
    }

    private var exerciseDescription: String {
        switch exerciseType {
        case .slowWalk:
            return LanguageManager.shared.localizedString(for: "antistress.slow_walk.subtitle")
        case .consciousStretching:
            return LanguageManager.shared.localizedString(for: "antistress.conscious_stretching.subtitle")
        case .audioRelaxation:
            return LanguageManager.shared.localizedString(for: "antistress.audio_relaxation.subtitle")
        case .whiteNoise:
            return LanguageManager.shared.localizedString(for: "antistress.white_noise.subtitle")
        case .positiveMantra:
            return LanguageManager.shared.localizedString(for: "antistress.positive_mantra.subtitle")
        case .visualMicroBreak:
            return LanguageManager.shared.localizedString(for: "antistress.visual_micro_break.subtitle")
        default:
            return LanguageManager.shared.localizedString(for: "antistress.default.subtitle")
        }
    }

}

#Preview {
    NavigationStack {
        AntiStressGenericDetailView(
            exerciseType: .slowWalk,
            situation: .overwhelmed,
            viewModel: AntiStressViewModel()
        )
    }
}
