# 🏗️ Architecture Firebase de CortiFree

## 📖 Vue d'Ensemble

Cette documentation décrit l'architecture complète de la base de données Firebase Firestore pour l'application CortiFree, une app de bien-être basée sur les neurosciences.

---

## 🗂️ Structure des Fichiers Créés

```
CortiFree/
├── Models/
│   └── FirebaseModels.swift          # Tous les modèles de données Firestore
├── Services/
│   ├── FirebaseManager.swift         # Gestionnaire centralisé Firestore
│   ├── MixpanelManager.swift         # Gestionnaire analytics Mixpanel
│   └── AuthManager.swift             # Gestionnaire d'authentification
├── Views/
│   └── AntiStress/
│       └── BreathingExerciseView.swift  # Intégration Firebase (feedback)
├── FIREBASE_SETUP_GUIDE.md           # Guide d'installation pas-à-pas
└── FIREBASE_ARCHITECTURE.md          # Ce fichier (documentation)
```

---

## 📊 Structure Firestore

### Collections Globales (Lecture Seule)

#### 1. `routines/`
**But**: Stocker les 8 routines principales de l'app

**Structure**:
```
routines/
└── {routineId} (ex: "reduce-anxiety")
    ├── id: "reduce-anxiety"
    ├── title: "Réduire mon anxiété"
    ├── description: "Programme de 8 semaines..."
    ├── objective: "Calmer les tensions internes..."
    ├── durationWeeks: 8
    ├── icon: "brain.head.profile"
    ├── category: "mental_health"
    ├── difficultyLevel: 2
    ├── tags: ["anxiety", "breathing"]
    ├── createdAt: Timestamp
    ├── updatedAt: Timestamp
    ├── isActive: true
    │
    └── weeks/{weekId}/
        ├── weekNumber: 1
        ├── theme: "Découvrir sa respiration"
        │
        └── daily_tasks/{dayId}/
            ├── dayNumber: 1
            │
            └── tasks/{taskId}/
                ├── taskId: "task_morning_1"
                ├── exerciseRef: "exercises/breathing_4_7_8"
                ├── moment: "morning"
                ├── order: 1
                ├── isMandatory: true
                ├── unlockCondition: null
                └── estimatedDurationMinutes: 3
```

**Exemple de routine**:
```json
{
  "id": "reduce-anxiety",
  "title": "Réduire mon anxiété",
  "description": "Programme de 8 semaines pour calmer les tensions internes et apaiser les pensées en boucle",
  "objective": "Calmer les tensions internes et les pensées en boucle",
  "durationWeeks": 8,
  "icon": "brain.head.profile",
  "category": "mental_health",
  "difficultyLevel": 2,
  "tags": ["anxiety", "breathing", "meditation"],
  "createdAt": "2025-11-09T10:00:00Z",
  "updatedAt": "2025-11-09T10:00:00Z",
  "isActive": true
}
```

#### 2. `exercises/`
**But**: Bibliothèque de tous les exercices disponibles

**Structure**:
```
exercises/
└── {exerciseId} (ex: "breathing_4_7_8")
    ├── id: "breathing_4_7_8"
    ├── type: "breathing"
    ├── title: "Respiration 4-7-8"
    ├── description: "Technique du Dr. Andrew Weil..."
    ├── instructions: [
    │     "Installez-vous confortablement",
    │     "Inspirez par le nez pendant 4s",
    │     "Retenez pendant 7s",
    │     "Expirez pendant 8s"
    │   ]
    ├── durationMinutes: 3
    ├── difficulty: 1
    ├── benefits: ["reduce_anxiety", "better_sleep"]
    ├── icon: "wind"
    ├── audioURL: null
    ├── animationType: "breathing_circle"
    ├── parameters: {
    │     "inhale_duration": 4,
    │     "hold_duration": 7,
    │     "exhale_duration": 8,
    │     "cycles": 8
    │   }
    ├── tags: ["anxiety", "sleep", "beginner"]
    ├── xpReward: 15
    ├── createdAt: Timestamp
    └── isActive: true
```

**Types d'exercices**:
- `breathing` - Exercices de respiration
- `meditation` - Méditations guidées
- `journaling` - Écriture thérapeutique
- `grounding` - Ancrage corporel
- `sound` - Sons d'ambiance
- `visualization` - Visualisations guidées

#### 3. `meditation_supports/`
**But**: Contenus des méditations guidées

```
meditation_supports/
└── {supportId} (ex: "body-scan")
    ├── id: "body-scan"
    ├── title: "Scan corporel guidé"
    ├── category: "grounding"
    ├── durationMinutes: 5
    ├── audioURL: "gs://..."
    ├── transcript: "Fermez les yeux..."
    │
    └── sections/{sectionId}/
        ├── order: 1
        ├── title: "Les pieds"
        ├── durationSeconds: 30
        └── steps: ["Portez attention...", "Ressentez..."]
```

