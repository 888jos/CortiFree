//
//  InstructionExerciseView.swift
//  CortiFree
//
//  Created by Claude on 22/11/2025.
//  Vue de session guidée avec slides pour les exercices d'instructions - WRAPPER pour UnifiedInstructionSlideView
//

import SwiftUI

struct InstructionExerciseView: View {
    let exerciseType: AntiStressExerciseType
    let situation: StressSituation
    @ObservedObject var viewModel: AntiStressViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        UnifiedInstructionSlideView(
            steps: exerciseType.instructionSteps.map { $0.toUnified() },
            exerciseTitle: exerciseType.displayName,
            onComplete: {
                Task {
                    await viewModel.completeExercise()
                }
            }
        )
        .onAppear {
            viewModel.startExercise(exerciseType)
        }
    }
}

// MARK: - Instruction Step Model

struct InstructionStep {
    let title: String
    let subtitle: String
    let icon: String
    let color: String
    let estimatedDuration: String?

    init(title: String, subtitle: String, icon: String, color: String, estimatedDuration: String? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.color = color
        self.estimatedDuration = estimatedDuration
    }

    // Conversion vers UnifiedInstructionStep
    func toUnified() -> UnifiedInstructionStep {
        return UnifiedInstructionStep(
            title: title,
            subtitle: subtitle,
            icon: icon,
            color: color,
            estimatedDuration: estimatedDuration
        )
    }
}

// MARK: - Extension pour les étapes par exercice

