//
//  Controls.swift
//  SnowChat
//
//  Created by Michael Borowiec on 12/1/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import Foundation

extension ControlProtocol {
    
    static func control(withMessage message: CBControlData) -> ControlProtocol? {
        switch message.controlType {
        case .boolean:
            return BooleanPickerControl.control(withMessage: message as! BooleanControlMessage)
        default:
            fatalError("not ready yet")
        }
        
        return nil
    }
}