#### 4. `onboarding_questions/`
**But**: Questions de l'onboarding (40 écrans)

```
onboarding_questions/
└── {questionId} (ex: "sleep_quality")
    ├── id: "sleep_quality"
    ├── screenNumber: 5
    ├── category: "symptoms"
    ├── questionText: "Comment évaluez-vous votre sommeil ?"
    ├── type: "scale"
    ├── options: ["Très mauvais", "Mauvais", "Moyen", "Bon", "Excellent"]
    ├── scaleMin: 1
    ├── scaleMax: 5
    ├── isRequired: true
    ├── affectsRoutineSelection: true
    ├── weightInAlgorithm: 0.8
    └── order: 5
```

---

### Collections Utilisateur (Privées)

#### 1. `users/`
**But**: Profil principal de chaque utilisateur

```
users/
└── {userId} (Firebase Auth UID)
    ├── uid: "firebase_auth_uid"
    ├── email: "user@example.com"
    ├── displayName: "Marie"
    ├── photoURL: "https://..."
    ├── createdAt: Timestamp
    ├── lastLogin: Timestamp
    ├── onboardingCompleted: true
    ├── onboardingCompletedAt: Timestamp
    ├── selectedRoutineId: "reduce-anxiety"
    ├── currentWeek: 2
    ├── currentDay: 10
    ├── totalXP: 450
    ├── level: 3
    ├── currentStreakDays: 7
    ├── longestStreakDays: 12
    ├── preferredMoments: ["morning", "evening"]
    ├── notificationSettings: {
    │     "morningTime": "08:00",
    │     "eveningTime": "21:00",
    │     "enabled": true
    │   }
    └── mixpanelDistinctId: "distinct_id"
```

#### 2. `users/{userId}/onboarding_responses/`
**But**: Réponses aux questions d'onboarding

```
onboarding_responses/
└── {questionId}
    ├── questionId: "sleep_quality"
    ├── response: "Mauvais"
    ├── score: 2
    └── answeredAt: Timestamp
```

#### 3. `users/{userId}/routine_progress/`
**But**: Progression dans les routines

```
routine_progress/
└── {routineId}
    ├── routineId: "reduce-anxiety"
    ├── startedAt: Timestamp
    ├── currentWeek: 2
    ├── currentDay: 10
    ├── completionPercentage: 45.5
    ├── isActive: true
    ├── completedAt: null
    ├── totalTasksCompleted: 91
    ├── totalTasks: 200
    ├── adherenceScore: 0.87
    │
    └── daily_progress/{date}/
        ├── date: "2025-11-09"
        ├── weekNumber: 2
        ├── dayNumber: 10
        ├── completedTasks: 18
        ├── totalTasks: 20
        ├── completionRate: 0.9
        ├── xpEarned: 270
        ├── moodMorning: "good"
        ├── moodEvening: "very_good"
        ├── energyLevel: 7
        ├── stressLevel: 4
        ├── notes: "Très bonne journée"
        └── createdAt: Timestamp
```

#### 4. `users/{userId}/completed_tasks/`
**But**: Historique de toutes les tâches complétées

```
completed_tasks/
└── {taskCompletionId}
    ├── taskId: "task_morning_1"
    ├── exerciseId: "breathing_4_7_8"
    ├── routineId: "reduce-anxiety"
    ├── weekNumber: 2
    ├── dayNumber: 10
    ├── moment: "morning"
    ├── completedAt: Timestamp
    ├── durationActualSeconds: 195
    ├── xpEarned: 15
    ├── feedbackMood: "veryGood"
    ├── feedbackNote: "Très relaxant"
    ├── wasManual: false
    └── deviceInfo: {
          "platform": "iOS",
          "version": "18.6"
        }
```

#### 5. `users/{userId}/custom_tasks/`
**But**: Tâches ajoutées manuellement par l'utilisateur

```
custom_tasks/
└── {customTaskId}
    ├── exerciseId: "breathing_5_5"
    ├── title: "Ma pause respiration"
    ├── moment: "afternoon"
    ├── reminderTime: "14:00"
    ├── isActive: true
    ├── createdAt: Timestamp
    └── recurrence: "daily"
```

#### 6. `users/{userId}/feedback/`
**But**: Feedbacks utilisateur (mood après exercices)

```
feedback/
└── {feedbackId}
    ├── type: "exercise_completion"
    ├── exerciseId: "breathing_4_7_8"
    ├── mood: "veryGood"
    ├── rating: 5
    ├── note: "Super exercice !"
    ├── timestamp: Timestamp
    └── context: {
          "routineId": "reduce-anxiety",
          "week": 2,
          "day": 10
        }
```

#### 7. `users/{userId}/ai_insights/`
**But**: Insights générés par l'IA pour adapter la routine

