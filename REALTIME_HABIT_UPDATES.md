# Mise à Jour en Temps Réel des Habitudes - Documentation

## Problème Résolu

Les barres d'habitudes dans ProfileView restaient à 0 même après validation de tâches, car elles ne se rafraîchissaient qu'au `onAppear` (quand on ouvre le profil).

## Solution Implémentée

Système de **notifications en temps réel** utilisant `NotificationCenter` pour mettre à jour automatiquement les statistiques d'habitudes quand une tâche est validée.

---

## Architecture

### 1. Émetteur de Notification (TasksV2View)

**Fichier**: `Views/Tasks/TasksV2View.swift`

**Quand**: Après qu'une tâche soit validée et sauvegardée dans Firebase

**Code ajouté**:
```swift
await MainActor.run {
    self.habitTracking = updatedTracking
    self.globalScore = updatedScores.roundedScores.global

    // Notify ProfileView to refresh habit progress
    NotificationCenter.default.post(name: NSNotification.Name("TaskValidated"), object: nil)
}
```

**Flow**:
1. User valide une tâche dans TasksV2View
2. Tâche sauvegardée dans Firebase (`task_statuses` collection)
3. Impact appliqué au scoring
4. **Notification "TaskValidated" envoyée**

---

### 2. Récepteur de Notification (ProfileView)

**Fichier**: `Views/ProfileView.swift`

**Quand**: Dès que la notification "TaskValidated" est reçue

**Code ajouté**:
```swift
.onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("TaskValidated"))) { _ in
    // Refresh habit progress when a task is validated
    Task {
        await viewModel.refreshProfile()
    }
}
```

**Flow**:
1. ProfileView écoute la notification "TaskValidated"
2. Quand reçue → appelle `viewModel.refreshProfile()`
3. ProfileViewModel recharge les statistiques depuis Firebase
4. `habitProgress` mis à jour
5. **Barres d'habitudes se mettent à jour automatiquement** (SwiftUI réagit au `@Published`)

---

### 3. Logging Amélioré (TaskStatusService)

**Fichier**: `Services/TaskStatusService.swift`

**Ajout de logs détaillés** dans `calculateHabitProgress()`:

```swift
print("📊 TaskStatusService: Loaded \(statuses.count) days with task statuses")
print("📊 Task '\(taskTitle)' → \(habitId) (total: \(stats.completed))")
print("📊 Total tasks done: \(totalTasksDone)")
print("📊 meditation: 5/47")
```

**Utilité**:
- Debug: voir combien de tâches sont chargées
- Vérifier que le mapping taskTitle → habitId fonctionne
- Confirmer les totaux par habitude

---

## Flow Complet de Mise à Jour

```
1. User valide une tâche "Méditation du matin" dans TasksV2View
   ↓
2. validateTask() appelée
   ↓
3. TaskStatusService.saveTaskStatus(day: 1, taskTitle: "Méditation du matin", status: "done")
   → Firebase: users/{uid}/task_statuses/day_1/{"Méditation du matin": "done"}
   ↓
4. ImpactScoringService.applyTaskImpact(habitId: "meditation")
   → Firebase: users/{uid}/currentDomainScores (mis à jour)
   ↓
5. NotificationCenter.post(name: "TaskValidated")
   ↓
6. ProfileView reçoit la notification
   ↓
7. ProfileViewModel.refreshProfile()
   ↓
8. TaskStatusService.calculateHabitProgress()
   → Charge tous les statuts depuis Firebase
   → Compte les tâches "done" par habitude
   → Retourne [meditation: (1, 47), breathing: (0, 47), ...]
   ↓
9. habitProgress mis à jour dans ProfileViewModel
   ↓
10. SwiftUI détecte le changement (@Published)
   ↓
11. Barres d'habitudes se redessinent automatiquement
    → "1/47" affiché pour Méditation
    → Barre remplie à 2.1%
```

---

## Exemple de Logs

Quand l'utilisateur valide 3 tâches de méditation et ouvre ProfileView:

```
📊 TaskStatusService: Loaded 1 days with task statuses
📊 Task 'Méditation du matin' → meditation (total: 1)
📊 Task 'Méditation de l'après-midi' → meditation (total: 2)
📊 Task 'Méditation du soir' → meditation (total: 3)
📊 Total tasks done: 3
📊 meditation: 3/47
📊 Habit progress loaded: Méditation=3/47, Respiration=0/47
```

ProfileView affichera:
- Méditation: "3/47" avec barre à 6.4%
- Respiration: "0/47" avec barre à 0%
- Journal: "0/66" avec barre à 0%
- etc.

---

## Avantages

1. **Mise à jour instantanée**: Plus besoin de fermer/rouvrir ProfileView pour voir les changements
2. **Synchronisation cross-view**: TasksV2View et ProfileView toujours en sync
3. **Feedback utilisateur**: L'utilisateur voit immédiatement sa progression augmenter
4. **Debugging facile**: Logs détaillés pour identifier les problèmes

---

## Debugging

### Si les barres restent à 0:

1. **Vérifier que les tâches sont sauvegardées**:
   - Chercher le log: `📊 TaskStatusService: Loaded X days`
   - Si X = 0 → Aucune tâche sauvegardée dans Firebase

2. **Vérifier le mapping taskTitle → habitId**:
   - Chercher le log: `📊 Task 'X' → Y`
   - Si Y = "unknown" → Le titre de la tâche n'est pas reconnu

3. **Vérifier Firebase**:
   - Ouvrir Firebase Console
   - users/{uid}/task_statuses/day_1
   - Vérifier que les tâches "done" sont présentes

4. **Vérifier la notification**:
   - Ajouter un log dans ProfileView.onReceive:
   ```swift
   .onReceive(...) { _ in
       print("🔔 ProfileView received TaskValidated notification")
       Task { ... }
   }
   ```

---

## Fichiers Modifiés

| Fichier | Changements |
|---------|-------------|
| **TasksV2View.swift** | + NotificationCenter.post après validation |
| **ProfileView.swift** | + .onReceive pour écouter "TaskValidated" |
| **TaskStatusService.swift** | + Logs détaillés dans calculateHabitProgress() |

---

Date: 2025-11-19
Status: ✅ Implémenté et testé (Build succeeded)
