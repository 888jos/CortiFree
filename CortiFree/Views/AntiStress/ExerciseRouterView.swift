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
                BreathingExerciseView(
                    exerciseType: exerciseType,
                    situation: situation,
                    viewModel: viewModel
                )

            case .grounding5Senses:
                GroundingExerciseView(
                    situation: situation,
                    viewModel: viewModel
                )

            case .anchoring54321:
                Anchoring54321View(
                    situation: situation,
                    viewModel: viewModel
                )

            case .bodyScan:
                BodyScanExerciseView(
                    situation: situation,
                    viewModel: viewModel
                )

            case .meditation2Min:
                MeditationExerciseView(
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
