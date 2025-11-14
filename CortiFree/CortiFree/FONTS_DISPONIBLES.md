# Fonts Disponibles dans CortiFree

## Faro (Fichiers avec "Lucky" dans le nom)
Utilise **"Faro"** comme nom de famille de font :

- `Faro-RegularLucky.ttf` → `.font(.custom("Faro-RegularLucky", size: X))`
- `Faro-LightLucky.ttf` → `.font(.custom("Faro-LightLucky", size: X))`
- `Faro-SemiBoldLucky.ttf` → `.font(.custom("Faro-SemiBoldLucky", size: X))`
- `Faro-BoldLucky.ttf` → `.font(.custom("Faro-BoldLucky", size: X))`
- `Faro-DisplayLucky.ttf` → `.font(.custom("Faro-DisplayLucky", size: X))`

## Hanken Grotesk
Utilise **"HankenGrotesk"** comme nom de famille de font :

### Weights Standards
- `HankenGrotesk-Thin.ttf` → `.font(.custom("HankenGrotesk-Thin", size: X))`
- `HankenGrotesk-ExtraLight.ttf` → `.font(.custom("HankenGrotesk-ExtraLight", size: X))`
- `HankenGrotesk-Light.ttf` → `.font(.custom("HankenGrotesk-Light", size: X))`
- `HankenGrotesk-Regular.ttf` → `.font(.custom("HankenGrotesk-Regular", size: X))`
- `HankenGrotesk-Medium.ttf` → `.font(.custom("HankenGrotesk-Medium", size: X))`
- `HankenGrotesk-SemiBold.ttf` → `.font(.custom("HankenGrotesk-SemiBold", size: X))`
- `HankenGrotesk-Bold.ttf` → `.font(.custom("HankenGrotesk-Bold", size: X))`
- `HankenGrotesk-ExtraBold.ttf` → `.font(.custom("HankenGrotesk-ExtraBold", size: X))`
- `HankenGrotesk-Black.ttf` → `.font(.custom("HankenGrotesk-Black", size: X))`

### Weights Italic
- `HankenGrotesk-ThinItalic.ttf` → `.font(.custom("HankenGrotesk-ThinItalic", size: X))`
- `HankenGrotesk-ExtraLightItalic.ttf` → `.font(.custom("HankenGrotesk-ExtraLightItalic", size: X))`
- `HankenGrotesk-LightItalic.ttf` → `.font(.custom("HankenGrotesk-LightItalic", size: X))`
- `HankenGrotesk-Italic.ttf` → `.font(.custom("HankenGrotesk-Italic", size: X))`
- `HankenGrotesk-MediumItalic.ttf` → `.font(.custom("HankenGrotesk-MediumItalic", size: X))`
- `HankenGrotesk-SemiBoldItalic.ttf` → `.font(.custom("HankenGrotesk-SemiBoldItalic", size: X))`
- `HankenGrotesk-BoldItalic.ttf` → `.font(.custom("HankenGrotesk-BoldItalic", size: X))`
- `HankenGrotesk-ExtraBoldItalic.ttf` → `.font(.custom("HankenGrotesk-ExtraBoldItalic", size: X))`
- `HankenGrotesk-BlackItalic.ttf` → `.font(.custom("HankenGrotesk-BlackItalic", size: X))`

## Exemples d'utilisation dans SwiftUI

```swift
// Faro
Text("Hello World")
    .font(.custom("Faro-RegularLucky", size: 16))

Text("Bold Text")
    .font(.custom("Faro-BoldLucky", size: 18))

// Hanken Grotesk
Text("Hello World")
    .font(.custom("HankenGrotesk-Regular", size: 16))

Text("SemiBold Text")
    .font(.custom("HankenGrotesk-SemiBold", size: 18))
```

## Notes importantes
- Les fonts ont été configurées et sont maintenant disponibles dans tout le projet
- Utilise le nom exact du fichier (sans l'extension .ttf) dans `.custom()`
- Toutes les fonts sont déjà enregistrées dans le projet CortiFree
