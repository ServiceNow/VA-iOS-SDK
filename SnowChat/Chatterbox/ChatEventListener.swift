//
//  ChatEventListener.swift
//  SnowChat
//
//  Created by Marc Attinasi on 12/11/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import Foundation

struct TopicInfo {
    let topicId: String
    let topicName: String?
    let conversationId: String
}

struct AgentInfo {
    var agentId: String
    var agentAvatar: String?
}

enum TransportStatus {
    case reachable
    case unreachable
}

protocol ChatEventListener: AnyObject {
    
    func chatterbox(_ chatterbox: Chatterbox, didStartTopic topicInfo: TopicInfo, forChat chatId: String)
    func chatterbox(_ chatterbox: Chatterbox, didResumeTopic topicInfo: TopicInfo, forChat chatId: String)
    func chatterbox(_ chatterbox: Chatterbox, didFinishTopic topicInfo: TopicInfo, forChat chatId: String)

    func chatterbox(_ chatterbox: Chatterbox, willStartAgentChat agentInfo: AgentInfo, forChat chatId: String)
    func chatterbox(_ chatterbox: Chatterbox, didStartAgentChat agentInfo: AgentInfo, forChat chatId: String)
    
    func chatterbox(_ chatterbox: Chatterbox, didEstablishUserSession sessionId: String, forChat chatId: String)
    
    func chatterbox(_ chatterbox: Chatterbox, didReceiveTransportStatus transportStatus: TransportStatus, forChat chatId: String)
}
