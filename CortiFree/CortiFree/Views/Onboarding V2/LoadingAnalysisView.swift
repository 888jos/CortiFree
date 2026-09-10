//
//  LoadingAnalysisView.swift
//  CortiFree
//
//  Created by Claude on 31/10/2025.
//  Loading screen with 0-100% progression animation
//

import SwiftUI

struct LoadingAnalysisView: View {
    private let speedMultiplier = 1.5

    @ObservedObject var languageManager = LanguageManager.shared
    let habitsQuizResult: HabitsQuizResult?
    let selectedSymptoms: Set<String>
    let onComplete: () -> Void
    @State private var displayedProgress: Int = 0
    @State private var currentSubtitle: String = "onboarding_v2.loading.understanding".localized
    @State private var showResultsButton: Bool = false
    @State private var screenViewTime: Date?

    init(
        habitsQuizResult: HabitsQuizResult? = nil,
        selectedSymptoms: Set<String> = [],
        onComplete: @escaping () -> Void
    ) {
        self.habitsQuizResult = habitsQuizResult
        self.selectedSymptoms = selectedSymptoms
        self.onComplete = onComplete
    }

    private var subtitles: [String] {
        guard let result = habitsQuizResult else {
            return [
                "onboarding_v2.loading.understanding".localized,
                "onboarding_v2.loading.profile_analysis".localized,
                "onboarding_v2.loading.data_processing".localized,
                "onboarding_v2.loading.personalizing".localized,
                "onboarding_v2.loading.plan_creation".localized,
                "onboarding_v2.loading.finalizing".localized
            ]
        }

        let isFrench = languageManager.currentLanguage == .french
        let goal = localizedGoal(result.primaryGoal, isFrench: isFrench)
        let time = result.availableTime
        let symptomCount = selectedSymptoms.count

        if isFrench {
            return [
                "Nous repérons les points qui pèsent le plus sur ton quotidien.",
                "Ton objectif prioritaire : \(goal.lowercased()).",
                "Nous ajustons le rythme à tes \(time) minutes disponibles par jour.",
                symptomCount > 0
                    ? "Nous intégrons les \(symptomCount) signaux que tu as sélectionnés."
                    : "Nous gardons ton parcours simple et progressif.",
                "Nous choisissons des exercices adaptés à ton niveau actuel.",
                "Ton parcours personnalisé est prêt."
            ]
        }

        return [
            "We are identifying what weighs most on your daily routine.",
            "Your priority: \(goal.lowercased()).",
            "We are matching the pace to your \(time) minutes per day.",
            symptomCount > 0
                ? "We are including the \(symptomCount) signals you selected."
                : "We are keeping your path simple and progressive.",
            "We are choosing exercises for your current level.",
            "Your personalized path is ready."
        ]
    }

    private func localizedGoal(_ goal: String, isFrench: Bool) -> String {
        switch goal {
        case "sleep": return isFrench ? "le sommeil" : "sleep"
        case "stress": return isFrench ? "le calme" : "calm"
        case "energy": return isFrench ? "l’énergie" : "energy"
        case "focus": return isFrench ? "la concentration" : "focus"
        default: return isFrench ? "l’équilibre" : "balance"
        }
    }

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
                                    Color(hex: "B794F6"),
                                    Color(hex: "D4B4FF")
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
                        .font(.faroBold(48))
                        .foregroundColor(.white)
                }

                // Title and subtitle grouped together with reduced spacing
                VStack(spacing: 12) {
                    // Title
                    Text("onboarding_v2.loading.calculating".localized)
                        .font(.faroBold(32))
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

                        if let startTime = screenViewTime {
                            let timeSpent = Date().timeIntervalSince(startTime)
                            MixpanelManager.shared.trackOnboardingLoadingAnalysisComplete(timeSpent: timeSpent)
                        }

                        onComplete()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.right")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.black)

                            Text("onboarding_v2.loading.see_plan".localized)
                                .font(.custom("Poppins-SemiBold", size: 16))
                                .foregroundColor(.black)
                        }
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
            screenViewTime = Date()
            MixpanelManager.shared.trackOnboardingLoadingAnalysisViewed()
            startProgressAnimation()
        }
    }

    private func startProgressAnimation() {
        // Six phases now complete in about five seconds total.
        let phaseDuration: Double = 1.25 / speedMultiplier

        // Phase 1: 0-17% avec "Compréhension des réponses"
        animatePhase(from: 0, to: 17, duration: phaseDuration, subtitle: subtitles[0]) {
            // Phase 2: 18-34% avec "Analyse de ton profil"
            self.animatePhase(from: 18, to: 34, duration: phaseDuration, subtitle: self.subtitles[1]) {
                // Phase 3: 35-51% avec "Traitement des données"
                self.animatePhase(from: 35, to: 51, duration: phaseDuration, subtitle: self.subtitles[2]) {
                    // Phase 4: 52-68% avec "Personnalisation du parcours"
                    self.animatePhase(from: 52, to: 68, duration: phaseDuration, subtitle: self.subtitles[3]) {
                        // Phase 5: 69-85% avec "Création du plan"
                        self.animatePhase(from: 69, to: 85, duration: phaseDuration, subtitle: self.subtitles[4]) {
                            // Phase 6: 86-100% avec "Finalisation des recommandations"
                            self.animatePhase(from: 86, to: 100, duration: phaseDuration, subtitle: self.subtitles[5]) {
                                // Show button at 100%
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    self.showResultsButton = true
                                }
                            }
                        }
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
