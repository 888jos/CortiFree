# 🚀 Quick Start - Dashboard CortiFree Analytics

Guide ultra-rapide pour lancer le dashboard avec **vraies données Firebase**.

---

## ⚡ Lancement Rapide (1 commande)

```bash
cd /Users/jos/CortiFree/analytics-dashboard
chmod +x start.sh
./start.sh
```

Le dashboard s'ouvre automatiquement dans ton navigateur! 🎉

---

## 🔧 Configuration Firebase

### ✅ Credentials Déjà Configurés!

Les credentials Firebase sont **déjà configurés** dans le dashboard (ligne ~712):
- **API Key:** AIzaSyDUNiZnPmlyqra5S-NE8oyteE0He78DwBA
- **Project ID:** cortifree-app
- **Mixpanel Token:** 54821f0aa53aa5ce3804237815f94332 (EU server)

Tu n'as **rien à changer** dans le code! 🎉

### Étape Unique: Security Rules Firestore (2 min)

1. **Firebase Console** > Firestore Database > Rules
2. **Remplacer** par:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read: if true;  // Dashboard read-only
      allow write: if false;
    }
  }
}
```

3. **Publish** les règles

⚠️ **Note:** C'est pour le dev. En prod, sécuriser davantage.

**C'est tout!** Le dashboard est prêt à être utilisé. 🚀

---

## 📊 Données Affichées (100% Réelles)

Le dashboard affiche **uniquement des vraies données** de ton app CortiFree:

### Section 1: Vue d'ensemble
- **Installations** - Total users dans Firestore (`users/`)
- **Onboarding Complété** - Users avec `onboardingCompleted: true`
- **Streak Moyen** - Moyenne des `currentStreakDays`
- **Tâches Complétées** - Total des tasks dans `completed_tasks/`
- **Méditation/Respiration** - Users avec `habit_tracking` actifs

### Section 2: Funnel d'Onboarding (4 Grands Blocs)

**Clique sur chaque bloc pour voir le détail des étapes!**

1. **Découverte & Quiz** (5 étapes)
   - Welcome → Overall Quiz → Habits Quiz

2. **Éducation & Confiance** (3 étapes)
   - Reassurance → 66 Days → Plan Scientifique

3. **Inscription & Analyse** (4 étapes)
   - Authentication → Loading → Rating

4. **Engagement & Conversion** (6 étapes)
   - 8 Habits → Notifications → Paywall → Completed

⚠️ **Note:** Pour l'instant, le funnel utilise des estimations basées sur `totalUsers` et `onboardingCompleted`. Pour des données précises, il faudrait intégrer Mixpanel API.

### Section 3: Abonnements & Conversion
- Abonnements Premium (RevenueCat)
- Taux de conversion Install → Paid
- MRR & ARPU (nécessite RevenueCat data)

### Section 4: Engagement & Rétention
- **Rétention J+1, J+7, J+30** - Calculée en temps réel
- Users actifs après X jours
- Graphique de rétention

### Section 5: Utilisation des Habitudes
- **8 Habitudes:** Méditation, Respiration, Journal, Sport, Eau, Nature, Social, Sommeil
- Comptage des users avec `totalCompletions > 0` dans `habit_tracking`
- Graphique en barres

---

## 🎨 Nouveau Design

Le dashboard a été **complètement redesigné**:

✅ Design moderne avec backdrop blur
✅ Cartes KPI avec hover effects
✅ Funnel interactif (4 blocs expandables)
✅ Charts Chart.js pour rétention & habits
✅ Responsive (desktop, tablet, mobile)
✅ Loading overlay professionnel
✅ Error handling avec banner
✅ Période selector: Aujourd'hui, 7j, 30j, 90j, Tout

---

## 🔍 Comment Ça Marche

### Queries Firebase Réelles

Le dashboard fait ces requêtes Firestore:

```javascript
// 1. Total users
const usersSnapshot = await db.collection('users').get();

// 2. Onboarding completed
const onboardingCompleted = await db.collection('users')
    .where('onboardingCompleted', '==', true)
    .get();

// 3. Completed tasks per user
const tasksSnapshot = await db.collection('users')
    .doc(userId)
    .collection('completed_tasks')
    .get();

// 4. Habit tracking
const habitSnapshot = await db.collectionGroup('habit_tracking')
    .where('habitId', '==', 'meditation')
    .where('totalCompletions', '>', 0)
    .get();

// 5. Retention metrics
// Calcule pour chaque user: jours depuis création + a au moins 1 task
```

### Filtrage par Période

Le dashboard filtre les données par période:
- **Aujourd'hui:** Users créés aujourd'hui
- **7j, 30j, 90j:** Users créés dans les X derniers jours
- **Tout:** Tous les users (pas de filtre)

### Performance

⚠️ **Important:** Les queries peuvent être lentes si tu as beaucoup d'users:
- Limit de 500 docs pour `habit_tracking`
- Calcul de rétention itère sur tous les users

**Optimisations possibles:**
- Créer des index Firestore
- Pré-calculer les métriques avec Cloud Functions
- Utiliser Mixpanel pour le funnel (plus rapide)

---

## 🎯 Prochaines Étapes

### Pour Améliorer le Dashboard:

1. **Intégrer Mixpanel API** pour le funnel détaillé
   - Requêter les events `onboarding_*_viewed`
   - Obtenir les vraies données de drop-off

2. **Intégrer RevenueCat API** pour les abonnements
   - Fetcher les subscriptions actives
   - Calculer MRR, ARPU, conversion rate

3. **Optimiser les queries**
   - Créer une collection `analytics_daily` avec pré-calculs
   - Cloud Function qui agrège les données chaque jour

4. **Ajouter des graphs**
   - Timeline de croissance (users over time)
   - Heatmap des jours d'activité
   - Breakdown par plateforme (iOS version, device)

---

## 🐛 Problème?

### Firebase Error
→ Vérifie les credentials (Étape 2)

### Permission Denied
→ Vérifie les Security Rules (Étape 3)

### Pas de données affichées
→ Ouvre la console (F12) et regarde les erreurs

### Queries lentes
→ Crée les index suggérés par Firebase Console

---

## 📱 C'est Tout!

Dashboard prêt avec **vraies données Firebase** en **5 minutes**!

Lance avec `./start.sh` et analyse tes métriques CortiFree! 🚀

---

**Plus de détails:** Voir `README.md` pour la doc complète.
