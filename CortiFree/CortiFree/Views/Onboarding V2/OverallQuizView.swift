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

    @ObservedObject var languageManager = LanguageManager.shared
    @State private var currentQuestionIndex: Int = 0
    @State private var selectedGender: Int? = nil
    @State private var selectedAge: Int? = nil
    @State private var selectedReasons: Set<Int> = []
    @State private var selectedAcquisition: Int? = nil
    @State private var selectedDuration: Int? = nil
    @State private var isGoingBack: Bool = false
    @State private var quizStartTime: Date?
    @State private var questionStartTime: Date?

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

            ScrollView {
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
                        genderQuestion
                            .id(0)
                            .transition(.asymmetric(
                                insertion: .move(edge: isGoingBack ? .leading : .trailing),
                                removal: .move(edge: isGoingBack ? .trailing : .leading)
                            ))
                    } else if currentQuestionIndex == 1 {
                        ageQuestion
                            .id(1)
                            .transition(.asymmetric(
                                insertion: .move(edge: isGoingBack ? .leading : .trailing),
                                removal: .move(edge: isGoingBack ? .trailing : .leading)
                            ))
                    } else if currentQuestionIndex == 2 {
                        acquisitionQuestion
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

                    Spacer(minLength: 100)
                }
            }
        }
        .animation(.easeInOut(duration: 0.5), value: currentQuestionIndex)
        .onAppear {
            quizStartTime = Date()
            questionStartTime = Date()
            MixpanelManager.shared.trackOnboardingOverallQuizViewed()
            // Track first question viewed
            trackQuestionViewed(0)
        }
        .onChange(of: currentQuestionIndex) { _, newIndex in
            questionStartTime = Date()
            trackQuestionViewed(newIndex)
        }
    }

    // MARK: - Question Tracking

    private func trackQuestionViewed(_ index: Int) {
        let questionTexts = [
            "Genre",
            "Âge",
            "Comment as-tu découvert CortiFree ?",
            "Raisons du stress",
            "Durée du stress"
        ]
        MixpanelManager.shared.trackOnboardingQuizQuestionViewed(
            questionNumber: index + 1,
            questionText: questionTexts[safe: index] ?? "Question \(index + 1)",
            quizType: "overall"
        )
    }

    private func trackQuestionAnswered(_ index: Int, answerIndex: Int, answerText: String) {
        let questionTexts = [
            "Genre",
            "Âge",
            "Comment as-tu découvert CortiFree ?",
            "Raisons du stress",
            "Durée du stress"
        ]
        let timeToAnswer = questionStartTime.map { Date().timeIntervalSince($0) } ?? 0.0
        MixpanelManager.shared.trackOnboardingQuizQuestionAnswered(
            questionNumber: index + 1,
            questionText: questionTexts[safe: index] ?? "Question \(index + 1)",
            answerIndex: answerIndex,
            answerText: answerText,
            timeToAnswer: timeToAnswer,
            quizType: "overall"
        )
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

            // Language selector button (right)
            LanguageSelectorButton()
                .padding(.trailing, 30)
        }
        .frame(height: 20)
    }

    // MARK: - Question 1: Gender

    private var genderQuestion: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Question text
            Text("onboarding_v2.overall.gender_question".localized)
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
                    text: "onboarding_v2.overall.gender_male".localized,
                    isSelected: selectedGender == 0,
                    onTap: {
                        HapticManager.light()
                        trackQuestionAnswered(0, answerIndex: 0, answerText: "onboarding_v2.overall.gender_male".localized)
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
                    text: "onboarding_v2.overall.gender_female".localized,
                    isSelected: selectedGender == 1,
                    onTap: {
                        HapticManager.light()
                        trackQuestionAnswered(0, answerIndex: 1, answerText: "onboarding_v2.overall.gender_female".localized)
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
                    text: "onboarding_v2.overall.gender_other".localized,
                    isSelected: selectedGender == 2,
                    onTap: {
                        HapticManager.light()
                        trackQuestionAnswered(0, answerIndex: 2, answerText: "onboarding_v2.overall.gender_other".localized)
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

    // MARK: - Question 2: Age

    private var ageQuestion: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Question text
            Text("onboarding_v2.overall.age_question".localized)
                .font(.custom("Poppins-Medium", size: 18))
                .foregroundColor(.white)
                .lineSpacing(4)
                .padding(.horizontal, 32)
                .padding(.top, 20)
                .padding(.bottom, 20)

            // Answer buttons
            VStack(spacing: 22) {
                ForEach(0..<6, id: \.self) { index in
                    let ageTexts = [
                        "onboarding_v2.overall.age_under_18".localized,
                        "onboarding_v2.overall.age_18_24".localized,
                        "onboarding_v2.overall.age_25_34".localized,
                        "onboarding_v2.overall.age_35_44".localized,
                        "onboarding_v2.overall.age_45_54".localized,
                        "onboarding_v2.overall.age_55_plus".localized
                    ]
                    OverallAnswerButton(
                        number: index + 1,
                        text: ageTexts[index],
                        isSelected: selectedAge == index,
                        onTap: {
                            HapticManager.light()
                            trackQuestionAnswered(1, answerIndex: index, answerText: ageTexts[index])
                            withAnimation(.easeInOut(duration: 0.5)) {
                                selectedAge = index
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                currentQuestionIndex += 1
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, 34)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Question 3: Acquisition (How discovered CortiFree)

    private var acquisitionQuestion: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Question text
            Text("onboarding_v2.habits.q9".localized)
                .font(.custom("Poppins-Medium", size: 18))
                .foregroundColor(.white)
                .lineSpacing(4)
                .padding(.horizontal, 32)
                .padding(.top, 20)
                .padding(.bottom, 20)

            // Answer buttons
            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    ForEach(0..<6, id: \.self) { index in
                        let acquisitionTexts = [
                            "onboarding_v2.habits.q9_opt1".localized,
                            "onboarding_v2.habits.q9_opt2".localized,
                            "onboarding_v2.habits.q9_opt3".localized,
                            "onboarding_v2.habits.q9_opt4".localized,
                            "onboarding_v2.habits.q9_opt5".localized,
                            "onboarding_v2.habits.q9_opt6".localized
                        ]
                        OverallAnswerButton(
                            number: index + 1,
                            text: acquisitionTexts[index],
                            isSelected: selectedAcquisition == index,
                            onTap: {
                                HapticManager.light()
                                trackQuestionAnswered(2, answerIndex: index, answerText: acquisitionTexts[index])
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    selectedAcquisition = index
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                    currentQuestionIndex += 1
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, 34)
                .padding(.bottom, 40)
            }
        }
    }

    // MARK: - Question 4: Reason (Multiple Choice)

    private var reasonQuestion: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Question text
            Text("onboarding_v2.overall.reason_question".localized)
                .font(.custom("Poppins-Medium", size: 18))
                .foregroundColor(.white)
                .lineSpacing(4)
                .padding(.horizontal, 32)
                .padding(.top, 20)
                .padding(.bottom, 20)

            // Answer buttons
            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    OverallAnswerButton(
                        number: 1,
                        text: "onboarding_v2.overall.reason_sleep".localized,
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
                        text: "onboarding_v2.overall.reason_anxiety".localized,
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
                        text: "onboarding_v2.overall.reason_energy".localized,
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
                        text: "onboarding_v2.overall.reason_mental".localized,
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
                        text: "onboarding_v2.overall.reason_difficult".localized,
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

                    OverallAnswerButton(
                        number: 6,
                        text: "onboarding_v2.overall.reason_habits".localized,
                        isSelected: selectedReasons.contains(5),
                        onTap: {
                            HapticManager.light()
                            withAnimation(.easeInOut(duration: 0.3)) {
                                if selectedReasons.contains(5) {
                                    selectedReasons.remove(5)
                                } else {
                                    selectedReasons.insert(5)
                                }
                            }
                        }
                    )

                    // Continue button
                    if !selectedReasons.isEmpty {
                        Button(action: {
                            HapticManager.light()
                            let reasonTexts = [
                                "onboarding_v2.overall.reason_sleep".localized,
                                "onboarding_v2.overall.reason_anxiety".localized,
                                "onboarding_v2.overall.reason_energy".localized,
                                "onboarding_v2.overall.reason_mental".localized,
                                "onboarding_v2.overall.reason_difficult".localized,
                                "onboarding_v2.overall.reason_habits".localized
                            ]
                            let selectedTexts = selectedReasons.sorted().compactMap { reasonTexts[safe: $0] }.joined(separator: ", ")
                            trackQuestionAnswered(3, answerIndex: selectedReasons.count, answerText: selectedTexts)
                            withAnimation(.easeInOut(duration: 0.5)) {
                                currentQuestionIndex += 1
                            }
                        }) {
                            Text(StringKeys.Common.continueButton)
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
    }

    // MARK: - Question 5: Duration

    private var durationQuestion: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Question text
            Text("onboarding_v2.overall.duration_question".localized)
                .font(.custom("Poppins-Medium", size: 18))
                .foregroundColor(.white)
                .lineSpacing(4)
                .padding(.horizontal, 32)
                .padding(.top, 20)
                .padding(.bottom, 20)

            // Answer buttons
            VStack(spacing: 22) {
                ForEach(0..<5, id: \.self) { index in
                    let durationTexts = [
                        "onboarding_v2.overall.duration_weeks".localized,
                        "onboarding_v2.overall.duration_2_6_months".localized,
                        "onboarding_v2.overall.duration_6_12_months".localized,
                        "onboarding_v2.overall.duration_1_year_plus".localized,
                        "onboarding_v2.overall.duration_years".localized
                    ]
                    OverallAnswerButton(
                        number: index + 1,
                        text: durationTexts[index],
                        isSelected: selectedDuration == index,
                        onTap: {
                            HapticManager.light()
                            trackQuestionAnswered(4, answerIndex: index, answerText: durationTexts[index])
                            withAnimation(.easeInOut(duration: 0.5)) {
                                selectedDuration = index
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                completeQuiz()
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, 34)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Complete Quiz

    private func completeQuiz() {
        let genderOptions = [
            "onboarding_v2.overall.gender_male".localized,
            "onboarding_v2.overall.gender_female".localized,
            "onboarding_v2.overall.gender_other".localized
        ]
        let ageOptions = [
            "onboarding_v2.overall.age_under_18".localized,
            "onboarding_v2.overall.age_18_24".localized,
            "onboarding_v2.overall.age_25_34".localized,
            "onboarding_v2.overall.age_35_44".localized,
            "onboarding_v2.overall.age_45_54".localized,
            "onboarding_v2.overall.age_55_plus".localized
        ]
        let acquisitionOptions = [
            "App Store",
            "Instagram",
            "TikTok",
            "Bouche à oreille",
            "Publicité",
            "Autre"
        ]
        let reasonOptions = [
            "onboarding_v2.overall.reason_sleep".localized,
            "onboarding_v2.overall.reason_anxiety".localized,
            "onboarding_v2.overall.reason_energy".localized,
            "onboarding_v2.overall.reason_mental".localized,
            "onboarding_v2.overall.reason_difficult".localized,
            "onboarding_v2.overall.reason_habits".localized
        ]
        let durationOptions = [
            "onboarding_v2.overall.duration_weeks".localized,
            "onboarding_v2.overall.duration_2_6_months".localized,
            "onboarding_v2.overall.duration_6_12_months".localized,
            "onboarding_v2.overall.duration_1_year_plus".localized,
            "onboarding_v2.overall.duration_years".localized
        ]

        let selectedReasonTexts = selectedReasons.sorted().map { reasonOptions[$0] }
        let acquisitionChannel = acquisitionOptions[selectedAcquisition ?? 5]

        let data = OverallQuizData(
            gender: genderOptions[selectedGender ?? 0],
            age: ageOptions[selectedAge ?? 0],
            acquisitionChannel: acquisitionChannel,
            reasons: selectedReasonTexts,
            duration: durationOptions[selectedDuration ?? 0]
        )

        // Track quiz completion
        let totalTime = quizStartTime.map { Date().timeIntervalSince($0) } ?? 0
        let ageString = ageOptions[selectedAge ?? 0]
        let ageInt = extractAgeFromString(ageString)

        MixpanelManager.shared.trackOnboardingOverallQuizCompleted(
            firstName: "",
            age: ageInt,
            gender: genderOptions[selectedGender ?? 0],
            stressReasons: selectedReasonTexts,
            stressDuration: durationOptions[selectedDuration ?? 0],
            timeToComplete: totalTime
        )

        // Track acquisition channel separately
        MixpanelManager.shared.trackOnboardingMarketingData(
            acquisitionChannel: acquisitionChannel,
            previousAppExperience: nil
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
    let gender: String
    let age: String
    let acquisitionChannel: String
    let reasons: [String]
    let duration: String
}

// MARK: - Preview

#Preview {
    OverallQuizView { data in
        print("Quiz completed:")
        print("- Gender: \(data.gender)")
        print("- Age: \(data.age)")
        print("- Reasons: \(data.reasons.joined(separator: ", "))")
        print("- Duration: \(data.duration)")
    }
}
