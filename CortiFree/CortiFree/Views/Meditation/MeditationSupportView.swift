//
//  MeditationSupportView.swift
//  CortiFree
//
//  Created by Claude on 23/10/2025.
//  Meditations are now guided AUDIO sessions: this entry point (used by the assistant,
//  lists and legacy flows) opens the audio session page for the mapped session.
//

import SwiftUI

struct MeditationSupportView: View {
    let support: MeditationSupport

    var body: some View {
        if let session = GuidedSessionCatalog.session(forLegacyID: support.meditationId) {
            GuidedSessionDetailView(session: session)
        } else {
            MeditationListView()
        }
    }
}

#Preview {
    if let support = MeditationSupport.support(for: "body-scan") {
        MeditationSupportView(support: support)
    }
}

// MARK: - Meditation Benefit Badge Component

struct MeditationBenefitBadge: View {
    let benefit: String
    let index: Int

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.appTheme, Color.appThemeSecondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 24, height: 24)

                Image(systemName: "checkmark")
                    .font(.custom("Poppins-Bold", size: 12))
                    .foregroundColor(.white)
            }

            Text(benefit)
                .font(.custom("Poppins-Medium", size: 14))
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: "1A1B3A").opacity(0.8),
                                Color(hex: "2A2B5A").opacity(0.6)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.appTheme.opacity(0.3),
                                Color.appThemeSecondary.opacity(0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
        )
    }
}
