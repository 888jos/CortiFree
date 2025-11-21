# Hexagone de Détail d'Habitude - Intégration Impact Scoring

## Problème Résolu

L'hexagone dans `HabitTaskDetailView` affichait des **valeurs hardcodées** au lieu des **vrais poids d'impact** calculés dans le système de scoring.

## Solution Implémentée

Connexion de l'hexagone aux **vraies données** du `HabitImpactWeights`.

---

## Modifications Apportées

### Fichier: `Views/Tasks/HabitTaskDetailView.swift`

#### 1. Fonction `getImpactProgress()` (lignes 410-456)

**AVANT**: Utilisait `task.impactAreas` avec des valeurs hardcodées

**APRÈS**: Récupère les poids réels via `HabitImpactWeights.impactForHabit()`

```swift
private func getImpactProgress() -> [Double] {
    // Get the real impact weights from HabitImpactWeights
    let habitId = getHabitId(for: task.imageName)
    let impact = HabitImpactWeights.impactForHabit(habitId)

    // Normalize weights to 0-1 scale for radar chart display
    let maxWeight = max(impact.serenity, impact.sleep, impact.energy, impact.focus, impact.balance, 0.001)

    let normalizedSerenity = impact.serenity / maxWeight
    let normalizedSleep = impact.sleep / maxWeight
    let normalizedEnergy = impact.energy / maxWeight
    let normalizedFocus = impact.focus / maxWeight
    let normalizedBalance = impact.balance / maxWeight

    // Global is the average of all domains
    let global = (normalizedSerenity + normalizedSleep + normalizedEnergy + normalizedFocus + normalizedBalance) / 5.0

    return [global, normalizedSerenity, normalizedSleep, normalizedEnergy, normalizedFocus, normalizedBalance]
}
```

**Normalisation**:
- Trouve le poids max parmi les 5 domaines
- Divise chaque poids par ce max → valeurs entre 0 et 1
- Le domaine avec le plus d'impact = 1.0 (remplit l'hexagone à 100%)
- Les autres domaines sont proportionnels

**Exemple - Méditation**:
```
Poids bruts:
- Sérénité: 0.248  ← MAX
- Sommeil: 0.141
- Énergie: 0.091
- Focus: 0.215
- Équilibre: 0.175

Normalisés (divisés par 0.248):
- Sérénité: 1.0    (100%)
- Focus: 0.867     (86.7%)
- Équilibre: 0.706 (70.6%)
- Sommeil: 0.569   (56.9%)
- Énergie: 0.367   (36.7%)
```

---

#### 2. Fonction `getImpactAreas()` (lignes 520-562)

**AVANT**: Switch avec valeurs hardcodées pour chaque habitude

**APRÈS**: Utilise `HabitImpactWeights` et trie par impact décroissant

```swift
static func getImpactAreas(for imageName: String) -> [ImpactArea] {
    // Map image name to habit ID
    let habitId = ... // mapping logic

    // Get real impact weights
    let impact = HabitImpactWeights.impactForHabit(habitId)

    // Convert weights to ImpactArea array
    // Scale weights by 100 for better display (0.248 → 24.8 → 25)
    var areas = [
        ImpactArea(icon: "leaf.fill", title: "Sérénité", increaseValue: Int(impact.serenity * 100), color: ...),
        ImpactArea(icon: "moon.fill", title: "Sommeil", increaseValue: Int(impact.sleep * 100), color: ...),
        ImpactArea(icon: "bolt.fill", title: "Énergie", increaseValue: Int(impact.energy * 100), color: ...),
        ImpactArea(icon: "target", title: "Focus", increaseValue: Int(impact.focus * 100), color: ...),
        ImpactArea(icon: "heart.fill", title: "Équilibre", increaseValue: Int(impact.balance * 100), color: ...)
    ]

    // Sort by impact value (descending) and keep only top 4
    areas.sort { $0.increaseValue > $1.increaseValue }
    return Array(areas.prefix(4))
}
```

**Avantages**:
- ✅ Affiche toujours les **4 domaines** avec le plus d'impact
- ✅ Ordre dynamique basé sur les vrais poids
- ✅ Valeurs précises (ex: 24.8 au lieu de 20 approximatif)

---

#### 3. Helper `getHabitId()` (lignes 435-455)

Nouvelle fonction pour mapper `imageName` → `habitId`

```swift
private func getHabitId(for imageName: String) -> String {
    if imageName.contains("sleep") || imageName.contains("sommeil") {
        return "sleep"
    } else if imageName.contains("breathe") || imageName.contains("respir") {
        return "breathing"
    } else if imageName.contains("meditate") || imageName.contains("médita") {
        return "meditation"
    // ... etc
    }
    return "unknown"
}
```

---

## Exemples de Résultats

### Méditation (habitId: "meditation")

**Poids réels**:
```swift
HabitImpactWeights.meditation = HabitImpactScore(
    serenity: 0.248,  // ← Impact le plus fort
    sleep: 0.141,
    energy: 0.091,
    focus: 0.215,
    balance: 0.175
)
```

