//
//  SnowBoolControl.swift
//  SnowChat
//
//  Created by Michael Borowiec on 12/15/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import AlamofireImage

class ControlsUtil {
    
    //swiftlint:disable:next cyclomatic_complexity
    static func controlForViewModel(_ model: ControlViewModel, resourceProvider provider: ControlResourceProvider) -> ControlProtocol {
        switch model.type {
        case .multiSelect:
            return MultiSelectControl(model: model)
        case .text:
            return TextControl(model: model)
        case .outputImage:
            return OutputImageControl(model: model, imageDownloader: provider.imageDownloader)
        case .inputImage:
            return InputImageControl(model: model)
        case .outputLink:
            return OutputLinkControl(model: model, resourceProvider: provider)
        case .outputHtml:
            return OutputHtmlControl(model: model, resourceProvider: provider)
        case .dateTime, .time, .date:
            return DateTimePickerControl(model: model)
        case .boolean:
            return BooleanControl(model: model)
        case .singleSelect:
            return SingleSelectControl(model: model)
        case .carousel:
            let carousel = CarouselControl(model: model)
            carousel.imageDownloader = provider.imageDownloader
            return carousel
        case .typingIndicator:
            return TypingIndicatorControl()
        case .button:
            return ButtonControl(model: model)
        }
    }
}
