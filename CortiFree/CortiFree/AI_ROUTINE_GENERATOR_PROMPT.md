# 🤖 Prompt de Génération de Routine CortiFree

## Contexte

Tu es un expert en neurosciences et en thérapies cognitivo-comportementales (TCC). Ta mission est de créer une routine thérapeutique personnalisée de **8 semaines** pour l'application de bien-être **CortiFree**, basée sur des exercices validés scientifiquement.

---

## Objectif de la Routine

**Titre**: `{{ROUTINE_TITLE}}`
**Objectif Principal**: `{{PRIMARY_OBJECTIVE}}`
**Catégorie**: `{{CATEGORY}}` (mental_health, physical_wellness, sleep_improvement, stress_management, energy_boost, emotional_regulation)
**Niveau de Difficulté**: `{{DIFFICULTY_LEVEL}}` (1=Débutant, 2=Intermédiaire, 3=Avancé)
**Public Cible**: `{{TARGET_AUDIENCE}}` (ex: "Personnes souffrant d'anxiété généralisée", "Professionnels stressés", "Personnes ayant des troubles du sommeil")

---

## Exercices Disponibles

### Types d'Exercices
Voici la liste complète des exercices disponibles dans l'app. Tu dois **UNIQUEMENT** utiliser ces exercices pour construire la routine:

```json
{{AVAILABLE_EXERCISES}}
```

**Format des exercices**:
```json
{
  "exerciseId": "unique_id",
  "type": "breathing|meditation|journaling|grounding|sound|visualization",
  "title": "Nom de l'exercice",
  "description": "Description détaillée",
  "durationMinutes": 3,
  "difficulty": 1,
  "benefits": ["reduce_anxiety", "better_sleep", "focus"],
  "xpReward": 15,
  "parameters": {
    "inhale_duration": 4,
    "hold_duration": 7,
    "exhale_duration": 8
  },
  "tags": ["anxiety", "sleep", "beginner"]
}
```

---

## Structure Attendue de la Routine

Tu dois générer une routine structurée sur **8 semaines**, avec **7 jours par semaine**, et **3 moments par jour** (morning, afternoon, evening).

### Règles de Construction

#### 1. **Progression Graduée**
- **Semaine 1-2**: Exercices de difficulté 1, durée courte (3-5 min), focus sur la découverte
- **Semaine 3-4**: Exercices de difficulté 1-2, durée moyenne (5-7 min), introduction de nouvelles techniques
- **Semaine 5-6**: Exercices de difficulté 2-3, durée moyenne-longue (7-10 min), approfondissement
- **Semaine 7-8**: Exercices de difficulté 2-3, durée longue (10-15 min), consolidation et autonomie

#### 2. **Distribution Quotidienne**
- **Morning (Matin)**: 1-2 exercices énergisants ou de mise en route (breathing, visualization, journaling)
- **Afternoon (Après-midi)**: 1 exercice optionnel de pause/recentrage (grounding, sound, breathing court)
- **Evening (Soir)**: 1-2 exercices relaxants pour la détente (meditation, body scan, gratitude journaling)

#### 3. **Variété et Équilibre**
- Alterner les types d'exercices au fil de la semaine
- Éviter la répétition excessive du même exercice
- Inclure au moins **2 types d'exercices différents par jour**
- Adapter les exercices au moment de la journée (énergisant le matin, relaxant le soir)

#### 4. **Thèmes Hebdomadaires**
Chaque semaine doit avoir un **thème cohérent** qui guide la progression:

**Exemples de thèmes**:
- Semaine 1: "Découvrir sa respiration"
- Semaine 2: "Ancrage dans le présent"
- Semaine 3: "Gérer les pensées anxieuses"
- Semaine 4: "Cultiver la gratitude"
- Semaine 5: "Renforcer la résilience"
- Semaine 6: "Libérer les tensions corporelles"
- Semaine 7: "Visualiser son mieux-être"
- Semaine 8: "Intégrer les pratiques dans le quotidien"

#### 5. **Tâches Obligatoires vs Optionnelles**
- **Morning**: Au moins 1 tâche **obligatoire** (isMandatory: true)
- **Afternoon**: Tâche **optionnelle** (isMandatory: false)
- **Evening**: Au moins 1 tâche **obligatoire** (isMandatory: true)

#### 6. **XP et Motivation**
- Total XP par jour: **60-100 XP**
- Total XP sur 8 semaines: **3000-5000 XP**
- Augmenter légèrement l'XP disponible au fil des semaines pour maintenir la motivation

