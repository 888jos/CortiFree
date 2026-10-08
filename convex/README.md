# Backend Convex de CortiFree

Backend principal de CortiFree. L'app Swift utilise désormais Convex pour
l'authentification, les profils, réglages, habitudes, check-ins, journal, tâches,
progression, stockage de fichiers et assistant. L'ancien runtime Firebase n'est
plus lié à la cible iOS ni déployable depuis ce dépôt.

Le dossier `functions/` ne contient plus de Cloud Function : il conserve seulement
l'exporteur ponctuel des anciennes données, à supprimer une fois la migration de
production terminée et vérifiée.

- Déploiement dev : `dev:reliable-oyster-468` (`https://reliable-oyster-468.convex.cloud`,
  HTTP : `https://reliable-oyster-468.convex.site`) — utilisé par la config **Debug** de l'app.
- Déploiement prod : `prod:compassionate-jackal-621` (`https://compassionate-jackal-621.convex.cloud`,
  HTTP : `https://compassionate-jackal-621.convex.site`) — utilisé par la config **Release**.
  L'URL vient du build setting `CONVEX_URL` (cible CortiFree) via `Info.plist`.
- `npm run convex:codegen` · `npm run typecheck:convex` · `npm run test:convex` (convex-test)
- `npx convex dev --once` pousse vers le dev ; `npx convex deploy` pousse vers la prod.

Variables d'environnement (dev **et** prod) : `JWT_PRIVATE_KEY`, `JWKS`, `SITE_URL`,
`APPLE_BUNDLE_ID`, `GOOGLE_CLIENT_IDS` sont en place (clés JWT distinctes par déploiement).
Restent à définir sur les deux : `DEEPSEEK_API_KEY` (Milo), `RESEND_API_KEY` + `AUTH_EMAIL_FROM`
(email de réinitialisation), `APPLE_TEAM_ID` + `APPLE_KEY_ID` + `APPLE_PRIVATE_KEY`
(révocation Sign in with Apple à la suppression de compte).

---

## 1. Architecture

```
convex/
  auth.ts, auth.config.ts, http.ts   Convex Auth (password, apple-native, google-native) + JWKS
  lib/session.ts                     requireUserId / requireUser, helpers
  lib/appleIdentity.ts               vérification du JWT Apple (jose + JWKS Apple, nonce)
  lib/googleIdentity.ts              vérification de l'ID token Google
  lib/passwordResetEmail.ts          code OTP de réinitialisation (Resend)
  schema.ts                          tables (authTables + tables applicatives + staging)
  profile.ts settings.ts habits.ts checkins.ts journal.ts tasks.ts progress.ts
  achievements.ts plan.ts baseline.ts feedback.ts todos.ts account.ts assistant.ts
  migration/importer.ts              internalMutations d'import (staging)
  migration/transform.ts             transformations Firestore → lignes Convex (pures)
  migration/claim.ts                 rattachement des données legacy à un compte (par lots)
  migration/media.ts                 base64 Firestore → Convex file storage
  migration/import-legacy.cli.mjs    script Node d'import (non déployé : deux points dans le nom)
  backend.test.ts                    tests convex-test (non déployé)
```

Principes :

- **Toute fonction publique** appelle `requireUser(ctx)` (ou `requireUserId` dans les actions),
  basé sur `getAuthUserId(ctx)`. Non authentifié → `ConvexError("Authentication required")`.
  `requireUser` vérifie aussi que la ligne `users` existe encore (un JWT reste valide ≤ 1 h
  après une suppression de compte).
- Chaque table utilisateur a `userId: v.id("users")` et un index commençant par `userId`.
- Les **clés de jour** restent des chaînes `yyyy-MM-dd` calculées sur l'appareil (calendrier
  local), comme les ids de documents Firestore. Les horodatages sont en **millisecondes epoch**
  (Swift : `Date().timeIntervalSince1970 * 1000`).
- Les écritures Firestore `setData(merge:)` deviennent des upserts ; les read-modify-write
  non transactionnels (habit_tracking) sont désormais atomiques côté serveur.
- Les images base64 (photo de profil, photos du journal, captures des bug reports) passent
  dans **Convex File Storage** (upload URL → `storageId`).
- `legacyUsers` / `legacyRecords` / `migrationRuns` ne sont lus par **aucune** fonction
  publique.
- Les catalogues `routines` / `exercises` Firestore ne sont lus que par du code mort : l'app
  utilise `TASKS_DATABASE.json` et les catalogues embarqués. **Pas de `catalog.ts`** ; ces
  collections restent dans `legacyRecords` à titre d'archive.

