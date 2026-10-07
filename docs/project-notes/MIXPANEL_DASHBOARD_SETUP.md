# 📊 Configuration Dashboard Mixpanel Pro - CortiFree

## 🎯 Événements implémentés (100+)

### ✅ ACTIFS (3 événements)
- `app_opened` - Chaque lancement
- `onboarding_welcome_viewed` - Écran bienvenue
- `onboarding_welcome_continue` - Click "Commencer"

### 🔥 PRIORITÉ 1 - Onboarding (50+ événements)

#### Quiz d'habitudes (12 questions)
```
onboarding_quiz_started
onboarding_quiz_question_answered (×12 fois, une par question)
  Properties: question_number, question_text, answer_index, answer_text, time_to_answer
onboarding_quiz_back_clicked
onboarding_habits_quiz_completed
  Properties: serenity_score, sleep_score, energy_score, focus_score,
              habits_score, balance_score, global_score, baseline_*
```

#### Autres écrans onboarding
```
onboarding_reassurance_viewed
onboarding_sixty_days_explanation_viewed
onboarding_scientific_plan_viewed
onboarding_auth_started
onboarding_loading_analysis_viewed
onboarding_cortifree_rating_submitted
onboarding_eight_habits_intro_viewed
onboarding_week_progress_viewed
onboarding_eight_habits_flow_viewed
onboarding_notification_permission_requested
onboarding_habits_progress_flow_viewed
onboarding_social_proof_viewed
onboarding_completed ⭐ (CRITIQUE)
  Properties: total_time, quiz_global_score, selected_goals_count,
              notifications_enabled, user_id, first_name, age, gender
```

### 🔥 PRIORITÉ 2 - App principale (30+ événements)

#### Tasks (CRITIQUE pour conversion)
```
task_validated ⭐
  Properties: task_title, habit_id, day, current_streak,
              tasks_completed_today, global_score_before, global_score_after
task_skipped
  Properties: task_title, habit_id, day, reason
achievement_unlocked ⭐
  Properties: achievement_id, achievement_title, category, requirement
badge_unlocked
  Properties: badge_id, badge_title, days_completed
```

#### HomeView - Quick Actions
```
quick_action_breathing_clicked
quick_action_meditation_clicked
quick_action_sounds_clicked
quick_action_journal_clicked
anti_stress_button_clicked
```

#### Exercises
```
breathing_exercise_started
breathing_exercise_completed
  Properties: exercise_id, duration_seconds, technique
meditation_session_started
meditation_session_completed
  Properties: meditation_id, duration_seconds, meditation_type
```

#### Journal
```
journal_entry_created
  Properties: mood, entry_length, has_tags
journal_entry_viewed
journal_mood_selected
  Properties: mood
```

### 🔥 PRIORITÉ 3 - Rétention (8 événements CRITIQUES)

```
first_app_launch ⭐
first_task_completed ⭐
  Properties: task_title, habit_id, day, time_since_onboarding
day_1_active ⭐
  Properties: tasks_completed, current_streak, global_score_change
day_3_active ⭐
day_7_active ⭐
day_14_active
day_30_active ⭐
day_66_completed ⭐ (FIN DU PROGRAMME!)
```

### Autres événements
```
profile_tab_clicked
settings_notifications_toggled
settings_language_changed
user_logout
error_occurred
  Properties: error_type, error_message, screen
```

---

## 🎨 Configuration Dashboard Mixpanel

### 1. **Insights** - Vue d'ensemble

#### A. Créer un Insight "Funnel d'Onboarding"
1. Va dans **Insights** → **Create Insight** → **Funnels**
2. Nom: "🎯 Funnel Onboarding Complet"
3. Ajoute les étapes:
   ```
   Step 1: app_opened
   Step 2: onboarding_welcome_viewed
   Step 3: onboarding_welcome_continue
   Step 4: onboarding_quiz_started
   Step 5: onboarding_habits_quiz_completed
   Step 6: onboarding_auth_started
   Step 7: onboarding_completed
   ```
4. Conversion Window: 1 day
5. **Save** et épingle au dashboard

#### B. Créer un Insight "Taux de complétion quotidien"
1. **Create Insight** → **Segmentation**
2. Nom: "📊 Tasks validées par jour"
3. Event: `task_validated`
4. Group by: Day
5. Chart type: Line chart
6. **Save**

#### C. Créer un Insight "Rétention J1, J3, J7, J30"
1. **Create Insight** → **Retention**
2. Nom: "🔥 Rétention utilisateurs"
3. Initial event: `first_app_launch`
4. Return event: `app_opened`
5. Retention type: N-Day
6. Brackets: Day 1, 3, 7, 14, 30, 66
7. **Save**

#### D. Créer un Insight "Achievements débloqués"
1. **Segmentation**
2. Event: `achievement_unlocked`
3. Group by: `achievement_title` (property)
4. Chart type: Bar chart
5. **Save**

### 2. **Boards** - Dashboard personnalisé

#### Créer un Board "📊 CortiFree - Executive Dashboard"
1. **Boards** → **Create Board**
2. Nom: "📊 CortiFree - Executive Dashboard"
3. Ajoute les Insights créés ci-dessus

#### Layout recommandé:
```
┌─────────────────────────────────────────┐
│  🎯 Funnel Onboarding (grand, en haut) │
├──────────────────┬──────────────────────┤
│ 📊 Tasks/jour    │ 🔥 Rétention        │
├──────────────────┼──────────────────────┤
│ 🏆 Achievements  │ 📈 Streaks actifs   │
└──────────────────┴──────────────────────┘
```

