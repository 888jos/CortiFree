# 📊 Mixpanel Tracking - Remaining 7 Onboarding Screens

**Guide complet pour ajouter le tracking Mixpanel aux 7 screens restants de l'onboarding.**

---

## ✅ Déjà fait

1. **AuthenticationView** ✅ - Tracking ajouté

---

## ⏳ Screens restants (7/16)

### 2. OverallQuizView ⏳

**Fichier:** `Views/Onboarding V2/OverallQuizView.swift`

**Events à tracker:**
- `onboarding_overall_quiz_viewed` - Quand le quiz démarre
- `onboarding_overall_quiz_completed` - Quand le quiz se termine

**Changements:**

1. Ajouter `@State private var quizStartTime: Date?` dans la struct

2. Ajouter `.onAppear` au body principal (avant la fermeture du ZStack):
```swift
.onAppear {
    quizStartTime = Date()
    MixpanelManager.shared.trackOnboardingOverallQuizViewed()
}
```

3. Dans la fonction `completeQuiz()` (ligne ~620), ajouter AVANT `onComplete(data)`:
```swift
// Track quiz completion
let totalTime = quizStartTime.map { Date().timeIntervalSince($0) }
MixpanelManager.shared.trackOnboardingOverallQuizCompleted(
    totalTime: totalTime,
    firstName: firstName,
    gender: genderOptions[selectedGender ?? 0],
    age: ageOptions[selectedAge ?? 0],
    reasons: selectedReasonTexts,
    duration: durationOptions[selectedDuration ?? 0]
)
```

---

### 3. CortiFreeRatingView ⏳

**Fichier:** `Views/Onboarding V2/CortiFreeRatingView.swift`

**Events à tracker:**
- `onboarding_cortifree_rating_viewed` - Quand l'écran apparaît
- `onboarding_rating_continue` - Quand le bouton "Continuer" est cliqué

**Changements:**

1. Ajouter `@State private var screenViewTime: Date?` dans la struct

2. Ajouter `.onAppear` au body principal (cherche le ZStack principal, avant sa fermeture):
```swift
.onAppear {
    screenViewTime = Date()
    MixpanelManager.shared.trackOnboardingCortiFreeRatingViewed(
        globalScoreCurrent: currentScores[0],
        globalScorePotential: potentialScores[0],
        serenityScoreCurrent: currentScores[1],
        sleepScoreCurrent: currentScores[2],
        energyScoreCurrent: currentScores[3],
        focusScoreCurrent: currentScores[4],
        balanceScoreCurrent: currentScores[5]
    )
}
```

3. Dans le bouton "Continuer", ajouter AVANT `onContinue()`:
```swift
// Track continue with time spent
if let startTime = screenViewTime {
    let timeSpent = Date().timeIntervalSince(startTime)
    MixpanelManager.shared.trackOnboardingRatingContinue(timeSpent: timeSpent)
}
```

---

### 4. EightHabitsIntroView ⏳

**Fichier:** `Views/Onboarding V2/EightHabitsIntroView.swift`

**Events à tracker:**
- `onboarding_eight_habits_intro_viewed` - Quand l'écran apparaît
- `onboarding_eight_habits_intro_continue` - Quand le bouton "Continuer" est cliqué

**Changements:**

1. Ajouter `.onAppear` au body principal (avant la fermeture du ZStack):
```swift
.onAppear {
    MixpanelManager.shared.trackOnboardingEightHabitsIntroViewed()
}
```

2. Dans le bouton "Continuer", ajouter AVANT `onContinue()`:
```swift
MixpanelManager.shared.trackOnboardingEightHabitsIntroContinue()
```

---

### 5. WeekProgressView ⏳

**Fichier:** `Views/Onboarding V2/WeekProgressView.swift`

**Events à tracker:**
- `onboarding_week_progress_viewed` - Quand l'écran apparaît
- `onboarding_week_progress_continue` - Quand le bouton "Continuer" est cliqué

**Changements:**

1. Ajouter `.onAppear` au body principal (avant la fermeture du ZStack):
```swift
.onAppear {
    MixpanelManager.shared.trackOnboardingWeekProgressViewed()
}
```

2. Dans le bouton "Continuer", ajouter AVANT `onContinue()`:
```swift
MixpanelManager.shared.trackOnboardingWeekProgressContinue()
```

---

### 6. EightHabitsFlowView ⏳

**Fichier:** `Views/Onboarding V2/EightHabitsFlowView.swift`

**Events à tracker:**
- `onboarding_eight_habits_flow_viewed` - Quand l'écran apparaît
- `onboarding_eight_habits_continue` - Quand le bouton "Continuer" est cliqué

**Changements:**

1. Ajouter `@State private var screenViewTime: Date?` dans la struct

2. Ajouter `.onAppear` au body principal (avant la fermeture du ZStack):
```swift
.onAppear {
    screenViewTime = Date()
    MixpanelManager.shared.trackOnboardingEightHabitsFlowViewed()
}
```