## 2. Correspondance tables ↔ collections Firestore

| Firestore | Table Convex | Clé naturelle (index) | Notes |
|---|---|---|---|
| Firebase Auth | `users` + `authAccounts`, `authSessions`, `authRefreshTokens`… | `email`, `by_appleSub`, `by_googleSub` | Convex Auth |
| `users/{uid}` | `users` (champs profil) | `by_legacyFirebaseUid` | `profilePhotoBase64` → `avatarStorageId` ; onboarding → `users.onboarding` ; `isPaid` → `users.subscription` |
| `users/{uid}/settings/preferences` | `userSettings` | `by_user` (1 ligne) | les deux schémas (UserSettings + SettingsViewModel) |
| `users/{uid}/habit_tracking/{habitId}` | `habitTracking` | `by_user_habit` | `lastCompletedDate` (clé de jour) ajouté pour le calcul de série |
| `…/habit_tracking/{h}/daily_completion/{date}` | `habitCompletions` | `by_user_habit_date`, `by_user_date` | |
| `users/{uid}/task_statuses/day_{N}` | `taskStatuses` | `by_user_day` | map dynamique → `statuses: [{key, status}]` |
| `users/{uid}/completed_tasks` | `completedTasks` | `by_user_completedAt`, `by_user_day_task` | idempotent par (programDay, taskId) |
| `users/{uid}/exercises_done` | `exerciseSessions` | `by_user_completedAt`, `by_user_localSessionId` | `duration` → `durationSeconds` |
| `users/{uid}/daily_checkins/{date}` | `dailyCheckins` | `by_user_date` | |
| `users/{uid}/daily_moods/{date}` | `dailyMoods` | `by_user_date` | |
| `users/{uid}/journalEntries` | `journalEntries` | `by_user_createdAt` (+ meditationType/Id) | `photoURL` base64 → `photoStorageId` |
| `users/{uid}/achievements/{id}` | `achievements` | `by_user_achievement` | |
| `users/{uid}/habit_badges/{habit}_{level}` | `habitBadges` | `by_user_habit_level` | |
| `users/{uid}/personalized_plan/current` | `personalPlans` | `by_user` (1 ligne) | `planJSON` reste une chaîne opaque |
| `users/{uid}/baseline/initial` | `baselines` | `by_user` (1 ligne) | |
| `users/{uid}/stats/main` | `userStats` | `by_user` (1 ligne) | `history` = record `yyyy-MM-dd → nombre` |
| `users/{uid}/tasks` | `userTasks` | `by_user_createdAt` | liste TaskItem (HomeViewModel) |
| `dailyTodos` (racine, champ `userId`) | `dailyTodos` | `by_user_active` | code mort côté UI, conservé |
| `bug_reports` (racine) | `bugReports` | `by_user`, `by_status` | écriture seule ; lecture via dashboard |
| collections mortes : `routine_progress`(+`daily_progress`), `feedback`, `custom_tasks`, `ai_insights`, `habit_goals`, `dailyPrograms`, `onboarding_responses`, `baseline/collection`, `baseline/validated`, `stats/weekly_summary`, `analytics_events`, `weeklyTargets` | `archivedRecords` | `by_user` | jamais exposé, supprimé avec le compte |
| `routines`, `exercises` (catalogues) | — (restent dans `legacyRecords`) | | inutilisés par l'app |
| — | `emailVerificationCodes` | `by_user` | preuve de propriété de l'email (comptes mot de passe) |
| — | `legacyUsers`, `legacyRecords`, `migrationRuns` | | staging privé de l'import |

## 3. Authentification depuis l'app Swift native (ConvexMobile)

Convex Auth n'a pas de SDK Swift, mais son API est **indépendante du web** : tout passe par
l'action publique `auth:signIn` (et `auth:signOut`). Vérifié dans
`node_modules/@convex-dev/auth/src/server/implementation/index.ts` et `signIn.ts` :
`signIn` renvoie `{ tokens: { token, refreshToken } }` pour les providers credentials, sans
cookie ni redirection ; les cookies ne concernent que l'intégration Next.js.

- `token` : JWT RS256 (durée **1 h**), `iss` = `CONVEX_SITE_URL`, `aud` = `convex`, `sub` =
  `userId|sessionId`. C'est le token à donner au client Convex.
