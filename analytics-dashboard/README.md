# 🎯 CortiFree Analytics Dashboard

Dashboard analytics standalone (HTML/JS) pour visualiser les métriques clés de l'app CortiFree iOS.

## 📊 Fonctionnalités

### 5 Sections Principales

1. **📊 Overview (KPI Clés)**
   - Installations
   - Onboarding started/completed
   - Trials started
   - Active subscriptions
   - Revenue total
   - ARPU (Average Revenue Per User)
   - Conversion globale Install → Paid

2. **🔽 Funnel d'Onboarding**
   - Visualisation de l'entonnoir complet
   - Pourcentages de conversion à chaque étape
   - Identification automatique de la plus grosse perte
   - Drop-off percentages

3. **💳 Trial & Abonnements**
   - Taux de conversion Trial → Paid
   - Répartition Annuel vs Mensuel
   - Churn J+1 et J+7
   - Temps moyen avant conversion

4. **💰 Revenue Details**
   - Revenu brut
   - Commission Apple (15%)
   - Revenu net
   - ARPPU (Average Revenue Per Paying User)
   - Projection 30 jours

5. **📈 Indicateurs Produit**
   - Activation rate (≥1 session)
   - Users avec ≥3 sessions
   - Utilisation respiration/méditation
   - Corrélation usage → conversion

### Gestion des Périodes

- **Aujourd'hui** - Données du jour en cours
- **7 jours** - 7 derniers jours
- **30 jours** - 30 derniers jours (défaut)
- **90 jours** - 90 derniers jours
- **Custom** - Sélection de date personnalisée

---

## 🚀 Installation & Setup

### Étape 1: Récupérer les Credentials Firebase

1. Aller sur [Firebase Console](https://console.firebase.google.com/)
2. Sélectionner votre projet **CortiFree**
3. Aller dans **Project Settings** (⚙️ en haut à gauche)
4. Scroller jusqu'à **Your apps**
5. Si pas d'app Web:
   - Cliquer sur le bouton **</>** (Add app)
   - Nom: "CortiFree Analytics Dashboard"
   - Pas besoin d'activer Firebase Hosting
6. Copier l'objet `firebaseConfig` qui ressemble à:

```javascript
const firebaseConfig = {
  apiKey: "AIzaSyBxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
  authDomain: "cortifree.firebaseapp.com",
  projectId: "cortifree",
  storageBucket: "cortifree.appspot.com",
  messagingSenderId: "123456789012",
  appId: "1:123456789012:web:abcdef1234567890"
};
```

### Étape 2: Configurer le Dashboard

1. Ouvrir `cortifree-analytics.html` dans un éditeur de texte
2. Trouver la section Firebase Configuration (ligne ~800):

```javascript
const firebaseConfig = {
    apiKey: "YOUR_API_KEY",  // ← Remplacer ici
    authDomain: "cortifree.firebaseapp.com",
    projectId: "cortifree",  // ← Et ici
    // ...
};
```

3. Remplacer les valeurs `YOUR_XXX` avec vos vraies credentials
4. Sauvegarder le fichier

### Étape 3: Configurer les Security Rules Firebase

**IMPORTANT:** Par défaut, Firestore bloque les lectures. Il faut autoriser le dashboard à lire les données.

1. Dans Firebase Console, aller dans **Firestore Database**
2. Onglet **Rules**
3. Ajouter une règle pour autoriser la lecture (⚠️ À ajuster selon votre sécurité):

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Règle temporaire pour dev (À SÉCURISER en prod)
    match /{document=**} {
      allow read: if true;  // ⚠️ Ouvert à tous
      allow write: if false; // Dashboard en lecture seule
    }

    // Option sécurisée: Restreindre à une IP ou un domaine
    // Créer un user Firebase Auth dédié pour le dashboard
    // match /{document=**} {
    //   allow read: if request.auth != null && request.auth.uid == "DASHBOARD_USER_ID";
    // }
  }
}
```

### Étape 4: Lancer le Dashboard

#### Option A: Ouvrir directement dans le navigateur

```bash
# Naviguer vers le dossier
cd /Users/jos/CortiFree/analytics-dashboard/

# Ouvrir dans le navigateur par défaut
open cortifree-analytics.html

# Ou spécifier Chrome/Firefox/Safari
open -a "Google Chrome" cortifree-analytics.html
```

#### Option B: Serveur local (recommandé pour éviter les erreurs CORS)

```bash
# Avec Python (Python 3)
python3 -m http.server 8000

# Avec Python 2
python -m SimpleHTTPServer 8000

