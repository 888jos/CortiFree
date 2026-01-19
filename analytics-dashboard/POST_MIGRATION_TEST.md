# 🧪 Post-Migration Testing Guide

## Migration Status: ✅ COMPLETE

**Date:** 2026-01-15
**Migration:** Mixpanel → Firebase Analytics + Firestore
**Status:** BUILD SUCCEEDED ✅
**Dashboard Status:** CONFIGURED ✅

---

## 🎯 Ce qui a changé

### AVANT:
```
iOS App → Mixpanel (EU)
           ❌ PAS DE LIEN
Dashboard ← Firebase Firestore (vide)
```

### MAINTENANT:
```
iOS App → Firebase Analytics (rapports)
       → Firestore collection "analytics_events" (dashboard)
           ↓
Dashboard ← Lit "analytics_events" ✅
```

---

## ✅ Checklist pré-test

Avant de commencer les tests, vérifie que tout est en place:

- [x] **GoogleService-Info.plist** existe dans le projet iOS
  - Project ID: `cortifree-app` ✅
  - Bundle ID: `Josbiot.App.CortiFree` ✅

- [x] **Firebase configuré** dans CortiFreeApp.swift
  - `FirebaseApp.configure()` appelé ✅
  - `MixpanelManager.shared.initialize()` appelé ✅

- [x] **MixpanelManager migré** vers Firebase
  - Import Firebase Analytics ✅
  - Import Firebase Firestore ✅
  - Double tracking implémenté ✅

- [x] **Dashboard configuré**
  - Firebase config matches iOS config ✅
  - Collection: `analytics_events` ✅

---

## 🧪 Test 1: Vérification Logs Console

**Objectif:** Confirmer que l'app envoie bien les events

### Steps:

1. **Ouvre Xcode**
   ```bash
   cd /Users/jos/CortiFree/CortiFree
   open CortiFree.xcodeproj
   ```

2. **Lance l'app** sur simulateur (Cmd+R)

3. **Vérifie la console Xcode** pour ces logs:

   **✅ Au démarrage:**
   ```
   [Analytics] ✅ Initialized successfully with Firebase
   [Analytics] 📊 Event: app_opened
   [Analytics] 💾 Sent to Firestore: app_opened
   ```

   **✅ Pendant l'onboarding (chaque step):**
   ```
   [Analytics] 📊 Event: onboarding_step_viewed | Properties: {...}
   [Analytics] 💾 Sent to Firestore: onboarding_step_viewed
   ```

   **❌ Si tu vois des erreurs:**
   ```
   [Analytics] ❌ Firestore error: [error message]
   ```
   → Va à la section "Troubleshooting" ci-dessous

### Résultat attendu:
- ✅ Logs `[Analytics] ✅ Initialized successfully with Firebase`
- ✅ Logs `[Analytics] 📊 Event: ...` pour chaque action
- ✅ Logs `[Analytics] 💾 Sent to Firestore: ...` pour chaque event
- ❌ AUCUN log `[Analytics] ❌ Firestore error`

---

## 🧪 Test 2: Vérification Firebase Console

**Objectif:** Confirmer que les events arrivent dans Firestore

### Steps:

1. **Ouvre Firebase Console**
   - URL: https://console.firebase.google.com/
   - Projet: `cortifree-app`

2. **Navigate vers Firestore Database**
   - Sidebar → Build → Firestore Database

3. **Vérifie la collection `analytics_events`**
   - Tu devrais voir des documents créés EN TEMPS RÉEL
   - Chaque document contient:
     ```
     {
       event_name: "app_opened"
       timestamp: Timestamp
       user_id: "abc123" ou "anonymous"
       properties: { ... }
     }
     ```

