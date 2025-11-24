//
//  HabitsQuizView.swift
//  CortiFree
//
//  Created by Claude on 11/11/2025.
//  Enhanced Quiz: 25 questions including baseline assessment
//  Q1-10: Baseline habits to prevent regression
//  Q11-25: Domain assessment for personalized scoring
//

import SwiftUI

struct HabitsQuizView: View {
    let onComplete: (HabitsQuizResult) -> Void

    @State private var currentQuestionIndex: Int = 0
    @State private var selectedAnswer: Int? = nil
    @State private var energySliderValue: Double = 5.0
    @State private var waterSliderValue: Double = 1.5
    @State private var wakeTimeHour: Int = 7
    @State private var wakeTimeMinute: Int = 0
    @State private var answers: [Int] = Array(repeating: 0, count: 12) // Optimized to 12 questions
    @State private var isGoingBack: Bool = false
    @State private var questionStartTime: Date? // Track time spent on each question
    @State private var quizStartTime: Date? // Track total quiz time

    private let totalQuestions = 12 // Optimized from 25 to 12

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

            VStack(spacing: 0) {
                // Navigation header
                headerSection
                    .padding(.top, 50)

                // Question content with fixed title
                VStack(spacing: 0) {
                    // Fixed Question Number Title
                    Text("Question #\(currentQuestionNumber)")
                        .font(.custom("Poppins-Bold", size: 24))
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

                Spacer()
            }
        }
        .animation(.easeInOut(duration: 0.5), value: currentQuestionIndex)
        .onAppear {
            // Track quiz started
            quizStartTime = Date()
            questionStartTime = Date()
            // Quiz start is tracked by first question view
        }
        .onChange(of: currentQuestionIndex) { _ in
            // Reset timer when question changes
            questionStartTime = Date()
        }
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

            // Language flag (right)
            Text("🇫🇷 FRA")
                .font(.custom("Poppins-Medium", size: 10))
                .foregroundColor(.white)
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
                .font(.custom("Poppins-Medium", size: 18))
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

    // MARK: - Energy Slider Question (Q11)

