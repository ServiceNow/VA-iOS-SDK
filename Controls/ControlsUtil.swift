//
//  SnowBoolControl.swift
//  SnowChat
//
//  Created by Michael Borowiec on 12/15/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

class ControlsUtil {
    static func controlForViewModel(_ model: ControlViewModel) -> ControlProtocol {
        switch model.type {
        case .multiSelect:
            return MultiSelectControl(model: model)
        case .text:
            return TextControl(model: model)
        case .outputImage:
            return OutputImageControl(model: model)
        case .boolean:
            return BooleanControl(model: model)
        case .singleSelect:
            return SingleSelectControl(model: model)
        case .typingIndicator:
            return TypingIndicatorControl()
        case .multiPart:
            return MultiPartControl(model: model)
        }
    }
}