```
ai_insights/
└── {insightId}
    ├── generatedAt: Timestamp
    ├── insightType: "routine_adjustment"
    ├── trigger: "low_energy_pattern"
    ├── dataAnalyzed: {
    │     "period": "last_7_days",
    │     "completionRate": 0.65,
    │     "avgMood": "neutral",
    │     "fatigueSignals": 5
    │   }
    ├── recommendation: "Passer à des exercices plus doux"
    ├── suggestedExercises: ["breathing_5_5", "gentle_meditation"]
    ├── priority: "medium"
    ├── isApplied: false
    └── appliedAt: null
```

#### 8. `users/{userId}/stats/`
**But**: Statistiques agrégées (générées par Cloud Functions)

```
stats/
└── weekly_summary (document unique)
    ├── weekStart: "2025-11-03"
    ├── totalTasksCompleted: 98
    ├── totalXPEarned: 1470
    ├── avgCompletionRate: 0.88
    ├── dominantMood: "good"
    ├── mostActiveMoment: "morning"
    └── generatedAt: Timestamp
```

---

## 🔐 Security Rules

Les règles de sécurité Firestore sont définies pour protéger les données:

**Principe**:
- **Collections globales**: Lecture seule pour tous les utilisateurs authentifiés
- **Collections utilisateur**: Lecture/écriture uniquement pour le propriétaire
- **Pas de suppression**: Les données utilisateur ne peuvent pas être supprimées (sauf par admin)

**Exemple de règles**:
```javascript
match /users/{userId} {
  allow read: if request.auth.uid == userId;
  allow create, update: if request.auth.uid == userId;
  allow delete: if false; // Prevent accidental deletion

  match /{document=**} {
    allow read, write: if request.auth.uid == userId;
  }
}
```

---

## 📈 Événements Mixpanel Trackés

### Onboarding
- `Onboarding Started`
- `Onboarding Question Answered` (avec question_id, answer, screen_number)
- `Onboarding Completed` (avec selected_routine)

### Routines
- `Routine Started` (avec routine_id, routine_name)
- `Routine Completed` (avec duration_weeks, adherence_score)

### Exercices
- `Exercise Started` (avec exercise_id, exercise_type, moment)
- `Exercise Completed` (avec duration_seconds, feedback_mood, xp_earned)
- `Exercise Abandoned` (avec duration_seconds)

### Feedback
- `Feedback Submitted` (avec mood, exercise_id, has_note)

### Progression
- `Level Up` (avec new_level, total_xp)
- `Streak Milestone` (avec streak_days)
- `XP Earned` (avec amount, source)

### Sons d'Ambiance
- `Sound Started` (avec sound_name, selected_duration)
- `Sound Stopped` (avec played_duration_seconds)
- `Sound Duration Changed` (avec new_duration)

### Méditation
- `Meditation Started` (avec meditation_id, type)
- `Meditation Completed` (avec duration_minutes, xp_earned)

### AI Insights
- `AI Insight Generated` (avec insight_type, trigger, priority)
- `AI Insight Applied` (avec insight_type)
- `AI Insight Dismissed` (avec insight_type)

---

## 🚀 Fonctionnalités Clés Implémentées

### 1. **FirebaseManager.swift**
Gestionnaire centralisé pour toutes les opérations Firestore:
- ✅ CRUD utilisateur (Create, Read, Update)
- ✅ Gestion onboarding (réponses + complétion)
- ✅ Gestion routines (fetch, start, progress)
- ✅ Gestion exercices (fetch by ID, type, tags)
- ✅ Sauvegarde tâches complétées
- ✅ Sauvegarde feedback
- ✅ Gestion tâches personnalisées
- ✅ Statistiques (weekly summary, daily progress)
- ✅ AI Insights (fetch, apply)
- ✅ Gestion streaks
- ✅ Calcul automatique XP et niveaux

### 2. **MixpanelManager.swift**
Tracking analytics complet:
- ✅ 30+ événements trackés
- ✅ User profiles avec propriétés
- ✅ Super properties (user_id, level, routine_id)
- ✅ Événements de progression (XP, levels, streaks)
- ✅ Événements UI (screen views, interactions)

### 3. **AuthManager.swift**
Gestion authentification Firebase:
- ✅ Sign up (Email/Password)
- ✅ Sign in
- ✅ Sign out
- ✅ Password reset
- 🔜 Apple Sign In (à implémenter)
- 🔜 Google Sign In (à implémenter)

### 4. **FirebaseModels.swift**
Tous les modèles de données:
- ✅ `UserProfile`
- ✅ `RoutineModel` + `RoutineWeek` + `DailyTask` + `TaskModel`
- ✅ `ExerciseModel`
- ✅ `RoutineProgress` + `DailyProgress`
- ✅ `CompletedTask`
- ✅ `CustomTask`
- ✅ `FeedbackModel`
- ✅ `AIInsight`
- ✅ `WeeklySummary`
- ✅ `OnboardingQuestion` + `OnboardingResponse`

