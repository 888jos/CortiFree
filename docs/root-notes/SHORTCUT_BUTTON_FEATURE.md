# Bouton Raccourci sur les Cartes de Tâches

## Problème Résolu

Ajout d'un **bouton de raccourci** directement sur les cartes de tâches (méditation, respiration et journal) pour accéder rapidement aux vues d'exercices.

---

## Solution Implémentée

### Fichier: `Components/TaskCard.swift`

#### 1. État pour la Navigation (ligne 23)

```swift
@State private var showExerciseView = false
```

---

#### 2. UI du Bouton (lignes 165-205)

**Position**: Coin inférieur droit de la carte de tâche (dans le ZStack)

**Apparence**:
- Rectangle arrondi avec coins de 20px
- Dégradé violet (B794F6 → 9B59B6)
- Ombre douce pour effet flottant
- Icône + texte
- Taille compacte adaptée à la carte

```swift
// Shortcut button (bottom right) - Only for meditation, breathing, journal
if shouldShowShortcut() {
    VStack {
        Spacer()
        HStack {
            Spacer()

            Button(action: {
                HapticManager.light()
                showExerciseView = true
            }) {
                HStack(spacing: 6) {
                    Image(systemName: getShortcutIcon())
                        .font(.system(size: 16, weight: .semibold))

                    Text(getShortcutText())
                        .font(.custom("Poppins-SemiBold", size: 13))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hex: "B794F6"),
                                    Color(hex: "9B59B6")
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: Color(hex: "B794F6").opacity(0.4), radius: 8, x: 0, y: 2)
                )
            }
            .padding(.trailing, 12)
            .padding(.bottom, 12)
        }
    }
}
```

---

#### 3. Navigation (lignes 217-229)

Utilise `.fullScreenCover` pour présenter la vue en plein écran.

```swift
.fullScreenCover(isPresented: $showExerciseView) {
    let habitId = getHabitId(for: imageName)
    switch habitId {
    case "meditation":
        MeditationListView()
    case "breathing":
        BreathingListView()
    case "journal":
        JournalView()
    default:
        EmptyView()
    }
}
```

---

#### 4. Helper Functions (lignes 232-288)

##### shouldShowShortcut()

Détermine si le bouton doit être affiché.

```swift
private func shouldShowShortcut() -> Bool {
    let habitId = getHabitId(for: task.imageName)
    return habitId == "meditation" || habitId == "breathing" || habitId == "journal"
}
```

**Retourne `true` pour**:
- ✅ Tâches de méditation
- ✅ Tâches de respiration
- ✅ Tâches de journal

**Retourne `false` pour**:
- ❌ Sommeil, eau, sport, nature, social

---

##### getShortcutIcon()

Retourne l'icône SF Symbol appropriée.

```swift
private func getShortcutIcon() -> String {
    let habitId = getHabitId(for: task.imageName)
    switch habitId {
    case "meditation":
        return "brain.head.profile"
    case "breathing":
        return "wind"
    case "journal":
        return "book.fill"
    default:
        return "star.fill"
    }
}
```

**Icônes**:
- 🧠 Méditation → `brain.head.profile`
- 💨 Respiration → `wind`
- 📖 Journal → `book.fill`

---

##### getShortcutText()

Retourne le texte du bouton.

```swift
private func getShortcutText() -> String {
    let habitId = getHabitId(for: task.imageName)
    switch habitId {
    case "meditation":
        return "Méditer"
    case "breathing":
        return "Respirer"
    case "journal":
        return "Écrire"
    default:
        return "Ouvrir"
    }
}
```

**Textes**:
- Méditation → **"Méditer"**
- Respiration → **"Respirer"**
- Journal → **"Écrire"**

---

## Flow Utilisateur

### Scénario 1: Tâche de Méditation

```
1. User voit la carte "Méditation du matin" dans TasksV2View
   ↓
2. La carte affiche le bouton "🧠 Méditer" en bas à droite
   ↓
3. User clique sur le bouton raccourci
   ↓
4. Haptic feedback (light)
   ↓
5. showExerciseView = true
   ↓
6. fullScreenCover présente MeditationListView
   ↓
7. User choisit un exercice de méditation guidée
   ↓
8. User peut commencer immédiatement sans passer par le détail de la tâche
```

### Scénario 2: Tâche de Respiration

```
1. User voit la carte "Exercice de respiration" dans TasksV2View
   ↓
2. Bouton "💨 Respirer" affiché sur la carte
   ↓
3. User clique → BreathingListView
   ↓
4. User choisit un exercice de respiration (box breathing, 4-7-8, etc.)
```

### Scénario 3: Tâche de Journal

```
1. User voit la carte "Écriture journal" dans TasksV2View
   ↓
2. Bouton "📖 Écrire" affiché sur la carte
   ↓
3. User clique → JournalView
   ↓
4. User peut écrire dans son journal immédiatement
```

### Scénario 4: Autres Tâches (Eau, Sport, etc.)

```
1. User voit la carte "Boire de l'eau" dans TasksV2View
   ↓
2. ❌ Pas de bouton raccourci (shouldShowShortcut() = false)
   ↓
3. Seulement le badge streak et l'icône info sont visibles
   ↓
4. User doit cliquer sur la carte pour voir les détails
```

---

## Design Visuel

