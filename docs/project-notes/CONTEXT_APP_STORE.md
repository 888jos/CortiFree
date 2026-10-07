# CortiFree - Document de Contexte Complet

## 📱 Vue d'ensemble

**CortiFree** est une application iOS de bien-être mental et réduction du stress basée sur un **programme de transformation de 66 jours** scientifiquement validé.

### Proposition de valeur
- Programme structuré de 66 jours avec 68% de réduction du stress moyenne
- 8 habitudes fondamentales progressives (difficulté croissante semaine après semaine)
- Exercices anti-stress personnalisés selon la situation
- Gamification avec streaks et badges de progression

---

## 🎯 Public cible

### Démographie
- **Âge** : 18-65+ ans
- **Marchés primaires** : France, Belgique, Suisse, Canada francophone, Afrique francophone
- **Marchés secondaires** : Anglophones mondiaux
- **Langues** : Français (prioritaire), Anglais

### Segments utilisateurs
| Segment | Problème principal | Fonctionnalités clés |
|---------|-------------------|---------------------|
| Professionnels stressés | Stress/anxiété au travail | Exercices de respiration, méditation rapide |
| Personnes avec troubles du sommeil | Insomnie, mauvaise qualité de sommeil | Routine du soir, sons relaxants |
| Épuisés/burnout | Fatigue chronique, manque d'énergie | Habitudes progressives, récupération |
| Difficulté de concentration | Pensées en boucle, distraction | Méditation guidée, techniques de focus |
| Amélioration générale | Bien-être global | Programme complet 8 habitudes |

---

## 🏗️ Architecture technique

### Stack technologique
| Composant | Technologie |
|-----------|-------------|
| Langage | Swift 5.x |
| Framework UI | SwiftUI |
| Architecture | MVVM |
| Backend | Firebase (Auth + Firestore) |
| Analytics | Mixpanel (serveur EU) |
| Monétisation | Superwall |
| Auth sociale | Google Sign-In, Apple Sign-In (à activer) |

### Identifiants & Configuration

**Bundle ID** : `Josbiot.App.CortiFree`

**Firebase** :
- Projet configuré avec Auth + Firestore
- GoogleService-Info.plist intégré

