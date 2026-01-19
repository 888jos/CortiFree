# 📊 Guide - Gestion des Scénarios Publicitaires

## 🎯 Pourquoi les Scénarios?

Les scénarios te permettent de **tester et comparer différents modèles publicitaires** pour trouver la meilleure stratégie:
- Comparer Meta vs Google vs TikTok
- Tester différents budgets (5K vs 10K vs 20K)
- Optimiser tes taux de conversion
- Projeter la rentabilité sur 6, 12, ou 24 mois

## 🚀 Comment Ça Marche

### 1. Créer un Scénario

1. Va sur l'onglet **"Ad Performance"**
2. Scroll jusqu'au **"Simulateur de Budget Publicitaire Avancé"**
3. **Configure tous les paramètres** (24 inputs disponibles)
4. Observe les résultats calculés en temps réel
5. **Donne un nom** au scénario (ex: "Meta 10K - Conv 18%")
6. Clique sur **"💾 Sauvegarder"**

✅ Ton scénario est enregistré avec tous ses paramètres ET ses résultats!

---

### 2. Gérer les Scénarios

Une fois sauvegardés, tes scénarios apparaissent dans un **tableau de comparaison**:

```
┌─────────────────┬─────────┬──────┬──────────┬───────────┬──────────┬──────────┬───────────┐
│ Scénario        │ Budget  │ CPI  │ Installs │ Paid Subs │ ROI M1   │ ROI 12M  │ Break-even│
├─────────────────┼─────────┼──────┼──────────┼───────────┼──────────┼──────────┼───────────┤
│ Meta 10K        │ €10,000 │ €6.50│ 1,538    │ 193       │ -82.4%   │ +45.2%   │ 8 mois    │
│ Google 10K      │ €10,000 │ €8.00│ 1,250    │ 156       │ -88.1%   │ +28.5%   │ 10 mois   │
│ TikTok 10K      │ €10,000 │ €5.00│ 2,000    │ 250       │ -65.3%   │ +82.6%   │ 6 mois    │
└─────────────────┴─────────┴──────┴──────────┴───────────┴──────────┴──────────┴───────────┘
```

**Actions disponibles:**
- **📂 Charger**: Recharge tous les paramètres du scénario dans le simulateur
- **📋 Dupliquer**: Crée une copie pour tester des variantes
- **🗑️ Supprimer**: Supprime le scénario

---

### 3. Comparer des Scénarios

**Workflow recommandé:**

#### Étape 1: Créer un scénario de base
```
Nom: "Baseline - 5K"
Budget: 5,000€
CPI: 7€
Conv Install→Trial: 70%
Conv Trial→Paid: 15%
Prix: 9.99€/mois, 49.99€/an
→ Sauvegarder
```

#### Étape 2: Dupliquer et varier le budget
```
📋 Dupliquer "Baseline - 5K"
→ Renommer: "Test Budget 10K"
→ Charger
→ Modifier: Budget = 10,000€
→ Observer les résultats
→ Sauvegarder
```

#### Étape 3: Tester différents CPI
```
📋 Dupliquer "Baseline - 5K"
→ Renommer: "Test CPI Bas"
→ Charger
→ Modifier: CPI = 4.50€ (optimisé)
→ Observer le ROI
→ Sauvegarder
```

#### Étape 4: Optimiser les conversions
```
📋 Dupliquer "Baseline - 5K"
→ Renommer: "Optimisation Conversion"
→ Charger
→ Modifier: Conv Trial→Paid = 22% (après A/B tests)
→ Comparer avec baseline
→ Sauvegarder
```

---

## 📤 Export CSV

Le bouton **"📤 Export CSV"** génère un fichier Excel/CSV avec tous tes scénarios.

**Colonnes exportées:**
- Nom du scénario
- Budget, CPI, Taux de conversion
- Prix mensuel, Prix annuel, Churn
- Durée de projection (mois)
- Résultats: Installs, Paid Subs, CPA
- Revenue Net, Profit Mois 1, ROI Mois 1
- Profit Cumulé, ROI Cumulé, Break-even
- Date de création

**Utilisation:**
1. Clique sur "📤 Export CSV"
2. Ouvre le fichier dans Excel/Numbers/Google Sheets
3. Crée des graphiques de comparaison
4. Partage avec ton équipe

---

## 🎯 Cas d'Usage Réels

### Cas 1: Choisir Entre Meta et Google

**Objectif:** Quel réseau publicitaire est le plus rentable?

**Scénarios à tester:**
```
1. "Meta - 10K Budget"
   - CPI: 6.50€ (typique Meta iOS)
   - CTR: 3%
   - Conv Install→Trial: 75%

2. "Google - 10K Budget"
   - CPI: 8.00€ (typique Google Search)
   - CTR: 4.5%
   - Conv Install→Trial: 70%

3. "TikTok - 10K Budget"
   - CPI: 5.00€ (moins cher mais...)
   - CTR: 2%
   - Conv Install→Trial: 65% (qualité moindre)
```

**Résultats attendus:**
- Meta: ROI 12M = +45% | Break-even = 8 mois
- Google: ROI 12M = +28% | Break-even = 10 mois
- TikTok: ROI 12M = +82% | Break-even = 6 mois ✅

**Décision:** TikTok offre le meilleur ROI malgré une conv plus faible!

---

### Cas 2: Optimiser le Budget

**Objectif:** Quel budget maximise le ROI?

**Scénarios à tester:**
```
1. "Budget 2K" → ROI 12M = +120%
2. "Budget 5K" → ROI 12M = +95%
3. "Budget 10K" → ROI 12M = +68%
4. "Budget 20K" → ROI 12M = +42%
```

