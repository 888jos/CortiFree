//
//  ErrorStateView.swift
//  CortiFree
//
//  Created on 21/01/2026.
//  Reusable error state component with retry functionality
//

import SwiftUI

/// Reusable error state view with icon, message, and retry button
/// Usage: ErrorStateView(message: "Connection lost", onRetry: { fetchData() })
struct ErrorStateView: View {
    let title: String
    let message: String
    let icon: String
    let iconColor: Color
    let onRetry: (() -> Void)?

    private var isFrench: Bool {
        Locale.preferredLanguages.first?.hasPrefix("fr") ?? false
    }

    init(
        title: String? = nil,
        message: String,
        icon: String = "wifi.exclamationmark",
        iconColor: Color = Color(hex: "EC407A"),
        onRetry: (() -> Void)? = nil
    ) {
        self.title = title ?? (Locale.preferredLanguages.first?.hasPrefix("fr") ?? false ? "Oups !" : "Oops!")
        self.message = message
        self.icon = icon
        self.iconColor = iconColor
        self.onRetry = onRetry
    }

    var body: some View {
        VStack(spacing: 24) {
            // Icon
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 100, height: 100)

                Image(systemName: icon)
                    .font(.system(size: 40))
                    .foregroundColor(iconColor)
            }

            // Text
            VStack(spacing: 8) {
                Text(title)
                    .font(.custom("Poppins-Bold", size: 22))
                    .foregroundColor(.white)

                Text(message)
                    .font(.custom("Poppins-Regular", size: 15))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            // Retry button
            if let onRetry = onRetry {
                Button(action: {
                    HapticManager.light()
                    onRetry()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 16, weight: .semibold))

                        Text(isFrench ? "Réessayer" : "Try again")
                            .font(.custom("Poppins-SemiBold", size: 16))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(iconColor)
                    )
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
        .padding(32)
        .onAppear {
            HapticManager.error()
        }
    }
}

// MARK: - Preset Error States
extension ErrorStateView {
    /// Network error state
    static func networkError(onRetry: @escaping () -> Void) -> ErrorStateView {
        let isFr = Locale.preferredLanguages.first?.hasPrefix("fr") ?? false
        return ErrorStateView(
            title: isFr ? "Connexion perdue" : "Connection lost",
            message: isFr ? "Vérifie ta connexion internet et réessaie." : "Check your internet connection and try again.",
            icon: "wifi.exclamationmark",
            iconColor: Color(hex: "EC407A"),
            onRetry: onRetry
        )
    }

    /// Generic error state
    static func genericError(onRetry: @escaping () -> Void) -> ErrorStateView {
        let isFr = Locale.preferredLanguages.first?.hasPrefix("fr") ?? false
        return ErrorStateView(
            title: isFr ? "Une erreur est survenue" : "Something went wrong",
            message: isFr ? "Réessaie dans quelques instants." : "Please try again in a moment.",
            icon: "exclamationmark.triangle.fill",
            iconColor: Color(hex: "FF7043"),
            onRetry: onRetry
        )
    }

    /// Data loading error
    static func loadingError(onRetry: @escaping () -> Void) -> ErrorStateView {
        let isFr = Locale.preferredLanguages.first?.hasPrefix("fr") ?? false
        return ErrorStateView(
            title: isFr ? "Chargement échoué" : "Loading failed",
            message: isFr ? "Impossible de charger les données." : "Unable to load data.",
            icon: "arrow.down.circle.fill",
            iconColor: Color(hex: "5C6BC0"),
            onRetry: onRetry
        )
    }

    /// Auth error state
    static func authError(onRetry: @escaping () -> Void) -> ErrorStateView {
        let isFr = Locale.preferredLanguages.first?.hasPrefix("fr") ?? false
        return ErrorStateView(
            title: isFr ? "Session expirée" : "Session expired",
            message: isFr ? "Reconnecte-toi pour continuer." : "Please sign in again to continue.",
            icon: "person.crop.circle.badge.exclamationmark",
            iconColor: Color(hex: "7E57C2"),
            onRetry: onRetry
        )
    }
}

// MARK: - Inline Error View (smaller, for cards)
struct InlineErrorView: View {
    let message: String
    let onRetry: (() -> Void)?

    private var isFrench: Bool {
        Locale.preferredLanguages.first?.hasPrefix("fr") ?? false
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(Color(hex: "EC407A"))

            Text(message)
                .font(.custom("Poppins-Regular", size: 14))
                .foregroundColor(.white.opacity(0.8))

            Spacer()

            if let onRetry = onRetry {
                Button(action: {
                    HapticManager.light()
                    onRetry()
                }) {
                    Text(isFrench ? "Réessayer" : "Retry")
                        .font(.custom("Poppins-Medium", size: 13))
                        .foregroundColor(Color(hex: "EC407A"))
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: "EC407A").opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(hex: "EC407A").opacity(0.3), lineWidth: 1)
                )
        )
    }
}

#Preview {
    ZStack {
        GalaxyBackgroundView(intensity: 1.0)
            .ignoresSafeArea()

        VStack(spacing: 40) {
            ErrorStateView.networkError {
                print("Retry tapped")
            }

            InlineErrorView(message: "Échec du chargement") {
                print("Retry tapped")
            }
            .padding(.horizontal, 24)
        }
    }
}
