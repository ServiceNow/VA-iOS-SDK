//
//  SnowControlViewModel.swift
//  SnowChat
//
//  Created by Michael Borowiec on 1/4/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

enum BubbleLocation {
    case left
    case right
    
    static func location(for direction: MessageDirection) -> BubbleLocation {
        switch direction {
        case .fromClient:
            return .right
        case .fromServer:
            return .left
        }
    }
}

class ChatMessageModel {
    
    let controlModel: ControlViewModel
    let location: BubbleLocation
    
    init(model: ControlViewModel, location: BubbleLocation) {
        self.controlModel = model
        self.location = location
    }
}
