//
//  SnowBoolControl.swift
//  SnowChat
//
//  Created by Michael Borowiec on 12/15/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import AlamofireImage

class ControlsUtil {
    static func controlForViewModel(_ model: ControlViewModel, apiManager manager: APIManager) -> ControlProtocol {
        switch model.type {
        case .multiSelect:
            return MultiSelectControl(model: model)
        case .text:
            return TextControl(model: model)
        case .outputImage:
            let outputImageControl = OutputImageControl(model: model)
            outputImageControl.imageDownloader = manager.imageDownloader
            return outputImageControl
        case .boolean:
            return BooleanControl(model: model)
        case .singleSelect:
            return SingleSelectControl(model: model)
        case .typingIndicator:
            return TypingIndicatorControl()
        }
    }
}
