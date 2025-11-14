# 🔥 Guide d'Installation Firebase + Mixpanel pour CortiFree

## Table des Matières
1. [Configuration Firebase](#1-configuration-firebase)
2. [Installation des SDKs](#2-installation-des-sdks)
3. [Configuration Firestore](#3-configuration-firestore)
4. [Security Rules](#4-security-rules)
5. [Indexes](#5-indexes)
6. [Configuration Mixpanel](#6-configuration-mixpanel)
7. [Test et Vérification](#7-test-et-vérification)

---

## 1. Configuration Firebase

### Étape 1.1: Créer un Projet Firebase

1. Va sur [Firebase Console](https://console.firebase.google.com/)
2. Clique sur "Ajouter un projet"
3. Nomme le projet "CortiFree" (ou ton nom choisi)
4. Active Google Analytics (optionnel mais recommandé)
5. Crée le projet

### Étape 1.2: Ajouter une App iOS

1. Dans la console Firebase, clique sur l'icône iOS
2. **Bundle ID**: Utilise le même que ton projet Xcode (probablement `com.cortifree.CortiFree`)
3. **App nickname**: CortiFree
4. **App Store ID**: Laisse vide pour l'instant
5. Télécharge le fichier `GoogleService-Info.plist`

### Étape 1.3: Ajouter GoogleService-Info.plist au Projet

1. Ouvre Xcode
2. Fais glisser `GoogleService-Info.plist` dans le dossier `CortiFree` (à côté de `CortiFreeApp.swift`)
3. ⚠️ **IMPORTANT**: Assure-toi de cocher "Copy items if needed" et "Add to targets: CortiFree"

---

## 2. Installation des SDKs

### Étape 2.1: Ajouter Firebase via Swift Package Manager

1. Dans Xcode, va dans **File → Add Package Dependencies...**
2. Colle cette URL: `https://github.com/firebase/firebase-ios-sdk`
3. Version: **Latest** (ou spécifie `10.20.0` minimum)
4. Sélectionne les packages suivants:
   - ✅ **FirebaseAuth**
   - ✅ **FirebaseFirestore**
   - ✅ **FirebaseFirestoreSwift**
   - ✅ **FirebaseAnalytics** (optionnel)
5. Clique sur "Add Package"

### Étape 2.2: Ajouter Mixpanel via Swift Package Manager

1. Dans Xcode, va dans **File → Add Package Dependencies...**
2. Colle cette URL: `https://github.com/mixpanel/mixpanel-swift`
3. Version: **Latest** (ou spécifie `4.2.0` minimum)
4. Sélectionne le package **Mixpanel**
5. Clique sur "Add Package"

### Étape 2.3: Initialiser Firebase dans CortiFreeApp.swift

```swift
import SwiftUI
import FirebaseCore

@main
struct CortiFreeApp: App {
    @StateObject private var authManager = AuthManager.shared

    init() {
        // Configure Firebase
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
        }
    }
}
```

---

## 3. Configuration Firestore

### Étape 3.1: Activer Firestore

1. Dans la Firebase Console, va dans **Firestore Database**
2. Clique sur "Créer une base de données"
3. Mode: **Production** (on ajoutera les rules après)
4. Localisation: **europe-west1** (ou le plus proche de toi)
5. Clique sur "Activer"

### Étape 3.2: Activer Authentication

1. Dans Firebase Console, va dans **Authentication**
2. Clique sur "Commencer"
3. Dans l'onglet "Sign-in method", active:
   - ✅ **E-mail/Mot de passe**
   - ✅ **Google** (optionnel)
   - ✅ **Apple** (recommandé pour iOS)

---

## 4. Security Rules

### Étape 4.1: Configurer les Firestore Rules

1. Dans Firebase Console, va dans **Firestore Database → Règles**
2. Remplace le contenu par:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }

    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }

    // Global content (read-only for authenticated users)
    match /routines/{routineId} {
      allow read: if isAuthenticated();
      allow write: if false; // Only via Admin SDK

      match /{document=**} {
        allow read: if isAuthenticated();
        allow write: if false;
      }
    }

    match /exercises/{exerciseId} {
      allow read: if isAuthenticated();
      allow write: if false;
    }

    match /meditation_supports/{supportId} {
      allow read: if isAuthenticated();
      allow write: if false;

      match /{document=**} {
        allow read: if isAuthenticated();
      }
    }

    match /onboarding_questions/{questionId} {
      allow read: if isAuthenticated();
      allow write: if false;
    }

    // User-specific data (private)
    match /users/{userId} {
      allow read: if isOwner(userId);
      allow create: if isOwner(userId);
      allow update: if isOwner(userId);
      allow delete: if false;

      match /{document=**} {
        allow read, write: if isOwner(userId);
      }
    }
  }
}
```

3. Clique sur "Publier"

---

## 5. Indexes

### Étape 5.1: Créer les Indexes Composites

Les indexes se créent automatiquement quand tu fais des queries. Mais tu peux les créer manuellement:

1. Dans Firebase Console, va dans **Firestore Database → Index**
2. Clique sur "Ajouter un index composite"

#### Index 1: completed_tasks par routine et date
- **Collection**: `users/{userId}/completed_tasks`
- **Champs**:
  - `routine_id` (Ascending)
  - `completed_at` (Descending)
- **Status de la requête**: Collection

#### Index 2: completed_tasks par exercise et date
- **Collection**: `users/{userId}/completed_tasks`
- **Champs**:
  - `exercise_id` (Ascending)
  - `completed_at` (Descending)

#### Index 3: exercises par type et difficulté
- **Collection**: `exercises`
- **Champs**:
  - `type` (Ascending)
  - `difficulty` (Ascending)

#### Index 4: daily_progress par date
- **Collection**: `users/{userId}/routine_progress/{routineId}/daily_progress`
- **Champs**:
  - `date` (Descending)
  - `completion_rate` (Descending)

---

## 6. Configuration Mixpanel

### Étape 6.1: Créer un Compte Mixpanel

1. Va sur [Mixpanel.com](https://mixpanel.com/)
2. Crée un compte (gratuit jusqu'à 100k événements/mois)
3. Crée un nouveau projet "CortiFree"

### Étape 6.2: Récupérer le Token

1. Dans Mixpanel, va dans **Settings → Project Settings**
2. Copie le **Project Token**

### Étape 6.3: Activer Mixpanel dans MixpanelManager.swift

1. Ouvre `Services/MixpanelManager.swift`
2. Décommente les lignes avec `Mixpanel` et remplace le token:

```swift
import Mixpanel

private init() {
    // Remplace "YOUR_MIXPANEL_TOKEN" par ton vrai token
    Mixpanel.initialize(token: "TON_TOKEN_ICI", trackAutomaticEvents: true)
}
```

3. Décommente toutes les fonctions `track()` dans le fichier

---

## 7. Test et Vérification

### Étape 7.1: Tester Firebase Authentication

Crée un fichier de test `AuthManager.swift` (si pas encore créé):

```swift
import Foundation
import FirebaseAuth

class AuthManager: ObservableObject {
    static let shared = AuthManager()

    @Published var currentUser: User?
    @Published var isAuthenticated = false

    private init() {
        // Check if user is already signed in
        if let user = Auth.auth().currentUser {
            self.currentUser = user
            self.isAuthenticated = true
            loadUserProfile(uid: user.uid)
        }
    }

    func signUp(email: String, password: String, displayName: String) async throws {
        let authResult = try await Auth.auth().createUser(withEmail: email, password: password)
        let user = authResult.user

        // Update display name
        let changeRequest = user.createProfileChangeRequest()
        changeRequest.displayName = displayName
        try await changeRequest.commitChanges()

        // Create Firestore profile
        try await FirebaseManager.shared.createUserProfile(
            uid: user.uid,
            email: email,
            displayName: displayName
        )

        // Set Mixpanel profile
        MixpanelManager.shared.setUserProfile(
            userId: user.uid,
            email: email,
            routineId: nil,
            level: 1
        )

        DispatchQueue.main.async {
            self.currentUser = user
            self.isAuthenticated = true
        }
    }

    func signIn(email: String, password: String) async throws {
        let authResult = try await Auth.auth().signIn(withEmail: email, password: password)
        let user = authResult.user

        // Update last login
        try await FirebaseManager.shared.updateLastLogin(uid: user.uid)

        DispatchQueue.main.async {
            self.currentUser = user
            self.isAuthenticated = true
        }

        loadUserProfile(uid: user.uid)
    }

    func signOut() throws {
        try Auth.auth().signOut()
        DispatchQueue.main.async {
            self.currentUser = nil
            self.isAuthenticated = false
            FirebaseManager.shared.currentUser = nil
        }
    }

    private func loadUserProfile(uid: String) {
        Task {
            do {
                _ = try await FirebaseManager.shared.fetchUserProfile(uid: uid)
            } catch {
                print("Error loading user profile: \(error)")
            }
        }
    }
}
```

### Étape 7.2: Test Manuel

1. Lance l'app
2. Crée un compte de test
3. Vérifie dans Firebase Console → Authentication que l'utilisateur apparaît
4. Vérifie dans Firestore Database → users qu'un document avec l'UID est créé
5. Complète un exercice de respiration avec feedback
6. Vérifie dans Firestore que `completed_tasks` et `feedback` sont créés
7. Vérifie dans Mixpanel → Live View que les événements arrivent

### Étape 7.3: Vérifier les Logs

Dans Xcode Console, tu devrais voir:
```
✅ Feedback saved to Firebase successfully
[Mixpanel] Event: Exercise Completed - breathing_4_7_8, XP: 15
[Mixpanel] Event: Feedback Submitted - Mood: veryGood
```

---

## 📊 Structure Firestore Finale

Après setup complet, ta base Firestore devrait ressembler à ça:

```
📁 Firestore Database
├── 📂 routines/
│   └── {routineId}/
│       └── weeks/
│           └── {weekId}/
│               └── daily_tasks/
│                   └── {dayId}/
│                       └── tasks/
│
├── 📂 exercises/
│   └── {exerciseId}
│
├── 📂 meditation_supports/
│   └── {supportId}/
│       └── sections/
│
├── 📂 onboarding_questions/
│   └── {questionId}
│
└── 📂 users/
    └── {userId}/
        ├── onboarding_responses/
        ├── routine_progress/
        │   └── {routineId}/
        │       └── daily_progress/
        ├── completed_tasks/
        ├── custom_tasks/
        ├── feedback/
        ├── ai_insights/
        └── stats/
```

---

## ⚠️ Checklist Finale

- [ ] Firebase SDK installé via SPM
- [ ] Mixpanel SDK installé via SPM
- [ ] `GoogleService-Info.plist` ajouté au projet
- [ ] `FirebaseApp.configure()` dans `CortiFreeApp.swift`
- [ ] Firestore activé en mode Production
- [ ] Authentication activée (Email/Password)
- [ ] Security Rules publiées
- [ ] Indexes créés (optionnel, se créeront automatiquement)
- [ ] Mixpanel token ajouté dans `MixpanelManager.swift`
- [ ] Test de création de compte réussi
- [ ] Test de sauvegarde d'exercice réussi
- [ ] Événements Mixpanel visibles dans Live View

---

## 🚀 Next Steps

1. **Peupler Firestore avec des données**:
   - Créer des routines dans la collection `routines`
   - Créer des exercices dans `exercises`
   - Créer des questions d'onboarding dans `onboarding_questions`

2. **Configurer Cloud Functions** (optionnel mais recommandé):
   - Analyse automatique des données utilisateur
   - Génération d'insights IA
   - Statistiques hebdomadaires

3. **Ajouter Apple Sign-In** (recommandé pour iOS):
   - Configure dans Firebase Authentication
   - Ajoute le capability dans Xcode

---

## 📞 Support

Si tu rencontres des problèmes:
1. Vérifie les logs Xcode
2. Vérifie la console Firebase (onglet Debug)
3. Vérifie que les Security Rules sont bien publiées
4. Assure-toi que l'utilisateur est bien authentifié avant toute opération Firestore

**Documentation officielle**:
- [Firebase iOS Quickstart](https://firebase.google.com/docs/ios/setup)
- [Firestore Get Started](https://firebase.google.com/docs/firestore/quickstart)
- [Mixpanel iOS SDK](https://docs.mixpanel.com/docs/tracking-methods/sdks/swift)
