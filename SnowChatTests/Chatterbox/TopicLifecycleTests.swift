//
//  TopicLifecycleTests.swift
//  SnowChatTests
//
//  Created by Marc Attinasi on 4/9/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import XCTest
@testable import SnowChat

class TopicLifecycleTests: XCTestCase {
    var chatterbox = Chatterbox(instance: ServerInstance(instanceURL: URL(fileURLWithPath: "foo.bar")))
    
    let jsonStartedTopic = """
    {
      "type" : "actionMessage",
      "data" : {
        "@class" : ".ActionMessageDto",
        "messageId" : "6686092a733a0300d63a566a4cf6a703",
        "sessionId" : "b47605e6733a0300d63a566a4cf6a77b",
        "conversationId" : "f0760de6733a0300d63a566a4cf6a7b6",
        "actionMessage" : {
          "taskId" : "f8760de6733a0300d63a566a4cf6a7b6",
          "vendorTopicId" : "ee86092a733a0300d63a566a4cf6a702",
          "topicName" : "Create Incident",
          "startStage" : "Finish",
          "topicId" : "f0760de6733a0300d63a566a4cf6a7b6",
          "type" : "StartedVendorTopic",
          "ready" : true
        },
        "links" : [

        ],
        "direction" : "outbound",
        "isAgent" : false,
        "receiveTime" : 0,
        "sendTime" : 0
      },
      "source" : "server"
    }
    """

    let jsonTopicFinished = """
        {
          "type" : "actionMessage",
          "data" : {
            "@class" : ".ActionMessageDto",
            "messageId" : "7984912f73760300d63a566a4cf6a76a",
            "sessionId" : "ce74996773760300d63a566a4cf6a7bc",
            "conversationId" : "ee86092a733a0300d63a566a4cf6a702",
            "actionMessage" : {
              "type" : "TopicFinished",
              "systemActionName" : "TopicFinished"
            },
            "links" : [

            ],
            "direction" : "outbound",
            "isAgent" : false,
            "receiveTime" : 0,
            "sendTime" : 1512771274122
          },
          "source" : "server"
        }
        """
    
    let jsonStartedAgentConversation = """
    {
      "type" : "actionMessage",
      "data" : {
        "actionMessage" : {
          "chatStage" : "ConnectToAgent",
          "topicId" : "42f17fd373501300d63a566a4cf6a7d6",
          "type" : "StartChat",
          "systemActionName" : "startChat"
        },
        "@class" : ".ActionMessageDto",
        "messageId" : "f8027fd373501300d63a566a4cf6a7fa",
        "sendTime" : 0,
        "conversationId" : "cbe17fd373501300d63a566a4cf6a7ce",
        "receiveTime" : 0,
        "links" : [

        ],
        "agent" : false,
        "sessionId" : "43e17fd373501300d63a566a4cf6a7ff",
        "taskId" : "c7e17fd373501300d63a566a4cf6a7cf",
        "isAgent" : false,
        "direction" : "inbound"
      },
      "source" : "client"
    }
    """
    
    let jsonChatFinished = """
    {
          "type" : "actionMessage",
          "data" : {
            "@class" : ".ActionMessageDto",
            "messageId" : "7984912f73760300d63a566a4cf6a76a",
            "sessionId" : "43e17fd373501300d63a566a4cf6a7ff",
            "conversationId" : "42f17fd373501300d63a566a4cf6a7d6",
            "actionMessage" : {
              "type" : "TopicFinished",
              "systemActionName" : "TopicFinished"
            },
            "links" : [

            ],
            "direction" : "outbound",
            "isAgent" : false,
            "receiveTime" : 0,
            "sendTime" : 1512771274122
          },
          "source" : "server"
        }
    """
    
    override func setUp() {
        super.setUp()
        
        chatterbox.chatStore.reset()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testStartedTopicMessageInitializesConversation() {
        // assert conversation not there initially
        XCTAssertNil(chatterbox.conversation(forId: "ee86092a733a0300d63a566a4cf6a702"))
        
        chatterbox.startUserTopicHandshakeHandler(jsonStartedTopic)
        
        // assert conversation is now there and has correct values
        let conversation = chatterbox.conversation(forId: "ee86092a733a0300d63a566a4cf6a702")
        XCTAssertNotNil(conversation)
        XCTAssertEqual("Create Incident", conversation?.topicTypeName)
        XCTAssertEqual(Conversation.ConversationState.inProgress, conversation?.state)
    }
    
    func testTopicFinishedMessageUpdatesConversation() {
        chatterbox.startUserTopicHandshakeHandler(jsonStartedTopic)
        
        let handled = chatterbox.processEventMessage(jsonTopicFinished)

        XCTAssertTrue(handled)
        
        let conversation = chatterbox.conversation(forId: "ee86092a733a0300d63a566a4cf6a702")
        XCTAssertNotNil(conversation)
        XCTAssertEqual(Conversation.ConversationState.completed, conversation?.state)
        XCTAssertEqual("Create Incident", conversation?.topicTypeName)
    }
    
    func testStartedAgentTopicMessageInitializesComnversation() {
        XCTAssertNil(chatterbox.conversation(forId: "42f17fd373501300d63a566a4cf6a7d6"))
        
        chatterbox.startLiveAgentHandshakeHandler(jsonStartedAgentConversation)
        
        let conversation = chatterbox.conversation(forId: "42f17fd373501300d63a566a4cf6a7d6")
        XCTAssertNotNil(conversation)
        XCTAssertEqual(Conversation.ConversationState.chatProgress, conversation?.state)
        XCTAssertEqual("Live Agent", conversation?.topicTypeName)
    }
    
    func testAgentChatEndedUpdatesConversation() {
        chatterbox.startLiveAgentHandshakeHandler(jsonStartedAgentConversation)

        let handled = chatterbox.processEventMessage(jsonChatFinished)
        
        XCTAssertTrue(handled)
        
        let conversation = chatterbox.conversation(forId: "42f17fd373501300d63a566a4cf6a7d6")
        XCTAssertNotNil(conversation)
        XCTAssertEqual(Conversation.ConversationState.completed, conversation?.state)
        XCTAssertEqual("Live Agent", conversation?.topicTypeName)
    }
}
