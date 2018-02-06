//
//  ChatEventListener.swift
//  SnowChat
//
//  Created by Marc Attinasi on 12/11/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import Foundation

protocol ChatEventListener: AnyObject {
    
    func chatterbox(_ chatterbox: Chatterbox, didEstablishUserSession sessionId: String, forChat chatId: String )
    
    func chatterbox(_ chatterbox: Chatterbox, didStartTopic topic: StartedUserTopicMessage, forChat chatId: String)
    func chatterbox(_ chatterbox: Chatterbox, didFinishTopic topic: TopicFinishedMessage, forChat chatId: String)
}
