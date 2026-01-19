# Guide - Fonctionnalités Avancées Dashboard Analytics

## 🎯 Nouvelles Fonctionnalités Ajoutées

### 1. Sélecteur de Période Amélioré

**Périodes Prédéfinies:**
- **Aujourd'hui** - Données du jour en cours
- **7 jours** - Dernière semaine (par défaut)
- **30 jours** - Dernier mois
- **90 jours** - 3 derniers mois
- **Custom** - Sélection personnalisée avec calendrier

**Sélecteur de Date Personnalisé:**
- Cliquer sur "Custom" ouvre un calendrier
- Choisir une date de début et une date de fin
- Cliquer "Appliquer" pour mettre à jour toutes les métriques
- Les données sont filtrées en temps réel via Firebase

### 2. Page Ad Performance (Nouvelle)

Une page complète dédiée à la gestion et l'analyse de vos campagnes publicitaires.

#### 2.1 Formulaire d'Ajout de Campagne

**Champs du formulaire:**
- **App / Plateforme**: CortiFree ou autre app
- **Plateforme Publicitaire**: Meta, Google Ads, TikTok, Snapchat, Apple Search Ads
- **Nom de la campagne**: Ex: "iOS Launch Campaign"
- **Budget dépensé (€)**: Montant total investi
- **Impressions**: Nombre d'impressions
- **Clics**: Nombre de clics
- **Installations**: Nombre d'installs générées
- **Abonnements payants**: Nombre de conversions

**Actions:**
- **Ajouter la campagne**: Enregistre les données
- **Réinitialiser**: Vide le formulaire

#### 2.2 Tableau Historique des Campagnes

**Colonnes affichées:**
- Campagne (nom)
- Plateforme publicitaire
- Budget dépensé
- Impressions
- **CTR** (Click-Through Rate) = Clics / Impressions × 100
- **CPI** (Cost Per Install) = Budget / Installations
- Installations
- **Conversion** = Abonnements payants / Installations × 100
- **CPA** (Cost Per Acquisition) = Budget / Abonnements payants
- **ROI** (Return on Investment) = (Revenus - Budget) / Budget × 100
- Actions (Supprimer)

**Calculs automatiques:**
- CTR, CPI, CPA, ROI calculés en temps réel
- ROI utilise l'ARPU de l'app (35€ par défaut)
- Couleurs: vert (ROI positif), rouge (ROI négatif)

#### 2.3 Analyse de Rentabilité

**8 métriques clés calculées:**

1. **Budget Total Investi**: Somme de tous les budgets
2. **Revenus Générés**: Total des abonnements × ARPU
3. **Profit Net**: Revenus - Budget
4. **ROI Global**: Pourcentage de rentabilité
5. **CPI Moyen**: Coût moyen par installation
6. **CPA Moyen**: Coût moyen par acquisition
7. **Taux de Conversion**: Install → Paid (%)
8. **Break-even Point**: Nombre de mois pour rentabiliser

**Formule Break-even:**
```javascript
breakeven = Budget / (Abonnements × ARPU mensuel)
```

**Intégration avec les données de l'app:**
- Utilise l'ARPU réel depuis `cachedData.arpu`
- Se met à jour automatiquement quand vous ajoutez/supprimez des campagnes

#### 2.4 Simulateur de Budget Publicitaire

**Sliders interactifs:**
- **Budget mensuel**: 1,000€ à 50,000€ (pas de 1,000€)
- **CPI estimé**: 0.50€ à 20€ (pas de 0.50€)
- **Taux de conversion**: 5% à 50% (pas de 1%)
- **ARPU mensuel**: 10€ à 100€ (pas de 5€)

**Résultats calculés en temps réel:**

1. **Installations estimées** = Budget / CPI
2. **Abonnements payants estimés** = Installations × Taux de conversion
3. **Revenus mensuels estimés (Mois 1)** = Abonnements × ARPU
4. **ROI prévu (Mois 1)** = (Revenus - Budget) / Budget × 100%
5. **Break-even estimé**: Nombre de mois pour rentabiliser
6. **Profit net projeté (6 mois)**: Projection avec churn de 15%

**Formule LTV 6 mois:**
```javascript
monthlyChurn = 0.15 // 15% de churn mensuel
ltv6Months = ARPU × ((1 - (1 - monthlyChurn)^6) / monthlyChurn)
profit6Months = (Abonnements × LTV6Months) - Budget
```

---

## 🔧 Fonctionnement Technique

### Navigation entre les Pages

4 onglets disponibles:
1. **Overview** - Vue d'ensemble (KPIs + funnel)
2. **Advanced Metrics** - Métriques secondaires
3. **Recommendations** - Recommandations IA
4. **Ad Performance** - Gestion des campagnes publicitaires (NOUVEAU)

Cliquer sur un onglet:
- Cache toutes les autres pages
- Affiche la page sélectionnée
- Conserve les données en mémoire (pas de rechargement)

### Stockage des Données de Campagne

**Variable globale:**
```javascript
let adCampaigns = [];
```

**Structure d'une campagne:**
```javascript
{
    id: Date.now(),
    app: 'cortifree',
    platform: 'meta',
    name: 'iOS Launch Campaign',
    spend: 1000,
    impressions: 50000,
    clicks: 2500,
    installs: 150,
    paidSubs: 25
}
```

**Persistance:**
- Actuellement: En mémoire uniquement (perdu au refresh)
- **Amélioration future**: Stocker dans `localStorage` pour persister les données

### Intégration avec Firebase

