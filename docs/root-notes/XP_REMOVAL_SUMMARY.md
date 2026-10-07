# Suppression du Système XP/Niveaux - Résumé

Date: 2025-11-19
Status: ✅ **Terminé**

---

## Objectif

Supprimer complètement le système XP/Niveaux (1-20) tout en conservant le système de scoring (5 domaines: Sérénité, Sommeil, Énergie, Focus, Équilibre).

---

## Fichier Principal Désactivé

### Services/ProgressionManager.swift
**Action**: Renommé en `.deprecated`
```bash
mv Services/ProgressionManager.swift Services/ProgressionManager.swift.deprecated
```

**Raison**: Ce fichier gérait tout le système XP/Niveaux qui n'est plus utilisé.

**Contenait**:
- 20 niveaux de progression (Stress initial → Harmonie complète)
- Gestion de currentXP, currentLevel
- Méthodes addXP(), addCustomXP()
- Stockage UserDefaults: userCurrentXP, userStreakDays
- XPAction enum (dailyMissionComplete, meditationComplete, breathingComplete, etc.)

---

## Fichiers Modifiés

### 1. Views/HomeView.swift

**Ligne 14**: Supprimé
```swift
- @StateObject private var progressionManager = ProgressionManager.shared
```

**Ligne 21**: Supprimé
```swift
- @State private var showProgression = false
```

**Lignes 414-432**: Commenté
```swift
// MARK: - Progress Level Bar
// Removed - no longer using XP/Levels system
```

**Lignes 148-150**: Supprimé sheet
```swift
- .sheet(isPresented: $showProgression) {
-     ProgressionView()
- }
```

---

### 2. ViewModels/AntiStressViewModel.swift

**Lignes 55-64**: Supprimé attribution XP
```swift
- // Award XP with new progression system
- ProgressionManager.shared.addXP(.sosUsed)
-
- // Award XP (old system compatibility)
- let xp = exerciseType.xpReward
- xpEarned = xp
-
- // Update user XP
- _ = try await firebaseService.updateUserXP(addXP: xp)
```

**Remplacé par**:
```swift
// XP system removed - using scoring system instead
xpEarned = 0
// Note: XP update removed - using domain scoring system instead
```

---

### 3. ViewModels/DailyTodoViewModel.swift

**Lignes 83-86**: Supprimé attribution XP
```swift
- // Award XP if completing (not uncompleting)
- if !todo.isCompleted {
-     ProgressionManager.shared.addXP(.dailyMissionComplete)
- }
```

**Remplacé par**:
```swift
// XP system removed - using scoring system instead
```

---

### 4. ViewModels/TasksViewModel.swift

**Lignes 268-271**: Supprimé attribution XP
```swift
- // Award XP when completing a task (not when uncompleting)
- if !wasCompleted && tasks[index].completed {
-     ProgressionManager.shared.addXP(.dailyMissionComplete)
- }
```

**Remplacé par**:
```swift
// XP system removed - using scoring system instead
```

---

### 5. Views/Breathing/LibraryBreathingView.swift

**Lignes 230-233**: Supprimé attribution XP
```swift
- // Award XP for completing breathing exercise
- if totalDuration >= 60 { // At least 1 minute
-     ProgressionManager.shared.addXP(.breathingComplete)
- }
```

**Remplacé par**:
```swift
// XP system removed - using scoring system instead
```

---

### 6. Views/Meditation/GuidedMeditationSessionView.swift

**Lignes 264-267**: Supprimé attribution XP
```swift
- // Award XP for completing meditation (session with at least 5 steps = ~5+ minutes)
- if allSteps.count >= 5 {
-     ProgressionManager.shared.addXP(.meditationComplete)
- }
```

**Remplacé par**:
```swift
// XP system removed - using scoring system instead
```

---

### 7. Views/Routine/DailyProgramView.swift

**Lignes 274-281**: Supprimé attribution XP
```swift
- // Award XP via ProgressionManager
- ProgressionManager.shared.addCustomXP(exercise.xpReward, description: exercise.title)
-
- // Check if all exercises completed and checkpoint exists
- if allExercisesCompleted, let checkpoint = dailyProgram.checkpoint {
-     DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
-         totalXPEarned += checkpoint.bonusXP
-         ProgressionManager.shared.addCustomXP(checkpoint.bonusXP, description: checkpoint.title)
-     }
- }
```

**Remplacé par**:
```swift
// XP system removed - using scoring system instead
```

---

### 8. Views/Routine/SimplifiedDailyProgramView.swift

**Lignes 369-376**: Supprimé attribution XP
```swift
- // Award XP via ProgressionManager
- ProgressionManager.shared.addCustomXP(task.xp, description: task.title)
-
- if allTasksCompleted, let program = dailyProgram, program.checkpointDay {
-     ProgressionManager.shared.addCustomXP(program.bonusXP, description: "Checkpoint Jour \(dayNumber)")
- }
```

**Remplacé par**:
```swift
// XP system removed - using scoring system instead
```

---

### 9. Views/ProgressionView.swift

**Lignes 1-8**: Marqué comme DEPRECATED
```swift
//
//  ProgressionView.swift
//  CortiFree
//
//  DEPRECATED: Vue de progression avec système de niveaux
//  NOTE: This view is no longer used - XP/Levels system has been removed
//  Replaced by Achievement system in ProfileView
//
```

**Note**: Cette vue entière (319 lignes) est désormais obsolète car elle affichait uniquement le système de niveaux XP. Remplacée par l'onglet "Badges" dans ProfileView.

---

### 10. Views/Profile/ProfileCardView.swift

