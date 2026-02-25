//
//  HabitsQuizView.swift
//  CortiFree
//
//  Created by Claude on 11/11/2025.
//  Quiz de prise de conscience du stress - 12 questions situationnelles
//  Q1-Q8: Questions pour calculer les scores (stress, sommeil, énergie, focus)
//  Q9: Question apparence physique (profil uniquement, pas de scoring)
//  Q10: Question marketing (expérience apps) - acquisition removed (duplicate with Overall quiz)
//  Q11-Q12: Objectif et temps disponible
//

import SwiftUI

struct HabitsQuizView: View {
    let onComplete: (HabitsQuizResult) -> Void

    @ObservedObject var languageManager = LanguageManager.shared
    @State private var currentQuestionIndex: Int = 0
    @State private var selectedAnswer: Int? = nil
    @State private var answers: [Int] = Array(repeating: 0, count: 12)
    @State private var isGoingBack: Bool = false
    @State private var questionStartTime: Date?
    @State private var quizStartTime: Date?

    private let totalQuestions = 12

    private var progress: Double {
        Double(currentQuestionIndex) / Double(totalQuestions)
    }

    private var currentQuestionNumber: Int {
        currentQuestionIndex + 1
    }

    var body: some View {
        ZStack {
            // Galaxy background (same as app)
            GalaxyBackgroundView(intensity: 1.0)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // Navigation header
                    headerSection
                        .padding(.top, 50)

                    // Question content with fixed title
                    VStack(spacing: 0) {
                    // Fixed Question Number Title
                    Text("Question #\(currentQuestionNumber)")
                        .font(.faroBold(24))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 30)
                        .id("questionTitle") // Keep it stable

                    // Sliding content
                    questionContent
                        .id(currentQuestionIndex)
                        .transition(.asymmetric(
                            insertion: .move(edge: isGoingBack ? .leading : .trailing),
                            removal: .move(edge: isGoingBack ? .trailing : .leading)
                        ))
                }

                    Spacer(minLength: 100)
                }
            }
        }
        .animation(.easeInOut(duration: 0.5), value: currentQuestionIndex)
        .onAppear {
            // Track quiz started
            quizStartTime = Date()
            questionStartTime = Date()
            MixpanelManager.shared.trackOnboardingHabitsQuizViewed()
            trackQuestionViewed(0)
        }
        .onChange(of: currentQuestionIndex) { _, newValue in
            // Reset timer when question changes
            questionStartTime = Date()
            trackQuestionViewed(newValue)
        }
    }

    // MARK: - Question Tracking

    private func trackQuestionViewed(_ index: Int) {
        let question = getQuestion(at: index)
        MixpanelManager.shared.trackOnboardingQuizQuestionViewed(
            questionNumber: index + 1,
            questionText: question.text
        )
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack(spacing: 0) {
            // Back button (left)
            Button(action: {
                HapticManager.light()
                if currentQuestionIndex > 0 {
                    // Track back button click
                    MixpanelManager.shared.trackOnboardingQuizBackClicked(
                        fromQuestionNumber: currentQuestionIndex + 1
                    )

                    isGoingBack = true
                    withAnimation(.easeInOut(duration: 0.5)) {
                        currentQuestionIndex -= 1
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        isGoingBack = false
                    }
                }
            }) {
                Image(systemName: "chevron.left")
                    .font(.custom("Poppins-Bold", size: 22))
                    .foregroundColor(.white)
                    .frame(width: 20, height: 20)
            }
            .padding(.leading, 30)
            .opacity(currentQuestionIndex > 0 ? 1.0 : 0.0)

            // Progress bar (center)
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(hex: "1D1D1D"))
                        .frame(height: 8)

                    // Progress fill
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hex: "B794F6"),
                                    Color(hex: "D4B4FF")
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progress, height: 8)
                        .animation(.easeInOut(duration: 0.3), value: progress)
                }
            }
            .frame(height: 8)
            .padding(.horizontal, 16)

            // Language selector button (right)
            LanguageSelectorButton()
                .padding(.trailing, 30)
        }
        .frame(height: 20)
    }

    // MARK: - Question Content

    @ViewBuilder
    private var questionContent: some View {
        let question = getQuestion(at: currentQuestionIndex)

        VStack(alignment: .leading, spacing: 16) {
            // Question text
            Text(question.text)
                .font(.faroRegular(18))
                .foregroundColor(.white)
                .lineSpacing(4)
                .padding(.horizontal, 32)
                .padding(.top, 20)
                .padding(.bottom, 20)

            // Answers
            answersView(options: question.options)
        }
    }

    // MARK: - Answer Buttons

    private func answersView(options: [String]) -> some View {
        VStack(spacing: 22) {
            ForEach(0..<options.count, id: \.self) { index in
                HabitsAnswerButton(
                    number: index + 1,
                    text: options[index],
                    isSelected: selectedAnswer == index,
                    onTap: {
                        HapticManager.light()
                        withAnimation(.easeInOut(duration: 0.5)) {
                            selectedAnswer = index
                        }

                        // Track the answer
                        let question = getQuestion(at: currentQuestionIndex)
                        let timeToAnswer = questionStartTime.map { Date().timeIntervalSince($0) } ?? 0.0

                        MixpanelManager.shared.trackOnboardingQuizQuestionAnswered(
                            questionNumber: currentQuestionIndex + 1,
                            questionText: question.text,
                            answerIndex: index,
                            answerText: options[index],
                            timeToAnswer: timeToAnswer
                        )

                        // Save answer and advance
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                            answers[currentQuestionIndex] = index
                            advanceToNextQuestion()
                        }
                    }
                )
            }
        }
        .padding(.horizontal, 34)
        .padding(.bottom, 40)
    }

    // MARK: - Navigation

    private func advanceToNextQuestion() {
        if currentQuestionIndex < totalQuestions - 1 {
            isGoingBack = false
            withAnimation(.easeInOut(duration: 0.5)) {
                currentQuestionIndex += 1
                selectedAnswer = nil
            }
        } else {
            // Quiz complete
            calculateAndComplete()
        }
    }

    // MARK: - Calculate Scores

    private func calculateAndComplete() {
        let result = HabitsQuizResult(answers: answers)

        // Calculate total time spent on quiz
        let totalTime = quizStartTime.map { Date().timeIntervalSince($0) } ?? 0.0

        // Track quiz completion with scores and marketing data
        MixpanelManager.shared.trackOnboardingHabitsQuizCompleted(
            totalTime: totalTime,
            serenityScore: result.serenityScore,
            sleepScore: result.sleepScore,
            energyScore: result.energyScore,
            focusScore: result.focusScore,
            habitsScore: result.habitsScore,
            balanceScore: result.balanceScore,
            globalScore: result.globalScore,
            appearanceConcern: result.appearanceConcern,
            baselineWakeTime: nil,
            baselineSleepDuration: nil,
            baselineWaterIntake: nil,
            baselineExerciseFrequency: nil,
            baselineMeditationFrequency: nil,
            baselineAvailableTime: String(result.availableTime),
            hasPhysicalLimitations: nil,
            primaryGoal: result.primaryGoal
        )

        // Track additional marketing data
        MixpanelManager.shared.trackOnboardingMarketingData(
            acquisitionChannel: "Unknown", // Acquisition now tracked in Overall quiz
            previousAppExperience: result.previousAppExperience
        )

        onComplete(result)
    }

    // MARK: - Get Question Data

    private func getQuestion(at index: Int) -> HabitsQuestion {
        let questions = getAllHabitsQuestions()
        return questions[index]
    }
}

