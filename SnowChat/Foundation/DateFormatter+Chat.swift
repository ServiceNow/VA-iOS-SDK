//
//  DateFormatter+Chat.swift
//  SnowChat
//
//  Created by Michael Borowiec on 2/13/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

extension DateFormatter {
    static func chatDateFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
}
