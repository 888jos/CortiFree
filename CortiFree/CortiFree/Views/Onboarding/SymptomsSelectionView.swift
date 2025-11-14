//
//  SymptomsSelectionView.swift
//  CortiFree
//
//  Created by Claude on 31/10/2025.
//  Symptoms selection screen (multiple choice)
//

import SwiftUI

struct SymptomsSelectionView: View {
    @State private var selectedSymptoms: Set<Int> = []
    let onContinue: (Set<Int>) -> Void

    // Symptômes organisés par catégories
    private let mentalSymptoms = [
        "Difficulté à se concentrer",
        "Ruminations mentales",
        "Anxiété globale ou anticipatoire",
        "Pensées en boucle difficiles à arrêter"
    ]

    private let physicalSymptoms = [
        "Tensions musculaires (nuque, mâchoire, trapèzes)",
        "Sommeil interrompu ou non réparateur",
        "Fatigue chronique dès le réveil",
        "Respiration courte ou superficielle"
    ]

    private let socialSymptoms = [
        "Agacement ou irritabilité fréquente",
        "Cravings alimentaires ou sauts de repas",
        "Évitement social ou isolement",
        "Difficulté à gérer les imprévus"
    ]

    // Index global mapping
    private var allSymptoms: [(category: String, text: String, index: Int)] {
        var result: [(String, String, Int)] = []
        var globalIndex = 0

        for symptom in mentalSymptoms {
            result.append(("Mentaux", symptom, globalIndex))
            globalIndex += 1
        }
        for symptom in physicalSymptoms {
            result.append(("Physiques", symptom, globalIndex))
            globalIndex += 1
        }
        for symptom in socialSymptoms {
            result.append(("Sociaux", symptom, globalIndex))
            globalIndex += 1
        }

        return result
    }

    var body: some View {
        ZStack {
            // Galaxy background
            GalaxyBackgroundView()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Title at top
                Text("Symptômes")
                    .font(.custom("Poppins-SemiBold", size: 16))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 16)
                    .padding(.bottom, 12)

                // Scrollable content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Simple instruction text
                        Text("Sélectionnez les symptômes ci-dessous que vous avez déjà ressenti")
                            .font(.custom("Poppins-Bold", size: 20))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 34)
                            .padding(.top, 8)
                            .padding(.bottom, 20)

                        VStack(spacing: 24) {
                            // Symptômes Mentaux
                            symptomCategorySection(title: "Symptômes Mentaux", symptoms: mentalSymptoms, startIndex: 0)

                            // Symptômes Physiques
                            symptomCategorySection(title: "Symptômes Physiques", symptoms: physicalSymptoms, startIndex: mentalSymptoms.count)

                            // Symptômes Sociaux
                            symptomCategorySection(title: "Symptômes Sociaux", symptoms: socialSymptoms, startIndex: mentalSymptoms.count + physicalSymptoms.count)
                        }
                        .padding(.top, 10)

                        Spacer(minLength: 100)
                    }
                }

                Spacer()

                // Fixed CTA Button at bottom (always visible)
                Button(action: {
                    HapticManager.light()
                    onContinue(selectedSymptoms)
                }) {
                    Text("Retrouver ma sérénité")
                        .font(.custom("Poppins-SemiBold", size: 16))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color(hex: "53D7D9"))
                        .clipShape(RoundedRectangle(cornerRadius: 40))
                }
                .padding(.horizontal, 34)
                .padding(.bottom, 40)
                .disabled(selectedSymptoms.isEmpty)
                .opacity(selectedSymptoms.isEmpty ? 0.5 : 1.0)
            }
        }
        .animation(.easeInOut, value: selectedSymptoms)
    }

    // MARK: - Category Section

    @ViewBuilder
    private func symptomCategorySection(title: String, symptoms: [String], startIndex: Int) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.custom("Poppins-SemiBold", size: 16))
                .foregroundColor(.white)
                .padding(.horizontal, 34)

            VStack(spacing: 12) {
                ForEach(0..<symptoms.count, id: \.self) { localIndex in
                    let globalIndex = startIndex + localIndex
                    SymptomButton(
                        text: symptoms[localIndex],
                        isSelected: selectedSymptoms.contains(globalIndex),
                        onTap: {
                            HapticManager.light()
                            if selectedSymptoms.contains(globalIndex) {
                                selectedSymptoms.remove(globalIndex)
                            } else {
                                selectedSymptoms.insert(globalIndex)
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, 34)
        }
    }
}

// MARK: - Symptom Button

struct SymptomButton: View {
    let text: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Toggle checkbox à gauche
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Circle()
                            .fill(Color(hex: "53D7D9"))
                            .frame(width: 24, height: 24)

                        Image(systemName: "checkmark")
                            .font(.custom("Poppins-Bold", size: 12))
                            .foregroundColor(.white)
                    }
                }

                // Texte aligné à gauche avec hauteur fixe
                Text(text)
                    .font(.custom("Poppins-Medium", size: 12))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(minHeight: 40, alignment: .leading)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .frame(height: 60)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(hex: "53D7D9").opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(
                                isSelected ? Color(hex: "53D7D9") : Color.clear,
                                lineWidth: 2
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    SymptomsSelectionView(onContinue: { _ in })
}
