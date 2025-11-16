//
//  OnboardingQuizView.swift
//  CortiFree
//
//  Created by Claude on 31/10/2025.
//  Main quiz view with navigation and progress
//

import SwiftUI

struct OnboardingQuizView: View {
    @ObservedObject var quizState: QuizState
    var onComplete: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss

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
                    if !quizState.showInfoScreen, let question = quizState.currentQuestion {
                        Text("Question #\(question.questionNumber)")
                            .font(.custom("Poppins-Bold", size: 24))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 30)
                            .id("questionTitle") // Keep it stable
                    }

                    // Sliding content
                    if quizState.showInfoScreen, let infoScreen = quizState.currentInfoScreen {
                        InfoScreenView(infoScreen: infoScreen) {
                            quizState.moveToNextQuestion()
                        }
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing),
                            removal: .move(edge: .leading)
                        ))
                    } else if let question = quizState.currentQuestion {
                        QuestionContentView(
                            question: question,
                            onAnswerSelected: { answerIndex in
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    quizState.selectAnswer(answerIndex)
                                }
                            },
                            quizState: quizState
                        )
                        .id(question.id) // Force recreation for transition
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing),
                            removal: .move(edge: .leading)
                        ))
                    }
                }

                Spacer()
            }
        }
        .animation(.easeInOut(duration: 0.5), value: quizState.currentQuestionIndex)
        .onChange(of: quizState.isCompleted) { oldValue, completed in
            if completed {
                onComplete?()
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack(spacing: 0) {
            // Back button (left)
            Button(action: {
                HapticManager.light()
                if quizState.currentQuestionIndex > 0 {
                    quizState.moveToPreviousQuestion()
                } else {
                    dismiss()
                }
            }) {
                Image(systemName: "chevron.left")
                    .font(.custom("Poppins-Bold", size: 22))
                    .foregroundColor(.white)
                    .frame(width: 20, height: 20)
            }
            .padding(.leading, 30)

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
                                    Color(hex: "73DE85"),
                                    Color(hex: "53D7D9")
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * quizState.progress, height: 8)
                        .animation(.easeInOut(duration: 0.3), value: quizState.progress)
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
}

// MARK: - Question Content View (without title)

struct QuestionContentView: View {
    let question: QuizQuestion
    let onAnswerSelected: (Int) -> Void
    @ObservedObject var quizState: QuizState

    @State private var selectedAnswer: Int? = nil
    @State private var textInput: String = ""
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Question text (title is now separate and fixed)
            Text(question.questionText)
                .font(.custom("Poppins-Medium", size: 18))
                .foregroundColor(.white)
                .lineSpacing(4)
                .padding(.horizontal, 32)
                .padding(.top, 20)
                .padding(.bottom, 20)

            // Check if it's a text input question (question 23 - first name)
            if question.answers.isEmpty {
                // Text input for first name
                VStack(spacing: 20) {
                    TextField("", text: $textInput)
                        .placeholder(when: textInput.isEmpty) {
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
                    if !textInput.isEmpty {
                        Button(action: {
                            HapticManager.light()
                            quizState.userFirstName = textInput
                            onAnswerSelected(0)
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
            } else {
                // Answer buttons for multiple choice
                VStack(spacing: 22) {
                    ForEach(0..<question.answers.count, id: \.self) { index in
                        AnswerButton(
                            number: index + 1,
                            text: question.answers[index],
                            isSelected: selectedAnswer == index,
                            onTap: {
                                HapticManager.light()
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    selectedAnswer = index
                                }

                                // Auto-advance after 0.8s
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                    onAnswerSelected(index)
                                    selectedAnswer = nil // Reset for next question
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
}

// Extension pour placeholder
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {

        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

// MARK: - Answer Button

struct AnswerButton: View {
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

// MARK: - Info Screen View

struct InfoScreenView: View {
    let infoScreen: InfoScreen
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Optional Lottie animation space
            if let _ = infoScreen.lottieAnimation {
                // TODO: Add Lottie animation here
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 260, height: 260)
                    .overlay(
                        Text("🎬")
                            .font(.system(size: 80))
                    )
            }

            VStack(spacing: 16) {
                // Title
                Text(infoScreen.title)
                    .font(.custom("Poppins-Bold", size: 22))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 36)

                // Body text
                Text(infoScreen.bodyText)
                    .font(.custom("Poppins-Medium", size: 14))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .padding(.horizontal, 36)

                // Data insight
                Text(infoScreen.dataInsight)
                    .font(.custom("Poppins-Regular", size: 12))
                    .foregroundColor(Color(hex: "73DE85"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 36)
                    .padding(.top, 8)
            }

            Spacer()

            // Continue button
            Button(action: {
                HapticManager.light()
                onContinue()
            }) {
                Text("Continuer")
                    .font(.custom("Poppins-SemiBold", size: 16))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(
                        LinearGradient(
                            colors: [
                                Color(hex: "73DE85"),
                                Color(hex: "53D7D9")
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 27))
            }
            .padding(.horizontal, 34)
            .padding(.bottom, 40)
        }
    }
}

#Preview {
    OnboardingQuizView(quizState: QuizState())
}
