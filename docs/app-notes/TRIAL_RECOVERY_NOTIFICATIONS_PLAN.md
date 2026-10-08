# Plan : relance des utilisateurs qui n'ont pas démarré l'essai gratuit

Objectif unique : **maximiser les démarrages d'essai gratuit** chez deux populations :

- **Segment A** : a quitté l'onboarding **avant** de voir le paywall → objectif : qu'il revienne et **voie le paywall**.
- **Segment B** : a **vu le paywall** sans démarrer l'essai → objectif : qu'il **démarre l'essai**.

Hors périmètre : utilisateurs en essai ou abonnés (rappels quotidiens existants), anciens abonnés (placement Superwall `winback_cancelled_trial` existant).

Statut : rédigé le 08/10/2026. **Phases 0 (côté app) et 1 implémentées le même jour**, avec ces changements par rapport au plan ci-dessous :

- **Plus de messages** : segment A = 10 notifications sur 14 jours (A1 et A2 ont chacun leurs textes), segment B = 11 notifications sur 14 jours.
- **Relance à chaque départ** : une notification 3 min après chaque passage en arrière-plan (3 textes en rotation), annulée si l'utilisateur revient avant.
- **Pas de limite d'une notif par jour** ni de plafond à vie. Restent : heures calmes 21h30-8h (sauf la relance 3 min), 45 min minimum entre deux messages de séquence, holdout 10 %.
- **Offres conditionnées** : les messages d'offre ne partent que si l'utilisateur a accepté les offres (interrupteur sur l'écran de permission) **et** que le produit existe dans l'offering RevenueCat (`cortifree_yearly_trial14`, `cortifree_yearly_discount`).
- **Interrupteur des offres** sur l'écran de permission, pas dans Réglages (les non-payants n'ont pas accès à Réglages).
- **Emails (§7) : gérés par toi via OneSignal**, pas de Convex/Resend.
- Code : `Services/Recovery/RecoveryScheduler.swift` (calendrier exact de chaque message), `NotificationRouter.swift`, tests `CortiFreeTests/RecoveryPlannerTests.swift`.

---

## 1. Ce que disent les données

Légende : **[S]** source solide (gros jeu de données ou Apple), **[V]** chiffre d'éditeur, **[F]** faible.

| Constat | Chiffre | Source |
|---|---|---|
| Les essais se jouent le jour 0 | 82 % des essais Health & Fitness démarrent le jour de l'installation | RevenueCat State of Subscription Apps 2026 [S] |
| Paywall dur > freemium | 10,7 % vs 2,1 % de conversion payante à J35 | RevenueCat 2026 [S] |
| Un essai long convertit mieux | 17-32 j : 42,5 % d'essai → payant ; 5-9 j : 37,4 % ; ≤ 4 j : 25,5 % | RevenueCat 2026 [S] |
| Un essai court est annulé tout de suite | 55 % des essais de 3 jours annulés le jour 0, 40 % pour 7 jours | RevenueCat 2026 [S] |
| Opt-in notifications iOS en Health & Fitness | ≈ 33 % | OneSignal 2024 [V] |
| Promettre un rappel avant la fin de l'essai | Blinkist : opt-in notifs 6 % → 74 %, démarrages d'essai +23 %, plaintes −55 % | Étude de cas Blinkist [V] |
| Offre quand l'utilisateur ferme la feuille de paiement | 6,3 % de conversion sur ces abandons, 17 % du revenu total | Superwall, 18 apps [V] |
| Trop de notifs = désactivation | 37 % désactivent à 2-5 notifs/semaine | Sondage 2018 [F] |
| La nouveauté s'use | Duolingo pénalise la répétition d'un même message ; +2 % de rétention des nouveaux | Duolingo KDD 2020 [S] |

**Conséquences pour CortiFree :**

1. **Le gros du gain est dans la première session**, pas dans les notifications : offre de sortie quand on ferme le paywall, frise de l'essai avec promesse de rappel. Les notifications rattrapent les 18 % restants.
2. **Sans permission, rien n'est possible.** Aujourd'hui la permission est demandée après le 14e écran : tout le segment A antérieur est injoignable. C'est le premier chantier.
3. **L'offre la plus solide est un essai plus long** (14 jours au lieu de 3/7), pas une réduction : ça ne coûte rien et les données le soutiennent le mieux.
4. **Peu de messages, bien placés** : 3 pour A, 4 pour B, 1 par jour maximum.

