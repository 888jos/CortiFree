# Guide d'écriture des méditations CortiFree

Ce guide s'applique à tous les scripts du catalogue (`catalog_plan.json`). Le français est la langue source. Les autres langues sont des adaptations, pas des traductions mot à mot.

## 1. Ton et voix

- **Tutoiement, toujours.** On parle à une seule personne : « tu », jamais « vous » ni « on » pour désigner l'auditeur.
- **Chaleureux, simple, concret.** Des phrases courtes (8 à 15 mots en moyenne), un vocabulaire de tous les jours. Pas de jargon spirituel (« énergie », « chakras », « vibrations »), pas de jargon psy non expliqué.
- **Invitation, pas injonction.** « Tu peux laisser tes épaules descendre » plutôt que « Relâche tes épaules ! ». Il est possible de proposer une option : « si c'est confortable », « si tu en as envie ».
- **Zéro performance.** On ne « réussit » pas une méditation. Normalise systématiquement la distraction, l'agitation et la somnolence.
- **Inclusif sans lourdeur.** Préfère les tournures neutres (« quand tu te sens prêt » → « quand c'est le bon moment pour toi »). Le point médian (·) est réservé aux titres. Dans le script parlé, il ne se prononce pas.
- **Ancré dans la vraie vie.** Des images concrètes et françaises (le métro, la machine à café, le dimanche soir), pas des clichés « plage de Bali ».

## 2. Structure obligatoire

Chaque script suit cinq temps. Les proportions sont indicatives, pour une session standard.

| Temps | Part | Contenu |
|---|---|---|
| **1. Arrivée** | ~10 % | Accueil, valider la raison de la venue, posture, 2-3 respirations pour arriver. |
| **2. Ancrage** | ~15 % | Un point d'appui stable (souffle, appuis, sons, objet). |
| **3. Technique centrale** | ~55 % | Le cœur de la session, dans l'ordre des beats de l'`outline`. |
| **4. Intégration** | ~10 % | Repos dans l'effet, remarquer ce qui a changé, sans l'exiger. |
| **5. Retour** | ~10 % | Retour progressif (corps, sons, yeux), plus une phrase « à emporter » dans la journée. |

Exceptions :

- **Sommeil** (tout le thème `sleep`, ainsi que le yoga nidra du soir) : **pas de retour**. La voix ralentit, les phrases raccourcissent, puis tout se fond dans le silence. N'écris jamais « ouvre les yeux » dans ces scripts.
- **Histoires du soir** : une introduction de 30 à 60 s (« installe-toi, tu n'as pas besoin de suivre toute l'histoire »), puis le récit. Le récit n'a ni tension, ni rebondissement, ni dialogue conflictuel. Il devient de plus en plus descriptif et lent dans le dernier tiers.
- **SOS (1 à 4 min)** : arrivée en une ou deux phrases maximum. On entre tout de suite dans la technique.
- **Le stress décodé** : environ un tiers d'explication vulgarisée au début, puis deux tiers de pratique qui illustre l'idée.

## 3. Règle de longueur (non négociable)

- Débit de référence : **150 mots prononcés par minute**.
- `target_words = round(150 × target_minutes × speech_ratio)`. La valeur est déjà calculée dans `catalog_plan.json`.
  - `speech_ratio` = **0,9** par défaut (environ 10 % de pauses de respiration),
  - **0,8** pour le sommeil, le yoga nidra et les body scans (plus de silence),
  - **1,0** pour les histoires du soir.
- **Tolérance : ±10 %** sur `target_words`. On compte les mots prononcés, sans les marqueurs `[pause Ns]`.
- Exemple : une session de 10 min standard fait 1 350 mots (1 215 à 1 485). Une session de sommeil de 20 min fait 2 400 mots.
- Le temps se remplit avec du **contenu guidé**, pas avec du remplissage. Si tu manques de matière, développe les beats : plus de détails sensoriels, des relances variées pour revenir au souffle, de courtes explications. Ne répète pas la même phrase.

## 4. Marqueurs de pause `[pause Ns]`

- Format exact, seul sur sa ligne : `[pause 4s]`.
- **Courts : 2 à 8 s.** Exceptionnellement 10 à 12 s, au maximum deux fois par script.
- **Rares :** en moyenne un marqueur toutes les 3 à 5 phrases. Le rythme vient d'abord de la ponctuation et des phrases courtes.
- Ils servent à placer une respiration guidée (« inspire… » `[pause 4s]` « expire… » `[pause 6s]`) ou à laisser une consigne se poser.
- **Ne pas** créer de longs silences pour « faire durer ». La durée vient des mots (voir § 3). Le moteur audio ajuste déjà légèrement les pauses pour coller à la durée cible.
- Pour une consigne du type « reste quelques instants avec ça », écris la phrase puis une pause de 6 à 8 s. Ensuite, relance.

## 5. Pas d'allégations médicales

- CortiFree n'est **pas un dispositif médical**. Interdit : « guérir », « soigner », « traiter », « faire baisser ton cortisol de X % », « remplace un traitement », et tout diagnostic.
- Autorisé, avec des formules prudentes : « peut aider à », « de nombreuses personnes ressentent », « des études suggèrent que… », « aide ton corps à passer en mode récupération ».
- Pour le contenu scientifique (thème « Le stress décodé »), vulgarise sans simplifier à tort. **Chaque affirmation scientifique doit être notée en commentaire, avec sa source, pour la relecture.**
- Les sessions sur l'épuisement, la tristesse, la panique et le sommeil contiennent une phrase sobre qui invite à **consulter un professionnel de santé** si la difficulté dure ou revient souvent. Une seule phrase, en fin de session, sans dramatiser.

## 6. Sécurité : respiration, panique, corps

- **Respiration :** pas de rétention prolongée (plus de 4 s), pas d'hyperventilation. Propose toujours de revenir au souffle naturel « si tu ressens un vertige ou un inconfort ».
- **Panique et anxiété aiguë :** on ne demande **jamais** de fermer les yeux, de retenir son souffle ou d'aller « au cœur de la sensation » de façon intense. Les yeux restent ouverts, on s'appuie sur les pieds et les mains, et on allonge l'expiration sans forcer l'inspiration. Valide : « c'est très désagréable, et ça va passer ».
- **Émotions difficiles :** demande de choisir une situation « moyennement difficile, pas la pire ». N'aborde pas un traumatisme de façon explicite.
- **Mouvement :** « jamais de douleur, reste dans le confortable ». Propose une alternative assise.
- **Contexte :** les sessions trajet ou marche disent clairement **pas au volant** et rappellent de garder l'attention aux traversées.
- **Sommeil :** pas de contenu qui active (pas de suspense, pas d'injonction à agir).

## 7. Adapter du français vers l'anglais (et les autres langues)

- **Adapte le sens, pas les mots.** Ce qui compte, c'est l'effet sur l'auditeur.
- Le « tu » français devient le « you » anglais naturel. En allemand, utilise « du ». En espagnol, « tú ». En japonais, un registre poli et doux (です/ます, sans excès de keigo). En coréen, un 해요체 chaleureux.
- L'anglais est **plus court et plus direct**. Une phrase française de 15 mots donne souvent 11 à 12 mots en anglais. Recalcule toujours `target_words` à 150 wpm, puis complète avec du contenu si besoin.
- Remplace les références culturelles quand elles ne parlent pas : « métro » → « train / subway », « boulot » → « work ». Garde les histoires (Bretagne, Provence) telles quelles : elles font partie de l'identité de la marque.
- Évite les calques : « Laisse-toi aller » → « Let yourself settle » (et non « Let yourself go »). « Prends soin de toi » → « Be gentle with yourself ». « Bienveillance » → « kindness » (pas « benevolence »).
- Pour les langues sans script dédié, les titres et sous-titres du plan sont déjà adaptés. La narration de/es/ja/ko se fera dans un second temps.

## 8. Format de livraison

- Ajoute le script dans `narration_fr.json` en gardant la structure existante : `id`, `targetMinutes`, `title`, `script` (tableau de lignes).
- **Une ligne = une à trois phrases** qui se prononcent d'un seul souffle. Les marqueurs de pause sont sur leur propre ligne.
- L'`id` doit correspondre **exactement** à celui du plan. N'en invente pas d'autre.

## 9. Checklist d'auto-vérification (à cocher avant de livrer)

- [ ] L'`id`, la durée et la technique correspondent au plan.
- [ ] Le nombre de mots prononcés est dans **±10 %** de `target_words`. Je l'ai compté avec un outil, pas estimé.
- [ ] Les cinq temps sont présents (ou l'exception sommeil / histoire / SOS est respectée).
- [ ] Tous les beats de l'`outline` sont traités, dans l'ordre.
- [ ] Le tutoiement est utilisé partout. Les phrases sont courtes. Il n'y a pas de jargon.
- [ ] Les pauses sont au format `[pause Ns]` : 2 à 8 s, rares, jamais plus de deux pauses de 10 à 12 s.
- [ ] Aucune allégation médicale. Les formulations scientifiques sont prudentes et sourcées en commentaire.
- [ ] La phrase « consulter un professionnel » est présente si le sujet l'exige (épuisement, tristesse, panique, insomnie).
- [ ] Sécurité respiratoire : pas de rétention longue, retour au souffle naturel proposé.
- [ ] Panique : les yeux restent ouverts, pas de rétention, la vague est validée.
- [ ] Sommeil : pas de retour à l'éveil, la fin se fond dans le silence.
- [ ] Aucune phrase n'est répétée en boucle pour remplir. Chaque relance est formulée différemment.
- [ ] La session ne fait pas doublon avec une autre du catalogue (relire le `purpose` des voisines).
- [ ] J'ai lu le script à voix haute avec un chronomètre et il sonne naturel.
- [ ] La version anglaise est une adaptation naturelle (relue par un anglophone si possible), et son nombre de mots est aussi recalculé.
