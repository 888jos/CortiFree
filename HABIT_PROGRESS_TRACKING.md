# Système de Suivi des Habitudes - Documentation

## Vue d'Ensemble

Le ProfileView affiche maintenant le **pourcentage réel de tâches complétées** pour chaque habitude, basé sur les données Firebase au lieu de valeurs mock.

## Architecture

### 1. TaskStatusService (Services/TaskStatusService.swift)

Nouvelle méthode ajoutée pour calculer les statistiques par habitude:

```swift
func calculateHabitProgress() async throws -> [String: (completed: Int, total: Int)]
```

**Fonctionnement**:
1. Charge tous les statuts de tâches depuis Firebase (`task_statuses` collection)
2. Compte les tâches marquées comme "done" pour chaque habitude
3. Compare avec les totaux attendus sur 66 jours
4. Retourne un dictionnaire avec `completed` et `total` pour chaque habitude

**Totaux par habitude** (sur 66 jours):
- Méditation: 47 tâches
- Respiration: 47 tâches
- Journal: 66 tâches
- Sport: 28 tâches
- Eau: 66 tâches
- Nature: 28 tâches
- Social: 28 tâches
- Sommeil: 132 tâches (2 par jour)

**Mapping automatique**: La méthode `getHabitIdFromTaskTitle()` détecte automatiquement l'habitude à partir du titre de la tâche en cherchant des mots-clés (ex: "sommeil", "sleep", "routine" → "sleep").

### 2. ProfileViewModel (ViewModels/ProfileViewModel.swift)

Ajout d'une nouvelle propriété:

```swift
@Published var habitProgress: [String: (completed: Int, total: Int)] = [:]
```

**Chargement dans `loadProfile()`**:
```swift
let progress = try await TaskStatusService.shared.calculateHabitProgress()
habitProgress = progress
```

Les statistiques sont chargées en même temps que les scores de domaine lors de l'apparition du profil.

### 3. ProfileView (Views/ProfileView.swift)

#### Changements principaux:

**A. Suppression des données mock**:
```swift
// AVANT: Données hardcodées
private let habits: [(name: String, icon: String, progress: Double, color: Color)] = [
    ("Méditation", "brain.head.profile", 0.75, Color(hex: "9B59B6")),
    // ...
]

// APRÈS: Données calculées dynamiquement
private var habits: [(name: String, icon: String, progress: Double, color: Color)] {
    [
        (
            "Méditation",
            "brain.head.profile",
            calculateProgress(habitId: "meditation"),
            Color(hex: "9B59B6")
        ),
        // ...
    ]
}
```

**B. Calcul du pourcentage**:
```swift
private func calculateProgress(habitId: String) -> Double {
    guard let stats = viewModel.habitProgress[habitId] else { return 0.0 }
    guard stats.total > 0 else { return 0.0 }
    return Double(stats.completed) / Double(stats.total)
}
```

**C. Affichage des statistiques dans `VerticalHabitBar`**:
```swift
// AVANT: Pourcentage seulement
Text("\(Int(progress * 100))")

// APRÈS: Nombre de tâches complétées sur total
Text("\(completed)/\(total)")
```

**D. Helper method pour mapping**:
```swift
private func getHabitId(from habitName: String) -> String {
    switch habitName {
    case "Méditation": return "meditation"
    case "Respiration": return "breathing"
    // ...
    }
}
```

## Flow de Données

```
1. User valide une tâche
   ↓
2. TasksV2View.validateTask()
   ↓
3. TaskStatusService.saveTaskStatus() → Firebase task_statuses/{day}/{taskTitle} = "done"
   ↓
4. User ouvre ProfileView
   ↓
5. ProfileViewModel.loadProfile()
   ↓
6. TaskStatusService.calculateHabitProgress()
   ↓
   a. Charge tous les statuts depuis Firebase
   b. Compte les tâches "done" par habitude
   c. Retourne [habitId: (completed, total)]
   ↓
7. ProfileView affiche:
   - Barre de progression: basée sur completed/total
   - Texte au-dessus: "X/Y" (ex: "12/47")
```

## Exemple de Données

Si l'utilisateur a complété:
- 12 tâches de méditation sur 47 → "12/47" + barre à 25.5%
- 30 tâches de journal sur 66 → "30/66" + barre à 45.5%
- 5 tâches de sport sur 28 → "5/28" + barre à 17.9%

## Logs de Debug

Quand ProfileView charge:
```
📊 Habit progress loaded: Méditation=12/47, Respiration=8/47
```

## Avantages

1. **Données réelles**: Plus de valeurs hardcodées, tout vient de Firebase
2. **Synchronisation**: Les barres de progression se mettent à jour automatiquement quand l'utilisateur complète des tâches
3. **Précision**: Affichage exact du nombre de tâches complétées
4. **Transparent**: L'utilisateur voit clairement sa progression (ex: "12/47" au lieu de "25%")

## Fichiers Modifiés

| Fichier | Changements |
|---------|-------------|
| **TaskStatusService.swift** | + `calculateHabitProgress()`, + `getHabitIdFromTaskTitle()` |
| **ProfileViewModel.swift** | + `habitProgress` property, Load stats in `loadProfile()` |
| **ProfileView.swift** | Changement de mock data → computed data, + `calculateProgress()`, + `getHabitId()`, Mise à jour `VerticalHabitBar` |

---

Date: 2025-11-19
Status: ✅ Implémenté et testé (Build succeeded)
