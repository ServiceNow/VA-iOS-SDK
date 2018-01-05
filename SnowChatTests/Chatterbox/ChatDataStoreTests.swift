//
//  ChatDataStoreTests.swift
//  SnowChatTests
//
//  Created by Marc Attinasi on 12/13/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import XCTest
@testable import SnowChat

class DataStoreTests: XCTestCase {
    
    var chatterbox: Chatterbox?
    let jsonBoolean = """
        {
          "type": "systemTextMessage",
          "data": {
            "sessionId": "1",
            "sendTime": 0,
            "receiveTime": 0,
            "direction": "outbound",
            "richControl": {
              "uiType": "Boolean",
              "value": true,
              "uiMetadata": {
                "label": "Would you like to create an incident?",
                "required": true
              },
              "model": {
                "name": "init_create_incident",
                "type": "field"
              }
            },
            "messageId": "d30c8342-1e78-47aa-886e-d6627c092691"
          }
        }
        """

    override func setUp() {
        chatterbox = Chatterbox(instance: ServerInstance(instanceURL: URL(fileURLWithPath: "")), dataListener: nil, eventListener: nil)
    }
    
    func testNoMessages() {
        let store = ChatDataStore(storeId: "test-store")
        XCTAssertEqual(store.conversationIds().count, 0)
    }
    
    func testAddConversations() {
        let store = ChatDataStore(storeId: "test-store")
        let control = CBDataFactory.controlFromJSON(jsonBoolean)
        
        store.storeControlData(control, expectResponse: true, forConversation: "testConversationID1", fromChat: chatterbox!)
        store.storeControlData(control, expectResponse: true, forConversation: "testConversationID2", fromChat: chatterbox!)
        
        // make sure 2 conversations
        let conversationIds = store.conversationIds()
        XCTAssertEqual(conversationIds.count, 2)
        
        // make sure each conversation has 1 message-exchange
        conversationIds.forEach { id in
            XCTAssertEqual(1, store.conversation(forId: id)?.messageExchanges().count)
        }
        
        // make sure the message ID in the exchanges are correct
        conversationIds.forEach { id in
            XCTAssertEqual(control.id, store.conversation(forId: id)?.messageExchanges().last?.message.uniqueId())
        }

    }
    
    func testAddMessagesWithAndWithoutResponses() {
        let store = ChatDataStore(storeId: "test-store")
        let control = CBDataFactory.controlFromJSON(jsonBoolean)
        
        store.storeControlData(control, expectResponse: true, forConversation: "testConversationID1", fromChat: chatterbox!)
        store.storeControlData(control, expectResponse: false, forConversation: "testConversationID2", fromChat: chatterbox!)
        
        XCTAssertEqual(control.uniqueId(), store.conversation(forId: "testConversationID1")?.messageExchanges().first?.message.uniqueId())
        XCTAssertEqual(control.uniqueId(), store.conversation(forId: "testConversationID2")?.messageExchanges().first?.message.uniqueId())

        XCTAssertFalse((store.conversation(forId: "testConversationID1")?.messageExchanges().first?.isComplete)!)
        XCTAssertTrue((store.conversation(forId: "testConversationID2")?.messageExchanges().first?.isComplete)!)
        
        XCTAssertEqual(control.id, store.lastPendingMessage(forConversation: "testConversationID1")?.uniqueId())
        XCTAssertNil(store.lastPendingMessage(forConversation: "testConversationID2"))
    }

    func testNoPendingMessageForDifferentConvresation() {
        let store = ChatDataStore(storeId: "test-store")
        let control = CBDataFactory.controlFromJSON(jsonBoolean)
        
        store.storeControlData(control, expectResponse: true, forConversation: "testConversationID1", fromChat: chatterbox!)

        XCTAssertEqual(control.id, store.lastPendingMessage(forConversation: "testConversationID1")?.uniqueId())
        XCTAssertNil(store.lastPendingMessage(forConversation: "some-other-conversation"))
    }
    
    func testResponseMakesCompleted() {
        let store = ChatDataStore(storeId: "test-store")
        let control = CBDataFactory.controlFromJSON(jsonBoolean)
        
        store.storeControlData(control, expectResponse: true, forConversation: "testConversationID", fromChat: chatterbox!)
        store.storeControlData(control, expectResponse: true, forConversation: "testConversationID2", fromChat: chatterbox!)
        XCTAssertNotNil(store.lastPendingMessage(forConversation: "testConversationID")?.uniqueId())
        XCTAssertNotNil(store.lastPendingMessage(forConversation: "testConversationID2")?.uniqueId())
        
        store.storeResponseData(control, forConversation: "testConversationID")
        
        XCTAssertNil(store.lastPendingMessage(forConversation: "testConversationID"))
        XCTAssertNotNil(store.lastPendingMessage(forConversation: "testConversationID2")?.uniqueId())
    }
}
