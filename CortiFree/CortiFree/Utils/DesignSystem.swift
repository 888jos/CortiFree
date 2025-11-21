//
//  DesignSystem.swift
//  CortiFree
//
//  Design System for unified typography and component styles
//  Created by Claude on 17/11/2025.
//

import SwiftUI

// MARK: - Typography Extensions
extension Font {

    // MARK: - SF Pro Rounded
    struct SFPro {
        static func rounded(_ weight: SFProWeight, size: CGFloat) -> Font {
            return Font.custom(weight.rawValue, size: size)
        }

        enum SFProWeight: String {
            case bold = "SF Pro Rounded-Bold"
            case semibold = "SF Pro Rounded-Semibold"
            case medium = "SF Pro Rounded-Medium"
            case regular = "SF Pro Rounded-Regular"
        }
    }

    // MARK: - Poppins
    struct Poppins {
        static func custom(_ weight: PoppinsWeight, size: CGFloat) -> Font {
            return Font.custom(weight.rawValue, size: size)
        }

        enum PoppinsWeight: String {
            case bold = "Poppins-Bold"
            case semiBold = "Poppins-SemiBold"
            case medium = "Poppins-Medium"
            case regular = "Poppins-Regular"
            case light = "Poppins-Light"
        }
    }

    // MARK: - HankenGrotesk
    struct HankenGrotesk {
        static func custom(_ weight: HankenWeight, size: CGFloat) -> Font {
            return Font.custom(weight.rawValue, size: size)
        }

        enum HankenWeight: String {
            case bold = "HankenGrotesk-Bold"
            case semiBold = "HankenGrotesk-SemiBold"
            case medium = "HankenGrotesk-Medium"
            case regular = "HankenGrotesk-Regular"
        }
    }

    // MARK: - App Typography Scale

    // Titles
    static var appLargeTitle: Font {
        SFPro.rounded(.bold, size: AppConstants.FontSize.largeTitle)
    }

    static var appTitle: Font {
        Poppins.custom(.bold, size: AppConstants.FontSize.title)
    }

    static var appTitle2: Font {
        Poppins.custom(.semiBold, size: AppConstants.FontSize.title2)
    }

    static var appTitle3: Font {
        Poppins.custom(.semiBold, size: AppConstants.FontSize.title3)
    }

    // Body
    static var appBody: Font {
        Poppins.custom(.regular, size: AppConstants.FontSize.body)
    }

    static var appBodyMedium: Font {
        Poppins.custom(.medium, size: AppConstants.FontSize.body)
    }

    static var appBodyLarge: Font {
        Poppins.custom(.regular, size: AppConstants.FontSize.bodyLarge)
    }

    static var appBodySmall: Font {
        Poppins.custom(.regular, size: AppConstants.FontSize.bodySmall)
    }

    // Captions
    static var appCaption: Font {
        Poppins.custom(.regular, size: AppConstants.FontSize.caption)
    }

    static var appCaption2: Font {
        Poppins.custom(.regular, size: AppConstants.FontSize.caption2)
    }

    // Buttons
    static var appButton: Font {
        Poppins.custom(.medium, size: AppConstants.FontSize.button)
    }

    static var appButtonSmall: Font {
        Poppins.custom(.medium, size: AppConstants.FontSize.bodySmall)
    }

    // Special
    static var appCountdown: Font {
        SFPro.rounded(.bold, size: AppConstants.FontSize.countdown)
    }

    static var appLevel: Font {
        Poppins.custom(.bold, size: AppConstants.FontSize.level)
    }
}

// MARK: - ViewModifiers for Common Styles

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: AppConstants.Layout.cornerRadius)
                    .fill(AppConstants.Colors.cardBackground)
            )
            .shadow(color: Color.black.opacity(0.2), radius: AppConstants.Layout.shadowRadius, x: 0, y: 4)
    }
}

struct PrimaryButtonStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.appButton)
            .foregroundColor(.white)
            .frame(height: AppConstants.Layout.buttonHeight)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient.accent
            )
            .clipShape(RoundedRectangle(cornerRadius: AppConstants.Layout.cornerRadiusXLarge))
    }
}

struct SecondaryButtonStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.appButton)
            .foregroundColor(AppConstants.Colors.violet)
            .frame(height: AppConstants.Layout.buttonHeight)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: AppConstants.Layout.cornerRadiusXLarge)
                    .stroke(AppConstants.Colors.violet, lineWidth: 2)
            )
    }
}

// MARK: - View Extensions for Easy Access
extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }

    func primaryButton() -> some View {
        modifier(PrimaryButtonStyle())
    }

    func secondaryButton() -> some View {
        modifier(SecondaryButtonStyle())
    }
}

// MARK: - Shadow Styles
extension View {
    func softShadow() -> some View {
        self.shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
    }

    func hardShadow() -> some View {
        self.shadow(color: Color.black.opacity(0.25), radius: 12, x: 0, y: 6)
    }

    func glowEffect(color: Color = AppConstants.Colors.violet, radius: CGFloat = 16) -> some View {
        self.shadow(color: color.opacity(0.4), radius: radius, x: 0, y: 4)
    }
}

// MARK: - Animation Presets
extension Animation {
    static var appStandard: Animation {
        .easeInOut(duration: AppConstants.Animation.standardDuration)
    }

    static var appProgress: Animation {
        .easeInOut(duration: AppConstants.Animation.progressDuration)
    }

    static var appSpring: Animation {
        .spring(response: 0.4, dampingFraction: 0.8)
    }

    static var appBounce: Animation {
        .spring(response: 0.3, dampingFraction: 0.6)
    }
}

// MARK: - Gradient Presets
extension LinearGradient {
    static var violetGradient: LinearGradient {
        LinearGradient(
            colors: [AppConstants.Colors.violet, AppConstants.Colors.violetLight],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var darkGradient: LinearGradient {
        LinearGradient(
            colors: [
                AppConstants.Colors.taskBackground1,
                AppConstants.Colors.taskBackground2,
                AppConstants.Colors.taskBackground1
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}