//
//  RatingSocialProofView.swift
//  CortiFree
//
//  Social proof screen with native App Store rating request.
//

import SwiftUI

struct RatingSocialProofView: View {
    let onContinue: () -> Void

    @ObservedObject private var languageManager = LanguageManager.shared

    private let reviews: [RatingProofReview] = [
        RatingProofReview(
            imageName: "testimonial_lisa",
            nameKey: "onboarding_v2.rating_proof.review_5_name",
            textKey: "onboarding_v2.rating_proof.review_5_text"
        ),
        RatingProofReview(
            imageName: "testimonial_sarah",
            nameKey: "onboarding_v2.rating_proof.review_1_name",
            textKey: "onboarding_v2.rating_proof.review_1_text"
        ),
        RatingProofReview(
            imageName: "testimonial_mike",
            nameKey: "onboarding_v2.rating_proof.review_2_name",
            textKey: "onboarding_v2.rating_proof.review_2_text"
        ),
        RatingProofReview(
            imageName: "testimonial_emma",
            nameKey: "onboarding_v2.rating_proof.review_3_name",
            textKey: "onboarding_v2.rating_proof.review_3_text"
        ),
        RatingProofReview(
            imageName: "testimonial_alex",
            nameKey: "onboarding_v2.rating_proof.review_4_name",
            textKey: "onboarding_v2.rating_proof.review_4_text"
        )
    ]

    var body: some View {
        let _ = languageManager.currentLanguage

        ZStack {
            GalaxyBackgroundView(intensity: 1.0)
            Color.black.opacity(0.28).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    VStack(spacing: 12) {
                        Text("onboarding_v2.rating_proof.title".localized)
                            .font(.faroBold(30))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white, Color(hex: "D4B4FF")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)

                        Text("onboarding_v2.rating_proof.subtitle".localized)
                            .font(.poppinsRegular(15))
                            .foregroundColor(.white.opacity(0.72))
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .padding(.horizontal, 8)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 72)

                    heroImage

                    VStack(spacing: 14) {
                        ForEach(reviews) { review in
                            RatingProofReviewCard(review: review)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 118)
                }
            }

            bottomButton
        }
        .ignoresSafeArea()
    }

    private var heroImage: some View {
        Image("testimonial_image")
            .resizable()
            .scaledToFit()
            .frame(maxWidth: 218)
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .shadow(color: Color(hex: "B794F6").opacity(0.22), radius: 24, y: 14)
            .padding(.top, 2)
    }

    private var bottomButton: some View {
        VStack {
            Spacer()

            Button(action: {
                HapticManager.medium()
                onContinue()

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    AppRatingService.shared.requestRating()
                }
            }) {
                HStack(spacing: 8) {
                    Text("onboarding_v2.rating_proof.cta".localized)
                        .font(.poppinsSemiBold(18))
                        .foregroundColor(.white)

                    Image(systemName: "arrow.right")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 28)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "B794F6"), Color(hex: "D4B4FF")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
                .shadow(color: Color(hex: "B794F6").opacity(0.35), radius: 16, y: 8)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
}

private struct RatingProofReview: Identifiable {
    let id = UUID()
    let imageName: String
    let nameKey: String
    let textKey: String
}

private struct RatingProofReviewCard: View {
    let review: RatingProofReview

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(review.imageName)
                .resizable()
                .scaledToFill()
                .frame(width: 52, height: 52)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.72), lineWidth: 1.2)
                )
                .shadow(color: Color.black.opacity(0.24), radius: 8, y: 4)

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    Text(review.nameKey.localized)
                        .font(.poppinsSemiBold(15))
                        .foregroundColor(.white)

                    Spacer(minLength: 8)

                    HStack(spacing: 2) {
                        ForEach(0..<5, id: \.self) { _ in
                            Image(systemName: "star.fill")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(Color(hex: "D4B4FF"))
                        }
                    }
                    .padding(.top, 2)
                }

                Text(review.textKey.localized)
                    .font(.poppinsRegular(13))
                    .foregroundColor(.white.opacity(0.74))
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(15)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(hex: "131146").opacity(0.78))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
    }
}

#Preview {
    RatingSocialProofView(onContinue: {})
}