---

## 2. Point de départ dans le code

| Élément | État actuel | Fichier |
|---|---|---|
| Onboarding | 18 étapes, étape sauvegardée en local (`onboardingCheckpoint`, `last_onboarding_checkpoint`), reprise au relancement | `Views/Onboarding V2/OnboardingV2FlowView.swift:90-221` |
| Ordre réel | welcome → overall → reassurance → habitsQuiz → stressPatternValidation → symptomChecker → cortisolScienceHook → sixtyDayExplanation → scientificPlan → **authentication** → loading → eightHabitsIntro → weekProgress → eightHabits → **notificationPermissions** → habitsProgress → commitmentPledge → **complete (paywall)** | idem `:90-108`, `:490-514` |
| Paywall | Superwall `campaign_trigger`, paywall dur ; `saw_paywall_without_accepting` mis à true à l'affichage | `CustomPaywallView.swift:135-178` |
| Produits | annuel 39,99 € (essai 3 j ou 7 j selon A/B), mensuel 9,99 €, offres de sortie `cortifree_offer_v1/v2` à 29,99 € | `RevenueCatManager.swift:228-250` |
| Notifications | locales uniquement, 3 séries de relance programmées à chaque passage en arrière-plan | `Services/NotificationService.swift:396-578` |
| Toucher une notif | ne fait que tracker `notification_clicked`, n'ouvre rien | `CortiFreeApp.swift:91-109` |
| Deep link | `cortifree://live_gift` ouvre le paywall `live_gift` | `CortiFreeApp.swift:440-483` |
| Live Activity onboarding | progression + « offre limitée 30 min » | `Services/OnboardingLiveActivityManager.swift` |
| Backend | compte Convex créé à l'étape 10 (email quasi toujours connu) ; pas de cron, pas de push, pas d'étape d'onboarding côté serveur | `convex/schema.ts:150-199` |
| Analytics | Amplitude + PostHog + TikTok ; `onboarding_screen_viewed`, `onboarding_paywall_viewed`, `subscription_purchased {is_trial}` | `AnalyticsManager.swift` |

**Bugs existants à corriger :**

1. **Notifs perdues après minuit** : les relances à 1 h, 2 h, 6 h, 12 h utilisent `daysFromNow: 0` + l'heure de (maintenant + X). Si maintenant + X tombe le lendemain, la date est passée et la notif ne part jamais.
2. **Le toucher n'ouvre rien** : l'utilisateur atterrit sur l'écran où il était, sans contexte.
3. **Doublons** : les séries « checkpoint » et « auth » peuvent partir toutes les deux → jusqu'à 6 notifs en 48 h.
4. **Séquence remise à zéro à chaque ouverture** : comme tout est reprogrammé au passage en arrière-plan, quelqu'un qui ouvre l'app chaque jour sans avancer recevra la notif « 1 h » tous les jours.
5. **Textes en dur en anglais** dans la Live Activity.
6. `NotificationService.scheduleTrialNotifications` est vide (`:101`), alors que le paywall promettra un rappel.

---

## 3. Architecture cible

```
            ┌───────────── App (iOS) ─────────────┐
 état local │ RecoveryState (UserDefaults)        │
            │  segment, étape, ancres de dates,   │
            │  messages envoyés, holdout          │
            │            │                        │
            │   RecoveryScheduler.reschedule()    │──► notifications locales (UNUserNotificationCenter)
            │            │                        │
            │   NotificationRouter (toucher)      │──► reprise d'onboarding / paywall Superwall
            └────────────┼────────────────────────┘
                         │ sync (étape, paywall vu, consentement)
            ┌────────────▼──── Convex ────────────┐
            │ users.recovery {...}                │◄── webhook RevenueCat (essai démarré)
            │ cron horaire → emails Resend        │
            └─────────────────────────────────────┘
```

