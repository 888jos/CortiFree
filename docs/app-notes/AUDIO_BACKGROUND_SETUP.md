# Configuration Audio en Arrière-plan

## Modifications Effectuées

### 1. SoundPlayer.swift
- ✅ Ajout de `totalPlayTime` pour tracker la durée totale de lecture
- ✅ Ajout de `playStartTime` et `accumulatedPlayTime` pour gérer les pauses
- ✅ Configuration de l'AVAudioSession pour la lecture en arrière-plan
- ✅ Mise à jour du timer pour calculer le temps total
- ✅ Ajout de `formattedTotalTime()` pour formater l'affichage

### 2. MiniPlayer.swift
- ✅ Ajout de l'affichage du timer à côté de la barre de progression
- ✅ Timer affiché en format MM:SS ou HH:MM:SS selon la durée

## Configuration Xcode Requise

Pour activer la lecture audio en arrière-plan, tu dois configurer les **Background Modes** dans Xcode:

### Étapes:

1. **Ouvre le projet dans Xcode**
   - Sélectionne le projet "CortiFree" dans le navigateur

2. **Sélectionne la target "CortiFree"**
   - Clique sur l'onglet "Signing & Capabilities"

3. **Ajoute Background Modes**
   - Clique sur "+ Capability"
   - Cherche et ajoute "Background Modes"

4. **Active "Audio, AirPlay, and Picture in Picture"**
   - Coche la case "Audio, AirPlay, and Picture in Picture"

### Fichier de Configuration

Alternativement, tu peux ajouter manuellement dans le fichier `Info.plist`:

```xml
<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
</array>
```

## Fonctionnalités

### Timer de Durée Totale
- Le timer affiche le temps total de lecture (même après pause/reprise)
- Format: MM:SS (moins d'1h) ou HH:MM:SS (1h ou plus)
- Couleur du thème de l'app pour une meilleure visibilité
- Police monospace pour une meilleure lisibilité

### Lecture en Arrière-plan
- L'audio continue de jouer quand l'app passe en arrière-plan
- Compatible avec le Control Center iOS
- Le timer continue de s'incrémenter même en arrière-plan

### Gestion des Pauses
- Le temps est accumulé entre les pauses
- Pause/reprise ne réinitialise pas le compteur
- Stop réinitialise complètement le timer

## Test

Pour tester:
1. Lance un son depuis la bibliothèque
2. Vérifie que le timer s'affiche et s'incrémente
3. Mets l'app en arrière-plan (bouton Home)
4. Le son doit continuer à jouer
5. Reviens dans l'app → le timer a continué à compter
6. Vérifie dans le Control Center que les contrôles audio sont visibles
