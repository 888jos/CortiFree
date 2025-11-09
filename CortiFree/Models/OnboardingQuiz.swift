//
//  OnboardingQuiz.swift
//  CortiFree
//
//  Created by Claude on 31/10/2025.
//  Models for onboarding quiz (Flow 2)
//

import Foundation

// MARK: - Quiz Question

struct QuizQuestion: Identifiable {
    let id: Int
    let questionNumber: Int
    let questionText: String
    let explanationText: String
    let answers: [String]

    init(id: Int, questionText: String, explanationText: String, answers: [String]) {
        self.id = id
        self.questionNumber = id
        self.questionText = questionText
        self.explanationText = explanationText
        self.answers = answers
    }
}

// MARK: - Info Screen

struct InfoScreen: Identifiable {
    let id: String
    let title: String
    let bodyText: String
    let dataInsight: String
    let lottieAnimation: String? // Optional Lottie file name
    let insertAfterQuestion: Int // Question number to insert after
}

// MARK: - Quiz State

class QuizState: ObservableObject {
    @Published var currentQuestionIndex: Int = 0
    @Published var answers: [Int: Int] = [:] // questionId: answerIndex
    @Published var showInfoScreen: Bool = false
    @Published var currentInfoScreen: InfoScreen?
    @Published var isCompleted: Bool = false
    @Published var userGender: String = "" // "homme", "femme", ou "non-spécifié"
    @Published var userAge: String = "" // "18-24", "25-34", etc.
    @Published var userFirstName: String = "" // User's first name

    let questions: [QuizQuestion] = QuizData.allQuestions
    let infoScreens: [InfoScreen] = QuizData.allInfoScreens

    // Helper pour avoir le bon accord grammatical
    var genderSuffix: String {
        return userGender == "femme" ? "e" : ""
    }

    var progress: Double {
        Double(currentQuestionIndex + 1) / Double(questions.count)
    }

    var currentQuestion: QuizQuestion? {
        guard currentQuestionIndex < questions.count else { return nil }
        return questions[currentQuestionIndex]
    }

    func selectAnswer(_ answerIndex: Int) {
        guard let question = currentQuestion else { return }
        answers[question.id] = answerIndex

        // Store gender (Question 1)
        if question.id == 1 {
            let genders = ["homme", "femme", "non-spécifié"]
            userGender = genders[answerIndex]
        }

        // Store age (Question 2)
        if question.id == 2 {
            let ages = ["18-24", "25-34", "35-44", "45-54", "55+"]
            userAge = ages[answerIndex]
        }

        // First name is captured in OnboardingQuizView for Question 23

        // Check if there's an info screen after this question
        if let infoScreen = infoScreens.first(where: { $0.insertAfterQuestion == question.id }) {
            currentInfoScreen = infoScreen
            showInfoScreen = true
        } else {
            moveToNextQuestion()
        }
    }

    // Helper function to add feminine ending if user is female
    func genderAdjective(_ baseWord: String) -> String {
        if userGender == "femme" {
            return baseWord + "e"
        }
        return baseWord
    }

    func moveToNextQuestion() {
        showInfoScreen = false
        currentInfoScreen = nil

        if currentQuestionIndex < questions.count - 1 {
            currentQuestionIndex += 1
        } else {
            // Quiz completed
            completeQuiz()
        }
    }

    func moveToPreviousQuestion() {
        if currentQuestionIndex > 0 {
            currentQuestionIndex -= 1
        }
    }

    func completeQuiz() {
        // Calculate score and save results
        UserDefaults.standard.set(true, forKey: "onboardingQuizCompleted")
        isCompleted = true
    }
}

// MARK: - Quiz Data

