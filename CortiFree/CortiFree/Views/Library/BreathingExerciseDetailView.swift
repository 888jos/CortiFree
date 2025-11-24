//
//  BreathingExerciseDetailView.swift
//  CortiFree
//
//  Created by Claude on 23/10/2025.
//  Version gamifiée et engageante avec UX améliorée
//

import SwiftUI

struct BreathingExerciseDetailView: View {
    let pattern: BreathingPattern
    @Environment(\.dismiss) var dismiss
    @State private var selectedDuration: Int = 180 // 3 minutes par défaut
    @State private var showBreathingExercise = false
    @State private var pulseAnimation = false
    @State private var showHowItWorks = true // Expandable card state
    @State private var showScience = false // Preuves scientifiques

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

                        // Preuves scientifiques - NOUVEAU
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
            LibraryBreathingView(
                pattern: pattern,
                totalDuration: Double(selectedDuration)
            ) {
                showBreathingExercise = false
                dismiss()
            }
        }
    }

    // MARK: - Animated Header

    private var animatedHeader: some View {
        ZStack(alignment: .topLeading) {
            // Gradient header background
            LinearGradient(
                colors: [
                    Color(hex: "49288C").opacity(0.3),
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

    // MARK: - Compact Title Section (replaces Hero)

    private var compactTitleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title
            Text(pattern.displayName)
                .font(.custom("Poppins-Bold", size: 28))
                .foregroundColor(.white)

            // Description courte
            Text(pattern.description)
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
                    Text(pattern.detailedDescription)
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
                        ForEach(pattern.scientificEvidence, id: \.self) { evidence in
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

                            Text(pattern.scientificSource)
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
                ForEach(Array(pattern.benefits.enumerated()), id: \.offset) { index, benefit in
                    BenefitBadge(benefit: benefit, index: index)
                }
            }
        }
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

                // Display selected duration with REDUCED font size
                Text(formatDuration(selectedDuration))
                    .font(.custom("Poppins-Bold", size: 18)) // Reduced from 24
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

    // CHANGED: Always use "min" format instead of "m"
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

// MARK: - Benefit Badge Component

struct BenefitBadge: View {
    let benefit: String
    let index: Int

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.appTheme, Color.appThemeSecondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 24, height: 24)

                Image(systemName: "checkmark")
                    .font(.custom("Poppins-Bold", size: 12))
                    .foregroundColor(.white)
            }

            Text(benefit)
                .font(.custom("Poppins-Medium", size: 14))
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 12)
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

                RoundedRectangle(cornerRadius: 12)
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
}

// MARK: - BreathingPattern Extension

extension BreathingPattern {
    var icon: String {
        switch name {
        case "DeepAbdominal": return "wind"
        case "4-7-8": return "moon.stars.fill"
        case "Coherence": return "heart.fill"
        case "Slow66": return "bed.double.fill"
        case "Triangle": return "triangle"
        case "Box": return "square"
        case "Kapalabhati": return "bolt.fill"
        case "Bhastrika": return "flame.fill"
        default: return "wind"
        }
    }

    var detailedDescription: String {
        switch name {
        case "DeepAbdominal":
            return NSLocalizedString("breathing_pattern.deep_abdominal.detailed_description", comment: "")
        case "4-7-8":
            return NSLocalizedString("breathing_pattern.four_seven_eight.detailed_description", comment: "")
        case "Coherence":
            return NSLocalizedString("breathing_pattern.coherence.detailed_description", comment: "")
        case "Slow66":
            return NSLocalizedString("breathing_pattern.slow66.detailed_description", comment: "")
        case "Triangle":
            return NSLocalizedString("breathing_pattern.triangle.detailed_description", comment: "")
        case "Box":
            return NSLocalizedString("breathing_pattern.box.detailed_description", comment: "")
        case "Kapalabhati":
            return NSLocalizedString("breathing_pattern.kapalabhati.detailed_description", comment: "")
        case "Bhastrika":
            return NSLocalizedString("breathing_pattern.bhastrika.detailed_description", comment: "")
        default:
            return description
        }
    }

