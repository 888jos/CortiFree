# Fonctionnalité de Sélection de Durée Audio

## Vue d'ensemble

L'utilisateur peut maintenant sélectionner combien de temps un son doit jouer. Le son s'arrêtera automatiquement à la fin de la durée choisie.

## Fonctionnalités Ajoutées

### 1. Sélection de Durée
- **Options disponibles:**
  - Infini (par défaut)
  - 5 minutes
  - 10 minutes
  - 15 minutes
  - 30 minutes
  - 45 minutes
  - 1 heure
  - 2 heures

### 2. Interface Utilisateur

#### MiniPlayer
- **Clic sur le timer** → Ouvre le sélecteur de durée
- **Affichage intelligent:**
  - Si durée = infinie → Affiche temps écoulé (ex: 05:23)
  - Si durée sélectionnée → Affiche temps restant (ex: 04:37)

#### Barre de Progression
- **Mode Infini:** Barre basée sur la longueur du fichier audio
- **Mode Durée:** Barre basée sur le temps écoulé / durée totale

#### Sheet de Sélection
- Grille 2 colonnes avec toutes les durées
- Sélection visuelle (checkmark + couleur thème)
- Fermeture automatique après sélection
- Haptic feedback

### 3. Logique d'Arrêt Automatique
- Le timer vérifie toutes les 0.1s si la durée est atteinte
- Arrêt automatique propre (sans coupure brutale)
- Réinitialisation de la durée au stop

## Fichiers Modifiés

### Services/SoundPlayer.swift
```swift
@Published var selectedDuration: TimeInterval? = nil
```
- Ajout de la propriété `selectedDuration`
- Vérification dans le timer pour arrêt automatique
- Réinitialisation dans `stop()`

### Components/MiniPlayer.swift
- Ajout du sélecteur de durée (sheet)
- Fonctions `timerText()` et `progressValue()`
- Composant `DurationPickerSheet`
- Composant `DurationButton`

## Utilisation

1. **Lancer un son** depuis la bibliothèque
2. **Cliquer sur le timer** dans le MiniPlayer
3. **Sélectionner une durée** (ou Infini)
4. Le son s'arrêtera automatiquement à la fin

## Comportement

### Mode Infini (par défaut)
- Le son joue en boucle indéfiniment
- Timer affiche le temps écoulé total
- Barre de progression basée sur la durée du fichier

### Mode Durée Sélectionnée
- Le son joue en boucle jusqu'à la durée limite
- Timer affiche le temps RESTANT
- Barre de progression remplie progressivement
- Arrêt automatique à 0:00

## Exemples

### Scénario 1: Méditation de 10 minutes
1. Lancer un son "Ocean"
2. Cliquer sur le timer
3. Sélectionner "10 min"
4. Le timer affiche "10:00" et décrémente
5. À 0:00, le son s'arrête automatiquement

### Scénario 2: Musique d'ambiance continue
1. Lancer un son "Pluie"
2. Cliquer sur le timer
3. Sélectionner "Infini"
4. Le timer affiche le temps écoulé (00:00, 00:01, ...)
5. Le son continue jusqu'à ce que l'utilisateur l'arrête

## Design

- **Couleurs:** Thème de l'app (gradient violet/bleu)
- **Animations:** Spring animations pour les sélections
- **Haptics:** Feedback léger à chaque interaction
- **Typography:** Poppins (cohérent avec l'app)

## Améliorations Futures Possibles

- [ ] Fade out progressif avant l'arrêt automatique
- [ ] Notification push quand le timer se termine
- [ ] Statistiques de temps d'écoute par jour
- [ ] Durées personnalisées (slider)
- [ ] Presets sauvegardés par son
