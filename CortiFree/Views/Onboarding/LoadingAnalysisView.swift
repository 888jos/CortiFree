//
//  LoadingAnalysisView.swift
//  CortiFree
//
//  Created by Claude on 31/10/2025.
//  Loading screen with 0-100% progression animation
//

import SwiftUI

struct LoadingAnalysisView: View {
    @State private var displayedProgress: Int = 0
    @State private var currentSubtitle: String = "Compréhension des réponses"
    @State private var showResultsButton: Bool = false
    let onComplete: () -> Void

    private let subtitles = [
        "Compréhension des réponses",
        "Traitement des données",
        "Création du plan"
    ]

    var body: some View {
        ZStack {
            // Galaxy background with stars
            GalaxyBackgroundView()
                .ignoresSafeArea()

            VStack(spacing: 48) {
                Spacer()

                // Circular progress
                ZStack {
                    // Background circle
                    Circle()
                        .stroke(Color(hex: "808080").opacity(0.3), lineWidth: 20)
                        .frame(width: 220, height: 220)

                    // Progress circle
                    Circle()
                        .trim(from: 0, to: Double(displayedProgress) / 100.0)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(hex: "73DE85"),
                                    Color(hex: "53D7D9")
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 20, lineCap: .round)
                        )
                        .frame(width: 220, height: 220)
                        .rotationEffect(.degrees(-90))

                    // Percentage text
                    Text("\(displayedProgress)%")
                        .font(.custom("Poppins-Bold", size: 48))
                        .foregroundColor(.white)
                }

                // Title and subtitle grouped together with reduced spacing
                VStack(spacing: 12) {
                    // Title
                    Text("Calcul en cours")
                        .font(.custom("Poppins-Bold", size: 32))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    // Subtitle (changes with progress)
                    Text(currentSubtitle)
                        .font(.custom("Poppins-Medium", size: 16))
                        .foregroundColor(Color(hex: "808080"))
                        .multilineTextAlignment(.center)
                        .animation(.easeInOut(duration: 0.3), value: currentSubtitle)
                }

                Spacer()

                // Results button (appears at 100%)
                if showResultsButton {
                    Button(action: {
                        HapticManager.light()
                        onComplete()
                    }) {
                        Text("Afficher mes résultats")
                            .font(.custom("Poppins-SemiBold", size: 16))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 42))
                    }
                    .padding(.horizontal, 34)
                    .padding(.bottom, 60)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .padding(.horizontal, 36)
        }
        .onAppear {
            startProgressAnimation()
        }
    }

    private func startProgressAnimation() {
        // 3 phases of 2.5s each = 7.5s total
        let phaseDuration: Double = 2.5
        let updateInterval: Double = 0.04 // Update every 40ms (25 FPS)

        // Phase 1: 0-33% avec "Compréhension des réponses"
        animatePhase(from: 0, to: 33, duration: phaseDuration, subtitle: subtitles[0]) {
            // Phase 2: 34-66% avec "Traitement des données"
            self.animatePhase(from: 34, to: 66, duration: phaseDuration, subtitle: self.subtitles[1]) {
                // Phase 3: 67-100% avec "Création du plan"
                self.animatePhase(from: 67, to: 100, duration: phaseDuration, subtitle: self.subtitles[2]) {
                    // Show button at 100%
                    withAnimation(.easeInOut(duration: 0.3)) {
                        self.showResultsButton = true
                    }
                }
            }
        }
    }

    private func animatePhase(from startProgress: Int, to endProgress: Int, duration: Double, subtitle: String, completion: @escaping () -> Void) {
        // Update subtitle
        withAnimation(.easeInOut(duration: 0.3)) {
            currentSubtitle = subtitle
        }

        let updateInterval: Double = 0.04
        let totalSteps = Int(duration / updateInterval)
        let progressRange = endProgress - startProgress

        var currentIteration = 0
        var hapticCounter = 0

        Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { timer in
            currentIteration += 1
            hapticCounter += 1

            // Calculate progress for this phase
            let phaseProgress = Double(currentIteration) / Double(totalSteps)
            let newProgress = startProgress + Int(phaseProgress * Double(progressRange))

            withAnimation(.linear(duration: updateInterval)) {
                displayedProgress = min(newProgress, endProgress)
            }

            // Vibration continue qui s'amplifie progressivement
            // Calculer l'intervalle de vibration basé sur la progression (0-100%)
            let globalProgress = Double(displayedProgress) / 100.0

            // Intervalle de vibration qui diminue avec la progression (vibration plus fréquente = plus intense)
            // 0%: vibration toutes les 25 frames (~1 seconde)
            // 50%: vibration toutes les 15 frames (~0.6 seconde)
            // 100%: vibration toutes les 5 frames (~0.2 seconde)
            let vibrationInterval = Int(25 - (globalProgress * 20)) // De 25 à 5

            if hapticCounter % vibrationInterval == 0 {
                // Intensité de la vibration basée sur la progression
                if globalProgress < 0.33 {
                    HapticManager.light()
                } else if globalProgress < 0.66 {
                    HapticManager.medium()
                } else {
                    HapticManager.heavy()
                }
            }

            // Complete phase when done
            if currentIteration >= totalSteps {
                timer.invalidate()
                displayedProgress = endProgress
                completion()
            }
        }
    }
}

#Preview {
    LoadingAnalysisView(onComplete: {})
}