**ARPU depuis les données réelles:**
```javascript
const arpu = cachedData && cachedData.arpu ? cachedData.arpu : 35;
```

Le simulateur et les calculs ROI utilisent l'ARPU de votre app:
- Récupéré depuis Firebase via `cachedData`
- Valeur par défaut: 35€ si données non disponibles

**Pour calculer l'ARPU réel:**
1. Récupérer le revenu total (RevenueCat)
2. Diviser par le nombre d'abonnements actifs
3. Mettre à jour `data.arpu` dans `fetchRealData()`

---

## 📊 Cas d'Usage

### Exemple 1: Évaluer une Campagne Meta

**Données saisies:**
- Plateforme: Meta (Facebook/Instagram)
- Budget: 2,000€
- Impressions: 100,000
- Clics: 3,000
- Installations: 200
- Abonnements payants: 30

**Résultats calculés:**
- CTR: 3.00%
- CPI: 10.00€
- Conversion: 15.0%
- CPA: 66.67€
- ROI: -10.5% (si ARPU = 35€ × 30 = 1,050€)

**Interprétation:**
- CTR élevé (3% est excellent)
- CPI acceptable (10€ pour iOS)
- Conversion bonne (15% est standard)
- ROI négatif au mois 1, mais rentable à partir du mois 2-3

### Exemple 2: Simuler un Budget de 10,000€

**Paramètres du simulateur:**
- Budget: 10,000€
- CPI: 6.00€
- Taux de conversion: 18%
- ARPU: 35€

**Résultats:**
- Installations: 1,666
- Abonnements payants: 300
- Revenus Mois 1: 10,500€
- ROI Mois 1: +5.0%
- Break-even: 1 mois (rentable dès le premier mois!)
- Profit 6 mois: ~45,000€

**Décision:**
✅ Investissement rentable, à lancer

---

## 🚀 Prochaines Étapes

### Améliorations Prioritaires

1. **Persistance des Données**
```javascript
// Sauvegarder dans localStorage
localStorage.setItem('adCampaigns', JSON.stringify(adCampaigns));

// Charger au démarrage
adCampaigns = JSON.parse(localStorage.getItem('adCampaigns') || '[]');
```

2. **Import/Export CSV**
```javascript
function exportCampaignsCSV() {
    const csv = adCampaigns.map(c =>
        `${c.name},${c.platform},${c.spend},${c.installs},${c.paidSubs}`
    ).join('\n');
    // Télécharger le fichier CSV
}
```

3. **Graphiques de Performance**
- Chart.js line chart: Budget vs ROI over time
- Bar chart: Comparaison des plateformes (Meta vs Google vs TikTok)
- Pie chart: Répartition du budget par plateforme

4. **Intégration API Publicitaires**
- Connexion à Meta Business API pour import automatique
- Google Ads API pour données en temps réel
- TikTok Ads Manager API

5. **Alertes et Recommandations**
```javascript
// Exemple: Alerte si CPI > 15€
if (cpi > 15) {
    alert('⚠️ CPI élevé: Optimisez vos créatives ou votre ciblage');
}
```

6. **Comparaison avec Objectifs**
```javascript
const targets = {
    cpi: 8,    // Objectif: CPI < 8€
    cpa: 50,   // Objectif: CPA < 50€
    roi: 100   // Objectif: ROI > 100%
};
// Afficher badges: ✅ Atteint / ⚠️ À améliorer
```

---

## 📝 Notes Techniques

### Calculs Clés

**CTR (Click-Through Rate):**
```javascript
CTR = (Clics / Impressions) × 100
```

**CPI (Cost Per Install):**
```javascript
CPI = Budget / Installations
```

**CPA (Cost Per Acquisition):**
```javascript
CPA = Budget / Abonnements payants
```

**Taux de Conversion:**
```javascript
Conversion = (Abonnements payants / Installations) × 100
```

**ROI (Return on Investment):**
```javascript
Revenus = Abonnements payants × ARPU
ROI = ((Revenus - Budget) / Budget) × 100
```

**Break-even (Simple):**
```javascript
Breakeven = Budget / (Abonnements × ARPU mensuel)
// Nombre de mois pour récupérer l'investissement
```

**LTV 6 mois (avec churn):**
```javascript
churn = 0.15 // 15% par mois
LTV6 = ARPU × ((1 - (1 - churn)^6) / churn)
// Revenus cumulés sur 6 mois avec attrition
```

### Benchmarks Industrie

**Wellness Apps (iOS):**
- CPI: 6€ - 12€
- CTR: 2% - 5%
- Install → Trial: 60% - 80%
- Trial → Paid: 15% - 25%
- D+7 Retention: 30% - 50%
- Monthly Churn: 10% - 20%

**Objectifs CortiFree:**
- CPI cible: < 8€
- CPA cible: < 50€
- ROI Mois 1: > 0%
- ROI 6 mois: > 150%

---

## ✅ Checklist Utilisation

- [x] Page Ad Performance ajoutée au header
- [x] Sélecteur de date custom avec calendrier
- [x] Formulaire d'ajout de campagne fonctionnel
- [x] Tableau historique avec calculs automatiques
- [x] Analyse de rentabilité en temps réel
- [x] Simulateur de budget interactif
- [ ] Persistance localStorage (à implémenter)
- [ ] Export CSV (à implémenter)
- [ ] Graphiques de tendances (à implémenter)
- [ ] Intégration APIs publicitaires (à implémenter)

---

**Dashboard CortiFree Analytics - Version 2.0**
Avec gestion complète des campagnes publicitaires et simulateur de ROI! 🚀
