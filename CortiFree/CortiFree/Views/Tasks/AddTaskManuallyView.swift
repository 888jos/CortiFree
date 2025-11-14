//
//  AddTaskManuallyView.swift
//  CortiFree
//
//  Created by Claude on 14/11/2025.
//  Vue pour ajouter manuellement une tâche d'habitude
//

import SwiftUI

struct AddTaskManuallyView: View {
    let onDismiss: () -> Void
    @State private var taskTitle: String = ""
    @State private var frequency: String = "1x/jour"
    @State private var difficulty: Int = 2

    private let frequencyOptions = ["Tous les jours", "1x/jour", "2x/jour", "3x/semaine", "2x/semaine", "1x/semaine"]

    var body: some View {
        ZStack {
            // Galaxy background
            GalaxyBackgroundView(intensity: 1.0)

            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        HapticManager.light()
                        onDismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                    }

                    Spacer()

                    Text("Nouvelle tâche")
                        .font(.custom("HankenGrotesk-Bold", size: 20))
                        .foregroundColor(.white)

                    Spacer()

                    // Spacer for alignment
                    Color.clear.frame(width: 44, height: 44)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 24)

                ScrollView {
                    VStack(spacing: 24) {
                        // Title input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Titre de la tâche")
                                .font(.custom("Poppins-SemiBold", size: 14))
                                .foregroundColor(.white)

                            TextField("Ex: Faire du yoga", text: $taskTitle)
                                .font(.custom("Poppins-Regular", size: 16))
                                .foregroundColor(.white)
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white.opacity(0.1))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                        )
                                )
                        }
                        .padding(.horizontal, 24)

                        // Frequency picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Fréquence")
                                .font(.custom("Poppins-SemiBold", size: 14))
                                .foregroundColor(.white)

                            Menu {
                                ForEach(frequencyOptions, id: \.self) { option in
                                    Button(option) {
                                        frequency = option
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(frequency)
                                        .font(.custom("Poppins-Regular", size: 16))
                                        .foregroundColor(.white)

                                    Spacer()

                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.6))
                                }
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white.opacity(0.1))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                        )
                                )
                            }
                        }
                        .padding(.horizontal, 24)

                        // Difficulty selector
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Difficulté")
                                .font(.custom("Poppins-SemiBold", size: 14))
                                .foregroundColor(.white)

                            HStack(spacing: 12) {
                                ForEach(1...3, id: \.self) { level in
                                    Button(action: {
                                        HapticManager.light()
                                        difficulty = level
                                    }) {
                                        HStack(spacing: 8) {
                                            // Difficulty bars
                                            HStack(alignment: .bottom, spacing: 2) {
                                                // Bar 1: 3x6
                                                RoundedRectangle(cornerRadius: 20)
                                                    .fill(level >= 1 ? Color(hex: "B794F6") : Color.white.opacity(0.3))
                                                    .frame(width: 3, height: 6)

                                                // Bar 2: 3x9
                                                RoundedRectangle(cornerRadius: 20)
                                                    .fill(level >= 2 ? Color(hex: "B794F6") : Color.white.opacity(0.3))
                                                    .frame(width: 3, height: 9)

                                                // Bar 3: 3x12
                                                RoundedRectangle(cornerRadius: 20)
                                                    .fill(level >= 3 ? Color(hex: "B794F6") : Color.white.opacity(0.3))
                                                    .frame(width: 3, height: 12)
                                            }

                                            Text(level == 1 ? "Facile" : level == 2 ? "Moyen" : "Difficile")
                                                .font(.custom("Poppins-Regular", size: 14))
                                                .foregroundColor(.white)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(difficulty == level ? Color(hex: "B794F6").opacity(0.2) : Color.white.opacity(0.05))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .stroke(difficulty == level ? Color(hex: "B794F6") : Color.white.opacity(0.2), lineWidth: 1)
                                                )
                                        )
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 24)

                        Spacer(minLength: 100)
                    }
                }

                // Bottom button
                Button(action: {
                    HapticManager.success()
                    // TODO: Save task
                    onDismiss()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 18, weight: .semibold))

                        Text("Ajouter la tâche")
                            .font(.custom("Poppins-SemiBold", size: 18))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 28)
                            .fill(Color(hex: "B794F6"))
                    )
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
                .opacity(taskTitle.isEmpty ? 0.5 : 1.0)
                .disabled(taskTitle.isEmpty)
            }
        }
    }
}

#Preview {
    AddTaskManuallyView(onDismiss: {})
}
