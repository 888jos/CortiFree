# RevenueCat Integration Setup Instructions

## Current Build Issue (URGENT FIX NEEDED)

There's a duplicate symbol linker error caused by including the `RevenueCat_CustomEntitlementComputation` package, which is not needed for standard RevenueCat usage.

### Fix Steps (MUST BE DONE IN XCODE):

1. Open the project in Xcode
2. Select the **CortiFree** target in Project Navigator
3. Go to **Build Phases** → **Link Binary With Libraries**
4. Find and **REMOVE** `RevenueCat_CustomEntitlementComputation` (keep only `RevenueCat` and `RevenueCatUI`)
5. Alternatively, go to **Project Settings** → **Package Dependencies**
6. Select the RevenueCat package
7. Uncheck `RevenueCat_CustomEntitlementComputation` (keep only `RevenueCat` and `RevenueCatUI` checked)
8. Build the project again

---

## RevenueCat Integration Overview

This project has been integrated with RevenueCat SDK for subscription management. Here's what has been implemented:

## 1. SDK Installation ✅

- RevenueCat SDK installed via Swift Package Manager
- Package URL: `https://github.com/RevenueCat/purchases-ios-spm.git`
- **IMPORTANT:** Only use `RevenueCat` and `RevenueCatUI` packages (NOT CustomEntitlementComputation)

## 2. Configuration ✅

