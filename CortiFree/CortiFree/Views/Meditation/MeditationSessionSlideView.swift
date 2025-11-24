//
//  MeditationSessionSlideView.swift
//  CortiFree
//
//  Created by Claude on 23/10/2025.
//  Vue de session guidée avec slides pour les méditations - WRAPPER pour UnifiedInstructionSlideView
//

import SwiftUI

struct MeditationSessionSlideView: View {
    let support: MeditationSupport
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        UnifiedInstructionSlideView(
            steps: support.toUnifiedInstructionSteps(),
            exerciseTitle: support.title,
            onComplete: {
                // Complete callback - pour tracker la complétion de méditation si besoin
            }
        )
    }
}

#Preview {
    if let support = MeditationSupport.support(for: "grounding") {
        MeditationSessionSlideView(support: support)
    }
}
