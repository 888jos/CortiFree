//
//  Logger.swift
//  CortiFree
//
//  Created on 21/01/2026.
//  Centralized logging service to replace scattered print() statements
//

import Foundation
import os.log

/// Centralized logging service with different log levels
/// Usage: Logger.debug("message"), Logger.info("message"), Logger.error("message")
final class Logger {

    // MARK: - Log Levels
    enum Level: String {
        case debug = "🔍 DEBUG"
        case info = "ℹ️ INFO"
        case warning = "⚠️ WARNING"
        case error = "❌ ERROR"
        case success = "✅ SUCCESS"

        var osLogType: OSLogType {
            switch self {
            case .debug: return .debug
            case .info: return .info
            case .warning: return .default
            case .error: return .error
            case .success: return .info
            }
        }
    }

    // MARK: - Categories
    enum Category: String {
        case general = "General"
        case auth = "Auth"
        case firebase = "Firebase"
        case analytics = "Analytics"
        case subscription = "Subscription"
        case network = "Network"
        case ui = "UI"
        case routine = "Routine"
        case breathing = "Breathing"
        case meditation = "Meditation"
        case task = "Task"
        case journal = "Journal"
        case notification = "Notification"
    }

    // MARK: - Properties
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.cortifree"
    private static var loggers: [Category: os.Logger] = [:]

    /// Enable/disable logging (disable in production for performance)
    static var isEnabled: Bool = {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }()

    /// Show timestamps in console output
    static var showTimestamps: Bool = true

    // MARK: - Private Methods
    private static func osLogger(for category: Category) -> os.Logger {
        if let existing = loggers[category] {
            return existing
        }
        let logger = os.Logger(subsystem: subsystem, category: category.rawValue)
        loggers[category] = logger
        return logger
    }

    private static func log(
        _ message: String,
        level: Level,
        category: Category,
        file: String,
        function: String,
        line: Int
    ) {
        guard isEnabled else { return }

        let fileName = (file as NSString).lastPathComponent
        let timestamp = showTimestamps ? "[\(timeString())] " : ""
        let location = "[\(fileName):\(line)]"
        let formattedMessage = "\(timestamp)\(level.rawValue) [\(category.rawValue)] \(location) \(message)"

        #if DEBUG
        print(formattedMessage)
        #endif

        // Also log to unified logging system
        let osLog = osLogger(for: category)
        osLog.log(level: level.osLogType, "\(formattedMessage)")
    }

    private static func timeString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter.string(from: Date())
    }

    // MARK: - Public API

    /// Debug level - for development troubleshooting
    static func debug(
        _ message: String,
        category: Category = .general,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .debug, category: category, file: file, function: function, line: line)
    }

    /// Info level - for general information
    static func info(
        _ message: String,
        category: Category = .general,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .info, category: category, file: file, function: function, line: line)
    }

    /// Warning level - for potential issues
    static func warning(
        _ message: String,
        category: Category = .general,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .warning, category: category, file: file, function: function, line: line)
    }

    /// Error level - for errors and failures
    static func error(
        _ message: String,
        category: Category = .general,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .error, category: category, file: file, function: function, line: line)
    }

    /// Success level - for successful operations
    static func success(
        _ message: String,
        category: Category = .general,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .success, category: category, file: file, function: function, line: line)
    }

    // MARK: - Convenience Methods

    /// Log Firebase operations
    static func firebase(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        debug(message, category: .firebase, file: file, function: function, line: line)
    }

    /// Log authentication events
    static func auth(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        debug(message, category: .auth, file: file, function: function, line: line)
    }

    /// Log analytics events
    static func analytics(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        debug(message, category: .analytics, file: file, function: function, line: line)
    }

    /// Log subscription events
    static func subscription(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        debug(message, category: .subscription, file: file, function: function, line: line)
    }

    /// Log network operations
    static func network(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        debug(message, category: .network, file: file, function: function, line: line)
    }
}
