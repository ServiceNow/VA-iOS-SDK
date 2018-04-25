//
//  CarouselControlViewModel.swift
//  SnowChat
//
//  Created by Michael Borowiec on 2/27/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

class CarouselItem: PickerItem {
    
    var attachment: URL?
    
    init(label: String?, value: String, attachment: URL?) {
        self.attachment = attachment
        super.init(type: .custom, label: label, value: value)
    }
}

class CarouselControlViewModel: PickerControlViewModel {
    
    let id: String
    
    let label: String?
    
    let isRequired: Bool
    
    let isMultiSelect: Bool = false
    
    var items = [PickerItem]()
    
    var type: ControlType {
        return .carousel
    }

    let messageDate: Date?

    init(id: String, label: String? = nil, required: Bool, items: [PickerItem], resultValue: String? = nil, messageDate: Date) {
        self.id = id
        self.label = label
        self.isRequired = required
        self.items = items
        self.messageDate = messageDate
        
        if !required {
            self.items.append(PickerItem.skipItem())
        }
        
        selectItem(withValue: resultValue)
    }
    
    private func selectItem(withValue value: String?) {
        guard let value = value else {
            return
        }
        
        let item = items.first(where: { $0.value == value })
        item?.isSelected = true
    }
    
    // MARK: - ValueRepresentable
    
    var resultValue: String? {
        guard let selectedItem = selectedItem, selectedItem.type != .skip else {
            return nil
        }
        
        return selectedItem.value
    }
    
    var displayValue: String? {
        return resultValue
    }
}
