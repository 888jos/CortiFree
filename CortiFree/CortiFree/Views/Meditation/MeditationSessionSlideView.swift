//
//  MeditationSessionSlideView.swift
//  CortiFree
//
//  Created by Claude on 23/10/2025.
//  Vue de session guidée avec slides pour les méditations
//

import SwiftUI
import Lottie

struct MeditationSessionSlideView: View {
    let support: MeditationSupport
    @Environment(\.dismiss) private var dismiss
    @State private var currentSlide = 0
    @State private var pulseAnimation = false
    @State private var showConfetti = false
    @State private var showCompletion = false

    private var slides: [String] {
        guard let section = support.content.sections.first else { return [] }

        // Retourner les steps, affirmations, ou prompts selon le type
        if let steps = section.steps {
            return steps
        } else if let affirmations = section.affirmations {
            return affirmations
        } else if let prompts = section.prompts {
            return prompts
        }
        return ["Suivez les instructions à l'écran"]
    }

    private var totalSlides: Int {
        return slides.count
    }

    var body: some View {
        ZStack {
            // Galaxy background
            GalaxyBackgroundView(intensity: 1.0)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header avec progress
                header

                Spacer()

                // Slide content
                slideContent

                Spacer()

                // Navigation controls
                navigationControls
            }

            // Confetti
            if showConfetti {
                LottieView(
                    filename: "confetti",
                    loopMode: .playOnce
                )
                .ignoresSafeArea()
                .allowsHitTesting(false)
            }

            // Completion overlay
            if showCompletion {
                MeditationCompletionOverlay(
                    onDismiss: {
                        dismiss()
                    }
                )
                .transition(.opacity)
            }
        }
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                pulseAnimation = true
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 20) {
            HStack {
                Button(action: {
                    HapticManager.light()
                    dismiss()
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 44, height: 44)
                            .blur(radius: 8)

                        Circle()
                            .fill(Color(hex: "1A1B3A").opacity(0.9))
                            .frame(width: 44, height: 44)

                        Image(systemName: "xmark")
                            .font(.custom("Poppins-SemiBold", size: 16))
                            .foregroundColor(.white)
                    }
                }

                Spacer()

                // Badge exercice
                HStack(spacing: 6) {
                    Image(systemName: "brain.head.profile")
                        .font(.custom("Poppins-SemiBold", size: 12))
                    Text(support.title)
                        .font(.custom("Poppins-Bold", size: 11))
                        .lineLimit(1)
                }
                .foregroundColor(Color(hex: "B388FF"))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color(hex: "B388FF").opacity(0.15))
                        .overlay(
                            Capsule()
                                .stroke(Color(hex: "B388FF").opacity(0.4), lineWidth: 1)
                        )
                )
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)

            // Progress bar
            progressBar
        }
    }

    private var progressBar: some View {
        VStack(spacing: 8) {
            // Slide counter
            Text("\(currentSlide + 1) / \(totalSlides)")
                .font(.custom("Poppins-Medium", size: 13))
                .foregroundColor(.white.opacity(0.7))

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.15))
                        .frame(height: 6)

                    // Progress
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "B388FF"), Color(hex: "8C9EFF")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: geometry.size.width * CGFloat(currentSlide + 1) / CGFloat(totalSlides),
                            height: 6
                        )
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: currentSlide)
                }
            }
            .frame(height: 6)
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Slide Content

    private var slideContent: some View {
        VStack(spacing: 40) {
            // Animated icon
            ZStack {
                // Pulse circles
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: "B388FF").opacity(0.2),
                                Color(hex: "8C9EFF").opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 180, height: 180)
                    .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                    .opacity(pulseAnimation ? 0.3 : 0.6)

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: "B388FF").opacity(0.3),
                                Color(hex: "8C9EFF").opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 140, height: 140)
                    .scaleEffect(pulseAnimation ? 1.1 : 1.0)

                // Icon
                Image(systemName: slideIcon())
                    .font(.system(size: 50, weight: .regular))
                    .foregroundColor(.white)
                    .shadow(color: Color(hex: "B388FF").opacity(0.5), radius: 20)
            }

            // Slide text avec style
            VStack(spacing: 20) {
                // Numéro du slide avec style
                Text("Étape \(currentSlide + 1)")
                    .font(.custom("Poppins-Bold", size: 14))
                    .tracking(2)
                    .foregroundColor(Color(hex: "B388FF"))
                    .textCase(.uppercase)

                // Instruction principale
                Text(slides[currentSlide])
                    .font(.custom("Poppins-SemiBold", size: 24))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(8)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 32)
            }
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))
            .id(currentSlide) // Force re-render on slide change
        }
    }

    // MARK: - Navigation Controls

    private var navigationControls: some View {
        HStack(spacing: 20) {
            // Bouton Précédent
            if currentSlide > 0 {
                Button(action: {
                    HapticManager.light()
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        currentSlide -= 1
                    }
                }) {
                    HStack(spacing: 10) {
                        Image(systemName: "chevron.left")
                            .font(.custom("Poppins-SemiBold", size: 16))
                        Text("Précédent")
                            .font(.custom("Poppins-SemiBold", size: 16))
                    }
                    .foregroundColor(.white.opacity(0.8))
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 28)
                            .fill(Color.white.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 28)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(ScaleButtonStyle())
            }

            // Bouton Suivant / Terminer
            Button(action: {
                HapticManager.medium()
                if currentSlide < totalSlides - 1 {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        currentSlide += 1
                    }
                } else {
                    // Dernière slide - terminer avec succès et confettis
                    HapticManager.success()
                    withAnimation {
                        showConfetti = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation {
                            showCompletion = true
                        }
                    }
                }
            }) {
                HStack(spacing: 12) {
                    Text(currentSlide < totalSlides - 1 ? "Suivant" : "Terminer")
                        .font(.custom("Poppins-Bold", size: 18))
                    Image(systemName: currentSlide < totalSlides - 1 ? "chevron.right" : "checkmark.circle.fill")
                        .font(.custom("Poppins-SemiBold", size: 18))
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
                                    colors: [Color(hex: "B388FF"), Color(hex: "8C9EFF")],
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
                                    colors: [Color(hex: "B388FF"), Color(hex: "8C9EFF")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
                )
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 32)
    }

    // MARK: - Helper Methods

    private func slideIcon() -> String {
        // Icônes différentes selon le type de méditation et le slide
        switch support.meditationId {
        case "conscious-breathing":
            return ["wind", "lungs.fill", "heart.fill"][min(currentSlide, 2)]
        case "body-scan":
            return ["figure.stand", "figure.walk", "bed.double.fill"][min(currentSlide, 2)]
        case "mindfulness":
            return ["eye.fill", "brain.head.profile", "sparkles"][min(currentSlide, 2)]
        case "grounding":
            let icons = ["eye.fill", "hand.raised.fill", "ear.fill", "nose.fill", "mouth.fill"]
            return icons[min(currentSlide, icons.count - 1)]
        case "visualization":
            return ["moon.stars.fill", "sparkles", "cloud.fill"][min(currentSlide, 2)]
        case "compassion":
            return ["heart.fill", "hands.and.sparkles.fill", "face.smiling.fill"][min(currentSlide, 2)]
        case "focus-clarity":
            return ["target", "brain.head.profile", "lightbulb.fill"][min(currentSlide, 2)]
        case "yoga-nidra":
            return ["bed.double.fill", "moon.zzz.fill", "zzz"][min(currentSlide, 2)]
        default:
            return "brain.head.profile"
        }
    }
}

// MARK: - Meditation Completion Overlay

struct MeditationCompletionOverlay: View {
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // Success icon
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(Color(hex: "B794F6"))

                // Message
                Text("Méditation terminée")
                    .font(.custom("Poppins-SemiBold", size: 28))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text("🧘‍♂️")
                    .font(.system(size: 60))

                // Continue button
                Button(action: {
                    HapticManager.light()
                    onDismiss()
                }) {
                    Text("Continuer")
                        .font(.custom("Poppins-SemiBold", size: 18))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color(hex: "B794F6"),
                                    Color(hex: "D4B4FF")
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 40)
                .padding(.top, 8)
            }
            .padding(40)
        }
    }
}

#Preview {
    if let support = MeditationSupport.support(for: "grounding") {
        MeditationSessionSlideView(support: support)
    }
}