---

## 🔄 Flux de Données

### 1. Inscription Utilisateur
```
User → AuthManager.signUp()
     → FirebaseAuth.createUser()
     → FirebaseManager.createUserProfile()
     → MixpanelManager.setUserProfile()
     → MixpanelManager.trackOnboardingStarted()
```

### 2. Complétion d'Exercice
```
User completes exercise
     → BreathingExerciseView.saveFeedback()
     → FirebaseManager.saveCompletedTask()
         → Save to completed_tasks/
         → Update daily_progress/
         → Update user totalXP
         → Calculate new level
     → FirebaseManager.saveFeedback()
         → Save to feedback/
     → MixpanelManager.trackExerciseCompleted()
     → MixpanelManager.trackFeedbackSubmitted()
```

### 3. Génération Insights IA (Cloud Function)
```
Cloud Function (scheduled nightly)
     → Fetch user's last 7 days activity
     → Analyze completion rate, moods, fatigue signals
     → Generate insights if patterns detected
     → Save to users/{uid}/ai_insights/
     → MixpanelManager.trackAIInsightGenerated()
```

---

## 📦 Indexes Firestore Requis

Les indexes composites sont nécessaires pour les queries complexes:

1. **completed_tasks** par routine et date:
   - `routine_id` (Ascending) + `completed_at` (Descending)

2. **completed_tasks** par exercise et date:
   - `exercise_id` (Ascending) + `completed_at` (Descending)

3. **exercises** par type et difficulté:
   - `type` (Ascending) + `difficulty` (Ascending)

4. **daily_progress** par date et completion:
   - `date` (Descending) + `completion_rate` (Descending)

---

## 🎯 Next Steps

### Phase 1: Data Population
- [ ] Créer les 8 routines dans `routines/`
- [ ] Créer 30+ exercices dans `exercises/`
- [ ] Créer les 40 questions d'onboarding dans `onboarding_questions/`
- [ ] Créer les supports de méditation dans `meditation_supports/`

### Phase 2: Cloud Functions (Backend)
- [ ] Fonction `analyzeUserActivity` (analyse quotidienne)
- [ ] Fonction `generateWeeklyStats` (stats hebdomadaires)
- [ ] Fonction `sendNotifications` (rappels exercices)
- [ ] Fonction `cleanupOldData` (archivage données > 1 an)

### Phase 3: UI/UX
- [ ] Écran d'inscription avec FirebaseAuth
- [ ] Écran d'onboarding (40 questions)
- [ ] Dashboard de progression (graphs, stats)
- [ ] Bibliothèque d'exercices (filtrables par type, difficulté)
- [ ] Écran AI Insights (recommandations)

### Phase 4: Advanced Features
- [ ] Offline mode (Firestore cache)
- [ ] Export données (JSON, PDF)
- [ ] Partage progression (social)
- [ ] Gamification (badges, achievements)

---

## 📞 Support & Documentation

**Fichiers de référence**:
- `FIREBASE_SETUP_GUIDE.md` - Guide d'installation pas-à-pas
- `FIREBASE_ARCHITECTURE.md` - Ce fichier (documentation technique)

**Documentation officielle**:
- [Firebase Firestore](https://firebase.google.com/docs/firestore)
- [Mixpanel iOS](https://docs.mixpanel.com/docs/tracking-methods/sdks/swift)

**Contact**:
- Questions techniques → Consulter la documentation Firebase
- Issues → Créer un issue dans le repo Git

---

## ✅ Résumé

**Ce qui a été créé**:
1. ✅ **Models** - Tous les modèles de données Firestore (`FirebaseModels.swift`)
2. ✅ **FirebaseManager** - Gestionnaire centralisé avec 30+ fonctions (`FirebaseManager.swift`)
3. ✅ **MixpanelManager** - Analytics complet avec 30+ événements (`MixpanelManager.swift`)
4. ✅ **AuthManager** - Gestion authentification Firebase (`AuthManager.swift`)
5. ✅ **Intégration** - Feedback Firebase dans `BreathingExerciseView.swift`
6. ✅ **Guides** - Setup guide complet + architecture documentation

**Structure Firestore complète** avec:
- 4 collections globales (routines, exercises, meditation_supports, onboarding_questions)
- 8 sous-collections utilisateur (responses, progress, tasks, feedback, insights, stats)
- Security Rules optimisées
- Indexes composites définis

**Prêt pour**:
- Installation Firebase SDK
- Installation Mixpanel SDK
- Population des données
- Déploiement Cloud Functions
- Tests utilisateur

🚀 **L'infrastructure complète Firebase + Mixpanel est prête à être utilisée !**
