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

            // Pinned on all four edges: the animation fills exactly the frame it is
            // given. Its own (per-animation) size must never push the layout around it.
            for axis in [NSLayoutConstraint.Axis.horizontal, .vertical] {
                animationView.setContentHuggingPriority(.fittingSizeLevel, for: axis)
                animationView.setContentCompressionResistancePriority(.fittingSizeLevel, for: axis)
            }
            NSLayoutConstraint.activate([
                animationView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                animationView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                animationView.topAnchor.constraint(equalTo: view.topAnchor),
                animationView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
        }

        return view
    }

    /// Take exactly the size SwiftUI proposes, so the animation never feeds a
    /// size of its own back into the surrounding layout.
    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UIView, context: Context) -> CGSize? {
        guard let width = proposal.width, let height = proposal.height,
              width.isFinite, height.isFinite else { return nil }
        return CGSize(width: width, height: height)
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
