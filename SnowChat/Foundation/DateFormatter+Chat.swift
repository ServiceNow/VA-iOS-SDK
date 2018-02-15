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
}
