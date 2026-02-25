//
//  Font+Custom.swift
//  CortiFree
//
//  Custom font extension with fallback support
//

import SwiftUI

extension Font {
    // Custom font with automatic fallback to system fonts
    static func customFont(_ name: String, size: CGFloat) -> Font {
        // Map Poppins to system fonts with matching weights
        switch name {
        case "Poppins-Bold":
            return Font.system(size: size, weight: .bold)
        case "Poppins-SemiBold":
            return Font.system(size: size, weight: .semibold)
        case "Poppins-Medium":
            return Font.system(size: size, weight: .medium)
        case "Poppins-Regular":
            return Font.system(size: size, weight: .regular)
        default:
            return Font.system(size: size, weight: .regular)
        }
    }

    // Convenience methods for common fonts
    static func poppinsRegular(_ size: CGFloat) -> Font {
        return Font.system(size: size, weight: .regular)
    }

    static func poppinsMedium(_ size: CGFloat) -> Font {
        return Font.system(size: size, weight: .medium)
    }

    static func poppinsSemiBold(_ size: CGFloat) -> Font {
        return Font.system(size: size, weight: .semibold)
    }

    static func poppinsBold(_ size: CGFloat) -> Font {
        return Font.system(size: size, weight: .bold)
    }

    // Faro — used for titles and numbers
    static func faroRegular(_ size: CGFloat) -> Font {
        return Font.custom("Faro-RegularLucky", size: size)
    }

    static func faroSemiBold(_ size: CGFloat) -> Font {
        return Font.custom("Faro-SemiBoldLucky", size: size)
    }

    static func faroBold(_ size: CGFloat) -> Font {
        return Font.custom("Faro-BoldLucky", size: size)
    }
}

// View modifier for custom fonts
extension View {
    func customFont(_ name: String, size: CGFloat) -> some View {
        self.font(.customFont(name, size: size))
    }
}