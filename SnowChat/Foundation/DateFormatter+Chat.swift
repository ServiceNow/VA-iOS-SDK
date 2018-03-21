//
//  DateFormatter+Chat.swift
//  SnowChat
//
//  Created by Michael Borowiec on 2/13/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

extension DateFormatter {
    
    // MARK: - Local TimeZone formatters
    
    // Formatters in local time zone. "Glide" means that it is used to translate date to/from a server expected format.
    static let localDisplayDateOnlyFormatter = chatLocalDateOnlyDateFormatter()
    static let localDisplayTimeOnlyFormatter = chatLocalTimeOnlyDateFormatter()
    static let localDisplayDateTimeFormatter = chatLocalDateTimeFormatter()
    
    static let glideLocalTimeOnlyFormatter = chatGlideLocalTimeFormatter()
    static let glideLocalDateOnlyFormatter = chatGlideLocalDateOnlyFormatter()
    
    // MARK: - Formatters in GMT time zone
    
    static let glideTimeOnlyFormatter = chatGlideTimeOnlyFormatter()
    static let glideDateOnlyFormatter = chatGlideDateOnlyFormatter()
    static let glideDisplayTimeOnlyFormatter = chatGlideDisplayTimeOnlyFormatter()
    static let glideDisplayDateOnlyFormatter = chatGlideDisplayDateOnlyFormatter()
    
    // MARK: - Static helper functions
    // Used in ViewController to display dateTime in local timezone.
    
    static func chatLocalDateTimeFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
    
    // Used in ViewController to display time in local timezone.
    
    static func chatLocalTimeOnlyDateFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }
    
    // Used in ViewController to display date-only in local timezone.
    
    static func chatLocalDateOnlyDateFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }
    
    // Used to format selected Date object to be send to the server (Time only format)
    
    static func chatGlideLocalTimeFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }
    
    // Used to format selected Date object to be send to the server (Date only format)
    
    static func chatGlideLocalDateOnlyFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }
    
    // Used to create Date object out of Time string coming from the server. Must be in GMT.
    
    static func chatGlideTimeOnlyFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }
    
    // Used to create Date object out of Date-only string coming from the server. Must be in GMT.
    
    static func chatGlideDateOnlyFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }
    
    // Used to output Time from the Date objec that came from the server. GMT
    
    static func chatGlideDisplayTimeOnlyFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }
    
    // Used to output Date-only from the Date objec that came from the server. GMT
    
    static func chatGlideDisplayDateOnlyFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }
    
    // MARK: - Helper function
    // Turns string coming from the server into displayable version of this string (takes locale into account)
    // timeOrDateString: "HH:mm:ss" for time, or "yyyy-MM-dd" for date only type
    
    static func glideDisplayString(for timeOrDateString: String, for chatterboxControlType: ChatterboxControlType) -> String {
        
        // Used to turn string into Date
        let glideDateFormatter = DateFormatter.glideFormatter(for: chatterboxControlType)
        
        // Used to turn Date into localized string
        let glideDisplayDateFormatter = DateFormatter.glideDisplayFormatter(for: chatterboxControlType)
        
        guard let date = glideDateFormatter.date(from: timeOrDateString) else {
            return ""
        }
        
        return glideDisplayDateFormatter.string(from: date)
    }
    
    // MARK: Glide formatters (GMT)
    
    static func glideFormatter(for chatterboxControlType: ChatterboxControlType) -> DateFormatter {
        switch chatterboxControlType {
        case .date:
            return DateFormatter.glideDateOnlyFormatter
        case .time:
            return DateFormatter.glideTimeOnlyFormatter
        default:
            fatalError("This control type should not be using dateFormatter: \(chatterboxControlType))")
        }
    }
    
    static func glideDisplayFormatter(for chatterboxControlType: ChatterboxControlType) -> DateFormatter {
        switch chatterboxControlType {
        case .date:
            return DateFormatter.glideDisplayDateOnlyFormatter
        case .time:
            return DateFormatter.glideDisplayTimeOnlyFormatter
        default:
            fatalError("This control type should not be using dateFormatter: \(chatterboxControlType))")
        }
    }
    
    // MARK: Local formatters. Used in View layer.
    
    static func localDisplayFormatter(for chatterboxControlType: ChatterboxControlType) -> DateFormatter {
        switch chatterboxControlType {
        case .dateTime:
            return DateFormatter.localDisplayDateTimeFormatter
        case .date:
            return DateFormatter.localDisplayDateOnlyFormatter
        case .time:
            return DateFormatter.localDisplayTimeOnlyFormatter
        default:
            fatalError("This control type should not be using dateFormatter: \(chatterboxControlType))")
        }
    }
    
    static func localDisplayFormatter(for controlType: ControlType) -> DateFormatter {
        switch controlType {
        case .dateTime:
            return DateFormatter.localDisplayDateTimeFormatter
        case .date:
            return DateFormatter.localDisplayDateOnlyFormatter
        case .time:
            return DateFormatter.localDisplayTimeOnlyFormatter
        default:
            fatalError("This control type should not be using dateFormatter: \(controlType))")
        }
    }
}
