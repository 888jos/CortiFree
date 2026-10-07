//
//  MeditationSessionSlideView.swift
//  CortiFree
//
//  Created by Claude on 23/10/2025.
//  Former step-by-step slides: now starts the matching guided audio session and shows
//  the full-screen player (used by RoutinePlayerView).
//

import SwiftUI

struct MeditationSessionSlideView: View {
    let support: MeditationSupport

    var body: some View {
        GuidedSessionAutoPlayView(session: GuidedSessionCatalog.session(forLegacyID: support.meditationId))
    }
}

#Preview {
    if let support = MeditationSupport.support(for: "grounding") {
        MeditationSessionSlideView(support: support)
    }
}
