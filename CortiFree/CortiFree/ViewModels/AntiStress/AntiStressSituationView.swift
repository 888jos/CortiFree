//
//  AntiStressSituationView.swift
//  CortiFree
//
//  Created by Claude on 22/10/2025.
//  Step 1: Situation Selection
//

import SwiftUI

struct AntiStressSituationView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = AntiStressViewModel()
    @State private var selectedSituation: StressSituation?
    @State private var showRecommendations = false

    var body: some View {
        NavigationStack {
            ZStack {
                GalaxyBackgroundView(intensity: 1.0, isAnimated: false)

                GeometryReader { geometry in
                    let horizontalPadding: CGFloat = 24
                    let columnSpacing: CGFloat = 16
                    let rowSpacing: CGFloat = 12
                    let headerHeight: CGFloat = 84
                    let verticalSpacing: CGFloat = 20
                    let availableWidth = geometry.size.width - (horizontalPadding * 2) - columnSpacing
                    let availableHeight = geometry.size.height - headerHeight - verticalSpacing - (rowSpacing * 2) - 28
                    let cardSize = max(88, min(availableWidth / 2, availableHeight / 3))

                    VStack(spacing: verticalSpacing) {
                        // Header
                        VStack(spacing: 12) {
                            Text(NSLocalizedString("antistress.situation.title", comment: ""))
                                .font(.faroSemiBold(24))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.white, Color(hex: "B794F6")],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .multilineTextAlignment(.center)

                            Text(NSLocalizedString("antistress.situation.subtitle", comment: ""))
                                .font(.custom("Poppins-Regular", size: 14))
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                        }
                        .padding(.horizontal, 32)
                        .frame(height: headerHeight)

                        // Situation Grid (2x3)
                        let situations = StressSituation.allCases
                        VStack(spacing: rowSpacing) {
                            ForEach(0..<(situations.count + 1) / 2, id: \.self) { row in
                                HStack(spacing: columnSpacing) {
                                    ForEach(0..<2) { col in
                                        let index = row * 2 + col
                                        if index < situations.count {
                                            let situation = situations[index]
                                            SituationCard(
                                                situation: situation,
                                                isSelected: selectedSituation == situation,
                                                onTap: {
                                                    HapticManager.light()
                                                    selectedSituation = situation
                                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                                        viewModel.selectSituation(situation)
                                                        showRecommendations = true
                                                    }
                                                }
                                            )
                                            .frame(width: cardSize, height: cardSize)
                                        } else {
                                            Color.clear
                                                .frame(width: cardSize, height: cardSize)
                                        }
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .padding(.top, 8)
                }
            }
            .navigationDestination(isPresented: $showRecommendations) {
                if let situation = selectedSituation {
                    ExerciseRecommendationView(
                        situation: situation,
                        viewModel: viewModel
                    )
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        HapticManager.light()
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.custom("Poppins-SemiBold", size: 18))
                            .foregroundColor(.white)
                    }
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

// MARK: - Situation Card

struct SituationCard: View {
    let situation: StressSituation
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Background image
                if let imageName = situation.customImageName {
                    Image(imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity)
                        .aspectRatio(1.0, contentMode: .fit)
                        .clipped()
                }

                // Dark overlay for readability
                Rectangle()
                    .fill(Color.black.opacity(isSelected ? 0.3 : 0.5))

                // Label en haut avec étoile
                VStack {
                    HStack(spacing: 6) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.white)

                        Text(situation.displayName)
                            .font(.custom("Poppins-SemiBold", size: 13))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 2)

                        Spacer()
                    }
                    .padding(.top, 12)
                    .padding(.leading, 12)

                    Spacer()
                }
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(1.0, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected ? Color.white : Color.white.opacity(0.3),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .shadow(
                color: isSelected ?
                    Color.white.opacity(0.3) :
                    Color.black.opacity(0.2),
                radius: isSelected ? 8 : 4,
                x: 0,
                y: isSelected ? 4 : 2
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    AntiStressSituationView()
}
