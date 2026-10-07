# Système de Scoring - Documentation

## 📍 Où sont stockés les scores ?

### Firebase Structure:
```
users/
  └── {userId}/
      ├── currentDomainScores/           ← SCORES ACTUELS (mis à jour par les tâches)
      │   ├── global: Double             // Moyenne des 5 domaines
      │   ├── serenity: Double           // Sérénité (0-100)
      │   ├── sleep: Double              // Sommeil (0-100)
      │   ├── energy: Double             // Énergie (0-100)
      │   ├── focus: Double              // Focus (0-100)
      │   └── balance: Double            // Équilibre (0-100)
      │
      ├── domainScores/                  ← SCORES ONBOARDING (point de départ)
      │   ├── serenity: Int
      │   ├── sleep: Int
      │   ├── energy: Int
      │   ├── focus: Int
      │   └── balance: Int
      │
      ├── potentialScores/               ← SCORES POTENTIELS (score actuel + 65)
      │   ├── serenity: Int
      │   ├── sleep: Int
      │   ├── energy: Int
      │   ├── focus: Int
      │   └── balance: Int
      │
      └── task_statuses/                 ← STATUTS DES TÂCHES
          └── day_{X}/
              ├── {taskTitle}: "done"|"skipped"
              └── lastUpdated: Timestamp
```

---

## 🔄 Flow du Scoring

### 1. Initialisation (Onboarding)
```
Utilisateur complète le quiz → domainScores sauvegardés (Int 0-100)
                            → potentialScores calculés (score + 65, max 98)
```

### 2. Première tâche complétée
```
ImpactScoringService.fetchCurrentScores()
  → Cherche currentDomainScores
  → Si pas trouvé: copie domainScores → currentDomainScores (comme Double)
  → Retourne UserDomainScores
```

### 3. Validation de tâche
```
User valide une tâche
  ↓
TasksV2View.validateTask()
  ↓
1. Sauvegarde statut → Firebase task_statuses/day_{X}/{taskTitle} = "done"
2. Mark habit completed → Firebase habit_tracking (pour streaks)
3. ImpactScoringService.applyTaskImpact(habitId)
   ↓
   a. Récupère scores actuels
   b. Ajoute les poids d'impact (ex: +0.248 Sérénité)
   c. Recalcule global = moyenne des 5 domaines
   d. Sauvegarde → Firebase currentDomainScores
   e. Retourne scores mis à jour
  ↓
4. Mise à jour UI avec scores arrondis
```

---

## 📊 Affichage des Scores

### ProfileView (Hexagone)
```swift
ProfileViewModel.loadProfile()
  ↓
ImpactScoringService.shared.fetchCurrentScores()
  ↓
domainScores = [
    currentScores.serenity,    // 0-100 (Double)
    currentScores.sleep,
    currentScores.energy,
    currentScores.focus,
    currentScores.balance
]
  ↓
ProfileView affiche:
  - Global score: Int(round(average))
  - Domain scores: Int(round(score))
  - Radar chart: scores / 100.0 (normalisé 0-1)
```

### TasksV2View (Score global en haut)
```swift
loadFirebaseData()
  ↓
ImpactScoringService.shared.fetchCurrentScores()
  ↓
globalScore = currentScores.roundedScores.global  // Int arrondi
```

---

## 🔢 Calculs et Formules

### Poids d'Impact (par tâche complétée)
- **Total sur 66 jours**: +65 points max par domaine
- **Exemple Méditation** (47 tâches):
  ```
  Sérénité: 0.248 points/tâche × 47 tâches = 11.66 points
  Sommeil: 0.141 points/tâche × 47 tâches = 6.63 points
  etc.
  ```

### Score Global
```swift
global = (serenity + sleep + energy + focus + balance) / 5.0
```

### Arrondissement (Frontend uniquement)
```swift
// Backend stocke: 34.87 (Double)
// Frontend affiche: 35 (Int)

Int(round(score))  // 34.9 → 35, 34.4 → 34
```

---

## 🛠️ Services et Fichiers Clés

| Fichier | Responsabilité |
|---------|---------------|
| **ImpactScoringService.swift** | Gère les scores (fetch, save, apply, remove) |
| **TaskStatusService.swift** | Sauvegarde statuts des tâches (done/skipped) |
| **HabitImpactWeights.swift** | Définit les poids d'impact par habitude |
| **ProfileViewModel.swift** | Charge les scores pour l'affichage profil |
| **TasksV2View.swift** | Valide tâches et applique le scoring |

---

## 🔍 Debugging

### Vérifier les scores dans Firebase:
1. Ouvrir Firebase Console
2. Firestore Database → users → {userId}
3. Chercher le champ `currentDomainScores`

### Logs utiles:
```
✅ Impact appliqué pour {habitId}: +{serenity} Sérénité, +{sleep} Sommeil, ...
📊 Profile scores loaded: Sérénité={X}, Sommeil={Y}, ...
⚠️ Unknown habit image: {imageName}
```

### Tester:
1. Valider une tâche
2. Vérifier dans Firebase que `currentDomainScores` a augmenté
3. Aller sur ProfileView → les scores doivent s'afficher

---

## ✅ Checklist de Vérification

- [ ] `currentDomainScores` existe dans Firebase pour l'utilisateur
- [ ] ProfileView affiche des scores > 0
- [ ] L'hexagone radar chart se remplit proportionnellement
- [ ] Quand on valide une tâche, le score global augmente
- [ ] Les logs `📊 Profile scores loaded` montrent des valeurs correctes

---

## 📋 Vérification des Fréquences (66 jours)

Toutes les fréquences ont été vérifiées et correspondent aux totaux attendus:

| Habitude | Fréquence | Total Tâches | Statut |
|----------|-----------|--------------|--------|
| Méditation | 3→7x/sem | 47 | ✅ |
| Respiration | 3→7x/sem | 47 | ✅ |
| Journal | 7x/sem | 66 | ✅ |
| Sport | 2→4x/sem | 28 | ✅ |
| Eau | 7x/sem | 66 | ✅ |
| Nature | 2→4x/sem | 28 | ✅ |
| Social | 2→4x/sem | 28 | ✅ |
| Sommeil | 7x/sem × 2 | 132 | ✅ |

**Total**: 434 tâches sur 66 jours

Voir [HABIT_FREQUENCY_VERIFICATION.md](../HABIT_FREQUENCY_VERIFICATION.md) pour les calculs détaillés.

---

Date: 2025-11-19
Updated: 2025-11-19 (Vérification fréquences complète)
