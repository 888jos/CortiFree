# Guide Complet - Configuration Funnel Mixpanel pour CortiFree

## Contexte

Je développe une app iOS appelée **CortiFree** (app de méditation/bien-être). J'ai implémenté un onboarding complet avec tracking Mixpanel. Les événements sont bien envoyés et visibles dans la section "Events" de Mixpanel, mais je n'arrive pas à les sélectionner dans le builder de Funnel.

## Configuration Mixpanel

- **Serveur** : EU (Europe)
- **Mode** : DEBUG avec flush interval de 5 secondes
- **SDK** : Mixpanel Swift SDK

## Événements Implémentés (dans l'ordre du flow)

Voici la liste **exacte** des événements envoyés par l'app, dans l'ordre chronologique du parcours utilisateur :

### 1. Welcome Screen
- `onboarding_welcome_viewed`
- `onboarding_welcome_clicked`

### 2. Overall Quiz (5 questions : genre, âge, découverte app, raisons stress, durée stress)
- `onboarding_overall_quiz_viewed`
- `onboarding_overall_quiz_q1_viewed`
- `onboarding_overall_quiz_q1_clicked`
- `onboarding_overall_quiz_q2_viewed`
- `onboarding_overall_quiz_q2_clicked`
- `onboarding_overall_quiz_q3_viewed`
- `onboarding_overall_quiz_q3_clicked`
- `onboarding_overall_quiz_q4_viewed`
- `onboarding_overall_quiz_q4_clicked`
- `onboarding_overall_quiz_q5_viewed`
- `onboarding_overall_quiz_q5_clicked`
- `onboarding_overall_quiz_clicked` (quiz terminé)

### 3. Reassurance Screen
- `onboarding_reassurance_viewed`
- `onboarding_reassurance_clicked`

### 4. Habits Quiz (11 questions sur les habitudes de vie)
- `onboarding_habits_quiz_viewed`
- `onboarding_habits_quiz_q1_viewed`
- `onboarding_habits_quiz_q1_clicked`
- `onboarding_habits_quiz_q2_viewed`
- `onboarding_habits_quiz_q2_clicked`
- `onboarding_habits_quiz_q3_viewed`
- `onboarding_habits_quiz_q3_clicked`
- `onboarding_habits_quiz_q4_viewed`
- `onboarding_habits_quiz_q4_clicked`
- `onboarding_habits_quiz_q5_viewed`
- `onboarding_habits_quiz_q5_clicked`
- `onboarding_habits_quiz_q6_viewed`
- `onboarding_habits_quiz_q6_clicked`
- `onboarding_habits_quiz_q7_viewed`
- `onboarding_habits_quiz_q7_clicked`
- `onboarding_habits_quiz_q8_viewed`
- `onboarding_habits_quiz_q8_clicked`
- `onboarding_habits_quiz_q9_viewed`
- `onboarding_habits_quiz_q9_clicked`
- `onboarding_habits_quiz_q10_viewed`
- `onboarding_habits_quiz_q10_clicked`
- `onboarding_habits_quiz_q11_viewed`
- `onboarding_habits_quiz_q11_clicked`
- `onboarding_habits_quiz_clicked` (quiz terminé)

### 5. Sixty Days Explanation
- `onboarding_sixty_days_viewed`
- `onboarding_sixty_days_clicked`

### 6. Scientific Plan
- `onboarding_scientific_plan_viewed`
- `onboarding_scientific_plan_clicked`

### 7. Authentication
- `onboarding_authentication_viewed`
- `onboarding_authentication_clicked` (avec property `auth_method`: "email" | "google" | "apple")

### 8. Loading Analysis
- `onboarding_loading_analysis_viewed`
- `onboarding_loading_analysis_clicked`

### 9. CortiFree Rating
- `onboarding_cortifree_rating_viewed`
- `onboarding_cortifree_rating_clicked`

### 10. Eight Habits Intro
- `onboarding_eight_habits_intro_viewed`
- `onboarding_eight_habits_intro_clicked`

### 11. Week Progress
- `onboarding_week_progress_viewed`
- `onboarding_week_progress_clicked`

### 12. Eight Habits Flow
- `onboarding_eight_habits_flow_viewed`
- `onboarding_eight_habits_flow_clicked`

### 13. Notifications Permission
- `onboarding_notifications_viewed`

### 14. Habits Progress
- `onboarding_habits_progress_viewed`
- `onboarding_habits_progress_clicked`

### 15. Testimonials / Social Proof
- `onboarding_testimonials_viewed`
- `onboarding_testimonials_clicked`

### 16. Paywall
- `onboarding_paywall_viewed`

### 17. Completion
- `onboarding_completed`

---

## Logs Console (preuve que les événements sont envoyés)

Voici un extrait des logs de l'app montrant que les événements sont bien envoyés :