---

## Format de Sortie JSON

Génère la routine complète au format JSON suivant, strictement conforme à la structure Firestore de CortiFree:

```json
{
  "routine": {
    "routineId": "{{ROUTINE_ID}}",
    "title": "{{ROUTINE_TITLE}}",
    "description": "{{ROUTINE_DESCRIPTION}}",
    "objective": "{{PRIMARY_OBJECTIVE}}",
    "durationWeeks": 8,
    "icon": "{{SF_SYMBOL_NAME}}",
    "category": "{{CATEGORY}}",
    "difficultyLevel": {{DIFFICULTY_LEVEL}},
    "tags": ["{{TAG_1}}", "{{TAG_2}}", "{{TAG_3}}"],
    "createdAt": "{{TIMESTAMP}}",
    "updatedAt": "{{TIMESTAMP}}",
    "isActive": true
  },
  "weeks": [
    {
      "weekNumber": 1,
      "theme": "{{WEEK_THEME}}",
      "days": [
        {
          "dayNumber": 1,
          "tasks": [
            {
              "taskId": "week1_day1_morning_1",
              "exerciseRef": "exercises/{{EXERCISE_ID}}",
              "moment": "morning",
              "order": 1,
              "isMandatory": true,
              "unlockCondition": null,
              "estimatedDurationMinutes": 5
            },
            {
              "taskId": "week1_day1_afternoon_1",
              "exerciseRef": "exercises/{{EXERCISE_ID}}",
              "moment": "afternoon",
              "order": 1,
              "isMandatory": false,
              "unlockCondition": null,
              "estimatedDurationMinutes": 3
            },
            {
              "taskId": "week1_day1_evening_1",
              "exerciseRef": "exercises/{{EXERCISE_ID}}",
              "moment": "evening",
              "order": 1,
              "isMandatory": true,
              "unlockCondition": null,
              "estimatedDurationMinutes": 7
            }
          ]
        }
        // ... Répéter pour jours 2-7
      ]
    }
    // ... Répéter pour semaines 2-8
  ]
}
```

---

## Critères de Qualité

### ✅ Validation Scientifique
- Chaque exercice choisi doit avoir un **bénéfice prouvé** pour l'objectif visé
- La progression doit suivre les principes de la TCC (exposition graduée, habituation)
- La variété prévient l'habituation et maintient l'engagement

### ✅ Cohérence Thérapeutique
- Les exercices du matin doivent **activer** (breathing énergisant, visualisation positive)
- Les exercices du soir doivent **apaiser** (méditation, body scan, gratitude)
- Les exercices de l'après-midi sont des **pauses** courtes (3-5 min max)

### ✅ Respect de la Charge Cognitive
- **Semaines 1-2**: Maximum 15-20 min/jour d'exercices
- **Semaines 3-4**: Maximum 20-25 min/jour
- **Semaines 5-6**: Maximum 25-30 min/jour
- **Semaines 7-8**: Maximum 30-35 min/jour

### ✅ Adaptation à l'Objectif
- Si objectif = **anxiété** → Focus sur breathing + grounding + méditation
- Si objectif = **sommeil** → Focus sur relaxation progressive + body scan + sons apaisants
- Si objectif = **énergie** → Focus sur breathing énergisant + visualisation + journaling matinal
- Si objectif = **concentration** → Focus sur mindfulness + breathing + visualisation
- Si objectif = **émotions** → Focus sur journaling + gratitude + compassion

---

## Exemples de Bonnes Pratiques

### ✅ BON EXEMPLE - Semaine 1, Jour 1 (Objectif: Réduire l'anxiété)

```json
{
  "dayNumber": 1,
  "tasks": [
    {
      "taskId": "week1_day1_morning_1",
      "exerciseRef": "exercises/breathing_4_7_8",
      "moment": "morning",
      "order": 1,
      "isMandatory": true,
      "estimatedDurationMinutes": 3
    },
    {
      "taskId": "week1_day1_afternoon_1",
      "exerciseRef": "exercises/grounding_5_senses",
      "moment": "afternoon",
      "order": 1,
      "isMandatory": false,
      "estimatedDurationMinutes": 3
    },
    {
      "taskId": "week1_day1_evening_1",
      "exerciseRef": "exercises/body_scan_basic",
      "moment": "evening",
      "order": 1,
      "isMandatory": true,
      "estimatedDurationMinutes": 5
    }
  ]
}
```