struct QuizData {
    static let allQuestions: [QuizQuestion] = [
        // Question 1 - Gender
        QuizQuestion(
            id: 1,
            questionText: "Quel est ton genre ?",
            explanationText: "",
            answers: ["Homme", "Femme", "Je préfère ne pas dire"]
        ),

        // Question 2 - Age
        QuizQuestion(
            id: 2,
            questionText: "Quelle est ta tranche d'âge ?",
            explanationText: "",
            answers: ["18-24 ans", "25-34 ans", "35-44 ans", "45-54 ans", "55 ans et plus"]
        ),

        // Question 3
        QuizQuestion(
            id: 3,
            questionText: "Le matin, te sens-tu reposé·e en te réveillant ?",
            explanationText: "Un sommeil non réparateur indique un pic de cortisol au mauvais moment.",
            answers: ["Toujours", "La plupart du temps", "Rarement", "Jamais"]
        ),

        // Question 4
        QuizQuestion(
            id: 4,
            questionText: "Te réveilles-tu souvent la nuit sans raison apparente ?",
            explanationText: "Ces réveils nocturnes sont liés à des déséquilibres du cortisol pendant le cycle de sommeil.",
            answers: ["Jamais", "Une fois par semaine", "Plusieurs fois par semaine", "Quasi chaque nuit"]
        ),

        // Question 5
        QuizQuestion(
            id: 5,
            questionText: "Te réveilles-tu souvent avec la nuque ou les épaules tendues ?",
            explanationText: "Des tensions physiques au réveil indiquent une sécrétion de cortisol encore élevée pendant la nuit.",
            answers: ["Jamais", "Rarement", "Parfois", "Souvent"]
        ),

        // Question 6
        QuizQuestion(
            id: 6,
            questionText: "Te sens-tu souvent épuisé·e dès le matin, malgré une nuit complète ?",
            explanationText: "Un épuisement au réveil reflète un dérèglement du cycle du cortisol, censé remonter à l'aube.",
            answers: ["Jamais", "Rarement", "Parfois", "Presque chaque matin"]
        ),

        // Question 7
        QuizQuestion(
            id: 7,
            questionText: "As-tu tendance à être vite agacé·e par les bruits, les imprévus ou les gens trop lents ?",
            explanationText: "Une hypersensibilité sensorielle et sociale traduit souvent un système nerveux saturé par un excès de cortisol.",
            answers: ["Jamais", "Rarement", "Parfois", "Très souvent"]
        ),

        // Question 8
        QuizQuestion(
            id: 8,
            questionText: "T'arrive-t-il de sauter un repas sans vraie raison (pas faim, pas le temps) ?",
            explanationText: "Sauter des repas perturbe la glycémie et accentue les pics de cortisol, l'hormone du stress.",
            answers: ["Jamais", "1 à 2 fois par semaine", "3 à 4 fois par semaine", "Presque tous les jours"]
        ),

        // Question 9
        QuizQuestion(
            id: 9,
            questionText: "Bois-tu du café ou du thé même quand tu te sens déjà tendu·e ?",
            explanationText: "La caféine stimule la sécrétion de cortisol et entretient un état de vigilance artificielle.",
            answers: ["Jamais", "Parfois", "Souvent", "Tous les jours"]
        ),

        // Question 10
        QuizQuestion(
            id: 10,
            questionText: "Combien d'heures passes-tu sur ton téléphone (hors travail) chaque jour ?",
            explanationText: "Un temps d'écran excessif maintient le cerveau en alerte constante et empêche la baisse naturelle du cortisol.",
            answers: ["Moins d'1 heure", "1 à 3 heures", "3 à 5 heures", "Plus de 5 heures"]
        ),

        // Question 11
        QuizQuestion(
            id: 11,
            questionText: "Restes-tu souvent sur ton téléphone tard le soir, juste avant de dormir ?",
            explanationText: "L'exposition prolongée aux écrans avant le coucher bloque la mélatonine et maintient un niveau élevé de cortisol.",
            answers: ["Jamais", "Parfois", "Souvent", "Presque chaque nuit"]
        ),

        // Question 12
        QuizQuestion(
            id: 12,
            questionText: "Combien d'heures passes-tu assis·e chaque jour (hors sommeil) ?",
            explanationText: "Un mode de vie sédentaire limite la régulation naturelle du cortisol par le mouvement et la respiration.",
            answers: ["Moins de 4 heures", "4 à 6 heures", "6 à 8 heures", "Plus de 8 heures"]
        ),

        // Question 13
        QuizQuestion(
            id: 13,
            questionText: "Ressens-tu souvent des tensions dans la nuque, la mâchoire ou les épaules au cours de la journée ?",
            explanationText: "Ces zones concentrent les effets physiques du stress chronique et d'une production excessive de cortisol.",
            answers: ["Jamais", "Parfois", "Souvent", "En permanence"]
        ),

        // Question 14
        QuizQuestion(
            id: 14,
            questionText: "As-tu tendance à être très affecté·e par les remarques ou critiques, même légères ?",
            explanationText: "Une hypersensibilité émotionnelle indique un système nerveux en vigilance constante, souvent alimenté par un taux de cortisol élevé.",
            answers: ["Jamais", "Rarement", "Parfois", "Très souvent"]
        ),

        // Question 15
        QuizQuestion(
            id: 15,
            questionText: "T'arrive-t-il de t'emporter ou de te mettre en colère pour des broutilles ?",
            explanationText: "Les réactions excessives signalent souvent un déséquilibre du cortisol et une difficulté à réguler les émotions.",
            answers: ["Jamais", "Rarement", "Parfois", "Très souvent"]
        ),

        // Question 16
        QuizQuestion(
            id: 16,
            questionText: "Peux-tu facilement décrocher mentalement du travail ou de tes responsabilités pendant les repas ou le week-end ?",
            explanationText: "La difficulté à déconnecter est un signe de stress chronique : ton système de vigilance ne redescend plus, maintenant le cortisol élevé.",
            answers: ["Oui, toujours", "Souvent", "Rarement", "Jamais"]
        ),

        // Question 17
        QuizQuestion(
            id: 17,
            questionText: "As-tu parfois l'impression que ton cerveau ne s'arrête jamais de penser, même sans raison précise ?",
            explanationText: "Une activité mentale continue est typique d'un cortisol trop élevé, maintenant le cerveau en mode 'alerte'.",
            answers: ["Jamais", "Parfois", "Souvent", "En permanence"]
        ),

        // Question 18
        QuizQuestion(
            id: 18,
            questionText: "Remets-tu souvent les choses à plus tard, non par flemme mais par fatigue mentale ?",
            explanationText: "Une fatigue cognitive persistante indique un excès de cortisol qui épuise les capacités d'attention et de décision.",
            answers: ["Jamais", "Parfois", "Souvent", "Presque toujours"]
        ),

        // Question 19
        QuizQuestion(
            id: 19,
            questionText: "As-tu du mal à déléguer ou à laisser les choses se faire sans tout contrôler ?",
            explanationText: "Le besoin de contrôle permanent traduit un état d'hypervigilance causé par un taux de cortisol trop élevé.",
            answers: ["Pas du tout", "Un peu", "Beaucoup", "Tout le temps"]
        ),

        // Question 20
        QuizQuestion(
            id: 20,
            questionText: "Te surprends-tu souvent à imaginer le pire scénario avant même que les choses ne se produisent ?",
            explanationText: "La peur anticipée active en continu la production de cortisol et empêche le corps de revenir à un état de calme.",
            answers: ["Jamais", "Parfois", "Souvent", "Presque toujours"]
        ),

        // Question 21
        QuizQuestion(
            id: 21,
            questionText: "As-tu tendance à vérifier ton téléphone dès que tu as deux secondes de silence ou d'attente ?",
            explanationText: "Ce réflexe de vérification permanente entretient des micro-décharges de cortisol liées à l'anticipation et à la récompense.",
            answers: ["Jamais", "Parfois", "Souvent", "Tout le temps"]
        ),

        // Question 22
        QuizQuestion(
            id: 22,
            questionText: "As-tu du mal à ne rien faire sans te sentir coupable ou inutile ?",
            explanationText: "L'incapacité à se poser ou à ralentir reflète un cortisol constamment élevé, empêchant la détente et la récupération.",
            answers: ["Jamais", "Parfois", "Souvent", "Toujours"]
        ),

        // Question 23 - First Name (text input) - LAST QUESTION
        QuizQuestion(
            id: 23,
            questionText: "Apprenons-nous à nous connaître",
            explanationText: "",
            answers: [] // Empty for text input
        )
    ]

    static let allInfoScreens: [InfoScreen] = [
        // Info screens removed - going straight through quiz questions
    ]
}
