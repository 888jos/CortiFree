//
//  DailyProgramView.swift
//  CortiFree
//
//  Created by Claude on 10/11/2025.
//  Vue pour afficher le programme quotidien du jour
//

import SwiftUI

struct DailyProgramView: View {
    let dailyProgram: DailyProgram
    @State private var completedExercises: Set<String> = []
    @State private var showCheckpointCelebration = false
    @Binding var totalXPEarned: Int

    var allExercisesCompleted: Bool {
        dailyProgram.exercises.allSatisfy { completedExercises.contains($0.id) }
    }

    var earnedXP: Int {
        dailyProgram.exercises.filter { completedExercises.contains($0.id) }
            .reduce(0) { $0 + $1.xpReward }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // Header with day number and title
                headerSection

                // Theme and time of day
                metadataSection

                // Guidance message
                guidanceSection

                // Exercises list
                exercisesSection

                // Stats footer
                statsSection

                // Checkpoint badge (if applicable)
                if let checkpoint = dailyProgram.checkpoint {
                    checkpointSection(checkpoint)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 100)
        }
        .background(
            GalaxyBackgroundView(intensity: 0.8)
                .ignoresSafeArea()
        )
        .sheet(isPresented: $showCheckpointCelebration) {
            if let checkpoint = dailyProgram.checkpoint {
                CheckpointCelebrationView(checkpoint: checkpoint)
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            // Day number badge
            HStack {
                Spacer()
                Text("JOUR \(dailyProgram.day)")
                    .font(.custom("Poppins-Bold", size: 14))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color.appTheme, Color.appThemeSecondary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                Spacer()
            }

            // Title
            Text(dailyProgram.title)
                .font(.custom("Poppins-Bold", size: 28))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
    }

    private var metadataSection: some View {
        HStack(spacing: 16) {
            // Time of day
            HStack(spacing: 8) {
                Image(systemName: dailyProgram.timeOfDay.icon)
                    .font(.system(size: 16))
                    .foregroundColor(Color.appTheme)

                Text(dailyProgram.timeOfDay.displayName)
                    .font(.custom("Poppins-Medium", size: 14))
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.1))
            )

            // Theme
            HStack(spacing: 8) {
                Image(systemName: "star.fill")
                    .font(.system(size: 14))
                    .foregroundColor(Color.appTheme)

                Text(dailyProgram.theme)
                    .font(.custom("Poppins-Medium", size: 14))
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.1))
            )
        }
    }

    private var guidanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "quote.bubble.fill")
                    .font(.system(size: 18))
                    .foregroundColor(Color.appTheme)

                Text("Message du jour")
                    .font(.custom("Poppins-SemiBold", size: 16))
                    .foregroundColor(.white)
            }

            Text(dailyProgram.guidance)
                .font(.custom("Poppins-Regular", size: 15))
                .foregroundColor(.white.opacity(0.9))
                .lineSpacing(6)
                .italic()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.appTheme.opacity(0.15),
                            Color.appThemeSecondary.opacity(0.10)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.appTheme.opacity(0.3), lineWidth: 1)
                )
        )
    }

    private var exercisesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Exercices du jour")
                .font(.custom("Poppins-SemiBold", size: 18))
                .foregroundColor(.white)

            ForEach(dailyProgram.exercises) { exercise in
                ExerciseCard(
                    exercise: exercise,
                    isCompleted: completedExercises.contains(exercise.id),
                    onToggle: {
                        toggleExercise(exercise)
                    }
                )
            }
        }
    }

    private var statsSection: some View {
        HStack(spacing: 20) {
            // Total duration
            StatBadge(
                icon: "clock.fill",
                value: "\(dailyProgram.totalDuration) min",
                label: "Durée totale",
                color: Color.appTheme
            )

            // Total XP
            StatBadge(
                icon: "star.fill",
                value: "\(earnedXP)/\(dailyProgram.totalXP) XP",
                label: "XP gagnés",
                color: Color(hex: "FFD700")
            )
        }
        .padding(.top, 8)
    }

    private func checkpointSection(_ checkpoint: RoutineCheckpoint) -> some View {
        VStack(spacing: 16) {
            Image(systemName: checkpoint.badgeIcon)
                .font(.system(size: 48))
                .foregroundColor(Color(hex: checkpoint.badgeColor))

            Text(checkpoint.title)
                .font(.custom("Poppins-Bold", size: 22))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            Text(checkpoint.description)
                .font(.custom("Poppins-Regular", size: 15))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)

            HStack(spacing: 8) {
                Image(systemName: "gift.fill")
                    .font(.system(size: 16))
                Text("+\(checkpoint.bonusXP) XP Bonus")
                    .font(.custom("Poppins-SemiBold", size: 16))
            }
            .foregroundColor(Color(hex: "FFD700"))
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(Color(hex: "FFD700").opacity(0.2))
            )
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: checkpoint.badgeColor).opacity(0.2),
                            Color(hex: checkpoint.badgeColor).opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            Color(hex: checkpoint.badgeColor).opacity(0.5),
                            lineWidth: 2
                        )
                )
        )
    }

    private func toggleExercise(_ exercise: DailyExercise) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            if completedExercises.contains(exercise.id) {
                completedExercises.remove(exercise.id)
                totalXPEarned -= exercise.xpReward
            } else {
                completedExercises.insert(exercise.id)
                totalXPEarned += exercise.xpReward
                HapticManager.success()

                // Award XP via ProgressionManager
                ProgressionManager.shared.addCustomXP(exercise.xpReward, description: exercise.title)

                // Check if all exercises completed and checkpoint exists
                if allExercisesCompleted, let checkpoint = dailyProgram.checkpoint {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        totalXPEarned += checkpoint.bonusXP
                        ProgressionManager.shared.addCustomXP(checkpoint.bonusXP, description: checkpoint.title)
                        showCheckpointCelebration = true
                    }
                }
            }
        }
    }
}

