//
//  ConsequencesFlowView.swift
//  CortiFree
//
//  Created by Claude on 31/10/2025.
//  6 screens showing cortisol consequences
//

import SwiftUI

struct ConsequencesFlowView: View {
    @State private var currentPage: Int = 0
    let onComplete: () -> Void

    private let consequences = [
        Consequence(
            title: "Le cortisol te maintient en alerte",
            description: "Il garde ton corps en alerte permanente en activant sans cesse ton système nerveux. Tu brûles ton énergie jusqu'à l'épuisement physique et mental complet.",
            lottieAnimation: "alerté.json"
        ),
        Consequence(
            title: "Le cortisol est un voleur de sommeil",
            description: "Il retarde l'endormissement et fragmente tes nuits. Tu te réveilles fatigué, le mental chargé et le corps non récupéré sans récupération réelle.",
            lottieAnimation: "voleur sommeil.json"
        ),
        Consequence(
            title: "Le cortisol épuise ton cœur",
            description: "Il maintient une tension artérielle élevée et force ton système cardiovasculaire à fonctionner en surrégime constant. Ce qui augmente les risques à long terme.",
            lottieAnimation: "coeur épuisé.json"
        ),
        Consequence(
            title: "Le cortisol désorganise ton métabolisme",
            description: "Il dérègle ta gestion de l'énergie, favorisant les fringales et le stockage de graisse. Tu subis des baisses brutales d'énergie après les repas et des envies sucrées constantes.",
            lottieAnimation: "désorganise métabolisme.json"
        ),
        Consequence(
            title: "Le cortisol alimente l'anxiété",
            description: "Il maintient ton esprit en danger constant, amplifiant ta réactivité face à chaque imprévu. Tu perçois les petits stress comme des menaces majeures et surréagis aux situations.",
            lottieAnimation: "anxiété.json"
        ),
        Consequence(
            title: "Le cortisol affaiblit ton corps",
            description: "Il supprime progressivement ton système immunitaire et accélère le vieillissement de tes cellules. Tu tombes plus facilement malade et récupères moins bien.",
            lottieAnimation: "corps affaibilit.json"
        )
    ]

    var body: some View {
        ZStack {
            // Background solid red
            Color(hex: "F50B1B")
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
                Text(consequences[currentPage].title)
                    .font(.custom("Poppins-Bold", size: 22))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 345)
                    .fixedSize(horizontal: false, vertical: true)
                    .id("title-\(currentPage)") // Force update

                Spacer()
                    .frame(height: 20)

                // Description (texte centré)
                Text(consequences[currentPage].description)
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
                        if currentPage < consequences.count - 1 {
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
            if let lottieFile = consequences[currentPage].lottieAnimation {
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
            ForEach(0..<consequences.count, id: \.self) { index in
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

            if currentPage < consequences.count - 1 {
                // Next page
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentPage += 1
                }
            } else {
                // Complete flow
                onComplete()
            }
        }) {
            Text(currentPage < consequences.count - 1 ? "Suivant →" : "Continuer")
                .font(.custom(
                    currentPage < consequences.count - 1 ? "Poppins-Medium" : "Poppins-SemiBold",
                    size: currentPage < consequences.count - 1 ? 14 : 16
                ))
                .foregroundColor(.black)
                .frame(width: currentPage < consequences.count - 1 ? 155 : 340, height: 54)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: currentPage < consequences.count - 1 ? 40 : 12))
        }
        .animation(.easeInOut(duration: 0.3), value: currentPage)
    }
}

// MARK: - Consequence Model

struct Consequence {
    let title: String
    let description: String
    let lottieAnimation: String? // Optional Lottie file name
}

#Preview {
    ConsequencesFlowView(onComplete: {})
}
