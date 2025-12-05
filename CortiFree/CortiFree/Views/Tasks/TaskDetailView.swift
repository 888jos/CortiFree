//
//  TaskDetailView.swift
//  CortiFree
//
//  Created by Claude on 22/10/2025.
//  Detail view for a task showing full information
//

import SwiftUI

struct TaskDetailView: View {
    let task: TaskItem
    @Environment(\.dismiss) var dismiss
    @State private var showExercise = false
    @State private var showJournal = false
    @State private var showBreathingList = false
    @State private var showMeditationList = false
    @State private var showSoundsList = false

    var body: some View {
        ZStack {
            // Background gradient - covers entire screen
            LinearGradient(
                colors: [
                    Color(hex: "1F0140"),
                    Color(hex: "0B011B"),
                    Color(hex: "01000C")
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(.all)

            VStack(spacing: 0) {
                // Header with close button
                HStack {
                    Spacer()

                    Button(action: {
                        HapticManager.light()
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 60)
                .padding(.bottom, 16)

                // Main content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Title
                        Text(task.title)
                            .font(.custom("Poppins-SemiBold", size: 26))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                            .padding(.top, 8)

                        // Category (simple text under title)
                        if let category = task.customCategory {
                            Text(category.displayName)
                                .font(.custom("Poppins-Regular", size: 14))
                                .foregroundColor(.white.opacity(0.6))
                                .padding(.top, -16)
                        }

                        // Info cards
                        VStack(spacing: 12) {
                            // Time
                            if let time = task.recommendedTime {
                                InfoCard(
                                    icon: "clock.fill",
                                    label: "Heure recommandée",
                                    value: time,
                                    gradient: [Color.appThemeSecondary, Color.appTheme]
                                )
                            }

                            // Duration
                            if let duration = task.durationInMinutes {
                                InfoCard(
                                    icon: "hourglass",
                                    label: "Durée",
                                    value: "\(duration) min",
                                    gradient: [Color.appTheme, Color.appThemeSecondary]
                                )
                            }
                        }
                        .padding(.horizontal, 24)

                        // Description section
                        if let description = task.taskDescription {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "lightbulb.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(Color(hex: "F59E0B"))

                                    Text("Pourquoi cette tâche ?")
                                        .font(.custom("Poppins-SemiBold", size: 18))
                                        .foregroundColor(.white)
                                }

                                Text(description)
                                    .font(.custom("Poppins-Regular", size: 15))
                                    .foregroundColor(.white.opacity(0.85))
                                    .lineSpacing(6)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color(hex: "2A2B5A").opacity(0.6),
                                                Color(hex: "1F1F3F").opacity(0.4)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(
                                        LinearGradient(
                                            colors: [
                                                Color(hex: "F59E0B").opacity(0.3),
                                                Color(hex: "F59E0B").opacity(0.1)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            )
                            .padding(.horizontal, 24)
                        }

                        Spacer(minLength: 100)
                    }
                    .padding(.bottom, 120)
                }

                // Smart action button - Fixed at bottom
                if let smartAction = getSmartAction() {
                    VStack(spacing: 0) {
                        // Gradient fade effect at top
                        LinearGradient(
                            colors: [
                                Color(hex: "01000C").opacity(0),
                                Color(hex: "01000C")
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 20)

                        Button(action: {
                            HapticManager.light()
                            smartAction.action()
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: smartAction.icon)
                                    .font(.system(size: 18))
                                    .foregroundColor(.white)

                                Text(smartAction.title)
                                    .font(.custom("Poppins-SemiBold", size: 16))
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                LinearGradient(
                                    colors: [
                                        Color.appTheme,
                                        Color.appThemeSecondary
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 40)
                        .background(Color(hex: "01000C"))
                    }
                }
            }
        }
        .sheet(isPresented: $showBreathingList) {
            BreathingListView()
        }
        .sheet(isPresented: $showMeditationList) {
            MeditationListView()
        }
        .sheet(isPresented: $showSoundsList) {
            SoundsListView()
        }
        .sheet(isPresented: $showJournal) {
            JournalHomeView()
        }
    }

    // MARK: - Smart Action Logic

    private func getSmartAction() -> (title: String, icon: String, action: () -> Void)? {
        let titleLowercase = task.title.lowercased()

        // Breathing exercises detection
        if task.customCategory == .breathing ||
           titleLowercase.contains("respiration") ||
           titleLowercase.contains("4-7-8") ||
           titleLowercase.contains("box") ||
           titleLowercase.contains("cohérence") {
            return (
                title: "Commencer l'exercice",
                icon: "wind",
                action: { showBreathingList = true }
            )
        }

        // Meditation exercises detection
        if task.customCategory == .mental ||
           titleLowercase.contains("méditer") ||
           titleLowercase.contains("meditation") ||
           titleLowercase.contains("mindfulness") ||
           titleLowercase.contains("pleine conscience") {
            return (
                title: "Commencer la méditation",
                icon: "figure.mind.and.body",
                action: { showMeditationList = true }
            )
        }

        // Sound/Sensory exercises detection
        if task.customCategory == .sensory ||
           task.customCategory == .sleep ||
           titleLowercase.contains("son") ||
           titleLowercase.contains("musique") ||
           titleLowercase.contains("relaxation") ||
           titleLowercase.contains("sommeil") {
            return (
                title: "Écouter les sons",
                icon: "speaker.wave.2.fill",
                action: { showSoundsList = true }
            )
        }

        // Journal/Gratitude detection
        if titleLowercase.contains("journal") ||
           titleLowercase.contains("gratitude") ||
           titleLowercase.contains("écrire") ||
           titleLowercase.contains("noter") {
            return (
                title: "Ouvrir le journal",
                icon: "book.fill",
                action: { showJournal = true }
            )
        }

        // No smart action for this task type
        return nil
    }
}

// MARK: - Info Card Component

struct InfoCard: View {
    let icon: String
    let label: String
    let value: String
    let gradient: [Color]

    var body: some View {
        HStack(spacing: 16) {
            // Icon with gradient
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.custom("Poppins-Regular", size: 13))
                    .foregroundColor(.white.opacity(0.6))

                Text(value)
                    .font(.custom("Poppins-SemiBold", size: 16))
                    .foregroundColor(.white)
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: "2A2B5A").opacity(0.4))
        )
    }
}

// MARK: - Preview

#Preview {
    TaskDetailView(
        task: TaskItem(
            title: "Respiration 4-7-8",
            category: .morning,
            completed: false,
            taskFrequency: .once,
            customCategory: .breathing,
            durationInMinutes: 5,
            icon: "🌬️",
            recommendedTime: "07:00",
            taskDescription: "La technique de respiration 4-7-8 active le système nerveux parasympathique, réduisant instantanément les niveaux de cortisol. En inspirant 4 secondes, retenant 7 secondes et expirant 8 secondes, vous signalez à votre corps qu'il est en sécurité."
        )
    )
    .environment(\.locale, Locale(identifier: "en"))
}
