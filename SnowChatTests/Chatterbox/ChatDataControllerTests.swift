//
//  ChatDtaControllerTests.swift
//  SnowChatTests
//
//  Created by Marc Attinasi on 1/5/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import Foundation
import XCTest
@testable import SnowChat

class DataControllerTests: XCTestCase, ViewDataChangeListener {
    func controller(_ dataController: ChatDataController, didChangeData changes: [ModelChangeInfo]) {
        expectation?.fulfill()
    }
    
    func controllerDidLoadContent(_ dataController: ChatDataController) {
        
    }
    
    class MockChatterbox: Chatterbox {
        var updatedControl: CBControlData?
        var pendingControlMessage: CBControlData?
        
        init(instance: ServerInstance) {
            super.init(instance: instance)
        }
        
        override func lastPendingControlMessage(forConversation conversationId: String) -> CBControlData? {
            return pendingControlMessage
        }
        
        override func update(control: CBControlData) {
            updatedControl = control
        }
    }
    
    var expectation: XCTestExpectation?
    var controller: ChatDataController?
    var mockChatterbox: MockChatterbox?
   
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
    
    override func setUp() {
        mockChatterbox = MockChatterbox(instance: ServerInstance(instanceURL: URL(fileURLWithPath: "/")))
        controller = ChatDataController(chatterbox: mockChatterbox!)
        controller?.setChangeListener(self)

        mockChatterbox?.updatedControl = nil
    }
    
    override func tearDown() {
        
    }
    
    func testTestInitialization() {
        XCTAssertEqual(0, controller?.controlCount())
        XCTAssertNil(controller?.controlForIndex(0))
        XCTAssertNil(controller?.conversationId)
    }
    
    func testAddControl() {
        let boolMessage = BooleanControlMessage.exampleInstance()
        expectation = expectation(description: "Expect model changed delegate to be called")
        
        controller?.chatterbox(mockChatterbox!, didReceiveBooleanData: boolMessage, forChat: "chatID")
        
        // Adding controls is buffered, so have to use an expectation to wait for it to be accessible
        wait(for: [expectation!], timeout: 5)

        // test a control is saved
        XCTAssertEqual(1, controller?.controlCount())
        // test that the control is of the correct type
        XCTAssertEqual(ControlType.boolean, controller?.controlForIndex(0)?.controlModel.type)
        // test the control model has a new ID
        XCTAssertNotEqual(boolMessage.uniqueId(), controller?.controlForIndex(0)?.controlModel.id)
        // test the ChatMessageData has the correct direction
        XCTAssertEqual(BubbleLocation(direction: MessageDirection.fromServer), controller?.controlForIndex(0)?.location)
    }
    
    func startConversationAndUpdateBooleanControl() -> String {
        // mimic a started conversation
        let startTopicMessage = CBDataFactory.actionFromJSON(jsonStartedTopic) as! StartedUserTopicMessage
        controller?.topicDidStart(startTopicMessage)

        // first add the initial boolean message as if it came from Chatterbox
        let boolMessage = BooleanControlMessage.exampleInstance()
        controller?.chatterbox(mockChatterbox!, didReceiveBooleanData: boolMessage, forChat: "chatID")
        mockChatterbox?.pendingControlMessage = boolMessage
        
        // now update it
        let modelChanged = BooleanControlViewModel(id: CBData.uuidString(), label: "", required: true, resultValue: true)
        controller?.updateControlData(modelChanged)
        return modelChanged.id
    }

    func testUpdateControl() {
        let id = startConversationAndUpdateBooleanControl()
        
        // make sure chattertbox got it
        XCTAssertEqual(CBControlType.boolean, mockChatterbox?.updatedControl!.controlType)
        XCTAssertEqual(id, mockChatterbox?.updatedControl!.id)
    }
    
    func testBooleanUpdateRendersTwoTextControls() {
        let _ = startConversationAndUpdateBooleanControl()
        
        // now mimic chatterbox sending out the notification of the update
        let booleanMessage = mockChatterbox?.pendingControlMessage
        var me = MessageExchange(withMessage: booleanMessage!)
        me.response = mockChatterbox?.updatedControl
        
        controller?.chatterbox(mockChatterbox!, didCompleteBooleanExchange: me, forChat: "ChatID")
        
        // make sure there are 2 controls, 1 typing indicatior and 2 of type text
        XCTAssertEqual(2, controller?.controlCount())
        XCTAssertEqual(ControlType.text, controller?.controlForIndex(0)?.controlModel.type)
        XCTAssertEqual(ControlType.text, controller?.controlForIndex(1)?.controlModel.type)
        
        // make sure the label and value are correct
        let label = (booleanMessage as! BooleanControlMessage).data.richControl?.uiMetadata?.label
        let value = "Yes"
        XCTAssertEqual(value, (controller?.controlForIndex(0)?.controlModel as! TextControlViewModel).value)
        XCTAssertEqual(label, (controller?.controlForIndex(1)?.controlModel as! TextControlViewModel).value)

    }
}

