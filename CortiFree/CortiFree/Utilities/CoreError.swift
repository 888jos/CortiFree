//
//  CoreError.swift
//  CortiFree
//
//  Created by Claude on 24/11/2025.
//  Standardized error handling system for the entire app
//

import Foundation

/// Core error types used throughout the application
/// All errors should conform to this enum for consistent handling
enum CoreError: LocalizedError {
    // MARK: - Authentication Errors
    case authenticationFailed(reason: String)
    case userNotFound
    case invalidCredentials
    case sessionExpired
    case emailAlreadyInUse
    case weakPassword

    // MARK: - Network Errors
    case networkUnavailable
    case serverError(code: Int)
    case timeout
    case invalidResponse

    // MARK: - Data Errors
    case dataCorrupted
    case documentNotFound(collection: String, id: String)
    case saveFailed(reason: String)
    case fetchFailed(reason: String)
    case decodingFailed
    case encodingFailed

    // MARK: - Validation Errors
    case invalidInput(field: String, reason: String)
    case missingRequiredField(field: String)
    case invalidFormat(field: String)

    // MARK: - Business Logic Errors
    case operationNotAllowed(reason: String)
    case insufficientPermissions
    case resourceNotAvailable
    case dailyLimitExceeded

    // MARK: - Unknown
    case unknown(Error)

    // MARK: - LocalizedError Implementation

    var errorDescription: String? {
        switch self {
        // Authentication
        case .authenticationFailed(let reason):
            return String(format: NSLocalizedString("error.auth.failed", comment: ""), reason)
        case .userNotFound:
            return NSLocalizedString("error.auth.user_not_found", comment: "")
        case .invalidCredentials:
            return NSLocalizedString("error.auth.invalid_credentials", comment: "")
        case .sessionExpired:
            return NSLocalizedString("error.auth.session_expired", comment: "")
        case .emailAlreadyInUse:
            return NSLocalizedString("error.auth.email_in_use", comment: "")
        case .weakPassword:
            return NSLocalizedString("error.auth.weak_password", comment: "")

        // Network
        case .networkUnavailable:
            return NSLocalizedString("error.network.unavailable", comment: "")
        case .serverError(let code):
            return String(format: NSLocalizedString("error.network.server_error", comment: ""), code)
        case .timeout:
            return NSLocalizedString("error.network.timeout", comment: "")
        case .invalidResponse:
            return NSLocalizedString("error.network.invalid_response", comment: "")

        // Data
        case .dataCorrupted:
            return NSLocalizedString("error.data.corrupted", comment: "")
        case .documentNotFound(let collection, let id):
            return String(format: NSLocalizedString("error.data.document_not_found", comment: ""), collection, id)
        case .saveFailed(let reason):
            return String(format: NSLocalizedString("error.data.save_failed", comment: ""), reason)
        case .fetchFailed(let reason):
            return String(format: NSLocalizedString("error.data.fetch_failed", comment: ""), reason)
        case .decodingFailed:
            return NSLocalizedString("error.data.decoding_failed", comment: "")
        case .encodingFailed:
            return NSLocalizedString("error.data.encoding_failed", comment: "")

        // Validation
        case .invalidInput(let field, let reason):
            return String(format: NSLocalizedString("error.validation.invalid_input", comment: ""), field, reason)
        case .missingRequiredField(let field):
            return String(format: NSLocalizedString("error.validation.missing_field", comment: ""), field)
        case .invalidFormat(let field):
            return String(format: NSLocalizedString("error.validation.invalid_format", comment: ""), field)

        // Business Logic
        case .operationNotAllowed(let reason):
            return String(format: NSLocalizedString("error.business.not_allowed", comment: ""), reason)
        case .insufficientPermissions:
            return NSLocalizedString("error.business.insufficient_permissions", comment: "")
        case .resourceNotAvailable:
            return NSLocalizedString("error.business.resource_unavailable", comment: "")
        case .dailyLimitExceeded:
            return NSLocalizedString("error.business.daily_limit", comment: "")

        // Unknown
        case .unknown(let error):
            return error.localizedDescription
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .networkUnavailable:
            return NSLocalizedString("error.recovery.check_connection", comment: "")
        case .invalidCredentials:
            return NSLocalizedString("error.recovery.check_credentials", comment: "")
        case .sessionExpired:
            return NSLocalizedString("error.recovery.sign_in_again", comment: "")
        case .weakPassword:
            return NSLocalizedString("error.recovery.stronger_password", comment: "")
        case .timeout:
            return NSLocalizedString("error.recovery.try_again", comment: "")
        case .dailyLimitExceeded:
            return NSLocalizedString("error.recovery.try_tomorrow", comment: "")
        default:
            return nil
        }
    }