- `refreshToken` : opaque (`refreshTokenId|sessionId`), **à usage unique** (rotation à chaque
  rafraîchissement, fenêtre de réutilisation 10 s ; une réutilisation tardive révoque toute la
  chaîne). Session : 30 jours max d'inactivité / 30 jours au total (variables
  `AUTH_SESSION_INACTIVE_DURATION_MS`, `AUTH_SESSION_TOTAL_DURATION_MS`).
- Stocker `token` + `refreshToken` dans le **Keychain**.

### 3.1 Appels (nom de fonction + payload)

Tous les appels `auth:signIn` se font **sans** token (client non authentifié). Toutes les
erreurs sont levées comme erreurs de fonction Convex.

| Cas | Appel | Retour |
|---|---|---|
| Inscription email | `auth:signIn` `{provider:"password", params:{flow:"signUp", email, password, firstName?}}` | `{tokens:{token, refreshToken}}` |
| Connexion email | `auth:signIn` `{provider:"password", params:{flow:"signIn", email, password}}` | `{tokens}` (erreur `InvalidSecret`/`InvalidAccountId` sinon ; limitation de tentatives intégrée) |
| Mot de passe oublié (1) | `auth:signIn` `{provider:"password", params:{flow:"reset", email}}` | `{tokens:null}` + email avec code à 8 chiffres (15 min) |
| Mot de passe oublié (2) | `auth:signIn` `{provider:"password", params:{flow:"reset-verification", email, code, newPassword}}` | `{tokens}` ; les autres sessions sont révoquées |
| Sign in with Apple | `auth:signIn` `{provider:"apple-native", params:{identityToken, nonce, firstName?}}` | `{tokens}` |
| Google Sign-In | `auth:signIn` `{provider:"google-native", params:{idToken, nonce?, firstName?}}` | `{tokens}` |
| Rafraîchir | `auth:signIn` `{refreshToken}` (sans `provider`) | `{tokens}` (nouveau couple) ou `{tokens:null}` = session expirée → déconnecter |
| Déconnexion | `auth:signOut` `{}` **avec** le token courant | `null` ; puis effacer le Keychain |

Détails :

- **Email** : envoyer l'email en minuscules et sans espaces (le serveur normalise, mais l'étape
  `reset-verification` compare l'email exact du compte). Mot de passe ≥ 8 caractères.
- **Apple** : générer un `rawNonce` aléatoire, mettre `request.nonce = sha256Hex(rawNonce)`
  (déjà fait dans `AuthenticationView.swift`), puis envoyer `identityToken` (UTF-8 de
  `credential.identityToken`) **et le `rawNonce`**. Le serveur vérifie la signature (JWKS
  Apple), `iss = https://appleid.apple.com`, `aud = com.solstys.cortifree` (`APPLE_BUNDLE_ID`),
  l'expiration et le nonce. Le compte est identifié par le `sub` Apple (= l'uid Apple de
  Firebase, ce qui permet de retrouver les anciennes données). Apple ne donne le prénom
  qu'à la première autorisation : le passer dans `firstName`.
- **Google** : `idToken` = `GIDGoogleUser.idToken.tokenString`, audience vérifiée contre
  `GOOGLE_CLIENT_IDS`. (`nonce` optionnel, comparé brut au claim `nonce`.)
- Aucune fusion automatique de comptes par email (Apple / Google / mot de passe restent des
  comptes distincts), pour éviter qu'un compte mot de passe non vérifié capture une identité.

### 3.2 Intégration ConvexMobile (convex-swift)

1. Un `ConvexClient(deploymentUrl:)` « anonyme » sert aux appels `auth:signIn`.
2. Pour les données, utiliser `ConvexClientWithAuth` avec un `AuthProvider` maison dont :
   - `login()` lance l'écran natif (Apple / Google / email) puis appelle `auth:signIn`, stocke
     les tokens au Keychain et renvoie la session ;
   - `loginFromCache()` lit le `refreshToken` du Keychain, appelle `auth:signIn {refreshToken}`
     et renvoie la nouvelle session (ou lève une erreur si `tokens == null`) ;
   - `logout()` appelle `auth:signOut` puis vide le Keychain ;
   - `extractIdToken(from:)` renvoie `token`.
3. **Le JWT expire après 1 h** et le client Swift ne sait pas rafraîchir seul un token
   provenant d'un provider maison : planifier un rafraîchissement (~5 min avant `exp`, et au
   retour au premier plan) via `loginFromCache()`. Un seul rafraîchissement à la fois (le
   refresh token est à usage unique). *À valider en phase 2 contre la version de convex-swift
   utilisée (noms exacts du protocole `AuthProvider`).*