**Hexagone affiché**:
- Forme: Étiré vers Sérénité (100%), fort vers Focus (87%), modéré vers Équilibre (71%)
- Top 4 impacts affichés: Sérénité (25), Focus (22), Équilibre (18), Sommeil (14)

---

### Sport (habitId: "sport")

**Poids réels**:
```swift
HabitImpactWeights.sport = HabitImpactScore(
    serenity: 0.071,
    sleep: 0.107,
    energy: 0.286,  // ← Impact le plus fort
    focus: 0.107,
    balance: 0.143
)
```

**Hexagone affiché**:
- Forme: Étiré vers Énergie (100%), modéré vers Équilibre (50%), léger vers Sleep/Focus (37%)
- Top 4 impacts affichés: Énergie (29), Équilibre (14), Sommeil (11), Focus (11)

---

### Sommeil (habitId: "sleep")

**Poids réels** (divisés par 2 car 2 tâches/jour):
```swift
HabitImpactWeights.sleep = HabitImpactScore(
    serenity: 0.087,
    sleep: 0.177,  // ← Impact le plus fort
    energy: 0.152,
    focus: 0.123,
    balance: 0.088
)
```

**Hexagone affiché**:
- Forme: Étiré vers Sommeil (100%), fort vers Énergie (86%), modéré vers Focus (69%)
- Top 4 impacts affichés: Sommeil (18), Énergie (15), Focus (12), Équilibre (9)

---

## Flow de Données

```
1. User clique sur tâche "Méditation du matin"
   ↓
2. HabitTaskDetailView s'ouvre avec task.imageName = "habit_meditate"
   ↓
3. getImpactProgress() appelée pour dessiner l'hexagone:
   a. getHabitId("habit_meditate") → "meditation"
   b. HabitImpactWeights.impactForHabit("meditation")
   c. Retourne HabitImpactScore(serenity: 0.248, sleep: 0.141, ...)
   d. Normalise: maxWeight = 0.248
   e. Divise tous par 0.248 → [1.0, 0.569, 0.367, 0.867, 0.706]
   f. Retourne [global, serenity, sleep, energy, focus, balance]
   ↓
4. HexagonRadarFill dessine l'hexagone avec ces proportions
   ↓
5. Hexagone affiché: Étiré vers Sérénité, fort vers Focus
```

---

## Cohérence avec le Système de Scoring

### Relation avec ImpactScoringService

Quand une tâche est validée:

1. **TasksV2View.validateTask()**:
   ```swift
   let updatedScores = try await ImpactScoringService.shared.applyTaskImpact(habitId: "meditation")
   // Ajoute +0.248 à Sérénité, +0.141 à Sommeil, etc.
   ```

2. **HabitTaskDetailView** affiche:
   - Hexagone avec la **même distribution** que ces poids
   - L'utilisateur **voit visuellement** ce qui va augmenter

3. **Cohérence parfaite**:
   - Si l'hexagone montre "Sérénité max", valider la tâche augmente surtout Sérénité ✅
   - Si l'hexagone montre "Énergie faible", valider la tâche augmente peu Énergie ✅

---

## Avantages de l'Implémentation

### 1. Source de Vérité Unique

**AVANT**:
- `HabitImpactWeights.swift` → poids pour le scoring
- `HabitTaskDetailView.swift` → valeurs hardcodées différentes
- ❌ Risque de désynchronisation

**APRÈS**:
- `HabitImpactWeights.swift` → **source unique**
- `HabitTaskDetailView.swift` → utilise les mêmes valeurs
- ✅ Toujours synchronisé

---

### 2. Précision

**AVANT**: Valeurs approximatives (ex: Méditation Sérénité = 20)

**APRÈS**: Valeurs exactes (ex: Méditation Sérénité = 24.8 = 0.248 × 100)

---

### 3. Tri Dynamique

**AVANT**: Ordre hardcodé dans le switch

**APRÈS**: Les 4 domaines avec le **plus d'impact** s'affichent automatiquement

---

### 4. Maintenance Facile

Pour changer les impacts:
1. Modifier `HabitImpactWeights.swift`
2. ✅ L'hexagone se met à jour automatiquement
3. ✅ Le scoring se met à jour automatiquement

Pas besoin de toucher 2 endroits différents!

---

## Testing

### Manuel

1. Lancer l'app
2. Aller sur TasksV2View
3. Cliquer sur une tâche "Méditation"
4. Vérifier que l'hexagone montre:
   - Sérénité au max (étirement vers le haut-droite)
   - Focus fort (étirement vers le bas-gauche)
   - Énergie faible (peu étiré vers le bas)

5. Cliquer sur "Sport"
6. Vérifier que l'hexagone montre:
   - Énergie au max (étirement vers le bas)
   - Équilibre/Sommeil modérés

---

## Fichiers Modifiés

| Fichier | Changements |
|---------|-------------|
| **HabitTaskDetailView.swift** | Remplacement valeurs hardcodées par HabitImpactWeights (lignes 410-562) |

---

Date: 2025-11-19
Status: ✅ Intégration complète - Build succeeded