extension AntiStressExerciseType {
    var instructionSteps: [InstructionStep] {
        switch self {
        case .bodyScan:
            return [
                InstructionStep(
                    title: NSLocalizedString("exercise.body_scan.step_1.title", comment: "Body scan step 1 title"),
                    subtitle: NSLocalizedString("exercise.body_scan.step_1.subtitle", comment: "Body scan step 1 subtitle"),
                    icon: "figure.stand",
                    color: "B388FF",
                    estimatedDuration: NSLocalizedString("exercise.body_scan.step_1.duration", comment: "Body scan step 1 duration")
                ),
                InstructionStep(
                    title: NSLocalizedString("exercise.body_scan.step_2.title", comment: "Body scan step 2 title"),
                    subtitle: NSLocalizedString("exercise.body_scan.step_2.subtitle", comment: "Body scan step 2 subtitle"),
                    icon: "eye.slash.fill",
                    color: "9B7BF1",
                    estimatedDuration: NSLocalizedString("exercise.body_scan.step_2.duration", comment: "Body scan step 2 duration")
                ),
                InstructionStep(
                    title: NSLocalizedString("exercise.body_scan.step_3.title", comment: "Body scan step 3 title"),
                    subtitle: NSLocalizedString("exercise.body_scan.step_3.subtitle", comment: "Body scan step 3 subtitle"),
                    icon: "face.smiling.fill",
                    color: "8C6BE5",
                    estimatedDuration: NSLocalizedString("exercise.body_scan.step_3.duration", comment: "Body scan step 3 duration")
                ),
                InstructionStep(
                    title: NSLocalizedString("exercise.body_scan.step_4.title", comment: "Body scan step 4 title"),
                    subtitle: NSLocalizedString("exercise.body_scan.step_4.subtitle", comment: "Body scan step 4 subtitle"),
                    icon: "figure.arms.open",
                    color: "7D5CD9",
                    estimatedDuration: NSLocalizedString("exercise.body_scan.step_4.duration", comment: "Body scan step 4 duration")
                ),
                InstructionStep(
                    title: NSLocalizedString("exercise.body_scan.step_5.title", comment: "Body scan step 5 title"),
                    subtitle: NSLocalizedString("exercise.body_scan.step_5.subtitle", comment: "Body scan step 5 subtitle"),
                    icon: "lungs.fill",
                    color: "6E4DCD",
                    estimatedDuration: NSLocalizedString("exercise.body_scan.step_5.duration", comment: "Body scan step 5 duration")
                ),
                InstructionStep(
                    title: NSLocalizedString("exercise.body_scan.step_6.title", comment: "Body scan step 6 title"),
                    subtitle: NSLocalizedString("exercise.body_scan.step_6.subtitle", comment: "Body scan step 6 subtitle"),
                    icon: "figure.walk",
                    color: "5F3EC1",
                    estimatedDuration: NSLocalizedString("exercise.body_scan.step_6.duration", comment: "Body scan step 6 duration")
                ),
                InstructionStep(
                    title: NSLocalizedString("exercise.body_scan.step_7.title", comment: "Body scan step 7 title"),
                    subtitle: NSLocalizedString("exercise.body_scan.step_7.subtitle", comment: "Body scan step 7 subtitle"),
                    icon: "heart.fill",
                    color: "B388FF",
                    estimatedDuration: NSLocalizedString("exercise.body_scan.step_7.duration", comment: "Body scan step 7 duration")
                )
            ]

        case .anchoring54321:
            return [
                InstructionStep(
                    title: NSLocalizedString("exercise.anchoring.step_1.title", comment: "Anchoring step 1 title"),
                    subtitle: NSLocalizedString("exercise.anchoring.step_1.subtitle", comment: "Anchoring step 1 subtitle"),
                    icon: "eye.fill",
                    color: "73DE85",
                    estimatedDuration: NSLocalizedString("exercise.anchoring.step_1.duration", comment: "Anchoring step 1 duration")
                ),
                InstructionStep(
                    title: NSLocalizedString("exercise.anchoring.step_2.title", comment: "Anchoring step 2 title"),
                    subtitle: NSLocalizedString("exercise.anchoring.step_2.subtitle", comment: "Anchoring step 2 subtitle"),
                    icon: "hand.raised.fill",
                    color: "66BB6A",
                    estimatedDuration: NSLocalizedString("exercise.anchoring.step_2.duration", comment: "Anchoring step 2 duration")
                ),
                InstructionStep(
                    title: NSLocalizedString("exercise.anchoring.step_3.title", comment: "Anchoring step 3 title"),
                    subtitle: NSLocalizedString("exercise.anchoring.step_3.subtitle", comment: "Anchoring step 3 subtitle"),
                    icon: "ear.fill",
                    color: "00FF88",
                    estimatedDuration: NSLocalizedString("exercise.anchoring.step_3.duration", comment: "Anchoring step 3 duration")
                ),
                InstructionStep(
                    title: NSLocalizedString("exercise.anchoring.step_4.title", comment: "Anchoring step 4 title"),
                    subtitle: NSLocalizedString("exercise.anchoring.step_4.subtitle", comment: "Anchoring step 4 subtitle"),
                    icon: "nose.fill",
                    color: "9B7BF1",
                    estimatedDuration: NSLocalizedString("exercise.anchoring.step_4.duration", comment: "Anchoring step 4 duration")
                ),
                InstructionStep(
                    title: NSLocalizedString("exercise.anchoring.step_5.title", comment: "Anchoring step 5 title"),
                    subtitle: NSLocalizedString("exercise.anchoring.step_5.subtitle", comment: "Anchoring step 5 subtitle"),
                    icon: "mouth.fill",
                    color: "FF6B9D",
                    estimatedDuration: NSLocalizedString("exercise.anchoring.step_5.duration", comment: "Anchoring step 5 duration")
                ),
                InstructionStep(
                    title: NSLocalizedString("exercise.anchoring.step_6.title", comment: "Anchoring step 6 title"),
                    subtitle: NSLocalizedString("exercise.anchoring.step_6.subtitle", comment: "Anchoring step 6 subtitle"),
                    icon: "checkmark.circle.fill",
                    color: "73DE85",
                    estimatedDuration: NSLocalizedString("exercise.anchoring.step_6.duration", comment: "Anchoring step 6 duration")
                )
            ]

        case .meditation2Min:
            return [
                InstructionStep(
                    title: NSLocalizedString("exercise.meditation_2min.step_1.title", comment: "2-min meditation step 1 title"),
                    subtitle: NSLocalizedString("exercise.meditation_2min.step_1.subtitle", comment: "2-min meditation step 1 subtitle"),
                    icon: "figure.seated.side",
                    color: "B388FF",
                    estimatedDuration: NSLocalizedString("exercise.meditation_2min.step_1.duration", comment: "2-min meditation step 1 duration")
                ),
                InstructionStep(
                    title: NSLocalizedString("exercise.meditation_2min.step_2.title", comment: "2-min meditation step 2 title"),
                    subtitle: NSLocalizedString("exercise.meditation_2min.step_2.subtitle", comment: "2-min meditation step 2 subtitle"),
                    icon: "eye.slash.fill",
                    color: "9B7BF1",
                    estimatedDuration: NSLocalizedString("exercise.meditation_2min.step_2.duration", comment: "2-min meditation step 2 duration")
                ),
                InstructionStep(
                    title: NSLocalizedString("exercise.meditation_2min.step_3.title", comment: "2-min meditation step 3 title"),
                    subtitle: NSLocalizedString("exercise.meditation_2min.step_3.subtitle", comment: "2-min meditation step 3 subtitle"),
                    icon: "wind",
                    color: "8C6BE5",
                    estimatedDuration: NSLocalizedString("exercise.meditation_2min.step_3.duration", comment: "2-min meditation step 3 duration")
                ),
                InstructionStep(
                    title: NSLocalizedString("exercise.meditation_2min.step_4.title", comment: "2-min meditation step 4 title"),
                    subtitle: NSLocalizedString("exercise.meditation_2min.step_4.subtitle", comment: "2-min meditation step 4 subtitle"),
                    icon: "cloud.fill",
                    color: "7D5CD9",
                    estimatedDuration: NSLocalizedString("exercise.meditation_2min.step_4.duration", comment: "2-min meditation step 4 duration")
                ),
                InstructionStep(
                    title: NSLocalizedString("exercise.meditation_2min.step_5.title", comment: "2-min meditation step 5 title"),
                    subtitle: NSLocalizedString("exercise.meditation_2min.step_5.subtitle", comment: "2-min meditation step 5 subtitle"),
                    icon: "arrow.uturn.backward",
                    color: "6E4DCD",
                    estimatedDuration: NSLocalizedString("exercise.meditation_2min.step_5.duration", comment: "2-min meditation step 5 duration")
                ),
                InstructionStep(
                    title: NSLocalizedString("exercise.meditation_2min.step_6.title", comment: "2-min meditation step 6 title"),
                    subtitle: NSLocalizedString("exercise.meditation_2min.step_6.subtitle", comment: "2-min meditation step 6 subtitle"),
                    icon: "lungs.fill",
                    color: "B388FF",
                    estimatedDuration: NSLocalizedString("exercise.meditation_2min.step_6.duration", comment: "2-min meditation step 6 duration")
                )
            ]

        case .grounding5Senses:
            return [
                InstructionStep(
                    title: NSLocalizedString("exercise.grounding.step_1.title", comment: "Grounding step 1 title"),
                    subtitle: NSLocalizedString("exercise.grounding.step_1.subtitle", comment: "Grounding step 1 subtitle"),
                    icon: "wind",
                    color: "73DE85",
                    estimatedDuration: NSLocalizedString("exercise.grounding.step_1.duration", comment: "Grounding step 1 duration")
                ),
                InstructionStep(
                    title: NSLocalizedString("exercise.grounding.step_2.title", comment: "Grounding step 2 title"),
                    subtitle: NSLocalizedString("exercise.grounding.step_2.subtitle", comment: "Grounding step 2 subtitle"),
                    icon: "eye.fill",
                    color: "66BB6A",
                    estimatedDuration: NSLocalizedString("exercise.grounding.step_2.duration", comment: "Grounding step 2 duration")
                ),
                InstructionStep(
                    title: NSLocalizedString("exercise.grounding.step_3.title", comment: "Grounding step 3 title"),
                    subtitle: NSLocalizedString("exercise.grounding.step_3.subtitle", comment: "Grounding step 3 subtitle"),
                    icon: "hand.raised.fill",
                    color: "00FF88",
                    estimatedDuration: NSLocalizedString("exercise.grounding.step_3.duration", comment: "Grounding step 3 duration")
                ),
                InstructionStep(
                    title: NSLocalizedString("exercise.grounding.step_4.title", comment: "Grounding step 4 title"),
                    subtitle: NSLocalizedString("exercise.grounding.step_4.subtitle", comment: "Grounding step 4 subtitle"),
                    icon: "ear.fill",
                    color: "9B7BF1",
                    estimatedDuration: NSLocalizedString("exercise.grounding.step_4.duration", comment: "Grounding step 4 duration")
                ),
                InstructionStep(
                    title: NSLocalizedString("exercise.grounding.step_5.title", comment: "Grounding step 5 title"),
                    subtitle: NSLocalizedString("exercise.grounding.step_5.subtitle", comment: "Grounding step 5 subtitle"),
                    icon: "nose.fill",
                    color: "FF6B9D",
                    estimatedDuration: NSLocalizedString("exercise.grounding.step_5.duration", comment: "Grounding step 5 duration")
                ),
                InstructionStep(
                    title: NSLocalizedString("exercise.grounding.step_6.title", comment: "Grounding step 6 title"),
                    subtitle: NSLocalizedString("exercise.grounding.step_6.subtitle", comment: "Grounding step 6 subtitle"),
                    icon: "mouth.fill",
                    color: "73DE85",
                    estimatedDuration: NSLocalizedString("exercise.grounding.step_6.duration", comment: "Grounding step 6 duration")
                )
            ]

        case .consciousStretching:
            return [
                InstructionStep(
                    title: NSLocalizedString("exercise.stretching.step_1.title", comment: "Stretching step 1 title"),
                    subtitle: NSLocalizedString("exercise.stretching.step_1.subtitle", comment: "Stretching step 1 subtitle"),
                    icon: "figure.stand",
                    color: "B388FF",
                    estimatedDuration: NSLocalizedString("exercise.stretching.step_1.duration", comment: "Stretching step 1 duration")
                ),
                InstructionStep(
                    title: NSLocalizedString("exercise.stretching.step_2.title", comment: "Stretching step 2 title"),
                    subtitle: NSLocalizedString("exercise.stretching.step_2.subtitle", comment: "Stretching step 2 subtitle"),
                    icon: "figure.arms.open",
                    color: "9B7BF1",
                    estimatedDuration: NSLocalizedString("exercise.stretching.step_2.duration", comment: "Stretching step 2 duration")
                ),
                InstructionStep(
                    title: NSLocalizedString("exercise.stretching.step_3.title", comment: "Stretching step 3 title"),
                    subtitle: NSLocalizedString("exercise.stretching.step_3.subtitle", comment: "Stretching step 3 subtitle"),
                    icon: "arrow.triangle.2.circlepath",
                    color: "8C6BE5",
                    estimatedDuration: NSLocalizedString("exercise.stretching.step_3.duration", comment: "Stretching step 3 duration")
                ),
                InstructionStep(
                    title: NSLocalizedString("exercise.stretching.step_4.title", comment: "Stretching step 4 title"),
                    subtitle: NSLocalizedString("exercise.stretching.step_4.subtitle", comment: "Stretching step 4 subtitle"),
                    icon: "figure.flexibility",
                    color: "7D5CD9",
                    estimatedDuration: NSLocalizedString("exercise.stretching.step_4.duration", comment: "Stretching step 4 duration")
                ),
                InstructionStep(
                    title: NSLocalizedString("exercise.stretching.step_5.title", comment: "Stretching step 5 title"),
                    subtitle: NSLocalizedString("exercise.stretching.step_5.subtitle", comment: "Stretching step 5 subtitle"),
                    icon: "arrow.left.and.right",
                    color: "6E4DCD",
                    estimatedDuration: NSLocalizedString("exercise.stretching.step_5.duration", comment: "Stretching step 5 duration")
                ),
                InstructionStep(
                    title: NSLocalizedString("exercise.stretching.step_6.title", comment: "Stretching step 6 title"),
                    subtitle: NSLocalizedString("exercise.stretching.step_6.subtitle", comment: "Stretching step 6 subtitle"),
                    icon: "wind",
                    color: "B388FF",
                    estimatedDuration: NSLocalizedString("exercise.stretching.step_6.duration", comment: "Stretching step 6 duration")
                )
            ]

        case .audioRelaxation:
            return [
                InstructionStep(
                    title: NSLocalizedString("exercise.audio.step_1.title", comment: "Audio relaxation step 1 title"),
                    subtitle: NSLocalizedString("exercise.audio.step_1.subtitle", comment: "Audio relaxation step 1 subtitle"),
                    icon: "headphones",
                    color: "B388FF",
                    estimatedDuration: NSLocalizedString("exercise.audio.step_1.duration", comment: "Audio relaxation step 1 duration")
                ),
                InstructionStep(
                    title: NSLocalizedString("exercise.audio.step_2.title", comment: "Audio relaxation step 2 title"),
                    subtitle: NSLocalizedString("exercise.audio.step_2.subtitle", comment: "Audio relaxation step 2 subtitle"),
                    icon: "bed.double.fill",
                    color: "9B7BF1",
                    estimatedDuration: NSLocalizedString("exercise.audio.step_2.duration", comment: "Audio relaxation step 2 duration")
                ),
                InstructionStep(
                    title: NSLocalizedString("exercise.audio.step_3.title", comment: "Audio relaxation step 3 title"),
                    subtitle: NSLocalizedString("exercise.audio.step_3.subtitle", comment: "Audio relaxation step 3 subtitle"),
                    icon: "play.circle.fill",
                    color: "8C6BE5",
                    estimatedDuration: NSLocalizedString("exercise.audio.step_3.duration", comment: "Audio relaxation step 3 duration")
                ),
                InstructionStep(
                    title: NSLocalizedString("exercise.audio.step_4.title", comment: "Audio relaxation step 4 title"),
                    subtitle: NSLocalizedString("exercise.audio.step_4.subtitle", comment: "Audio relaxation step 4 subtitle"),
                    icon: "arrow.forward.circle.fill",
                    color: "7D5CD9",
                    estimatedDuration: NSLocalizedString("exercise.audio.step_4.duration", comment: "Audio relaxation step 4 duration")
                ),
                InstructionStep(
                    title: NSLocalizedString("exercise.audio.step_5.title", comment: "Audio relaxation step 5 title"),
                    subtitle: NSLocalizedString("exercise.audio.step_5.subtitle", comment: "Audio relaxation step 5 subtitle"),
                    icon: "arrow.down.circle.fill",
                    color: "6E4DCD",
                    estimatedDuration: NSLocalizedString("exercise.audio.step_5.duration", comment: "Audio relaxation step 5 duration")
                ),
                InstructionStep(
                    title: NSLocalizedString("exercise.audio.step_6.title", comment: "Audio relaxation step 6 title"),
                    subtitle: NSLocalizedString("exercise.audio.step_6.subtitle", comment: "Audio relaxation step 6 subtitle"),
                    icon: "sparkles",
                    color: "B388FF",
                    estimatedDuration: NSLocalizedString("exercise.audio.step_6.duration", comment: "Audio relaxation step 6 duration")
                )
            ]

        case .positiveMantra:
            return [
                InstructionStep(
                    title: NSLocalizedString("exercise.mantra.step_1.title", comment: "Mantra step 1 title"),
                    subtitle: NSLocalizedString("exercise.mantra.step_1.subtitle", comment: "Mantra step 1 subtitle"),
                    icon: "text.quote",
                    color: "B388FF",
                    estimatedDuration: NSLocalizedString("exercise.mantra.step_1.duration", comment: "Mantra step 1 duration")
                ),
                InstructionStep(
                    title: NSLocalizedString("exercise.mantra.step_2.title", comment: "Mantra step 2 title"),
                    subtitle: NSLocalizedString("exercise.mantra.step_2.subtitle", comment: "Mantra step 2 subtitle"),
                    icon: "figure.seated.side",
                    color: "9B7BF1",
                    estimatedDuration: NSLocalizedString("exercise.mantra.step_2.duration", comment: "Mantra step 2 duration")
                ),
                InstructionStep(
                    title: NSLocalizedString("exercise.mantra.step_3.title", comment: "Mantra step 3 title"),
                    subtitle: NSLocalizedString("exercise.mantra.step_3.subtitle", comment: "Mantra step 3 subtitle"),
                    icon: "face.smiling.fill",
                    color: "8C6BE5",
                    estimatedDuration: NSLocalizedString("exercise.mantra.step_3.duration", comment: "Mantra step 3 duration")
                ),
                InstructionStep(
                    title: NSLocalizedString("exercise.mantra.step_4.title", comment: "Mantra step 4 title"),
                    subtitle: NSLocalizedString("exercise.mantra.step_4.subtitle", comment: "Mantra step 4 subtitle"),
                    icon: "arrow.clockwise",
                    color: "7D5CD9",
                    estimatedDuration: NSLocalizedString("exercise.mantra.step_4.duration", comment: "Mantra step 4 duration")
                ),
                InstructionStep(
                    title: NSLocalizedString("exercise.mantra.step_5.title", comment: "Mantra step 5 title"),
                    subtitle: NSLocalizedString("exercise.mantra.step_5.subtitle", comment: "Mantra step 5 subtitle"),
                    icon: "heart.circle.fill",
                    color: "6E4DCD",
                    estimatedDuration: NSLocalizedString("exercise.mantra.step_5.duration", comment: "Mantra step 5 duration")
                ),
                InstructionStep(
                    title: NSLocalizedString("exercise.mantra.step_6.title", comment: "Mantra step 6 title"),
                    subtitle: NSLocalizedString("exercise.mantra.step_6.subtitle", comment: "Mantra step 6 subtitle"),
                    icon: "sparkles",
                    color: "B388FF",
                    estimatedDuration: NSLocalizedString("exercise.mantra.step_6.duration", comment: "Mantra step 6 duration")
                )
            ]

        case .visualMicroBreak:
            return [
                InstructionStep(
                    title: NSLocalizedString("exercise.visual_break.step_1.title", comment: "Visual break step 1 title"),
                    subtitle: NSLocalizedString("exercise.visual_break.step_1.subtitle", comment: "Visual break step 1 subtitle"),
                    icon: "eye.fill",
                    color: "B388FF",
                    estimatedDuration: NSLocalizedString("exercise.visual_break.step_1.duration", comment: "Visual break step 1 duration")
                ),
                InstructionStep(
                    title: NSLocalizedString("exercise.visual_break.step_2.title", comment: "Visual break step 2 title"),
                    subtitle: NSLocalizedString("exercise.visual_break.step_2.subtitle", comment: "Visual break step 2 subtitle"),
                    icon: "scope",
                    color: "9B7BF1",
                    estimatedDuration: NSLocalizedString("exercise.visual_break.step_2.duration", comment: "Visual break step 2 duration")
                ),
                InstructionStep(
                    title: NSLocalizedString("exercise.visual_break.step_3.title", comment: "Visual break step 3 title"),
                    subtitle: NSLocalizedString("exercise.visual_break.step_3.subtitle", comment: "Visual break step 3 subtitle"),
                    icon: "drop.fill",
                    color: "8C6BE5",
                    estimatedDuration: NSLocalizedString("exercise.visual_break.step_3.duration", comment: "Visual break step 3 duration")
                ),
                InstructionStep(
                    title: NSLocalizedString("exercise.visual_break.step_4.title", comment: "Visual break step 4 title"),
                    subtitle: NSLocalizedString("exercise.visual_break.step_4.subtitle", comment: "Visual break step 4 subtitle"),
                    icon: "arrow.triangle.2.circlepath.circle.fill",
                    color: "7D5CD9",
                    estimatedDuration: NSLocalizedString("exercise.visual_break.step_4.duration", comment: "Visual break step 4 duration")
                ),
                InstructionStep(
                    title: NSLocalizedString("exercise.visual_break.step_5.title", comment: "Visual break step 5 title"),
                    subtitle: NSLocalizedString("exercise.visual_break.step_5.subtitle", comment: "Visual break step 5 subtitle"),
                    icon: "eye.slash.fill",
                    color: "6E4DCD",
                    estimatedDuration: NSLocalizedString("exercise.visual_break.step_5.duration", comment: "Visual break step 5 duration")
                ),
                InstructionStep(
                    title: NSLocalizedString("exercise.visual_break.step_6.title", comment: "Visual break step 6 title"),
                    subtitle: NSLocalizedString("exercise.visual_break.step_6.subtitle", comment: "Visual break step 6 subtitle"),
                    icon: "checkmark.circle.fill",
                    color: "B388FF",
                    estimatedDuration: NSLocalizedString("exercise.visual_break.step_6.duration", comment: "Visual break step 6 duration")
                )
            ]

        case .slowWalk:
            return [
                InstructionStep(
                    title: NSLocalizedString("exercise.slow_walk.step_1.title", comment: "Slow walk step 1 title"),
                    subtitle: NSLocalizedString("exercise.slow_walk.step_1.subtitle", comment: "Slow walk step 1 subtitle"),
                    icon: "figure.walk",
                    color: "B388FF",
                    estimatedDuration: NSLocalizedString("exercise.slow_walk.step_1.duration", comment: "Slow walk step 1 duration")
                ),
                InstructionStep(
                    title: NSLocalizedString("exercise.slow_walk.step_2.title", comment: "Slow walk step 2 title"),
                    subtitle: NSLocalizedString("exercise.slow_walk.step_2.subtitle", comment: "Slow walk step 2 subtitle"),
                    icon: "figure.stand",
                    color: "9B7BF1",
                    estimatedDuration: NSLocalizedString("exercise.slow_walk.step_2.duration", comment: "Slow walk step 2 duration")
                ),
                InstructionStep(
                    title: NSLocalizedString("exercise.slow_walk.step_3.title", comment: "Slow walk step 3 title"),
                    subtitle: NSLocalizedString("exercise.slow_walk.step_3.subtitle", comment: "Slow walk step 3 subtitle"),
                    icon: "tortoise.fill",
                    color: "8C6BE5",
                    estimatedDuration: NSLocalizedString("exercise.slow_walk.step_3.duration", comment: "Slow walk step 3 duration")
                ),
                InstructionStep(
                    title: NSLocalizedString("exercise.slow_walk.step_4.title", comment: "Slow walk step 4 title"),
                    subtitle: NSLocalizedString("exercise.slow_walk.step_4.subtitle", comment: "Slow walk step 4 subtitle"),
                    icon: "wind",
                    color: "7D5CD9",
                    estimatedDuration: NSLocalizedString("exercise.slow_walk.step_4.duration", comment: "Slow walk step 4 duration")
                ),
                InstructionStep(
                    title: NSLocalizedString("exercise.slow_walk.step_5.title", comment: "Slow walk step 5 title"),
                    subtitle: NSLocalizedString("exercise.slow_walk.step_5.subtitle", comment: "Slow walk step 5 subtitle"),
                    icon: "timer",
                    color: "6E4DCD",
                    estimatedDuration: NSLocalizedString("exercise.slow_walk.step_5.duration", comment: "Slow walk step 5 duration")
                ),
                InstructionStep(
                    title: NSLocalizedString("exercise.slow_walk.step_6.title", comment: "Slow walk step 6 title"),
                    subtitle: NSLocalizedString("exercise.slow_walk.step_6.subtitle", comment: "Slow walk step 6 subtitle"),
                    icon: "checkmark.circle.fill",
                    color: "B388FF",
                    estimatedDuration: NSLocalizedString("exercise.slow_walk.step_6.duration", comment: "Slow walk step 6 duration")
                )
            ]

        case .whiteNoise:
            return [
                InstructionStep(
                    title: NSLocalizedString("exercise.white_noise.step_1.title", comment: "White noise step 1 title"),
                    subtitle: NSLocalizedString("exercise.white_noise.step_1.subtitle", comment: "White noise step 1 subtitle"),
                    icon: "waveform",
                    color: "B388FF",
                    estimatedDuration: NSLocalizedString("exercise.white_noise.step_1.duration", comment: "White noise step 1 duration")
                ),
                InstructionStep(
                    title: NSLocalizedString("exercise.white_noise.step_2.title", comment: "White noise step 2 title"),
                    subtitle: NSLocalizedString("exercise.white_noise.step_2.subtitle", comment: "White noise step 2 subtitle"),
                    icon: "speaker.wave.2.fill",
                    color: "9B7BF1",
                    estimatedDuration: NSLocalizedString("exercise.white_noise.step_2.duration", comment: "White noise step 2 duration")
                ),
                InstructionStep(
                    title: NSLocalizedString("exercise.white_noise.step_3.title", comment: "White noise step 3 title"),
                    subtitle: NSLocalizedString("exercise.white_noise.step_3.subtitle", comment: "White noise step 3 subtitle"),
                    icon: "bed.double.fill",
                    color: "8C6BE5",
                    estimatedDuration: NSLocalizedString("exercise.white_noise.step_3.duration", comment: "White noise step 3 duration")
                ),
                InstructionStep(
                    title: NSLocalizedString("exercise.white_noise.step_4.title", comment: "White noise step 4 title"),
                    subtitle: NSLocalizedString("exercise.white_noise.step_4.subtitle", comment: "White noise step 4 subtitle"),
                    icon: "eye.slash.fill",
                    color: "7D5CD9",
                    estimatedDuration: NSLocalizedString("exercise.white_noise.step_4.duration", comment: "White noise step 4 duration")
                ),
                InstructionStep(
                    title: NSLocalizedString("exercise.white_noise.step_5.title", comment: "White noise step 5 title"),
                    subtitle: NSLocalizedString("exercise.white_noise.step_5.subtitle", comment: "White noise step 5 subtitle"),
                    icon: "timer",
                    color: "6E4DCD",
                    estimatedDuration: NSLocalizedString("exercise.white_noise.step_5.duration", comment: "White noise step 5 duration")
                ),
                InstructionStep(
                    title: NSLocalizedString("exercise.white_noise.step_6.title", comment: "White noise step 6 title"),
                    subtitle: NSLocalizedString("exercise.white_noise.step_6.subtitle", comment: "White noise step 6 subtitle"),
                    icon: "checkmark.circle.fill",
                    color: "B388FF",
                    estimatedDuration: NSLocalizedString("exercise.white_noise.step_6.duration", comment: "White noise step 6 duration")
                )
            ]

        default:
            return []
        }
    }
}

#Preview {
    InstructionExerciseView(
        exerciseType: .bodyScan,
        situation: .overwhelmed,
        viewModel: AntiStressViewModel()
    )
}
