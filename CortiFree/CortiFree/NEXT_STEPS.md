# CortiFree - Prochaines Étapes

## 📋 Check-list de Déploiement

### 1. Ajout des Assets (PRIORITAIRE) ⚠️

#### Polices Poppins
- [ ] Télécharger Poppins depuis [Google Fonts](https://fonts.google.com/specimen/Poppins)
- [ ] Ajouter les fichiers .ttf au projet :
  - `Poppins-Bold.ttf`
  - `Poppins-SemiBold.ttf`
  - `Poppins-Medium.ttf`
  - `Poppins-Regular.ttf`
- [ ] Ajouter à `Info.plist` :
```xml
<key>UIAppFonts</key>
<array>
    <string>Poppins-Bold.ttf</string>
    <string>Poppins-SemiBold.ttf</string>
    <string>Poppins-Medium.ttf</string>
    <string>Poppins-Regular.ttf</string>
</array>
```
- [ ] Vérifier dans Build Phases > Copy Bundle Resources

#### Fichiers Audio
- [ ] Créer/télécharger les fichiers MP3 :
  - `rain.mp3` - Son de pluie ambiant
  - `ocean.mp3` - Vagues d'océan
  - `fire.mp3` - Crépitement de feu
  - `whitenoise.mp3` - Bruit blanc
- [ ] Ajouter au projet et au target
- [ ] Tester la lecture avec SoundPlayer

### 2. Configuration Firebase

#### Authentication
- [ ] Activer Email/Password Auth dans Console Firebase
- [ ] (Optionnel) Activer Google Sign-In
- [ ] Créer les vues de Login/Signup
- [ ] Gérer les états connecté/déconnecté
- [ ] Implémenter le logout
- [ ] Gérer la réinitialisation de mot de passe

#### Firestore Rules
- [ ] Configurer les règles de sécurité :
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;

      match /tasks/{taskId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }

      match /stats/{document=**} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
  }
}
```

#### Firestore Indexes
- [ ] Créer l'index pour `tasks` : `(userId, createdAt)`
- [ ] Tester les requêtes dans la Console

### 3. Onboarding Flow

- [ ] Créer WelcomeView
- [ ] Créer QuizView (diagnostic de stress)
- [ ] Créer OnboardingGoalView (sélection d'objectif)
- [ ] Créer NotificationPermissionView
- [ ] Intégrer le paywall Superwall
- [ ] Persister l'état onboarding (UserDefaults)
- [ ] Rediriger vers ContentView après onboarding

### 4. Push Notifications

- [ ] Activer Capabilities > Push Notifications
- [ ] Demander permission utilisateur
- [ ] Configurer Firebase Cloud Messaging
- [ ] Créer notifications locales pour :
  - Rappel tâches du matin (8h)
  - Rappel pause midi (12h30)
  - Rappel routine soir (20h)
- [ ] Implémenter badge count sur tab "Tâches"

### 5. Tests & QA

#### Tests Manuels
- [ ] Tester création de compte
- [ ] Tester login/logout
- [ ] Tester ajout/suppression de tâches
- [ ] Tester système XP et level-up
- [ ] Tester audio player (play/pause/stop)
- [ ] Tester stats sur différentes périodes
- [ ] Tester mode avion (erreurs réseau)
- [ ] Tester sur iPhone et iPad
- [ ] Tester rotation d'écran
- [ ] Tester avec VoiceOver

#### Tests Unitaires
- [ ] Écrire tests pour FirebaseService
- [ ] Écrire tests pour ViewModels
- [ ] Écrire tests pour système XP
- [ ] Tester calcul de streak

### 6. Optimisations

#### Performance
- [ ] Implémenter cache local (Core Data)
- [ ] Optimiser chargement images
- [ ] Lazy loading pour longues listes
- [ ] Compression audio si fichiers trop lourds

#### UX
- [ ] Ajouter skeleton screens pendant loading
- [ ] Améliorer gestion erreurs (AlertView)
- [ ] Ajouter états vides (empty states)
- [ ] Implémenter pull-to-refresh partout
- [ ] Ajouter vibration lors confetti
- [ ] Animation de breathing dans AntiStressView

### 7. Fonctionnalités Additionnelles (v1.1+)

#### Court terme
- [ ] Ajouter bouton "Ajouter tâche personnalisée"
- [ ] Timer pour exercices de respiration
- [ ] Mode sombre (déjà prévu dans design)
- [ ] Export des données (CSV/PDF)
- [ ] Partage sur réseaux sociaux

#### Moyen terme
- [ ] Widget iOS (progression du jour)
- [ ] Apple Watch app
- [ ] Intégration Apple Health
- [ ] Rappels intelligents (ML)
- [ ] Mode offline complet
- [ ] Synchronisation multi-device

#### Long terme
- [ ] Communauté / Social features
- [ ] Coach virtuel IA
- [ ] Programmes personnalisés
- [ ] Contenu premium (méditations pro)
- [ ] Intégration wearables

### 8. Marketing & Distribution

#### App Store
- [ ] Créer screenshots (5-8 images)
- [ ] Écrire description App Store (FR + EN)
- [ ] Créer icône app (1024x1024)
- [ ] Créer vidéo preview (optionnel)
- [ ] Choisir catégorie (Health & Fitness)
- [ ] Définir keywords pour ASO
- [ ] Créer site web/landing page
- [ ] Préparer Privacy Policy
- [ ] Préparer Terms of Service

#### Launch
- [ ] Beta testing avec TestFlight (20-30 users)
- [ ] Corriger bugs remontés
- [ ] Préparer stratégie de lancement
- [ ] Créer contenu réseaux sociaux
- [ ] Newsletter/email marketing
- [ ] Contacter influenceurs wellness

### 9. Analytics & Monitoring

- [ ] Implémenter Firebase Analytics
- [ ] Tracker événements clés :
  - Signup / Login
  - Task completed
  - Level up
  - Exercise started/completed
  - Paywall shown/converted
- [ ] Configurer Firebase Crashlytics
- [ ] Monitorer performance avec Xcode Instruments
- [ ] Créer dashboard analytics

### 10. Légal & Conformité

- [ ] RGPD compliance (UE)
- [ ] CCPA compliance (Californie)
- [ ] Privacy Policy détaillée
- [ ] Terms of Service
- [ ] Cookie policy (si web)
- [ ] Consentement tracking
- [ ] Droit à l'oubli (delete account)

## 🎯 Roadmap Suggérée

### Semaine 1-2: Setup & Assets
- ✅ Code de base (FAIT)
- [ ] Ajouter polices et audio
- [ ] Tester build sur device

### Semaine 3-4: Auth & Onboarding
- [ ] Flow d'authentification
- [ ] Onboarding complet
- [ ] Intégration paywall

### Semaine 5-6: Features & Polish
- [ ] Push notifications
- [ ] Tests complets
- [ ] Bug fixes
- [ ] Optimisations

### Semaine 7-8: Beta & Launch
- [ ] TestFlight beta
- [ ] Corrections finales
- [ ] App Store submission
- [ ] Launch! 🚀

## 📞 Support Technique

### En cas de problème

1. **Build errors**: Vérifier dépendances Firebase dans Package.swift
2. **Firestore errors**: Vérifier GoogleService-Info.plist
3. **Font errors**: Vérifier Info.plist et Build Phases
4. **Audio errors**: Vérifier que fichiers sont dans le bundle

### Ressources utiles
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [Firebase iOS Guide](https://firebase.google.com/docs/ios/setup)
- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)

---

**Note**: Cette liste est indicative. Adaptez selon vos priorités et ressources.

**Bonne chance avec CortiFree! 🍀**
