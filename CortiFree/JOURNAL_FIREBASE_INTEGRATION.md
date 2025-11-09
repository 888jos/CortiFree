# Intégration Firebase pour les Entrées de Journal

## Vue d'ensemble

Toutes les entrées de journal (gratitude, clarity, reflection, goals, general) sont maintenant sauvegardées automatiquement sur Firebase. Le système existait déjà mais a été amélioré pour sauvegarder **tous les champs** du modèle JournalEntry.

## Ce qui a été fait

### 1. Mise à jour de JournalService.swift

Le service Firebase a été amélioré pour sauvegarder tous les champs de `JournalEntry`:

**Champs sauvegardés**:
- ✅ `meditationId` - ID de la méditation/activité
- ✅ `meditationType` - Type de journal (gratitude, clarity, reflection, goals, general)
- ✅ `prompt` - La question/prompt associé
- ✅ `content` - Le contenu écrit par l'utilisateur
- ✅ `createdAt` - Date de création
- ✅ `userId` - ID de l'utilisateur
- ✅ `mood` - Humeur sélectionnée (si applicable)
- ✅ `tags` - Tags personnalisés (si applicable)
- ✅ `isFavorite` - Marqué comme favori
- ✅ `wordCount` - Nombre de mots

### 2. Règles Firestore mises à jour

Les règles Firestore ont été mises à jour pour inclure la sous-collection `journalEntries` dans `users/{userId}`:

```firestore
match /users/{userId} {
  allow read, write: if isOwner(userId);

  // Sous-collection: journalEntries
  match /journalEntries/{entryId} {
    allow read, write, delete: if isOwner(userId);
    allow create: if isSignedIn() && request.auth.uid == userId;
  }
}
```

## Structure Firebase

Les entrées de journal sont stockées dans:
```
users/{userId}/journalEntries/{entryId}
```

Cette structure permet:
- 🔒 Isolation des données par utilisateur
- 🚀 Requêtes rapides pour un utilisateur spécifique
- 🔐 Sécurité renforcée avec les règles Firestore
- 📊 Organisation claire des données

## Fonctionnalités

### Sauvegarde automatique
Lorsque l'utilisateur clique sur "Sauvegarder":
1. Le contenu est validé (non vide)
2. Le mood est inclus (si sélectionné)
3. Le nombre de mots est calculé automatiquement
4. L'entrée est sauvegardée sur Firebase
5. Message de succès affiché
6. L'utilisateur gagne de l'XP

### Chargement des entrées
Les entrées peuvent être chargées:
- Par meditationId (toutes les entrées d'une activité spécifique)
- Par type (toutes les entrées de gratitude, clarity, etc.)
- Toutes les entrées de l'utilisateur
- Triées par date (plus récent en premier)

### Suppression
Les utilisateurs peuvent supprimer leurs entrées avec confirmation.

## Mood Selector Conditionnel

Le sélecteur de mood s'affiche seulement pour certains types de journal:

**Affiche le mood**:
- ✅ gratitude
- ✅ clarity
- ✅ reflection
- ✅ general

**N'affiche pas le mood**:
- ❌ goals
- ❌ todo

## Types de Journal

| Type | Nom | Description |
|------|-----|-------------|
| gratitude | Gratitude | Écrire ce pour quoi on est reconnaissant |
| clarity | Clarté | Clarifier ses pensées et gérer le stress |
| reflection | Réflexion | Réfléchir sur sa journée et ses apprentissages |
| goals | Objectifs | Définir et planifier ses objectifs |
| general | Journal | Journal libre |

## Configuration Firebase (À faire)

**IMPORTANT**: Pour que tout fonctionne, tu dois mettre à jour les règles Firestore dans la console Firebase:

1. Va sur [Firebase Console](https://console.firebase.google.com)
2. Sélectionne le projet CortiFree
3. Va dans "Firestore Database"
4. Clique sur l'onglet "Règles" (Rules)
5. Copie les règles depuis [FIRESTORE_RULES.txt](./FIRESTORE_RULES.txt)
6. Clique sur "Publier" (Publish)

## Fichiers modifiés

### Services/JournalService.swift
- ✅ Ajout de tous les champs dans `saveEntry()`
- ✅ Support pour mood (optionnel)
- ✅ Support pour tags (optionnel)
- ✅ Support pour isFavorite et wordCount

### FIRESTORE_RULES.txt
- ✅ Ajout des règles pour `users/{userId}/journalEntries/{entryId}`

## Tests

Pour tester que tout fonctionne:

1. ✅ **Lance l'app** et connecte-toi
2. ✅ **Crée une entrée de gratitude** avec un mood
3. ✅ **Vérifie dans Firebase Console** que l'entrée est sauvegardée avec tous les champs
4. ✅ **Ferme et relance l'app** pour vérifier que les entrées sont chargées
5. ✅ **Supprime une entrée** pour vérifier que ça fonctionne

## Sécurité

- 🔒 Seuls les utilisateurs authentifiés peuvent créer des entrées
- 🔒 Les utilisateurs ne peuvent accéder qu'à leurs propres entrées
- 🔒 Impossible de lire ou modifier les entrées d'autres utilisateurs
- 🔒 Les règles Firestore sont appliquées côté serveur

## XP et Progression

Créer une entrée de journal donne de l'XP à l'utilisateur:
```swift
ProgressionManager.shared.addXP(.dailyMissionComplete)
```

## Prochaines améliorations possibles

- 📊 Statistiques d'écriture (nombre d'entrées par jour/semaine)
- 🏷️ Système de tags personnalisés
- ⭐ Marquer les entrées comme favorites
- 🔍 Recherche dans les entrées
- 📅 Vue calendrier des entrées
- 📈 Graphique de mood sur le temps
- 💾 Export des entrées (PDF, TXT)
