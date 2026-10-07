# Fix Build - 448 Erreurs "Multiple commands produce"

## Problème
Les erreurs "Multiple commands produce" indiquent que plusieurs targets ou build phases tentent de copier les mêmes fichiers.

## Solution Rapide dans Xcode

### Option 1 : Build Settings (Recommandé)
1. **Ouvre Xcode** (déjà ouvert)
2. **Clique sur le projet CortiFree** (icône bleue)
3. **Sélectionne la target "CortiFree"**
4. **Build Settings** (onglet)
5. **Cherche** "ENABLE_USER_SCRIPT_SANDBOXING"
6. **Change de** `Yes` **à** `No`

### Option 2 : Unique Output File Names
1. **Build Settings** → Cherche "DUPLICATE_FILE_AGGREGATION"
2. **Change** la valeur

### Option 3 : Clean Complète
```bash
# Terminal
cd /Users/jos/CortiFree
rm -rf ~/Library/Developer/Xcode/DerivedData/CortiFree-*
rm -rf CortiFree/build
```

Puis dans Xcode:
- Product → Clean Build Folder (⌘ + Shift + K)
- Product → Build (⌘ + B)

## Cause Probable
Ces erreurs apparaissent souvent après:
- Mise à jour Xcode
- Changements dans Swift Package Manager
- Targets multiples qui référencent les mêmes ressources

## Alternative : Build depuis Terminal
```bash
cd /Users/jos/CortiFree
xcodebuild clean build \
  -project CortiFree.xcodeproj \
  -scheme CortiFree \
  -configuration Debug \
  -sdk iphonesimulator \
  -derivedDataPath ./build \
  CODE_SIGNING_ALLOWED=NO
```

---

**Note**: Ces erreurs n'ont RIEN À VOIR avec le code Achievement que j'ai créé.
C'est un problème de configuration build Xcode.