- **Canal principal : notifications locales.** Elles marchent hors ligne, sans serveur, et l'app connaît l'état exact.
- **Canal secondaire : email** (phase 2), pour ceux qui ont refusé les notifs. On a l'email dès l'étape 10.
- **Push serveur (APNs depuis Convex) : optionnel** (phase 3). Utile seulement pour changer les textes sans mise à jour de l'app ou relancer au-delà de J7.

### 3.1 Un seul moteur, déterministe

Remplacer les 3 stratégies par **`RecoveryScheduler`** (nouveau fichier `Services/Recovery/RecoveryScheduler.swift`) :

- `reschedule()` est **idempotent** : il supprime toutes les notifs `recovery_*` en attente, recalcule l'état, reprogramme ce qui reste à envoyer. Appelé au passage en arrière-plan, au lancement, au changement d'étape, à l'affichage et à la fermeture du paywall, au changement de permission.
- Les délais partent d'**ancres fixes**, pas de « maintenant » :
  - `recovery.dropOffAt` : dernier passage en arrière-plan pendant l'onboarding. Mis à jour seulement si l'utilisateur a **avancé** depuis, sinon on garde l'ancre d'origine (corrige le bug 4).
  - `recovery.paywallFirstSeenAt` : premier affichage du paywall, jamais réécrit.
- On mémorise les messages déjà programmés et dont la date est passée (`recovery.sentIDs`) : un message n'est jamais envoyé deux fois.
- Les dates sont calculées avec `UNTimeIntervalNotificationTrigger` ou `UNCalendarNotificationTrigger` sur une date absolue (corrige le bug 1).
- **Arrêt immédiat de tout** (`cancelAll()`) quand : essai démarré ou achat (`RCPurchaseController` + listener `customerInfo`), onboarding terminé, utilisateur dans le holdout, opt-out des relances dans Réglages.

### 3.2 Règles de fréquence

