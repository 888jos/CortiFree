# DEBUG - Problème Firebase

## Ce que j'ai corrigé dans le code:

### 1. DailyTodoViewModel.swift
**Problème**: Le `userId` pouvait être une chaîne vide `""` si l'utilisateur n'était pas connecté.

**Solution**:
- Changé `userId` de `String` à `String?` (optionnel)
- Ajouté des `guard let userId = userId` dans toutes les méthodes
- Si pas connecté, affiche maintenant: "Vous devez être connecté pour créer des to-dos"

### 2. DailyTodosView.swift
**Ajout**: Message d'erreur visible en haut de la vue pour voir exactement ce qui bloque

## Comment tester maintenant:

### Étape 1: Vérifie que tu es connecté
1. Lance l'app
2. Va dans l'onglet **Profil** (icône personne en bas)
3. En haut, tu dois voir ton email
4. Si tu ne vois pas d'email, **tu n'es pas connecté!**

### Étape 2: Si tu n'es pas connecté
L'app devrait normalement te montrer l'écran de connexion au démarrage. Si ce n'est pas le cas:
1. Ferme complètement l'app
2. Redémarre l'app
3. Tu devrais voir l'écran "CortiFree" avec les boutons:
   - "Créer un compte"
   - "Se connecter"

### Étape 3: Crée un compte ou connecte-toi
1. Si tu n'as pas de compte, clique "Créer un compte"
   - Email: ton.email@example.com
   - Mot de passe: au moins 6 caractères
   - Nom d'utilisateur: ce que tu veux
2. Si tu as déjà un compte, clique "Se connecter"

### Étape 4: Teste les to-dos
1. Une fois connecté, va dans l'onglet **Journal**
2. Clique sur l'onglet **To-Do**
3. Essaie d'ajouter une tâche

**Si tu vois un message d'erreur orange en haut**, lis-le attentivement:
- "Vous devez être connecté..." → retourne à l'étape 1
- "Missing or insufficient permissions" → les règles Firestore ne sont pas bonnes
- Autre erreur → dis-moi le message exact

## Vérification des règles Firestore

Si tu as encore l'erreur "Missing or insufficient permissions", vérifie dans Firebase Console:

### URL directe:
https://console.firebase.google.com/project/_/firestore/rules

### Tes règles doivent ressembler exactement à ça:
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Helper function
    function isSignedIn() {
      return request.auth != null;
    }

    // DailyTodos collection
    match /dailyTodos/{todoId} {
      allow read, write: if isSignedIn() && resource.data.userId == request.auth.uid;
      allow create: if isSignedIn() && request.resource.data.userId == request.auth.uid;
    }

    // Autres collections...
  }
}
```

### Points importants:
1. `isSignedIn()` vérifie que `request.auth` n'est pas null
2. Pour CREATE: on vérifie `request.resource.data.userId` (les données qu'on VEUT créer)
3. Pour READ/WRITE: on vérifie `resource.data.userId` (les données qui EXISTENT)
4. Les deux doivent correspondre à `request.auth.uid`

## Si ça ne marche toujours pas

Envoie-moi:
1. Le message d'erreur exact que tu vois dans l'app (capture d'écran si possible)
2. Es-tu connecté? (vérifie dans Profil)
3. Les règles Firestore actuelles dans ta console (copie-colle)

Je pourrai alors voir exactement ce qui bloque!
