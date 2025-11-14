//
//  RecoveryBenefitsFlowView.swift
//  CortiFree
//
//  Created by Claude on 31/10/2025.
//  6 screens showing recovery path and app benefits
//

import SwiftUI

struct RecoveryBenefitsFlowView: View {
    @State private var currentPage: Int = 0
    let onComplete: () -> Void

    private let benefits = [
            Benefit(
                title: "Chemin vers la récupération",
                description: "CortiFree t'aide à réapprendre à ralentir, à respirer et à retrouver ton équilibre naturel. Tu reprends le contrôle de ton bien-être avec des outils simples et efficaces au quotidien.",
                lottieAnimation: "récupération.json"
            ),
            Benefit(
                title: "Un cerveau plus calme",
                description: "Les exercices de respiration et de méditation guidés apaisent ton activité mentale. Tu retrouves une clarté d'esprit et une capacité à te concentrer sans effort mental épuisant.",
                lottieAnimation: "cerveau plus calme.json"
            ),
            Benefit(
                title: "Un sommeil qui redevient profond",
                description: "Les sons relaxants et les routines du soir t'aident à t'endormir plus facilement. Tu dors plus profondément et te réveilles avec une énergie claire et stable.",
                lottieAnimation: "sommeil profond.json"
            ),
            Benefit(
                title: "Un corps qui se détend",
                description: "Les pauses et les respirations guidées apaisent tes tensions. Tes muscles se détendent, ta respiration s'allège et ton corps retrouve un vrai relâchement.",
                lottieAnimation: "corps détendu.json"
            ),
            Benefit(
                title: "Une énergie plus stable",
                description: "En équilibrant ton stress, tu évites les pics et les chutes. Ton énergie devient stable, continue, et ton corps cesse de s'épuiser pour rien.",
                lottieAnimation: "énergie stable.json"
            ),
            Benefit(
                title: "Un équilibre qui devient naturel",
                description: "CortiFree t'accompagne pour que la sérénité devienne ton nouvel état par défaut. Les pratiques s'intègrent naturellement dans ta vie et transforment durablement ton rapport au stress.",
                lottieAnimation: "équilibre naturel.json"
        )
    ]

    var body: some View {
        ZStack {
            // Background bleu uni
            Color(hex: "1889EC")
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Icône positionnée pour que le titre soit au milieu de l'écran (400px)
                // 400px (titre au milieu) - 30px (spacing) - 240px (icône) = 130px
                Spacer()
                    .frame(height: 130)

                // Lottie animation (au-dessus du titre)
                lottieAnimationPlaceholder
                    .frame(width: 240, height: 240)
                    .clipped()

                Spacer()
                    .frame(height: 30)

                // Title au milieu de l'écran (400px)
                Text(benefits[currentPage].title)
                    .font(.custom("Poppins-Bold", size: 22))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 345)
                    .fixedSize(horizontal: false, vertical: true)
                    .id("title-\(currentPage)") // Force update

                Spacer()
                    .frame(height: 20)

                // Description (texte centré)
                Text(benefits[currentPage].description)
                    .font(.custom("Poppins-Medium", size: 12))
                    .foregroundColor(.white)
                    .lineSpacing(2)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 328)
                    .fixedSize(horizontal: false, vertical: true)
                    .id("description-\(currentPage)") // Force update

                Spacer() // Flexible spacer pour absorber la différence de hauteur du titre

                // Pagination dots (5px d'écart)
                paginationDots

                Spacer()
                    .frame(height: 30)

                // Next/Continue button
                nextButton

                Spacer()
                    .frame(height: 60)
            }
        }
        .gesture(
            DragGesture(minimumDistance: 50)
                .onEnded { value in
                    let horizontalSwipe = value.translation.width

                    if horizontalSwipe < -50 {
                        // Swipe left - next page
                        if currentPage < benefits.count - 1 {
                            HapticManager.light()
                            withAnimation(.easeInOut(duration: 0.3)) {
                                currentPage += 1
                            }
                        }
                    } else if horizontalSwipe > 50 {
                        // Swipe right - previous page
                        if currentPage > 0 {
                            HapticManager.light()
                            withAnimation(.easeInOut(duration: 0.3)) {
                                currentPage -= 1
                            }
                        }
                    }
                }
        )
    }

    // MARK: - Lottie Animation

    private var lottieAnimationPlaceholder: some View {
        Group {
            if let lottieFile = benefits[currentPage].lottieAnimation {
                LottieView(filename: lottieFile, loopMode: .loop)
            } else {
                // Fallback to SF Symbol
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                    Image(systemName: "circle")
                        .font(.system(size: 80))
                        .foregroundColor(.white)
                }
            }
        }
        .id("lottie-\(currentPage)")
    }

    // MARK: - Pagination Dots

    private var paginationDots: some View {
        HStack(spacing: 5) {  // 5px d'écart entre chaque dot
            ForEach(0..<benefits.count, id: \.self) { index in
                Circle()
                    .fill(index == currentPage ? Color.white : Color(hex: "5E5E5E"))
                    .frame(width: 8, height: 8)
                    .animation(.easeInOut(duration: 0.3), value: currentPage)
            }
        }
    }

    // MARK: - Next Button

    private var nextButton: some View {
        Button(action: {
            HapticManager.light()

            if currentPage < benefits.count - 1 {
                // Next page
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentPage += 1
                }
            } else {
                // Complete flow
                onComplete()
            }
        }) {
            Text(currentPage < benefits.count - 1 ? "Suivant →" : "Découvrir CortiFree")
                .font(.custom(
                    currentPage < benefits.count - 1 ? "Poppins-Medium" : "Poppins-SemiBold",
                    size: currentPage < benefits.count - 1 ? 14 : 16
                ))
                .foregroundColor(.black)
                .frame(width: currentPage < benefits.count - 1 ? 155 : 340, height: currentPage < benefits.count - 1 ? 54 : 56)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: currentPage < benefits.count - 1 ? 40 : 12))
        }
        .animation(.easeInOut(duration: 0.3), value: currentPage)
    }
}

// MARK: - Benefit Model

struct Benefit {
    let title: String
    let description: String
    let lottieAnimation: String? // Optional Lottie file name
}

#Preview {
    RecoveryBenefitsFlowView(onComplete: {})
}
