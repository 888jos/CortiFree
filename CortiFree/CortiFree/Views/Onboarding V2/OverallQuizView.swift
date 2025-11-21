//
//  OverallQuizView.swift
//  CortiFree
//
//  Created by Claude on 11/11/2025.
//  Quiz Overall - 4 questions de profil utilisateur
//

import SwiftUI

struct OverallQuizView: View {
    let onComplete: (OverallQuizData) -> Void

    @State private var currentQuestionIndex: Int = 0
    @State private var firstName: String = ""
    @State private var selectedGender: Int? = nil
    @State private var selectedAge: Int? = nil
    @State private var selectedReasons: Set<Int> = []
    @State private var selectedDuration: Int? = nil
    @State private var isGoingBack: Bool = false
    @State private var quizStartTime: Date?
    @FocusState private var isTextFieldFocused: Bool

    private let totalQuestions = 5

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
                    if currentQuestionIndex == 0 {
                        firstNameQuestion
                            .id(0)
                            .transition(.asymmetric(
                                insertion: .move(edge: isGoingBack ? .leading : .trailing),
                                removal: .move(edge: isGoingBack ? .trailing : .leading)
                            ))
                    } else if currentQuestionIndex == 1 {
                        genderQuestion
                            .id(1)
                            .transition(.asymmetric(
                                insertion: .move(edge: isGoingBack ? .leading : .trailing),
                                removal: .move(edge: isGoingBack ? .trailing : .leading)
                            ))
                    } else if currentQuestionIndex == 2 {
                        ageQuestion
                            .id(2)
                            .transition(.asymmetric(
                                insertion: .move(edge: isGoingBack ? .leading : .trailing),
                                removal: .move(edge: isGoingBack ? .trailing : .leading)
                            ))
                    } else if currentQuestionIndex == 3 {
                        reasonQuestion
                            .id(3)
                            .transition(.asymmetric(
                                insertion: .move(edge: isGoingBack ? .leading : .trailing),
                                removal: .move(edge: isGoingBack ? .trailing : .leading)
                            ))
                    } else if currentQuestionIndex == 4 {
                        durationQuestion
                            .id(4)
                            .transition(.asymmetric(
                                insertion: .move(edge: isGoingBack ? .leading : .trailing),
                                removal: .move(edge: isGoingBack ? .trailing : .leading)
                            ))
                    }
                }

                Spacer()
            }
        }
        .animation(.easeInOut(duration: 0.5), value: currentQuestionIndex)
        .onAppear {
            quizStartTime = Date()
            MixpanelManager.shared.trackOnboardingOverallQuizViewed()
        }
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

            // Progress bar (center - prend tout l'espace entre bouton et flag)
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

    // MARK: - Question 1: First Name (Text Input)

    private var firstNameQuestion: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Question text
            Text("Comment puis-je t'appeler ?")
                .font(.custom("Poppins-Medium", size: 18))
                .foregroundColor(.white)
                .lineSpacing(4)
                .padding(.horizontal, 32)
                .padding(.top, 20)
                .padding(.bottom, 20)

            // Text input for first name
            VStack(spacing: 20) {
                TextField("", text: $firstName)
                    .placeholder(when: firstName.isEmpty) {
                        Text("Ton prénom")
                            .foregroundColor(Color.white.opacity(0.5))
                            .font(.custom("Poppins-Medium", size: 16))
                    }
                    .font(.custom("Poppins-Medium", size: 16))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .frame(height: 54)
                    .background(
                        RoundedRectangle(cornerRadius: 40)
                            .fill(Color(hex: "131146").opacity(0.8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 40)
                                    .stroke(Color(hex: "1B1864"), lineWidth: 2)
                            )
                    )
                    .focused($isTextFieldFocused)
                    .onAppear {
                        isTextFieldFocused = true
                    }

                // Continue button
                if !firstName.isEmpty {
                    Button(action: {
                        HapticManager.light()
                        withAnimation(.easeInOut(duration: 0.5)) {
                            currentQuestionIndex += 1
                        }
                    }) {
                        Text("Continuer")
                            .font(.custom("Poppins-SemiBold", size: 16))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 40))
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .padding(.horizontal, 34)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Question 2: Gender

    private var genderQuestion: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Question text
            Text("Quel est ton genre ?")
                .font(.custom("Poppins-Medium", size: 18))
                .foregroundColor(.white)
                .lineSpacing(4)
                .padding(.horizontal, 32)
                .padding(.top, 20)
                .padding(.bottom, 20)

            // Answer buttons
            VStack(spacing: 22) {
                OverallAnswerButton(
                    number: 1,
                    text: "Homme",
                    isSelected: selectedGender == 0,
                    onTap: {
                        HapticManager.light()
                        withAnimation(.easeInOut(duration: 0.5)) {
                            selectedGender = 0
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                            currentQuestionIndex += 1
                        }
                    }
                )

                OverallAnswerButton(
                    number: 2,
                    text: "Femme",
                    isSelected: selectedGender == 1,
                    onTap: {
                        HapticManager.light()
                        withAnimation(.easeInOut(duration: 0.5)) {
                            selectedGender = 1
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                            currentQuestionIndex += 1
                        }
                    }
                )

                OverallAnswerButton(
                    number: 3,
                    text: "Préfère ne pas dire",
                    isSelected: selectedGender == 2,
                    onTap: {
                        HapticManager.light()
                        withAnimation(.easeInOut(duration: 0.5)) {
                            selectedGender = 2
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                            currentQuestionIndex += 1
                        }
                    }
                )
            }
            .padding(.horizontal, 34)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Question 3: Age

    private var ageQuestion: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Question text
            Text("Quel âge as-tu ?")
                .font(.custom("Poppins-Medium", size: 18))
                .foregroundColor(.white)
                .lineSpacing(4)
                .padding(.horizontal, 32)
                .padding(.top, 20)
                .padding(.bottom, 20)

            // Answer buttons
            VStack(spacing: 22) {
                OverallAnswerButton(
                    number: 1,
                    text: "18-24 ans",
                    isSelected: selectedAge == 0,
                    onTap: {
                        HapticManager.light()
                        withAnimation(.easeInOut(duration: 0.5)) {
                            selectedAge = 0
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                            currentQuestionIndex += 1
                            selectedAge = nil
                        }
                    }
                )

                OverallAnswerButton(
                    number: 2,
                    text: "25-34 ans",
                    isSelected: selectedAge == 1,
                    onTap: {
                        HapticManager.light()
                        withAnimation(.easeInOut(duration: 0.5)) {
                            selectedAge = 1
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                            currentQuestionIndex += 1
                            selectedAge = nil
                        }
                    }
                )

                OverallAnswerButton(
                    number: 3,
                    text: "35-44 ans",
                    isSelected: selectedAge == 2,
                    onTap: {
                        HapticManager.light()
                        withAnimation(.easeInOut(duration: 0.5)) {
                            selectedAge = 2
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                            currentQuestionIndex += 1
                            selectedAge = nil
                        }
                    }
                )

                OverallAnswerButton(
                    number: 4,
                    text: "45-54 ans",
                    isSelected: selectedAge == 3,
                    onTap: {
                        HapticManager.light()
                        withAnimation(.easeInOut(duration: 0.5)) {
                            selectedAge = 3
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                            currentQuestionIndex += 1
                            selectedAge = nil
                        }
                    }
                )

                OverallAnswerButton(
                    number: 5,
                    text: "55-64 ans",
                    isSelected: selectedAge == 4,
                    onTap: {
                        HapticManager.light()
                        withAnimation(.easeInOut(duration: 0.5)) {
                            selectedAge = 4
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                            currentQuestionIndex += 1
                            selectedAge = nil
                        }
                    }
                )

                OverallAnswerButton(
                    number: 6,
                    text: "65 ans et plus",
                    isSelected: selectedAge == 5,
                    onTap: {
                        HapticManager.light()
                        withAnimation(.easeInOut(duration: 0.5)) {
                            selectedAge = 5
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                            currentQuestionIndex += 1
                            selectedAge = nil
                        }
                    }
                )
            }
            .padding(.horizontal, 34)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Question 3: Reason (Multiple Choice)

    private var reasonQuestion: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Question text
            Text("Qu'est-ce qui t'a poussé à télécharger CortiFree aujourd'hui ?")
                .font(.custom("Poppins-Medium", size: 18))
                .foregroundColor(.white)
                .lineSpacing(4)
                .padding(.horizontal, 32)
                .padding(.top, 20)
                .padding(.bottom, 20)

            // Answer buttons
            VStack(spacing: 22) {
                OverallAnswerButton(
                    number: 1,
                    text: "Je dors très mal",
                    isSelected: selectedReasons.contains(0),
                    onTap: {
                        HapticManager.light()
                        withAnimation(.easeInOut(duration: 0.3)) {
                            if selectedReasons.contains(0) {
                                selectedReasons.remove(0)
                            } else {
                                selectedReasons.insert(0)
                            }
                        }
                    }
                )

                OverallAnswerButton(
                    number: 2,
                    text: "Je me sens anxieux en permanence",
                    isSelected: selectedReasons.contains(1),
                    onTap: {
                        HapticManager.light()
                        withAnimation(.easeInOut(duration: 0.3)) {
                            if selectedReasons.contains(1) {
                                selectedReasons.remove(1)
                            } else {
                                selectedReasons.insert(1)
                            }
                        }
                    }
                )

                OverallAnswerButton(
                    number: 3,
                    text: "Je suis constamment épuisé",
                    isSelected: selectedReasons.contains(2),
                    onTap: {
                        HapticManager.light()
                        withAnimation(.easeInOut(duration: 0.3)) {
                            if selectedReasons.contains(2) {
                                selectedReasons.remove(2)
                            } else {
                                selectedReasons.insert(2)
                            }
                        }
                    }
                )

                OverallAnswerButton(
                    number: 4,
                    text: "Je n'arrive plus à me concentrer",
                    isSelected: selectedReasons.contains(3),
                    onTap: {
                        HapticManager.light()
                        withAnimation(.easeInOut(duration: 0.3)) {
                            if selectedReasons.contains(3) {
                                selectedReasons.remove(3)
                            } else {
                                selectedReasons.insert(3)
                            }
                        }
                    }
                )

                OverallAnswerButton(
                    number: 5,
                    text: "Je veux améliorer mon bien-être",
                    isSelected: selectedReasons.contains(4),
                    onTap: {
                        HapticManager.light()
                        withAnimation(.easeInOut(duration: 0.3)) {
                            if selectedReasons.contains(4) {
                                selectedReasons.remove(4)
                            } else {
                                selectedReasons.insert(4)
                            }
                        }
                    }
                )

                // Continue button
                if !selectedReasons.isEmpty {
                    Button(action: {
                        HapticManager.light()
                        withAnimation(.easeInOut(duration: 0.5)) {
                            currentQuestionIndex += 1
                        }
                    }) {
                        Text("Continuer")
                            .font(.custom("Poppins-SemiBold", size: 16))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 40))
                    }
                    .padding(.top, 8)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .padding(.horizontal, 34)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Question 4: Duration

    private var durationQuestion: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Question text
            Text("Depuis combien de temps ressens-tu ces difficultés ?")
                .font(.custom("Poppins-Medium", size: 18))
                .foregroundColor(.white)
                .lineSpacing(4)
                .padding(.horizontal, 32)
                .padding(.top, 20)
                .padding(.bottom, 20)

            // Answer buttons
            VStack(spacing: 22) {
                OverallAnswerButton(
                    number: 1,
                    text: "Quelques semaines",
                    isSelected: selectedDuration == 0,
                    onTap: {
                        HapticManager.light()
                        withAnimation(.easeInOut(duration: 0.5)) {
                            selectedDuration = 0
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                            completeQuiz()
                        }
                    }
                )

                OverallAnswerButton(
                    number: 2,
                    text: "2 à 6 mois",
                    isSelected: selectedDuration == 1,
                    onTap: {
                        HapticManager.light()
                        withAnimation(.easeInOut(duration: 0.5)) {
                            selectedDuration = 1
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                            completeQuiz()
                        }
                    }
                )

                OverallAnswerButton(
                    number: 3,
                    text: "6 mois à 1 an",
                    isSelected: selectedDuration == 2,
                    onTap: {
                        HapticManager.light()
                        withAnimation(.easeInOut(duration: 0.5)) {
                            selectedDuration = 2
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                            completeQuiz()
                        }
                    }
                )

                OverallAnswerButton(
                    number: 4,
                    text: "Plus d'un an",
                    isSelected: selectedDuration == 3,
                    onTap: {
                        HapticManager.light()
                        withAnimation(.easeInOut(duration: 0.5)) {
                            selectedDuration = 3
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                            completeQuiz()
                        }
                    }
                )

                OverallAnswerButton(
                    number: 5,
                    text: "Plusieurs années",
                    isSelected: selectedDuration == 4,
                    onTap: {
                        HapticManager.light()
                        withAnimation(.easeInOut(duration: 0.5)) {
                            selectedDuration = 4
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                            completeQuiz()
                        }
                    }
                )
            }
            .padding(.horizontal, 34)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Complete Quiz

    private func completeQuiz() {
        let genderOptions = ["Homme", "Femme", "Préfère ne pas dire"]
        let ageOptions = ["18-24 ans", "25-34 ans", "35-44 ans", "45-54 ans", "55-64 ans", "65 ans et plus"]
        let reasonOptions = [
            "Je dors très mal",
            "Je me sens anxieux en permanence",
            "Je suis constamment épuisé",
            "Je n'arrive plus à me concentrer",
            "Je veux améliorer mon bien-être"
        ]
        let durationOptions = ["Quelques semaines", "2 à 6 mois", "6 mois à 1 an", "Plus d'un an", "Plusieurs années"]

        let selectedReasonTexts = selectedReasons.sorted().map { reasonOptions[$0] }

        let data = OverallQuizData(
            firstName: firstName.trimmingCharacters(in: .whitespacesAndNewlines),
            gender: genderOptions[selectedGender ?? 0],
            age: ageOptions[selectedAge ?? 0],
            reasons: selectedReasonTexts,
            duration: durationOptions[selectedDuration ?? 0]
        )

        // Track quiz completion
        let totalTime = quizStartTime.map { Date().timeIntervalSince($0) } ?? 0
        let ageString = ageOptions[selectedAge ?? 0]
        let ageInt = extractAgeFromString(ageString)

        MixpanelManager.shared.trackOnboardingOverallQuizCompleted(
            firstName: firstName,
            age: ageInt,
            gender: genderOptions[selectedGender ?? 0],
            stressReasons: selectedReasonTexts,
            stressDuration: durationOptions[selectedDuration ?? 0],
            timeToComplete: totalTime
        )

        onComplete(data)
    }

    // Helper to extract age from string like "18-24 ans"
    private func extractAgeFromString(_ ageString: String) -> Int {
        // Extract first number from string like "18-24 ans" -> 18
        let components = ageString.components(separatedBy: CharacterSet.decimalDigits.inverted)
        if let firstNumber = components.first(where: { !$0.isEmpty }), let age = Int(firstNumber) {
            return age
        }
        return 25 // Default fallback
    }
}

// MARK: - Overall Answer Button

struct OverallAnswerButton: View {
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
                        .fill(isSelected ? Color(hex: "#67DB3D") : Color(hex: "4CC6FF"))
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

// MARK: - Data Model

struct OverallQuizData {
    let firstName: String
    let gender: String
    let age: String
    let reasons: [String]
    let duration: String
}

// MARK: - Preview

#Preview {
    OverallQuizView { data in
        print("Quiz completed:")
        print("- Name: \(data.firstName)")
        print("- Gender: \(data.gender)")
        print("- Age: \(data.age)")
        print("- Reasons: \(data.reasons.joined(separator: ", "))")
        print("- Duration: \(data.duration)")
    }
}
