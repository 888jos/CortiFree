//
//  WelcomeView.swift
//  CortiFree
//
//  Created by Claude on 07/11/2025.
//  Initial welcome screen before quiz flow
//

import SwiftUI

struct WelcomeView: View {
    var onContinue: () -> Void

    var body: some View {
        ZStack {
            // Galaxy background (same as rest of app)
            GalaxyBackgroundView()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Title and description at top
                VStack(alignment: .leading, spacing: 20) {
                    // Title (aligned left)
                    Text("Bienvenue!")
                        .font(.custom("Poppins-Bold", size: 32))
                        .foregroundColor(.white)

                    // Description (aligned left, max width 280)
                    Text("Commençons par voir si ton niveau de cortisol est plus élevé que tu ne le penses.")
                        .font(.custom("Poppins-Regular", size: 18))
                        .foregroundColor(.white.opacity(0.85))
                        .frame(maxWidth: 280, alignment: .leading)

                    // Social proof images (aligned horizontally)
                    HStack(spacing: 16) {
                        Image("welcome_5_stars")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 120, height: 50)
                            .clipped()

                        Image("welcome_cortifree_app")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 120, height: 50)
                            .clipped()
                    }
                    .padding(.top, 24)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 40)
                .padding(.top, 80)

                Spacer()

                // Continue button and time estimate (bottom right)
                VStack(spacing: 12) {
                    Button(action: {
                        HapticManager.light()
                        onContinue()
                    }) {
                        HStack(spacing: 12) {
                            Text("Débuter")
                                .font(.custom("Poppins-SemiBold", size: 16))
                                .foregroundColor(Color(hex: "1A1A4E"))

                            // White arrow in dark circle
                            ZStack {
                                Circle()
                                    .fill(Color(hex: "1A1A4E"))
                                    .frame(width: 32, height: 32)

                                Image(systemName: "arrow.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.vertical, 12)
                        .padding(.leading, 24)
                        .padding(.trailing, 12)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 40))
                    }

                    // Time estimate (centered below button)
                    Text("Prends 5 minutes")
                        .font(.custom("Poppins-Regular", size: 14))
                        .foregroundColor(.white.opacity(0.6))
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.horizontal, 40)
                .padding(.bottom, 50)
            }
        }
    }
}

#Preview {
    WelcomeView(onContinue: {})
}
