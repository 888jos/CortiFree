# 🔧 Fix: Erreur "Filename BreathingExerciseView.swift used twice"

## ❌ Erreur

```
CortiFree
Filename "BreathingExerciseView.swift" used twice:
'/Users/jos/CortiFree/CortiFree/CortiFree/Views/Breathing/BreathingExerciseView.swift'
and '/Users/jos/CortiFree/CortiFree/CortiFree/Views/AntiStress/BreathingExerciseView.swift'
```

## ✅ Solution

Le fichier `Views/Breathing/BreathingExerciseView.swift` a été correctement renommé en `LibraryBreathingView.swift`, mais **Xcode garde une référence fantôme dans son cache**.

### Étapes pour résoudre:

1. **Fermer complètement Xcode** (Cmd+Q)

2. **Nettoyer les caches Xcode** (déjà fait via terminal):
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData/*
   rm -f CortiFree.xcodeproj/project.xcworkspace/xcuserdata/*/UserInterfaceState.xcuserstate
   ```

3. **Rouvrir Xcode**

4. **Product > Clean Build Folder** (Cmd+Shift+K)

5. **Product > Build** (Cmd+B)

### Vérification

Si le problème persiste après avoir fermé/rouvert Xcode, vérifiez que le fichier n'existe vraiment pas:

```bash
find /Users/jos/CortiFree/CortiFree -name "BreathingExerciseView.swift"
```

**Résultat attendu:** Un seul fichier dans `Views/AntiStress/`

```
/Users/jos/CortiFree/CortiFree/CortiFree/Views/AntiStress/BreathingExerciseView.swift
```

Le fichier `LibraryBreathingView.swift` devrait être dans `Views/Breathing/`:

```bash
ls /Users/jos/CortiFree/CortiFree/CortiFree/Views/Breathing/
```

**Résultat attendu:**
```
LibraryBreathingView.swift
```

## 📁 Structure Correcte

```
Views/
├── AntiStress/
│   └── BreathingExerciseView.swift    ← Pour le flow Anti-Stress (animation scale)
└── Breathing/
    └── LibraryBreathingView.swift     ← Pour la Librairie (animation verticale)
```

## 🔍 Pourquoi cette erreur?

Xcode utilise un nouveau format de projet (`PBXFileSystemSynchronizedRootGroup`) qui synchronise automatiquement le filesystem. Mais parfois, quand un fichier est renommé en dehors de Xcode, le cache interne garde l'ancienne référence.

**La solution définitive:** Fermer et rouvrir Xcode pour forcer un refresh complet.

## ✅ Build Status via Terminal

Le build via ligne de commande **réussit déjà**:

```bash
cd /Users/jos/CortiFree/CortiFree
xcodebuild -project CortiFree.xcodeproj -scheme CortiFree -sdk iphonesimulator build
```

**Résultat:**
```
** BUILD SUCCEEDED **
```

Donc le problème est uniquement dans l'UI de Xcode qui a un cache obsolète.

## 🚀 Si le problème persiste

Si après fermeture/réouverture de Xcode l'erreur persiste:

1. **Supprimer le dossier Breathing et le recréer:**
   ```bash
   cd /Users/jos/CortiFree/CortiFree/CortiFree/Views
   rm -rf Breathing
   mkdir Breathing
   # Puis recopier LibraryBreathingView.swift
   ```

2. **Ou renommer temporairement le fichier dans Xcode:**
   - Ouvrir Xcode
   - Dans le navigateur de fichiers, clic droit sur `LibraryBreathingView.swift`
   - Rename... → `LibraryBreathingExerciseView.swift` (nom différent)
   - Mettre à jour les références dans le code si nécessaire

---

**Date:** 22 Octobre 2025
**Status:** ✅ Fichier correctement renommé, build terminal réussit
**Action requise:** Fermer et rouvrir Xcode
