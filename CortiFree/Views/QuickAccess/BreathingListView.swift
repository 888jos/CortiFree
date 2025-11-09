//
//  BreathingListView.swift
//  CortiFree
//
//  Created by Claude on 23/10/2025.
//  Liste des exercices de respiration depuis l'accueil
//

import SwiftUI

struct BreathingListView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showBreathingDetail = false
    @State private var selectedBreathingPattern: BreathingPattern?

    let breathingExercises: [(pattern: BreathingPattern, icon: String, title: String)] = [
        (.fourSevenEight, "wind", "4-7-8"),
        (.boxBreathing, "square.dashed", "Box Breathing"),
        (.coherence, "heart.fill", "Cohérence"),
        (.deepRelax, "figure.mind.and.body", "Deep Relax"),
        (.energizing, "bolt.fill", "Energizing"),
        (.fourSevenEight, "moon.fill", "Sommeil"),
        (.boxBreathing, "sparkles", "Clarté Mentale"),
        (.energizing, "sun.max.fill", "Éveil")
    ]

    var body: some View {
        ZStack {
            // Galaxy background
            GalaxyBackgroundView(intensity: 1.0)

            VStack(spacing: 0) {
                // Header
                headerSection

                // Grid des exercices
                ScrollView(showsIndicators: false) {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 24),
                        GridItem(.flexible(), spacing: 24)
                    ], spacing: 24) {
                        ForEach(breathingExercises, id: \.title) { exercise in
                            BreathingCard(
                                icon: exercise.icon,
                                title: exercise.title
                            ) {
                                selectedBreathingPattern = exercise.pattern
                                showBreathingDetail = true
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .padding(.bottom, 24)

                    Spacer(minLength: 40)
                }
            }
        }
        .sheet(isPresented: $showBreathingDetail) {
            if let pattern = selectedBreathingPattern {
                BreathingExerciseDetailView(pattern: pattern)
            }
        }
    }

    private var headerSection: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.custom("Poppins-SemiBold", size: 18))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Color.white.opacity(0.1)))
            }

            Spacer()

            Text("Exercices de Respiration")
                .font(.custom("Poppins-SemiBold", size: 20))
                .foregroundColor(.white)

            Spacer()

            Color.clear.frame(width: 36, height: 36)
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }
}

struct BreathingCard: View {
    let icon: String
    let title: String
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            HapticManager.light()
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                    isPressed = false
                }
            }
            action()
        }) {
            VStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color(hex: "0E0530"))
                        .frame(width: 60, height: 60)

                    Image(systemName: icon)
                        .font(.system(size: 26))
                        .foregroundColor(.white)
                }

                // Title
                Text(title)
                    .font(.custom("Poppins-Medium", size: 15))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, minHeight: 160)
            .aspectRatio(1, contentMode: .fit)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: "49288C").opacity(0.4),
                                Color(hex: "2A2B5A").opacity(0.6)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.appTheme.opacity(0.3),
                                        Color.appThemeSecondary.opacity(0.3)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    BreathingListView()
}
