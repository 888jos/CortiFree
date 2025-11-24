//
//  ErrorHandler.swift
//  CortiFree
//
//  Created by Claude on 24/11/2025.
//  Centralized error handling and display system
//

import Foundation
import SwiftUI

// MARK: - Displayable Error

/// Error representation suitable for UI display
struct DisplayableError: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let severity: Severity
    let actionButtons: [ErrorAction]

    enum Severity: String {
        case info
        case warning
        case error
        case critical

        var icon: String {
            switch self {
            case .info: return "info.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .error: return "xmark.circle.fill"
            case .critical: return "exclamationmark.octagon.fill"
            }
        }

        var color: Color {
            switch self {
            case .info: return .blue
            case .warning: return .orange
            case .error: return .red
            case .critical: return .purple
            }
        }
    }

    struct ErrorAction {
        let title: String
        let style: ActionStyle
        let action: () -> Void

        enum ActionStyle {
            case `default`
            case cancel
            case destructive
        }
    }

    // MARK: - Initialization

    init(
        title: String,
        message: String,
        severity: Severity = .error,
        actionButtons: [ErrorAction] = []
    ) {
        self.title = title
        self.message = message
        self.severity = severity
        self.actionButtons = actionButtons
    }

    init(from error: Error, context: String? = nil) {
        let coreError = CoreError.from(error)

        self.title = NSLocalizedString("error.title.generic", comment: "")
        self.message = coreError.errorDescription ?? error.localizedDescription
        self.severity = Self.determineSeverity(for: coreError)
        self.actionButtons = Self.determineActions(for: coreError, context: context)
    }

    // MARK: - Helpers

    private static func determineSeverity(for error: CoreError) -> Severity {
        switch error {
        case .networkUnavailable, .timeout:
            return .warning
        case .sessionExpired, .authenticationFailed, .insufficientPermissions:
            return .critical
        case .userNotFound, .documentNotFound:
            return .error
        case .invalidInput, .missingRequiredField, .invalidFormat:
            return .info
        default:
            return .error
        }
    }

    private static func determineActions(for error: CoreError, context: String?) -> [ErrorAction] {
        var actions: [ErrorAction] = []

        switch error {
        case .networkUnavailable, .timeout:
            actions.append(ErrorAction(
                title: NSLocalizedString("error.action.retry", comment: ""),
                style: .default,
                action: {
                    // Retry will be handled by the calling context
                    NotificationCenter.default.post(
                        name: NSNotification.Name("RetryLastOperation"),
                        object: context
                    )
                }
            ))

        case .sessionExpired:
            actions.append(ErrorAction(
                title: NSLocalizedString("error.action.sign_in", comment: ""),
                style: .default,
                action: {
                    NotificationCenter.default.post(
                        name: NSNotification.Name("NavigateToLogin"),
                        object: nil
                    )
                }
            ))

        default:
            break
        }

        return actions
    }
}

// MARK: - Error Handler

/// Centralized error handler for the entire app
@MainActor
class ErrorHandler: ObservableObject {
    static let shared = ErrorHandler()

    @Published var currentError: DisplayableError?
    @Published var showError = false

    private init() {}

    // MARK: - Public Methods

    /// Handle an error and prepare it for display
    /// - Parameters:
    ///   - error: The error to handle
    ///   - context: Optional context string for debugging
    ///   - showToUser: Whether to show this error to the user (default: true)
    func handle(_ error: Error, context: String? = nil, showToUser: Bool = true) {
        let displayable = DisplayableError(from: error, context: context)

        // Log to console in debug
        #if DEBUG
        print("❌ Error [\(context ?? "unknown")]: \(error)")
        if let coreError = error as? CoreError {
            if let recovery = coreError.recoverySuggestion {
                print("💡 Recovery: \(recovery)")
            }
        }
        #endif

        // Track in analytics
        trackError(error, context: context, severity: displayable.severity)

        // Show to user if requested
        if showToUser {
            currentError = displayable
            showError = true
        }
    }

    /// Handle a CoreError directly
    func handle(_ error: CoreError, context: String? = nil, showToUser: Bool = true) {
        handle(error as Error, context: context, showToUser: showToUser)
    }

    /// Dismiss the current error
    func dismiss() {
        withAnimation {
            showError = false
        }

        // Delay clearing to allow dismiss animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.currentError = nil
        }
    }

    /// Show a custom error message
    func showCustomError(
        title: String,
        message: String,
        severity: DisplayableError.Severity = .error,
        actions: [DisplayableError.ErrorAction] = []
    ) {
        let error = DisplayableError(
            title: title,
            message: message,
            severity: severity,
            actionButtons: actions
        )
        currentError = error
        showError = true
    }

    // MARK: - Private Methods

    private func trackError(_ error: Error, context: String?, severity: DisplayableError.Severity) {
        // Track error in Mixpanel
        let errorDescription = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        let errorType = String(describing: type(of: error))

        MixpanelManager.shared.trackError(
            errorType: errorType,
            errorMessage: errorDescription,
            screen: context ?? "unknown",
            userAction: nil
        )
    }
}

// MARK: - Convenience Extensions

extension View {
    /// Add error handling capability to any view
    func withErrorHandling() -> some View {
        modifier(ErrorHandlingModifier())
    }
}

private struct ErrorHandlingModifier: ViewModifier {
    @ObservedObject private var errorHandler = ErrorHandler.shared

    func body(content: Content) -> some View {
        content
            .alert(
                errorHandler.currentError?.title ?? NSLocalizedString("error.title.generic", comment: ""),
                isPresented: $errorHandler.showError,
                presenting: errorHandler.currentError
            ) { error in
                // Action buttons
                ForEach(error.actionButtons.indices, id: \.self) { index in
                    let button = error.actionButtons[index]
                    Button(button.title, role: buttonRole(for: button.style)) {
                        button.action()
                        errorHandler.dismiss()
                    }
                }

                // Default dismiss button
                Button(NSLocalizedString("common.dismiss", comment: ""), role: .cancel) {
                    errorHandler.dismiss()
                }
            } message: { error in
                Text(error.message)
            }
    }

    private func buttonRole(for style: DisplayableError.ErrorAction.ActionStyle) -> ButtonRole? {
        switch style {
        case .cancel: return .cancel
        case .destructive: return .destructive
        case .default: return nil
        }
    }
}
