# ⚡ Test Rapide Mixpanel - Vérification de connexion

## 🎯 Objectif
Vérifier que Mixpanel reçoit bien les événements de ton app

## ✅ Étapes (2 minutes)

### 1. Lance l'app sur simulateur

```bash
# Ouvre le projet dans Xcode
cd /Users/jos/CortiFree/CortiFree
open CortiFree.xcodeproj

# Puis dans Xcode: CMD + R pour lancer
```

### 2. Vérifie la console Xcode

Tu devrais voir immédiatement:
```
[Mixpanel] ✅ Initialized successfully with EU server
[Mixpanel] 📊 Event: app_opened
```

✅ Si tu vois ces 2 lignes → Mixpanel est bien initialisé !

### 3. Attends 30 secondes - 1 minute

Les événements sont envoyés par batch. Attends un peu que le flush se fasse.

### 4. Va sur le dashboard Mixpanel

1. Ouvre: **https://eu.mixpanel.com/project/3310694**
2. Clique sur **"Events"** dans le menu de gauche
3. Attends 1-2 minutes max
4. Tu devrais voir apparaître: **`app_opened`**

### 5. Si tu ne vois toujours rien après 2 minutes

**Option A - Envoie plus d'événements:**

Dans l'app:
1. Déconnecte-toi (Settings > Déconnexion)
2. Clique sur "Sign Up"
3. L'écran de bienvenue s'affiche → Événement `onboarding_welcome_viewed` envoyé
4. Clique sur "Commencer" → Événement `onboarding_welcome_continue` envoyé

Retourne sur le dashboard, tu devrais voir ces 3 événements:
- ✅ `app_opened`
- ✅ `onboarding_welcome_viewed`
- ✅ `onboarding_welcome_continue`

**Option B - Force le flush manuellement:**

Dans Xcode, ouvre `CortiFreeApp.swift` et dans `AppDelegate.didFinishLaunchingWithOptions`, ajoute après l'initialisation de Mixpanel:

```swift
// Force un événement de test
DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
    MixpanelManager.shared.flush()
}
```

## 🔍 Vérification du token

Ton token actuel: `54821f0aa53aa5ce3804237815f94332`
Serveur: `https://api-eu.mixpanel.com` (EU)

Si tu vois "No data" dans Mixpanel:

1. **Vérifie le token** dans le dashboard:
   - Clique sur l'icône de ton compte (en haut à droite)
   - Project Settings
   - Vérifie que le "Project Token" correspond bien

2. **Vérifie la région** (EU vs US):
   - Dans Project Settings
   - Vérifie "Data Residency" = **EU**

## 🐛 Debug avancé

Si vraiment rien n'apparaît, ajoute plus de logs dans MixpanelManager.swift:

```swift
private func track(event: String, properties: [String: any MixpanelType]? = nil) {
    print("[Mixpanel] 🚀 AVANT track: \(event)")
    Mixpanel.mainInstance().track(event: event, properties: properties)
    print("[Mixpanel] ✅ APRES track: \(event)")

    // Force flush immediately for each event (ONLY FOR TESTING!)
    Mixpanel.mainInstance().flush()
    print("[Mixpanel] 💾 Flush executed")

    #if DEBUG
    if let props = properties, !props.isEmpty {
        print("[Mixpanel] 📊 Event: \(event) | Properties: \(props)")
    } else {
        print("[Mixpanel] 📊 Event: \(event)")
    }
    #endif
}
```

Puis relance l'app et regarde la console.

## ✅ Résultat attendu

Dans la console Xcode:
```
[Mixpanel] ✅ Initialized successfully with EU server
[Mixpanel] 📊 Event: app_opened
```

Dans le dashboard Mixpanel (après 1-2 min):
- Événement `app_opened` visible
- Avec les super properties:
  - `app_version`
  - `os_version`
  - `device_type`
  - `language`
  - `platform` = "iOS"

## 📝 Notes

- Les événements peuvent prendre jusqu'à **2 minutes** pour apparaître
- Le SDK envoie les événements par **batch** (toutes les 60 secondes par défaut)
- L'événement `app_opened` est envoyé **à chaque lancement** de l'app
- Le `flush()` force l'envoi immédiat