# Avec Node.js (si http-server installé)
npx http-server -p 8000

# Avec PHP
php -S localhost:8000
```

Puis ouvrir: `http://localhost:8000/cortifree-analytics.html`

---

## 🎨 Données Mockées vs Réelles

### Par Défaut: Données Mockées

Le dashboard utilise des données simulées pour que vous puissiez tester immédiatement l'interface.

Dans `cortifree-analytics.html`, ligne ~910:

```javascript
// Mode MOCK (défaut)
const metrics = await fetchMockData();

// Mode FIREBASE (décommenter quand prêt)
// const metrics = await fetchFirebaseData();
```

### Passer aux Données Réelles

1. Ouvrir `cortifree-analytics.html`
2. Trouver la fonction `fetchAndRenderMetrics()` (ligne ~908)
3. Commenter la ligne `fetchMockData()`:

```javascript
// const metrics = await fetchMockData();  // ← Commenter
```

4. Décommenter la ligne `fetchFirebaseData()`:

```javascript
const metrics = await fetchFirebaseData();  // ← Décommenter
```

5. Sauvegarder et recharger la page

---

## 📝 Structure des Données Firestore

Le dashboard s'attend à cette structure (déjà présente dans CortiFree):

### Collection `users`

```javascript
{
  uid: "xxx",
  email: "user@example.com",
  createdAt: Timestamp,
  onboardingCompleted: true,
  onboardingCompletedAt: Timestamp,
  subscriptionActive: true,  // À ajouter si pas présent
  // ...
}
```

### Sous-collection `users/{uid}/completed_tasks`

```javascript
{
  taskId: "breathing_morning",
  completedAt: Timestamp,
  // ...
}
```

### Collection Group `habit_tracking`

```javascript
{
  habitId: "breathing", // ou "meditation"
  totalCompletions: 5,
  // ...
}
```

---

## 🔧 Queries Firebase Utilisées

Le dashboard effectue ces queries Firestore:

```javascript
// 1. Total users
db.collection('users').get()

// 2. Onboarding completed
db.collection('users')
  .where('onboardingCompleted', '==', true)
  .get()

// 3. Active subscriptions
db.collection('users')
  .where('subscriptionActive', '==', true)
  .get()

// 4. Breathing users
db.collectionGroup('habit_tracking')
  .where('habitId', '==', 'breathing')
  .where('totalCompletions', '>', 0)
  .get()

// 5. Meditation users
db.collectionGroup('habit_tracking')
  .where('habitId', '==', 'meditation')
  .where('totalCompletions', '>', 0)
  .get()
```

**Note:** Certaines queries (comme le comptage des sessions) nécessitent de parcourir les sous-collections, ce qui peut être lent pour beaucoup d'utilisateurs. Le code inclut une limite de 100 users pour la performance.

---

## ⚡ Performance & Optimisations

### Pour de Meilleures Performances

1. **Créer des Index Firestore:**
   - Firebase va suggérer automatiquement les index nécessaires
   - Cliquer sur les liens dans la console si erreurs

2. **Limiter les Queries:**
   - Le dashboard limite certaines queries lourdes à 100 documents
   - Ajuster selon vos besoins dans `fetchFirebaseData()`

3. **Cacher les Résultats:**
   - Les données sont déjà cachées dans `cachedMetrics`
   - Éviter de recharger inutilement

4. **Utiliser des Agrégations:**
   - Idéalement, pré-calculer les métriques dans Cloud Functions
   - Stocker dans une collection `analytics_daily` par exemple

---

## 🔒 Sécurité

### ⚠️ Important

- **Ne jamais commit `firebase-config.js`** avec vos vraies credentials
- Le `.gitignore` est déjà configuré pour ignorer ce fichier
- Les clés API Firebase peuvent être publiques (utilisées côté client), mais:
  - Configurer les Security Rules Firestore correctement
  - Limiter les domaines autorisés dans Firebase Console

### Sécuriser l'Accès

#### Option 1: Domaine Whitelisting

Dans Firebase Console > Project Settings > General:
- Ajouter seulement votre domaine dans "Authorized domains"

#### Option 2: Firebase Auth Required

Créer un user Firebase Auth dédié:

```javascript
// Ajouter authentification dans cortifree-analytics.html
firebase.auth().signInWithEmailAndPassword("dashboard@cortifree.com", "PASSWORD")
  .then(() => {
    // Lancer les queries
    fetchAndRenderMetrics();
  });
```

Puis dans Security Rules:

```javascript
match /{document=**} {
  allow read: if request.auth != null && request.auth.uid == "DASHBOARD_USER_UID";
}
```

