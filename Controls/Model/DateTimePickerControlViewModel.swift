//
//  DateTimePickerControlViewModel.swift
//  SnowChat
//
//  Created by Michael Borowiec on 2/8/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

/**
 > date: `yyyy-MM-dd` (always assumed local date, so even if the user's timezone changes, the date will never change.)
 
 > date time: no change – still sent and received in unix time, displayed in local time on clients.
 
 > time: `HH:mm:ss` (always assumed local time, so even if the user's timezone changes, the time will never change.)
 
 Additional Notes:
 - Date matches platform behavior.
 
 - Date Time will need to display with the user session's timezone preference on the desktop to match the platform. Mobile clients will display local device time zone.
 
 - Time does not match `GlideTime` field's platform behavior. We need a local "floating" time to handle our use case (like an alarm clock that's always 6am no matter where you are, for example). The platform does not currently have a concept of a "local" / "floating" time field.
 */

class DateTimePickerControlViewModel: ControlViewModel, ValueRepresentable {
    var label: String?

    var isRequired: Bool

    var id: String
    
    var value: Date?
    
    var resultValue: Date? {
        return value
    }
    
    var type: ControlType {
        return .dateTime
    }
    
    var dateFormatter: DateFormatter {
        return DateFormatter.localDisplayDateTimeFormatter
    }
    
    var displayValue: String? {
        guard let value = value else { return nil }
        return dateFormatter.string(from: value)
    }
    
    var messageDate: Date?
    
    init(id: String, label: String? = nil, required: Bool, resultValue: Date? = nil, messageDate: Date) {
        self.label = label
        self.id = id
        self.isRequired = required
        self.value = resultValue
        self.messageDate = messageDate
    }
}

// MARK: Date-only PickerViewModel

class DatePickerControlViewModel: DateTimePickerControlViewModel {
    override var type: ControlType {
        return .date
    }
    
    override var dateFormatter: DateFormatter {
        return DateFormatter.glideLocalDateOnlyFormatter
    }
}

// MARK: Time-only PickerViewModel

class TimePickerControlViewModel: DateTimePickerControlViewModel {
    override var type: ControlType {
        return .time
    }
    
    override var dateFormatter: DateFormatter {
        return DateFormatter.glideLocalTimeOnlyFormatter
    }
}