```
[Mixpanel] 📊 Event: onboarding_welcome_viewed
[Mixpanel] 💾 Flush executed for event: onboarding_welcome_viewed
[Mixpanel] 📊 Event: onboarding_welcome_clicked
[Mixpanel] 💾 Flush executed for event: onboarding_welcome_clicked
[Mixpanel] 📊 Event: onboarding_overall_quiz_viewed
[Mixpanel] 💾 Flush executed for event: onboarding_overall_quiz_viewed
[Mixpanel] 📊 Event: onboarding_overall_quiz_q1_viewed
[Mixpanel] 💾 Flush executed for event: onboarding_overall_quiz_q1_viewed
[Mixpanel] 📊 Event: onboarding_overall_quiz_q1_clicked
[Mixpanel] 💾 Flush executed for event: onboarding_overall_quiz_q1_clicked
[Mixpanel] 📊 Event: onboarding_overall_quiz_q2_viewed
... (tous les événements jusqu'à)
[Mixpanel] 📊 Event: onboarding_habits_quiz_q11_clicked
[Mixpanel] 📊 Event: onboarding_habits_quiz_clicked
[Mixpanel] 📊 Event: onboarding_paywall_viewed
[Mixpanel] 📊 Event: onboarding_completed
```

---

## Mon Problème

1. Je vais dans Mixpanel → **Events** → Je vois bien tous mes événements listés (onboarding_overall_quiz_q1_viewed, etc.)

2. Je vais dans Mixpanel → **Funnels** → Je clique sur "Create Funnel" ou j'édite un funnel existant

3. Quand j'essaie d'ajouter une étape et de sélectionner un événement, **les événements q1, q2, etc. n'apparaissent pas dans la liste de sélection**

4. Les événements principaux comme `onboarding_welcome_viewed` apparaissent, mais pas les événements de questions individuelles

---

## Ce que je veux faire

### Funnel Simplifié (par écran)
Créer un funnel avec uniquement les événements `_viewed` de chaque écran principal :

1. `onboarding_welcome_viewed`
2. `onboarding_overall_quiz_viewed`
3. `onboarding_reassurance_viewed`
4. `onboarding_habits_quiz_viewed`
5. `onboarding_sixty_days_viewed`
6. `onboarding_scientific_plan_viewed`
7. `onboarding_authentication_viewed`
8. `onboarding_loading_analysis_viewed`
9. `onboarding_cortifree_rating_viewed`
10. `onboarding_eight_habits_intro_viewed`
11. `onboarding_week_progress_viewed`
12. `onboarding_eight_habits_flow_viewed`
13. `onboarding_notifications_viewed`
14. `onboarding_habits_progress_viewed`
15. `onboarding_testimonials_viewed`
16. `onboarding_paywall_viewed`
17. `onboarding_completed`

### Funnel Détaillé Overall Quiz
1. `onboarding_overall_quiz_viewed`
2. `onboarding_overall_quiz_q1_viewed`
3. `onboarding_overall_quiz_q1_clicked`
4. `onboarding_overall_quiz_q2_viewed`
5. `onboarding_overall_quiz_q2_clicked`
6. `onboarding_overall_quiz_q3_viewed`
7. `onboarding_overall_quiz_q3_clicked`
8. `onboarding_overall_quiz_q4_viewed`
9. `onboarding_overall_quiz_q4_clicked`
10. `onboarding_overall_quiz_q5_viewed`
11. `onboarding_overall_quiz_q5_clicked`
12. `onboarding_overall_quiz_clicked`

### Funnel Détaillé Habits Quiz
1. `onboarding_habits_quiz_viewed`
2. `onboarding_habits_quiz_q1_viewed`
3. `onboarding_habits_quiz_q1_clicked`
4. ... (jusqu'à q11)
12. `onboarding_habits_quiz_clicked`

---

## Questions

1. **Pourquoi les événements apparaissent dans "Events" mais pas dans le sélecteur de Funnel ?**

2. **Y a-t-il un délai de synchronisation entre l'ingestion des événements et leur disponibilité dans les Funnels ?**

3. **Faut-il faire une action spécifique pour "activer" ou "indexer" les nouveaux événements ?**

4. **Est-ce que le fait d'utiliser des caractères spéciaux (underscore, chiffres) dans les noms d'événements pose problème ?**

5. **Comment créer correctement un Funnel avec tous ces événements ?**

---

## Informations Supplémentaires

- Les événements ont été envoyés aujourd'hui (8 décembre 2025)
- Le projet Mixpanel est sur le serveur EU
- J'utilise le plan gratuit de Mixpanel
- L'app est en développement (pas encore sur l'App Store)

---

Merci de me guider pas à pas pour :
1. Comprendre pourquoi les événements ne sont pas sélectionnables
2. Créer les 3 funnels décrits ci-dessus