3. Dans le bouton "Continuer" (probablement dans la dernière card), ajouter AVANT `onComplete()`:
```swift
// Track completion with time spent
let timeSpent = screenViewTime.map { Date().timeIntervalSince($0) } ?? 0.0
MixpanelManager.shared.trackOnboardingEightHabitsContinue(
    habitsViewedCount: habits.count,
    timeSpent: timeSpent
)
```

---

### 7. HabitsProgressFlowView ⏳

**Fichier:** `Views/Onboarding V2/HabitsProgressFlowView.swift`

**Events à tracker:**
- `onboarding_habits_progress_viewed` - Quand l'écran apparaît
- `onboarding_progress_continue` - Quand le bouton "Continuer" est cliqué

**Changements:**

1. Ajouter `@State private var screenViewTime: Date?` dans la struct

2. Ajouter `.onAppear` au body principal (avant la fermeture du ZStack):
```swift
.onAppear {
    screenViewTime = Date()
    MixpanelManager.shared.trackOnboardingHabitsProgressViewed()
}
```

3. Dans le bouton "Continuer", ajouter AVANT `onComplete()`:
```swift
// Track completion with time spent
let timeSpent = screenViewTime.map { Date().timeIntervalSince($0) } ?? 0.0
MixpanelManager.shared.trackOnboardingProgressContinue(timeSpent: timeSpent)
```

---

### 8. SocialProofFlowView ⏳

**Fichier:** `Views/Onboarding V2/SocialProofFlowView.swift`

**Events à tracker:**
- `onboarding_testimonials_viewed` - Quand les témoignages apparaissent
- `onboarding_testimonials_continue` - Quand le bouton "Continuer" est cliqué (vers goals)
- `onboarding_goals_selection_viewed` - Quand la page de sélection d'objectifs apparaît
- `onboarding_goals_selection_completed` - Quand les objectifs sont sélectionnés

**Changements:**

Ce fichier est composite avec 2 sous-views : `TestimonialsView` et `GoalsSelectionView`.

#### Dans `TestimonialsView`:

1. Ajouter `.onAppear` :
```swift
.onAppear {
    MixpanelManager.shared.trackOnboardingTestimonialsViewed()
}
```

2. Dans le bouton "Continuer", ajouter AVANT `onContinue()`:
```swift
MixpanelManager.shared.trackOnboardingTestimonialsContinue()
```

#### Dans `GoalsSelectionView`:

1. Ajouter `.onAppear`:
```swift
.onAppear {
    MixpanelManager.shared.trackOnboardingGoalsSelectionViewed()
}
```

2. Dans le bouton "Continuer" (quand on valide les goals), ajouter AVANT `onContinue()`:
```swift
// Track goals selection with selected goals
let selectedGoalTexts = selectedGoals.map { goals[$0] }
MixpanelManager.shared.trackOnboardingGoalsSelectionCompleted(selectedGoals: selectedGoalTexts)
```

---

## 📊 Résumé des Events Ajoutés

| Screen | Events Trackés | Propriétés Clés |
|--------|----------------|-----------------|
| **OverallQuizView** | `onboarding_overall_quiz_viewed`, `onboarding_overall_quiz_completed` | firstName, gender, age, reasons, duration, total_time |
| **CortiFreeRatingView** | `onboarding_cortifree_rating_viewed`, `onboarding_rating_continue` | scores actuels/potentiels, time_spent |
| **EightHabitsIntroView** | `onboarding_eight_habits_intro_viewed`, `onboarding_eight_habits_intro_continue` | - |
| **WeekProgressView** | `onboarding_week_progress_viewed`, `onboarding_week_progress_continue` | - |
| **EightHabitsFlowView** | `onboarding_eight_habits_flow_viewed`, `onboarding_eight_habits_continue` | habitsViewedCount, time_spent |
| **HabitsProgressFlowView** | `onboarding_habits_progress_viewed`, `onboarding_progress_continue` | time_spent |
| **SocialProofFlowView** | `onboarding_testimonials_viewed`, `onboarding_testimonials_continue`, `onboarding_goals_selection_viewed`, `onboarding_goals_selection_completed` | selectedGoals[] |

**Total: 15 nouveaux events trackés**

---

## 🎯 Après Implémentation

Une fois tous ces changements appliqués, tu pourras:

1. **Voir le funnel complet** de l'onboarding dans Mixpanel (16 steps au total)
2. **Identifier les drop-off points** à chaque screen
3. **Mesurer le temps passé** sur chaque screen
4. **Analyser les choix utilisateurs** (goals sélectionnés, quiz responses, etc.)

---

## 🚀 Next Steps

**Immédiat:**
1. Applique ces changements à chaque fichier
2. Build le projet
3. Test end-to-end de l'onboarding
4. Vérifie dans Mixpanel que tous les events apparaissent

**Court terme:**
- Crée le funnel complet dans Mixpanel (16 steps)
- Set up des alertes si drop-off >15% à un step
- Attends 100-200 users pour données significatives

---

**Dernière mise à jour:** 2025-11-21
**Status:** 1/8 screens complétés (AuthenticationView ✅)
**Restant:** 7 screens