// MARK: - Exercise Card Component

struct ExerciseCard: View {
    let exercise: DailyExercise
    let isCompleted: Bool
    let onToggle: () -> Void

    @State private var showDetail = false

    var body: some View {
        Button(action: {
            HapticManager.light()
            onToggle()
        }) {
            HStack(spacing: 16) {
                // Completion checkbox
                ZStack {
                    Circle()
                        .fill(isCompleted ? Color.appTheme : Color.white.opacity(0.1))
                        .frame(width: 32, height: 32)

                    if isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 2)
                            .frame(width: 32, height: 32)
                    }
                }

                // Exercise icon
                Image(systemName: exercise.type.icon)
                    .font(.system(size: 22))
                    .foregroundColor(Color.appTheme)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(Color.appTheme.opacity(0.15))
                    )

                // Exercise info
                VStack(alignment: .leading, spacing: 6) {
                    Text(exercise.title)
                        .font(.custom("Poppins-SemiBold", size: 16))
                        .foregroundColor(.white)
                        .strikethrough(isCompleted, color: .white.opacity(0.5))

                    Text(exercise.description)
                        .font(.custom("Poppins-Regular", size: 13))
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(2)

                    HStack(spacing: 12) {
                        // Duration
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.system(size: 10))
                            Text("\(exercise.durationMinutes) min")
                                .font(.custom("Poppins-Regular", size: 12))
                        }
                        .foregroundColor(Color.appTheme.opacity(0.8))

                        // XP reward
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                            Text("+\(exercise.xpReward) XP")
                                .font(.custom("Poppins-Regular", size: 12))
                        }
                        .foregroundColor(Color(hex: "FFD700").opacity(0.8))

                        if exercise.isOptional {
                            Text("Optionnel")
                                .font(.custom("Poppins-Regular", size: 11))
                                .foregroundColor(.white.opacity(0.6))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(Color.white.opacity(0.1))
                                )
                        }
                    }
                }

                Spacer()

                // Detail arrow
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.4))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        isCompleted ?
                            Color.appTheme.opacity(0.15) :
                            Color.white.opacity(0.05)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isCompleted ?
                                    Color.appTheme.opacity(0.4) :
                                    Color.white.opacity(0.1),
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Stat Badge Component

