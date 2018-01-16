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
    
    
    override func setUp() {
        chatterbox = Chatterbox(instance: ServerInstance(instanceURL: URL(fileURLWithPath: "")), dataListener: nil, eventListener: nil)
    }
    
    func testNoMessages() {
        let store = ChatDataStore(storeId: "test-store")
        XCTAssertEqual(store.conversationIds().count, 0)
    }
    
    func testAddConversations() {
        let store = ChatDataStore(storeId: "test-store")
        let booleanControl =  BooleanControlMessage.exampleInstance()

        store.storeControlData(booleanControl, forConversation: "testConversationID1", fromChat: chatterbox!)
        store.storeControlData(booleanControl, forConversation: "testConversationID2", fromChat: chatterbox!)
        
        // make sure 2 conversations
        let conversationIds = store.conversationIds()
        XCTAssertEqual(conversationIds.count, 2)
        
        // make sure each conversation has 1 message-exchange
        conversationIds.forEach { id in
            XCTAssertEqual(1, store.conversation(forId: id)?.messageExchanges().count)
        }
        
        // make sure the message ID in the exchanges are correct
        conversationIds.forEach { id in
            XCTAssertEqual(booleanControl.id, store.conversation(forId: id)?.messageExchanges().last?.message.uniqueId())
        }

    }
    
    func testAddMessagesWithAndWithoutResponses() {
        let store = ChatDataStore(storeId: "test-store")
        let booleanControl = BooleanControlMessage.exampleInstance()
        let inputControl = InputControlMessage.exampleInstance()
        let outputControl = OutputTextMessage.exampleInstance()
        
        store.storeControlData(booleanControl, forConversation: "testConversationID1", fromChat: chatterbox!)
        store.storeControlData(inputControl, forConversation: "testConversationID2", fromChat: chatterbox!)
        store.storeControlData(outputControl, forConversation: "testConversationID3", fromChat: chatterbox!)
        
        XCTAssertEqual(booleanControl.uniqueId(), store.conversation(forId: "testConversationID1")?.messageExchanges().first?.message.uniqueId())
        XCTAssertEqual(inputControl.uniqueId(), store.conversation(forId: "testConversationID2")?.messageExchanges().first?.message.uniqueId())
        XCTAssertEqual(outputControl.uniqueId(), store.conversation(forId: "testConversationID3")?.messageExchanges().first?.message.uniqueId())

        XCTAssertFalse((store.conversation(forId: "testConversationID1")?.messageExchanges().first?.isComplete)!)
        XCTAssertFalse((store.conversation(forId: "testConversationID2")?.messageExchanges().first?.isComplete)!)
        XCTAssertTrue((store.conversation(forId: "testConversationID3")?.messageExchanges().first?.isComplete)!)

        XCTAssertEqual(booleanControl.id, store.lastPendingMessage(forConversation: "testConversationID1")?.uniqueId())
        XCTAssertEqual(inputControl.id, store.lastPendingMessage(forConversation: "testConversationID2")?.uniqueId())
        XCTAssertNil(store.lastPendingMessage(forConversation: "testConversationID3")?.uniqueId())
    }

    func testNoPendingMessageForDifferentConvresation() {
        let store = ChatDataStore(storeId: "test-store")
        let control = BooleanControlMessage.exampleInstance()
        
        store.storeControlData(control, forConversation: "testConversationID1", fromChat: chatterbox!)

        XCTAssertEqual(control.id, store.lastPendingMessage(forConversation: "testConversationID1")?.uniqueId())
        XCTAssertNil(store.lastPendingMessage(forConversation: "some-other-conversation"))
    }
    
    func testResponseMakesCompleted() {
        let store = ChatDataStore(storeId: "test-store")
        let control = BooleanControlMessage.exampleInstance()
        
        store.storeControlData(control, forConversation: "testConversationID", fromChat: chatterbox!)
        store.storeControlData(control, forConversation: "testConversationID2", fromChat: chatterbox!)
        XCTAssertNotNil(store.lastPendingMessage(forConversation: "testConversationID")?.uniqueId())
        XCTAssertNotNil(store.lastPendingMessage(forConversation: "testConversationID2")?.uniqueId())
        
        store.storeResponseData(control, forConversation: "testConversationID")
        
        XCTAssertNil(store.lastPendingMessage(forConversation: "testConversationID"))
        XCTAssertNotNil(store.lastPendingMessage(forConversation: "testConversationID2")?.uniqueId())
    }
    
    func testPersistence() {
        let store = ChatDataStore(storeId: "test-store")
        store.consumerAccountId = "ConsumerAccountId-TEST1"

        let control = BooleanControlMessage.exampleInstance()
        store.storeControlData(control, forConversation: "testConversationID", fromChat: chatterbox!)

        do {
            try store.store()
            
            store.consumerAccountId = "NA"
            
            let ids = try store.load()
            
            XCTAssertEqual("ConsumerAccountId-TEST1", store.consumerAccountId)
            XCTAssertEqual(1, ids?.count)
            XCTAssertEqual("testConversationID", ids?[0])
        } catch _ {
            XCTAssert(false)
        }
    }
}