**Mixpanel** :
- Token : `54821f0aa53aa5ce3804237815f94332`
- Serveur : EU (https://api-eu.mixpanel.com)

**Superwall** :
- API Key : `pk_JPmmC0H5be4yqTnw24VTm`

**Google Sign-In** :
- Client ID : `559047783915-e7oca1vj0ssv0rqlb7m2o3vla5ii8ks8.apps.googleusercontent.com`
- URL Scheme : `com.googleusercontent.apps.559047783915-e7oca1vj0ssv0rqlb7m2o3vla5ii8ks8`

---

## 🔄 Parcours utilisateur

### 1. Onboarding (10 étapes)
```
Welcome → Reassurance → Quiz Global (2 min) → Quiz Habitudes →
Social Proof → Intro 8 Habitudes → Sélection Routine → Paywall →
Analyse Loading → Félicitations
```

### 2. Quiz d'évaluation
Collecte :
- Prénom, genre, tranche d'âge
- Symptômes actuels (sommeil, anxiété, épuisement, concentration, bien-être)
- Durée des difficultés
- Fréquence actuelle des 8 habitudes
- Score baseline calculé (0-100)

### 3. Choix de routine
| Routine | Icône | Description |
|---------|-------|-------------|
| Équilibrée | 🌍 Terre | Programme standard |
| Intensive | 🔴 Mars | Pour résultats rapides |
| Douce | 🌙 Lune | Progression lente |

### 4. App principale
- **Home** : Dashboard quotidien, timer 66 jours, message motivationnel
- **Tâches** : Liste quotidienne (matin/jour/soir), tracking de streak
- **Bibliothèque** : Respirations, méditations, sons, journal
- **Anti-Stress** : Exercices selon situation (6 situations → 15 exercices)
- **Profil** : Avatar, stats, achievements, paramètres

---

## 📊 Les 8 Habitudes (Coeur du programme)

| # | Habitude | Semaine 1 | Semaine 10 | Progression |
|---|----------|-----------|------------|-------------|
| 1 | **Sommeil** | Heure fixe ±30min | Heure fixe stricte | Régularité |
| 2 | **Respiration** | 3x/sem, 5 min | 7x/sem, 10 min | Fréquence + durée |
| 3 | **Méditation** | 3x/sem, 5 min | 7x/sem, 13 min | Fréquence + durée |
| 4 | **Journal** | 1x/jour | 7x/sem complet | Consistance |
| 5 | **Sport** | 45 min/sem | 3h30/sem | Volume |
| 6 | **Nature** | 15 min, 2x/sem | 15+ min, 5x/sem | Fréquence |
| 7 | **Social** | 1 interaction/sem | Plusieurs/sem | Fréquence |
| 8 | **Hydratation** | 1.5L/jour | 2.5L/jour | Quantité |

---

## 🏆 Gamification

### Système XP
- 5 XP par tâche complétée
- 100 XP par niveau
- Seuil de streak : 80% de complétion quotidienne

### Badges de streak
| Badge | Jours | Description |
|-------|-------|-------------|
| 🔥 | 3 | Première flamme |
| ⭐ | 7 | Une semaine |
| 🌟 | 14 | Deux semaines |
| 💪 | 21 | Habitude formée |
| 🏅 | 30 | Un mois |
| 🎖️ | 40 | Persévérance |
| 🏆 | 50 | Expert |
| 👑 | 60 | Champion |
| 🎯 | 66 | Programme complété |

---

## 💰 Monétisation

### Stratégie paywall
- **Moment** : Après quiz onboarding, avant accès app
- **Type** : Abonnement mensuel/annuel via Superwall
- **Tactiques d'urgence** :
  - Timer 30 minutes
  - Comparaison score baseline vs potentiel
  - Témoignages utilisateurs
  - Graphiques de progression des habitudes

### Plans d'abonnement
À configurer dans App Store Connect :
- Plan mensuel
- Plan annuel (recommandé, meilleur prix)
- Période d'essai gratuit (suggéré : 7 jours)

---

## 📝 App Store Connect - Guide de configuration

### Informations de l'app

**Nom de l'app** : CortiFree
**Sous-titre** (30 car.) : Réduis ton stress en 66 jours
**Catégorie principale** : Santé et forme
**Catégorie secondaire** : Style de vie

### Description courte (promotionnelle, 170 car.)
```
Transforme ta vie en 66 jours avec CortiFree. Programme scientifique de 8 habitudes pour réduire le stress de 68%. Respiration, méditation, journal et plus.
```

### Description longue App Store
```
🧘 RÉDUIS TON STRESS DE 68% EN 66 JOURS

CortiFree est ton compagnon de bien-être mental basé sur la science. Notre programme de 66 jours t'aide à construire 8 habitudes fondamentales pour une vie moins stressée et plus épanouie.

📊 PROGRAMME PERSONNALISÉ
• Quiz d'évaluation pour créer ton plan sur-mesure
• 3 niveaux d'intensité : Doux, Équilibré ou Intensif
• Progression adaptée semaine après semaine

🌟 8 HABITUDES TRANSFORMATRICES
• Sommeil régulier
• Exercices de respiration guidés
• Méditation quotidienne
• Journal de gratitude
• Activité physique
• Temps dans la nature
• Connexions sociales
• Hydratation optimale

🆘 ANTI-STRESS INSTANTANÉ
• 15 exercices selon ta situation
• Respiration guidée
• Techniques d'ancrage
• Méditation de crise

📈 SUIVI DE PROGRESSION
• Streak quotidien avec badges
• Statistiques détaillées
• Visualisation de ton évolution

🎧 BIBLIOTHÈQUE COMPLÈTE
• Sons relaxants (pluie, océan, forêt...)
• Méditations guidées
• Exercices de respiration variés

Rejoins les milliers de personnes qui ont transformé leur vie avec CortiFree. Commence ton voyage de 66 jours aujourd'hui.
```

### Mots-clés (100 car.)
```
stress,anxiété,méditation,respiration,bien-être,sommeil,relaxation,habitudes,santé mentale,calme
```

### Captures d'écran requises
1. **Home Dashboard** - Timer 66 jours + message motivationnel
2. **Tâches quotidiennes** - Liste matin/jour/soir avec checkboxes
3. **Exercice de respiration** - Animation de respiration guidée
4. **Bibliothèque** - Grille de sons/méditations
5. **Anti-stress** - Sélection de situation
6. **Profil/Stats** - Progression et badges
7. **Onboarding Quiz** - Interface du questionnaire
8. **Résultats** - Graphique baseline vs potentiel

### Informations de confidentialité

**Types de données collectées** :
| Donnée | Usage | Liée à l'identité |
|--------|-------|-------------------|
| Email | Authentification | Oui |
| Prénom | Personnalisation | Oui |
| Données de santé | Fonctionnalité app | Non |
| Identifiants | Analytics | Non |
| Données d'utilisation | Analytics | Non |
| Achats | Abonnement | Oui |

**Tracking** : Non (pas de tracking publicitaire tiers)

### Permissions requises (déjà dans Info.plist)
| Permission | Raison affichée |
|------------|-----------------|
| Microphone | Pour les exercices de respiration guidée |
| Notifications | Rappels pour les routines quotidiennes |
| HealthKit (lecture) | Personnaliser l'expérience avec données santé |
| HealthKit (écriture) | Synchroniser les données de bien-être |
| Tracking | Publicités personnalisées (optionnel) |

### Configuration In-App Purchases

**Identifiants suggérés** :
- `com.cortifree.monthly` - Abonnement mensuel
- `com.cortifree.yearly` - Abonnement annuel

**Groupe d'abonnements** : CortiFree Premium

---

## 🔧 Configuration technique restante

### Apple Sign-In (non activé)
1. Aller sur developer.apple.com → Identifiers
2. Sélectionner App ID `Josbiot.App.CortiFree`
3. Activer "Sign in with Apple"
4. Dans Xcode : Signing & Capabilities → + Sign in with Apple
5. Retirer `.disabled(true)` et `.opacity(0.5)` du bouton Apple dans AuthenticationView.swift

### Superwall Paywalls
Configurer dans dashboard Superwall :
- Créer paywall avec les plans
- Associer à l'événement de trigger après onboarding

### Mixpanel Events
Events déjà trackés :
- `onboarding_started`
- `onboarding_quiz_completed`
- `onboarding_authentication_completed`
- `task_completed`
- `habit_logged`
- `exercise_started`
- `exercise_completed`

---

## 📁 Structure du projet

```
CortiFree/
├── CortiFreeApp.swift          # Point d'entrée
├── Models/                      # Modèles de données
│   ├── UserSettings.swift
│   ├── HabitProgressionModel.swift
│   ├── AntiStress.swift
│   └── ...
├── Views/                       # Interfaces utilisateur
│   ├── HomeView.swift
│   ├── Onboarding V2/          # Flow d'onboarding
│   ├── Tasks/                   # Gestion des tâches
│   ├── AntiStress/             # Exercices anti-stress
│   ├── QuickAccess/            # Bibliothèque
│   └── ...
├── ViewModels/                  # Logique métier
├── Services/                    # Services (Firebase, Auth, etc.)
├── Resources/                   # Assets, localisations
│   ├── en.lproj/
│   ├── fr.lproj/
│   └── Lottie/                 # Animations
└── Config/                      # Configuration
```

---

## ✅ Checklist pré-soumission App Store

- [ ] Screenshots pour tous les appareils requis
- [ ] Icône app (1024x1024)
- [ ] Politique de confidentialité (URL)
- [ ] Conditions d'utilisation (URL)
- [ ] URL de support
- [ ] Compte démo pour review Apple (si paywall)
- [ ] Tester flux complet sur device réel
- [ ] Vérifier tous les textes localisés (FR/EN)
- [ ] Configurer In-App Purchases dans App Store Connect
- [ ] Créer groupe d'abonnements
- [ ] Renseigner informations de confidentialité
- [ ] Préparer réponses pour rejection potentielle (guideline 3.1.1 pour paywall)

---

*Document généré le 3 décembre 2025 pour faciliter la configuration App Store Connect*
