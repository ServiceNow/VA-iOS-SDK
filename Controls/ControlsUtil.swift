//
//  SnowBoolControl.swift
//  SnowChat
//
//  Created by Michael Borowiec on 12/15/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import AlamofireImage

class ControlsUtil {
    static func controlForViewModel(_ model: ControlViewModel, resourceProvider provider: ControlResourceProvider? = nil) -> ControlProtocol {
        switch model.type {
        case .multiSelect:
            return MultiSelectControl(model: model)
        case .text:
            return TextControl(model: model)
        case .outputImage:
            let outputImageControl = OutputImageControl(model: model)
            outputImageControl.imageDownloader = provider?.imageProvider
            return outputImageControl
        case .outputLink:
            return LinkOutputControl(model: model)
        case .boolean:
            return BooleanControl(model: model)
        case .singleSelect:
            return SingleSelectControl(model: model)
        case .typingIndicator:
            return TypingIndicatorControl()
        case .button:
            return ButtonControl(model: model)
        }
    }
}