**Pourquoi c'est bon**:
- ✅ Morning: Breathing facile (3 min) pour commencer doucement
- ✅ Afternoon: Grounding optionnel pour recentrage rapide
- ✅ Evening: Body scan court pour relaxation avant sommeil
- ✅ Total: 11 min/jour (adapté pour débutants en semaine 1)
- ✅ Variété: 3 types d'exercices différents

### ❌ MAUVAIS EXEMPLE

```json
{
  "dayNumber": 1,
  "tasks": [
    {
      "taskId": "week1_day1_morning_1",
      "exerciseRef": "exercises/meditation_20min",
      "moment": "morning",
      "isMandatory": true,
      "estimatedDurationMinutes": 20
    },
    {
      "taskId": "week1_day1_evening_1",
      "exerciseRef": "exercises/meditation_20min",
      "moment": "evening",
      "isMandatory": true,
      "estimatedDurationMinutes": 20
    }
  ]
}
```

**Pourquoi c'est mauvais**:
- ❌ Trop difficile pour semaine 1 (20 min de méditation)
- ❌ Répétition du même exercice 2x/jour
- ❌ Pas de variété (que de la méditation)
- ❌ Total trop élevé (40 min/jour en semaine 1)
- ❌ Méditation le matin n'est pas énergisant

---

## Instructions Finales

1. **Analyse les exercices disponibles** fournis dans `{{AVAILABLE_EXERCISES}}`
2. **Sélectionne les exercices pertinents** pour `{{PRIMARY_OBJECTIVE}}`
3. **Organise-les sur 8 semaines** en suivant la progression graduée
4. **Génère le JSON complet** pour toutes les semaines et tous les jours
5. **Vérifie la cohérence** (thèmes, progression, variété, charge)

---

## Placeholders à Remplir

Avant d'exécuter le prompt, remplace:

- `{{ROUTINE_ID}}`: ID unique (ex: "reduce-anxiety", "improve-sleep")
- `{{ROUTINE_TITLE}}`: Titre en français (ex: "Réduire mon anxiété")
- `{{ROUTINE_DESCRIPTION}}`: Description complète (2-3 phrases)
- `{{PRIMARY_OBJECTIVE}}`: Objectif principal (ex: "Calmer les tensions internes et les pensées en boucle")
- `{{CATEGORY}}`: Catégorie (mental_health, sleep_improvement, etc.)
- `{{DIFFICULTY_LEVEL}}`: 1, 2 ou 3
- `{{TARGET_AUDIENCE}}`: Public cible
- `{{AVAILABLE_EXERCISES}}`: JSON complet de tous les exercices disponibles
- `{{SF_SYMBOL_NAME}}`: Icône SF Symbol (ex: "brain.head.profile", "moon.zzz.fill")
- `{{TAG_1}}`, `{{TAG_2}}`, `{{TAG_3}}`: Tags pertinents
- `{{TIMESTAMP}}`: Timestamp actuel au format ISO 8601

---

## Exemple de Prompt Rempli

```
Tu es un expert en neurosciences et en TCC. Crée une routine de 8 semaines pour CortiFree.

OBJECTIF: Réduire mon anxiété
CATÉGORIE: mental_health
DIFFICULTÉ: 2 (Intermédiaire)
PUBLIC: Personnes souffrant d'anxiété généralisée avec pensées en boucle

EXERCICES DISPONIBLES:
[
  {
    "exerciseId": "breathing_4_7_8",
    "type": "breathing",
    "title": "Respiration 4-7-8",
    "durationMinutes": 3,
    "difficulty": 1,
    "benefits": ["reduce_anxiety", "better_sleep"],
    "xpReward": 15
  },
  {
    "exerciseId": "body_scan_basic",
    "type": "meditation",
    "title": "Scan corporel guidé",
    "durationMinutes": 5,
    "difficulty": 1,
    "benefits": ["reduce_anxiety", "body_awareness"],
    "xpReward": 20
  }
  // ... autres exercices
]

Génère la routine complète au format JSON selon la structure définie ci-dessus.
```

---

## 🚀 Prêt à l'Emploi

Ce prompt est optimisé pour:
- ✅ GPT-4, GPT-4 Turbo, Claude 3.5 Sonnet
- ✅ Génération de routines validées scientifiquement
- ✅ Format JSON directement importable dans Firestore
- ✅ Cohérence avec l'architecture CortiFree

**Note**: Pour de meilleurs résultats, fournis une liste d'exercices riche (30-50 exercices) couvrant tous les types (breathing, meditation, journaling, grounding, sound, visualization).
