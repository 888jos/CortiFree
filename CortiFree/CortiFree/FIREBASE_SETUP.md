# 🔥 Configuration Firebase pour CortiFree

## Problème
```
Missing required module 'FirebaseFirestoreInternalWrapper'
```

Cette erreur signifie que les packages Firebase ne sont pas installés dans le projet.

## 📦 Solution : Ajouter Firebase via Swift Package Manager

### Méthode 1 : Via Xcode (RECOMMANDÉ)

1. **Ouvrir le projet dans Xcode**
   ```bash
   open /Users/jos/CortiFree/CortiFree/CortiFree.xcodeproj
   ```

2. **Ajouter le package Firebase**
   - Sélectionnez le projet **CortiFree** dans le navigateur (icône bleue)
   - Cliquez sur le projet (pas le target)
   - Allez dans l'onglet **"Package Dependencies"**
   - Cliquez sur le bouton **"+"** en bas à gauche

3. **Rechercher Firebase**
   - Dans la barre de recherche, collez :
     ```
     https://github.com/firebase/firebase-ios-sdk
     ```
   - Appuyez sur Entrée

4. **Sélectionner la version**
   - Dependency Rule : **"Up to Next Major Version"**
   - Version : **10.0.0** (ou la dernière disponible)
   - Cliquez sur **"Add Package"**

5. **Choisir les produits Firebase**
   Cochez UNIQUEMENT :
   - ✅ **FirebaseAuth**
   - ✅ **FirebaseFirestore**
   - ✅ **FirebaseAnalytics** (optionnel mais recommandé)

   ⚠️ NE PAS cocher tous les modules (trop lourd)

6. **Confirmer**
   - Target : **CortiFree**
   - Cliquez sur **"Add Package"**

7. **Attendre l'installation**
   - Xcode va télécharger les packages (peut prendre 1-2 minutes)
   - Une barre de progression apparaîtra en haut

8. **Vérifier l'installation**
   - Dans le navigateur de projet, sous **"Package Dependencies"**
   - Vous devriez voir **firebase-ios-sdk**

### Méthode 2 : Vérifier les dépendances existantes

Si Firebase est déjà installé mais ne se charge pas :

1. **Nettoyer le build**
   ```
   Product > Clean Build Folder
   ```
   Ou : `Cmd + Shift + K`

2. **Réinitialiser les caches**
   ```
   File > Packages > Reset Package Caches
   ```

3. **Résoudre les packages**
   ```
   File > Packages > Resolve Package Versions
   ```

4. **Rebuild le projet**
   ```
   Product > Build
   ```
   Ou : `Cmd + B`

### Méthode 3 : Si Xcode ne trouve pas le package

Si le bouton "+" ne montre pas les packages :

1. Fermez Xcode complètement
2. Supprimez le dossier DerivedData :
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData
   ```
3. Rouvrez le projet
4. Réessayez la Méthode 1

## ✅ Vérification

Après installation, ces imports devraient fonctionner :

```swift
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth
```

### Fichiers qui utilisent Firebase :
- ✅ `CortiFreeApp.swift` - Initialisation
- ✅ `Models/User.swift` - @DocumentID
- ✅ `Models/Task.swift` - @DocumentID, Timestamp
- ✅ `Models/UserStats.swift` - Timestamp
- ✅ `Services/FirebaseService.swift` - Firestore operations

## 🚨 Erreurs Courantes

### Erreur : "Missing required module"
**Solution** : Les packages ne sont pas installés
→ Suivre Méthode 1

### Erreur : "Module not found"
**Solution** : Mauvais import dans le target
→ Vérifier que les produits Firebase sont bien ajoutés au target CortiFree

### Erreur : "Cycle in dependencies"
**Solution** : Conflit de versions
→ File > Packages > Update to Latest Package Versions

### Build très lent
**Cause** : Trop de modules Firebase installés
→ Désinstaller les modules non utilisés (garder seulement Auth, Firestore, Analytics)

## 📋 Checklist

- [ ] Firebase iOS SDK ajouté dans Package Dependencies
- [ ] FirebaseAuth produit ajouté au target
- [ ] FirebaseFirestore produit ajouté au target
- [ ] GoogleService-Info.plist présent dans le projet
- [ ] Build réussi (Cmd + B)
- [ ] Aucune erreur d'import

## 🔍 Debug

Si le problème persiste :

1. **Vérifier les packages installés**
   ```
   File > Packages > Show Package Dependencies
   ```
   Devrait montrer : firebase-ios-sdk

2. **Vérifier le target**
   - Sélectionner le target **CortiFree**
   - Onglet **"General"**
   - Section **"Frameworks, Libraries, and Embedded Content"**
   - Devrait contenir :
     - FirebaseAuth
     - FirebaseFirestore

3. **Vérifier GoogleService-Info.plist**
   ```bash
   ls -la /Users/jos/CortiFree/CortiFree/CortiFree/ | grep GoogleService
   ```
   Le fichier doit être présent et ajouté au target

## 🆘 Besoin d'aide ?

Si rien ne fonctionne :

1. Fermez Xcode
2. Supprimez DerivedData :
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData
   ```
3. Supprimez le dossier .swiftpm :
   ```bash
   cd /Users/jos/CortiFree/CortiFree
   rm -rf .swiftpm
   ```
4. Rouvrez Xcode
5. Recommencez la Méthode 1

## 📚 Documentation Firebase

- [Firebase iOS Setup](https://firebase.google.com/docs/ios/setup)
- [Firebase iOS SDK GitHub](https://github.com/firebase/firebase-ios-sdk)
- [SwiftPM Integration](https://github.com/firebase/firebase-ios-sdk/blob/master/SwiftPackageManager.md)

---

**Une fois Firebase installé, le projet devrait compiler sans erreur ! 🎉**