// MARK: - Habits Question Model

struct HabitsQuestion {
    let text: String
    let options: [String]
    let scoring: [Int]
}

// MARK: - All Questions

func getAllHabitsQuestions() -> [HabitsQuestion] {
    return [
        // ============ PHASE 1: PRISE DE CONSCIENCE (Q1-Q8) ============
        // Questions situationnelles pour calculer les scores

        // Q1 - STRESS: Détente après le travail
        HabitsQuestion(
            text: "onboarding_v2.habits.q1".localized,
            options: [
                "onboarding_v2.habits.q1_opt1".localized,
                "onboarding_v2.habits.q1_opt2".localized,
                "onboarding_v2.habits.q1_opt3".localized,
                "onboarding_v2.habits.q1_opt4".localized
            ],
            scoring: [15, 40, 70, 100]
        ),

        // Q2 - ÉNERGIE: Impact sur la vie sociale
        HabitsQuestion(
            text: "onboarding_v2.habits.q2".localized,
            options: [
                "onboarding_v2.habits.q2_opt1".localized,
                "onboarding_v2.habits.q2_opt2".localized,
                "onboarding_v2.habits.q2_opt3".localized,
                "onboarding_v2.habits.q2_opt4".localized
            ],
            scoring: [15, 40, 70, 100]
        ),

        // Q3 - SOMMEIL: Réveils nocturnes
        HabitsQuestion(
            text: "onboarding_v2.habits.q3".localized,
            options: [
                "onboarding_v2.habits.q3_opt1".localized,
                "onboarding_v2.habits.q3_opt2".localized,
                "onboarding_v2.habits.q3_opt3".localized,
                "onboarding_v2.habits.q3_opt4".localized
            ],
            scoring: [15, 40, 70, 100]
        ),

        // Q4 - STRESS PHYSIQUE: Tensions corporelles
        HabitsQuestion(
            text: "onboarding_v2.habits.q4".localized,
            options: [
                "onboarding_v2.habits.q4_opt1".localized,
                "onboarding_v2.habits.q4_opt2".localized,
                "onboarding_v2.habits.q4_opt3".localized,
                "onboarding_v2.habits.q4_opt4".localized
            ],
            scoring: [15, 40, 70, 100]
        ),

        // Q5 - FOCUS: Capacité de concentration
        HabitsQuestion(
            text: "onboarding_v2.habits.q5".localized,
            options: [
                "onboarding_v2.habits.q5_opt1".localized,
                "onboarding_v2.habits.q5_opt2".localized,
                "onboarding_v2.habits.q5_opt3".localized,
                "onboarding_v2.habits.q5_opt4".localized
            ],
            scoring: [15, 40, 70, 100]
        ),

        // Q6 - CHARGE MENTALE: Se sentir submergé
        HabitsQuestion(
            text: "onboarding_v2.habits.q6".localized,
            options: [
                "onboarding_v2.habits.q6_opt1".localized,
                "onboarding_v2.habits.q6_opt2".localized,
                "onboarding_v2.habits.q6_opt3".localized,
                "onboarding_v2.habits.q6_opt4".localized
            ],
            scoring: [15, 40, 70, 100]
        ),

        // Q7 - DIGITAL/SOMMEIL: Déconnexion écrans
        HabitsQuestion(
            text: "onboarding_v2.habits.q7".localized,
            options: [
                "onboarding_v2.habits.q7_opt1".localized,
                "onboarding_v2.habits.q7_opt2".localized,
                "onboarding_v2.habits.q7_opt3".localized,
                "onboarding_v2.habits.q7_opt4".localized
            ],
            scoring: [15, 40, 70, 100]
        ),

        // Q8 - ÉNERGIE: Niveau fin de journée
        HabitsQuestion(
            text: "onboarding_v2.habits.q8".localized,
            options: [
                "onboarding_v2.habits.q8_opt1".localized,
                "onboarding_v2.habits.q8_opt2".localized,
                "onboarding_v2.habits.q8_opt3".localized,
                "onboarding_v2.habits.q8_opt4".localized
            ],
            scoring: [15, 40, 70, 100]
        ),

        // ============ PHASE 2: APPARENCE PHYSIQUE (Q9) ============
        // Question de profil/engagement (pas de scoring)

        // Q9 - APPARENCE: Impact physique du stress
        HabitsQuestion(
            text: "onboarding_v2.habits.q9".localized,
            options: [
                "onboarding_v2.habits.q9_opt1".localized,
                "onboarding_v2.habits.q9_opt2".localized,
                "onboarding_v2.habits.q9_opt3".localized,
                "onboarding_v2.habits.q9_opt4".localized
            ],
            scoring: [0, 0, 0, 0] // Pas de scoring, juste pour profil
        ),

        // ============ PHASE 3: MARKETING (Q10) ============
        // Question pour analytics (pas de scoring)
        // NOTE: Acquisition question (Q10) removed - already asked in Overall quiz

        // Q10 - EXPÉRIENCE: Apps similaires (ex-Q11)
        HabitsQuestion(
            text: "onboarding_v2.habits.q11".localized,
            options: [
                "onboarding_v2.habits.q11_opt1".localized,
                "onboarding_v2.habits.q11_opt2".localized,
                "onboarding_v2.habits.q11_opt3".localized,
                "onboarding_v2.habits.q11_opt4".localized
            ],
            scoring: [0, 0, 0, 0] // Pas de scoring, juste tracking
        ),

        // ============ PHASE 4: ENGAGEMENT (Q11-Q12) ============

        // Q11 - OBJECTIF: Ce qu'ils veulent améliorer (ex-Q12)
        HabitsQuestion(
            text: "onboarding_v2.habits.q12".localized,
            options: [
                "onboarding_v2.habits.q12_opt1".localized,
                "onboarding_v2.habits.q12_opt2".localized,
                "onboarding_v2.habits.q12_opt3".localized,
                "onboarding_v2.habits.q12_opt4".localized,
                "onboarding_v2.habits.q12_opt5".localized
            ],
            scoring: [0, 0, 0, 0, 0] // Utilisé pour primaryGoal
        ),

        // Q12 - TEMPS: Disponibilité quotidienne (ex-Q13)
        HabitsQuestion(
            text: "onboarding_v2.habits.q13".localized,
            options: [
                "onboarding_v2.habits.q13_opt1".localized,
                "onboarding_v2.habits.q13_opt2".localized,
                "onboarding_v2.habits.q13_opt3".localized,
                "onboarding_v2.habits.q13_opt4".localized,
                "onboarding_v2.habits.q13_opt5".localized
            ],
            scoring: [10, 30, 50, 75, 100]
        )
    ]
}

