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
    @ObservedObject private var languageManager = LanguageManager.shared
    @State private var showBreathingDetail = false
    @State private var selectedBreathingPattern: BreathingPattern?

    private var breathingExercises: [(pattern: BreathingPattern, icon: String, titleKey: String)] {
        [
            (.deepAbdominal, "wind", "library.breathing.deep_abdominal"),
            (.fourSevenEight, "moon.stars.fill", "library.breathing.4_7_8"),
            (.coherence, "heart.fill", "library.breathing.cardiac_coherence"),
            (.slow66, "bed.double.fill", "library.breathing.slow"),
            (.triangle, "triangle", "library.breathing.triangle"),
            (.boxBreathing, "square", "library.breathing.box"),
            (.kapalabhati, "bolt.fill", "library.breathing.kapalabhati"),
            (.bhastrika, "flame.fill", "library.breathing.bhastrika")
        ]
    }

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
                        ForEach(breathingExercises, id: \.titleKey) { exercise in
                            BreathingCard(
                                icon: exercise.icon,
                                title: languageManager.localized(exercise.titleKey)
                            ) {
                                selectedBreathingPattern = exercise.pattern
                                showBreathingDetail = true
                            }
                        }
                    }
                    .id(languageManager.refreshID)
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

            Text(languageManager.localized("library.breathing.title"))
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
            ZStack {
                // Centered icon
                Image(systemName: icon)
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundColor(Color(hex: "E4F9FF"))

                // Title avec étoile en haut à gauche
                VStack {
                    HStack(spacing: 6) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.white)

                        Text(title)
                            .font(.custom("Poppins-SemiBold", size: 12))
                            .foregroundColor(.white)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)

                        Spacer()
                    }
                    .padding(.top, 12)
                    .padding(.leading, 12)
                    .padding(.trailing, 12)

                    Spacer()
                }
            }
            .frame(maxWidth: .infinity, minHeight: 160)
            .aspectRatio(1, contentMode: .fit)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(hex: "16233A"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(hex: "E4F9FF").opacity(0.3), lineWidth: 1)
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
