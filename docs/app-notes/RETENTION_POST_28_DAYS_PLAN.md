# Plan : rétention après le plan de 28 jours

Objectif : qu'un utilisateur qui termine (ou abandonne) son plan de 28 jours **garde une raison d'ouvrir l'app chaque jour**, renouvelle son abonnement et ne désinstalle pas.

Statut (09/10/2026) : **phases 0, 1 et 2 implémentées dans l'app iOS**, phase 3 non commencée (voir « Ce qui est fait » ci-dessous). Rédigé le 09/10/2026.

### Ce qui est fait

**Phase 0**
- Enchaînement automatique : `PersonalPlanStore.autoContinueIfNeeded()` démarre le cycle suivant dès J29 (même objectif, ou celui choisi au bilan de J28), au lancement, au retour dans l'app et à minuit. La carte de fin n'est plus qu'un secours ; un bandeau « Cycle N commencé · changer d'objectif » s'affiche les 3 premiers jours. Événement `plan_cycle_started {cycle, goal, auto, theme, gentle, acquired_habits}`.
- Bilan des 28 jours (`PlanBilanView`, `PlanBilanCenter`) : une fois par cycle, à J28 ou pendant la 1re semaine du cycle suivant. Test d'anxiété J28 proposé d'abord s'il manque, GAD-7 J1 → J14 → J28, séances, minutes, meilleure série, jours actifs, habitudes les mieux tenues, pratique qui a le plus aidé, carte image partageable, puis intro du cycle suivant. Événements `plan_bilan_viewed`, `plan_bilan_shared`, `plan_bilan_check_offered`, `plan_bilan_next_cycle`.
- Série et validations : rien à changer côté calcul (jours absolus), le cycle suivant fournit des tâches chaque jour.
- Notifications (`PlanReminderScheduler`, abonnés uniquement, identifiants `plan_reminder_*`) : J26, J28 à 19 h 30 (bilan), J29 matin (1re séance du cycle suivant), rappel quotidien qui nomme la séance du jour (remplace le rappel générique du matin).
- En-tête du plan : « Cycle N · Jour X/28 · thème ».

**Phase 1**
- Thèmes de cycle (`PlanCycleTheme`) : Apaiser, Ancrer (séances un peu plus longues, nouvelles respirations en priorité), Autonomie (séance guidée « au choix » un jour sur deux, 2 habitudes max), Entretien (≈ 10 min/jour, thèmes hebdo sommeil / concentration / relations / énergie, sans fin).
- Pas de répétition visible : le contenu du cycle précédent est pénalisé (`PlanPreferences.previousCycleRefIDs`). `PersonalPlanGenerator.priorityRefIDs` permet de mettre en avant de nouvelles séances (§1.4, à remplir quand elles sortent).
- Objectif suivant suggéré au bilan (`PlanCycleReview.suggestion`) : baisse ≥ 25 % → sommeil ou concentration ; < 10 % ou moins de 10 jours actifs → même objectif, plan plus doux.
- Habitudes acquises : ≥ 80 % sur le cycle (et proposées ≥ 8 fois) → badge au bilan, célébration, retirées des cycles suivants (`PlanPreferences.acquiredHabits`).

