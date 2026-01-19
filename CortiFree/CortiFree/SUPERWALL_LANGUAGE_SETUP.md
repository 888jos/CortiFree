# Configuration Superwall Multi-langue

## 🎯 Objectif
Le paywall Superwall affiche maintenant la bonne langue selon la langue détectée pendant l'onboarding.

## 🔧 Comment ça marche

### 1. Détection automatique de la langue
L'app détecte automatiquement la langue du système au démarrage de l'onboarding:
- Si le système est en français → `onboardingLanguage = "fr"`
- Sinon → `onboardingLanguage = "en"` (par défaut)

Cette valeur est sauvegardée dans `UserDefaults` avec la clé `"onboardingLanguage"`.

### 2. Placement Superwall dynamique
Quand l'utilisateur arrive au paywall (OnboardingCompletionView), l'app choisit le bon placement:
- Français: `"trigger_fr"`
- Anglais: `"trigger"`

Code:
```swift
let placement = language == "fr" ? "trigger_fr" : "trigger"
Superwall.shared.register(placement: placement)
```

## ⚙️ Configuration dans Superwall Dashboard

### Tu dois créer 2 placements dans ton dashboard Superwall:

#### 1. Placement Anglais: `"trigger"`
- **Nom**: trigger
- **Campagne**: Ta campagne en anglais
- **Product IDs**: `cortifree.yearly.sub`, `cortifree.monthly.sub`
- **Textes**: Tous en anglais

#### 2. Placement Français: `"trigger_fr"`
- **Nom**: trigger_fr
- **Campagne**: Ta campagne en français
- **Product IDs**: `cortifree.yearly.sub`, `cortifree.monthly.sub`
- **Textes**: Tous en français

### Steps pour créer les placements:

1. Va dans ton **Superwall Dashboard**
2. Menu **Placements** → **Create Placement**
3. Pour chaque placement:
   - **Name**: `trigger` (anglais) ou `trigger_fr` (français)
   - **Event**: Choisis l'event qui déclenche le paywall
   - **Campaign**: Assigne la campagne dans la bonne langue
   - **Products**: Configure avec `cortifree.yearly.sub` et `cortifree.monthly.sub`

## 🧪 Test

### Pour tester le français:
1. Change la langue de ton simulateur: Settings → General → Language & Region → French
2. Désinstalle et réinstalle l'app
3. Lance l'onboarding
4. Le paywall devrait être en français

### Pour tester l'anglais:
1. Change la langue de ton simulateur: Settings → General → Language & Region → English
2. Désinstalle et réinstalle l'app
3. Lance l'onboarding
4. Le paywall devrait être en anglais

### Logs de debug:
Dans la console Xcode, tu verras:
```
🌍 Detected onboarding language: fr
🌍 Showing Superwall paywall with placement: trigger_fr (language: fr)
```

## 📝 Notes importantes

1. **Product IDs**: Assure-toi que les Product IDs dans Superwall correspondent exactement à ceux dans App Store Connect:
   - `cortifree.yearly.sub`
   - `cortifree.monthly.sub`

2. **Campagnes**: Tu dois créer 2 campagnes distinctes dans Superwall:
   - Une en anglais (pour placement `trigger`)
   - Une en français (pour placement `trigger_fr`)

3. **Fallback**: Si le placement `trigger_fr` n'existe pas, Superwall ne montrera rien. Tu peux soit:
   - Créer les 2 placements
   - OU modifier le code pour toujours utiliser `trigger` et gérer les langues dans une seule campagne

## 🐛 Troubleshooting

### Le paywall ne s'affiche pas
Vérifie dans les logs Xcode:
- Le placement utilisé: `trigger` ou `trigger_fr`
- Les erreurs Superwall comme `no_rule_match`

### Le paywall est dans la mauvaise langue
Vérifie:
1. La langue détectée dans les logs: `🌍 Detected onboarding language:`
2. Le placement appelé: `🌍 Showing Superwall paywall with placement:`
3. La campagne assignée au placement dans Superwall dashboard

### Reset pour tester à nouveau
Pour forcer une nouvelle détection de langue:
```swift
// Dans le simulateur, exécute:
UserDefaults.standard.removeObject(forKey: "onboardingLanguage")
UserDefaults.standard.removeObject(forKey: "onboardingV2Completed")
```

Puis redémarre l'app.
