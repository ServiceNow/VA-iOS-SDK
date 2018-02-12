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
    
    let type: ControlType = .dateTime
    
    var value: Date?
    
    var resultValue: Date? {
        return nil
    }
    
    var displayValue: String? {
        return nil
    }
    
    init(id: String, label: String? = nil, required: Bool, resultValue: Date? = nil) {
        self.label = label
        self.value = resultValue
        self.id = id
        self.isRequired = required
    }
}
