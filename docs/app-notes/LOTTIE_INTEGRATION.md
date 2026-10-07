# Intégration Lottie - Instructions

## État actuel

Les fichiers Lottie JSON ont été copiés dans `Resources/Lottie/` et sont référencés dans `ConsequencesFlowView.swift`.

Pour le moment, `LottieView.swift` affiche des icônes SF Symbols en tant que placeholder.

## Fichiers Lottie disponibles

- `alerté.json` → Écran 1: "Le cortisol te maintient en alerte"
- `voleur sommeil.json` → Écran 2: "Le cortisol est un voleur de sommeil"
- `coeur épuisé.json` → Écran 3: "Le cortisol épuise ton cœur"
- `désorganise métabolisme.json` → Écran 4: "Le cortisol désorganise ton métabolisme"
- `anxiété.json` → Écran 5: "Le cortisol alimente l'anxiété"
- `corps affaiblit.json` → Écran 6: "Le cortisol affaiblit ton corps"

## Pour intégrer la vraie bibliothèque Lottie

### Étape 1: Ajouter le package via Xcode

1. Ouvrir Xcode
2. File → Add Package Dependencies
3. Rechercher: `https://github.com/airbnb/lottie-spm`
4. Sélectionner la version la plus récente
5. Ajouter à la target CortiFree

### Étape 2: Mettre à jour LottieView.swift

Remplacer le contenu actuel par:

```swift
import SwiftUI
import Lottie

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

struct LottieViewRepresentable: UIViewRepresentable {
    let filename: String
    let loopMode: LottieLoopMode

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)

        // Load animation from bundle
        if let animation = LottieAnimation.named(filename.replacingOccurrences(of: ".json", with: "")) {
            let animationView = LottieAnimationView(animation: animation)
            animationView.contentMode = .scaleAspectFit
            animationView.loopMode = loopMode == .loop ? .loop : .playOnce
            animationView.play()

            animationView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(animationView)

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

enum LottieLoopMode {
    case loop
    case playOnce
}
```

### Étape 3: Ajouter les fichiers au projet Xcode

1. Dans Xcode, clic droit sur le dossier `Resources`
2. Add Files to "CortiFree"...
3. Sélectionner tous les fichiers `.json` du dossier `Resources/Lottie/`
4. Cocher "Copy items if needed"
5. Cocher la target "CortiFree"

### Étape 4: Tester

Lancer l'app et naviguer vers les écrans de conséquences pour voir les animations Lottie en action.

## Notes

- Les animations sont configurées pour boucler en continu (`loopMode: .loop`)
- Chaque animation change avec la page grâce à `.id("lottie-\(currentPage)")`
- Les fichiers JSON sont optimisés et prêts à l'emploi
