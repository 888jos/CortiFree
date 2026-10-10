# CortiFree — plan de tracking Amplitude

Projet Amplitude en zone **EU**. Tout passe par `AnalyticsManager.track` → `AmplitudeManager` (iOS).
Le dashboard local (`analytics-dashboard/`) lit uniquement l'API Amplitude (et RevenueCat si la clé est là).

## 1. Acquisition et onboarding (déjà en place)
| Événement | Propriétés | Source |
|---|---|---|
| `[Amplitude] Application Installed / Opened` | — | autocapture SDK |
| `onboarding_screen_viewed` | `screen_name`, `step_number`, `total_steps` | chaque écran (funnel canonique) |
| `onboarding_*_viewed / _clicked` | selon l'écran | écrans historiques |
| `onboarding_notifications_permission_requested / _result` | `granted` | demande système pendant le chargement |
| `onboarding_commitment_completed`, `onboarding_completed` | — | fin d'onboarding |

## 2. Monétisation (nouveau — `SuperwallAnalytics.swift`)
Toutes avec `placement`, `paywall_identifier`, `paywall_name`, `experiment_id`, `variant_id` (+ `product_id`, `price`, `currency`, `period` si un produit est en jeu).

| Événement | Quand |
|---|---|
| `paywall_open` / `paywall_close` / `paywall_decline` | paywall Superwall affiché / fermé / refusé |
| `paywall_load_failed` | paywall introuvable ou pas chargé |
| `transaction_start` / `_abandon` / `_fail` / `_timeout` / `_complete` | achat App Store |
| `trial_started` | essai gratuit démarré |
| `subscription_started` + `revenue_amount` (revenu Amplitude) | abonnement payé tout de suite |
| `transaction_restore` | restauration d'achats |
| `paywall_survey_response` | réponse au sondage de sortie Superwall |

État RevenueCat (`RevenueCatManager.trackSubscriptionChanges`) :
`trial_converted`, `trial_expired`, `subscription_expired`, `subscription_auto_renew_off`, `subscription_auto_renew_on`.

**Renouvellements, annulations, remboursements** : invisibles depuis l'app → intégration serveur
RevenueCat → Amplitude (événements `rc_*` avec revenu). À activer dans RevenueCat (voir §6).

## 3. Engagement (déjà en place, complété)
`session_start/end`, `audio_session_started`, `plan_item_opened/completed`, `plan_edited`, `daily_checkin_completed`,
`session_rated`, `breathe_pause_shown/finished`, `calm_check_completed`, `milo_pulse_measured`,
`face_check_completed`, **`face_check_failed`** (nouveau).

Milo (nouveau) : `milo_message_sent` (`source` typed/dictated/suggestion, `length`, `turn`),
`milo_reply_received` (`latency_ms`, `has_card`, `has_plan_proposal`), `milo_error` (`kind`),
`milo_dictation_used` (`language`, `candidates`, `auto_detected`, `server_transcript`, `seconds`).

## 4. Notifications (nouveau — `NotificationAnalytics.swift`)
Funnel par `notification_type` (campagne, sinon identifiant sans numéros : `milestone_streak`, `recovery_b`, `day`…).

| Événement | Quand |
|---|---|
| `notification_scheduled` | nouvelle notification en attente (vu au retour dans l'app) — `hours_until_fire`, `fire_hour`, `repeats` |
| `notification_delivered` | affichée : app fermée (vue dans le centre de notifications au retour), au premier plan, ou ouverte directement — `app_state`, `delivered_hour` |
| `notification_opened` | touchée — `action`, `minutes_after_delivery` (remplace `notification_clicked`) |
| `notification_permission_changed` | statut iOS modifié (`from`, `to`) |

Limite iOS : une notification affichée puis balayée sans ouvrir l'app avant qu'elle disparaisse du centre n'est pas vue.

## 5. Propriétés utilisateur
`is_premium`, `subscription_period_type` (trial/intro/paid/expired/never), `subscription_product`, `subscription_will_renew`,
`notification_permission`, `notifications_pending`, `app_language`, `plan_goal`, `plan_day`, `has_apple_watch`,
`health_connected`, `breathe_pause_configured` (+ existantes : `gender`, `age`, …).

## 6. Actions côté consoles (une fois)
1. **RevenueCat → Integrations → Amplitude** : clé API Amplitude du projet, région EU. Ça envoie les `rc_*`
   (achat initial, renouvellement, annulation, remboursement, conversion d'essai) avec le revenu réel.
2. **Dashboard local** : `analytics-dashboard/.env.local` contient déjà les clés Amplitude ; pour les cartes
   RevenueCat (MRR, abonnés actifs, essais), ajouter `REVENUECAT_SECRET_API_KEY` (clé v2, lecture des métriques)
   et `REVENUECAT_PROJECT_ID`.
