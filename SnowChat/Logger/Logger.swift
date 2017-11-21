//
//  Logger.swift
//  SnowChat
//
//  Logging facility for SnowChat
//
//  - use `Logger.def' for basic logging, or create a new logger for specific needs using
//    'let logger = Logger.logger(for: "AMB")` to greate a logger specific to a functional area or category od usage.
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
            setLogger(name: name, logger: Logger(forCategory: name))
        }
        // swiftlint:disable:next force_unwrapping
        return loggers[name]!
    }
    
    static func setLogger(name: String, logger: Logger) {
        loggers.updateValue(logger, forKey: name)
    }
    
    enum LogLevel {
        case Info
        case Debug
        case Error
        case Fatal
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
    
    init(forCategory: String, atLevel: LogLevel = .Info) {
        category = forCategory
        logLevel = atLevel
        osLogger = OSLog(subsystem: domain, category: forCategory)
    }
    
    func logInfo(_ msg: String) {
        if enabled && shouldLog(level: .Info) {
            let m: StaticString = "%@"
            os_log(m, log: osLogger, type: .info, msg)
        }
    }
    
    func logDebug(_ msg: String) {
        if enabled && shouldLog(level: .Debug) {
            let m: StaticString = "%@"
            os_log(m, log: osLogger, type: .debug, msg)
        }
    }
    
    func logError(_ msg: String) {
        if enabled && shouldLog(level: .Error) {
            let m: StaticString = "%@"
            os_log(m, log: osLogger, type: .error, msg)
        }
    }
    
    func logFatal(_ msg: String) {
        if enabled && shouldLog(level: .Fatal) {
            let m: StaticString = "%@"
            os_log(m, log: osLogger, type: .fault, msg)
        }
    }
    
    func log(_ msg: String, level: LogLevel) {
        switch level {
        case .Info:
            logInfo(msg)
        case .Debug:
            logDebug(msg)
        case .Error:
            logError(msg)
        case .Fatal:
            logFatal(msg)
        }
    }
    
    fileprivate func shouldLog(level: LogLevel) -> Bool {
        switch level {
        case .Fatal:
            return true
        case .Error:
            return logLevel == .Info || logLevel == .Debug || logLevel == .Error
        case .Debug:
            return logLevel == .Info || logLevel == .Debug
        case .Info:
            return logLevel == .Info
        }
    }
}
