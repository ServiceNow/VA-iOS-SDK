//
//  TimeAgo.swift
//  SnowChat
//
//  Created by Floyd Morgan on 4/16/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import Foundation

extension DateFormatter {
    //swiftlint:disable:next cyclomatic_complexity
    public static func now_timeAgoSince(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let subset: Set<Calendar.Component> = [.second, .minute, .hour, .day, .weekOfYear, .month, .year]
        let components = calendar.dateComponents(subset, from: now)
        
        if let year = components.year, year >= 2 {
            return NSLocalizedString("\(year) years ago", comment: "A date that's N years ago")
        }
        
        if let year = components.year, year >= 1 {
            return NSLocalizedString("Last year", comment: "A date that's a year ago")
        }
        
        if let month = components.month, month >= 2 {
            return NSLocalizedString("\(month) months ago", comment: "A date that's N months ago")
        }
        
        if let month = components.month, month >= 1 {
            return NSLocalizedString("Last month", comment: "A date that's a month ago")
        }
        
        if let week = components.weekOfYear, week >= 2 {
            return NSLocalizedString("\(week) weeks ago", comment: "A date that's N weeks ago")
        }
        
        if let week = components.weekOfYear, week >= 1 {
            return NSLocalizedString("Last week", comment: "A date that's a week ago")
        }
        
        if let day = components.day, day >= 2 {
            return NSLocalizedString("\(day) days ago", comment: "A date that's N days ago")
        }
        
        if let day = components.day, day >= 1 {
            return NSLocalizedString("Yesterday", comment: "A date that's yesterday")
        }
        
        if let hour = components.hour, hour >= 2 {
            return NSLocalizedString("\(hour) hours ago", comment: "A date that's N hours ago")
        }
        
        if let hour = components.hour, hour >= 1 {
            return NSLocalizedString("An hour ago", comment: "A date that's an hour ago")
        }
        
        if let minute = components.minute, minute >= 2 {
            return NSLocalizedString("\(minute) minutes ago", comment: "A date that's N mintues ago")
        }
        
        if let minute = components.minute, minute >= 1 {
            return NSLocalizedString("A minute ago", comment: "A date that's a minute ago")
        }
        
        if let second = components.second, second >= 3 {
            return NSLocalizedString("\(second) seconds ago", comment: "A date that's N seconds ago")
        }
        
        return NSLocalizedString("Just now", comment: "A date that's current time")
    }
}