### 3. **User Profiles** - Propriétés utilisateur

Quand un user complète l'onboarding, on set ces propriétés:

```javascript
// People Properties (via MixpanelManager.shared.setUserProfile)
$name               // Prénom
$email              // Email
age                 // Âge
gender              // Genre
global_score        // Score global
primary_goal        // Objectif principal

// Updated régulièrement (via updateUserProgress)
current_program_day // Jour actuel (1-66)
current_streak      // Streak actuel
total_tasks_completed // Total tâches complétées
total_achievements  // Total achievements débloqués
```

### 4. **Cohorts** - Segments d'utilisateurs

#### A. Cohort "🔥 Power Users"
1. **Cohorts** → **Create Cohort**
2. Nom: "🔥 Power Users"
3. Criteria:
   - `task_validated` > 20 in last 30 days
   - AND `current_streak` > 7
4. **Save**

#### B. Cohort "⚠️ At Risk" (risque de churn)
1. Nom: "⚠️ At Risk - Pas de tâche depuis 3 jours"
2. Criteria:
   - Did NOT do `task_validated` in last 3 days
   - AND did `onboarding_completed`
3. **Save**

#### C. Cohort "🎓 Onboarding Completed"
1. Nom: "🎓 Onboarding Completed"
2. Criteria:
   - Did `onboarding_completed` at least once
3. **Save**

### 5. **Events** - Organisation

#### Marquer les événements critiques
Dans **Events** → Clique sur chaque événement → **Edit** → Ajoute des tags:

**Tag "conversion":**
- `onboarding_completed`
- `first_task_completed`
- `task_validated`

**Tag "retention":**
- `day_1_active`
- `day_3_active`
- `day_7_active`
- `day_30_active`
- `day_66_completed`

**Tag "engagement":**
- `achievement_unlocked`
- `badge_unlocked`
- `journal_entry_created`

### 6. **Alertes** - Notifications

#### A. Alerte "Spike d'erreurs"
1. **Alerts** → **Create Alert**
2. Event: `error_occurred`
3. Condition: Count > 10 in 1 hour
4. Notification: Email
5. **Save**

#### B. Alerte "Drop de conversions onboarding"
1. Event: `onboarding_completed`
2. Condition: Count < 5 in 1 day
3. Notification: Email + Slack (si configuré)
4. **Save**

---

## 📈 KPIs à suivre (priorité)

### Conversion
- **Onboarding completion rate:** (onboarding_completed / app_opened) × 100
  - Target: >70%
- **First task completion:** (first_task_completed / onboarding_completed) × 100
  - Target: >80%

### Engagement
- **DAU (Daily Active Users):** Distinct users doing `app_opened` per day
- **Tasks per user per day:** task_validated / distinct users
  - Target: >2
- **Streak distribution:** Avg `current_streak` property
  - Target: >7 days

### Rétention
- **Day 1 retention:** % users active J+1
  - Target: >60%
- **Day 7 retention:** % users active J+7
  - Target: >40%
- **Day 30 retention:** % users active J+30
  - Target: >20%
- **Day 66 completion:** % users completing full program
  - Target: >10%

### Engagement features
- **Achievement unlock rate:** achievements / tasks completed
- **Journal usage:** % users creating entries

---

## 🚀 Prochaines étapes d'implémentation

### Phase 2: Onboarding V2 (2-3h)
**Fichiers à modifier:**
- `HabitsQuizView.swift` - 12 tracking calls
- `ReassuranceView.swift` - 1 tracking call
- `AuthenticationView.swift` - 2 tracking calls
- `OnboardingCompletionView.swift` - 1 tracking call + user identification

### Phase 3: App principale (1-2h)
**Fichiers à modifier:**
- `TasksV2View.swift` - track task_validated, task_skipped
- `HomeView.swift` - track quick actions
- `ProfileView.swift` - track achievement_unlocked

### Phase 4: Rétention (30min)
**Fichiers à modifier:**
- `CortiFreeApp.swift` - track first_app_launch
- Logic pour tracker day_1_active, day_3_active, etc.

---

## 💡 Tips Pro

### 1. Test en local
Utilise le filtre dans Events:
```
device_type = "iPhone Simulator"
```
Pour voir uniquement tes tests sans polluer les vraies données.

### 2. Annotations
Ajoute des annotations dans les graphiques pour marquer:
- Releases de nouvelles versions
- Campagnes marketing
- Changements majeurs de features

### 3. Alertes Slack
Configure Slack integration dans Mixpanel Settings pour recevoir les alertes importantes en temps réel.

### 4. Export data
Mixpanel permet d'exporter les données en CSV pour analyses externes (Excel, Google Sheets).

### 5. Formulas
Utilise les "Formulas" dans Insights pour calculer:
```
(onboarding_completed / onboarding_welcome_viewed) × 100
```
Pour avoir le taux de conversion directement dans le dashboard.

---

## 🎯 Dashboard final recommandé

### Row 1: Conversion
- Funnel Onboarding (large)
- Taux completion onboarding (%)

### Row 2: Engagement
- Tasks validées / jour (line chart)
- Distribution des streaks (bar chart)

### Row 3: Rétention
- Rétention J1/J3/J7/J30 (retention chart)
- DAU/MAU (line chart)

### Row 4: Features
- Achievements débloqués (bar chart)
- Journal entries créées (line chart)

### Row 5: Errors
- Erreurs / jour (line chart)
- Top 5 error types (table)

---

**Note:** Tous ces événements sont déjà codés dans `MixpanelManager.swift` (862 lignes), il suffit maintenant de les appeler dans les bonnes vues pendant les Phases 2-4.