    private var energySliderQuestion: some View {
        VStack(spacing: 24) {
            // Slider
            VStack(spacing: 12) {
                Slider(value: $energySliderValue, in: 0...10, step: 1)
                    .accentColor(Color(hex: "B794F6"))
                    .padding(.horizontal, 34)

                // Value display
                Text("\(Int(energySliderValue))")
                    .font(.custom("Poppins-Bold", size: 48))
                    .foregroundColor(Color(hex: "B794F6"))

                // Labels
                HStack {
                    Text("😴 Épuisé")
                        .font(.custom("Poppins-Regular", size: 14))
                        .foregroundColor(.white.opacity(0.7))

                    Spacer()

                    Text("🤩 Plein d'énergie")
                        .font(.custom("Poppins-Regular", size: 14))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.horizontal, 34)
            }

            // Continue button
            Button(action: {
                HapticManager.light()
                answers[currentQuestionIndex] = Int(energySliderValue)
                advanceToNextQuestion()
            }) {
                Text(StringKeys.Common.continueButton)
                    .font(.custom("Poppins-SemiBold", size: 16))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 40))
            }
            .padding(.horizontal, 34)
            .padding(.bottom, 40)
        }
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

        // Track quiz completion with all scores
        MixpanelManager.shared.trackOnboardingHabitsQuizCompleted(
            totalTime: totalTime,
            serenityScore: result.serenityScore,
            sleepScore: result.sleepScore,
            energyScore: result.energyScore,
            focusScore: result.focusScore,
            habitsScore: result.habitsScore,
            balanceScore: result.balanceScore,
            globalScore: result.globalScore,
            baselineWakeTime: result.baselineData.wakeTime,
            baselineSleepDuration: result.baselineData.sleepDuration,
            baselineWaterIntake: result.baselineData.waterIntake,
            baselineExerciseFrequency: result.baselineData.exerciseFrequency,
            baselineMeditationFrequency: result.baselineData.meditationFrequency,
            baselineAvailableTime: String(result.baselineData.availableTime),
            hasPhysicalLimitations: nil,
            primaryGoal: result.primaryGoal
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
        // ============ PHASE 1: SYMPTÔMES (Q1-Q4) ============
        // Identifier l'état mental et physique actuel

        // Q1 - SÉRÉNITÉ: Pensées en boucle
        HabitsQuestion(
            text: "As-tu des pensées qui tournent en boucle dans ta tête ?",
            options: [
                "Tout le temps, sans arrêt",
                "Presque tous les jours",
                "Quelques fois par semaine",
                "Non, mon esprit est calme"
            ],
            scoring: [10, 40, 70, 100]
        ),

        // Q2 - ÉNERGIE: Niveau d'énergie quotidien
        HabitsQuestion(
            text: "Quel est ton niveau d'énergie au quotidien ?",
            options: [
                "Épuisé, je n'ai aucune énergie",
                "Fatigué, je manque d'énergie",
                "Moyen, ça va",
                "Bon, j'ai de l'énergie",
                "Excellent, plein d'énergie"
            ],
            scoring: [10, 35, 60, 80, 100]
        ),

        // Q3 - FOCUS: Capacité de concentration
        HabitsQuestion(
            text: "Combien de temps peux-tu rester concentré sur une tâche ?",
            options: [
                "Moins de 15 minutes, mon esprit papillonne",
                "15-30 minutes puis je me déconcentre",
                "30-60 minutes avant de décrocher",
                "Plus d'une heure sans problème"
            ],
            scoring: [10, 40, 70, 100]
        ),

        // Q4 - SOMMEIL: Temps d'endormissement
        HabitsQuestion(
            text: "Combien de temps te faut-il pour t'endormir le soir ?",
            options: [
                "Plus d'une heure",
                "30-60 minutes",
                "15-30 minutes",
                "Moins de 15 minutes"
            ],
            scoring: [10, 40, 75, 100]
        ),

        // ============ PHASE 2: CONTEXTE (Q5-Q6) ============
        // Comprendre l'environnement et les contraintes

        // Q5 - SOCIAL: Interactions sociales
        HabitsQuestion(
            text: "Combien de fois par semaine as-tu des interactions sociales significatives ?",
            options: [
                "Jamais ou presque",
                "1-2 fois par semaine",
                "3-4 fois par semaine",
                "5-6 fois par semaine",
                "Tous les jours"
            ],
            scoring: [10, 35, 60, 80, 100]
        ),

        // Q6 - CONTRAINTES: Limitations physiques
        HabitsQuestion(
            text: "As-tu des limitations physiques qui pourraient affecter certaines habitudes ?",
            options: [
                "Oui, plusieurs limitations importantes",
                "Quelques limitations mineures",
                "Non, aucune limitation"
            ],
            scoring: [30, 65, 100]
        ),

        // ============ PHASE 3: BASELINE HABITS (Q7-Q12) ============
        // Mesurer les habitudes actuelles pour éviter la régression

        // Q7 - BASELINE SOMMEIL: Heure de réveil
        HabitsQuestion(
            text: "À quelle heure te réveilles-tu habituellement ?",
            options: [
                "Avant 6h00",
                "Entre 6h00 et 7h00",
                "Entre 7h00 et 8h00",
                "Entre 8h00 et 9h00",
                "Après 9h00"
            ],
            scoring: [100, 90, 70, 50, 30]
        ),

        // Q8 - BASELINE SOMMEIL: Durée de sommeil
        HabitsQuestion(
            text: "Combien d'heures dors-tu actuellement par nuit ?",
            options: [
                "Moins de 5 heures",
                "5-6 heures",
                "6-7 heures",
                "7-8 heures",
                "Plus de 8 heures"
            ],
            scoring: [20, 40, 60, 90, 100]
        ),

        // Q9 - BASELINE HYDRATATION: Consommation d'eau
        HabitsQuestion(
            text: "Quelle quantité d'eau bois-tu par jour actuellement ?",
            options: [
                "Moins de 0.5L",
                "0.5L à 1L",
                "1L à 1.5L",
                "1.5L à 2L",
                "2L à 2.5L",
                "Plus de 2.5L"
            ],
            scoring: [10, 25, 45, 65, 85, 100]
        ),

        // Q10 - BASELINE SPORT: Fréquence d'exercice
        HabitsQuestion(
            text: "Combien de fois fais-tu du sport/exercice par semaine actuellement ?",
            options: [
                "Jamais",
                "1 fois par semaine",
                "2-3 fois par semaine",
                "4-5 fois par semaine",
                "6-7 fois par semaine"
            ],
            scoring: [0, 25, 50, 75, 100]
        ),

        // Q11 - BASELINE MINDFULNESS: Pratique méditation
        HabitsQuestion(
            text: "Pratiques-tu déjà la méditation ou la pleine conscience ?",
            options: [
                "Jamais essayé",
                "J'ai essayé mais j'ai arrêté",
                "Occasionnellement (1-2x/mois)",
                "Régulièrement (1-2x/semaine)",
                "Souvent (3-5x/semaine)",
                "Tous les jours"
            ],
            scoring: [0, 15, 30, 50, 75, 100]
        ),

        // Q12 - FAISABILITÉ: Temps disponible (CRUCIAL - dernière question)
        HabitsQuestion(
            text: "Combien de temps peux-tu consacrer aux nouvelles habitudes par jour ?",
            options: [
                "Moins de 15 minutes",
                "15-30 minutes",
                "30-45 minutes",
                "45-60 minutes",
                "Plus d'1 heure"
            ],
            scoring: [30, 50, 70, 85, 100]
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

    // MARK: - Baseline Data (Q7-Q12)
    var baselineData: BaselineHabits {
        BaselineHabits(
            wakeTime: getWakeTimeFromAnswer(answers[6]),           // Q7
            sleepDuration: getSleepDurationFromAnswer(answers[7]), // Q8
            waterIntake: getWaterIntakeFromAnswer(answers[8]),     // Q9
            exerciseFrequency: getExerciseFrequencyFromAnswer(answers[9]), // Q10
            exerciseDuration: 30,  // DEFAULT: question removed, reasonable default
            meditationFrequency: getMeditationFrequencyFromAnswer(answers[10]), // Q11
            meditationDuration: 5, // DEFAULT: question removed, reasonable default
            breathingFrequency: 0, // DEFAULT: question removed, assume not practiced
            availableTime: getAvailableTimeFromAnswer(answers[11]), // Q12
            preferredIntensity: "moderate" // DEFAULT: question removed, moderate pace
        )
    }

    // MARK: - Domain Scores (Q1-Q12 optimized)
    var serenityScore: Int {
        calculateDomainScore(questionIndices: [0]) // Q1: Pensées en boucle
    }

    var sleepScore: Int {
        // Q4 (temps endormissement) + Q7 (heure réveil) + Q8 (durée sommeil)
        calculateDomainScore(questionIndices: [3, 6, 7])
    }

    var energyScore: Int {
        calculateDomainScore(questionIndices: [1]) // Q2: Niveau d'énergie
    }

    var focusScore: Int {
        calculateDomainScore(questionIndices: [2]) // Q3: Concentration
    }

    var habitsScore: Int {
        // Q5 (social) + Q9 (eau) + Q10 (sport) + Q11 (méditation)
        calculateDomainScore(questionIndices: [4, 8, 9, 10])
    }

    var globalScore: Int {
        (serenityScore + sleepScore + energyScore + focusScore + habitsScore) / 5
    }

    var balanceScore: Int {
        (serenityScore + focusScore) / 2
    }

    // MARK: - Additional Insights
    var hasPhysicalLimitations: Bool {
        answers[5] < 2 // Q6 - physical limitations (0 or 1 = has limitations)
    }

    var preferredTimeOfDay: String {
        // Default to morning since question was removed
        "morning"
    }

    var primaryGoal: String {
        // Determine from symptoms: highest priority from low scores
        if serenityScore < sleepScore && serenityScore < energyScore {
            return "stress"
        } else if sleepScore < energyScore {
            return "sleep"
        } else if energyScore < focusScore {
            return "energy"
        } else if focusScore < 50 {
            return "focus"
        }
        return "balance"
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

        return total / questionIndices.count
    }

    // Baseline extraction methods
    private func getWakeTimeFromAnswer(_ answer: Int) -> String {
        ["05:30", "06:30", "07:30", "08:30", "09:30"][answer]
    }

    private func getSleepDurationFromAnswer(_ answer: Int) -> Double {
        [4.5, 5.5, 6.5, 7.5, 8.5][answer]
    }

    private func getWaterIntakeFromAnswer(_ answer: Int) -> Double {
        [0.5, 0.75, 1.25, 1.75, 2.25, 2.75][answer]
    }

    private func getExerciseFrequencyFromAnswer(_ answer: Int) -> Int {
        [0, 1, 3, 5, 7][answer]
    }

    private func getMeditationFrequencyFromAnswer(_ answer: Int) -> Int {
        [0, 0, 1, 2, 4, 7][answer]
    }

    private func getAvailableTimeFromAnswer(_ answer: Int) -> Int {
        [10, 22, 37, 52, 75][answer]
    }
}

// MARK: - Baseline Habits Structure
struct BaselineHabits {
    let wakeTime: String
    let sleepDuration: Double
    let waterIntake: Double
    let exerciseFrequency: Int // per week
    let exerciseDuration: Int // minutes
    let meditationFrequency: Int // per week
    let meditationDuration: Int // minutes
    let breathingFrequency: Int // per week
    let availableTime: Int // minutes per day
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
        print("- Sérénité: \(result.serenityScore)")
        print("- Sommeil: \(result.sleepScore)")
        print("- Énergie: \(result.energyScore)")
        print("- Focus: \(result.focusScore)")
        print("- Habitudes: \(result.habitsScore)")
        print("- Global: \(result.globalScore)")
        print("- Équilibre: \(result.balanceScore)")
        print("- Baseline: \(result.baselineData)")
    }
}
