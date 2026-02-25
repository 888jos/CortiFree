//
//  ExerciseRouterView.swift
//  CortiFree
//
//  Created by Claude on 22/10/2025.
//  Routes to appropriate exercise view
//

import SwiftUI

struct ExerciseRouterView: View {
    let exerciseType: AntiStressExerciseType
    let situation: StressSituation
    @ObservedObject var viewModel: AntiStressViewModel

    var body: some View {
        Group {
            switch exerciseType {
            case .guidedBreathing, .cardiacCoherence, .boxBreathing,
                 .alternateBreathing, .consciousBreathing:
                // Show detail page first for breathing exercises
                AntiStressBreathingDetailView(
                    exerciseType: exerciseType,
                    situation: situation,
                    viewModel: viewModel
                )

            case .grounding5Senses:
                // Show detail page first for grounding exercise
                AntiStressGroundingDetailView(
                    exerciseType: exerciseType,
                    situation: situation,
                    viewModel: viewModel
                )

            case .anchoring54321:
                // Show detail page first for anchoring exercise
                AntiStressAnchoring54321DetailView(
                    exerciseType: exerciseType,
                    situation: situation,
                    viewModel: viewModel
                )

            case .bodyScan:
                // Show detail page first for body scan exercise
                AntiStressBodyScanDetailView(
                    exerciseType: exerciseType,
                    situation: situation,
                    viewModel: viewModel
                )

            case .meditation2Min:
                // Show detail page first for meditation
                AntiStressMeditationDetailView(
                    situation: situation,
                    viewModel: viewModel
                )

            case .slowWalk, .consciousStretching, .audioRelaxation,
                 .whiteNoise, .positiveMantra, .visualMicroBreak:
                // Show detail page for generic exercises
                AntiStressGenericDetailView(
                    exerciseType: exerciseType,
                    situation: situation,
                    viewModel: viewModel
                )

            default:
                // Generic exercise view for exercises not yet implemented
                GenericExerciseView(
                    exerciseType: exerciseType,
                    situation: situation,
                    viewModel: viewModel
                )
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}
