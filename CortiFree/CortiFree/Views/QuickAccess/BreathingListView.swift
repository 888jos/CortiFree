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

    private var breathingExercises: [(pattern: BreathingPattern, imageName: String, titleKey: String)] {
        [
            (.deepAbdominal, "guided_breathing_01", "library.breathing.deep_abdominal"),
            (.fourSevenEight, "guided_breathing_02", "library.breathing.4_7_8"),
            (.coherence, "guided_breathing_03", "library.breathing.cardiac_coherence"),
            (.slow66, "guided_breathing_04", "library.breathing.slow"),
            (.triangle, "guided_breathing_05", "library.breathing.triangle"),
            (.boxBreathing, "guided_breathing_06", "library.breathing.box"),
            (.kapalabhati, "guided_breathing_07", "library.breathing.kapalabhati"),
            (.bhastrika, "guided_breathing_08", "library.breathing.bhastrika")
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
                                imageName: exercise.imageName,
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
                .font(.faroSemiBold(20))
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
    let imageName: String
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
                Image(imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()

                LinearGradient(
                    colors: [.black.opacity(0.62), .clear, .black.opacity(0.52)],
                    startPoint: .top,
                    endPoint: .bottom
                )

                // Title avec étoile en haut à gauche
                VStack {
                    HStack(spacing: 6) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.white)

                        Text(title)
                            .font(.faroSemiBold(12))
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
                RoundedRectangle(cornerRadius: 16).fill(Color(hex: "16233A"))
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    BreathingListView()
}
