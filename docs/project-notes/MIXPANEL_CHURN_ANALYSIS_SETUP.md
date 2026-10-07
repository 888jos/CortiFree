# 🎯 Mixpanel Churn Analysis - CortiFree Onboarding

## ✅ Tracking Implementé pour Analyse de Churn

### 📊 Écrans Trackés (9/16 - 56% Onboarding Complete)

#### ✅ 1. FirstLaunchWelcomeView - Écran d'entrée
**Events:**
- `app_opened` - Lancement app
- `onboarding_welcome_viewed` - Premier écran vu
- `onboarding_welcome_continue` - Click "Commencer"

**Métriques Churn:**
- **Drop-off rate**: Combien d'users voient l'écran mais ne cliquent pas?
- **Time on screen**: Les users qui passent <5s vs >15s ont-ils des taux de conversion différents?

---

#### ✅ 2. ReassuranceView - Message de réassurance
**Events:**
- `onboarding_reassurance_viewed`
- `onboarding_reassurance_continue`

**Métriques Churn:**
- **Emotional connection**: Combien de temps les users passent à lire le message?
- **Drop-off rate**: % qui abandonnent après ce message

---

#### ✅ 3. HabitsQuizView - Quiz principal (12 questions) ⭐ CRITICAL
**Events:**
- `onboarding_quiz_started`
- `onboarding_quiz_question_answered` (×12)
- `onboarding_quiz_back_clicked`
- `onboarding_habits_quiz_completed`

**Métriques Churn - TRÈS IMPORTANTES:**
- **Question drop-off**: À quelle question les users abandonnent?
  - Question 1-4: Symptômes
  - Question 5-6: Contexte
  - Question 7-12: Baseline habits
- **Back button clicks**: Questions confusantes qui font revenir en arrière
- **Time per question**: Questions qui prennent trop de temps
- **Quiz completion rate**: % qui finissent vs abandonnent
- **Score distribution**: Est-ce que les low scores (stress élevé) abandonnent plus?

**Action Items:**
```sql
-- Mixpanel Query: Quiz Drop-off Analysis
SELECT
  question_number,
  COUNT(DISTINCT user_id) as users_reached,
  COUNT(CASE WHEN completed = true THEN user_id END) as users_completed,
  (users_completed / users_reached * 100) as completion_rate
FROM onboarding_quiz_question_answered
GROUP BY question_number
ORDER BY question_number
```

---

#### ✅ 4. SixtyDaysExplanationView - Explication du programme
**Events:**
- `onboarding_sixty_days_explanation_viewed`
- `onboarding_sixty_days_explanation_continue`

**Métriques Churn:**
- **Time on screen**: Est-ce que les users lisent ou skip rapidement?
- **Conversion rate**: % qui continuent après voir la durée (66 jours)

**Hypothesis:**
- Si drop-off élevé ici → Les users sont découragés par la durée du programme

---

#### ✅ 5. ScientificPlanView - Preuves scientifiques
**Events:**
- `onboarding_scientific_plan_viewed`
- `onboarding_scientific_plan_continue`

**Métriques Churn:**
- **Trust building**: Time on screen corrélé avec conversion?
- **Drop-off rate**: % qui abandonnent après voir les citations

---

#### ✅ 6. LoadingAnalysisView - Écran de chargement
**Events:**
- `onboarding_loading_analysis_viewed`
- `onboarding_loading_analysis_complete`

**Métriques Churn:**
- **Wait time tolerance**: Combien de users ferment l'app pendant le loading?
- **Completion rate**: % qui attendent jusqu'à 100%

---

#### ✅ 7. NotificationPermissionsView - Permissions notifs
**Events:**
- `onboarding_notification_permission_viewed`
- `onboarding_notification_permission_requested`
  - Properties: streakEnabled, dailyRitualEnabled, weeklyReportEnabled

**Métriques Churn:**
- **Permission grant rate**: % qui acceptent vs refusent
- **Toggle preferences**: Quels types de notifs sont les plus acceptés?
- **Drop-off après refus**: Est-ce que refuser les notifs = churn ultérieur?

**Correlation Analysis:**
```
Users who enable notifications → Higher Day 7 retention?
```

---

#### ✅ 8. OnboardingCompletionView - Fin onboarding ⭐ CRITICAL
**Events:**
- `onboarding_completed` (avec tous les scores)
- `onboarding_view_plan_clicked`

**User Identification:**
- `identify(userId)` - Association user
- `setUserProfile()` - Propriétés user

**Métriques Churn - CONVERSION FINALE:**
- **Onboarding completion rate**: (completed / app_opened) × 100
  - **Target: >70%**
- **Score correlation**: Est-ce que globalScore influence completion?
- **View plan rate**: % qui cliquent pour voir le plan

**This is your PRIMARY conversion metric!**

---

### 🎯 Funnel Onboarding Complet Trackable

```
100 users → app_opened
 ↓ ?% drop
80 users → onboarding_welcome_viewed
 ↓ ?% drop
75 users → onboarding_welcome_continue
 ↓ ?% drop
70 users → onboarding_reassurance_viewed
 ↓ ?% drop
68 users → onboarding_quiz_started
 ↓ ?% drop per question (CRITICAL)
50 users → onboarding_quiz_completed (26% drop in quiz!)
 ↓ ?% drop
48 users → onboarding_sixty_days_explanation_viewed
 ↓ ?% drop (Hypothesis: discouraged by 66 days)
45 users → onboarding_scientific_plan_viewed
 ↓ ?% drop
44 users → onboarding_loading_analysis_viewed
 ↓ ?% drop
43 users → onboarding_notification_permission_viewed
 ↓ ?% drop
42 users → onboarding_completed ⭐

FINAL CONVERSION RATE: 42%
```

