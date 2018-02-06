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
    let conversationId: String
}

protocol ChatEventListener: AnyObject {
    
    func chatterbox(_ chatterbox: Chatterbox, didStartTopic topicInfo: TopicInfo, forChat chatId: String)
    func chatterbox(_ chatterbox: Chatterbox, didResumeTopic topicInfo: TopicInfo, forChat chatId: String)
    func chatterbox(_ chatterbox: Chatterbox, didFinishTopic topicInfo: TopicInfo, forChat chatId: String)

    func chatterbox(_ chatterbox: Chatterbox, didEstablishUserSession sessionId: String, forChat chatId: String )    
}