// MARK: - Habits Answer Button

struct HabitsAnswerButton: View {
    let number: Int
    let text: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Toggle avec numéro ou checkmark
                ZStack {
                    Circle()
                        .fill(isSelected ? Color(hex: "#67DB3D") : Color(hex: "B794F6"))
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.custom("Poppins-Bold", size: 12))
                            .foregroundColor(.black)
                    } else {
                        Text("\(number)")
                            .font(.custom("Poppins-Bold", size: 12))
                            .foregroundColor(.black)
                    }
                }

                // Texte aligné à gauche
                Text(text)
                    .font(.custom("Poppins-Medium", size: 18))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 16)
            .frame(height: 54)
            .background(
                RoundedRectangle(cornerRadius: 40)
                    .fill(Color(hex: "131146").opacity(0.8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 40)
                            .stroke(
                                Color(hex: "1B1864"),
                                lineWidth: 2
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 0.98 : 1.0)
        .opacity(isSelected ? 0.9 : 1.0)
    }
}

// MARK: - Habits Quiz Result

struct HabitsQuizResult {
    let answers: [Int]

    // MARK: - Domain Scores (Q1-Q8)

    /// Score de stress/sérénité (Q1 détente + Q4 tensions + Q6 submergé)
    var stressScore: Int {
        calculateDomainScore(questionIndices: [0, 3, 5])
    }