**Ligne 12**: Supprimé
```swift
- @StateObject private var progressionManager = ProgressionManager.shared
```

**Remplacé par**:
```swift
// Removed ProgressionManager - using scoring system instead
```

**Ligne 16**: Marqué deprecated
```swift
@State private var userLevel: String = "" // Deprecated - no longer using levels
```

---

## Système Conservé: Scoring

### ImpactScoringService.swift ✅ CONSERVÉ

Ce service reste intact et continue de gérer les **5 domaines de scoring**:

1. **Sérénité** (serenity)
2. **Sommeil** (sleep)
3. **Énergie** (energy)
4. **Focus** (focus)
5. **Équilibre** (balance)

**Méthodes conservées**:
```swift
func applyTaskImpact(habitId: String) async throws -> DomainScores
func removeTaskImpact(habitId: String) async throws -> DomainScores
func loadDomainScores() async throws -> DomainScores
```

**Stockage Firebase**: `users/{uid}/scoring/`

**Scores**: 0-100 pour chaque domaine

---

## Nouveau Système: Achievements + Milestones

### Remplace XP/Niveaux par:

1. **15 Achievements** répartis en 5 catégories
   - Streak (week_warrior, month_master, etc.)
   - Completion (triple_crown, perfect_week)
   - Habit (zen_master, breath_expert, journal_writer)
   - Milestone (halfway_hero, graduate)
   - Special (comeback_kid, perfectionist)

2. **4 Milestones** avec bonus de score (pas XP!)
   - Jour 7: +50 points
   - Jour 21: +100 points
   - Jour 33: +150 points
   - Jour 66: +500 points

3. **Affichage dans ProfileView**
   - Onglet "Badges" au lieu de "Niveaux"
   - Grille 3x3 d'achievements
   - Barre de progression (X/15 débloqués)
   - Galerie complète avec filtres par catégorie

---

## UserDefaults Nettoyées

Les clés suivantes ne sont plus utilisées:
- `userCurrentXP` ❌
- `userCurrentLevel` ❌
- `userStreakDays` ❌ (maintenant géré par Firebase HabitTracking)

---

## Firebase Collections Obsolètes

Ces chemins Firebase ne sont plus utilisés:
- `users/{uid}/progression/xp` ❌
- `users/{uid}/progression/level` ❌

**Nouveaux chemins** (système achievements):
- `users/{uid}/achievements/{achievementId}` ✅
- `users/{uid}/milestones/{milestoneId}` ✅

---

## Impact Utilisateur

### Avant (Système XP/Niveaux)
```
User complète tâche
  ↓
+50 XP ajouté
  ↓
Niveau 3/20 → Niveau 4/20
  ↓
Notification: "Nouveau niveau!"
```

### Après (Système Achievements + Scoring)
```
User complète tâche
  ↓
Score Sérénité: +5 (45 → 50)
  ↓
Check achievements automatique
  ↓
Si condition remplie: Badge débloqué avec confetti
  ↓
Si jour milestone: Célébration + bonus score
```

---

## Avantages du Nouveau Système

### 1. Plus Pertinent
- Les scores reflètent directement le bien-être (0-100)
- Les achievements célèbrent les vraies réussites
- Les milestones récompensent la progression du programme

### 2. Plus Simple
- Pas de notion abstraite de "niveau 1-20"
- Pas d'XP à accumuler
- Progression claire et visuelle

### 3. Plus Motivant
- Badges variés avec progression claire
- Milestones avec gros bonus
- Célébrations visuelles (confetti, animations)

### 4. Plus Flexible
- Facile d'ajouter de nouveaux achievements
- Conditions personnalisables
- Catégories extensibles

---

## Vérifications de Build

Après suppression, vérifier que:
- ✅ Aucune erreur de compilation liée à `ProgressionManager`
- ✅ Aucune référence à `.addXP()` ou `.addCustomXP()`
- ✅ Les scores domaines fonctionnent toujours
- ✅ Les achievements se débloquent correctement
- ✅ Les milestones se célèbrent correctement

---

## Commandes pour Nettoyer Complètement

Si besoin de supprimer définitivement le fichier deprecated:

```bash
# Supprimer le fichier deprecated
rm /Users/jos/CortiFree/CortiFree/CortiFree/Services/ProgressionManager.swift.deprecated

# Nettoyer les références dans la doc
grep -r "ProgressionManager" /Users/jos/CortiFree --exclude-dir=DerivedData
```

---

## Tests Post-Suppression

### ✅ À Tester:
1. Compléter une tâche → Vérifier que le score s'incrémente (pas XP)
2. Compléter 7 jours consécutifs → Badge "week_warrior" débloqué
3. Atteindre jour 7 → Milestone + 50 points de bonus
4. Compléter méditation × 10 → Badge "zen_master" débloqué
5. Ouvrir ProfileView → Onglet "Badges" visible, pas "Niveaux"
6. Voir galerie achievements → Filtrer par catégorie fonctionne
7. Déconnexion/reconnexion → Données persistées correctement

---

## Résumé

✅ **Supprimé**:
- ProgressionManager.swift (renommé .deprecated)
- Toutes les références à addXP() / addCustomXP()
- ProgressionView (marquée deprecated)
- Système de niveaux 1-20
- Accumulation d'XP
- UserDefaults XP keys

✅ **Conservé**:
- ImpactScoringService (scores 0-100 des 5 domaines)
- Firebase scoring collection
- Logique d'impact des habitudes

✅ **Nouveau**:
- AchievementService
- 15 achievements + 4 milestones
- Système de célébrations
- Onglet "Badges" dans ProfileView

🎯 **Résultat**: Application plus claire, plus simple, plus motivante!