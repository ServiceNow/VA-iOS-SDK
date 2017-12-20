//
//  SnowBoolControl.swift
//  SnowChat
//
//  Created by Michael Borowiec on 12/15/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

class SnowControlUtils {
    
    static func booleanControl(forBooleanMessage message: BooleanControlMessage) -> BooleanControl {
        guard let model = BooleanControlViewModel.model(withMessage: message) else {
            fatalError("oops")
        }
        
        let booleanControl = BooleanControl(model: model)
        return booleanControl
    }
    
    static func textControls(forBooleanMessage message: BooleanControlMessage) -> [TextControl] {
        guard let model = BooleanControlViewModel.model(withMessage: message) else {
            fatalError("Invalid message")
        }
        
        // FIXME: provide proper direction info and result string. Temporary hacking together
        let questionModel = TextControlViewModel(id: model.id, label: model.label, value: model.label, direction: .inbound)
        let questionTextControl = TextControl(model: questionModel)
        
        // FIXME: This result needs to come from the BooleanControlMessage. Not sure if that is ready yet
        let result = "Yes"
        let answerModel = TextControlViewModel(id: model.id, label: result, value: result, direction: .outbound)
        let answerTextControl = TextControl(model: answerModel)
        return [questionTextControl, answerTextControl]
    }
    
}
