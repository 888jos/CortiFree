//
//  GuidedMeditationSessionView.swift
//  CortiFree
//
//  Created by Claude on 24/10/2025.
//  Session de méditation guidée avec instructions étape par étape
//

import SwiftUI

struct GuidedMeditationSessionView: View {
    let support: MeditationSupport
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var planetSettings = PlanetSettings.shared

    @State private var currentStepIndex = 0
    @State private var isCompleted = false
    @State private var showConfetti = false
    @State private var showCompletion = false
    @State private var orbScale: CGFloat = 1.0

    private var allSteps: [String] {
        support.content.sections.flatMap { $0.steps ?? [] }
    }

    private var currentStep: String {
        guard currentStepIndex < allSteps.count else { return "Session terminée" }
        return allSteps[currentStepIndex]
    }

    private var isLastStep: Bool {
        currentStepIndex >= allSteps.count - 1
    }

    var body: some View {
        ZStack {
            // Galaxy background
            GalaxyBackgroundView(intensity: 0.8)

            VStack(spacing: 0) {
                // Header
                header

                Spacer()

                if !isCompleted {
                    // Orb respiratoire avec planète
                    breathingOrb
                        .padding(.bottom, 40)

                    // Progress indicator
                    progressIndicator
                        .padding(.bottom, 32)

                    // Current step
                    stepCard
                        .padding(.horizontal, 24)

                    Spacer()

                    // Navigation buttons
                    navigationButtons
                        .padding(.horizontal, 24)
                        .padding(.bottom, 40)
                }
            }

            // Completion overlay
            if showCompletion {
                CompletionOverlay(
                    onDismiss: {
                        dismiss()
                    }
                )
                .transition(.opacity)
            }

            // Confetti
            if showConfetti {
                ConfettiView()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
        }
        .onAppear {
            startOrbAnimation()
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.white.opacity(0.6))
            }

            Spacer()

            Text(support.title)
                .font(.custom("Poppins-SemiBold", size: 18))
                .foregroundColor(.white)

            Spacer()

            Color.clear
                .frame(width: 32, height: 32)
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
    }

    // MARK: - Breathing Orb

    private var breathingOrb: some View {
        BreathingCircle(
            planet: planetSettings.selectedPlanet,
            size: 180,
            haloOpacity: 0.5
        )
        .scaleEffect(orbScale)
    }

    // MARK: - Progress Indicator

    private var progressIndicator: some View {
        VStack(spacing: 8) {
            Text("Étape \(currentStepIndex + 1) sur \(allSteps.count)")
                .font(.custom("Poppins-Medium", size: 14))
                .foregroundColor(Color(hex: "B0B8D4"))

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    Capsule()
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 6)

                    // Progress
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color.appTheme, Color.appThemeSecondary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * CGFloat(currentStepIndex + 1) / CGFloat(allSteps.count), height: 6)
                        .animation(.easeInOut, value: currentStepIndex)
                }
            }
            .frame(height: 6)
        }
        .padding(.horizontal, 40)
    }

    // MARK: - Step Card

    private var stepCard: some View {
        VStack(spacing: 20) {
            Text("Instruction")
                .font(.custom("Poppins-SemiBold", size: 14))
                .foregroundColor(Color.appTheme)
                .textCase(.uppercase)
                .tracking(1.5)

            Text(currentStep)
                .font(.custom("Poppins-Regular", size: 18))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineSpacing(8)
                .padding(.horizontal, 16)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .padding(.horizontal, 24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.appTheme.opacity(0.3), lineWidth: 1)
                )
        )
    }

    // MARK: - Navigation Buttons

    private var navigationButtons: some View {
        HStack(spacing: 16) {
            // Previous button
            if currentStepIndex > 0 {
                Button(action: {
                    HapticManager.light()
                    withAnimation(.spring(response: 0.3)) {
                        currentStepIndex -= 1
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .font(.custom("Poppins-SemiBold", size: 18))
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.1))
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                        )
                }
            }

            Spacer()

            // Next/Complete button
            Button(action: {
                HapticManager.medium()
                if isLastStep {
                    completeSession()
                } else {
                    withAnimation(.spring(response: 0.3)) {
                        currentStepIndex += 1
                    }
                }
            }) {
                HStack(spacing: 12) {
                    Text(isLastStep ? "Terminer" : "Suivant")
                        .font(.custom("Poppins-SemiBold", size: 17))

                    Image(systemName: isLastStep ? "checkmark.circle.fill" : "chevron.right")
                        .font(.custom("Poppins-SemiBold", size: 20))
                }
                .foregroundColor(.white)
                .frame(maxWidth: isLastStep ? .infinity : nil)
                .frame(height: 56)
                .padding(.horizontal, isLastStep ? 0 : 32)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color.appTheme, Color.appThemeSecondary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
            }
        }
    }

    // MARK: - Helper Functions

    private func startOrbAnimation() {
        withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
            orbScale = 1.15
        }
    }

    private func completeSession() {
        // XP system removed - using scoring system instead

        HapticManager.success()

        withAnimation {
            isCompleted = true
            showConfetti = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation {
                showCompletion = true
            }
        }
    }
}

#Preview {
    if let support = MeditationSupport.support(for: "body-scan") {
        GuidedMeditationSessionView(support: support)
    }
}