**Insight:** Budget plus petit = ROI % plus élevé, mais profit absolu plus faible.

**Décision:** Dépend de tes objectifs:
- Maximiser ROI % → 2K
- Maximiser profit absolu → 20K
- Équilibre → 5-10K

---

### Cas 3: Impact de l'Optimisation Conversion

**Objectif:** Vaut-il la peine d'investir dans l'optimisation du funnel?

**Scénarios:**
```
1. "Avant Optimisation"
   - Conv Install→Trial: 70%
   - Conv Trial→Paid: 15%
   → ROI 12M = +45%

2. "Après A/B Tests"
   - Conv Install→Trial: 80% (+10%)
   - Conv Trial→Paid: 20% (+5%)
   → ROI 12M = +128% 🚀
```

**Décision:** +10% de conv Install→Trial et +5% Trial→Paid = **+83% de ROI**!
Investir dans l'optimisation du funnel est ultra rentable.

---

### Cas 4: Prix Annuel vs Mensuel

**Objectif:** Quel mix annuel/mensuel est optimal?

**Scénarios:**
```
1. "70% Annuel / 30% Mensuel" (actuel)
   → LTV = 68.50€ | ROI 12M = +45%

2. "50% Annuel / 50% Mensuel"
   → LTV = 62.30€ | ROI 12M = +38%

3. "90% Annuel / 10% Mensuel"
   → LTV = 72.80€ | ROI 12M = +54% ✅
```

**Décision:** Pousser les abonnements annuels augmente significativement le LTV et le ROI!

---

## 💡 Tips & Best Practices

### 1. Nomme Bien Tes Scénarios
❌ Mauvais: "Test 1", "Essai", "Nouveau"
✅ Bon: "Meta 10K - CPI 6€ - Conv 18%", "Google Optimisé v2"

**Format recommandé:** `[Plateforme] [Budget] - [Particularité]`

### 2. Teste Systématiquement
**Méthode scientifique:**
1. Crée un scénario "Baseline" (situation actuelle)
2. Ne change **qu'un seul paramètre** à la fois
3. Compare avec le baseline
4. Documente tes insights

### 3. Utilise les Duplications
Au lieu de tout reconfigurer:
1. Duplique un scénario proche
2. Change 1-2 paramètres
3. Sauvegarde avec nouveau nom

### 4. Projections Long Terme
**Pour évaluer la vraie rentabilité:**
- Change "Projection sur" à **24 mois** (2 ans)
- Observe le ROI Cumulé et le Payback period
- Un ROI négatif Mois 1 peut devenir +200% à 24 mois!

### 5. Teste la Sensibilité
**Questions à se poser:**
- Si mon CPI augmente de 20%, suis-je toujours rentable?
- Si mon churn passe à 20%, quel impact?
- Quelle conv Trial→Paid minimum pour break-even?

Crée des scénarios "Pessimiste" et "Optimiste" autour de ton Baseline.

---

## 📊 Métriques à Surveiller

### Pour Choisir le Meilleur Scénario

**Si budget limité (<10K/mois):**
- Focus: **ROI Cumulé %** (maximiser le retour)
- Métrique secondaire: Break-even (< 6 mois idéal)

**Si budget illimité (>50K/mois):**
- Focus: **Profit Cumulé €** (maximiser profit absolu)
- Métrique secondaire: CPA (< 50€ idéal)

**Pour tester une nouvelle plateforme:**
- Focus: **CPI + Taux de conversion global**
- Si CPI bas mais conv basse = faux positif!

---

## 🔄 Workflow Complet

```
1. Baseline
   └─ Sauvegarder situation actuelle

2. Tests Budget
   ├─ 2K, 5K, 10K, 20K
   └─ Identifier point optimal

3. Tests Plateforme
   ├─ Meta, Google, TikTok, Snapchat
   └─ Choisir la plus rentable

4. Tests Conversion
   ├─ Conv optimisée (+10%)
   └─ Calculer gain potentiel

5. Tests Pricing
   ├─ 70% annuel, 80% annuel, 90% annuel
   └─ Optimiser mix

6. Scénario Final
   └─ Combinaison des meilleurs paramètres
```

---

## 💾 Stockage des Scénarios

Les scénarios sont sauvegardés dans **localStorage** (navigateur).

**Important:**
- ✅ Persiste entre les sessions (pas besoin de resauvegarder)
- ✅ Spécifique à ton navigateur (sécurisé)
- ⚠️ Si tu changes de navigateur/ordinateur, exporte en CSV d'abord
- ⚠️ Nettoyer le cache navigateur = perte des scénarios

**Backup recommandé:** Exporte régulièrement en CSV!

---

## ✅ Checklist Avant de Lancer une Campagne

- [ ] Créer scénario "Baseline" avec données actuelles
- [ ] Créer scénario "Optimiste" (+20% conv, -15% CPI)
- [ ] Créer scénario "Pessimiste" (-20% conv, +15% CPI)
- [ ] Vérifier que scénario Pessimiste reste rentable (ROI > 0%)
- [ ] Calculer budget maximum pour break-even < 12 mois
- [ ] Exporter tous les scénarios en CSV
- [ ] Partager avec l'équipe pour validation
- [ ] 🚀 Lancer la campagne

---

**Dashboard CortiFree Analytics - Version 3.0**
Avec gestion complète des scénarios publicitaires! 🎉

Maintenant tu peux **tester et comparer** tous tes modèles publicitaires pour trouver la stratégie la plus rentable!