4. Après chaque connexion : `profile:recordLogin`, puis `account:claimLegacyData` (cf. §5).

Les types côté Swift : les arguments sont des dictionnaires `[String: ConvexEncodable?]` ;
les nombres Convex `v.number()` sont des `Double` ; les ids sont des `String`.

## 4. Variables d'environnement

| Variable | Dev (`reliable-oyster-468`) | Prod | Rôle |
|---|---|---|---|
| `JWT_PRIVATE_KEY` | ✅ définie | à générer | clé privée RS256 qui signe les JWT |
| `JWKS` | ✅ définie | à générer (même paire) | clé publique servie sur `/.well-known/jwks.json` |
| `SITE_URL` | ✅ `https://cortifree.app` | idem | requis par Convex Auth pour les flux OTP (pas de redirection utilisée en natif) |
| `APPLE_BUNDLE_ID` | ✅ `com.solstys.cortifree` | idem | audience(s) du token Apple (liste séparée par des virgules) |
| `GOOGLE_CLIENT_IDS` | ✅ client iOS de `GoogleService-Info.plist` | idem | audience(s) des ID tokens Google |
| `RESEND_API_KEY` | ❌ à fournir | à fournir | emails (reset mot de passe, vérification email) |
| `AUTH_EMAIL_FROM` | ❌ optionnel | à fournir | ex. `CortiFree <no-reply@cortifree.app>` (domaine vérifié chez Resend) |
| `APPLE_TEAM_ID`, `APPLE_KEY_ID`, `APPLE_PRIVATE_KEY` | ❌ à fournir | à fournir | révocation du token Apple à la suppression de compte (clé `.p8` « Sign in with Apple ») |
| `DEEPSEEK_API_KEY` | ❌ | ❌ | seulement si `assistant:chat` remplace le Worker Cloudflare actuel |
| `CONVEX_SITE_URL` | automatique | automatique | fourni par Convex |

Générer les clés JWT (méthode recommandée par Convex Auth : `npx @convex-dev/auth`, ou ce
script équivalent) :

```bash
node --input-type=module -e '
import { exportJWK, exportPKCS8, generateKeyPair } from "jose";
const k = await generateKeyPair("RS256", { extractable: true });
const priv = (await exportPKCS8(k.privateKey)).trimEnd().replace(/\n/g, " ");
const jwks = JSON.stringify({ keys: [{ use: "sig", ...(await exportJWK(k.publicKey)) }] });
process.stdout.write(`JWT_PRIVATE_KEY="${priv}"\nJWKS=${jwks}\n`);'
# puis, pour la prod :
npx convex env set --prod JWT_PRIVATE_KEY -- "-----BEGIN PRIVATE KEY----- ... -----END PRIVATE KEY-----"
npx convex env set --prod JWKS -- '{"keys":[...]}'
npx convex env set --prod SITE_URL https://cortifree.app
npx convex env set --prod APPLE_BUNDLE_ID com.solstys.cortifree
npx convex env set --prod GOOGLE_CLIENT_IDS 559047783915-cmbhjkc2ceuitt2p1o3pia84d56l2jvb.apps.googleusercontent.com
npx convex env set --prod RESEND_API_KEY re_...
```

Changer `JWT_PRIVATE_KEY`/`JWKS` invalide tous les JWT en cours (les refresh tokens restent
valides : le client se reconnecte via `loginFromCache`).

## 5. Déploiement prod

```bash
npx convex deploy            # pousse schéma + fonctions vers le déploiement prod du projet
# (en CI : CONVEX_DEPLOY_KEY=<clé prod> npx convex deploy)
```

Puis définir les variables §4 avec `--prod`, et donner l'URL prod
(`https://<prod>.convex.cloud`) à l'app iOS (config de build Release).

## 6. Import des données Firestore et rattachement (« claim »)

1. **Export** (lecture seule, coûteux, écritures gelées) :
   `node functions/scripts/export-firestore-for-convex.js --project <id> --confirm-read-cost --writes-paused`
   → `migration/private/firestore-<ts>/` (`legacyUsers.jsonl`, `legacyRecords.jsonl`,
   `legacyAuthUsers.jsonl`, `manifest.json`).