---

## 📱 Responsive Design

Le dashboard est responsive et s'adapte:
- **Desktop:** Grille 4 colonnes de KPIs
- **Tablet:** Grille 2-3 colonnes
- **Mobile:** KPIs empilés

---

## 🎨 Personnalisation

### Changer les Couleurs

Dans le `<style>`, modifier:

```css
/* Purple accent (par défaut: #B794F6) */
.kpi-value {
    color: #B794F6; /* ← Changer ici */
}

/* Background gradient */
body {
    background: linear-gradient(135deg, #1F0140 0%, #01000C 100%);
}
```

### Ajouter des Métriques

1. Ajouter le calcul dans `fetchFirebaseData()` ou `fetchMockData()`
2. Ajouter le rendu dans `renderOverview()` ou créer une nouvelle section
3. Suivre le pattern des KPI cards existantes

---

## 🐛 Troubleshooting

### Erreur: "Firebase initialization error"

- Vérifier que les credentials Firebase sont corrects
- Vérifier que le projet Firebase existe

### Erreur: "Permission denied"

- Vérifier les Security Rules Firestore
- S'assurer que la lecture est autorisée

### Aucune Donnée Affichée

- Vérifier que vous avez décommenté `fetchFirebaseData()`
- Ouvrir la console du navigateur (F12) pour voir les erreurs
- Vérifier que les collections Firestore existent

### Queries Lentes

- Créer les index suggérés par Firebase
- Limiter le nombre de documents fetché
- Pré-calculer les métriques avec Cloud Functions

### CORS Errors

- Utiliser un serveur local (voir Étape 4, Option B)
- Ou ouvrir le fichier avec `file://` protocol (moins recommandé)

---

## 🚀 Hébergement (Optionnel)

### Option 1: Vercel (Gratuit)

```bash
# Installer Vercel CLI
npm install -g vercel

# Déployer
cd analytics-dashboard
vercel

# URL générée: https://cortifree-analytics.vercel.app
```

### Option 2: Netlify (Gratuit)

1. Créer un compte sur [Netlify](https://www.netlify.com/)
2. Drag & drop le dossier `analytics-dashboard`
3. URL générée automatiquement

### Option 3: GitHub Pages (Gratuit)

```bash
# Créer un repo GitHub
git init
git add .
git commit -m "Initial commit"
git branch -M main
git remote add origin https://github.com/VOTRE_USERNAME/cortifree-analytics.git
git push -u origin main

# Activer GitHub Pages dans Settings > Pages
# URL: https://VOTRE_USERNAME.github.io/cortifree-analytics/
```

**⚠️ Attention:** Si hébergé publiquement, sécuriser l'accès avec Firebase Auth!

---

## 📊 Métriques Expliquées

### KPIs Clés

- **Installations:** Nombre total d'utilisateurs créés (collection `users`)
- **Onboarding Started:** Users ayant démarré l'onboarding (~80% des installs)
- **Onboarding Completed:** Users avec `onboardingCompleted: true`
- **Trial Started:** Users ayant démarré un essai gratuit
- **Active Subscriptions:** Users avec abonnement actif
- **ARPU:** Average Revenue Per User = Revenue Total / Installations
- **ARPPU:** Average Revenue Per Paying User = Revenue Total / Active Subs
- **Conversion Globale:** % de users installant l'app qui deviennent payants

### Benchmarks

- **Install → Onboarding:** ~80% (bon)
- **Onboarding → Completed:** 70-85% (très bon)
- **Trial → Paid:** 40-60% (excellent pour wellness app)
- **Churn J+7:** <30% (acceptable)
- **Activation Rate:** >75% (bon engagement)

---

## 🔄 Mises à Jour

Pour mettre à jour les données:
- **Automatique:** Les données se rechargent à chaque changement de période
- **Manuel:** Recharger la page (⌘R / Ctrl+R)
- **Future:** Implémenter un bouton "Refresh" ou auto-refresh toutes les X minutes

---

## 📞 Support

**Questions ou problèmes?**

1. Vérifier la console du navigateur (F12) pour les erreurs
2. Vérifier les Security Rules Firebase
3. Tester d'abord avec les données mockées
4. Vérifier que les collections Firestore existent

---

## 📝 Licence

Dashboard créé pour CortiFree par Claude Code (2026)

---

## 🎉 C'est Prêt!

Vous avez maintenant un dashboard analytics complet pour piloter CortiFree!

**Next Steps:**
1. Configurer Firebase (5 min)
2. Ouvrir le dashboard
3. Analyser les métriques
4. Optimiser la conversion! 🚀
