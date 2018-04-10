//
//  ChatEventListener.swift
//  SnowChat
//
//  Created by Marc Attinasi on 12/11/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import Foundation

struct TopicInfo {
    let topicId: String?
    let topicName: String?
    let taskId: String?
    let conversationId: String
}

struct AgentInfo {
    let agentId: String
    let agentAvatar: String?
    
    static let IDUNKNOWN = "UNKNOWN"
}

enum TransportStatus {
    case reachable
    case reconnecting
    case unreachable
}

protocol ChatEventListener: AnyObject {
    
    func chatterbox(_ chatterbox: Chatterbox, didStartTopic topicInfo: TopicInfo, forChat chatId: String)
    func chatterbox(_ chatterbox: Chatterbox, didResumeTopic topicInfo: TopicInfo, forChat chatId: String)
    func chatterbox(_ chatterbox: Chatterbox, didFinishTopic topicInfo: TopicInfo, forChat chatId: String)

    func chatterbox(_ chatterbox: Chatterbox, willStartAgentChat agentInfo: AgentInfo, forChat chatId: String)
    func chatterbox(_ chatterbox: Chatterbox, didStartAgentChat agentInfo: AgentInfo, forChat chatId: String)
    func chatterbox(_ chatterbox: Chatterbox, didResumeAgentChat agentInfo: AgentInfo, forChat chatId: String)
    func chatterbox(_ chatterbox: Chatterbox, didFinishAgentChat agentInfo: AgentInfo, forChat chatId: String)

    func chatterbox(_ chatterbox: Chatterbox, didEstablishUserSession sessionId: String, forChat chatId: String)
    func chatterbox(_ chatterbox: Chatterbox, didRestoreUserSession sessionId: String, forChat chatId: String)

    func chatterbox(_ chatterbox: Chatterbox, didReceiveTransportStatus transportStatus: TransportStatus, forChat chatId: String)
}
