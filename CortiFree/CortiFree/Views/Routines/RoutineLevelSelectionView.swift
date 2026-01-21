//
//  RoutineLevelSelectionView.swift
//  CortiFree
//
//  Created on 20/01/2026.
//

import SwiftUI

struct RoutineLevelSelectionView: View {
    let category: RoutineCategory
    @Environment(\.dismiss) var dismiss
    @State private var selectedRoutine: Routine?
    @State private var showPlayer = false

    private var routines: [Routine] {
        Routine.routines(for: category)
    }

    private var isFrench: Bool {
        Locale.preferredLanguages.first?.hasPrefix("fr") ?? false
    }

    var body: some View {
        ZStack {
            // Galaxy background
            GalaxyBackgroundView(intensity: 1.0)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header with category info
                headerSection

                // Level cards
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        ForEach(routines) { routine in
                            RoutineLevelDetailCard(routine: routine, category: category) {
                                selectedRoutine = routine
                            }
                        }

                        // Info section
                        infoSection
                            .padding(.top, 16)

                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
                }
            }
        }
        .navigationBarHidden(true)
        .onChange(of: selectedRoutine) { _, newValue in
            if newValue != nil {
                showPlayer = true
            }
        }
        .fullScreenCover(isPresented: $showPlayer) {
            if let routine = selectedRoutine {
                RoutinePlayerView(routine: routine)
            }
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 0) {
            // Top bar with back button
            HStack {
                Button(action: {
                    HapticManager.light()
                    dismiss()
                }) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: "1A1B3A").opacity(0.8))
                            .frame(width: 40, height: 40)

                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }

                Spacer()

                // Category title centered
                Text(category.localizedName)
                    .font(.custom("Poppins-Bold", size: 20))
                    .foregroundColor(.white)

                Spacer()

                // Category icon
                ZStack {
                    Circle()
                        .fill(Color(hex: category.color).opacity(0.2))
                        .frame(width: 40, height: 40)

                    Image(systemName: category.icon)
                        .font(.system(size: 18))
                        .foregroundColor(Color(hex: category.color))
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 60)

            // Subtitle - choose your level
            Text(isFrench ? "Choisissez votre niveau" : "Choose your level")
                .font(.custom("Poppins-Regular", size: 14))
                .foregroundColor(.white.opacity(0.6))
                .padding(.top, 16)
                .padding(.bottom, 8)
        }
    }

    // MARK: - Info Section
    private var infoSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: category.color))

                Text(isFrench ? "Conseil" : "Tip")
                    .font(.custom("Poppins-SemiBold", size: 14))
                    .foregroundColor(.white)

                Spacer()
            }

            Text(isFrench ?
                 "Commencez par le niveau Débutant pour vous familiariser avec les exercices, puis progressez vers les niveaux supérieurs." :
                 "Start with the Beginner level to familiarize yourself with the exercises, then progress to higher levels.")
                .font(.custom("Poppins-Regular", size: 13))
                .foregroundColor(.white.opacity(0.7))
                .lineSpacing(4)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(hex: category.color).opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Routine Level Detail Card (Compact design)
struct RoutineLevelDetailCard: View {
    let routine: Routine
    let category: RoutineCategory
    let action: () -> Void

    private var isFrench: Bool {
        Locale.preferredLanguages.first?.hasPrefix("fr") ?? false
    }

    var body: some View {
        Button(action: {
            HapticManager.light()
            action()
        }) {
            HStack(spacing: 14) {
                // Difficulty indicator (compact)
                VStack(spacing: 6) {
                    // Difficulty bars
                    HStack(alignment: .bottom, spacing: 3) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(routine.difficulty >= 1 ? Color(hex: category.color) : Color.white.opacity(0.2))
                            .frame(width: 6, height: 10)

                        RoundedRectangle(cornerRadius: 2)
                            .fill(routine.difficulty >= 2 ? Color(hex: category.color) : Color.white.opacity(0.2))
                            .frame(width: 6, height: 16)

                        RoundedRectangle(cornerRadius: 2)
                            .fill(routine.difficulty >= 3 ? Color(hex: category.color) : Color.white.opacity(0.2))
                            .frame(width: 6, height: 22)
                    }

                    Text(routine.difficultyText)
                        .font(.custom("Poppins-Medium", size: 9))
                        .foregroundColor(Color(hex: category.color))
                }
                .frame(width: 50)

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(routine.localizedName)
                        .font(.custom("Poppins-SemiBold", size: 15))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    // Stats row
                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.system(size: 11))
                            Text(routine.formattedDuration)
                                .font(.custom("Poppins-Regular", size: 12))
                        }
                        .foregroundColor(.white.opacity(0.6))

                        HStack(spacing: 4) {
                            Image(systemName: "list.number")
                                .font(.system(size: 11))
                            Text("\(routine.steps.count) \(isFrench ? "étapes" : "steps")")
                                .font(.custom("Poppins-Regular", size: 12))
                        }
                        .foregroundColor(.white.opacity(0.6))
                    }
                }

                Spacer()

                // Play button (circle) - white with dark violet chevron
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 44, height: 44)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color(hex: "5E35B1"))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

#Preview {
    RoutineLevelSelectionView(category: .morning)
}
