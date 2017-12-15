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
            fatalError("oops")
        }
        
        let questionModel = TextControlViewModel(id: model.id, label: model.label, value: model.label)
        let questionTextControl = TextControl(model: questionModel)
        
        let result = "Yes"
        let answerModel = TextControlViewModel(id: model.id, label: result, value: result)
        let answerTextControl = TextControl(model: answerModel)
        return [questionTextControl, answerTextControl]
    }
    
}
