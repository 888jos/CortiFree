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

    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                // Galaxy background
                GalaxyBackgroundView(intensity: 1.0)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        // Header
                        VStack(spacing: 12) {
                            Text("Dans quelle situation es-tu ?")
                                .font(.custom("Poppins-SemiBold", size: 24))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)

                            Text("Choisis celle qui te correspond le mieux.")
                                .font(.custom("Poppins-Regular", size: 16))
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 20)
                        .padding(.horizontal, 24)

                        // Situation Grid (2x3)
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(StressSituation.allCases, id: \.self) { situation in
                                SituationCard(
                                    situation: situation,
                                    isSelected: selectedSituation == situation,
                                    onTap: {
                                        HapticManager.light()
                                        withAnimation(.spring(response: 0.3)) {
                                            selectedSituation = situation
                                        }

                                        // Auto-advance after selection
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                            viewModel.selectSituation(situation)
                                            showRecommendations = true
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 24)

                        Spacer(minLength: 40)
                    }
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
            GeometryReader { geometry in
                ZStack(alignment: .topLeading) {
                    // Label en haut
                    Text(situation.displayName)
                        .font(.custom("Poppins-Medium", size: 15))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 12)
                        .padding(.horizontal, 12)

                    // Icon ou Image personnalisée en bas à droite
                    if let imageName = situation.customImageName {
                        Image(imageName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 140, height: 140)
                            .foregroundColor(isSelected ? Color.appTheme : .white)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                            .padding(.trailing, -20)
                            .padding(.bottom, -20)
                    } else {
                        Image(systemName: situation.icon)
                            .font(.system(size: 80))
                            .foregroundColor(isSelected ? Color.appTheme : .white)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                            .padding(.trailing, 8)
                            .padding(.bottom, 8)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(1.0, contentMode: .fit)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(hex: "131146").opacity(0.8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected ?
                                    LinearGradient(
                                        colors: [
                                            Color.appTheme,
                                            Color.appThemeSecondary
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ) :
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
                    .shadow(
                        color: isSelected ?
                            Color.appTheme.opacity(0.3) :
                            Color.black.opacity(0.2),
                        radius: isSelected ? 8 : 4,
                        x: 0,
                        y: isSelected ? 4 : 2
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3), value: isSelected)
    }
}

#Preview {
    AntiStressSituationView()
}
