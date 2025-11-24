//
//  AntiStressBreathingDetailView.swift
//  CortiFree
//
//  Created by Claude on 21/11/2025.
//  Breathing exercise detail view for Anti-Stress flow
//

import SwiftUI

struct AntiStressBreathingDetailView: View {
    let exerciseType: AntiStressExerciseType
    let situation: StressSituation
    @ObservedObject var viewModel: AntiStressViewModel
    @Environment(\.dismiss) var dismiss

    @State private var selectedDuration: Int = 180 // 3 minutes par défaut
    @State private var showBreathingExercise = false
    @State private var pulseAnimation = false
    @State private var showHowItWorks = true
    @State private var showScience = false

    private let durations = [60, 120, 180, 300, 600] // 1min, 2min, 3min, 5min, 10min

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

                        // Preuves scientifiques
                        scientificEvidenceCard

                        // Spacer to push duration and button to bottom
                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 180) // Space for fixed bottom section
                }

                // FIXED BOTTOM SECTION - Duration + Button
                fixedBottomSection
            }
        }
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                pulseAnimation = true
            }
        }
        .fullScreenCover(isPresented: $showBreathingExercise) {
            BreathingExerciseView(
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
                    Image(systemName: "wind")
                        .font(.system(size: 12))
                    Text(NSLocalizedString("breathing_detail.category_badge", comment: ""))
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
            Text(exerciseType.displayName)
                .font(.custom("Poppins-Bold", size: 28))
                .foregroundColor(.white)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)

            // Description courte
            Text(exerciseType.description)
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

                    Text(NSLocalizedString("breathing_detail.how_it_works", comment: ""))
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
                    Text(howItWorksText)
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

    private var howItWorksText: String {
        switch exerciseType {
        case .guidedBreathing, .consciousBreathing:
            return NSLocalizedString("breathing_detail.how_it_works.deep_abdominal", comment: "")
        case .cardiacCoherence:
            return NSLocalizedString("breathing_detail.how_it_works.cardiac_coherence", comment: "")
        case .boxBreathing:
            return NSLocalizedString("breathing_detail.how_it_works.box_breathing", comment: "")
        case .alternateBreathing:
            return NSLocalizedString("breathing_detail.how_it_works.alternate_breathing", comment: "")
        default:
            return NSLocalizedString("breathing_detail.how_it_works.default", comment: "")
        }
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

                    Text(NSLocalizedString("breathing_detail.scientific_evidence", comment: ""))
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

                        // Source
                        HStack(spacing: 8) {
                            Image(systemName: "doc.text.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.5))

                            Text(scientificSource)
                                .font(.custom("Poppins-Regular", size: 12))
                                .foregroundColor(.white.opacity(0.6))
                                .italic()
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
        switch exerciseType {
        case .cardiacCoherence:
            return [
                NSLocalizedString("breathing_detail.evidence.cardiac_coherence_1", comment: ""),
                NSLocalizedString("breathing_detail.evidence.cardiac_coherence_2", comment: ""),
                NSLocalizedString("breathing_detail.evidence.cardiac_coherence_3", comment: "")
            ]
        case .boxBreathing:
            return [
                NSLocalizedString("breathing_detail.evidence.box_breathing_1", comment: ""),
                NSLocalizedString("breathing_detail.evidence.box_breathing_2", comment: ""),
                NSLocalizedString("breathing_detail.evidence.box_breathing_3", comment: "")
            ]
        case .alternateBreathing:
            return [
                NSLocalizedString("breathing_detail.evidence.alternate_breathing_1", comment: ""),
                NSLocalizedString("breathing_detail.evidence.alternate_breathing_2", comment: ""),
                NSLocalizedString("breathing_detail.evidence.alternate_breathing_3", comment: "")
            ]
        default:
            return [
                NSLocalizedString("breathing_detail.evidence.default_1", comment: ""),
                NSLocalizedString("breathing_detail.evidence.default_2", comment: ""),
                NSLocalizedString("breathing_detail.evidence.default_3", comment: "")
            ]
        }
    }

    private var scientificSource: String {
        return NSLocalizedString("breathing_detail.source", comment: "")
    }

    // MARK: - Benefits Section

    private var benefitsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "heart.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Color.appTheme)

                Text(NSLocalizedString("breathing_detail.benefits", comment: ""))
                    .font(.custom("Poppins-SemiBold", size: 18))
                    .foregroundColor(.white)
            }

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(Array(benefits.enumerated()), id: \.offset) { index, benefit in
                    BenefitBadge(benefit: benefit, index: index)
                }
            }
        }
    }

    private var benefits: [String] {
        return [
            NSLocalizedString("breathing_detail.benefit.reduce_stress", comment: ""),
            NSLocalizedString("breathing_detail.benefit.calm_heart", comment: ""),
            NSLocalizedString("breathing_detail.benefit.improve_sleep", comment: ""),
            NSLocalizedString("breathing_detail.benefit.soothe_mind", comment: "")
        ]
    }

    // MARK: - FIXED BOTTOM SECTION (Duration + Button)

    private var fixedBottomSection: some View {
        VStack(spacing: 16) {
            // Duration Selector
            gamifiedDurationSelector

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

    // MARK: - Modern Duration Selector

    private var gamifiedDurationSelector: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "clock.fill")
                    .font(.system(size: 18))
                    .foregroundColor(Color.appTheme)

                Text(NSLocalizedString("breathing_detail.exercise_duration", comment: ""))
                    .font(.custom("Poppins-SemiBold", size: 16))
                    .foregroundColor(.white)

                Spacer()

                // Display selected duration
                Text(formatDuration(selectedDuration))
                    .font(.custom("Poppins-Bold", size: 18))
                    .foregroundColor(Color.appTheme)
                    .monospacedDigit()
            }

            // Modern segmented control
            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    ForEach(durations, id: \.self) { duration in
                        DurationPill(
                            duration: duration,
                            isSelected: selectedDuration == duration
                        ) {
                            HapticManager.light()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedDuration = duration
                            }
                        }
                    }
                }

                // Visual indicator bar
                GeometryReader { geometry in
                    let pillWidth = (geometry.size.width - CGFloat((durations.count - 1) * 8)) / CGFloat(durations.count)
                    let selectedIndex = durations.firstIndex(of: selectedDuration) ?? 0

                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            LinearGradient(
                                colors: [Color.appTheme, Color.appThemeSecondary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: pillWidth, height: 4)
                        .offset(x: CGFloat(selectedIndex) * (pillWidth + 8))
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedDuration)
                }
                .frame(height: 4)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
    }

    private func formatDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        return "\(minutes) min"
    }

    // MARK: - Launch Button

    private var launchButton: some View {
        Button(action: {
            HapticManager.success()
            showBreathingExercise = true
        }) {
            HStack(spacing: 12) {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 24))

                Text(NSLocalizedString("breathing_detail.start_exercise", comment: ""))
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
        AntiStressBreathingDetailView(
            exerciseType: .guidedBreathing,
            situation: .overwhelmed,
            viewModel: AntiStressViewModel()
        )
    }
}
