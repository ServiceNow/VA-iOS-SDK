//
//  ChatEventListener.swift
//  SnowChat
//
//  Created by Marc Attinasi on 12/11/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import Foundation

protocol ChatEventListener: AnyObject {
    
    func chatterbox(_: Chatterbox, didStartTopic topic: StartedUserTopicMessage, forChat chatId: String)
    func chatterbox(_: Chatterbox, didFinishTopic topic: TopicFinishedMessage, forChat chatId: String)
}