2. **Import** dans le staging privé (dev d'abord, puis prod), avec une clé de déploiement du
   dashboard (Settings → Deploy keys) :

   ```bash
   CONVEX_URL=https://reliable-oyster-468.convex.cloud CONVEX_DEPLOY_KEY=<clé> \
     npm run convex:import:legacy -- --dir migration/private/firestore-<ts> --run-id 2026-10-import-1
   ```

   Le script lit les comptes Firebase Auth pour associer à chaque `firebaseUid` son email,
   son **Apple sub** (`providerData[apple.com].uid`) et son Google sub, puis appelle par lots
   (100) les internalMutations `migration/importer:importLegacyUsers` et
   `importLegacyRecords` (idempotentes par `firebaseUid` / `firestorePath`). Les documents
   racine (`dailyTodos`, `bug_reports`) sont rattachés via leur champ `userId`.
   Vérification : `migrationRuns` (comptes + digests), `npx convex run
   migration/importer:stagingCounts '{"collection":"daily_checkins"}'`.
3. **Claim** (au premier login Convex de chaque utilisateur) : l'app appelle
   `account:claimLegacyData`. Correspondance par **Apple sub**, **Google sub**, ou **email
   vérifié** (Apple/Google vérifient l'email ; un compte mot de passe doit d'abord faire
   `account:sendEmailVerificationCode` + `account:verifyEmail`, sinon la réponse est
   `{status:"nothing_to_claim", needsEmailVerification:true}`). Le profil legacy remplit les
   champs vides, puis `migration/claim:claimBatch` déplace les documents par lots de 100
   (transformations de `migration/transform.ts`), supprime les lignes de staging, et
   `migration/media:convertLegacyImages` convertit les images base64 en fichiers.
   Règle de conflit : une ligne Convex déjà créée depuis la connexion **gagne** (sauf
   `taskStatuses`, où les clés manquantes sont fusionnées). Suivi :
   `account:legacyClaimStatus` (`state: "running" | "done"`).
4. Les mots de passe Firebase ne sont pas migrés : un utilisateur email crée un compte
   Convex avec le même email (ou fait « mot de passe oublié » si on choisit de pré-créer les
   comptes – décision ouverte), puis vérifie son email pour récupérer ses données.

## 7. Suppression de compte

`account:deleteMyAccount` (action) `{appleAuthorizationCode?}` : révoque le token Apple si un
`authorizationCode` frais est fourni et que les variables Apple sont définies, puis supprime
par lots toutes les lignes de l'utilisateur (19 tables), ses fichiers (avatar, photos,
captures), les restes legacy (`legacyRecords` de son `firebaseUid`, `legacyUsers`), et les
lignes Convex Auth (`authAccounts`, `authVerificationCodes`, `authSessions`,
`authRefreshTokens`) puis `users`. Retour `{deleted:true, appleTokenRevoked}`. Le client
efface ensuite son Keychain (pas besoin d'appeler `auth:signOut`). Les bug reports sont aussi
supprimés (contrairement à Firestore).

## 8. Fonctions à appeler depuis Swift (phase 2)

`Q` = query, `M` = mutation, `A` = action. Toutes exigent un utilisateur connecté sauf
`auth:signIn`.

| Écran / service Swift actuel | Fonctions Convex |
|---|---|
| `AuthenticationView` / `AuthView` / `EmailAuthView` / `AuthModule` / `ResetPasswordView` | `auth:signIn` (A, §3), `auth:signOut` (A) |
| `AuthViewModel` (état + `onboardingCompleted`) | `profile:me` (Q), `profile:recordLogin` (M) `{language?}`, `account:claimLegacyData` (M), `account:legacyClaimStatus` (Q) |
| Vérification email (nouveau, comptes mot de passe) | `account:sendEmailVerificationCode` (A), `account:verifyEmail` (M) `{code}` |
| `OnboardingV2FlowView` / `OptimizedFirebaseService` | `baseline:saveInitial` (M) `{baseline, profile?, onboardingCompleted?}`, `profile:saveOnboarding` (M) `{answers?, completed?, hasBaseline?}` |
| `ProfileViewModel` / `EditProfileView` | `profile:me` (Q), `profile:updateProfile` (M), `profile:generateAvatarUploadUrl` (M) → POST JPEG → `profile:setAvatar` (M) `{storageId}`, `profile:removeAvatar` (M) |
| `RevenueCatManager` | `profile:setSubscriptionStatus` (M) `{isPaid, entitlementId?}` |
| `SettingsViewModel`, `HomeView`, `TasksV2View`, `AvatarProgressCard`, `EditProfileView` (FirebaseManager.save/fetchUserSettings) | `settings:get` (Q), `settings:save` (M, merge) |
| `TasksV2View` (habitudes) | `habits:initializeTracking` (M), `habits:listTracking` (Q), `habits:getTrackingByHabit` (Q), `habits:markCompleted` (M) `{habitId, programDay, date, completedAt?}`, `habits:removeCompletion` (M), `habits:listCompletions` (Q) |
| `TaskStatusService` | `tasks:listStatuses` (Q), `tasks:setStatus` (M) `{programDay, key, status}`, `tasks:clearStatus` (M) |
| `ProgressAnalyticsService.recordTaskCompletion` | `tasks:recordCompletion` (M), `tasks:removeCompletion` (M), `tasks:listCompletions` (Q) |
| `ProgressAnalyticsService` (lectures) | `progress:analyticsSnapshot` (Q) `{since?, sinceDate?}` (un seul aller-retour) |
| `ExerciseSessionRecorder` (breathing_flow, sound_player, audio_session) | `progress:recordExerciseSession` (M) `{exerciseId?, exerciseType, durationSeconds, source, localSessionId}` |
| `AntiStressViewModel` | `profile:recordSituation` (M) `{situation}`, `progress:recordExerciseSession` (M) avec `situation` (met aussi à jour `lastExerciseType`/`totalExercisesCompleted`) |
| `FirebaseService.fetchStats` / `updateDailyProgress` | `progress:getStats` (Q), `progress:updateStats` (M) |
| `HomeViewModel` (`FirebaseService.fetchTasks`) | `tasks:listUserTasks` (Q) (+ `tasks:upsertUserTask`, `tasks:removeUserTask` si réactivé) |
| `DailyCheckInService` | `checkins:submit` (M) `{date, dayStartAt, mood, stress, sleep, energy, note?, journalPrompt?}` — crée aussi l'entrée de journal « daily_checkin » (ne plus l'écrire côté client) ; `checkins:getCheckin`, `checkins:listCheckins`, `checkins:listMoods`, `checkins:setMood` |
| `JournalService` / `JournalHomeView` / `JournalHistoryView` | `journal:list` (Q) `{limit?}` ou `journal:listPage` (Q, pagination), `journal:listByMeditation` (Q), `journal:get` (Q), `journal:generatePhotoUploadUrl` (M), `journal:create` (M), `journal:update` (M), `journal:remove` (M) |
| `AchievementService` | `achievements:list` (Q), `achievements:upsertMany` (M) `{items}` |
| `HabitBadgeService` | `achievements:listBadges` (Q), `achievements:upsertBadges` (M) `{badges}` |
| `PersonalPlanStore` | `plan:getCurrent` (Q), `plan:saveCurrent` (M), `plan:planInputs` (Q) (profil d'onboarding + baseline) |
| `BaselineService` | `baseline:getInitial` (Q), `baseline:saveInitial` (M) |
| `SettingsView` (bug report) | `feedback:generateScreenshotUploadUrl` (M) → POST JPEG → `feedback:submitBugReport` (M) |
| `DailyTodoService` (UI morte) | `todos:listActive` (Q), `todos:create`, `todos:setCompleted`, `todos:rename`, `todos:archive` (M) |
| `AccountDeletionService` | `account:deleteMyAccount` (A) `{appleAuthorizationCode?}` |
| Assistant Milo (`DeepSeekChatService`, Worker Cloudflare aujourd'hui) | optionnel : `assistant:chat` (A) `{messages}` |

Upload de fichier : `POST <uploadUrl>` avec `Content-Type: image/jpeg` et le corps binaire,
réponse `{"storageId": "..."}`. Les URLs de lecture (`avatarUrl`, `photoUrl`) sont renvoyées
par les queries.

## 9. Décisions ouvertes

- Réactiver l'équipe Convex / passer en Pro (bloquant pour tout test réel).
- Comptes email existants : création à la première connexion + vérification email (actuel),
  ou pré-création + « mot de passe oublié » forcé, ou import des hash scrypt Firebase.
- Garder Google Sign-In (implémenté : `google-native`) ou ne garder qu'Apple + email.
- Rendre obligatoire la vérification email à l'inscription (provider `verify` de Convex Auth).
- Miroir d'abonnement : webhook RevenueCat → Convex (fiable) au lieu de l'auto-déclaration.
- Purge du staging (`legacyRecords` non réclamés) après la fenêtre de rollback.
- Migrer l'assistant du Worker Cloudflare vers `assistant:chat`.