    var benefits: [String] {
        switch name {
        case "DeepAbdominal":
            return [
                NSLocalizedString("breathing_pattern.deep_abdominal.benefit_1", comment: ""),
                NSLocalizedString("breathing_pattern.deep_abdominal.benefit_2", comment: ""),
                NSLocalizedString("breathing_pattern.deep_abdominal.benefit_3", comment: ""),
                NSLocalizedString("breathing_pattern.deep_abdominal.benefit_4", comment: "")
            ]
        case "4-7-8":
            return [
                NSLocalizedString("breathing_pattern.four_seven_eight.benefit_1", comment: ""),
                NSLocalizedString("breathing_pattern.four_seven_eight.benefit_2", comment: ""),
                NSLocalizedString("breathing_pattern.four_seven_eight.benefit_3", comment: ""),
                NSLocalizedString("breathing_pattern.four_seven_eight.benefit_4", comment: "")
            ]
        case "Coherence":
            return [
                NSLocalizedString("breathing_pattern.coherence.benefit_1", comment: ""),
                NSLocalizedString("breathing_pattern.coherence.benefit_2", comment: ""),
                NSLocalizedString("breathing_pattern.coherence.benefit_3", comment: ""),
                NSLocalizedString("breathing_pattern.coherence.benefit_4", comment: "")
            ]
        case "Slow66":
            return [
                NSLocalizedString("breathing_pattern.slow66.benefit_1", comment: ""),
                NSLocalizedString("breathing_pattern.slow66.benefit_2", comment: ""),
                NSLocalizedString("breathing_pattern.slow66.benefit_3", comment: ""),
                NSLocalizedString("breathing_pattern.slow66.benefit_4", comment: "")
            ]
        case "Triangle":
            return [
                NSLocalizedString("breathing_pattern.triangle.benefit_1", comment: ""),
                NSLocalizedString("breathing_pattern.triangle.benefit_2", comment: ""),
                NSLocalizedString("breathing_pattern.triangle.benefit_3", comment: ""),
                NSLocalizedString("breathing_pattern.triangle.benefit_4", comment: "")
            ]
        case "Box":
            return [
                NSLocalizedString("breathing_pattern.box.benefit_1", comment: ""),
                NSLocalizedString("breathing_pattern.box.benefit_2", comment: ""),
                NSLocalizedString("breathing_pattern.box.benefit_3", comment: ""),
                NSLocalizedString("breathing_pattern.box.benefit_4", comment: "")
            ]
        case "Kapalabhati":
            return [
                NSLocalizedString("breathing_pattern.kapalabhati.benefit_1", comment: ""),
                NSLocalizedString("breathing_pattern.kapalabhati.benefit_2", comment: ""),
                NSLocalizedString("breathing_pattern.kapalabhati.benefit_3", comment: ""),
                NSLocalizedString("breathing_pattern.kapalabhati.benefit_4", comment: "")
            ]
        case "Bhastrika":
            return [
                NSLocalizedString("breathing_pattern.bhastrika.benefit_1", comment: ""),
                NSLocalizedString("breathing_pattern.bhastrika.benefit_2", comment: ""),
                NSLocalizedString("breathing_pattern.bhastrika.benefit_3", comment: ""),
                NSLocalizedString("breathing_pattern.bhastrika.benefit_4", comment: "")
            ]
        default:
            return []
        }
    }

    var scientificEvidence: [String] {
        switch name {
        case "DeepAbdominal":
            return [
                NSLocalizedString("breathing_pattern.deep_abdominal.evidence_1", comment: ""),
                NSLocalizedString("breathing_pattern.deep_abdominal.evidence_2", comment: ""),
                NSLocalizedString("breathing_pattern.deep_abdominal.evidence_3", comment: "")
            ]
        case "4-7-8":
            return [
                NSLocalizedString("breathing_pattern.four_seven_eight.evidence_1", comment: ""),
                NSLocalizedString("breathing_pattern.four_seven_eight.evidence_2", comment: ""),
                NSLocalizedString("breathing_pattern.four_seven_eight.evidence_3", comment: "")
            ]
        case "Coherence":
            return [
                NSLocalizedString("breathing_pattern.coherence.evidence_1", comment: ""),
                NSLocalizedString("breathing_pattern.coherence.evidence_2", comment: ""),
                NSLocalizedString("breathing_pattern.coherence.evidence_3", comment: "")
            ]
        case "Slow66":
            return [
                NSLocalizedString("breathing_pattern.slow66.evidence_1", comment: ""),
                NSLocalizedString("breathing_pattern.slow66.evidence_2", comment: ""),
                NSLocalizedString("breathing_pattern.slow66.evidence_3", comment: "")
            ]
        case "Triangle":
            return [
                NSLocalizedString("breathing_pattern.triangle.evidence_1", comment: ""),
                NSLocalizedString("breathing_pattern.triangle.evidence_2", comment: ""),
                NSLocalizedString("breathing_pattern.triangle.evidence_3", comment: "")
            ]
        case "Box":
            return [
                NSLocalizedString("breathing_pattern.box.evidence_1", comment: ""),
                NSLocalizedString("breathing_pattern.box.evidence_2", comment: ""),
                NSLocalizedString("breathing_pattern.box.evidence_3", comment: "")
            ]
        case "Kapalabhati":
            return [
                NSLocalizedString("breathing_pattern.kapalabhati.evidence_1", comment: ""),
                NSLocalizedString("breathing_pattern.kapalabhati.evidence_2", comment: ""),
                NSLocalizedString("breathing_pattern.kapalabhati.evidence_3", comment: "")
            ]
        case "Bhastrika":
            return [
                NSLocalizedString("breathing_pattern.bhastrika.evidence_1", comment: ""),
                NSLocalizedString("breathing_pattern.bhastrika.evidence_2", comment: ""),
                NSLocalizedString("breathing_pattern.bhastrika.evidence_3", comment: "")
            ]
        default:
            return [NSLocalizedString("breathing_pattern.default.evidence", comment: "")]
        }
    }

    var scientificSource: String {
        switch name {
        case "DeepAbdominal": return NSLocalizedString("breathing_pattern.deep_abdominal.source", comment: "")
        case "4-7-8": return NSLocalizedString("breathing_pattern.four_seven_eight.source", comment: "")
        case "Coherence": return NSLocalizedString("breathing_pattern.coherence.source", comment: "")
        case "Slow66": return NSLocalizedString("breathing_pattern.slow66.source", comment: "")
        case "Triangle": return NSLocalizedString("breathing_pattern.triangle.source", comment: "")
        case "Box": return NSLocalizedString("breathing_pattern.box.source", comment: "")
        case "Kapalabhati": return NSLocalizedString("breathing_pattern.kapalabhati.source", comment: "")
        case "Bhastrika": return NSLocalizedString("breathing_pattern.bhastrika.source", comment: "")
        default: return NSLocalizedString("breathing_pattern.default.source", comment: "")
        }
    }
}

#Preview {
    BreathingExerciseDetailView(pattern: .fourSevenEight)
}
