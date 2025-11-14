# 🔴 SOLUTION : Erreur "Missing required module 'FirebaseFirestoreInternalWrapper'"

## 🎯 Le Problème

Firebase est partiellement installé (GoogleUtilities, etc.) mais le module **FirebaseFirestore** principal est manquant.

## ✅ Solution Complète (5 minutes)

### Étape 1 : Ouvrir le projet dans Xcode

```bash
cd /Users/jos/CortiFree/CortiFree
open CortiFree.xcodeproj
```

### Étape 2 : Ajouter firebase-ios-sdk

1. Dans Xcode, sélectionnez le **projet CortiFree** (icône bleue en haut du navigateur)
2. Allez dans l'onglet **"Package Dependencies"**
3. Vérifiez si **firebase-ios-sdk** est dans la liste :

#### Si firebase-ios-sdk est ABSENT :
   - Cliquez sur le bouton **"+"** en bas
   - Collez cette URL :
     ```
     https://github.com/firebase/firebase-ios-sdk
     ```
   - Appuyez sur Entrée
   - Sélectionnez **"Up to Next Major Version"** : **10.0.0**
   - Cliquez **"Add Package"**
   - Dans la liste des produits, cochez :
     - ✅ **FirebaseAuth**
     - ✅ **FirebaseFirestore**
   - Cliquez **"Add Package"**
   - Attendez le téléchargement (1-2 minutes)

#### Si firebase-ios-sdk est PRÉSENT mais l'erreur persiste :
   - Sélectionnez **firebase-ios-sdk** dans la liste
   - Cliquez sur le bouton **"-"** pour le supprimer
   - Confirmez la suppression
   - Attendez quelques secondes
   - Recommencez en ajoutant le package (voir ci-dessus)

### Étape 3 : Vérifier le Target

1. Sélectionnez le **target CortiFree** (pas le projet, mais le target sous le projet)
2. Allez dans l'onglet **"General"**
3. Scrollez jusqu'à la section **"Frameworks, Libraries, and Embedded Content"**
4. Vérifiez que ces frameworks sont présents :
   - FirebaseAuth
   - FirebaseFirestore

5. S'ils sont absents, cliquez sur le **"+"** et ajoutez-les manuellement

### Étape 4 : Clean Build

1. Dans Xcode :
   ```
   Product > Clean Build Folder
   ```
   Ou : `Cmd + Shift + K`

2. Réinitialisez les packages :
   ```
   File > Packages > Reset Package Caches
   ```

3. Résolvez les packages :
   ```
   File > Packages > Resolve Package Versions
   ```

### Étape 5 : Rebuild

1. Build le projet :
   ```
   Product > Build
   ```
   Ou : `Cmd + B`

2. Si le build réussit, lancez l'app :
   ```
   Product > Run
   ```
   Ou : `Cmd + R`

## 🔍 Vérification des Imports

Après le fix, ces imports dans vos fichiers devraient fonctionner sans erreur :

**CortiFreeApp.swift**
```swift
import FirebaseCore  // ✅ Doit compiler
```

**Models/User.swift**
```swift
import FirebaseFirestore  // ✅ Doit compiler
```

**Services/FirebaseService.swift**
```swift
import FirebaseFirestore  // ✅ Doit compiler
import FirebaseAuth        // ✅ Doit compiler
```

## 🚨 Si ça ne marche toujours pas

### Option A : Nettoyage complet

```bash
# Fermer Xcode d'abord !
cd /Users/jos/CortiFree/CortiFree

# Supprimer les caches
rm -rf ~/Library/Developer/Xcode/DerivedData

# Supprimer les packages locaux
rm -rf .swiftpm
rm -rf CortiFree.xcodeproj/project.xcworkspace/xcshareddata/swiftpm

# Rouvrir Xcode
open CortiFree.xcodeproj

# Attendre que Xcode résolve les packages
# Puis : Product > Build
```

### Option B : Vérifier la version d'Xcode

```bash
xcodebuild -version
```

Firebase iOS SDK nécessite :
- Xcode 15.0 ou supérieur
- Swift 5.9 ou supérieur

Si votre Xcode est plus ancien, mettez-le à jour depuis l'App Store.

### Option C : Utiliser CocoaPods (Alternative)

Si Swift Package Manager pose problème, vous pouvez utiliser CocoaPods :

1. Fermez Xcode
2. Créez un `Podfile` :
   ```bash
   cd /Users/jos/CortiFree/CortiFree
   pod init
   ```
3. Éditez le Podfile :
   ```ruby
   platform :ios, '16.0'

   target 'CortiFree' do
     use_frameworks!

     pod 'Firebase/Auth'
     pod 'Firebase/Firestore'
     pod 'Firebase/Analytics'
   end
   ```
4. Installez :
   ```bash
   pod install
   ```
5. Ouvrez le workspace (pas le projet) :
   ```bash
   open CortiFree.xcworkspace
   ```

## ✅ Checklist Finale

Avant de considérer que c'est réglé, vérifiez :

- [ ] firebase-ios-sdk visible dans Package Dependencies
- [ ] FirebaseAuth et FirebaseFirestore cochés dans le target
- [ ] GoogleService-Info.plist présent dans le projet
- [ ] Clean Build réussi (Cmd+Shift+K puis Cmd+B)
- [ ] Aucune erreur rouge dans l'éditeur
- [ ] L'app se lance (Cmd+R)

## 📚 Ressources

- [Firebase iOS Setup Guide](https://firebase.google.com/docs/ios/setup)
- [Swift Package Manager Firebase](https://github.com/firebase/firebase-ios-sdk/blob/master/SwiftPackageManager.md)
- [Troubleshooting Firebase](https://firebase.google.com/docs/ios/troubleshooting)

---

**Une fois réglé, votre projet devrait compiler sans erreur ! 🎉**

Si vous avez encore des problèmes, partagez le message d'erreur exact.