**Target:** >70% conversion (app_opened → onboarding_completed)

---

## 📊 Dashboard Mixpanel - Configuration pour Churn Analysis

### 1. Insight: "Funnel Onboarding avec Drop-off"

**Type:** Funnel
**Steps:**
1. app_opened
2. onboarding_welcome_viewed
3. onboarding_quiz_started
4. onboarding_quiz_completed
5. onboarding_notification_permission_viewed
6. onboarding_completed

**Conversion Window:** 1 day
**Breakdown:** By `device_type`, `language`

**Expected Output:**
```
Step 1: 100% (1000 users)
Step 2: 85% (-15% drop) ⚠️ Investigate!
Step 3: 78% (-7% drop)
Step 4: 52% (-26% drop) 🚨 CRITICAL ISSUE!
Step 5: 48% (-4% drop)
Step 6: 42% (-6% drop)
```

**Action:** Si drop > 10% entre 2 steps → Investigate ce screen!

---

### 2. Insight: "Quiz Question Drop-off Heatmap"

**Type:** Segmentation
**Event:** `onboarding_quiz_question_answered`
**Group by:** `questionNumber`
**Unique users per question**

**Expected Pattern:**
- Question 1: 1000 users
- Question 2: 950 users (-5%)
- Question 3: 920 users (-3%)
- ...
- Question 8: 600 users (-35% depuis Q7!) 🚨

**If you see a sharp drop at a specific question:**
→ That question is too complex, too personal, or poorly worded

---

### 3. Insight: "Time Spent Distribution"

**Type:** Segmentation
**Events:** All `*_continue` events
**Formula:** AVG(`time_spent`)
**Breakdown:** By completion status

**Analysis:**
```
Users who completed onboarding:
- Avg time on welcome: 12s
- Avg time on quiz: 180s
- Avg time on explanations: 25s

Users who dropped off:
- Avg time on welcome: 5s (too fast = not engaged)
- Avg time on quiz: 45s (dropped mid-quiz)
- Avg time on explanations: 3s (skipped without reading)
```

**Hypothesis:** Users who read < 5s per screen have 3x higher churn

---

### 4. Insight: "Quiz Score Correlation with Completion"

**Type:** Segmentation
**Event:** `onboarding_habits_quiz_completed`
**Group by:** `global_score` (buckets: 0-30, 30-50, 50-70, 70-100)
**Show:** % who completed onboarding

**Expected Analysis:**
```
Global Score 0-30 (high stress): 35% complete onboarding
Global Score 30-50: 42% complete
Global Score 50-70: 48% complete
Global Score 70-100 (low stress): 55% complete
```

**Insight:** Users avec stress élevé abandonnent plus?
**Action:** Add more reassurance for low-score users

---

### 5. Cohort: "🚨 Quiz Drop-offs" (At-Risk)

**Definition:**
- Did `onboarding_quiz_started`
- Did NOT do `onboarding_quiz_completed`
- In last 7 days

**Size:** Should be <30% of quiz starters
**Action:** Send re-engagement email/push

---

### 6. Cohort: "💎 Onboarding Completers"

**Definition:**
- Did `onboarding_completed`

**Use for:**
- Retention analysis (Day 1, 3, 7, 30)
- Feature adoption rate
- Paywall conversion

---

## 🎯 KPIs de Churn à Suivre

### Onboarding Funnel (Primary Metrics)
1. **Welcome → Quiz start:** Target >90%
2. **Quiz start → Quiz complete:** Target >75% (CRITICAL)
3. **Quiz complete → Onboarding complete:** Target >85%
4. **Overall conversion:** Target >70%

### Quiz Performance (Secondary Metrics)
5. **Avg questions answered:** Target >10/12
6. **Back button clicks:** Target <5% of users
7. **Avg time per question:** Target 10-20s

### Engagement Indicators
8. **Avg time on explanation screens:** Target >15s
9. **Notification permission grant rate:** Target >60%
10. **View plan click rate:** Target >80%

---

## 🔥 Actions Immédiates selon Métriques

### Si Quiz completion rate < 60%:
1. Identifier la question avec le plus grand drop-off
2. A/B test wording de cette question
3. Réduire le nombre de questions (12 → 8)
4. Ajouter progress bar plus visible

### Si Drop-off après "66 jours":
1. Changer "66 jours" → "9 semaines"
2. Ajouter "résultats visibles dès la 1ère semaine"
3. Montrer success stories court-terme

### Si Notification refusal > 50%:
1. Retravailler le wording (moins "pushy")
2. Montrer la valeur avant de demander
3. Permettre de skip et demander plus tard

---

## 📈 Écrans Restants à Tracker (7/16)

**Priority MEDIUM** (moins critiques pour churn principal):
- [ ] CortiFreeRatingView
- [ ] EightHabitsIntroView
- [ ] WeekProgressView
- [ ] EightHabitsFlowView
- [ ] HabitsProgressFlowView
- [ ] SocialProofFlowView
- [ ] OverallQuizView (premier quiz avec firstName/age/gender)

**Estimation:** 1-2 heures pour compléter

---

## 🚀 Next Steps

1. **Lance l'app et teste le funnel complet**
2. **Vérifie que tous les events arrivent dans Mixpanel**
3. **Crée les 6 Insights dans Mixpanel dashboard**
4. **Attends 100-200 users pour avoir des données significatives**
5. **Analyse les drop-off rates** → Identifie les problèmes
6. **Itère sur les screens avec le plus de churn**

---

**Last Updated:** 2025-01-20
**Status:** 9/16 screens tracked (56%)
**Primary Conversion Funnel:** ✅ FULLY TRACKED
**Ready for Churn Analysis:** ✅ YES
