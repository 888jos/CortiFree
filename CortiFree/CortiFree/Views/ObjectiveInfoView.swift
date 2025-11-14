//
//  ObjectiveInfoView.swift
//  CortiFree
//
//  Vue d'informations sur l'objectif de l'utilisateur
//

import SwiftUI

struct ObjectiveInfoView: View {
    let routineTitle: String
    let startDate: Date
    let planet: Planet

    @Environment(\.dismiss) private var dismiss
    @StateObject private var progressionManager = ProgressionManager.shared
    @State private var planetScale: CGFloat = 1.0

    private var daysPassed: Int {
        Calendar.current.dateComponents([.day], from: startDate, to: Date()).day ?? 0
    }

    private var daysRemaining: Int {
        max(0, 66 - daysPassed)
    }

    private var progressPercentage: Double {
        Double(daysPassed) / 66.0
    }

    private var objectiveDescription: String {
        switch routineTitle.lowercased() {
        case let title where title.contains("anxiété"):
            return "Retrouver ton calme intérieur"
        case let title where title.contains("sommeil"):
            return "Dormir paisiblement"
        case let title where title.contains("concentration"):
            return "Être pleinement concentré"
        case let title where title.contains("fatigue"):
            return "Retrouver ton énergie"
        case let title where title.contains("tension"):
            return "Apaiser ton corps"
        case let title where title.contains("contrôle"):
            return "Reprendre le contrôle"
        case let title where title.contains("énergie"):
            return "Être plein d'énergie"
        case let title where title.contains("émotions"):
            return "Maîtriser tes émotions"
        default:
            return "Atteindre ton objectif"
        }
    }

    private var scientificFacts: [String] {
        switch routineTitle.lowercased() {
        case let title where title.contains("anxiété"):
            return [
                "La respiration contrôlée réduit l'anxiété de 60% en 66 jours",
                "La méditation régulière diminue le cortisol de 30%",
                "Les exercices anti-stress activent le système parasympathique"
            ]
        case let title where title.contains("sommeil"):
            return [
                "Une routine de relaxation améliore la qualité du sommeil de 75%",
                "La méditation augmente la production de mélatonine",
                "Les exercices de respiration favorisent l'endormissement"
            ]
        case let title where title.contains("concentration"):
            return [
                "La méditation améliore la concentration de 50% en 66 jours",
                "Les exercices de respiration augmentent l'oxygénation du cerveau",
                "Une pratique régulière renforce les connexions neuronales"
            ]
        default:
            return [
                "66 jours suffisent pour créer de nouvelles habitudes durables",
                "La pratique quotidienne augmente l'efficacité de 70%",
                "Les résultats sont visibles dès les 3 premières semaines"
            ]
        }
    }

    var body: some View {
        ZStack {
            // Background
            GalaxyBackgroundView(intensity: 1.0)

            VStack(spacing: 0) {
                // Header avec bouton fermer
                HStack {
                    Spacer()

                    Button(action: {
                        HapticManager.light()
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                            .frame(width: 36, height: 36)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        // Planète avec halo
                        ZStack {
                            // Halo
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [
                                            planet.haloColor.opacity(0.4),
                                            Color.clear
                                        ],
                                        center: .center,
                                        startRadius: 80,
                                        endRadius: 120
                                    )
                                )
                                .frame(width: 180, height: 180)
                                .scaleEffect(planetScale)

                            // Planète
                            Image(planet.imageName)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 200, height: 200)
                                .shadow(color: planet.haloColor.opacity(0.5), radius: 20)
                                .scaleEffect(planetScale)
                        }
                        .onAppear {
                            withAnimation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true)) {
                                planetScale = 1.05
                            }
                        }
                        .padding(.top, 20)

                        // Titre et description
                        VStack(spacing: 12) {
                            Text(routineTitle)
                                .font(.custom("SF Pro Rounded-Bold", size: 28))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)

                            Text(objectiveDescription)
                                .font(.custom("SF Pro Rounded-Regular", size: 16))
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 32)

                        // Statistiques de progression
                        VStack(spacing: 20) {
                            // Barre de progression
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Progression")
                                        .font(.custom("SF Pro Rounded-Bold", size: 16))
                                        .foregroundColor(.white)

                                    Spacer()

                                    Text("\(Int(progressPercentage * 100))%")
                                        .font(.custom("SF Pro Rounded-Bold", size: 16))
                                        .foregroundColor(planet.haloColor)
                                }

                                GeometryReader { geometry in
                                    ZStack(alignment: .leading) {
                                        // Background
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.white.opacity(0.1))
                                            .frame(height: 12)

                                        // Progress
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(
                                                LinearGradient(
                                                    colors: [planet.haloColor, planet.haloColor.opacity(0.7)],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                            .frame(width: geometry.size.width * progressPercentage, height: 12)
                                    }
                                }
                                .frame(height: 12)
                            }

                            // Stats cards
                            HStack(spacing: 16) {
                                ObjectiveStatCard(
                                    value: "\(daysPassed)",
                                    label: daysPassed > 1 ? "jours passés" : "jour passé",
                                    color: planet.haloColor
                                )

                                ObjectiveStatCard(
                                    value: "\(daysRemaining)",
                                    label: daysRemaining > 1 ? "jours restants" : "jour restant",
                                    color: planet.haloColor
                                )
                            }

                            HStack(spacing: 16) {
                                ObjectiveStatCard(
                                    value: "\(progressionManager.currentLevel.id)",
                                    label: "Niveau actuel",
                                    color: planet.haloColor
                                )

                                ObjectiveStatCard(
                                    value: "\(progressionManager.streakDays)",
                                    label: progressionManager.streakDays > 1 ? "jours de série" : "jour de série",
                                    color: planet.haloColor
                                )
                            }
                        }
                        .padding(.horizontal, 24)

                        // Faits scientifiques
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Pourquoi 66 jours ?")
                                .font(.custom("SF Pro Rounded-Bold", size: 20))
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)

                            ForEach(scientificFacts, id: \.self) { fact in
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(planet.haloColor)
                                        .padding(.top, 2)

                                    Text(fact)
                                        .font(.custom("SF Pro Rounded-Regular", size: 14))
                                        .foregroundColor(.white.opacity(0.8))
                                        .fixedSize(horizontal: false, vertical: true)

                                    Spacer()
                                }
                                .padding(.horizontal, 24)
                            }
                        }

                        // Message motivant
                        VStack(spacing: 12) {
                            Text("Continue comme ça !")
                                .font(.custom("SF Pro Rounded-Bold", size: 18))
                                .foregroundColor(.white)

                            Text("Chaque jour compte. Reste régulier et les résultats viendront naturellement.")
                                .font(.custom("SF Pro Rounded-Regular", size: 14))
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                        .padding(.vertical, 24)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(planet.haloColor.opacity(0.1))
                        )
                        .padding(.horizontal, 24)

                    }
                    .padding(.bottom, 40)
                }
            }
        }
    }
}

// MARK: - Objective Stat Card Component

struct ObjectiveStatCard: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.custom("SF Pro Rounded-Bold", size: 32))
                .foregroundColor(.white)

            Text(label)
                .font(.custom("SF Pro Rounded-Regular", size: 12))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

#Preview {
    ObjectiveInfoView(
        routineTitle: "Réduire l'anxiété",
        startDate: Calendar.current.date(byAdding: .day, value: -20, to: Date()) ?? Date(),
        planet: Planet.earth
    )
}
