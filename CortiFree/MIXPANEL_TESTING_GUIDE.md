# Guide de test Mixpanel Analytics

## Configuration ✅

- **Token**: `54821f0aa53aa5ce3804237815f94332`
- **Serveur**: EU (`https://api-eu.mixpanel.com`)
- **Dashboard**: https://eu.mixpanel.com/project/3310694

## Phase 1: SDK Installé ✅

### Tests de base

1. **Vérifier l'initialisation**
   ```bash
   # Lance l'app et cherche dans les logs Xcode:
   [Mixpanel] ✅ Initialized successfully with EU server
   ```

2. **Vérifier les Super Properties**

   Tous les événements incluent automatiquement:
   - `app_version` - Version de l'app (ex: "1.0")
   - `os_version` - Version iOS (ex: "18.6")
   - `device_type` - Type d'appareil (ex: "iPhone Simulator")
   - `language` - Langue (ex: "fr")
   - `platform` - Toujours "iOS"

## Phase 2: Onboarding - Premier écran ✅

### Test de FirstLaunchWelcomeView

**Scénario de test:**

1. Déconnecte-toi de l'app (Settings > Déconnexion)
2. Clique sur "Sign Up"
3. L'écran de bienvenue s'affiche
4. **Événement attendu:** `onboarding_welcome_viewed`
   ```
   [Mixpanel] 📊 Event: onboarding_welcome_viewed
   ```

5. Attends 5-10 secondes sur l'écran
6. Clique sur "Commencer"
7. **Événement attendu:** `onboarding_welcome_continue`
   ```
   [Mixpanel] 📊 Event: onboarding_welcome_continue | Properties: ["time_spent": 8.5]
   ```

### Vérification dans le dashboard Mixpanel

1. Ouvre https://eu.mixpanel.com/project/3310694
2. Menu **Events** → Attends 1-2 minutes pour la synchro
3. Tu devrais voir:
   - ✅ `onboarding_welcome_viewed`
   - ✅ `onboarding_welcome_continue` avec propriété `time_spent`

## Événements implémentés

### ✅ Onboarding V2
- `onboarding_welcome_viewed` - Écran de bienvenue affiché
- `onboarding_welcome_continue` - Bouton "Commencer" cliqué
  - Propriétés: `time_spent` (secondes)

### 🚧 À venir (Phase 2-4)

**Onboarding (priorité haute):**
- `onboarding_quiz_started`
- `onboarding_quiz_question_answered` (×12)
- `onboarding_habits_quiz_completed`
- `onboarding_completed`

**App principale (priorité haute):**
- `task_validated`
- `task_skipped`
- `achievement_unlocked`
- `badge_unlocked`

**Rétention (priorité haute):**
- `first_app_launch`
- `first_task_completed`
- `day_1_active`, `day_3_active`, `day_7_active`
- `day_30_active`, `day_66_completed`

## Debugging

### Voir tous les événements envoyés

Dans la console Xcode, filtre par `[Mixpanel]`:

```
[Mixpanel] ✅ Initialized successfully with EU server
[Mixpanel] 📊 Event: onboarding_welcome_viewed
[Mixpanel] 📊 Event: onboarding_welcome_continue | Properties: ["time_spent": 8.5]
```

### Forcer l'envoi des événements

Les événements sont envoyés automatiquement, mais pour forcer un flush immédiat:

```swift
// Dans n'importe quelle view ou service
MixpanelManager.shared.flush()
```

### Reset (pour tests)

Pour reset l'identité utilisateur (utile en dev):

```swift
MixpanelManager.shared.reset()
```

## Méthodes disponibles

### Identification utilisateur

```swift
// Après signup/login
MixpanelManager.shared.identify(userId: user.uid)

// Définir le profil utilisateur
MixpanelManager.shared.setUserProfile(
    firstName: "John",
    email: "john@example.com",
    age: 25,
    gender: "M",
    globalScore: 75,
    primaryGoal: "reduce_stress"
)

// Mettre à jour la progression
MixpanelManager.shared.updateUserProgress(
    currentDay: 10,
    currentStreak: 5,
    totalTasksCompleted: 42,
    globalScore: 85,
    totalAchievements: 3
)
```

### Tracking d'événements

```swift
// Onboarding
MixpanelManager.shared.trackOnboardingWelcomeViewed()
MixpanelManager.shared.trackOnboardingWelcomeContinue(timeSpent: 10.5)

// Tasks (à implémenter)
MixpanelManager.shared.trackTaskValidated(
    taskTitle: "Méditation",
    habitId: "meditation",
    day: 10,
    currentStreak: 5,
    tasksCompletedToday: 3,
    globalScoreBefore: 80,
    globalScoreAfter: 85
)

// Rétention
MixpanelManager.shared.trackDayActive(
    day: 7,
    tasksCompleted: 5,
    currentStreak: 7,
    globalScoreChange: 5
)
```

## Prochaines étapes

### Phase 2: Onboarding complet
- [ ] HabitsQuizView - Tracking des 12 questions
- [ ] ReassuranceView
- [ ] AuthenticationView
- [ ] NotificationPermissionsView
- [ ] OnboardingCompletionView avec identification

### Phase 3: App principale
- [ ] TasksV2View - Validation/skip de tâches
- [ ] HomeView - Quick actions
- [ ] Achievement/Badge unlocking
- [ ] Journal entries

### Phase 4: Rétention
- [ ] First launch & first task
- [ ] Day 1, 3, 7 milestones
- [ ] Day 30, 66 completion

## Résumé du code

**Fichiers modifiés:**
- ✅ `Services/MixpanelManager.swift` (862 lignes, 100+ méthodes)
- ✅ `CortiFreeApp.swift` (initialisation)
- ✅ `Views/Onboarding V2/FirstLaunchWelcomeView.swift` (tracking ajouté)
- ✅ `Services/AuthManager.swift` (identification utilisateur)
- ⚠️ `Services/FirebaseManager.swift` (6 appels commentés, à réimplémenter)

**État actuel:**
- ✅ Build réussi
- ✅ SDK initialisé
- ✅ Premier écran trackés
- 🚧 15 écrans onboarding restants
- 🚧 App principale à tracker
- 🚧 Milestones de rétention
