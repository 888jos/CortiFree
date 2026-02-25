//
//  ExerciseRecommendationView.swift
//  CortiFree
//
//  Created by Claude on 22/10/2025.
//  Step 2: Exercise Recommendations - Modern Glassmorphic Design
//

import SwiftUI

struct ExerciseRecommendationView: View {
    let situation: StressSituation
    @ObservedObject var viewModel: AntiStressViewModel
    @State private var selectedExercise: AntiStressExerciseType?
    @State private var showExercise = false
    @Environment(\.dismiss) var dismiss

    var recommendations: [ExerciseRecommendation] {
        AntiStressRecommendationEngine.recommendations(for: situation)
    }

    var body: some View {
        ZStack {
            // Galaxy background
            GalaxyBackgroundView(intensity: 1.0)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    // Header
                    VStack(spacing: 12) {
                        Text(NSLocalizedString("antistress.recommendation.title", comment: ""))
                            .font(.custom("Poppins-SemiBold", size: 26))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white, Color(hex: "B794F6")],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .multilineTextAlignment(.center)

                        Text(NSLocalizedString("antistress.recommendation.subtitle", comment: ""))
                            .font(.custom("Poppins-Regular", size: 15))
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    .padding(.horizontal, 24)

                    // Hero Card (Top Match)
                    if let topMatch = recommendations.first {
                        ModernExerciseCard(
                            exercise: topMatch,
                            isTopMatch: true,
                            onTap: {
                                HapticManager.light()
                                selectedExercise = topMatch.exerciseType
                                showExercise = true
                            }
                        )
                        .padding(.horizontal, 24)
                        .cascadeAppear(index: 0, baseDelay: 0.1)
                    }

                    // Remaining Recommendations Grid (2 colonnes)
                    if recommendations.count > 1 {
                        let columns = [
                            GridItem(.flexible(), spacing: 16),
                            GridItem(.flexible(), spacing: 16)
                        ]

                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(Array(recommendations.dropFirst().enumerated()), id: \.element.id) { index, recommendation in
                                ModernExerciseCard(
                                    exercise: recommendation,
                                    isTopMatch: false,
                                    onTap: {
                                        HapticManager.light()
                                        selectedExercise = recommendation.exerciseType
                                        showExercise = true
                                    }
                                )
                                .cascadeAppear(index: index + 1, baseDelay: 0.1)
                            }
                        }
                        .padding(.horizontal, 24)
                    }

                    Spacer(minLength: 40)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    HapticManager.light()
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
        }
        .navigationDestination(isPresented: $showExercise) {
            if let exercise = selectedExercise {
                ExerciseRouterView(
                    exerciseType: exercise,
                    situation: situation,
                    viewModel: viewModel
                )
            }
        }
    }
}

#Preview {
    NavigationStack {
        ExerciseRecommendationView(
            situation: .overwhelmed,
            viewModel: AntiStressViewModel()
        )
    }
}
