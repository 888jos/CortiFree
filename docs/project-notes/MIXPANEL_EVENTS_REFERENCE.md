# 📊 Mixpanel Events Reference - CortiFree

Quick reference de tous les events Mixpanel trackés.

---

## ✅ Events Actifs (30+)

### App Lifecycle
| Event | Properties | Où | Description |
|-------|-----------|-----|-------------|
| `app_opened` | - | CortiFreeApp.swift | App launched |

---

### Onboarding V2 - Welcome Flow

#### FirstLaunchWelcomeView
| Event | Properties | Description |
|-------|-----------|-------------|
| `onboarding_welcome_viewed` | - | Screen view |
| `onboarding_welcome_continue` | `time_spent` | Button click |

#### ReassuranceView
| Event | Properties | Description |
|-------|-----------|-------------|
| `onboarding_reassurance_viewed` | `user_name` | Screen view |
| `onboarding_reassurance_continue` | `time_spent` | Button click |

---

### Onboarding V2 - Quiz (CRITICAL)

#### HabitsQuizView
| Event | Properties | Description |
|-------|-----------|-------------|
| `onboarding_quiz_question_answered` | `questionNumber`, `questionText`, `answerIndex`, `answerText`, `timeToAnswer` | Each answer (×12) |
| `onboarding_quiz_back_clicked` | `fromQuestionNumber` | Back button |
| `onboarding_habits_quiz_completed` | Voir détails ci-dessous | Quiz complete |

**Properties pour `onboarding_habits_quiz_completed`:**
- `total_time` - Temps total du quiz
- `serenity_score`, `sleep_score`, `energy_score`, `focus_score`, `habits_score`, `balance_score`, `global_score`
- `baseline_wake_time`, `baseline_sleep_duration`, `baseline_water_intake`
- `baseline_exercise_frequency`, `baseline_meditation_frequency`, `baseline_available_time`
- `has_physical_limitations`, `primary_goal`

---

### Onboarding V2 - Explanation & Trust

#### SixtyDaysExplanationView
| Event | Properties | Description |
|-------|-----------|-------------|
| `onboarding_sixty_days_explanation_viewed` | - | Screen view |
| `onboarding_sixty_days_continue_clicked` | `time_spent` | Button click |

#### ScientificPlanView
| Event | Properties | Description |
|-------|-----------|-------------|
| `onboarding_scientific_plan_viewed` | - | Screen view |
| `onboarding_scientific_plan_continue_clicked` | `time_spent` | Button click |

#### LoadingAnalysisView
| Event | Properties | Description |
|-------|-----------|-------------|
| `onboarding_loading_analysis_viewed` | - | Screen view |
| `onboarding_loading_analysis_completed` | `loading_duration` | Loading done |

---

### Onboarding V2 - Permissions & Completion

#### NotificationPermissionsView
| Event | Properties | Description |
|-------|-----------|-------------|
| `onboarding_notification_permission_viewed` | - | Screen view |
| `onboarding_notification_permission_requested` | `streak_enabled`, `daily_ritual_enabled`, `weekly_report_enabled` | Permission request |

#### OnboardingCompletionView (CRITICAL)
| Event | Properties | Description |
|-------|-----------|-------------|
| `onboarding_completed` | Voir détails ci-dessous | Final completion ⭐ |
| `onboarding_view_plan_clicked` | - | View plan button |

**Properties pour `onboarding_completed`:**
- `total_time` - Temps total onboarding
- `quiz_global_score` - Score quiz
- `selected_goals_count` - Nombre objectifs
- `notifications_enabled` - Permission accordée?
- `user_id` - Firebase UID
- `first_name`, `age`, `gender` - Démographie

**User Identification:**
- `identify(userId)` - Associe user
- `setUserProfile()` - Propriétés Mixpanel People

---

## ⏳ Events Prêts mais Non Actifs

### Onboarding V2 - Secondary Screens (7 restants)
- CortiFreeRatingView
- EightHabitsIntroView
- WeekProgressView
- EightHabitsFlowView
- HabitsProgressFlowView
- SocialProofFlowView
- OverallQuizView

### Phase 3 - Main App (À implémenter)
- `task_validated` ⭐
- `task_skipped`
- `achievement_unlocked`
- `badge_unlocked`
- `quick_action_breathing_clicked`
- `quick_action_meditation_clicked`
- `quick_action_sounds_clicked`
- `quick_action_journal_clicked`
- `journal_entry_created`
- `breathing_exercise_started`
- `breathing_exercise_completed`
- `meditation_session_started`
- `meditation_session_completed`

### Phase 4 - Retention (À implémenter)
- `first_app_launch`
- `first_task_completed`
- `day_1_active`, `day_3_active`, `day_7_active`
- `day_14_active`, `day_30_active`
- `day_66_completed` (FIN PROGRAMME)

---

## 📊 Super Properties (Sent with Every Event)

Propriétés automatiques envoyées avec chaque event:

| Property | Value | Description |
|----------|-------|-------------|
| `app_version` | "1.0" (example) | Version de l'app |
| `os_version` | "iOS 18.0" (example) | Version iOS |
| `device_type` | "iPhone 15 Pro" (example) | Modèle appareil |
| `language` | "fr" / "en" | Langue app |
| `platform` | "iOS" | Platform |

---

## 🎯 Event Naming Convention

**Pattern:** `{category}_{screen/action}_{detail}`

**Examples:**
- `onboarding_welcome_viewed` - Category: onboarding, Screen: welcome, Detail: viewed
- `onboarding_quiz_question_answered` - Category: onboarding, Screen: quiz, Detail: question_answered
- `task_validated` - Category: task, Action: validated

---

## 🔍 Comment Utiliser cet Event dans Mixpanel

### 1. Funnel
```
Step 1: onboarding_welcome_viewed
Step 2: onboarding_quiz_question_answered
Step 3: onboarding_habits_quiz_completed
Step 4: onboarding_completed
```

### 2. Segmentation (Time Analysis)
- Event: `onboarding_welcome_continue`
- Group by: Bucket `time_spent` (0-5s, 5-15s, 15-30s, >30s)
- Show: Conversion rate to `onboarding_quiz_question_answered`

### 3. Cohort (Quiz Completers)
- Users who did: `onboarding_habits_quiz_completed`
- And have property: `global_score < 50` (high stress)

---

## 🚀 Quick Event Search

**Quiz drop-off:**
```
onboarding_quiz_question_answered
→ Filter by questionNumber (1-12)
→ Show unique users per question
```

**Time spent distribution:**
```
onboarding_*_continue
→ Formula: AVG(time_spent)
→ Breakdown by completion status
```

**Notification impact:**
```
onboarding_notification_permission_requested
→ Filter by streak_enabled = true
→ Show Day 7 retention rate
```

---

**Last Updated:** 2025-11-20
**Active Events:** 30+
**Ready Events:** 100+
