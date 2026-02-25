//
//  MotivationalMessageCard.swift
//  CortiFree
//
//  Created by Claude on 24/11/2025.
//  Motivational message card with time-based title and message
//

import SwiftUI

struct MotivationalMessageCard: View {
    @ObservedObject var viewModel: MotivationalMessageViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Time-based title with gradient text
            Text(viewModel.timeBasedTitle)
                .font(.faroBold(28))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color.white,
                            Color(hex: "8B5CF6")
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .multilineTextAlignment(.leading)

            // Motivational message
            Text(viewModel.currentMessage)
                .font(.custom("Poppins-Regular", size: 15))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.leading)
                .lineSpacing(6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 24)
        .padding(.horizontal, 24)
    }
}

#Preview {
    ZStack {
        GalaxyBackgroundView(intensity: 0.8)
            .ignoresSafeArea()

        MotivationalMessageCard(
            viewModel: MotivationalMessageViewModel()
        )
    }
}
