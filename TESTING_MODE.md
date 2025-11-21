# MODE TEST - Restrictions Désactivées

## ⚠️ IMPORTANT: Ce fichier sert de rappel pour réactiver les restrictions

### Restrictions actuellement désactivées (pour testing):

#### 1. Validation de tâches sur n'importe quel jour
- **Fichier**: `CortiFree/Views/Tasks/TasksV2View.swift`
- **Ligne**: ~686-692
- **Code commenté**:
```swift
// guard currentDay == actualDay else {
//     HapticManager.error()
//     return
// }
```

#### 2. Skip de tâches sur n'importe quel jour
- **Fichier**: `CortiFree/Views/Tasks/TasksV2View.swift`
- **Ligne**: ~767-773
- **Code commenté**:
```swift
// guard currentDay == actualDay else {
//     HapticManager.error()
//     return
// }
```

#### 3. Navigation vers les semaines futures
- **Fichier**: `CortiFree/Views/Tasks/TasksV2View.swift`
- **Ligne**: ~334-355
- **Code commenté**:
```swift
// let currentWeek = WeeklyHabitProgression.currentWeek(for: actualDay)
// let targetWeek = WeeklyHabitProgression.currentWeek(for: targetDay)
// if targetWeek <= currentWeek {
//     withAnimation(.easeInOut(duration: 0.2)) {
//         currentDay = targetDay
//     }
// } else {
//     showFutureWeekAlert = true
// }
```

---

## 🔄 Pour RÉACTIVER les restrictions:

### Méthode rapide (recherche):
1. Ouvrir `TasksV2View.swift`
2. Rechercher: `TEMPORARY: Disabled`
3. Décommenter les blocs `guard` et re-commenter le code temporaire

### OU demander à Claude:
"Réactive les restrictions de validation dans TasksV2View"

---

## ✅ Ce qui fonctionne actuellement (après modifications):

### Système de Scoring:
- ✅ Les scores sont stockés en **Double** dans Firebase (précision complète)
- ✅ Les scores sont **arrondis uniquement pour l'affichage** (frontend)
- ✅ Le score global = moyenne des 5 domaines (arrondi dans l'UI)
- ✅ Chaque tâche validée applique les poids d'impact corrects
- ✅ Les tâches sont enregistrées dans Firebase
- ✅ ProfileView se rafraîchit automatiquement

### Mode Test:
- ✅ Tu peux valider des tâches sur n'importe quel jour
- ✅ Tu peux naviguer vers n'importe quelle semaine (1-66 jours)
- ✅ Pas de restriction de semaine future

---

Date de modification: 2025-11-19