    /// Alias pour compatibilité
    var serenityScore: Int { stressScore }

    /// Score de sommeil (Q3 réveils nuit + Q7 écrans)
    var sleepScore: Int {
        calculateDomainScore(questionIndices: [2, 6])
    }

    /// Score d'énergie (Q2 annuler plans + Q8 niveau fin journée)
    var energyScore: Int {
        calculateDomainScore(questionIndices: [1, 7])
    }

    /// Score de focus/concentration (Q5)
    var focusScore: Int {
        calculateDomainScore(questionIndices: [4])
    }

    /// Score global (moyenne des 4 domaines)
    var globalScore: Int {
        (stressScore + sleepScore + energyScore + focusScore) / 4
    }

    /// Score d'équilibre (stress + focus)
    var balanceScore: Int {
        (stressScore + focusScore) / 2
    }

    /// Pour compatibilité - pas de baseline, retourne valeur fixe
    var habitsScore: Int { globalScore }

    // MARK: - Apparence physique (Q9)

    /// Réponse apparence physique (Q9) - pour profil uniquement
    var appearanceConcern: String {
        let concerns = ["Bien dans ma peau", "Quelques imperfections", "Fatigue visible", "Cernes et teint gris"]
        return concerns[safe: answers[8]] ?? "Bien dans ma peau"
    }

