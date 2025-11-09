//
//  MeditationSupportView.swift
//  CortiFree
//
//  Created by Claude on 23/10/2025.
//  Vue simplifiée pour les exercices de méditation - Bénéfice + Lancer
//

import SwiftUI

struct MeditationSupportView: View {
    let support: MeditationSupport
    @Environment(\.dismiss) private var dismiss
    @State private var showGuidedSession = false
    @State private var pulseAnimation = false

    private var meditationIcon: String {
        switch support.supportType {
        case .instructions: return "list.bullet.circle.fill"
        case .journal: return "book.fill"
        case .guide: return "map.fill"
        case .tracker: return "chart.line.uptrend.xyaxis"
        case .visualGuide: return "eye.fill"
        case .affirmations: return "heart.text.square.fill"
        }
    }

    var body: some View {
        ZStack {
            // Galaxy background uniforme
            GalaxyBackgroundView(intensity: 0.8)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                header

                Spacer()

                // Content centré
                VStack(spacing: 40) {
                    // Hero icon
                    heroIcon

                    // Title
                    Text(support.title)
                        .font(.custom("Poppins-Bold", size: 28))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .shadow(color: Color.black.opacity(0.3), radius: 8, y: 4)
                        .padding(.horizontal, 32)

                    // Benefit card
                    benefitCard

                    // Launch button
                    launchButton
                }
                .padding(.horizontal, 24)

                Spacer()
            }
        }
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                pulseAnimation = true
            }
        }
        .fullScreenCover(isPresented: $showGuidedSession) {
            GuidedMeditationSessionView(support: support)
        }
    }

    // MARK: - Header
    private var header: some View {
        HStack {
            Button(action: {
                HapticManager.light()
                dismiss()
            }) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 44, height: 44)
                        .blur(radius: 8)

                    Circle()
                        .fill(Color(hex: "1A1B3A").opacity(0.9))
                        .frame(width: 44, height: 44)

                    Image(systemName: "chevron.left")
                        .font(.custom("Poppins-SemiBold", size: 18))
                        .foregroundColor(.white)
                }
            }

            Spacer()

            // Badge catégorie
            HStack(spacing: 6) {
                Image(systemName: "brain.head.profile")
                    .font(.custom("Poppins-SemiBold", size: 12))
                Text("MÉDITATION")
                    .font(.custom("Poppins-Bold", size: 11))
            }
            .foregroundColor(Color(hex: "B388FF"))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color(hex: "B388FF").opacity(0.15))
                    .overlay(
                        Capsule()
                            .stroke(Color(hex: "B388FF").opacity(0.4), lineWidth: 1)
                    )
            )
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
    }

    // MARK: - Hero Icon
    private var heroIcon: some View {
        ZStack {
            // Glow effect
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(hex: "B388FF").opacity(0.3), Color.clear],
                        center: .center,
                        startRadius: 20,
                        endRadius: 80
                    )
                )
                .frame(width: 160, height: 160)
                .scaleEffect(pulseAnimation ? 1.2 : 1.0)

            // Main icon circle
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "B388FF").opacity(0.3), Color(hex: "8C9EFF").opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 120, height: 120)
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [Color(hex: "B388FF"), Color(hex: "8C9EFF")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
                .shadow(color: Color(hex: "B388FF").opacity(0.3), radius: 20, y: 10)

            Image(systemName: meditationIcon)
                .font(.custom("Poppins-Medium", size: 50))
                .foregroundColor(.white)
        }
    }

    // MARK: - Benefit Card
    private var benefitCard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.custom("Poppins-SemiBold", size: 16))
                Text("Bénéfice")
                    .font(.custom("Poppins-SemiBold", size: 16))
                    .textCase(.uppercase)
                    .tracking(1.5)
            }
            .foregroundColor(Color(hex: "B388FF"))

            Text(support.benefit)
                .font(.custom("Poppins-Regular", size: 17))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .padding(.horizontal, 8)
        }
        .padding(.vertical, 28)
        .padding(.horizontal, 24)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 24)
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
                RoundedRectangle(cornerRadius: 24)
                    .stroke(
                        LinearGradient(
                            colors: [Color(hex: "B388FF").opacity(0.4), Color(hex: "8C9EFF").opacity(0.4)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            }
            .shadow(color: Color.black.opacity(0.3), radius: 15, y: 8)
        )
    }

    // MARK: - Launch Button
    private var launchButton: some View {
        Button(action: {
            HapticManager.medium()
            showGuidedSession = true
        }) {
            HStack(spacing: 12) {
                Image(systemName: "play.circle.fill")
                    .font(.custom("Poppins-SemiBold", size: 24))

                Text("Lancer la session")
                    .font(.custom("Poppins-Bold", size: 18))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 64)
            .background(
                ZStack {
                    // Shadow layer
                    RoundedRectangle(cornerRadius: 32)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "B388FF"), Color(hex: "8C9EFF")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .blur(radius: 20)
                        .offset(y: 8)

                    // Main button
                    RoundedRectangle(cornerRadius: 32)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "B388FF"), Color(hex: "8C9EFF")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

#Preview {
    if let support = MeditationSupport.support(for: "body-scan") {
        MeditationSupportView(support: support)
    }
}
