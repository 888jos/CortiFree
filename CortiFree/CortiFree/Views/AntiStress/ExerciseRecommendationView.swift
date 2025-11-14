//
//  ExerciseRecommendationView.swift
//  CortiFree
//
//  Created by Claude on 22/10/2025.
//  Step 2: Exercise Recommendations
//

import SwiftUI

struct ExerciseRecommendationView: View {
    let situation: StressSituation
    @ObservedObject var viewModel: AntiStressViewModel
    @State private var selectedExercise: AntiStressExerciseType?
    @State private var showExercise = false

    var recommendations: [ExerciseRecommendation] {
        AntiStressRecommendationEngine.recommendations(for: situation)
    }

    var body: some View {
        ZStack {
            // Galaxy background
            GalaxyBackgroundView(intensity: 1.0)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Text("Exercices recommandés")
                            .font(.custom("Poppins-SemiBold", size: 24))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)

                        Text("Basé sur ta situation actuelle")
                            .font(.custom("Poppins-Regular", size: 16))
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    .padding(.horizontal, 24)

                    // Recommendations Grid (2 colonnes)
                    let columns = [
                        GridItem(.flexible(), spacing: 16),
                        GridItem(.flexible(), spacing: 16)
                    ]

                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(recommendations) { recommendation in
                            RecommendationCard(
                                recommendation: recommendation,
                                onTap: {
                                    HapticManager.light()
                                    selectedExercise = recommendation.exerciseType
                                    showExercise = true
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 24)

                    Spacer(minLength: 40)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
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

// MARK: - Recommendation Card

struct RecommendationCard: View {
    let recommendation: ExerciseRecommendation
    let onTap: () -> Void

    // Couleur unique pour le badge
    private var percentageColor: Color {
        return Color.appTheme
    }

    var body: some View {
        Button(action: onTap) {
            GeometryReader { geometry in
                ZStack(alignment: .topLeading) {
                    // Badge de pourcentage en haut à gauche
                    HStack(spacing: 4) {
                        Text("\(recommendation.matchPercentage)%")
                            .font(.custom("Poppins-Bold", size: 16))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(percentageColor)
                            .shadow(color: percentageColor.opacity(0.4), radius: 8, x: 0, y: 2)
                    )
                    .padding(12)
                    .zIndex(1)

                    // Contenu principal
                    VStack(spacing: 0) {
                        Spacer()

                        // Titre et description au centre
                        VStack(alignment: .center, spacing: 8) {
                            Text(recommendation.displayName)
                                .font(.custom("Poppins-SemiBold", size: 16))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                                .minimumScaleFactor(0.8)

                            Text("\(recommendation.duration / 60) min")
                                .font(.custom("Poppins-Regular", size: 13))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .padding(.horizontal, 12)

                        Spacer()
                    }
                }
            }
            .aspectRatio(1.0, contentMode: .fit)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(hex: "131146").opacity(0.8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(percentageColor.opacity(0.3), lineWidth: 2)
                    )
            )
            .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
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
