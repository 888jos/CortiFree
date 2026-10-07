# 🔧 FIX : "Missing required module 'FirebaseFirestoreInternalWrapper'"

## ⚡ Solution Rapide (3 minutes)

### Dans Xcode :

1. **Ouvrir le projet**
   ```bash
   open /Users/jos/CortiFree/CortiFree/CortiFree.xcodeproj
   ```

2. **Ajouter Firebase Package**
   - Cliquez sur le projet **CortiFree** (icône bleue en haut)
   - Onglet **"Package Dependencies"**
   - Cliquez sur le **"+"**
   - Collez : `https://github.com/firebase/firebase-ios-sdk`
   - Cliquez **"Add Package"**

3. **Sélectionner les modules**
   - Cochez : **FirebaseAuth**
   - Cochez : **FirebaseFirestore**
   - Cliquez **"Add Package"**

4. **Attendre 1-2 minutes** (téléchargement)

5. **Build**
   - `Cmd + B`
   - ✅ Devrait compiler !

## 🎯 Résumé

**Problème** : Firebase n'est pas installé via Swift Package Manager
**Solution** : Ajouter firebase-ios-sdk comme dépendance
**Temps** : 3 minutes max

---

Si ça ne marche pas, consultez [FIREBASE_SETUP.md](FIREBASE_SETUP.md) pour plus de détails.
