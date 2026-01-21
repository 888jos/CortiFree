//
//  APIConfig.swift
//  CortiFree
//
//  Created on 21/01/2026.
//  Centralized API configuration - reads keys from Info.plist for security
//

import Foundation

/// Centralized API key configuration
/// Keys should be stored in Info.plist and NOT in source code
///
/// To add keys to Info.plist:
/// 1. Open Info.plist
/// 2. Add new rows with keys like "REVENUECAT_API_KEY", "SUPERWALL_API_KEY", etc.
/// 3. Set values in the plist (or use build settings for different environments)
///
/// For production, consider using:
/// - Xcode build configuration files (.xcconfig)
/// - Environment-specific Info.plist values
/// - Secrets management (never commit real keys to git)
final class APIConfig {

    // MARK: - Singleton
    static let shared = APIConfig()
    private init() {}

    // MARK: - Info.plist Keys
    private enum PlistKey: String {
        case revenueCatAPIKey = "REVENUECAT_API_KEY"
        case superwallAPIKey = "SUPERWALL_API_KEY"
        case mixpanelToken = "MIXPANEL_TOKEN"
        case googleClientID = "GIDClientID" // Standard Google Sign-In key
    }

    // MARK: - Private Methods
    private func value(for key: PlistKey) -> String? {
        Bundle.main.object(forInfoDictionaryKey: key.rawValue) as? String
    }

    // MARK: - API Keys

    /// RevenueCat API Key
    /// Add REVENUECAT_API_KEY to Info.plist
    var revenueCatAPIKey: String {
        if let key = value(for: .revenueCatAPIKey), !key.isEmpty, !key.hasPrefix("$(") {
            return key
        }
        // Fallback for development - REMOVE IN PRODUCTION
        #if DEBUG
        Logger.warning("RevenueCat API key not found in Info.plist, using fallback", category: .subscription)
        return "test_VJPakDolvKFgQacRtOHITvapOtT"
        #else
        fatalError("RevenueCat API key must be set in Info.plist for production builds")
        #endif
    }

    /// Superwall API Key
    /// Add SUPERWALL_API_KEY to Info.plist
    var superwallAPIKey: String {
        if let key = value(for: .superwallAPIKey), !key.isEmpty, !key.hasPrefix("$(") {
            return key
        }
        // Fallback for development - REMOVE IN PRODUCTION
        #if DEBUG
        Logger.warning("Superwall API key not found in Info.plist, using fallback", category: .subscription)
        return "pk_JPmmC0H5be4yqTnw24VTm"
        #else
        fatalError("Superwall API key must be set in Info.plist for production builds")
        #endif
    }

    /// Mixpanel Token
    /// Add MIXPANEL_TOKEN to Info.plist
    var mixpanelToken: String? {
        if let token = value(for: .mixpanelToken), !token.isEmpty, !token.hasPrefix("$(") {
            return token
        }
        #if DEBUG
        Logger.warning("Mixpanel token not found in Info.plist", category: .analytics)
        #endif
        return nil
    }

    /// Google Sign-In Client ID
    /// Usually already in Info.plist as GIDClientID
    var googleClientID: String? {
        value(for: .googleClientID)
    }

    // MARK: - Validation

    /// Check if all required API keys are configured
    var isConfigured: Bool {
        let hasRevenueCat = value(for: .revenueCatAPIKey) != nil
        let hasSuperwall = value(for: .superwallAPIKey) != nil
        return hasRevenueCat && hasSuperwall
    }

    /// Log configuration status
    func logConfigurationStatus() {
        Logger.info("API Configuration Status:", category: .general)
        Logger.info("  - RevenueCat: \(value(for: .revenueCatAPIKey) != nil ? "✅" : "⚠️ Using fallback")", category: .subscription)
        Logger.info("  - Superwall: \(value(for: .superwallAPIKey) != nil ? "✅" : "⚠️ Using fallback")", category: .subscription)
        Logger.info("  - Mixpanel: \(value(for: .mixpanelToken) != nil ? "✅" : "❌ Not configured")", category: .analytics)
        Logger.info("  - Google: \(value(for: .googleClientID) != nil ? "✅" : "❌ Not configured")", category: .auth)
    }
}