struct StatBadge: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(color)

                Text(value)
                    .font(.custom("Poppins-Bold", size: 18))
                    .foregroundColor(.white)
            }

            Text(label)
                .font(.custom("Poppins-Regular", size: 12))
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Checkpoint Celebration View

struct CheckpointCelebrationView: View {
    let checkpoint: RoutineCheckpoint
    @Environment(\.dismiss) private var dismiss
    @State private var animateIn = false

    var body: some View {
        ZStack {
            // Background
            Color.black.opacity(0.9)
                .ignoresSafeArea()

            VStack(spacing: 32) {
                // Animated badge
                Image(systemName: checkpoint.badgeIcon)
                    .font(.system(size: 100))
                    .foregroundColor(Color(hex: checkpoint.badgeColor))
                    .scaleEffect(animateIn ? 1.0 : 0.5)
                    .opacity(animateIn ? 1.0 : 0.0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.6), value: animateIn)

                VStack(spacing: 16) {
                    Text(checkpoint.title)
                        .font(.custom("Poppins-Bold", size: 28))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .opacity(animateIn ? 1.0 : 0.0)
                        .offset(y: animateIn ? 0 : 20)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2), value: animateIn)

                    Text(checkpoint.description)
                        .font(.custom("Poppins-Regular", size: 16))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .opacity(animateIn ? 1.0 : 0.0)
                        .offset(y: animateIn ? 0 : 20)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.3), value: animateIn)
                }

                // Bonus XP
                VStack(spacing: 8) {
                    Text("BONUS")
                        .font(.custom("Poppins-Bold", size: 14))
                        .foregroundColor(Color(hex: "FFD700"))

                    HStack(spacing: 8) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 24))
                        Text("+\(checkpoint.bonusXP) XP")
                            .font(.custom("Poppins-Bold", size: 32))
                    }
                    .foregroundColor(Color(hex: "FFD700"))
                }
                .padding(.vertical, 24)
                .padding(.horizontal, 40)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(hex: "FFD700").opacity(0.15))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color(hex: "FFD700").opacity(0.5), lineWidth: 2)
                        )
                )
                .opacity(animateIn ? 1.0 : 0.0)
                .scaleEffect(animateIn ? 1.0 : 0.8)
                .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.4), value: animateIn)

                // Continue button
                Button(action: {
                    HapticManager.success()
                    dismiss()
                }) {
                    Text("Continuer")
                        .font(.custom("Poppins-SemiBold", size: 18))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color(hex: checkpoint.badgeColor),
                                    Color(hex: checkpoint.badgeColor).opacity(0.7)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                }
                .padding(.horizontal, 40)
                .opacity(animateIn ? 1.0 : 0.0)
                .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.5), value: animateIn)
            }
        }
        .onAppear {
            HapticManager.success()
            animateIn = true
        }
    }
}

#Preview {
    @Previewable @State var totalXP = 0

    let sampleDay = DailyProgram(
        day: 1,
        title: "Bienvenue dans ton programme",
        theme: "Découverte",
        timeOfDay: .morning,
        exercises: [
            DailyExercise(
                type: .breathing,
                title: "4-7-8 (5 min)",
                description: "Première respiration apaisante",
                durationMinutes: 5,
                exerciseId: "478",
                xpReward: 25
            ),
            DailyExercise(
                type: .meditation,
                title: "Méditation guidée : Ancrage",
                description: "Se connecter au moment présent",
                durationMinutes: 10,
                exerciseId: "grounding",
                xpReward: 25
            ),
            DailyExercise(
                type: .journal,
                title: "Journal de réflexion",
                description: "Quelles situations déclenchent ton anxiété en ce moment ?",
                durationMinutes: 10,
                xpReward: 25
            )
        ],
        checkpoint: RoutineCheckpoint(
            day: 1,
            title: "Premier pas vers la sérénité",
            description: "Tu as commencé ton voyage !",
            badgeIcon: "flag.fill",
            badgeColor: "4A90E2",
            bonusXP: 50
        ),
        guidance: "Aujourd'hui, tu commences un voyage vers une vie plus apaisée. Chaque exercice compte, même s'il te semble simple."
    )

    return DailyProgramView(dailyProgram: sampleDay, totalXPEarned: $totalXP)
}