### Position
- **Coin inférieur droit de la carte de tâche**
- Padding trailing: 12px
- Padding bottom: 12px

### Style
- **Forme**: RoundedRectangle(cornerRadius: 20)
- **Fond**: Dégradé linéaire
  - Top-left: #B794F6 (violet clair)
  - Bottom-right: #9B59B6 (violet foncé)
- **Ombre**:
  - Couleur: #B794F6 à 40% d'opacité
  - Radius: 8px
  - Offset: (0, 2)
- **Contenu**: HStack avec icône + texte
  - Spacing: 6px
  - Padding horizontal: 12px
  - Padding vertical: 8px

### Typographie
- **Icône**: SF Symbol, size 16, weight semibold
- **Texte**: Poppins-SemiBold, size 13
- **Couleur**: Blanc

---

## Avantages

### 1. Accès Rapide aux Exercices

**AVANT**:
```
User → TasksView → Retour HomeView → QuickAccess → Méditation
(4 étapes)
```

**APRÈS**:
```
User → TasksView → Bouton "Méditer" sur la carte → MeditationListView
(2 étapes)
```

**Économie**: -2 étapes, -50% de clics, accès direct depuis la carte

---

### 2. Contextuel et Pertinent

Le bouton n'apparaît **que** pour les tâches qui ont une vue d'exercice associée:
- ✅ Méditation → a des exercices guidés
- ✅ Respiration → a des techniques de respiration
- ✅ Journal → a une vue d'écriture

Les autres tâches (eau, sport, nature, social, sommeil) n'ont pas besoin de raccourci car elles n'ont pas de vue d'exercice dédiée.

---

### 3. Design Cohérent

Le style violet du bouton **correspond au thème** des tâches/habitudes:
- Même palette que les cartes d'impact
- Gradient similaire aux autres boutons CTA
- Effet d'ombre pour l'affordance

---

### 4. Feedback Haptique

Utilise `HapticManager.light()` pour donner un retour tactile immédiat quand le bouton est pressé, améliorant l'expérience utilisateur.

---

## Tests de Validation

### Test 1: Carte de Méditation
1. ✅ Aller dans TasksV2View
2. ✅ Voir la carte "Méditation du matin"
3. ✅ Vérifier que le bouton "🧠 Méditer" apparaît en bas à droite de la carte
4. ✅ Cliquer sur le bouton raccourci
5. ✅ Vérifier que MeditationListView s'ouvre en plein écran
6. ✅ Fermer et retourner à TasksV2View

### Test 2: Carte de Respiration
1. ✅ Voir la carte "Exercice de respiration"
2. ✅ Vérifier que le bouton "💨 Respirer" apparaît sur la carte
3. ✅ Cliquer → BreathingListView s'ouvre
4. ✅ Choisir un exercice de respiration

### Test 3: Carte de Journal
1. ✅ Voir la carte "Écriture journal"
2. ✅ Vérifier que le bouton "📖 Écrire" apparaît sur la carte
3. ✅ Cliquer → JournalView s'ouvre
4. ✅ Écrire dans le journal

### Test 4: Autres Cartes (Négatif)
1. ✅ Voir la carte "Boire de l'eau"
2. ✅ Vérifier que **aucun bouton raccourci** n'apparaît
3. ✅ Répéter pour cartes Sport, Nature, Social, Sommeil
4. ✅ Confirmer que seules les cartes Méditation/Respiration/Journal ont le bouton

---

## Fichiers Modifiés

| Fichier | Changement | Lignes |
|---------|-----------|--------|
| **Components/TaskCard.swift** | + @State showExerciseView | 23 |
| **Components/TaskCard.swift** | + Bouton raccourci UI | 165-205 |
| **Components/TaskCard.swift** | + .fullScreenCover navigation | 217-229 |
| **Components/TaskCard.swift** | + getHabitId() | 232-252 |
| **Components/TaskCard.swift** | + shouldShowShortcut() | 254-258 |
| **Components/TaskCard.swift** | + getShortcutIcon() | 260-273 |
| **Components/TaskCard.swift** | + getShortcutText() | 275-288 |

---

## Dépendances

### Vues Cibles
- ✅ `Views/QuickAccess/MeditationListView.swift` - Existe
- ✅ `Views/QuickAccess/BreathingListView.swift` - Existe
- ✅ `Views/Journal/JournalView.swift` - Existe

### Utilitaires
- ✅ `HapticManager.swift` - Pour le feedback haptique
- ✅ `getHabitId(for:)` - Helper existant pour mapper imageName → habitId

---

## Évolutions Futures Possibles

### 1. Animation d'Entrée
Ajouter une animation slide-in pour le bouton:
```swift
.transition(.move(edge: .trailing).combined(with: .opacity))
```

### 2. Badge de Notification
Si l'user n'a pas fait l'exercice aujourd'hui, afficher un badge:
```swift
.overlay(
    Circle()
        .fill(Color.red)
        .frame(width: 8, height: 8)
        .offset(x: 12, y: -12)
    , alignment: .topTrailing
)
```

### 3. Long Press pour Options
Long press pourrait ouvrir un menu avec plusieurs exercices:
```swift
.contextMenu {
    Button("Méditation courte (5 min)") { ... }
    Button("Méditation longue (15 min)") { ... }
}
```

---

Date: 2025-11-19
Status: ✅ Implémentation complète - Prêt pour test
