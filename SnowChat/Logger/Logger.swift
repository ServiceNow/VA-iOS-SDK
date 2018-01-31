//
//  Logger.swift
//  SnowChat
//
//  Logging facility for SnowChat
//
//  - use `Logger.default' for basic logging, or create a new logger for specific needs using
//    'let logger = Logger.logger(for: "AMB")` to greate a logger specific to a functional area or category of usage.
//    Note that the named logger is retained, so you can access the same instance by name repeatedly and do not have
//    to manage the logger instance yourself
//  - loggers are configured indepently, and all use the underlying Apple Unified Logging APIs
//  - loggers can be disabled, and are disabled by default in non-DEBUG builds
//
//  Created by Marc Attinasi on 11/20/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import Foundation
import os.log

class Logger {
    
    static var loggers = [String: Logger]()

    static let `default` = Logger.logger(for: "default")
    
    static func logger(for name: String) -> Logger {
        let logger = loggers[name]
        if logger == nil {
            setLogger(withName: name, logger: Logger(forCategory: name))
        }
        // swiftlint:disable:next force_unwrapping
        return loggers[name]!
    }
    
    enum LogLevel {
        case info
        case debug
        case error
        case fatal
    }
    
    var logLevel: LogLevel
    let osLogger: OSLog
    let domain = "com.servicenow.SnowChat"
    let category: String
    
    #if DEBUG
        let enabled: Bool = true
    #else
        let enabled: Bool = false
    #endif
    
    init(forCategory: String, level: LogLevel = .info) {
        category = forCategory
        logLevel = level
        osLogger = OSLog(subsystem: domain, category: forCategory)
    }

    func log(_ message: String, level: LogLevel) {
        if enabled && shouldLog(level: level) {
            let type: OSLogType
            switch level {
            case .debug:
                type = .debug
            case .info:
                type = .info
            case .error:
                type = .error
            case .fatal:
                type = .fault
            }
            let formatString: StaticString = "%@"
            os_log(formatString, log: osLogger, type: type, message)
        }
    }

    func logInfo(_ message: String) {
        log(message, level: .info)
    }
    
    func logDebug(_ message: String) {
        log(message, level: .debug)
    }
    
    func logError(_ message: String) {
        log(message, level: .error)
    }
    
    func logFatal(_ message: String) {
        log(message, level: .fatal)
    }
    
    private func shouldLog(level: LogLevel) -> Bool {
        switch level {
        case .fatal:
            return true
        case .error:
            return logLevel == .info || logLevel == .debug || logLevel == .error
        case .debug:
            return logLevel == .info || logLevel == .debug
        case .info:
            return logLevel == .info
        }
    }
    
    private static func setLogger(withName name: String, logger: Logger) {
        loggers.updateValue(logger, forKey: name)
    }
}
