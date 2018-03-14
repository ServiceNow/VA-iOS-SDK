//
//  SubscribeToSupportQueueMessage.swift
//  SnowChat
//
//  Created by Marc Attinasi on 3/1/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import Foundation

struct SupportQueue: Codable {
    var active: Bool
    var queueAmbChannel: String?
    var averageWaitTime:  String
    var sysId: String
    
    var channel: String? {
        return queueAmbChannel
    }
}

struct SubscribeToSupportQueueMessage: Codable, ActionData {
    var eventType: ChatterboxActionType = .supportQueueSubscribe

    let type: String = "actionMessage"
    let data: ActionMessageData<ActionMessageDetails>
    
    struct ActionMessageDetails: Codable {
        let type: String
        let supportQueue: SupportQueue
    }
    
    // define the properties that we decode / encode
    private enum CodingKeys: String, CodingKey {
        case type
        case data
    }
    
    var channel: String? {
        return data.actionMessage.supportQueue.channel
    }
    
    var active: Bool {
        return data.actionMessage.supportQueue.active
    }
    
    var waitTimeDisplayString: String {
        return data.actionMessage.supportQueue.averageWaitTime
    }
}
