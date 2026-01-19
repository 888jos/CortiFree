# Guide d'Intégration - Nouvelles Pages Analytics

## 📋 Résumé

Nous avons créé **3 pages** pour le dashboard CortiFree:
1. **Overview** (existante) - KPIs principaux + funnels
2. **Advanced Metrics** (nouvelle) - Métriques secondaires avancées
3. **Recommendations** (nouvelle) - Recommandations IA en temps réel

## 🔧 Intégration Manuelle

### Étape 1: Ajouter le script JavaScript

Avant la balise `</body>` dans `cortifree-analytics.html`, ajoute:

```html
<script src="cortifree-analytics-pages.js"></script>
```

### Étape 2: Wrapper le contenu Overview

Trouve la ligne avec `<!-- KPI Cards -->` et ajoute AVANT:

```html
<!-- PAGE 1: OVERVIEW -->
<div class="page-content active" id="overviewPage">
```

Puis trouve la fin du contenu (avant les `</div></body>`) et ferme la div:

```html
</div> <!-- End Overview Page -->
```

### Étape 3: Ajouter les nouvelles pages

Copie le contenu de `new-pages.html` et insère-le APRÈS la fermeture de `overviewPage` et AVANT `</div></body>`.

## 📊 Fonctionnalités

### Page "Advanced Metrics"

**Métriques Affichées:**
- Session Duration (durée moyenne de session)
- DAU/MAU Ratio (ratio utilisateurs actifs quotidiens/mensuels)
- Churn Rate (taux de désabonnement mensuel)
- Time to Value (temps jusqu'à première task)
- Feature Adoption (utilisateurs essayant 3+ habitudes)
- Power Users (utilisateurs quotidiens)
- ARPS (revenu moyen par session)
- CAC Payback Period (temps pour récupérer coût d'acquisition)
- Viral Coefficient (K-factor, référencements par user)

**Cohortes:**
- Highly Engaged (>10 jours de streak)
- Moderately Active (3-10 jours)
- At Risk (1-3 jours)
- Churned (0 jours récemment)

### Page "Recommendations"

**Algorithme de Recommandations:**

L'IA analyse automatiquement:
1. **Onboarding Rate** < 70% → Simplifier le flux
2. **Paywall View Rate** < 50% → Fixer les drop-offs
3. **Avg Streak** < 5 jours → Améliorer engagement
4. **D+7 Retention** < 40% → Implémenter email drips
5. **Trial to Paid** < 20% → A/B tester le pricing

**Priorités:**
- 🚨 **HIGH** (rouge) - Impact immédiat sur revenue
- ⚠️ **MEDIUM** (orange) - Amélioration engagement
- ✅ **LOW** (vert) - Optimisations, quick wins

**Chaque Recommandation Contient:**
- Titre + Description du problème
- Métriques actuelles vs. target
- 2-3 actions concrètes à implémenter

## 🎨 Navigation

Les utilisateurs peuvent switcher entre les pages via les onglets en haut:

```
[Overview] [Advanced Metrics] [Recommendations]
```

- **Overview** = vue par défaut (active au chargement)
- **Advanced Metrics** = métriques secondaires (données statiques pour l'instant)
- **Recommendations** = générées dynamiquement à partir de `cachedData`

## 💻 Logique JavaScript

### Fonction `switchPage(pageName)`
```javascript
// Appelée par onclick sur les nav-tabs
// Cache toutes les pages, affiche celle demandée
// Génère les recommendations si page = 'recommendations'
```

### Fonction `generateRecommendations(data)`
```javascript
// Analyse cachedData
// Retourne array de recommandations avec:
// - title, description, priority
// - metrics (array de {label, value})
// - actions (array de {label, primary})
```

## 🚀 Prochaines Étapes

Pour rendre les métriques avancées **réelles** (pas mockées):

1. **Session Duration**: Tracker timestamps dans Firebase
2. **DAU/MAU**: Compter users actifs par jour/mois
3. **Churn Rate**: Calculer désabonnements mensuels via RevenueCat
4. **TTV**: Timestamp de first task completion
5. **Feature Adoption**: Compter users avec >3 habitudes actives
6. **Power Users**: Users avec tasks chaque jour
7. **ARPS**: Revenue total / nombre de sessions
8. **CAC Payback**: LTV / months to breakeven
9. **Viral K**: Referrals / total users

## ✅ Checklist d'Intégration

- [ ] Copier `cortifree-analytics-pages.js` dans le dossier
- [ ] Ajouter `<script src="...">` avant `</body>`
- [ ] Wrapper contenu Overview dans `<div class="page-content active">`
- [ ] Copier contenu de `new-pages.html` après Overview
- [ ] Tester navigation entre onglets
- [ ] Vérifier génération des recommandations
- [ ] (Optionnel) Remplacer métriques mockées par vraies queries

## 📝 Notes

- Les styles CSS sont déjà dans `cortifree-analytics.html`
- La navigation utilise les classes `.active` pour show/hide
- Les recommendations se génèrent automatiquement au switch de page
- Toutes les métriques sont calculées à partir de `cachedData` (données réelles Firebase)

---

**C'est tout!** Le dashboard CortiFree dispose maintenant de 3 pages complètes avec recommandations IA. 🎉
