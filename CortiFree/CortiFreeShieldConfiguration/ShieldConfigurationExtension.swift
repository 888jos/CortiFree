//
//  ShieldConfigurationExtension.swift
//  CortiFreeShieldConfiguration
//
//  The screen iOS shows over TikTok (or any app picked in CortiFree) instead of the app:
//  « Breathe first » + a button that sends the user to the 30-second pause.
//  This extension may only return a configuration: no network, no writes to the App Group.
//

import ManagedSettings
import ManagedSettingsUI
import UIKit

final class ShieldConfigurationExtension: ShieldConfigurationDataSource {
    override func configuration(shielding application: Application) -> ShieldConfiguration {
        breathe(appName: application.localizedDisplayName)
    }

    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        breathe(appName: application.localizedDisplayName)
    }

    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        breathe(appName: webDomain.domain)
    }

    override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration {
        breathe(appName: webDomain.domain)
    }

    private func breathe(appName: String?) -> ShieldConfiguration {
        let accent = UIColor(red: 0.55, green: 0.80, blue: 0.95, alpha: 1)
        let title = String(localized: "shield.title", defaultValue: "Breathe first")
        let subtitle = appName.map {
            String(format: String(localized: "shield.subtitle.app", defaultValue: "30 seconds of breathing with Milo, then %@ opens for 10 minutes."), $0)
        } ?? String(localized: "shield.subtitle", defaultValue: "30 seconds of breathing with Milo, then the app opens for 10 minutes.")
        return ShieldConfiguration(
            backgroundBlurStyle: .systemUltraThinMaterialDark,
            backgroundColor: UIColor(red: 0.04, green: 0.05, blue: 0.12, alpha: 1),
            icon: UIImage(named: "ShieldIcon"),
            title: .init(text: title, color: .white),
            subtitle: .init(text: subtitle, color: UIColor.white.withAlphaComponent(0.75)),
            primaryButtonLabel: .init(text: String(localized: "shield.breathe", defaultValue: "Breathe 30 s"), color: .black),
            primaryButtonBackgroundColor: accent,
            secondaryButtonLabel: .init(text: String(localized: "shield.not_now", defaultValue: "Not now"), color: .white)
        )
    }
}
