//
//  DateFormatter+Chat.swift
//  SnowChat
//
//  Created by Michael Borowiec on 2/13/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

extension DateFormatter {
    static let dateOnlyFormatter = chatDateOnlyDateFormatter()
    static let timeOnlyFormatter = chatTimeOnlyDateFormatter()
    static let dateTimeFormatter = chatDateTimeFormatter()
    
    static let glideTimeFormatter = chatGlideTimeFormatter()
    static let glideDateOnlyFormatter = chatGlideDateOnlyFormatter()
    static let glideDisplayTimeFormatter = chatGlideDisplayTimeFormatter()
    static let glideDisplayDateOnlyFormatter = chatGlideDisplayDateOnlyFormatter()
    
    static func chatDateTimeFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
    
    static func chatTimeOnlyDateFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }
    
    static func chatDateOnlyDateFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }
    
    static func chatGlideTimeFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }
    
    static func chatGlideDateOnlyFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }
    
    static func chatGlideDisplayTimeFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }
    
    static func chatGlideDisplayDateOnlyFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }
    
    static func formatterForChatterboxControlType(_ type: ChatterboxControlType) -> DateFormatter {
        switch type {
        case .dateTime:
            return DateFormatter.dateTimeFormatter
        case .date:
            return DateFormatter.dateOnlyFormatter
        case .time:
            return DateFormatter.timeOnlyFormatter
        default:
            fatalError("This control type should not be using dateFormatter: \(type))")
        }
    }
    
    static func formatterForDateTimeControlType(_ type: ControlType) -> DateFormatter {
        switch type {
        case .dateTime:
            return DateFormatter.dateTimeFormatter
        case .date:
            return DateFormatter.dateOnlyFormatter
        case .time:
            return DateFormatter.timeOnlyFormatter
        default:
            fatalError("This control type should not be using dateFormatter: \(type))")
        }
    }
}
