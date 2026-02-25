//
//  SocialProofFlowView.swift
//  CortiFree
//
//  Social proof screen before paywall
//  Shows rating breakdown, verified testimonials, and credibility logos
//

import SwiftUI

struct SocialProofFlowView: View {
    var onComplete: () -> Void
    @State private var screenViewTime: Date?

    // MARK: - Testimonial Data

    private var testimonials: [Testimonial] {
        [
            Testimonial(
                name: "Sophie M.",
                rating: 5,
                text: "social_proof.testimonial.sophie.text".localized,
                timeAgo: "social_proof.testimonial.sophie.time".localized,
                avatarColor: Color(hex: "B794F6")
            ),
            Testimonial(
                name: "social_proof.testimonial.james.name".localized,
                rating: 5,
                text: "social_proof.testimonial.james.text".localized,
                timeAgo: "social_proof.testimonial.james.time".localized,
                avatarColor: Color(hex: "53D7D9")
            ),
            Testimonial(
                name: "Claire D.",
                rating: 5,
                text: "social_proof.testimonial.claire.text".localized,
                timeAgo: "social_proof.testimonial.claire.time".localized,
                avatarColor: Color(hex: "FF8A80")
            ),
            Testimonial(
                name: "social_proof.testimonial.marc.name".localized,
                rating: 5,
                text: "social_proof.testimonial.marc.text".localized,
                timeAgo: "social_proof.testimonial.marc.time".localized,
                avatarColor: Color(hex: "4FC3F7")
            ),
            Testimonial(
                name: "Emma R.",
                rating: 5,
                text: "social_proof.testimonial.emma.text".localized,
                timeAgo: "social_proof.testimonial.emma.time".localized,
                avatarColor: Color(hex: "AED581")
            )
        ]
    }

    var body: some View {
        ZStack {
            GalaxyBackgroundView(intensity: 1.0)
                .ignoresSafeArea()

            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Title
                        Text("social_proof.title".localized)
                            .font(.faroBold(28))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .padding(.top, 70)
                            .padding(.horizontal, 32)

                        // User count
                        Text("social_proof.user_count".localized)
                            .font(.custom("Poppins-Regular", size: 14))
                            .foregroundColor(.white.opacity(0.5))
                            .padding(.top, 8)

                        // Testimonial cards
                        VStack(spacing: 14) {
                            ForEach(testimonials) { testimonial in
                                TestimonialCardView(testimonial: testimonial)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 24)

                        // Credibility logos
                        credibilityLogosSection
                            .padding(.top, 28)

                        Spacer()
                            .frame(height: 140)
                    }
                }

                // Continue button
                VStack(spacing: 0) {
                    LinearGradient(
                        colors: [Color.black.opacity(0), Color.black.opacity(0.8)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 30)

                    Button(action: {
                        HapticManager.light()
                        MixpanelManager.shared.trackOnboardingTestimonialsContinue()
                        onComplete()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.right")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color(hex: "1A1A4E"))

                            Text("social_proof.cta".localized)
                                .font(.custom("Poppins-SemiBold", size: 16))
                                .foregroundColor(Color(hex: "1A1A4E"))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 40))
                    }
                    .padding(.horizontal, 34)
                    .padding(.bottom, 40)
                    .background(Color.black.opacity(0.8))
                }
            }
        }
        .onAppear {
            screenViewTime = Date()
            MixpanelManager.shared.trackOnboardingTestimonialsViewed()
        }
    }

    // MARK: - Credibility Logos

    private var credibilityLogosSection: some View {
        VStack(spacing: 12) {
            Text("social_proof.based_on_research".localized)
                .font(.custom("Poppins-Regular", size: 12))
                .foregroundColor(.white.opacity(0.35))

            HStack(spacing: 20) {
                Image("logo_harvard")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 24)
                    .opacity(0.5)

                Image("logo_nih")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 24)
                    .opacity(0.5)

                Image("logo_ucl")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 24)
                    .opacity(0.5)
            }
        }
    }
}

// MARK: - Data Model

struct Testimonial: Identifiable {
    let id = UUID()
    let name: String
    let rating: Int
    let text: String
    let timeAgo: String
    let avatarColor: Color
}

// MARK: - Testimonial Card

struct TestimonialCardView: View {
    let testimonial: Testimonial

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header: avatar + name/date + verified badge
            HStack(spacing: 10) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(testimonial.avatarColor.opacity(0.25))
                        .frame(width: 40, height: 40)

                    Text(String(testimonial.name.prefix(1)))
                        .font(.custom("Poppins-Bold", size: 16))
                        .foregroundColor(testimonial.avatarColor)
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text(testimonial.name)
                        .font(.custom("Poppins-SemiBold", size: 14))
                        .foregroundColor(.white)

                    Text(testimonial.timeAgo)
                        .font(.custom("Poppins-Regular", size: 11))
                        .foregroundColor(.white.opacity(0.35))
                }

                Spacer()
            }

            // Stars
            HStack(spacing: 3) {
                ForEach(0..<testimonial.rating, id: \.self) { _ in
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "B794F6"))
                }
            }

            // Review text
            Text(testimonial.text)
                .font(.custom("Poppins-Regular", size: 13))
                .foregroundColor(.white.opacity(0.8))
                .lineSpacing(3)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(hex: "131146").opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }
}

#Preview {
    SocialProofFlowView(onComplete: {})
}
