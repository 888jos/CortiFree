# Résolution des problèmes de Provisioning Profile

## Le problème

Xcode affiche deux erreurs :
1. **No Accounts**: Aucun compte Apple Developer configuré
2. **No profiles**: Aucun provisioning profile pour 'Josbiot.App.CortiFree'

## Solutions

### Option 1 : Utiliser un Apple ID gratuit (RECOMMANDÉ pour tester)

1. **Ajouter ton compte Apple dans Xcode :**
   - Ouvre Xcode
   - Va dans **Xcode → Settings** (ou Cmd+,)
   - Clique sur l'onglet **Accounts**
   - Clique sur le **+** en bas à gauche
   - Sélectionne **Apple ID**
   - Connecte-toi avec ton Apple ID (même gratuit)

2. **Configurer le projet :**
   - Ouvre le projet dans Xcode
   - Clique sur **CortiFree** dans le navigateur (fichier bleu en haut)
   - Dans l'onglet **Signing & Capabilities**
   - Coche **Automatically manage signing**
   - Dans **Team**, sélectionne ton compte (Personal Team)
   - Change le **Bundle Identifier** en quelque chose d'unique :
     - Par exemple : `com.josselin.CortiFree`
     - Ou : `com.yourname.CortiFree`

### Option 2 : Tester uniquement sur simulateur

Si tu veux juste tester sur simulateur (pas sur un vrai iPhone) :

1. Dans Xcode, sélectionne un simulateur dans la barre du haut
2. Tu peux compiler sans provisioning profile
3. Mais tu ne pourras pas installer sur un vrai iPhone

### Option 3 : Désactiver temporairement le signing

Pour compiler sans signing (juste pour tester) :

1. Dans **Build Settings** du projet
2. Cherche **Code Signing Identity**
3. Change à **Don't Code Sign**
4. ⚠️ Attention : L'app ne pourra pas être installée sur un appareil

## Étapes recommandées

1. **Ajoute ton Apple ID dans Xcode** (Settings → Accounts)
2. **Active "Automatically manage signing"** dans le projet
3. **Change le Bundle ID** pour quelque chose d'unique
4. **Sélectionne ton Personal Team**
5. **Build & Run** sur simulateur d'abord

## Bundle Identifier actuel

```
Josbiot.App.CortiFree
```

Tu devrais le changer en :
```
com.josselin.cortifree
```
ou
```
com.[tonnom].cortifree
```

## Test rapide

Après configuration, teste avec :
```bash
xcodebuild -list -project CortiFree.xcodeproj
```

Puis compile :
```bash
xcodebuild -scheme CortiFree -sdk iphonesimulator build
```