**Phase 2**
- Rappels intelligents : heure = moyenne de la 1re pratique des 7 derniers jours (sinon l'heure du réglage), série en danger à 20 h si rien n'est fait, résumé du dimanche 19 h, relance J+2 / J+4 / J+7 sans ouverture puis silence. Heures calmes respectées, préférence « Notifications » respectée, rien pour les non-abonnés (la relance d'essai reste à `RecoveryScheduler`). Événement `plan_reminders_scheduled`.
- Milo : carte hebdomadaire dans le Plan (fin de chaque semaine du plan ou dimanche) qui ouvre Milo avec une question de réflexion. Événements `milo_weekly_checkin_opened` / `_dismissed`.
- Widgets : non branchés (fichiers d'une autre session en cours) ; la donnée est disponible via `PersonalPlanStore.shared.plan.cycle` et `dayIndex()`.

Reste à faire : phase 3 ; §1.4 production de contenu ; Milo qui ajuste réellement le plan après le check-in (aujourd'hui il n'ouvre que la conversation) ; le résumé hebdo n'inclut pas encore « stress -x % ».

---

## 1. Ce qui se passe aujourd'hui au 29e jour

Constat dans le code (`TasksV2View.swift`, `PersonalPlan.swift`, `PlanComponents.swift`) :

| Élément | Comportement à J29 et après |
|---|---|
| Onglet Plan | Affiche la carte « Tes 28 jours sont terminés ! » avec 2 boutons : « Nouveau cycle : {objectif} » ou « Choisir un autre objectif ». |
| Les tâches du jour | **Il n'y en a plus.** L'écran reste bloqué sur le jour 28 en lecture seule (`displayedDay` plafonné à 28, `isViewingToday` devient faux) : impossible de valider quoi que ce soit, pas de « prochaine séance ». |
| Si l'utilisateur ne touche pas la carte | Rien ne se passe, indéfiniment. Aucun nouveau cycle n'est lancé automatiquement. |
| Série (streak) | Ne peut plus avancer depuis le plan (rien à valider), donc elle casse au bout d'un jour ou deux. |
| Notifications | Les rappels quotidiens génériques continuent (« 5 min de respiration… »), mais ils mènent vers un plan vide. Aucune notification n'annonce la fin du plan ni ne propose la suite. |
| Accueil / Profil | La carte de progression reste pleine (28/28) ; le profil affiche « Plan terminé, bravo ! ». |
| Bilan | Un test d'anxiété est proposé aux jours 1, 14 et 28 (`AnxietyCheckStore.checkpoints`), mais **aucun écran ne compare J1 et J28** pour montrer le progrès. |
| Bibliothèque | Reste utilisable normalement (séances, respiration, sons). |
| Cycle 2 (si l'utilisateur le lance) | Nouveau plan de 28 jours, même moteur, sessions un peu plus longues (`cycle > 1` décale la progression d'une semaine) et contenu différent grâce à la graine aléatoire. Les exclusions et préférences sont conservées. |

**En résumé : à J29 l'app passe d'un « coach qui te dit quoi faire chaque jour » à une bibliothèque sans direction.** C'est exactement le moment où l'utilisateur décroche.

### Pourquoi c'est critique pour le revenu

- **Abonnés mensuels** (9,99 €) : leur premier renouvellement tombe vers **J30-31, juste après la fin du plan**. Un utilisateur qui voit « terminé » à J28 a toutes les raisons d'annuler à J29.
- **Abonnés annuels** : l'essai (3 ou 7 jours) se termine bien avant J28, mais un utilisateur qui n'ouvre plus l'app à partir du 2e mois demande un remboursement, laisse un avis négatif et ne renouvelle pas à M12. Le Health & Fitness a la plus faible rétention au premier renouvellement de toutes les catégories (≈ 30 %, Adapty 2026, chiffre éditeur).

---

## 2. Principes

1. **Jamais de jour vide.** Il y a toujours quelque chose à faire aujourd'hui, même si l'utilisateur ne fait aucun choix.
2. **Montrer le progrès.** La preuve que « ça marche » (score d'anxiété J1 → J28, minutes pratiquées) est le meilleur argument pour continuer et payer.
3. **La fin d'un cycle est une célébration, pas une fin.** On fête, on fait le bilan, et on enchaîne.
4. **Variété.** Le contenu ne doit pas se répéter visiblement d'un cycle à l'autre.
5. **Mesurer.** Chaque changement est suivi (événements + rétention par cohorte).

---

## 3. Le plan

### Phase 0 : supprimer la falaise de J29 (à faire avant la mise en production)

**0.1 Enchaînement automatique du cycle suivant**
- À J29, si l'utilisateur n'a rien choisi, le cycle 2 démarre automatiquement avec le même objectif (`startNextCycle(goal: nil)`), et il a des tâches dès le matin.
- La carte de fin reste, mais devient un bandeau « Cycle 2 commencé · changer d'objectif » au-dessus des tâches du jour, pas un mur.
- Événement `plan_cycle_started {cycle, goal, auto: true/false}`.

**0.2 Écran « Ton bilan des 28 jours »** (moment fort, plein écran, à l'ouverture le jour 28 ou 29)
- Score d'anxiété J1 → J14 → J28 (les 3 tests existent déjà), en clair : « -32 % de stress ressenti ».
  Si le test J28 n'a pas été fait, le proposer d'abord (30 s).
- Chiffres concrets : séances terminées, minutes de respiration/méditation, meilleure série, habitudes les plus tenues.
- Ce qui a le plus aidé : la catégorie de séances la plus terminée.
- Carte partageable (image) : bouche-à-oreille.
- Puis : « Ton cycle 2 : {thème} » avec 3 lignes sur ce qui change, bouton « Commencer », lien « Changer d'objectif ».
- Événements `plan_bilan_viewed`, `plan_bilan_shared`.

**0.3 Corriger la série et la validation après J28**
- Tant que le cycle suivant n'est pas lancé, les jours ≥ 29 doivent rester validables (ou le cycle 2 doit déjà être en place, cf. 0.1). Aujourd'hui la série casse mécaniquement.

**0.4 Notifications de transition**
- J26 : « Plus que 3 jours dans ton plan. Ton bilan arrive. »
- J28 au soir : « Ton bilan des 28 jours est prêt 🎉 »
- J29 matin : « Ton cycle 2 commence aujourd'hui : {première séance} »
- Les rappels quotidiens existants doivent citer la séance du jour du plan en cours (et non un texte générique).

### Phase 1 : une progression au-delà de 28 jours

**1.1 Des cycles qui ont chacun un sens**

| Cycle | Thème | Ce qui change |
|---|---|---|
| 1 (J1-28) | Apaiser | Plan actuel |
| 2 (J29-56) | Ancrer | Séances un peu plus longues, nouvelles techniques de respiration, 1 habitude « acquise » remplacée par une nouvelle |
| 3 (J57-84) | Autonomie | L'utilisateur choisit davantage (créneaux, types de séances), moins d'items imposés |
| 4+ | Entretien | Plan léger (≈ 10 min/jour), thèmes hebdomadaires tournants (sommeil, focus, relations, énergie…), indéfiniment |

- Le générateur prend déjà un paramètre `cycle` : il faut lui ajouter les thèmes de cycle et le mode « Entretien ».
- Afficher « Cycle 2 · Jour 3/28 » au lieu de « Jour 31 ».

**1.2 Faire évoluer l'objectif**
- Au bilan, proposer l'objectif suivant à partir des résultats : stress en forte baisse → proposer « Sommeil » ou « Concentration » ; peu de progrès → rester sur le même objectif avec un plan plus doux.

**1.3 Habitudes « acquises »**
- Une habitude tenue ≥ 80 % sur 4 semaines devient « acquise » (badge, célébration) et sort du plan pour laisser la place à une nouvelle. C'est le sens de la grille de progression de l'écran habitude.

**1.4 Contenu frais**
- 103 séances guidées ≈ 2 cycles sans répétition visible. Au cycle 3, les répétitions deviennent évidentes.
- Ajouter **4 à 8 nouvelles séances par mois** avec le pipeline de narration existant (`scripts/narration`), mises en avant dans « Nouveautés » et intégrées en priorité dans les plans.
- Le téléchargement à la demande (streaming) permet d'en ajouter sans alourdir l'app.

### Phase 2 : boucles d'engagement quotidiennes

**2.1 Rappels intelligents** (même moteur que la relance d'essai, `RecoveryScheduler`)
- Heure du rappel = heure habituelle de pratique de l'utilisateur (moyenne des 7 derniers jours), pas une heure fixe.
- Série en danger à 20 h seulement si rien n'est fait.
- Résumé hebdomadaire le dimanche soir (« Cette semaine : 5 séances, 42 min, stress -8 % »).
- Relance des inactifs : J+2, J+4, J+7 sans ouverture, avec la séance du jour en accroche ; arrêt après 3 messages.

**2.2 Milo**
- Bilan hebdomadaire conversationnel (« Comment s'est passée ta semaine ? ») qui ajuste le plan.

**2.3 Widgets et Live Activities**
- La séance du jour et la série sur l'écran d'accueil (en cours dans une autre session : à brancher sur le cycle en cours).

### Phase 3 : protéger le revenu

**3.1 Mensuels autour de J28**
- Au bilan, proposer de passer à l'annuel avec une offre (« Garde ton élan : 12 mois pour le prix de 4 »), via un placement Superwall `plan_bilan_upgrade`.

**3.2 Résiliation**
- Questionnaire de sortie (raison de l'annulation) dans Réglages → Gérer l'abonnement, puis offre adaptée (pause, prix réduit, changement d'objectif) via un placement Superwall.
- Les anciens abonnés ont déjà le placement `winback_cancelled_trial` : vérifier qu'il couvre aussi les mensuels expirés.

**3.3 Annuels**
- Bilans à 3 mois et 6 mois, et un « Ton année avec CortiFree » un mois avant le renouvellement, avec rappel transparent de la date de renouvellement (évite les remboursements).

---

## 4. Mesure

Tableau de bord Amplitude :
- Rétention J7 / J30 / J60 / J90 (ouverture de l'app) par cohorte d'installation.
- % d'utilisateurs actifs à J29 qui ont des tâches et en valident au moins une à J29-J35.
- % de cycles 2 lancés (auto vs manuel), % de cycles 2 terminés.
- Renouvellement des mensuels à M1, M2, M3 (RevenueCat) avant/après la phase 0.
- Taux de partage du bilan.

Pour l'enchaînement automatique (0.1), un test A/B est possible : enchaînement automatique contre carte de choix seule, en comparant l'activité J29-J35 et le renouvellement M1.

---

## 5. Ordre de réalisation

| Phase | Contenu | Effort estimé |
|---|---|---|
| 0 | Enchaînement auto du cycle 2, écran bilan, série après J28, notifications de transition | 3-4 j |
| 1 | Thèmes de cycle + mode Entretien, objectif suivant suggéré, habitudes acquises | 4-5 j |
| 1.4 | Nouvelles séances mensuelles (production de contenu) | continu |
| 2 | Rappels intelligents, résumé hebdo, relance des inactifs, Milo hebdo | 3-4 j |
| 3 | Offre d'upgrade au bilan, questionnaire de sortie, bilans annuels | 2-3 j + config Superwall |
