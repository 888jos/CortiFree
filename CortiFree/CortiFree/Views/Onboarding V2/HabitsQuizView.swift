//
//  HabitsQuizView.swift
//  CortiFree
//
//  Created by Claude on 11/11/2025.
//  Quiz de 15 questions optimisées pour scorer les 4 domaines + habitudes clés
//

import SwiftUI

struct HabitsQuizView: View {
    let onComplete: (HabitsQuizResult) -> Void

    @State private var currentQuestionIndex: Int = 0
    @State private var selectedAnswer: Int? = nil
    @State private var energySliderValue: Double = 5.0
    @State private var answers: [Int] = Array(repeating: 0, count: 15)
    @State private var isGoingBack: Bool = false

    private let totalQuestions = 15

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
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack(spacing: 0) {
            // Back button (left)
            Button(action: {
                HapticManager.light()
                if currentQuestionIndex > 0 {
                    isGoingBack = true
                    withAnimation(.easeInOut(duration: 0.5)) {
                        currentQuestionIndex -= 1
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
                Text("Continuer")
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
        // Q1 - SÉRÉNITÉ
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

        // Q2 - SÉRÉNITÉ
        HabitsQuestion(
            text: "Arrives-tu à \"éteindre\" ton cerveau en fin de journée ?",
            options: [
                "Impossible, mon cerveau ne s'arrête jamais",
                "Non, je reste en mode \"actif\" même le soir",
                "Ça prend un peu de temps mais j'y arrive",
                "Oui, je décroche facilement"
            ],
            scoring: [10, 40, 70, 100]
        ),

        // Q6 - SOMMEIL
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

        // Q7 - SOMMEIL
        HabitsQuestion(
            text: "Combien de fois te réveilles-tu par nuit en moyenne ?",
            options: [
                "4 fois ou plus",
                "2-3 fois",
                "1 fois",
                "Jamais, je dors d'une traite"
            ],
            scoring: [10, 40, 70, 100]
        ),

        // Q9 - SOMMEIL
        HabitsQuestion(
            text: "Combien d'heures dors-tu par nuit ?",
            options: [
                "Moins de 5 heures",
                "5-6 heures",
                "6-7 heures",
                "7-8 heures",
                "Plus de 8 heures"
            ],
            scoring: [10, 40, 70, 100, 60]
        ),

        // Q11 - ÉNERGIE
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

        // Q14 - ÉNERGIE
        HabitsQuestion(
            text: "Comment est ta motivation au quotidien ?",
            options: [
                "Aucune motivation, tout est un effort",
                "Il faut que je me force pour tout",
                "Ça va, je fais ce que j'ai à faire",
                "Motivé, j'ai envie de faire les choses"
            ],
            scoring: [10, 35, 65, 100]
        ),

        // Q16 - FOCUS
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

        // Q21 - HABITUDES
        HabitsQuestion(
            text: "Combien de fois par semaine fais-tu des exercices de respiration consciente ?",
            options: [
                "Jamais",
                "1-2 fois par semaine",
                "3-4 fois par semaine",
                "5-6 fois par semaine",
                "Tous les jours"
            ],
            scoring: [0, 30, 55, 75, 100]
        ),

        // Q22 - HABITUDES
        HabitsQuestion(
            text: "Combien de fois par semaine médites-tu ou pratiques-tu la pleine conscience ?",
            options: [
                "Jamais",
                "1-2 fois par semaine",
                "3-4 fois par semaine",
                "5-6 fois par semaine",
                "Tous les jours"
            ],
            scoring: [0, 30, 55, 75, 100]
        ),

        // Q25 - HABITUDES
        HabitsQuestion(
            text: "Combien de fois par semaine écris-tu dans un journal (gratitude, pensées, etc.) ?",
            options: [
                "Jamais",
                "1-2 fois par semaine",
                "3-4 fois par semaine",
                "5-6 fois par semaine",
                "Tous les jours"
            ],
            scoring: [0, 30, 55, 75, 100]
        ),

        // Q24 - HABITUDES
        HabitsQuestion(
            text: "Combien de nuits par semaine te couches-tu et te lèves-tu à la même heure ?",
            options: [
                "Jamais les mêmes horaires",
                "2-3 nuits par semaine",
                "4-5 nuits par semaine",
                "6 nuits par semaine",
                "Tous les jours mêmes horaires"
            ],
            scoring: [10, 35, 60, 80, 100]
        ),

        // Q26 - HABITUDES
        HabitsQuestion(
            text: "Combien de fois par semaine fais-tu une activité physique (marche, yoga, sport) ?",
            options: [
                "Jamais",
                "1-2 fois par semaine",
                "3-4 fois par semaine",
                "5-6 fois par semaine",
                "Tous les jours"
            ],
            scoring: [0, 30, 55, 75, 100]
        ),

        // Q27 - HABITUDES
        HabitsQuestion(
            text: "Combien de fois par semaine passes-tu au moins 15 minutes dans la nature ou dehors ?",
            options: [
                "Jamais",
                "1-2 fois par semaine",
                "3-4 fois par semaine",
                "5-6 fois par semaine",
                "Tous les jours"
            ],
            scoring: [0, 30, 55, 75, 100]
        ),

        // Q23 - HABITUDES
        HabitsQuestion(
            text: "Combien de litres d'eau bois-tu par jour en moyenne ?",
            options: [
                "Moins de 1 litre",
                "1 à 1,5 litres",
                "1,5 à 2 litres",
                "2 à 2,5 litres",
                "Plus de 2,5 litres"
            ],
            scoring: [10, 40, 70, 90, 100]
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

    // Calculate scores (updated for 15-question quiz)
    var serenityScore: Int {
        calculateDomainScore(questionIndices: [0, 1]) // Q1, Q2
    }

    var sleepScore: Int {
        calculateDomainScore(questionIndices: [2, 3, 4]) // Q6, Q7, Q9
    }

    var energyScore: Int {
        calculateDomainScore(questionIndices: [5, 6]) // Q11 (slider), Q14
    }

    var focusScore: Int {
        calculateDomainScore(questionIndices: [7]) // Q16
    }

    var habitsScore: Int {
        calculateDomainScore(questionIndices: [8, 9, 10, 11, 12, 13, 14]) // Q21, Q22, Q25, Q24, Q26, Q27, Q23
    }

    var globalScore: Int {
        (serenityScore + sleepScore + energyScore + focusScore + habitsScore) / 5
    }

    var balanceScore: Int {
        (serenityScore + focusScore) / 2
    }

    private func calculateDomainScore(questionIndices: [Int]) -> Int {
        let questions = getAllHabitsQuestions()
        var total = 0

        for index in questionIndices {
            let answerIndex = answers[index]
            let scoring = questions[index].scoring
            total += scoring[answerIndex]
        }

        return total / questionIndices.count
    }
}

#Preview {
    HabitsQuizView { result in
        print("Quiz completed:")
        print("- Sérénité: \(result.serenityScore)")
        print("- Sommeil: \(result.sleepScore)")
        print("- Énergie: \(result.energyScore)")
        print("- Focus: \(result.focusScore)")
        print("- Habitudes: \(result.habitsScore)")
        print("- Global: \(result.globalScore)")
        print("- Équilibre: \(result.balanceScore)")
    }
}
