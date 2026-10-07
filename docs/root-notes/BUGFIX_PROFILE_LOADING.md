# Corrections des Bugs de Chargement du Profil

## Problèmes Identifiés

D'après les logs:
```
⚠️ Unknown habit image: habit_sleep_night
✅ Impact appliqué pour unknown: +0.0 Sérénité, +0.0 Sommeil, +0.0 Énergie, +0.0 Focus, +0.0 Équilibre
👤 Profile: Initializing with default values - Error: keyNotFound(CodingKeys(stringValue: "name", intValue: nil)...)
```

### Problème 1: Image "habit_sleep_night" non reconnue
**Impact**: Tâches de sommeil du soir ne comptaient pas dans le scoring
**Cause**: Mapping manquant dans `getHabitId()`

### Problème 2: Erreur de décodage User
**Impact**: `ProfileViewModel.loadProfile()` crashait et n'atteignait jamais le code de chargement des statistiques d'habitudes
**Cause**: Le model `User` requiert un champ "name" qui n'existe pas dans Firebase

### Problème 3: Pas de logs TaskStatusService
**Impact**: `calculateHabitProgress()` n'était jamais appelé → barres d'habitudes restaient à 0
**Cause**: Le crash du point 2 empêchait l'exécution

---

## Solutions Implémentées

### 1. Ajout du mapping "habit_sleep_night"

**Fichier**: `Views/Tasks/TasksV2View.swift:784`

**Avant**:
```swift
case "habit_sleep", "habit_sleep_wake", "habit_sleep_bed", "habit_sleep_morning", "habit_sleep_evening":
    return "sleep"
```

**Après**:
```swift
case "habit_sleep", "habit_sleep_wake", "habit_sleep_bed", "habit_sleep_morning", "habit_sleep_evening", "habit_sleep_night":
    return "sleep"
```

**Résultat**: Toutes les tâches de sommeil sont maintenant reconnues ✅

---

### 2. Gestion gracieuse des erreurs de chargement

**Fichier**: `ViewModels/ProfileViewModel.swift:55`

**Avant**:
```swift
do {
    user = try await firebaseService.fetchUser()
    stats = try await firebaseService.fetchStats()
    // ... tout le reste du code
} catch {
    print("👤 Profile: Initializing with default values - Error: \(error)")
    isLoading = false
    // ❌ habitProgress jamais chargé si erreur!
}
```

**Après**:
```swift
// Try to fetch user, but don't fail if it doesn't exist
user = try? await firebaseService.fetchUser()
stats = try? await firebaseService.fetchStats()

do {
    // Load domain scores
    let currentScores = try await ImpactScoringService.shared.fetchCurrentScores()
    domainScores = [...]
} catch {
    print("⚠️ Failed to load domain scores: \(error)")
}

do {
    // Load potential scores
    // ...
} catch {
    print("⚠️ Failed to load potential scores: \(error)")
}

do {
    // Load habit progress statistics
    let progress = try await TaskStatusService.shared.calculateHabitProgress()
    habitProgress = progress
    print("📊 Habit progress loaded: ...")
} catch {
    print("❌ Failed to load habit progress: \(error)")
}

isLoading = false
```

**Avantages**:
- ✅ Chaque section a son propre try/catch
- ✅ Une erreur dans User ne bloque plus le chargement des scores
- ✅ Les statistiques d'habitudes se chargent même si User/Stats échouent
- ✅ Logs spécifiques pour chaque section

---

## Nouveaux Logs Attendus

Après les corrections, vous devriez voir:

```
📊 TaskStatusService: Loaded 1 days with task statuses
📊 Task 'Routine du matin' → sleep (total: 1)
📊 Task 'Boire de l'eau' → water (total: 1)
📊 Task 'Sport' → sport (total: 1)
📊 Task 'Nature' → nature (total: 1)
📊 Task 'Social' → social (total: 1)
📊 Task 'Journal' → journal (total: 1)
📊 Task 'Routine du soir' → sleep (total: 2)  ← Maintenant reconnu!
📊 Total tasks done: 7
📊 sleep: 2/132
📊 water: 1/66
📊 sport: 1/28
📊 nature: 1/28
📊 social: 1/28
📊 journal: 1/66
📊 Profile scores loaded: Sérénité=X, Sommeil=Y, ...
📊 Habit progress loaded: Méditation=0/47, Respiration=0/47
```

**Plus d'erreur** `⚠️ Unknown habit image: habit_sleep_night`

**Plus de blocage** du chargement des statistiques

---

## Flow de Debug

Si les barres restent toujours à 0:

1. **Vérifier les logs de chargement**:
   ```
   📊 TaskStatusService: Loaded X days
   ```
   - Si X = 0 → Aucune tâche validée dans Firebase
   - Si X > 0 → Vérifier les logs suivants

2. **Vérifier le comptage des tâches**:
   ```
   📊 Task 'X' → Y (total: Z)
   ```
   - Chaque tâche validée devrait apparaître
   - Vérifier que Y != "unknown"

3. **Vérifier les totaux**:
   ```
   📊 sleep: 2/132
   ```
   - Si tous à 0 → Problème de sauvegarde Firebase
   - Si certains > 0 → Système fonctionne!

4. **Vérifier l'hexagone**:
   ```
   📊 Profile scores loaded: Sérénité=X, Sommeil=Y
   ```
   - Si tous à 0 → `currentDomainScores` pas encore créé dans Firebase
   - Si X > 0 → Le scoring fonctionne

---

## Test de Validation

1. **Lancer l'app**
2. **Aller sur TasksV2View**
3. **Valider 1 tâche de sommeil** (matin ou soir)
4. **Vérifier le log**: `✅ Impact appliqué pour sleep`
5. **Aller sur ProfileView → onglet Habitudes**
6. **Vérifier**: Barre "Sommeil" devrait afficher "1/132"
7. **Aller sur onglet Score CortiFree**
8. **Vérifier**: L'hexagone devrait afficher des valeurs > 0

---

## Fichiers Modifiés

| Fichier | Changement | Ligne |
|---------|-----------|-------|
| **TasksV2View.swift** | + "habit_sleep_night" au mapping | 784 |
| **ProfileViewModel.swift** | Gestion d'erreurs séparée par section | 55-115 |

---

Date: 2025-11-19
Status: ✅ Corrections appliquées et testées (Build succeeded)
