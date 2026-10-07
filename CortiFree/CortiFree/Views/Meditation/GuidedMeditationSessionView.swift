//
//  GuidedMeditationSessionView.swift
//  CortiFree
//
//  Created by Claude on 24/10/2025.
//  Former text-based guided session: now plays the matching guided audio session.
//

import SwiftUI

struct GuidedMeditationSessionView: View {
    let support: MeditationSupport

    var body: some View {
        GuidedSessionAutoPlayView(session: GuidedSessionCatalog.session(forLegacyID: support.meditationId))
    }
}

#Preview {
    if let support = MeditationSupport.support(for: "body-scan") {
        GuidedMeditationSessionView(support: support)
    }
}
