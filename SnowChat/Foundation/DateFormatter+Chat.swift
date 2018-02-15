//
//  DateFormatter+Chat.swift
//  SnowChat
//
//  Created by Michael Borowiec on 2/13/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

extension DateFormatter {
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
            return DateFormatter.chatDateTimeFormatter()
        case .date:
            return DateFormatter.chatDateOnlyDateFormatter()
        case .time:
            return DateFormatter.chatTimeOnlyDateFormatter()
        default:
            fatalError("This control type should not be using dateFormatter: \(type))")
        }
    }
}
