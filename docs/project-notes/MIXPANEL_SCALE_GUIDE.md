# 📊 Guide Complet Mixpanel pour Scaler CortiFree

**Guide ultime pour transformer vos données Mixpanel en décisions actionnables et scaler votre app.**

---

## 🎯 Table des Matières

1. [Dashboard Setup - Configuration Initiale](#1-dashboard-setup)
2. [Funnels Critiques - Conversion Analysis](#2-funnels-critiques)
3. [Insights Essentiels - Data Visualizations](#3-insights-essentiels)
4. [Cohorts - Segmentation Utilisateurs](#4-cohorts-segmentation)
5. [Signals - Automated Alerts](#5-signals-alertes)
6. [Data Interpretation - Comment Lire](#6-interprétation-des-données)
7. [Action Plan - Que Faire Avec Les Données](#7-action-plan)
8. [KPIs à Suivre - Metrics That Matter](#8-kpis-critiques)

---

## 1. Dashboard Setup

### Connexion à Mixpanel

1. Va sur [eu.mixpanel.com](https://eu.mixpanel.com) (serveur EU)
2. Login avec ton compte
3. Sélectionne ton projet CortiFree
4. Tu vas créer un **Dashboard** custom

### Créer Ton Dashboard Principal

**Navigation:** Sidebar gauche → **Boards** → **+ Create Board**

Nomme-le: **"CortiFree - Onboarding & Retention Dashboard"**

---

## 2. Funnels Critiques

### Funnel 1: Onboarding Conversion (CRITIQUE)

**Objectif:** Identifier où les users abandonnent l'onboarding

**Configuration:**
1. Clique **+ Add Insight** → Sélectionne **Funnels**
2. Configure les steps:

```
Step 1: app_opened
Step 2: onboarding_welcome_continue_clicked
Step 3: onboarding_reassurance_continue
Step 4: onboarding_habits_quiz_completed
Step 5: onboarding_sixty_days_continue_clicked
Step 6: onboarding_scientific_plan_continue_clicked
Step 7: onboarding_loading_analysis_completed
Step 8: onboarding_notification_permission_requested
Step 9: onboarding_completed
```

**Settings:**
- Conversion window: **30 minutes** (temps max pour finir onboarding)
- Counting: **Total conversions**
- Breakdown: Aucun (pour l'instant)

**Comment Lire:**
- Tu verras un graphique avec % de conversion à chaque step
- **Drop-off >15% entre 2 steps = PROBLÈME MAJEUR**
- Exemple: Si 1000 users font `app_opened`, mais seulement 600 font `onboarding_welcome_continue_clicked` = **40% drop-off = URGENT**

**Actions:**
- Clique sur un step pour voir les users qui ont drop
- Utilise "Show properties" pour voir les caractéristiques communes des users qui drop

---

### Funnel 2: Quiz Completion (Question-by-Question)

**Objectif:** Savoir quelle question fait abandonner les users

**Configuration:**
1. **+ Add Insight** → **Funnels**
2. Configure:

```
Step 1: onboarding_quiz_question_answered (questionNumber = 1)
Step 2: onboarding_quiz_question_answered (questionNumber = 2)
Step 3: onboarding_quiz_question_answered (questionNumber = 3)
...
Step 12: onboarding_quiz_question_answered (questionNumber = 12)
Step 13: onboarding_habits_quiz_completed
```

**Settings:**
- Conversion window: **10 minutes**
- Breakdown by: `questionNumber`

**Comment Lire:**
- Si drop-off >10% à la question 7 → **Question 7 est trop difficile/longue/intrusive**
- Regarde la propriété `questionText` pour savoir quelle question c'est

---

### Funnel 3: 66-Day Commitment Test

**Objectif:** Tester si la mention "66 jours" décourage les users

**Configuration:**
```
Step 1: onboarding_habits_quiz_completed
Step 2: onboarding_sixty_days_explanation_viewed
Step 3: onboarding_sixty_days_continue_clicked
Step 4: onboarding_scientific_plan_continue_clicked
```

**Settings:**
- Conversion window: **5 minutes**
- Compare with: Previous period (pour trend analysis)

**Comment Lire:**
- Drop-off >20% entre Step 2 et 3 = "66 jours" fait peur
- **Action:** Considère A/B test avec "30 jours" ou "2 mois"

---

## 3. Insights Essentiels

### Insight 1: Time-on-Screen Analysis

**Objectif:** Savoir si les users lisent vraiment les screens ou skip

**Configuration:**
1. **+ Add Insight** → **Insights** → **Segmentation**
2. Event: `onboarding_*_continue` (sélectionne tous les events de continue)
3. Visualize: **Average** of property `time_spent`
4. Breakdown by: **Event name**
5. Date range: **Last 30 days**

**Comment Lire:**
- Time spent <5s = **Users skip le contenu** (mauvais signe)
- Time spent 15-30s = **Users lisent** (bon engagement)
- Time spent >60s = **Users sont perdus ou confus** (problème d'UX)

**Action:**
- Si time_spent <5s: **Contenu trop long ou pas intéressant**
- Simplifie le texte, ajoute des visuels

---

### Insight 2: Quiz Score Distribution

**Objectif:** Comprendre le profil de tes users (stress élevé vs faible)

**Configuration:**
1. **+ Add Insight** → **Insights** → **Segmentation**
2. Event: `onboarding_habits_quiz_completed`
3. Visualize: **Distribution** (histogram)
4. Property: `global_score`
5. Bucket size: **10** (0-10, 11-20, 21-30, etc.)

**Comment Lire:**
- Si majorité des users ont `global_score < 50` → **Target audience = high stress** (bon pour marketing)
- Si distribution bimodale (2 pics) → **2 segments d'audience différents**

**Action:**
- Crée 2 cohorts: "High Stress" (score <50) et "Low Stress" (score >70)
- Personnalise l'expérience pour chaque segment

---

### Insight 3: Notification Permission Acceptance Rate

**Objectif:** Mesurer l'efficacité de ton prompt notifications

**Configuration:**
1. **+ Add Insight** → **Insights** → **Segmentation**
2. Event: `onboarding_notification_permission_requested`
3. Breakdown by: Properties:
   - `streak_enabled`
   - `daily_ritual_enabled`
   - `weekly_report_enabled`
4. Visualize: **Total** count

**Comment Lire:**
- Si `streak_enabled = true` > 60% → **Bon taux d'acceptance**
- Si <40% → **Ton prompt n'est pas convaincant**

**Action:**
- A/B test différents messages de demande de permission
- Montre des preuves sociales ("85% des users activent les notifications")

---

### Insight 4: Back Button Clicks (Quiz Frustration)

**Objectif:** Détecter les questions qui font hésiter les users

**Configuration:**
1. **+ Add Insight** → **Insights** → **Segmentation**
2. Event: `onboarding_quiz_back_clicked`
3. Breakdown by: `fromQuestionNumber`
4. Visualize: **Total** count

**Comment Lire:**
- Si beaucoup de back clicks depuis question 8 → **Question 8 pose problème**
- Users hésitent ou ne comprennent pas

**Action:**
- Revois le wording de la question
- Ajoute un tooltip d'explication

---

## 4. Cohorts - Segmentation

### Cohort 1: Power Users

**Définition:** Users qui ont complété l'onboarding ET ont un engagement élevé

**Configuration:**
1. Sidebar → **Cohorts** → **+ Create Cohort**
2. Nom: **Power Users**
3. Conditions:
   - Did event: `onboarding_completed` **at least once**
   - AND User property: `global_score` **less than 50** (high stress = high engagement potential)

**Utilisation:**
- Cibler ces users pour beta features
- Demander des reviews
- Offrir early access à nouvelles fonctionnalités

---

### Cohort 2: At-Risk Users

**Définition:** Users qui ont commencé l'onboarding mais n'ont pas complété

**Configuration:**
1. **+ Create Cohort**
2. Nom: **At-Risk - Onboarding Dropoff**
3. Conditions:
   - Did event: `onboarding_welcome_viewed` **at least once**
   - AND Did NOT do event: `onboarding_completed`

**Utilisation:**
- Envoie un email de relance ("Tu n'as pas fini ton diagnostic")
- Push notification pour les rappeler
- A/B test des incentives (badge gratuit, contenu débloqué)

---

### Cohort 3: Quiz Completers (High Stress)

**Définition:** Users avec stress élevé (ton audience cible)

**Configuration:**
1. **+ Create Cohort**
2. Nom: **High Stress Segment**
3. Conditions:
   - Did event: `onboarding_habits_quiz_completed` **at least once**
   - AND Event property: `global_score` **less than 50**

**Utilisation:**
- Marketing messaging: "Rejoins 1000+ personnes qui ont réduit leur stress"
- Personnalise le contenu de l'app

---

### Cohort 4: Skeptical Users (Dropped After "66 Days")

**Définition:** Users qui ont drop après l'explication "66 jours"

**Configuration:**
1. **+ Create Cohort**
2. Nom: **Skeptical - 66 Days Dropoff**
3. Conditions:
   - Did event: `onboarding_sixty_days_explanation_viewed` **at least once**
   - AND Did NOT do event: `onboarding_sixty_days_continue_clicked`

**Utilisation:**
- Test si mentionner "66 jours" trop tôt est un problème
- A/B test: ne pas mentionner la durée avant la fin de l'onboarding

---

## 5. Signals - Alertes

### Signal 1: Drop-Off Spike Alert

**Objectif:** Être notifié si le drop-off rate augmente soudainement

**Configuration:**
1. Sidebar → **Signals** → **+ Create Signal**
2. Type: **Funnel**
3. Sélectionne ton funnel "Onboarding Conversion"
4. Alert when: **Conversion rate decreases by 10% or more**
5. Compared to: **Previous 7 days**
6. Notify via: **Email**

**Utilité:**
- Si un bug apparaît, tu seras alerté immédiatement
- Si un changement d'UX fait baisser la conversion, tu le sais en temps réel

---

### Signal 2: Power User Growth Alert

**Objectif:** Célébrer quand tu gagnes des power users

**Configuration:**
1. **+ Create Signal**
2. Type: **Cohort**
3. Cohort: **Power Users**
4. Alert when: **Cohort size increases by 20% or more**
5. Compared to: **Previous 7 days**

**Utilité:**
- Savoir quand ta croissance accélère
- Moment idéal pour fundraising ou communication

---

## 6. Interprétation des Données

### Que Signifient Les Métriques?

#### Funnel Conversion Rate

| Taux | Interprétation | Action |
|------|----------------|--------|
| >70% | Excellent - onboarding fluide | Keep it, optimise les détails |
| 50-70% | Bon - améliorations possibles | Teste quelques A/B tests |
| 30-50% | Moyen - problèmes d'UX | Refonte partielle nécessaire |
| <30% | Critique - onboarding cassé | URGENT - Analyse logs, sessions recordings |

---

#### Time on Screen

| Temps | Interprétation | Action |
|-------|----------------|--------|
| <5s | Users skip | Simplifie ou rends plus visuel |
| 5-15s | Lecture rapide | OK si le contenu est court |
| 15-30s | Bon engagement | Idéal pour contenu important |
| 30-60s | Lecture attentive ou confusion | Vérifie heatmaps (si disponible) |
| >60s | Perdus ou bloqués | UX problem - simplifie |

---

#### Quiz Drop-off per Question

| Drop-off | Interprétation | Action |
|----------|----------------|--------|
| <5% | Question OK | Rien à faire |
| 5-10% | Légère friction | Améliore le wording |
| 10-20% | Problème notable | Revois la question ou la rends optionnelle |
| >20% | Bloquante | SUPPRIME ou reformule complètement |

---

## 7. Action Plan - Que Faire Avec Les Données

### Scénario 1: Drop-off Massif à un Screen Spécifique

**Exemple:** 40% des users drop après `onboarding_sixty_days_explanation_viewed`

**Diagnostic:**
1. Regarde `time_spent` sur ce screen
   - Si <5s → Users ne lisent pas, contenu trop long
   - Si >30s → Users lisent mais ne sont pas convaincus

2. Regarde les users qui ont réussi vs ceux qui drop
   - **Cohort comparison:** Users who did `onboarding_sixty_days_continue_clicked` vs Users who didn't
   - Compare leurs propriétés (`global_score`, `age`, `gender`)

**Actions:**
- **Test A:** Raccourcis le texte de 50%
- **Test B:** Ajoute une vidéo explicative (30s)
- **Test C:** Change l'ordre des screens (mets ce screen APRÈS l'authentification)

---

### Scénario 2: Quiz Completion Faible

**Exemple:** Seulement 50% des users qui commencent le quiz le terminent

**Diagnostic:**
1. Regarde question-by-question drop-off
   - Identifie les questions avec >10% drop
2. Regarde `timeToAnswer` pour ces questions
   - Si >20s → Question trop complexe

**Actions:**
- **Immédiat:** Simplifie les questions problématiques
- **Moyen terme:** Réduis le nombre de questions (12 → 8)
- **Long terme:** Quiz adaptatif (skip questions selon réponses précédentes)

---

### Scénario 3: Bon Taux de Conversion Mais Peu de Retention

**Exemple:** 75% complètent onboarding, mais seulement 20% reviennent J+3

**Diagnostic:**
- Les users complètent l'onboarding mais ne voient pas la valeur dans l'app

**Actions:**
1. **Analyse post-onboarding:** Ajoute tracking pour:
   - `first_task_validated` (combien de temps après onboarding?)
   - `day_1_active`, `day_3_active` (reviennent-ils?)
2. **Améliore l'onboarding completion:**
   - Montre immédiatement une tâche facile à compléter
   - Quick win dès la fin de l'onboarding
3. **Push notifications:**
   - Rappel J+1: "Prêt pour ton premier exercice?"

---

### Scénario 4: Users Complètent Vite Mais Sans Lire

**Exemple:** Temps moyen sur chaque screen <5s, mais 80% complètent l'onboarding

**Diagnostic:**
- Users skip le contenu pour accéder à l'app
- Bonne conversion, MAIS mauvaise éducation utilisateur

**Risque:**
- Users ne comprennent pas la valeur de l'app → Churn élevé après J+7

**Actions:**
1. **Gamification:** Ajoute points/badges pour lire le contenu
2. **Interactive quiz:** Change le quiz en conversationnel (type chatbot)
3. **Progressive disclosure:** Révèle du contenu éducatif DANS l'app (pas pendant onboarding)

---

## 8. KPIs Critiques

### Onboarding KPIs (Priorité 1)

| KPI | Formule | Target | Fréquence |
|-----|---------|--------|-----------|
| **Overall Conversion Rate** | (onboarding_completed / app_opened) × 100 | >70% | Daily |
| **Welcome → Quiz Start** | (onboarding_reassurance_continue / onboarding_welcome_continue_clicked) × 100 | >90% | Daily |
| **Quiz Completion Rate** | (onboarding_habits_quiz_completed / onboarding_quiz_question_answered[Q1]) × 100 | >75% | Daily |
| **66-Day Acceptance** | (onboarding_sixty_days_continue_clicked / onboarding_sixty_days_explanation_viewed) × 100 | >80% | Weekly |
| **Notification Permission** | (streak_enabled=true / onboarding_notification_permission_requested) × 100 | >60% | Weekly |
| **Avg Onboarding Time** | AVG(total_time) where event=onboarding_completed | 45-90s | Weekly |

---

### Engagement KPIs (Priorité 2 - À implémenter Phase 3)

| KPI | Formule | Target | Fréquence |
|-----|---------|--------|-----------|
| **D1 Retention** | Users active J+1 / Users completed onboarding | >40% | Daily |
| **D7 Retention** | Users active J+7 / Users completed onboarding | >20% | Weekly |
| **D30 Retention** | Users active J+30 / Users completed onboarding | >10% | Monthly |
| **Task Completion Rate** | task_validated / onboarding_completed | >5 tasks/user | Weekly |
| **Streak Avg Length** | AVG(current_streak) | >3 days | Weekly |

---

### Growth KPIs (Priorité 3 - Scaling)

| KPI | Formule | Target | Fréquence |
|-----|---------|--------|-----------|
| **Weekly Active Users** | COUNT(DISTINCT users with any event in last 7 days) | Growth +10%/week | Weekly |
| **Viral Coefficient** | (New users from referral / Total users) | >0.15 | Monthly |
| **Paywall Conversion** | (Subscriptions / onboarding_completed) | >5% | Monthly |

---

## 9. Mixpanel Features Avancées

### A/B Testing avec Mixpanel Experiments

**Utilisation:** Tester 2 versions du même screen

**Exemple:** Tester "66 jours" vs "2 mois"

**Setup:**
1. Sidebar → **Experiments** → **+ Create Experiment**
2. Nom: **Sixty Days Wording Test**
3. Variants:
   - Control (50%): "66 jours" (actuel)
   - Variant A (50%): "2 mois"
4. Success metric: `onboarding_sixty_days_continue_clicked`
5. Sample size: 200 users minimum
6. Duration: 7 days

**Dans ton code Swift:**
```swift
// Get experiment variant
let variant = MixpanelManager.shared.getExperimentVariant("SixtyDaysWordingTest")

// Show different text based on variant
let durationText = variant == "variantA" ? "2 mois" : "66 jours"
```

---

### Session Replay (Si disponible - feature payante)

**Utilité:**
- Voir exactement ce que les users font (vidéo de session)
- Identifier problèmes d'UX invisibles dans les métriques

**Quand l'utiliser:**
- Après avoir identifié un drop-off point, regarde 10-20 sessions de users qui drop
- Tu verras s'ils:
  - Cliquent sur des éléments non-clickables (bug)
  - Scrollent sans trouver le bouton (UX problem)
  - Restent bloqués (loading infini?)

---

### Custom Reports avec SQL (Mixpanel Premium)

**Utilité:**
- Requêtes complexes que l'UI ne permet pas

**Exemple:** Trouver les users qui ont répondu "oui" à une question spécifique du quiz

```sql
SELECT distinct_id, properties.$email
FROM events
WHERE event = 'onboarding_quiz_question_answered'
  AND properties.questionNumber = 5
  AND properties.answerIndex = 1
  AND time >= '2025-11-01'
```

---

## 10. Checklist Hebdomadaire

### Chaque Lundi Matin (15 minutes)

- [ ] Regarde le funnel "Onboarding Conversion"
  - Note le taux de conversion global
  - Compare à la semaine dernière (+/- X%)
- [ ] Identifie le screen avec le plus grand drop-off
  - Si >15%, ajoute-le à ta todo list de fixes
- [ ] Vérifie les Signals/Alerts
  - As-tu reçu une alerte cette semaine?
  - Si oui, investigue immédiatement

---

### Chaque Mois (1 heure)

- [ ] Analyse les cohorts
  - Combien de Power Users as-tu gagné?
  - Combien de At-Risk users?
- [ ] Compare les métriques month-over-month
  - Onboarding conversion: +/- X%?
  - Avg time on screen: +/- X secondes?
- [ ] Identifie 1-2 optimisations à tester ce mois-ci
  - Exemple: "Tester une version plus courte du quiz"

---

## 11. Ressources Utiles

### Documentation Mixpanel

- [Mixpanel Funnels Guide](https://docs.mixpanel.com/docs/analysis/funnels)
- [Mixpanel Cohorts Guide](https://docs.mixpanel.com/docs/users/cohorts)
- [Mixpanel Signals (Alerts)](https://docs.mixpanel.com/docs/analysis/signals)

### Templates de Questions à Se Poser

**Conversion:**
- Quel screen a le pire drop-off?
- Pourquoi les users drop à ce screen?
- Qu'est-ce qui a changé cette semaine? (nouveau build, marketing campaign?)

**Engagement:**
- Les users qui complètent l'onboarding rapidement (<60s) ont-ils un meilleur retention que ceux qui prennent >120s?
- Les users avec `global_score < 50` (high stress) reviennent-ils plus souvent?

**Optimisation:**
- Si je réduis le quiz de 12 à 8 questions, est-ce que ça augmente la completion rate sans perdre en data quality?
- Si je change l'ordre des screens, est-ce que ça améliore la conversion?

---

## 12. Next Steps

### Phase 3: Main App Tracking (À faire maintenant)

**Objectif:** Tracker l'usage de l'app APRÈS l'onboarding

**Events critiques à implémenter:**
1. `task_validated` → Combien de tâches les users complètent?
2. `achievement_unlocked` → Gamification engagement
3. `quick_action_breathing_clicked` → Usage des quick actions
4. `journal_entry_created` → Usage du journal

**Impact:**
- Savoir si les users utilisent vraiment l'app après l'onboarding
- Identifier les features les plus populaires
- Optimiser le contenu pour les tâches les plus complétées

---

### Phase 4: Retention Milestones (Ensuite)

**Events:**
- `day_1_active` → User revient J+1
- `day_7_active` → User revient J+7 (CRITIQUE pour retention)
- `day_30_active` → User revient J+30
- `day_66_completed` → User a fini le programme (HOLY GRAIL)

**Impact:**
- Mesurer la vraie valeur de ton app
- Prouver aux investors que tu as product-market fit
- Identifier les moments où les users churn pour intervenir

---

## 📞 Besoin d'Aide?

**Problèmes courants:**

1. **"Je ne vois pas mes events dans Mixpanel"**
   - Vérifie que l'app est en DEBUG mode
   - Regarde les logs Xcode: `[Mixpanel] Event tracked: ...`
   - Events apparaissent 30-60s après tracking

2. **"Mon funnel montre 0% conversion"**
   - Vérifie que les noms d'events sont EXACTS (case-sensitive)
   - Regarde la fenêtre de conversion (augmente à 1 heure)

3. **"Trop de données, je suis perdu"**
   - Commence par 1 seul KPI: Overall Onboarding Conversion
   - Ajoute 1 nouveau KPI par semaine

---

**Dernière mise à jour:** 2025-11-21
**Version:** 1.0
**Status:** Prêt pour scaling

---

## 🚀 Résumé Exécutif (Pour Les Pressés)

**3 Steps pour commencer:**

1. **Crée le Funnel "Onboarding Conversion"** (5 min)
   - Va sur Mixpanel → Funnels → Ajoute les 9 steps
   - Regarde le taux de conversion global
   - Identifie le screen avec le plus gros drop-off

2. **Crée l'Insight "Time on Screen"** (3 min)
   - Segmentation → Event: `onboarding_*_continue`
   - Property: `time_spent` (average)
   - Breakdown by: Event name
   - Vois si users lisent vraiment (<5s = skip)

3. **Set up 1 Signal d'Alerte** (2 min)
   - Signals → Funnel alert
   - Alert si conversion baisse >10%
   - Email notification

**Total: 10 minutes pour avoir les insights critiques.**

**Ensuite:** Reviens chaque lundi pour checker, itère sur les problèmes.

---

**Questions? Tu peux uploader ce fichier dans Claude et demander:**
- "Comment créer le funnel X exactement?"
- "J'ai un drop-off de 40% au screen Y, que faire?"
- "Comment interpréter cette métrique Z?"