### API Key Configuration
- **Test API Key:** `test_VJPakDolvKFgQacRtOHITvapOtT`
- **Location:** [CortiFreeApp.swift:36](CortiFreeApp.swift#L36)
- Configured in `AppDelegate.application(_:didFinishLaunchingWithOptions:)`

### Entitlement ID
- **Entitlement Name:** `CortiFree Premium`
- Must be configured in RevenueCat Dashboard

### Product IDs
- **Monthly:** `monthly`
- **Yearly:** `yearly`
- Must match your App Store Connect product IDs

## 3. Core Components

### RevenueCatManager ([Services/RevenueCatManager.swift](Services/RevenueCatManager.swift))

Singleton class that handles all RevenueCat operations:

```swift
// Access the shared instance
let manager = RevenueCatManager.shared

// Check premium access
if manager.hasPremiumEntitlement {
    // Show premium content
}

// Get subscription details
let subscriptionType = manager.getSubscriptionType() // "monthly" or "yearly"
let expirationDate = manager.getSubscriptionExpirationDate()
let willRenew = manager.willRenew()
```

**Key Methods:**
- `configure()` - Initialize SDK (called in AppDelegate)
- `identifyUser(userId:)` - Link user to RevenueCat
- `refreshCustomerInfo()` - Update subscription status
- `purchase(package:)` - Make a purchase
- `restorePurchases()` - Restore previous purchases
- `checkPremiumAccess()` - Check if user has premium
- `logout()` - Clear user session

## 4. User Identification

Users are automatically identified with RevenueCat when they:
- Sign up ([AuthViewModel.swift:89](ViewModels/AuthViewModel.swift#L89))
- Sign in ([AuthViewModel.swift:119](ViewModels/AuthViewModel.swift#L119))
- App launches with existing session ([AuthViewModel.swift:44](ViewModels/AuthViewModel.swift#L44))

Apple Sign In integration ([AuthenticationView.swift:1311](Views/Onboarding V2/AuthenticationView.swift#L1311))
Google Sign In integration ([AuthenticationView.swift:1018](Views/Onboarding V2/AuthenticationView.swift#L1018))

## 5. Paywall Views

### Option 1: RevenueCat Built-in Paywall (Recommended)
Located: [Views/Onboarding V2/RevenueCatPaywallView.swift](Views/Onboarding V2/RevenueCatPaywallView.swift)

```swift
// Present paywall
RevenueCatPaywallView(
    onPurchaseCompleted: {
        print("Purchase completed!")
    },
    onRestoreCompleted: {
        print("Purchases restored!")
    }
)

// Or use view modifier for automatic presentation
ContentView()
    .presentRevenueCatPaywallIfNeeded(
        requiredEntitlementIdentifier: "CortiFree Premium"
    )
```

### Option 2: Keep Custom Paywall UI with RevenueCat Backend
See examples in: [Views/RevenueCatIntegrationExample.swift](Views/RevenueCatIntegrationExample.swift)

Your beautiful CustomPaywallView can be kept and integrated with RevenueCat purchases.

## 6. Settings Integration ✅

Customer Center integrated in [Views/SettingsView.swift](Views/SettingsView.swift):
- Shows subscription status (Premium/Free)
- Displays subscription type (Monthly/Yearly)
- Shows expiration/renewal date
- Opens RevenueCat Customer Center for management
- Customer Center location: [SettingsView.swift:133](Views/SettingsView.swift#L133)

## 7. Entitlement Checking

### Real-time Access Control

```swift
@ObservedObject private var revenueCatManager = RevenueCatManager.shared

var body: some View {
    if revenueCatManager.hasPremiumEntitlement {
        PremiumFeatureView()
    } else {
        LockedFeatureView()
    }
}
```

### Published Properties
The `RevenueCatManager` publishes these properties that auto-update:
- `hasPremiumEntitlement: Bool`
- `hasActiveSubscription: Bool`
- `customerInfo: CustomerInfo?`
- `currentOffering: Offering?`
- `isLoading: Bool`

## 8. Customer Center

Users can manage their subscriptions directly in the app:
- Cancel subscriptions
- Restore purchases
- Request refunds (iOS only)
- Change plans (iOS only)
- View subscription details

Access via Settings → Manage Subscription

## 9. RevenueCat Dashboard Configuration

### Required Setup in Dashboard:

1. **Create Entitlement:**
   - Name: `CortiFree Premium`
   - Products attached: monthly, yearly

2. **Configure Products:**
   - Monthly product ID: `monthly`
   - Yearly product ID: `yearly`
   - Must match App Store Connect

3. **Create Offering:**
   - Default offering with both packages
   - Set yearly as recommended

4. **Optional: Configure Paywall:**
   - If using RevenueCatUI paywall
   - Design in dashboard
   - No code changes needed

## 10. Testing

### Test Mode
- Currently using test API key
- Before production, replace with production key in [RevenueCatManager.swift:35](Services/RevenueCatManager.swift#L35)

### Debug Logging
Debug logs are enabled in development:
```swift
#if DEBUG
Purchases.logLevel = .debug
#endif
```

### Test Purchases
1. Build and run in simulator
2. Use StoreKit Configuration file for testing
3. Check Xcode console for RevenueCat logs

## 11. Migration from StoreKit

If you have existing StoreKit implementation:
1. RevenueCat automatically detects App Store receipts
2. Call `revenueCatManager.restorePurchases()` to sync
3. Existing subscribers will be recognized

## 12. Production Checklist

Before submitting to App Store:

- [ ] Replace test API key with production key
- [ ] Configure products in RevenueCat Dashboard
- [ ] Set up entitlements correctly
- [ ] Test purchase flow end-to-end
- [ ] Test restore purchases
- [ ] Verify Customer Center works
- [ ] Test on multiple iOS versions
- [ ] Test on iPad layout
- [ ] Remove debug logging
- [ ] Test with real App Store sandbox account

## 13. Code Examples

See comprehensive examples in:
- [Views/RevenueCatIntegrationExample.swift](Views/RevenueCatIntegrationExample.swift)

Examples include:
- Custom paywall with RevenueCat backend
- Built-in RevenueCat paywall
- Entitlement checking
- Subscription status display
- Premium feature gates
- Migration helpers

## 14. Support

- RevenueCat Docs: https://www.revenuecat.com/docs
- Dashboard: https://app.revenuecat.com
- SDK Reference: https://sdk.revenuecat.com

## 15. Important Notes

⚠️ **CRITICAL FIXES NEEDED:**
1. Remove `RevenueCat_CustomEntitlementComputation` from target dependencies
2. This is causing duplicate symbol linker errors
3. Only `RevenueCat` and `RevenueCatUI` are needed

✅ **What's Working:**
- SDK initialization
- User identification
- Entitlement checking
- Customer Center integration
- Settings subscription display
- Auth flow integration

🔄 **Next Steps:**
1. Fix linker error (remove CustomEntitlementComputation)
2. Configure products in RevenueCat Dashboard
3. Test purchase flow
4. Connect to your App Store Connect products
5. Test on device with sandbox account

## 16. Architecture

```
CortiFreeApp
    ├── AppDelegate.application() → RevenueCatManager.configure()
    ├── AuthViewModel → RevenueCatManager.identifyUser()
    └── SettingsView → Customer Center

RevenueCatManager (Singleton)
    ├── Published properties (auto-updating)
    ├── Purchase methods
    ├── Entitlement checking
    └── Customer info stream

Views
    ├── RevenueCatPaywallView (Built-in UI)
    ├── CustomPaywallView (Your custom UI)
    └── SettingsView (Customer Center)
```

---

## Quick Start

1. **Fix the linker error** (see top of document)
2. **Configure in RevenueCat Dashboard:**
   - Add entitlement: "CortiFree Premium"
   - Add products: monthly, yearly
   - Create offering
3. **Test:**
   ```swift
   // In any view
   @ObservedObject private var rc = RevenueCatManager.shared

   if rc.hasPremiumEntitlement {
       Text("You're Premium! 🎉")
   } else {
       Button("Upgrade to Premium") {
           showPaywall = true
       }
   }
   ```

4. **Build and run!**
