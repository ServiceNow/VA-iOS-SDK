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
    
    // MARK: - Helper function
    // Turns string coming from the server into displayable version of this string (takes locale into account)
    // timeOrDateString: "HH:mm:ss" for time, or "yyyy-MM-dd" for date only type
    
    static func glideDisplayString(for timeOrDateString: String, for chatterboxControlType: ChatterboxControlType) -> String {
        if chatterboxControlType == .time,
            let date = Calendar.current.timeOnlyDate(from: timeOrDateString) {
            return localDisplayTimeOnlyFormatter.string(from: date)
        } else if chatterboxControlType == .date, let date = glideLocalDateOnlyFormatter.date(from: timeOrDateString) {
            return localDisplayDateOnlyFormatter.string(from: date)
        } else {
            return ""
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

extension Calendar {
    func timeOnlyDate(from glideTimeString: String) -> Date? {
        let stringComponents = glideTimeString.components(separatedBy: ":")
        guard stringComponents.count == 3 else { return nil }
        
        guard let hour = Int(stringComponents[0]),
            let minute = Int(stringComponents[1]),
            let second = Int(stringComponents[2]) else { return nil }
        
        return date(bySettingHour: hour, minute: minute, second: second, of: Date(timeIntervalSince1970: 0))
    }
}