- **1 message par jour maximum**, tous types confondus (relance + Live Activity + email comptent séparément mais on n'envoie pas email et notif le même jour).
- **Heures calmes 21h30 → 8h00** (heure locale) : un envoi qui y tombe est décalé à 8h30, sauf T+1 h qu'on décale à 19h00 la veille si possible, sinon 8h30.
- **Plafond à vie : 7 notifs de relance**, A et B confondus. Passé ce cap, plus rien.
- Si l'utilisateur rouvre l'app avant un message, ce message est annulé et la séquence continue à partir de la nouvelle situation (avancer d'étape fait passer du A au B, etc.).

### 3.3 Holdout pour mesurer le vrai gain

- 10 % des nouveaux utilisateurs, tirés au hasard au premier lancement (`recovery.holdout`), ne reçoivent **aucune** relance (notif ni email). Les écrans de la première session restent identiques pour tout le monde.
- Envoyé en propriété utilisateur Amplitude/PostHog (`recovery_holdout: true/false`).
- Sans ça, impossible de savoir si les essais « après notif » seraient venus de toute façon.

---

## 4. Chantier 0 : la première session (plus gros levier, avant les notifs)

### 4.1 Frise de l'essai + promesse de rappel sur le paywall

À ajouter sur le paywall Superwall (dans l'éditeur Superwall, pas dans le code) :

> **Aujourd'hui** — accès complet à ton plan
> **Jour 5** — on te prévient par notification
> **Jour 7** — début de l'abonnement, annulable à tout moment avant

- Le jour du rappel = durée de l'essai − 2 (essai de 3 jours : rappel J1 ; 7 jours : J5 ; 14 jours : J12).
- **Il faut que la promesse soit vraie** : implémenter `scheduleTrialNotifications` (bug 6) à partir de la date de fin d'essai donnée par RevenueCat (`entitlements["pro"].expirationDate`), envoi à fin − 48 h, 10h00 locale.

### 4.2 Offre de sortie dans la même session

Configurer dans Superwall (les produits `cortifree_offer_v1/v2` existent déjà) :

| Événement Superwall | Paywall montré | Contenu |
|---|---|---|
| `paywall_decline` (l'utilisateur ferme le paywall) | `recovery_exit` | Annuel avec **essai 14 jours** (nouveau produit, voir §8) |
| `transaction_abandon` (ferme la feuille de paiement Apple) | `recovery_exit` | idem |

- Une seule fois par utilisateur (règle d'audience Superwall « n'a jamais vu `recovery_exit` »).
- Après fermeture de l'offre de sortie, l'utilisateur reste sur le paywall dur (comportement actuel inchangé).

### 4.3 Live Activity

- Garder la Live Activity de progression pour le segment A.
- L'« offre limitée 30 min » n'est acceptable que si l'offre **disparaît vraiment** après 30 min (règle 3.1.2 d'Apple). Sinon la remplacer par « Ton plan t'attend ».
- Traduire ses textes (bug 5) dans les 6 langues.
- Elle compte dans le plafond « 1 par jour » : ne pas programmer la notif T+1 h si la Live Activity est encore affichée.

---

## 5. Chantier 1 : obtenir la permission plus tôt

### 5.1 Autorisation provisoire dès le premier écran

- Au premier lancement (`welcome`), appeler `requestAuthorization(options: [.alert, .sound, .badge, .provisional])`. **Aucune popup** : les notifs arrivent discrètement dans le centre de notifications, avec des boutons « Garder » / « Désactiver ».
- Visibilité faible, mais c'est le seul moyen de toucher ceux qui partent dans les 10 premiers écrans.
- Le texte de ces notifs provisoires doit donner envie de les garder (c'est le premier contact) : pas d'offre, juste la progression.

### 5.2 Demande complète avancée et reformulée

- **Déplacer `notificationPermissions` juste après `loading`** (le plan vient d'être généré, moment où la motivation est maximale), au lieu d'après `eightHabits`.
- Écran de pré-demande (déjà existant, `NotificationPermissionsView.swift`) reformulé autour du bénéfice principal, comme Blinkist :
  - « On te prévient **2 jours avant la fin de ton essai**, pour ne jamais être prélevé par surprise »
  - « Un rappel par jour pour ta séance anti-stress, à l'heure que tu choisis »
  - Ligne de consentement (règle 4.5.4 d'Apple) : « Tu recevras aussi, de temps en temps, des rappels et offres CortiFree. Désactivable dans Réglages. »
- Puis la popup système (`requestAuthorization` sans `.provisional` : elle s'affiche aussi pour quelqu'un en provisoire).
- **Si refus** : re-proposer une fois, sous forme d'interrupteur sur le paywall (« Me rappeler avant la fin de l'essai »), qui renvoie vers Réglages iOS.

### 5.3 Réglages

Ajouter dans `SettingsView` un interrupteur **« Rappels et offres »** (`recovery.marketingOptIn`, true par défaut si consentement donné à l'étape 5.2). Obligatoire pour la règle 4.5.4. S'il est désactivé : `RecoveryScheduler.cancelAll()` et plus d'emails marketing.

---

## 6. Les séquences

Variables disponibles pour personnaliser : prénom (`userFirstName`, Sign in with Apple), objectif principal (`PlanProfile.reasonCodes` : sommeil / anxiété / énergie / concentration / mental), durée du stress (`durationCode`), minutes disponibles (`availableMinutes`), heure du premier lancement (`recovery.firstOpenHour`).

Chaque message a **2 variantes de texte** tirées au hasard (A/B, et évite la répétition). Les textes ci-dessous sont en français ; les 6 langues sont à fournir (en, fr, de, es, ja, ko).

### 6.1 Segment A : a quitté avant le paywall

Sous-segments selon l'étape atteinte :

- **A1 — avant `authentication`** (étapes 1-9) : pas de compte, pas d'email, souvent seulement l'autorisation provisoire.
- **A2 — entre `authentication` et `complete`** (étapes 10-17) : compte et email connus, plan déjà généré.

| # | Quand | A1 (début d'onboarding) | A2 (plan généré) | Toucher → |
|---|---|---|---|---|
| A-1 | dropOffAt + 1 h | « Plus que quelques questions et ton plan anti-stress est prêt. » | « {Prénom}, ton plan anti-{objectif} est prêt à 90 %. Il ne manque plus que toi. » | reprise à l'étape exacte |
| A-2 | J+1 à l'heure du premier lancement (bornée 8h30-21h) | « Ton niveau de stress mérite 2 minutes. On reprend où tu t'étais arrêté ? » | « Ton programme de 4 semaines pour {objectif} t'attend. Première séance : {minutes} min. » | reprise à l'étape exacte |
| A-3 | J+3, 19h00 | « 3 habitudes simples baissent le cortisol en quelques semaines. Découvre lesquelles. » | « Ce soir, tu pourrais déjà faire ta première séance pour {objectif}. » | reprise à l'étape exacte |

Puis arrêt. Si l'utilisateur atteint le paywall entre-temps, il bascule dans le segment B.

Pas d'offre en segment A : il n'a pas encore vu le prix, l'objectif est seulement qu'il atteigne le paywall.

### 6.2 Segment B : a vu le paywall, pas d'essai

Ancre : `recovery.paywallFirstSeenAt`.

| # | Quand | Angle | Exemple | Toucher → |
|---|---|---|---|---|
| B-1 | + 1 h | Rassurer, pas d'offre | « Ton essai est gratuit, sans engagement. On te prévient 2 jours avant la fin. » | paywall principal (`campaign_trigger`) |
| B-2 | J+1, 10h00 | **L'offre** : essai plus long | « {Prénom}, on t'offre 14 jours d'essai au lieu de {durée}. Valable 48 h. » | paywall `recovery_offer` (essai 14 j) |
| B-3 | J+3, 19h00 | Valeur, preuve sociale | « Les personnes qui suivent le plan 4 semaines voient leur stress baisser dès la 2e semaine. » (ne citer que des chiffres réels, issus des données de l'app) | paywall `recovery_offer` si encore valable, sinon principal |
| B-4 | J+7, 10h00 | Dernière relance | « Dernier rappel : ton plan pour {objectif} est toujours prêt. Après, on arrête de te solliciter. » | paywall `recovery_last_chance` (annuel −25 % la 1re année, ou essai 14 j) |

Puis arrêt définitif des notifications de relance. L'email prend le relais (§7).

**Règles de l'offre :**

- « Valable 48 h » doit être vrai : le placement `recovery_offer` n'affiche l'essai 14 jours que si `now < paywallFirstSeenAt + J+1 + 48 h`. Après, il montre le paywall principal. Le décompte affiché dans le paywall utilise la vraie date d'expiration.
- Si l'utilisateur a déjà vu l'offre de sortie (§4.2) avec l'essai 14 jours, B-2 met en avant **la réduction annuelle** à la place.
- B-4 : décider entre réduction et essai long avec les résultats de B-2 (A/B dans Superwall).

### 6.3 Récapitulatif temporel

```
Segment A   T0 ──1h── A-1 ──── J+1 A-2 ─────── J+3 A-3 ─ stop
Segment B   T0 ──1h── B-1 ──── J+1 B-2 ─────── J+3 B-3 ─────── J+7 B-4 ─ stop
Email       (refus notifs ou après la fin)      J+2 ─── J+5 ─── J+10 ── J+21
```

---

## 7. Chantier 2 : emails (Convex + Resend)

Pour qui : utilisateurs avec compte (A2 et B) qui **ont refusé les notifs**, plus tout le monde une fois les notifs terminées.

### 7.1 Données côté serveur

Ajouter à `users` dans `convex/schema.ts` :

```ts
recovery: v.optional(v.object({
  onboardingStep: v.string(),          // dernière étape atteinte
  onboardingStepAt: v.number(),
  paywallFirstSeenAt: v.optional(v.number()),
  notificationsAuthorized: v.boolean(),
  marketingOptIn: v.boolean(),         // consentement email + notifs promo
  holdout: v.boolean(),
  emailsSent: v.array(v.string()),     // ids des emails déjà envoyés
  unsubscribedAt: v.optional(v.number()),
})),
trialStartedAt: v.optional(v.number()),
```

- Mutation `recovery:sync` appelée par l'app à chaque changement d'étape (après l'étape 10), à l'affichage du paywall et au changement de permission.
- **Webhook RevenueCat → action HTTP Convex** (`convex/http.ts`) qui met `trialStartedAt` / `subscription.isPaid` à jour. C'est la source fiable côté serveur (l'utilisateur peut démarrer l'essai puis ne jamais rouvrir l'app).

### 7.2 Cron

`convex/crons.ts` : toutes les heures, `recovery:sendDueEmails` :

1. Sélectionne les utilisateurs sans essai ni abonnement, `marketingOptIn`, pas en holdout, pas désabonnés.
2. Calcule l'email dû selon le segment et l'ancre (comme le moteur local), en respectant 1 contact/jour et l'heure locale (fuseau à synchroniser depuis l'app).
3. Envoie via Resend, ajoute l'id à `emailsSent`.

| Email | Quand | Contenu |
|---|---|---|
| E-1 | J+2 | Récap personnalisé du plan (objectif, 4 semaines, première séance) + bouton vers l'app |
| E-2 | J+5 | Contenu utile sans paywall : « 3 techniques de respiration contre le cortisol » (article) |
| E-3 | J+10 | Offre essai 14 jours (lien d'ouverture de l'app vers `recovery_offer`) |
| E-4 | J+21 | Dernier email, puis arrêt |

- Les boutons ouvrent l'app via un **Universal Link** (`https://<domaine>/r/offer` → `cortifree://paywall?placement=recovery_offer`), à configurer (fichier `apple-app-site-association` + entitlement Associated Domains).
- Lien de désabonnement en un clic dans chaque email (mutation `recovery:unsubscribe`).

### 7.3 Consentement email (RGPD)

Les inscrits non payants ne sont pas « clients » : la prospection par email vers des particuliers demande **un consentement** (CNIL). Ajouter à l'étape `authentication` une case non cochée par défaut : « Recevoir des conseils et offres CortiFree par email ». Sans case cochée, seuls les emails transactionnels (compte, essai) partent.

---

## 8. Chantier 3 (optionnel) : push serveur

À faire seulement si on veut modifier les textes ou les délais sans publier une version, ou relancer au-delà de J7.

- Enregistrement APNs (`registerForRemoteNotifications`), jeton envoyé à Convex (`users.pushTokens`).
- Envoi depuis une action Convex (clé APNs .p8 en variable d'environnement).
- Textes dans une table `recoveryMessages` (id, langue, variantes) lue par le cron.

Recommandation : **ne pas le faire tout de suite**. Le local couvre J0-J7, là où se jouent les conversions.

---

## 9. Navigation au toucher

Nouveau `NotificationRouter` (appelé depuis `AppDelegate.userNotificationCenter(didReceive:)`, `CortiFreeApp.swift:91`). Chaque notif porte dans `userInfo` :

```json
{ "deeplink": "cortifree://paywall?placement=recovery_offer",
  "campaign": "recovery", "message_id": "B-2", "variant": "b", "segment": "B" }
```

Liens à gérer (dans le gestionnaire d'URL existant `CortiFreeApp.swift:440`) :

| Lien | Action |
|---|---|
| `cortifree://onboarding/resume` | reprend l'onboarding à la dernière étape (mécanisme `resumeFromCheckpoint` existant) |
| `cortifree://paywall?placement=X` | affiche le placement Superwall X (généralise `live_gift`) |

Le lien doit fonctionner app tuée, en arrière-plan ou au premier plan (mettre l'action en attente tant que l'onboarding n'est pas monté).

---

## 10. Analytics

| Événement | Propriétés |
|---|---|
| `recovery_scheduled` | segment, message_ids, holdout |
| `recovery_notification_presented` | message_id, variant (via `willPresent` si app ouverte) |
| `notification_clicked` (existant, enrichi) | campaign, message_id, variant, segment, hours_since_anchor |
| `recovery_paywall_viewed` | placement, message_id |
| `recovery_email_sent` / `_clicked` (serveur, via PostHog) | email_id, segment |
| `notification_permission_changed` | from, to (provisional/authorized/denied), à chaque lancement |
| `subscription_purchased` (existant) | + `recovery_source` = message_id si un toucher a eu lieu dans les 24 h |

Propriétés utilisateur : `recovery_holdout`, `recovery_segment`, `notification_status`, `marketing_opt_in`.

**Tableau de bord (Amplitude) :**

- Taux de démarrage d'essai à J7 par segment, **groupe relancé vs holdout** (c'est le seul vrai indicateur de gain).
- Taux de clic par message et variante.
- Taux de passage de A au paywall.
- Taux de désactivation des notifs dans les 7 jours (garde-fou : si > 15 %, réduire).
- Taux d'acceptation de la permission (provisoire, puis complète) selon l'emplacement de la demande.

---

## 11. Conformité Apple

- **4.5.4** : pas de notif promotionnelle sans consentement affiché dans l'app + moyen de se désinscrire → ligne de consentement §5.2 + interrupteur §5.3.
- **3.1.2** : durée d'essai et prix clairs avant le démarrage ; aucune fausse urgence → offres réellement limitées dans le temps, décomptes basés sur la vraie expiration.
- Offres pour des utilisateurs **jamais abonnés** : seules les **offres d'introduction** (essai gratuit, prix réduit 1re période) et les **codes d'offre** sont autorisés. Les offres promotionnelles et win-back d'Apple sont réservées aux anciens abonnés. Donc : un **produit séparé** par offre, dans le même groupe d'abonnement, chacun avec son offre d'introduction.

---

## 12. Ce que tu dois faire hors du code

1. **App Store Connect** : créer dans le groupe d'abonnement existant
   - `cortifree_yearly_trial14` : annuel 39,99 €, offre d'introduction **essai gratuit 14 jours** ;
   - `cortifree_yearly_discount` : annuel, offre d'introduction **29,99 € la 1re année** (paiement initial).
2. **RevenueCat** : ajouter ces produits à l'offering, créer le webhook vers l'URL Convex, noter le secret.
3. **Superwall** : créer les placements `recovery_exit`, `recovery_offer`, `recovery_last_chance` avec leurs paywalls ; règles sur `paywall_decline` et `transaction_abandon` ; ajouter la frise d'essai au paywall principal.
4. **Resend** : domaine d'envoi pour les emails marketing (séparé de celui des codes de vérification si possible).
5. **Domaine** : héberger `apple-app-site-association` pour les Universal Links.
6. **Textes** : valider les messages FR ci-dessus, faire traduire les 5 autres langues.

---

## 13. Ordre d'implémentation

| Phase | Contenu | Effort estimé |
|---|---|---|
| **0** | Frise d'essai + offre de sortie Superwall (§4.1-4.2), rappel de fin d'essai réel (`scheduleTrialNotifications`) | 1 j code + config Superwall |
| **1a** | Correctifs : bug minuit, doublons, toucher sans action | 0,5 j |
| **1b** | Permission : provisoire au lancement, demande déplacée et reformulée, interrupteur Réglages (§5) | 1 j |
| **1c** | `RecoveryScheduler` + `NotificationRouter` + séquences A et B + holdout + analytics (§3, §6, §9, §10) ; supprimer les 3 anciennes stratégies et les clés `inline.notificationservice.06`-`23` | 2-3 j |
| **1d** | Textes dans les 6 langues, Live Activity traduite | 0,5 j + traduction |
| **2** | Convex : schéma, sync, webhook RevenueCat, cron, emails Resend, Universal Links, consentement email (§7) | 2-3 j |
| **3** | Push serveur (optionnel, §8) | 2 j |

Après 4 semaines en production : comparer relancés vs holdout. Si le gain est nul sur un message, le retirer ; si un message a plus de 15 % de désactivations, le réécrire ou le supprimer.

---

## 14. Tests

- Tests unitaires de `RecoveryScheduler` avec une horloge injectable : chaque segment, passage A → B, heures calmes, passage de minuit, plafond 1/jour et 7 à vie, essai démarré qui annule tout, holdout.
- Simulateur : `xcrun simctl push` avec un fichier `.apns` contenant le `userInfo` pour tester chaque lien, app tuée / arrière-plan / premier plan.
- Superwall : mode test pour chaque placement ; StoreKit config locale mise à jour avec les 2 nouveaux produits.
- Vérifier sur un vrai iPhone l'autorisation provisoire (le simulateur la gère mal).
