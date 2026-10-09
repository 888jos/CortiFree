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
            exerciseID: exerciseType.rawValue,
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
                    title: LanguageManager.shared.localizedString(for: "exercise.body_scan.step_1.title"),
                    subtitle: LanguageManager.shared.localizedString(for: "exercise.body_scan.step_1.subtitle"),
                    icon: "figure.stand",
                    color: "B388FF",
                    estimatedDuration: LanguageManager.shared.localizedString(for: "exercise.body_scan.step_1.duration")
                ),
                InstructionStep(
                    title: LanguageManager.shared.localizedString(for: "exercise.body_scan.step_2.title"),
                    subtitle: LanguageManager.shared.localizedString(for: "exercise.body_scan.step_2.subtitle"),
                    icon: "eye.slash.fill",
                    color: "9B7BF1",
                    estimatedDuration: LanguageManager.shared.localizedString(for: "exercise.body_scan.step_2.duration")
                ),
                InstructionStep(
                    title: LanguageManager.shared.localizedString(for: "exercise.body_scan.step_3.title"),
                    subtitle: LanguageManager.shared.localizedString(for: "exercise.body_scan.step_3.subtitle"),
                    icon: "face.smiling.fill",
                    color: "8C6BE5",
                    estimatedDuration: LanguageManager.shared.localizedString(for: "exercise.body_scan.step_3.duration")
                ),
                InstructionStep(
                    title: LanguageManager.shared.localizedString(for: "exercise.body_scan.step_4.title"),
                    subtitle: LanguageManager.shared.localizedString(for: "exercise.body_scan.step_4.subtitle"),
                    icon: "figure.arms.open",
                    color: "7D5CD9",
                    estimatedDuration: LanguageManager.shared.localizedString(for: "exercise.body_scan.step_4.duration")
                ),
                InstructionStep(
                    title: LanguageManager.shared.localizedString(for: "exercise.body_scan.step_5.title"),
                    subtitle: LanguageManager.shared.localizedString(for: "exercise.body_scan.step_5.subtitle"),
                    icon: "lungs.fill",
                    color: "6E4DCD",
                    estimatedDuration: LanguageManager.shared.localizedString(for: "exercise.body_scan.step_5.duration")
                ),
                InstructionStep(
                    title: LanguageManager.shared.localizedString(for: "exercise.body_scan.step_6.title"),
                    subtitle: LanguageManager.shared.localizedString(for: "exercise.body_scan.step_6.subtitle"),
                    icon: "figure.walk",
                    color: "5F3EC1",
                    estimatedDuration: LanguageManager.shared.localizedString(for: "exercise.body_scan.step_6.duration")
                ),
                InstructionStep(
                    title: LanguageManager.shared.localizedString(for: "exercise.body_scan.step_7.title"),
                    subtitle: LanguageManager.shared.localizedString(for: "exercise.body_scan.step_7.subtitle"),
                    icon: "heart.fill",
                    color: "B388FF",
                    estimatedDuration: LanguageManager.shared.localizedString(for: "exercise.body_scan.step_7.duration")
                )
            ]

        case .anchoring54321:
            return [
                InstructionStep(
                    title: LanguageManager.shared.localizedString(for: "exercise.anchoring.step_1.title"),
                    subtitle: LanguageManager.shared.localizedString(for: "exercise.anchoring.step_1.subtitle"),
                    icon: "eye.fill",
                    color: "73DE85",
                    estimatedDuration: LanguageManager.shared.localizedString(for: "exercise.anchoring.step_1.duration")
                ),
                InstructionStep(
                    title: LanguageManager.shared.localizedString(for: "exercise.anchoring.step_2.title"),
                    subtitle: LanguageManager.shared.localizedString(for: "exercise.anchoring.step_2.subtitle"),
                    icon: "hand.raised.fill",
                    color: "66BB6A",
                    estimatedDuration: LanguageManager.shared.localizedString(for: "exercise.anchoring.step_2.duration")
                ),
                InstructionStep(
                    title: LanguageManager.shared.localizedString(for: "exercise.anchoring.step_3.title"),
                    subtitle: LanguageManager.shared.localizedString(for: "exercise.anchoring.step_3.subtitle"),
                    icon: "ear.fill",
                    color: "00FF88",
                    estimatedDuration: LanguageManager.shared.localizedString(for: "exercise.anchoring.step_3.duration")
                ),
                InstructionStep(
                    title: LanguageManager.shared.localizedString(for: "exercise.anchoring.step_4.title"),
                    subtitle: LanguageManager.shared.localizedString(for: "exercise.anchoring.step_4.subtitle"),
                    icon: "nose.fill",
                    color: "9B7BF1",
                    estimatedDuration: LanguageManager.shared.localizedString(for: "exercise.anchoring.step_4.duration")
                ),
                InstructionStep(
                    title: LanguageManager.shared.localizedString(for: "exercise.anchoring.step_5.title"),
                    subtitle: LanguageManager.shared.localizedString(for: "exercise.anchoring.step_5.subtitle"),
                    icon: "mouth.fill",
                    color: "FF6B9D",
                    estimatedDuration: LanguageManager.shared.localizedString(for: "exercise.anchoring.step_5.duration")
                ),
                InstructionStep(
                    title: LanguageManager.shared.localizedString(for: "exercise.anchoring.step_6.title"),
                    subtitle: LanguageManager.shared.localizedString(for: "exercise.anchoring.step_6.subtitle"),
                    icon: "checkmark.circle.fill",
                    color: "73DE85",
                    estimatedDuration: LanguageManager.shared.localizedString(for: "exercise.anchoring.step_6.duration")
                )
            ]

        case .meditation2Min:
            return [
                InstructionStep(
                    title: LanguageManager.shared.localizedString(for: "exercise.meditation_2min.step_1.title"),
                    subtitle: LanguageManager.shared.localizedString(for: "exercise.meditation_2min.step_1.subtitle"),
                    icon: "figure.seated.side",
                    color: "B388FF",
                    estimatedDuration: LanguageManager.shared.localizedString(for: "exercise.meditation_2min.step_1.duration")
                ),
                InstructionStep(
                    title: LanguageManager.shared.localizedString(for: "exercise.meditation_2min.step_2.title"),
                    subtitle: LanguageManager.shared.localizedString(for: "exercise.meditation_2min.step_2.subtitle"),
                    icon: "eye.slash.fill",
                    color: "9B7BF1",
                    estimatedDuration: LanguageManager.shared.localizedString(for: "exercise.meditation_2min.step_2.duration")
                ),
                InstructionStep(
                    title: LanguageManager.shared.localizedString(for: "exercise.meditation_2min.step_3.title"),
                    subtitle: LanguageManager.shared.localizedString(for: "exercise.meditation_2min.step_3.subtitle"),
                    icon: "wind",
                    color: "8C6BE5",
                    estimatedDuration: LanguageManager.shared.localizedString(for: "exercise.meditation_2min.step_3.duration")
                ),
                InstructionStep(
                    title: LanguageManager.shared.localizedString(for: "exercise.meditation_2min.step_4.title"),
                    subtitle: LanguageManager.shared.localizedString(for: "exercise.meditation_2min.step_4.subtitle"),
                    icon: "cloud.fill",
                    color: "7D5CD9",
                    estimatedDuration: LanguageManager.shared.localizedString(for: "exercise.meditation_2min.step_4.duration")
                ),
                InstructionStep(
                    title: LanguageManager.shared.localizedString(for: "exercise.meditation_2min.step_5.title"),
                    subtitle: LanguageManager.shared.localizedString(for: "exercise.meditation_2min.step_5.subtitle"),
                    icon: "arrow.uturn.backward",
                    color: "6E4DCD",
                    estimatedDuration: LanguageManager.shared.localizedString(for: "exercise.meditation_2min.step_5.duration")
                ),
                InstructionStep(
                    title: LanguageManager.shared.localizedString(for: "exercise.meditation_2min.step_6.title"),
                    subtitle: LanguageManager.shared.localizedString(for: "exercise.meditation_2min.step_6.subtitle"),
                    icon: "lungs.fill",
                    color: "B388FF",
                    estimatedDuration: LanguageManager.shared.localizedString(for: "exercise.meditation_2min.step_6.duration")
                )
            ]

        case .grounding5Senses:
            return [
                InstructionStep(
                    title: LanguageManager.shared.localizedString(for: "exercise.grounding.step_1.title"),
                    subtitle: LanguageManager.shared.localizedString(for: "exercise.grounding.step_1.subtitle"),
                    icon: "wind",
                    color: "73DE85",
                    estimatedDuration: LanguageManager.shared.localizedString(for: "exercise.grounding.step_1.duration")
                ),
                InstructionStep(
                    title: LanguageManager.shared.localizedString(for: "exercise.grounding.step_2.title"),
                    subtitle: LanguageManager.shared.localizedString(for: "exercise.grounding.step_2.subtitle"),
                    icon: "eye.fill",
                    color: "66BB6A",
                    estimatedDuration: LanguageManager.shared.localizedString(for: "exercise.grounding.step_2.duration")
                ),
                InstructionStep(
                    title: LanguageManager.shared.localizedString(for: "exercise.grounding.step_3.title"),
                    subtitle: LanguageManager.shared.localizedString(for: "exercise.grounding.step_3.subtitle"),
                    icon: "hand.raised.fill",
                    color: "00FF88",
                    estimatedDuration: LanguageManager.shared.localizedString(for: "exercise.grounding.step_3.duration")
                ),
                InstructionStep(
                    title: LanguageManager.shared.localizedString(for: "exercise.grounding.step_4.title"),
                    subtitle: LanguageManager.shared.localizedString(for: "exercise.grounding.step_4.subtitle"),
                    icon: "ear.fill",
                    color: "9B7BF1",
                    estimatedDuration: LanguageManager.shared.localizedString(for: "exercise.grounding.step_4.duration")
                ),
                InstructionStep(
                    title: LanguageManager.shared.localizedString(for: "exercise.grounding.step_5.title"),
                    subtitle: LanguageManager.shared.localizedString(for: "exercise.grounding.step_5.subtitle"),
                    icon: "nose.fill",
                    color: "FF6B9D",
                    estimatedDuration: LanguageManager.shared.localizedString(for: "exercise.grounding.step_5.duration")
                ),
                InstructionStep(
                    title: LanguageManager.shared.localizedString(for: "exercise.grounding.step_6.title"),
                    subtitle: LanguageManager.shared.localizedString(for: "exercise.grounding.step_6.subtitle"),
                    icon: "mouth.fill",
                    color: "73DE85",
                    estimatedDuration: LanguageManager.shared.localizedString(for: "exercise.grounding.step_6.duration")
                )
            ]

        case .consciousStretching:
            return [
                InstructionStep(
                    title: LanguageManager.shared.localizedString(for: "exercise.stretching.step_1.title"),
                    subtitle: LanguageManager.shared.localizedString(for: "exercise.stretching.step_1.subtitle"),
                    icon: "figure.stand",
                    color: "B388FF",
                    estimatedDuration: LanguageManager.shared.localizedString(for: "exercise.stretching.step_1.duration")
                ),
                InstructionStep(
                    title: LanguageManager.shared.localizedString(for: "exercise.stretching.step_2.title"),
                    subtitle: LanguageManager.shared.localizedString(for: "exercise.stretching.step_2.subtitle"),
                    icon: "figure.arms.open",
                    color: "9B7BF1",
                    estimatedDuration: LanguageManager.shared.localizedString(for: "exercise.stretching.step_2.duration")
                ),
                InstructionStep(
                    title: LanguageManager.shared.localizedString(for: "exercise.stretching.step_3.title"),
                    subtitle: LanguageManager.shared.localizedString(for: "exercise.stretching.step_3.subtitle"),
                    icon: "arrow.triangle.2.circlepath",
                    color: "8C6BE5",
                    estimatedDuration: LanguageManager.shared.localizedString(for: "exercise.stretching.step_3.duration")
                ),
                InstructionStep(
                    title: LanguageManager.shared.localizedString(for: "exercise.stretching.step_4.title"),
                    subtitle: LanguageManager.shared.localizedString(for: "exercise.stretching.step_4.subtitle"),
                    icon: "figure.flexibility",
                    color: "7D5CD9",
                    estimatedDuration: LanguageManager.shared.localizedString(for: "exercise.stretching.step_4.duration")
                ),
                InstructionStep(
                    title: LanguageManager.shared.localizedString(for: "exercise.stretching.step_5.title"),
                    subtitle: LanguageManager.shared.localizedString(for: "exercise.stretching.step_5.subtitle"),
                    icon: "arrow.left.and.right",
                    color: "6E4DCD",
                    estimatedDuration: LanguageManager.shared.localizedString(for: "exercise.stretching.step_5.duration")
                ),
                InstructionStep(
                    title: LanguageManager.shared.localizedString(for: "exercise.stretching.step_6.title"),
                    subtitle: LanguageManager.shared.localizedString(for: "exercise.stretching.step_6.subtitle"),
                    icon: "wind",
                    color: "B388FF",
                    estimatedDuration: LanguageManager.shared.localizedString(for: "exercise.stretching.step_6.duration")
                )
            ]

        case .audioRelaxation:
            return [
                InstructionStep(
                    title: LanguageManager.shared.localizedString(for: "exercise.audio.step_1.title"),
                    subtitle: LanguageManager.shared.localizedString(for: "exercise.audio.step_1.subtitle"),
                    icon: "headphones",
                    color: "B388FF",
                    estimatedDuration: LanguageManager.shared.localizedString(for: "exercise.audio.step_1.duration")
                ),
                InstructionStep(
                    title: LanguageManager.shared.localizedString(for: "exercise.audio.step_2.title"),
                    subtitle: LanguageManager.shared.localizedString(for: "exercise.audio.step_2.subtitle"),
                    icon: "bed.double.fill",
                    color: "9B7BF1",
                    estimatedDuration: LanguageManager.shared.localizedString(for: "exercise.audio.step_2.duration")
                ),
                InstructionStep(
                    title: LanguageManager.shared.localizedString(for: "exercise.audio.step_3.title"),
                    subtitle: LanguageManager.shared.localizedString(for: "exercise.audio.step_3.subtitle"),
                    icon: "play.circle.fill",
                    color: "8C6BE5",
                    estimatedDuration: LanguageManager.shared.localizedString(for: "exercise.audio.step_3.duration")
                ),
                InstructionStep(
                    title: LanguageManager.shared.localizedString(for: "exercise.audio.step_4.title"),
                    subtitle: LanguageManager.shared.localizedString(for: "exercise.audio.step_4.subtitle"),
                    icon: "arrow.forward.circle.fill",
                    color: "7D5CD9",
                    estimatedDuration: LanguageManager.shared.localizedString(for: "exercise.audio.step_4.duration")
                ),
                InstructionStep(
                    title: LanguageManager.shared.localizedString(for: "exercise.audio.step_5.title"),
                    subtitle: LanguageManager.shared.localizedString(for: "exercise.audio.step_5.subtitle"),
                    icon: "arrow.down.circle.fill",
                    color: "6E4DCD",
                    estimatedDuration: LanguageManager.shared.localizedString(for: "exercise.audio.step_5.duration")
                ),
                InstructionStep(
                    title: LanguageManager.shared.localizedString(for: "exercise.audio.step_6.title"),
                    subtitle: LanguageManager.shared.localizedString(for: "exercise.audio.step_6.subtitle"),
                    icon: "sparkles",
                    color: "B388FF",
                    estimatedDuration: LanguageManager.shared.localizedString(for: "exercise.audio.step_6.duration")
                )
            ]

        case .positiveMantra:
            return [
                InstructionStep(
                    title: LanguageManager.shared.localizedString(for: "exercise.mantra.step_1.title"),
                    subtitle: LanguageManager.shared.localizedString(for: "exercise.mantra.step_1.subtitle"),
                    icon: "text.quote",
                    color: "B388FF",
                    estimatedDuration: LanguageManager.shared.localizedString(for: "exercise.mantra.step_1.duration")
                ),
                InstructionStep(
                    title: LanguageManager.shared.localizedString(for: "exercise.mantra.step_2.title"),
                    subtitle: LanguageManager.shared.localizedString(for: "exercise.mantra.step_2.subtitle"),
                    icon: "figure.seated.side",
                    color: "9B7BF1",
                    estimatedDuration: LanguageManager.shared.localizedString(for: "exercise.mantra.step_2.duration")
                ),
                InstructionStep(
                    title: LanguageManager.shared.localizedString(for: "exercise.mantra.step_3.title"),
                    subtitle: LanguageManager.shared.localizedString(for: "exercise.mantra.step_3.subtitle"),
                    icon: "face.smiling.fill",
                    color: "8C6BE5",
                    estimatedDuration: LanguageManager.shared.localizedString(for: "exercise.mantra.step_3.duration")
                ),
                InstructionStep(
                    title: LanguageManager.shared.localizedString(for: "exercise.mantra.step_4.title"),
                    subtitle: LanguageManager.shared.localizedString(for: "exercise.mantra.step_4.subtitle"),
                    icon: "arrow.clockwise",
                    color: "7D5CD9",
                    estimatedDuration: LanguageManager.shared.localizedString(for: "exercise.mantra.step_4.duration")
                ),
                InstructionStep(
                    title: LanguageManager.shared.localizedString(for: "exercise.mantra.step_5.title"),
                    subtitle: LanguageManager.shared.localizedString(for: "exercise.mantra.step_5.subtitle"),
                    icon: "heart.circle.fill",
                    color: "6E4DCD",
                    estimatedDuration: LanguageManager.shared.localizedString(for: "exercise.mantra.step_5.duration")
                ),
                InstructionStep(
                    title: LanguageManager.shared.localizedString(for: "exercise.mantra.step_6.title"),
                    subtitle: LanguageManager.shared.localizedString(for: "exercise.mantra.step_6.subtitle"),
                    icon: "sparkles",
                    color: "B388FF",
                    estimatedDuration: LanguageManager.shared.localizedString(for: "exercise.mantra.step_6.duration")
                )
            ]

        case .visualMicroBreak:
            return [
                InstructionStep(
                    title: LanguageManager.shared.localizedString(for: "exercise.visual_break.step_1.title"),
                    subtitle: LanguageManager.shared.localizedString(for: "exercise.visual_break.step_1.subtitle"),
                    icon: "eye.fill",
                    color: "B388FF",
                    estimatedDuration: LanguageManager.shared.localizedString(for: "exercise.visual_break.step_1.duration")
                ),
                InstructionStep(
                    title: LanguageManager.shared.localizedString(for: "exercise.visual_break.step_2.title"),
                    subtitle: LanguageManager.shared.localizedString(for: "exercise.visual_break.step_2.subtitle"),
                    icon: "scope",
                    color: "9B7BF1",
                    estimatedDuration: LanguageManager.shared.localizedString(for: "exercise.visual_break.step_2.duration")
                ),
                InstructionStep(
                    title: LanguageManager.shared.localizedString(for: "exercise.visual_break.step_3.title"),
                    subtitle: LanguageManager.shared.localizedString(for: "exercise.visual_break.step_3.subtitle"),
                    icon: "drop.fill",
                    color: "8C6BE5",
                    estimatedDuration: LanguageManager.shared.localizedString(for: "exercise.visual_break.step_3.duration")
                ),
                InstructionStep(
                    title: LanguageManager.shared.localizedString(for: "exercise.visual_break.step_4.title"),
                    subtitle: LanguageManager.shared.localizedString(for: "exercise.visual_break.step_4.subtitle"),
                    icon: "arrow.triangle.2.circlepath.circle.fill",
                    color: "7D5CD9",
                    estimatedDuration: LanguageManager.shared.localizedString(for: "exercise.visual_break.step_4.duration")
                ),
                InstructionStep(
                    title: LanguageManager.shared.localizedString(for: "exercise.visual_break.step_5.title"),
                    subtitle: LanguageManager.shared.localizedString(for: "exercise.visual_break.step_5.subtitle"),
                    icon: "eye.slash.fill",
                    color: "6E4DCD",
                    estimatedDuration: LanguageManager.shared.localizedString(for: "exercise.visual_break.step_5.duration")
                ),
                InstructionStep(
                    title: LanguageManager.shared.localizedString(for: "exercise.visual_break.step_6.title"),
                    subtitle: LanguageManager.shared.localizedString(for: "exercise.visual_break.step_6.subtitle"),
                    icon: "checkmark.circle.fill",
                    color: "B388FF",
                    estimatedDuration: LanguageManager.shared.localizedString(for: "exercise.visual_break.step_6.duration")
                )
            ]

        case .slowWalk:
            return [
                InstructionStep(
                    title: LanguageManager.shared.localizedString(for: "exercise.slow_walk.step_1.title"),
                    subtitle: LanguageManager.shared.localizedString(for: "exercise.slow_walk.step_1.subtitle"),
                    icon: "figure.walk",
                    color: "B388FF",
                    estimatedDuration: LanguageManager.shared.localizedString(for: "exercise.slow_walk.step_1.duration")
                ),
                InstructionStep(
                    title: LanguageManager.shared.localizedString(for: "exercise.slow_walk.step_2.title"),
                    subtitle: LanguageManager.shared.localizedString(for: "exercise.slow_walk.step_2.subtitle"),
                    icon: "figure.stand",
                    color: "9B7BF1",
                    estimatedDuration: LanguageManager.shared.localizedString(for: "exercise.slow_walk.step_2.duration")
                ),
                InstructionStep(
                    title: LanguageManager.shared.localizedString(for: "exercise.slow_walk.step_3.title"),
                    subtitle: LanguageManager.shared.localizedString(for: "exercise.slow_walk.step_3.subtitle"),
                    icon: "tortoise.fill",
                    color: "8C6BE5",
                    estimatedDuration: LanguageManager.shared.localizedString(for: "exercise.slow_walk.step_3.duration")
                ),
                InstructionStep(
                    title: LanguageManager.shared.localizedString(for: "exercise.slow_walk.step_4.title"),
                    subtitle: LanguageManager.shared.localizedString(for: "exercise.slow_walk.step_4.subtitle"),
                    icon: "wind",
                    color: "7D5CD9",
                    estimatedDuration: LanguageManager.shared.localizedString(for: "exercise.slow_walk.step_4.duration")
                ),
                InstructionStep(
                    title: LanguageManager.shared.localizedString(for: "exercise.slow_walk.step_5.title"),
                    subtitle: LanguageManager.shared.localizedString(for: "exercise.slow_walk.step_5.subtitle"),
                    icon: "timer",
                    color: "6E4DCD",
                    estimatedDuration: LanguageManager.shared.localizedString(for: "exercise.slow_walk.step_5.duration")
                ),
                InstructionStep(
                    title: LanguageManager.shared.localizedString(for: "exercise.slow_walk.step_6.title"),
                    subtitle: LanguageManager.shared.localizedString(for: "exercise.slow_walk.step_6.subtitle"),
                    icon: "checkmark.circle.fill",
                    color: "B388FF",
                    estimatedDuration: LanguageManager.shared.localizedString(for: "exercise.slow_walk.step_6.duration")
                )
            ]

        case .whiteNoise:
            return [
                InstructionStep(
                    title: LanguageManager.shared.localizedString(for: "exercise.white_noise.step_1.title"),
                    subtitle: LanguageManager.shared.localizedString(for: "exercise.white_noise.step_1.subtitle"),
                    icon: "waveform",
                    color: "B388FF",
                    estimatedDuration: LanguageManager.shared.localizedString(for: "exercise.white_noise.step_1.duration")
                ),
                InstructionStep(
                    title: LanguageManager.shared.localizedString(for: "exercise.white_noise.step_2.title"),
                    subtitle: LanguageManager.shared.localizedString(for: "exercise.white_noise.step_2.subtitle"),
                    icon: "speaker.wave.2.fill",
                    color: "9B7BF1",
                    estimatedDuration: LanguageManager.shared.localizedString(for: "exercise.white_noise.step_2.duration")
                ),
                InstructionStep(
                    title: LanguageManager.shared.localizedString(for: "exercise.white_noise.step_3.title"),
                    subtitle: LanguageManager.shared.localizedString(for: "exercise.white_noise.step_3.subtitle"),
                    icon: "bed.double.fill",
                    color: "8C6BE5",
                    estimatedDuration: LanguageManager.shared.localizedString(for: "exercise.white_noise.step_3.duration")
                ),
                InstructionStep(
                    title: LanguageManager.shared.localizedString(for: "exercise.white_noise.step_4.title"),
                    subtitle: LanguageManager.shared.localizedString(for: "exercise.white_noise.step_4.subtitle"),
                    icon: "eye.slash.fill",
                    color: "7D5CD9",
                    estimatedDuration: LanguageManager.shared.localizedString(for: "exercise.white_noise.step_4.duration")
                ),
                InstructionStep(
                    title: LanguageManager.shared.localizedString(for: "exercise.white_noise.step_5.title"),
                    subtitle: LanguageManager.shared.localizedString(for: "exercise.white_noise.step_5.subtitle"),
                    icon: "timer",
                    color: "6E4DCD",
                    estimatedDuration: LanguageManager.shared.localizedString(for: "exercise.white_noise.step_5.duration")
                ),
                InstructionStep(
                    title: LanguageManager.shared.localizedString(for: "exercise.white_noise.step_6.title"),
                    subtitle: LanguageManager.shared.localizedString(for: "exercise.white_noise.step_6.subtitle"),
                    icon: "checkmark.circle.fill",
                    color: "B388FF",
                    estimatedDuration: LanguageManager.shared.localizedString(for: "exercise.white_noise.step_6.duration")
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
