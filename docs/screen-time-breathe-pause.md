# « Respire avant TikTok » sans Raccourcis (API Temps d'écran)

Objectif : plus d'automatisation Raccourcis à créer. L'utilisateur choisit ses apps une fois ; à l'ouverture de TikTok, iOS affiche l'écran « Respire d'abord » de CortiFree. C'est ce que font one sec et Opal.

## 1. L'entitlement Family Controls (à lire avant tout)

- **Clé** : `com.apple.developer.family-controls`. Sans elle, les API Temps d'écran (FamilyControls, ManagedSettings, DeviceActivity) refusent de fonctionner.
- **En développement** : la variante « Development » s'active librement (Xcode → Signing & Capabilities → + Family Controls), mais **uniquement sur un vrai iPhone** : l'autorisation Temps d'écran ne marche pas dans le simulateur.
- **Pour TestFlight et l'App Store** : la variante « Distribution » **se demande à Apple** : <https://developer.apple.com/contact/request/family-controls-distribution>. La demande doit être faite par le titulaire du compte (Account Holder) de l'équipe RSC662VDU8. On y explique l'usage : outil de bien-être numérique **pour soi-même** (autorisation `.individual`), pas de contrôle parental ; aucune donnée d'usage ne quitte l'iPhone.
- **Délais constatés (forums Apple, 2025-2026)** : de 1 jour à plus d'un mois, parfois bloqué sur « Submitted » plusieurs semaines. Si ça traîne : ouvrir un ticket de support technique (DTS) avec le Team ID et les bundle IDs.
- **Par app ou par équipe ?** En 2025, il fallait une approbation **par bundle ID** : l'app + chacune des 3 extensions, donc 4 demandes. Une réponse d'Apple en 2026 indique qu'une approbation couvre désormais toute l'équipe. À vérifier sur le portail une fois l'accord reçu : la capacité doit apparaître pour les 4 identifiants.
- **App Review** : les règles 5.1.1/5.1.2 s'appliquent (pas de collecte des données Temps d'écran, rien envoyé à un serveur). Tant que l'entitlement n'est pas accordé, **rien ne change pour la version actuelle** : `ScreenTimeShield.isEnabled = false` et le parcours Raccourcis reste en place.

## 2. Le parcours

1. Accueil → tuile « Respire avant TikTok » → `ScreenTimePauseSetupView` : « Choisir les apps » → autorisation Temps d'écran (Face ID) → autorisation des notifications → `FamilyActivityPicker`.
2. La sélection (jetons opaques : on ne sait pas quelles apps ont été choisies) est enregistrée dans l'App Group, et le bouclier est posé (`ManagedSettingsStore(named: "breathe")`).
3. L'utilisateur ouvre TikTok → **écran bouclier** (extension Shield Configuration) : « Respire d'abord », bouton « Respirer 30 s », bouton secondaire « Pas maintenant ».
4. « Respirer 30 s » → l'extension Shield Action **ne peut pas ouvrir CortiFree** (Apple ne le permet pas : `ShieldActionResponse` n'a que none / close / defer, et Apple refuse les API privées). Comme one sec, elle envoie une **notification** « Respire avec Milo » et ferme TikTok. Un appui sur la notification ouvre CortiFree sur `BreathePauseView` (la courbe « montagne russe », jamais d'orbe).
5. Fin de la pause : « Non, ça va » laisse le bouclier en place ; « Débloquer 10 min » retire le bouclier (`ScreenTimeShield.startPass`) et l'utilisateur retourne dans TikTok lui-même (on ne peut pas l'ouvrir pour lui, l'app est anonyme).
6. 10 min plus tard, l'extension Device Activity Monitor remet le bouclier. iOS refuse les plages de moins de 15 min : la plage commence 5 min dans le passé pour finir à +10 min (**à vérifier sur appareil**). Si iOS la refuse, l'app remet le bouclier à son prochain retour au premier plan.

Limites à connaître :
- La notification dépend de l'autorisation des notifications, des modes Concentration et du résumé programmé. `interruptionLevel = .timeSensitive` n'a d'effet qu'avec l'entitlement Time Sensitive Notifications (à activer dans Capabilities, sans demande à Apple).
- Le déblocage concerne toutes les apps choisies en même temps, pas seulement celle qui a été ouverte.

## 3. Ce qui est en place dans le code (compile, désactivé)

| Fichier | Rôle |
|---|---|
| `CortiFree/Services/Calm/ScreenTimeShield.swift` | Cœur partagé app + extensions : sélection dans l'App Group, poser ou retirer le bouclier, plage de 10 min, notification. `isEnabled = false`. |
| `CortiFree/Views/Calm/ScreenTimePauseSetupView.swift` | Réglage : autorisations, choix des apps, désactiver, lien vers le guide Raccourcis. |
| `Services/Calm/BreathePause.swift` | `PauseTarget` (`.app(PauseApp)` pour Raccourcis, `.shielded` pour Temps d'écran) ; `finish` lance le déblocage. |
| `Views/Calm/BreathePauseView.swift` | Textes adaptés à `.shielded` (« Débloquer 10 min »). |
| `Services/Recovery/NotificationRouter.swift` | Notification `campaign = breathe_shield` → pause. |
| `Views/Calm/HomeCalmToolsSection.swift` | Ouvre le nouveau réglage si `isEnabled`, sinon le guide Raccourcis. |
| `CortiFreeShieldConfiguration/`, `CortiFreeShieldAction/`, `CortiFreeActivityMonitor/` | Code, Info.plist et entitlements des 3 extensions, **pas encore ajoutés au projet Xcode** (vérifiés avec `swiftc -typecheck`). |

## 4. Le jour où Apple accorde l'entitlement

Dans Xcode, pour chacune des trois cibles (File → New → Target) :

| Modèle Xcode | Nom de la cible | Bundle ID | Dossier |
|---|---|---|---|
| Shield Configuration Extension | CortiFreeShieldConfiguration | `com.solstys.cortifree.ShieldConfiguration` | `CortiFreeShieldConfiguration/` |
| Shield Action Extension | CortiFreeShieldAction | `com.solstys.cortifree.ShieldAction` | `CortiFreeShieldAction/` |
| Device Activity Monitor Extension | CortiFreeActivityMonitor | `com.solstys.cortifree.ActivityMonitor` | `CortiFreeActivityMonitor/` |

1. Remplacer les fichiers générés par ceux du dossier (Info.plist et `.entitlements` compris). Déploiement iOS 18.5.
2. Ajouter `CortiFree/Services/Calm/ScreenTimeShield.swift` aux cibles **ShieldAction** et **ActivityMonitor** (même méthode que `WidgetDataStore.swift` pour le widget).
3. App principale : capacité **Family Controls** (+ App Group `group.com.solstys.cortifree`, déjà présent). Les 3 extensions ont Family Controls + le même App Group.
4. Optionnel : ajouter une image `ShieldIcon` aux assets de l'extension Shield Configuration (l'avatar de Milo).
5. Passer `ScreenTimeShield.isEnabled` à `true`, tester sur iPhone (pas dans le simulateur) : choisir TikTok → l'ouvrir → bouclier → notification → pause → « Débloquer 10 min » → retour du bouclier après 10 min.
6. Traduire les textes du bouclier (`shield.*`, aujourd'hui en anglais par défaut) dans un `Localizable.strings` propre aux extensions.
