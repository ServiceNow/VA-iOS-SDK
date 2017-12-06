//
//  Controls.swift
//  SnowChat
//
//  Created by Michael Borowiec on 12/1/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import Foundation

public enum Control {
    
    case boolean
    
    case multiselect
    
    case text
    
    // for internal use
    case selectableItem
    
    func displayTitle() -> String {
        switch self {
        case .boolean:
            return "Boolean Picker"
        case .multiselect:
            return "Multiselect Picker"
        case .text:
            return "Text Control"
        case .selectableItem:
            return "Selectable Item"
        }
    }
}