    var failureReason: String? {
        switch self {
        case .authenticationFailed(let reason),
             .saveFailed(let reason),
             .fetchFailed(let reason),
             .operationNotAllowed(let reason),
             .invalidInput(_, let reason):
            return reason
        default:
            return nil
        }
    }
}

// MARK: - Service-Specific Errors

/// Service-specific error wrapper
enum ServiceError: LocalizedError {
    case firebase(CoreError)
    case mixpanel(CoreError)
    case authentication(CoreError)
    case storage(CoreError)

    var underlyingError: CoreError {
        switch self {
        case .firebase(let error),
             .mixpanel(let error),
             .authentication(let error),
             .storage(let error):
            return error
        }
    }

    var errorDescription: String? {
        underlyingError.errorDescription
    }

    var recoverySuggestion: String? {
        underlyingError.recoverySuggestion
    }
}

// MARK: - Error Transformation Helpers

extension CoreError {
    /// Transform a generic Error into a CoreError
    static func from(_ error: Error) -> CoreError {
        if let coreError = error as? CoreError {
            return coreError
        }

        if let serviceError = error as? ServiceError {
            return serviceError.underlyingError
        }

        // Map common NSError codes
        let nsError = error as NSError
        switch nsError.domain {
        case "NSURLErrorDomain":
            return mapURLError(nsError)
        case "FIRAuthErrorDomain", "FirebaseAuth":
            return mapFirebaseAuthError(nsError)
        case "FIRFirestoreErrorDomain", "FirebaseFirestore":
            return mapFirestoreError(nsError)
        default:
            return .unknown(error)
        }
    }

    private static func mapURLError(_ error: NSError) -> CoreError {
        switch error.code {
        case -1009: // NSURLErrorNotConnectedToInternet
            return .networkUnavailable
        case -1001: // NSURLErrorTimedOut
            return .timeout
        case -1003, -1004: // NSURLErrorCannotFindHost, NSURLErrorCannotConnectToHost
            return .serverError(code: error.code)
        default:
            return .networkUnavailable
        }
    }

    private static func mapFirebaseAuthError(_ error: NSError) -> CoreError {
        switch error.code {
        case 17004: // FIRAuthErrorCodeEmailAlreadyInUse
            return .emailAlreadyInUse
        case 17007: // FIRAuthErrorCodeInvalidEmail
            return .invalidFormat(field: "email")
        case 17008: // FIRAuthErrorCodeUserNotFound
            return .userNotFound
        case 17009: // FIRAuthErrorCodeWrongPassword
            return .invalidCredentials
        case 17011: // FIRAuthErrorCodeWeakPassword
            return .weakPassword
        case 17020: // FIRAuthErrorCodeNetworkError
            return .networkUnavailable
        case 17014: // FIRAuthErrorCodeRequiresRecentLogin
            return .sessionExpired
        default:
            return .authenticationFailed(reason: error.localizedDescription)
        }
    }

    private static func mapFirestoreError(_ error: NSError) -> CoreError {
        switch error.code {
        case 5: // NOT_FOUND
            return .documentNotFound(collection: "unknown", id: "unknown")
        case 7: // PERMISSION_DENIED
            return .insufficientPermissions
        case 14: // UNAVAILABLE
            return .networkUnavailable
        case 4: // DEADLINE_EXCEEDED
            return .timeout
        default:
            return .fetchFailed(reason: error.localizedDescription)
        }
    }
}
