# CortiFree iOS App

**Application de bien-être scientifique pour la gestion du stress et du cortisol**

## 🎯 Vue d'ensemble

CortiFree est une application iOS SwiftUI qui aide les utilisateurs à mesurer, comprendre et réguler leur stress à travers des routines quotidiennes, des exercices de respiration, et un système de progression gamifié.

## ✨ Fonctionnalités principales

### 🏠 HomeView
- Orbe gradient animé
- Indicateur de progression hebdomadaire (7 jours)
- Actions rapides (Respiration, Méditation)
- Barre de progression de niveau avec XP
- Bouton anti-stress d'urgence

### ✅ TasksView
- Gestion des tâches quotidiennes
- 3 catégories : Matin, Journée, Soir
- Swipe pour supprimer
- Animation confetti à 100%
- Système XP (+5 par tâche)
- Sync Firebase en temps réel

### 📚 LibraryView
- Sons relaxants (Pluie, Océan, Feu, Bruit blanc)
- Exercices de respiration (4-7-8, Box, Cohérence cardiaque)
- Mini-lecteur audio intégré
- Contrôles play/pause/stop

### 👤 ProfileView
- Avatar avec gradient orb
- Statistiques détaillées
- Graphique de progression (7j/30j/90j)
- Système de badges et achievements
- Compteur de séries (streak)

## 🛠 Technologies

- **Framework**: SwiftUI + Combine
- **Backend**: Firebase Firestore + Authentication
- **Architecture**: MVVM
- **Audio**: AVAudioPlayer
- **iOS Target**: 16.0+

## 📂 Structure du projet

```
CortiFree/
├── Models/           # Modèles de données (User, Task, Stats, Exercise)
├── Services/         # Firebase & Audio services
├── ViewModels/       # Logique métier MVVM
├── Views/            # Vues principales (Home, Tasks, Library, Profile)
├── Components/       # Composants UI réutilisables
└── Utilities/        # Extensions & helpers
```

## 🚀 Installation

1. **Cloner le projet**
   ```bash
   cd CortiFree
   ```

2. **Ajouter Firebase**
   - Placer `GoogleService-Info.plist` dans le dossier du projet
   - Firebase est déjà configuré dans `CortiFreeApp.swift`

3. **Ajouter les polices Poppins**
   - Ajouter les fichiers TTF/OTF au projet
   - Mettre à jour `Info.plist`:
   ```xml
   <key>UIAppFonts</key>
   <array>
       <string>Poppins-Bold.ttf</string>
       <string>Poppins-SemiBold.ttf</string>
       <string>Poppins-Medium.ttf</string>
       <string>Poppins-Regular.ttf</string>
   </array>
   ```

4. **Ajouter les fichiers audio**
   - Placer les MP3 dans le projet :
     - `rain.mp3`
     - `ocean.mp3`
     - `fire.mp3`
     - `whitenoise.mp3`

5. **Build & Run**
   ```bash
   Cmd + R dans Xcode
   ```

## 🎨 Design System

### Couleurs
- Background: `#1A1B3A` → `#0D0E1F`
- Accent: `#73DE85` → `#53D7D9`
- Primary: `#00FF88`

### Typographie
- Police: Poppins (Bold, SemiBold, Medium, Regular)
- Fallback: SF Pro

### Animations
- Durée standard: 0.3s
- Durée progression: 0.6s
- Spring animations avec response 0.3-0.8

## 🎮 Système XP & Niveaux

```swift
XP par tâche: +5
Niveau = (XP / 100) + 1
Progrès = (XP % 100) / 100
```

## 🔥 Structure Firebase

```
users/{userId}/
  ├── profile: { name, level, xp, goalType, ... }
  ├── tasks/{taskId}: { title, category, completed, ... }
  └── stats/main: { streak, history, totalTasksCompleted }
```

## 📱 Navigation

TabBar personnalisée avec 4 onglets:
1. **Accueil** - Dashboard principal
2. **Tâches** - Gestion des routines
3. **Librairie** - Exercices & Sons
4. **Profil** - Stats & Achievements

## 🔔 Fonctionnalités Haptic

- **Light**: Taps, sélections
- **Medium**: Suppressions
- **Heavy**: Level-ups, bouton anti-stress
- **Success**: Confetti, réussites

## 📊 Statistiques

- Taux de complétion quotidien
- Historique sur 90 jours
- Séries (streak) basées sur 80%+ de complétion
- Graphique animé avec 3 périodes (7j, 30j, 90j)

## 🧪 État du projet

### ✅ Complété
- Architecture MVVM complète
- 4 vues principales fonctionnelles
- Système XP & Levels
- Audio player
- Firebase sync
- Animations & haptics
- Composants réutilisables

### 🚧 À faire
- [ ] Authentification utilisateur
- [ ] Onboarding flow
- [ ] Push notifications
- [ ] Mode offline (Core Data)
- [ ] Tests unitaires
- [ ] Localisation
- [ ] Accessibilité complète

## 📝 Notes importantes

1. **Firebase Auth**: Le service Firebase est prêt mais l'UI d'authentification n'est pas implémentée
2. **Polices**: Poppins doit être ajoutée manuellement
3. **Audio**: Fichiers MP3 à ajouter au bundle
4. **Superwall**: Déjà intégré pour le paywall/subscriptions

## 🐛 Débogage

Si erreur de build:
1. Vérifier que `GoogleService-Info.plist` est bien ajouté
2. Vérifier que les polices sont dans Build Phases > Copy Bundle Resources
3. Vérifier que les fichiers audio sont dans le target

## 📚 Ressources

- [Documentation SwiftUI](https://developer.apple.com/documentation/swiftui)
- [Firebase iOS](https://firebase.google.com/docs/ios/setup)
- [Superwall SDK](https://docs.superwall.com/docs)

## 👨‍💻 Développement

Ce projet utilise:
- Xcode 15+
- Swift 5.9+
- iOS Deployment Target: 16.0

---

**Status**: ✅ Production-ready core features
**Version**: 1.0
**Last Updated**: 22 Octobre 2025