4. **Teste un flow complet**
   - Dans l'app: Fais l'onboarding complet
   - Dans Firebase Console: Refresh la page
   - Tu devrais voir apparaître ~15-20 events (tous les steps d'onboarding)

### Résultat attendu:
- ✅ Collection `analytics_events` existe
- ✅ Nouveaux documents apparaissent en temps réel (~2-5 sec de délai)
- ✅ Structure des documents correcte (event_name, timestamp, user_id, properties)

---

## 🧪 Test 3: Vérification Dashboard Analytics

**Objectif:** Confirmer que le dashboard affiche les events

### Steps:

1. **Ouvre le dashboard**
   ```bash
   cd /Users/jos/CortiFree/analytics-dashboard
   open cortifree-analytics.html
   ```

2. **Vérifie la console du navigateur (Cmd+Option+I)**
   - Cherche: `✅ Firebase initialized successfully`
   - Pas d'erreurs "Firebase initialization failed"

3. **Vérifie la section "Live Events"**
   - Tab: Vue d'ensemble
   - Scroll vers "Événements récents"
   - Tu devrais voir la liste des events arriver en temps réel

4. **Lance l'app iOS et teste:**
   - Ouvre l'app (devrait générer `app_opened`)
   - Refresh le dashboard (F5)
   - L'event `app_opened` devrait apparaître dans les 2-5 secondes

5. **Teste un flow complet:**
   - Lance l'onboarding complet dans l'app
   - Dashboard → Tab "Onboarding"
   - Tu devrais voir le funnel se remplir avec les events

### Résultat attendu:
- ✅ Dashboard charge sans erreur
- ✅ Section "Live Events" affiche les events récents
- ✅ Events apparaissent ~2-5 secondes après action dans l'app
- ✅ Funnels d'onboarding se remplissent correctement

---

## 🧪 Test 4: Test End-to-End Complet

**Objectif:** Valider tout le flow analytics du début à la fin

### Steps:

1. **Désinstalle l'app du simulateur** (pour simuler un nouveau user)
   - Simulator → Long press sur CortiFree → Delete App

2. **Ouvre le dashboard dans le navigateur**

3. **Lance l'app dans Xcode** (Cmd+R)

4. **Fais l'onboarding complet:**
   - Welcome screens (swipe)
   - Habits quiz (réponds aux questions)
   - Create account (email + password)
   - Paywall (clique sur "Start my program")

5. **Pendant l'onboarding, vérifie:**
   - **Console Xcode:** Logs `[Analytics] 📊 Event: ...` pour chaque step
   - **Dashboard:** Onglet "Live Events" se remplit en temps réel

6. **Après l'onboarding, vérifie:**
   - Dashboard → Tab "Onboarding" → Funnel devrait montrer toutes les étapes
   - Dashboard → Tab "Users" → Tu devrais voir 1 nouveau user
   - Firebase Console → Firestore → ~15-20 nouveaux documents

### Résultat attendu:
- ✅ Tous les events d'onboarding trackés (17 steps)
- ✅ Dashboard affiche le funnel complet
- ✅ Firebase Console contient tous les events
- ✅ Aucune erreur dans logs Xcode
- ✅ Dashboard montre les stats en temps réel

---

## 🐛 Troubleshooting

### ❌ Problème 1: "Firestore error: Permission denied"

**Cause:** Les règles Firestore bloquent les écritures

**Solution:**
1. Va sur Firebase Console → Firestore Database → Rules
2. Vérifie que les règles permettent l'écriture:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow authenticated users to write analytics events
    match /analytics_events/{document=**} {
      allow read: if true; // Dashboard needs to read
      allow write: if request.auth != null; // Only auth users
    }
  }
}
```

3. Si tu testes avec users anonymes, change temporairement en:
```javascript
allow write: if true; // TEMPORARY - permet écriture anonyme
```

4. **Publie les règles** (bouton "Publish")

5. **Relance l'app** et vérifie les logs

---

### ❌ Problème 2: "Firebase initialized successfully" mais aucun event

**Cause:** Firebase Analytics est initialisé mais Firestore écrit échoue silencieusement

**Solution:**
1. Vérifie que `GoogleService-Info.plist` est bien dans le projet Xcode:
   - Xcode → Project Navigator → `GoogleService-Info.plist` devrait être visible
   - Target Membership: CortiFree ✅

2. Vérifie que Firebase est initialisé AVANT MixpanelManager:
   - Ouvre `CortiFreeApp.swift`
   - Ordre doit être:
     ```swift
     FirebaseApp.configure() // 1er
     MixpanelManager.shared.initialize() // 2ème
     ```

3. Clean build:
   ```bash
   cd /Users/jos/CortiFree/CortiFree
   xcodebuild clean -project CortiFree.xcodeproj
   ```

4. Relance l'app

---

### ❌ Problème 3: Dashboard affiche "No events found"

**Cause:** Le dashboard lit la mauvaise collection ou la config Firebase est incorrecte

**Solution:**
1. Ouvre `cortifree-analytics.html` dans un éditeur
2. Cherche `firebase.initializeApp` (ligne ~1542)
3. Vérifie que la config match exactement `GoogleService-Info.plist`:
   ```javascript
   const firebaseConfig = {
       apiKey: "AIzaSyDUNiZnPmlyqra5S-NE8oyteE0He78DwBA",
       authDomain: "cortifree-app.firebaseapp.com",
       projectId: "cortifree-app", // MUST MATCH
       storageBucket: "cortifree-app.firebasestorage.app",
       messagingSenderId: "559047783915",
       appId: "1:559047783915:ios:528a29531de5a8219155ae"
   };
   ```

4. Vérifie la collection Firestore:
   ```javascript
   // Ligne ~1600
   db.collection('analytics_events') // MUST BE "analytics_events"
   ```

5. Refresh le dashboard (Cmd+R)

---

### ❌ Problème 4: Events arrivent avec 10+ minutes de délai

**Cause:** Firebase Analytics batch les events pour économiser la batterie

**Solution:**
C'est normal pour Firebase Analytics (rapports), MAIS Firestore devrait être instantané.

1. Vérifie que tu regardes bien **Firestore** (pas Firebase Analytics DebugView)
2. Firestore délai normal: 2-5 secondes maximum
3. Si Firestore est lent (>10 sec):
   - Check ta connexion internet
   - Vérifie Firebase Status: https://status.firebase.google.com/
   - Regarde les logs Xcode pour `[Analytics] ❌ Firestore error`

---

## 📊 Événements à Tracker

Voici les events principaux qui devraient apparaître dans ton dashboard:

### Onboarding Events:
- ✅ `onboarding_started`
- ✅ `onboarding_step_viewed` (17 fois)
- ✅ `onboarding_welcome_swiped`
- ✅ `onboarding_quiz_started`
- ✅ `onboarding_quiz_completed`
- ✅ `onboarding_habits_quiz_completed`
- ✅ `onboarding_account_created`
- ✅ `onboarding_paywall_viewed`
- ✅ `onboarding_completed`

### App Events:
- ✅ `app_opened`
- ✅ `screen_viewed`
- ✅ `task_completed`
- ✅ `meditation_started`
- ✅ `journal_entry_created`

### Subscription Events:
- ✅ `subscription_started` (trial)
- ✅ `subscription_status_changed`
- ✅ `purchase_completed`

### Notification Events:
- ✅ `notification_received`
- ✅ `notification_clicked`

---

## ✅ Success Criteria

Ton analytics système fonctionne parfaitement si:

1. **✅ Logs Xcode:**
   - `[Analytics] ✅ Initialized successfully with Firebase`
   - `[Analytics] 📊 Event: ...` pour chaque action
   - `[Analytics] 💾 Sent to Firestore: ...` pour chaque event
   - ZERO `[Analytics] ❌ Firestore error`

2. **✅ Firebase Console:**
   - Collection `analytics_events` existe
   - Nouveaux documents créés en temps réel (<5 sec)
   - Structure correcte: event_name, timestamp, user_id, properties

3. **✅ Dashboard Analytics:**
   - Charge sans erreur JavaScript
   - "Live Events" affiche les events récents
   - Funnels d'onboarding se remplissent
   - Stats mises à jour en temps réel

4. **✅ End-to-End Test:**
   - Onboarding complet → 17 events trackés
   - Dashboard montre tout le funnel
   - Pas de gaps dans les données
   - Délai <5 secondes entre action et dashboard

---

## 📝 Prochaines Étapes

Une fois que tous les tests passent:

### 1. Supprimer Mixpanel Package (Optionnel)
Le code ne référence plus Mixpanel, tu peux supprimer le package:
- Xcode → Project → CortiFree → Package Dependencies
- Sélectionne "Mixpanel-swift"
- Clic droit → Delete

### 2. Configurer Firestore Rules (Production)
Avant de déployer en production:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /analytics_events/{document=**} {
      allow read: if true; // Dashboard read
      allow write: if request.auth != null; // Only authenticated users
    }
  }
}
```

### 3. Monitoring
Dashboard à surveiller quotidiennement:
- Live Events (vérifie que les events arrivent)
- Onboarding Funnel (taux de conversion)
- User Count (croissance)
- Subscription Status (trial vs active)

---

## 🎉 Migration Réussie!

Si tous les tests passent:
- ✅ Mixpanel → Firebase Analytics migration COMPLETE
- ✅ Dashboard analytics fonctionnel
- ✅ Double tracking (Analytics + Firestore)
- ✅ Données en temps réel (<5 sec)
- ✅ GRATUIT jusqu'à 10M events/mois

**Coût analytics:**
- Avant: Mixpanel gratuit jusqu'à 100k events/mois
- Maintenant: Firebase GRATUIT jusqu'à 10M events/mois (100x plus!)

**Félicitations! 🎊**
