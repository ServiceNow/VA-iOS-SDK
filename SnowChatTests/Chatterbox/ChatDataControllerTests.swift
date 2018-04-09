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
    func controllerWillLoadContent(_ dataController: ChatDataController) {
    }
    
    func controlllerDidLoadContent(_ dataController: ChatDataController) {
        expectation?.fulfill()
    }
    
    func controller(_ dataController: ChatDataController, didChangeModel changes: [ModelChangeType]) {
        expectation?.fulfill()
    }
    
    func controllerDidLoadContent(_ dataController: ChatDataController) {
        
    }
    
    class MockChatterbox: Chatterbox {
        var updatedControl: ControlData?
        var pendingControlMessage: ControlData?
        
        override func lastPendingControlMessage(forConversation conversationId: String) -> ControlData? {
            return pendingControlMessage
        }
        
        override func update(control: ControlData) {
            updatedControl = control
        }
        
        override func currentConversationHasControlData(forId messageId: String) -> Bool {
            return true
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
        let boolMessage = ExampleData.exampleBooleanControlMessage()
        expectation = expectation(description: "Expect model changed delegate to be called")
        
        controller?.chatterbox(mockChatterbox!, didReceiveControlMessage: boolMessage, forChat: "chatID")
        
        // Adding controls is buffered, so have to use an expectation to wait for it to be accessible
        wait(for: [expectation!], timeout: 5)

        // test a control is saved
        XCTAssertEqual(1, controller?.controlCount())
        // test that the control is of the correct type
        XCTAssertEqual(ControlType.boolean, controller?.controlForIndex(0)?.controlModel?.type)
        // test the control model has the same ID
        XCTAssertEqual(boolMessage.messageId, controller?.controlForIndex(0)?.controlModel?.id)
        // test the ChatMessageData has the correct direction
        XCTAssertEqual(BubbleLocation(direction: MessageDirection.fromServer), controller?.controlForIndex(0)?.bubbleLocation)
    }
    
    func testEndTopicDivider() {
        XCTAssertEqual(0, controller?.controlCount())
        startConversation()
        XCTAssertEqual(2, controller?.controlCount())
        
        endConversation()
        XCTAssertEqual(2, controller?.controlCount())
        
        XCTAssertEqual(ChatMessageType.topicDivider, controller?.controlForIndex(0)?.type)
        XCTAssertEqual(ChatMessageType.control, controller?.controlForIndex(1)?.type)
        XCTAssertEqual(ControlType.text, controller?.controlForIndex(1)?.controlModel?.type)
    }
    
    func startConversation() {
        // mimic a started conversation
        let topicInfo = TopicInfo(topicId: "f0760de6733a0300d63a566a4cf6a7b6", topicName: "Topic Name", taskId: nil, conversationId: "f0760de6733a0300d63a566a4cf6a7b6")
        controller?.topicDidStart(topicInfo)
    }
    
    func endConversation() {
        controller?.topicDidFinish()
    }
    
    func startConversationAndUpdateBooleanControl() {
        startConversation()
        
        // first add the initial boolean message as if it came from Chatterbox
        let boolMessage = ExampleData.exampleBooleanControlMessage()
        controller?.chatterbox(mockChatterbox!, didReceiveControlMessage: boolMessage, forChat: "chatID")
        mockChatterbox?.pendingControlMessage = boolMessage
        
        // now update it
        let modelChanged = BooleanControlViewModel(id: boolMessage.messageId, label: "", required: true, resultValue: true)
        controller?.updateControlData(modelChanged)
    }

    func testUpdateControl() {
        startConversationAndUpdateBooleanControl()
        
        // make sure chattertbox got it
        XCTAssertEqual(ChatterboxControlType.boolean, mockChatterbox?.updatedControl!.controlType)
    }
    
    func testBooleanUpdateRendersTwoTextControls() {
        startConversationAndUpdateBooleanControl()
        
        let initialCount = controller?.controlCount()
        
        // now mimic chatterbox sending out the notification of the update
        let booleanMessage = mockChatterbox?.pendingControlMessage
        var me = MessageExchange(withMessage: booleanMessage!)
        me.response = mockChatterbox?.updatedControl
        
        controller?.chatterbox(mockChatterbox!, didCompleteMessageExchange: me, forChat: "ChatID")
        
        // make sure 2 controls were added
        XCTAssertEqual(initialCount! + 2, controller?.controlCount())
        XCTAssertEqual(ControlType.text, controller?.controlForIndex(1)?.controlModel?.type)
        XCTAssertEqual(ControlType.text, controller?.controlForIndex(2)?.controlModel?.type)
        
        // typing indicator gets put as first control after a response is entered
        XCTAssertEqual(ControlType.typingIndicator, controller?.controlForIndex(0)?.controlModel?.type)

        // make sure the label and value are correct
        let label = (booleanMessage as! BooleanControlMessage).data.richControl?.uiMetadata?.label
        let value = "Yes"
        XCTAssertEqual(value, (controller?.controlForIndex(1)?.controlModel as! TextControlViewModel).value)
        XCTAssertEqual(label, (controller?.controlForIndex(2)?.controlModel as! TextControlViewModel).value)

    }
}

