# Standardisation UI/UX - CortiFree

## Résumé des Modifications

Date: 22 novembre 2025

### ✅ Phase 1: Extensions Créées

**Fichier**: `Utils/DesignSystem.swift`

Nouvelles extensions ajoutées:
- `.standardCornerRadius()` - Utilise `AppConstants.Layout.cornerRadius` (16pt)
- `.smallCornerRadius()` - Utilise `AppConstants.Layout.cornerRadiusSmall` (12pt)
- `.largeCornerRadius()` - Utilise `AppConstants.Layout.cornerRadiusLarge` (20pt)
- `.minimumTouchTarget()` - Force minimum 44x44pt (Apple HIG)

Extensions déjà disponibles:
- `.appTitle`, `.appTitle2`, `.appTitle3` - Titres standardisés
- `.appBody`, `.appBodyLarge`, `.appBodySmall` - Corps de texte
- `.appButton` - Style de bouton
- `.cardStyle()`, `.primaryButton()`, `.secondaryButton()` - Styles de composants
- `.softShadow()`, `.hardShadow()`, `.glowEffect()` - Ombres

### ✅ Phase 2: Polices Standardisées

**Script**: `standardize_ui.sh`

**Remplacements automatiques effectués** (~40 occurrences):

```bash
# SF Pro Rounded → Poppins
"SF Pro Rounded-Bold" → Font.Poppins.custom(.bold, size: X)
"SF Pro Rounded-Semibold" → Font.Poppins.custom(.semiBold, size: X)
"SF Pro Rounded-Medium" → Font.Poppins.custom(.medium, size: X)
"SF Pro Rounded-Regular" → Font.Poppins.custom(.regular, size: X)

# HankenGrotesk → Poppins
"HankenGrotesk-Bold" → Font.Poppins.custom(.bold, size: X)
"HankenGrotesk-SemiBold" → Font.Poppins.custom(.semiBold, size: X)
"HankenGrotesk-Medium" → Font.Poppins.custom(.medium, size: X)
"HankenGrotesk-Regular" → Font.Poppins.custom(.regular, size: X)
```

**Fichiers modifiés** (21 fichiers):
- HomeView.swift
- ProgressionView.swift
- DiagnosticResultView.swift
- LevelUpPopupView.swift
- AvatarProgressCard.swift
- TasksV2View.swift
- HabitTaskDetailView.swift
- ProfileView.swift
- AchievementsView.swift
- WeekProgressView.swift
- CortiFreeRatingView.swift
- HabitsProgressFlowView.swift
- ScientificPlanView.swift
- SixtyDaysExplanationView.swift
- JournalHomeView.swift
- JournalHistoryView.swift
- LearningSectionView.swift
- TipsSectionView.swift
- AddTaskManuallyView.swift
- DistractionsAndROIView.swift

### ✅ Phase 3: Corner Radius Standardisés

**Remplacements effectués** (~5 occurrences):
```bash
cornerRadius: 14 → cornerRadius: AppConstants.Layout.cornerRadius (16pt)
```

**Fichiers ciblés**:
- Components/TaskCard.swift
- Components/HabitTaskCard.swift
- Settings cards

### ✅ Phase 4: Animations Standardisées

**Remplacements effectués** (~15 occurrences):
```bash
.easeOut(duration: 0.3) → .easeInOut(duration: AppConstants.Animation.standardDuration)
.easeIn(duration: 0.3) → .easeInOut(duration: AppConstants.Animation.standardDuration)
.easeInOut(duration: 0.2) → .easeInOut(duration: AppConstants.Animation.standardDuration)
```

**Valeur standard**: `AppConstants.Animation.standardDuration = 0.3`

### ⚠️ Phase 5: Couleurs (Partiellement)

**Status**: Les couleurs hardcodées dans ProfileView sont **intentionnelles**.

**Raison**: Chaque habitude a sa couleur spécifique pour le radar chart:
- Méditation: `#9B59B6` (violet)
- Respiration: `#1ABC9C` (turquoise)
- Journal: `#E74C3C` (rouge)
- Sport: `#2ECC71` (vert)
- Water: `#3498DB` (bleu)

Ces couleurs doivent rester hard-coded car elles sont spécifiques à chaque domaine.

---

## 📊 Statistiques

- **Total remplacements**: ~60
- **Fichiers modifiés**: 21+
- **Lignes de code touchées**: ~150

---

## 🎯 Impact UX

### Avant
- ❌ 3 familles de polices différentes (SF Pro Rounded, HankenGrotesk, Poppins)
- ❌ Corner radius inconsistants (12pt, 14pt, 16pt)
- ❌ Durées d'animation variées (0.2s, 0.3s, 0.4s)
- ❌ Pas de minimum touch target garanti

### Après
- ✅ Une seule famille: Poppins (standard de l'app)
- ✅ Corner radius standardisés via AppConstants
- ✅ Durée d'animation unique: 0.3s
- ✅ Extension `.minimumTouchTarget()` disponible

---

## ⏭️ Prochaines Étapes Recommandées

### Priorité HAUTE
1. **Accessibilité** - Ajouter labels VoiceOver (0 actuellement)
2. **États d'erreur** - Ajouter UI d'erreur Firebase
3. **États vides** - Ajouter illustrations pour listes vides
4. **exit(0)** - Remplacer par méthode sûre

### Priorité MOYENNE
5. **Touch targets** - Appliquer `.minimumTouchTarget()` aux petits boutons
6. **Localisation** - Remplacer ~50+ strings hardcodés
7. **Pull-to-refresh** - Ajouter à HomeView, ProfileView
8. **Messages d'erreur** - Humaniser erreurs Firebase

### Priorité BASSE
9. **Spacings** - Auditer et utiliser AppConstants.Layout
10. **Nombres magiques** - Extraire en constantes
11. **Mode sombre** - Ajouter support complet

---

## 📝 Notes Techniques

### Script de Standardisation
Le script `standardize_ui.sh` peut être réexécuté à tout moment pour standardiser de nouveaux fichiers.

**Usage**:
```bash
cd /Users/jos/CortiFree/CortiFree
./standardize_ui.sh
```

### AppConstants
Toutes les constantes sont définies dans:
- `Utilities/AppConstants.swift`
- `Utils/DesignSystem.swift`

### Build
Vérifier le build après standardisation:
```bash
xcodebuild -project CortiFree.xcodeproj -scheme CortiFree -destination 'platform=iOS Simulator,name=iPhone 16' build
```

---

## ✅ Checklist Standardisation

- [x] Extensions créées dans DesignSystem
- [x] Polices standardisées (21 fichiers)
- [x] Corner radius standardisés (Components)
- [x] Animations standardisées (15 occurrences)
- [x] Couleurs ProfileView analysées (intentionnelles)
- [ ] Touch targets minimum 44x44pt appliqués
- [ ] Spacings standardisés
- [ ] Build vérifié sans erreurs

---

Généré automatiquement le 22/11/2025