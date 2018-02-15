//
//  DateTimePickerControlViewModel.swift
//  SnowChat
//
//  Created by Michael Borowiec on 2/8/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

class DateTimePickerControlViewModel: ControlViewModel, ValueRepresentable {
    
    let label: String?
    
    let isRequired: Bool
    
    let id: String
    
    var type: ControlType {
        return .dateTime
    }
    
    var value: Date?
    
    var resultValue: Date? {
        return value
    }
    
    var dateFormatter: DateFormatter {
        return DateFormatter.chatDateTimeFormatter()
    }
    
    var displayValue: String? {
        guard let value = value else { return nil }
        return dateFormatter.string(from: value)
    }
    
    init(id: String, label: String? = nil, required: Bool, resultValue: Date? = nil) {
        self.label = label
        self.value = resultValue
        self.id = id
        self.isRequired = required
    }
}

class DatePickerControlViewModel: DateTimePickerControlViewModel {
    override var type: ControlType {
        return .date
    }
    
    override var dateFormatter: DateFormatter {
        return DateFormatter.chatDateOnlyDateFormatter()
    }
}

class TimePickerControlViewModel: DateTimePickerControlViewModel {
    override var type: ControlType {
        return .time
    }
    
    override var dateFormatter: DateFormatter {
        return DateFormatter.chatTimeOnlyDateFormatter()
    }
}
