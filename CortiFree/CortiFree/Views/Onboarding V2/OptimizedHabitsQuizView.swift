//
//  OptimizedHabitsQuizView.swift
//  CortiFree
//
//  Version optimisée de HabitsQuizView pour de meilleures performances
//  Réduit à 15 questions essentielles + animations optimisées
//

import SwiftUI

struct OptimizedHabitsQuizView: View {
    let onComplete: (HabitsQuizResult) -> Void

    @State private var currentQuestionIndex: Int = 0
    @State private var selectedAnswer: Int? = nil
    @State private var answers: [Int] = Array(repeating: 0, count: 15)
    @State private var isGoingBack: Bool = false

    // Questions essentielles seulement (15 au lieu de 25)
    private let totalQuestions = 15

    private var progress: Double {
        Double(currentQuestionIndex) / Double(totalQuestions)
    }

    var body: some View {
        ZStack {
            // Simplified background for performance
            Color(hex: "0A0515")
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Simplified header
                headerSection
                    .padding(.top, 50)

                // Question content
                questionContent
                    .id(currentQuestionIndex)

                Spacer()
            }
        }
        // Reduced animation duration for snappier feel
        .animation(.easeInOut(duration: 0.2), value: currentQuestionIndex)
    }

    // MARK: - Simplified Header

    private var headerSection: some View {
        HStack {
            // Back button
            if currentQuestionIndex > 0 {
                Button(action: goBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                }
                .padding(.leading, 24)
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.2))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(hex: "B794F6"))
                        .frame(width: geometry.size.width * progress, height: 6)
                }
            }
            .frame(height: 6)
            .padding(.horizontal, 20)

            // Question number
            Text("\(currentQuestionIndex + 1)/\(totalQuestions)")
                .font(.custom("Poppins-Medium", size: 14))
                .foregroundColor(.white.opacity(0.7))
                .padding(.trailing, 24)
        }
        .frame(height: 44)
    }

    // MARK: - Question Content

    @ViewBuilder
    private var questionContent: some View {
        let question = getEssentialQuestion(at: currentQuestionIndex)

        VStack(alignment: .leading, spacing: 20) {
            // Question text
            Text(question.text)
                .font(.custom("Poppins-Medium", size: 18))
                .foregroundColor(.white)
                .lineSpacing(4)
                .padding(.horizontal, 24)
                .padding(.top, 30)

            // Answer options
            VStack(spacing: 12) {
                ForEach(0..<question.options.count, id: \.self) { index in
                    SimpleAnswerButton(
                        text: question.options[index],
                        isSelected: selectedAnswer == index,
                        onTap: {
                            selectAnswer(index)
                        }
                    )
                }
            }
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Actions

    private func goBack() {
        HapticManager.light()
        if currentQuestionIndex > 0 {
            isGoingBack = true
            currentQuestionIndex -= 1
            selectedAnswer = nil
        }
    }

    private func selectAnswer(_ index: Int) {
        HapticManager.light()
        selectedAnswer = index
        answers[currentQuestionIndex] = index

        // Auto-advance after short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            advanceToNext()
        }
    }

    private func advanceToNext() {
        if currentQuestionIndex < totalQuestions - 1 {
            isGoingBack = false
            currentQuestionIndex += 1
            selectedAnswer = nil
        } else {
            completeQuiz()
        }
    }

    private func completeQuiz() {
        // Create simplified result
        let result = createSimplifiedResult(answers: answers)
        onComplete(result)
    }

    // MARK: - Essential Questions Only

    private func getEssentialQuestion(at index: Int) -> HabitsQuestion {
        let essentialQuestions = [
            // BASELINE (5 questions)
            HabitsQuestion(
                text: "À quelle heure te réveilles-tu habituellement ?",
                options: ["Avant 7h", "7h-8h", "8h-9h", "Après 9h"],
                scoring: [100, 75, 50, 25]
            ),
            HabitsQuestion(
                text: "Combien d'heures dors-tu par nuit ?",
                options: ["<6h", "6-7h", "7-8h", ">8h"],
                scoring: [25, 50, 90, 100]
            ),
            HabitsQuestion(
                text: "Quelle quantité d'eau bois-tu par jour ?",
                options: ["<1L", "1-1.5L", "1.5-2L", ">2L"],
                scoring: [25, 50, 75, 100]
            ),
            HabitsQuestion(
                text: "Combien de fois fais-tu du sport par semaine ?",
                options: ["Jamais", "1-2x", "3-4x", "5x+"],
                scoring: [0, 40, 70, 100]
            ),
            HabitsQuestion(
                text: "Pratiques-tu déjà la méditation ?",
                options: ["Jamais", "Parfois", "Souvent", "Tous les jours"],
                scoring: [0, 35, 70, 100]
            ),

            // ÉTAT ACTUEL (10 questions)
            HabitsQuestion(
                text: "As-tu des pensées qui tournent en boucle ?",
                options: ["Toujours", "Souvent", "Parfois", "Rarement"],
                scoring: [10, 35, 65, 100]
            ),
            HabitsQuestion(
                text: "Arrives-tu à déconnecter le soir ?",
                options: ["Impossible", "Difficile", "Ça va", "Facilement"],
                scoring: [10, 35, 65, 100]
            ),
            HabitsQuestion(
                text: "Combien de temps pour t'endormir ?",
                options: [">1h", "30-60min", "15-30min", "<15min"],
                scoring: [10, 40, 70, 100]
            ),
            HabitsQuestion(
                text: "Te réveilles-tu la nuit ?",
                options: ["Très souvent", "Souvent", "Parfois", "Jamais"],
                scoring: [10, 35, 65, 100]
            ),
            HabitsQuestion(
                text: "Quel est ton niveau d'énergie ?",
                options: ["Épuisé", "Fatigué", "Moyen", "Énergique"],
                scoring: [10, 35, 60, 100]
            ),
            HabitsQuestion(
                text: "Comment est ta motivation ?",
                options: ["Nulle", "Faible", "Normale", "Bonne"],
                scoring: [10, 35, 65, 100]
            ),
            HabitsQuestion(
                text: "Peux-tu rester concentré ?",
                options: ["<15min", "15-30min", "30-60min", ">1h"],
                scoring: [10, 40, 70, 100]
            ),
            HabitsQuestion(
                text: "Combien de temps disponible par jour ?",
                options: ["<15min", "15-30min", "30-45min", ">45min"],
                scoring: [30, 50, 70, 90]
            ),
            HabitsQuestion(
                text: "Comment préfères-tu commencer ?",
                options: ["Très doucement", "Progressif", "Modéré", "Intense"],
                scoring: [25, 50, 75, 100]
            ),
            HabitsQuestion(
                text: "Quel est ton objectif principal ?",
                options: ["Moins de stress", "Mieux dormir", "Plus d'énergie", "Équilibre global"],
                scoring: [80, 80, 80, 100]
            )
        ]

        return essentialQuestions[safe: index] ?? essentialQuestions[0]
    }

    // MARK: - Create Simplified Result

    private func createSimplifiedResult(answers: [Int]) -> HabitsQuizResult {
        // Create a padded answer array for compatibility
        var fullAnswers = Array(repeating: 0, count: 25)

        // Map essential answers to full structure
        // Baseline questions (0-4) -> (0-4)
        for i in 0..<min(5, answers.count) {
            fullAnswers[i] = answers[i]
        }

        // State questions (5-14) -> (10-19)
        for i in 5..<min(15, answers.count) {
            fullAnswers[i + 5] = answers[i]
        }

        // Fill remaining with defaults
        fullAnswers[5] = 2  // Meditation frequency
        fullAnswers[6] = 1  // Meditation duration
        fullAnswers[7] = 1  // Breathing frequency
        fullAnswers[8] = answers[12] // Available time
        fullAnswers[9] = answers[13] // Intensity
        fullAnswers[22] = 2 // No limitations
        fullAnswers[23] = 1 // Morning
        fullAnswers[24] = answers[14] // Goal

        return HabitsQuizResult(answers: fullAnswers)
    }
}

// MARK: - Simple Answer Button

struct SimpleAnswerButton: View {
    let text: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                Circle()
                    .fill(isSelected ? Color(hex: "67DB3D") : Color.white.opacity(0.2))
                    .frame(width: 20, height: 20)
                    .overlay(
                        isSelected ?
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.black)
                        : nil
                    )

                Text(text)
                    .font(.custom("Poppins-Regular", size: 16))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 16)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(isSelected ? 0.15 : 0.08))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Extension already defined in HabitsQuizView.swift