    // MARK: - Marketing Data (Q10)
    // NOTE: Acquisition channel (old Q10) removed - duplicate with Overall quiz

    /// Expérience avec apps similaires (Q10, ex-Q11)
    var previousAppExperience: String {
        let experiences = ["Première app", "A arrêté", "En utilise une autre", "Plusieurs essayées"]
        return experiences[safe: answers[9]] ?? "Première app"
    }

    // MARK: - Objectif et disponibilité (Q11-Q12)

    /// Objectif principal choisi par l'user (Q11, ex-Q12)
    var primaryGoal: String {
        let goals = ["sleep", "stress", "energy", "focus", "balance"]
        return goals[safe: answers[10]] ?? "balance"
    }

    /// Temps disponible par jour en minutes (Q12, ex-Q13)
    var availableTime: Int {
        let times = [10, 22, 37, 52, 75]
        return times[safe: answers[11]] ?? 22
    }

    // MARK: - Compatibilité baselineData (simplifié)

    /// BaselineData simplifié pour compatibilité avec PlanGenerationService
    var baselineData: BaselineHabits {
        BaselineHabits(
            wakeTime: "07:30",
            sleepDuration: 7.0,
            waterIntake: 1.5,
            exerciseFrequency: 2,
            exerciseDuration: 30,
            meditationFrequency: 0,
            meditationDuration: 5,
            breathingFrequency: 0,
            availableTime: availableTime,
            preferredIntensity: "moderate"
        )
    }

    // MARK: - Helper Methods

    private func calculateDomainScore(questionIndices: [Int]) -> Int {
        let questions = getAllHabitsQuestions()
        var total = 0

        for index in questionIndices {
            let answerIndex = answers[index]
            let scoring = questions[index].scoring
            total += scoring[safe: answerIndex] ?? 0
        }

        return total / max(questionIndices.count, 1)
    }
}

// MARK: - Baseline Habits Structure (Compatibilité)

struct BaselineHabits {
    let wakeTime: String
    let sleepDuration: Double
    let waterIntake: Double
    let exerciseFrequency: Int
    let exerciseDuration: Int
    let meditationFrequency: Int
    let meditationDuration: Int
    let breathingFrequency: Int
    let availableTime: Int
    let preferredIntensity: String
}

// Safe array access extension
extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

#Preview {
    HabitsQuizView { result in
        print("Quiz completed (12 questions):")
        print("- Stress/Sérénité: \(result.stressScore)")
        print("- Sommeil: \(result.sleepScore)")
        print("- Énergie: \(result.energyScore)")
        print("- Focus: \(result.focusScore)")
        print("- Global: \(result.globalScore)")
        print("- Apparence: \(result.appearanceConcern)")
        print("- Expérience apps: \(result.previousAppExperience)")
        print("- Objectif: \(result.primaryGoal)")
        print("- Temps disponible: \(result.availableTime) min")
    }
}
