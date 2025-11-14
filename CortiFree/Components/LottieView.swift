//
//  LottieView.swift
//  CortiFree
//
//  Created by Claude on 05/11/2025.
//  Lottie animation wrapper
//

import SwiftUI
import Lottie

// MARK: - Lottie View Wrapper

struct LottieView: View {
    let filename: String
    let loopMode: LottieLoopMode

    init(filename: String, loopMode: LottieLoopMode = .loop) {
        self.filename = filename
        self.loopMode = loopMode
    }

    var body: some View {
        LottieViewRepresentable(filename: filename, loopMode: loopMode)
    }
}

// MARK: - UIViewRepresentable for Lottie

struct LottieViewRepresentable: UIViewRepresentable {
    let filename: String
    let loopMode: LottieLoopMode

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .clear // Transparent background

        // Load animation from bundle
        let animationName = filename.replacingOccurrences(of: ".json", with: "")

        if let animation = LottieAnimation.named(animationName) {
            let animationView = LottieAnimationView(animation: animation)
            animationView.contentMode = .scaleAspectFill // Rogne au maximum pour remplir
            animationView.loopMode = loopMode == .loop ? .loop : .playOnce
            animationView.backgroundBehavior = .pauseAndRestore
            animationView.backgroundColor = .clear // Transparent background

            // Méthode avancée pour supprimer le fond blanc
            // 1. Utiliser multiply blend mode
            animationView.layer.compositingFilter = "multiplyBlendMode"

            // 2. Ajouter un filtre pour rendre les zones blanches/claires plus transparentes
            if let filter = CIFilter(name: "CIColorControls") {
                animationView.layer.filters = [filter]
            }

            // 3. Réduire légèrement l'opacité pour mieux fusionner avec le fond
            animationView.alpha = 0.95

            animationView.play()

            animationView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(animationView)
            view.clipsToBounds = true // Important pour rogner les débordements

            NSLayoutConstraint.activate([
                animationView.heightAnchor.constraint(equalTo: view.heightAnchor),
                animationView.widthAnchor.constraint(equalTo: view.widthAnchor)
            ])
        }

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // Update if needed
    }
}

// MARK: - Loop Mode Enum

enum LottieLoopMode {
    case loop
    case playOnce
}

#Preview {
    ZStack {
        Color.red
            .ignoresSafeArea()

        LottieView(filename: "alerté.json", loopMode: .loop)
            .frame(width: 180, height: 180)
    }
}
