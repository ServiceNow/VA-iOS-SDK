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
    
    func testDidReceiveControlMessage() {
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
        
        // should have topic title only
        XCTAssertEqual(1, controller?.controlCount())
        
        endConversation {
            XCTAssertEqual(2, self.controller?.controlCount())
            
            XCTAssertEqual(ChatMessageType.topicDivider, self.controller?.controlForIndex(0)?.type)
            XCTAssertEqual(ChatMessageType.control, self.controller?.controlForIndex(1)?.type)
            XCTAssertEqual(ControlType.text, self.controller?.controlForIndex(1)?.controlModel?.type)
        }
    }
    
    func startConversation() {
        // mimic a started conversation
        let topicInfo = TopicInfo(topicId: "f0760de6733a0300d63a566a4cf6a7b6", topicName: "Topic Name", taskId: nil, conversationId: "f0760de6733a0300d63a566a4cf6a7b6")
        controller?.topicDidStart(topicInfo)
    }
    
    func endConversation(_ completion: @escaping () -> Void) {
        controller?.topicDidFinish(completion)
    }
    
    func startConversationAndUpdateBooleanControl() {
        startConversation()
        
        // first add the initial boolean message as if it came from Chatterbox
        let boolMessage = ExampleData.exampleBooleanControlMessage()
        controller?.chatterbox(mockChatterbox!, didReceiveControlMessage: boolMessage, forChat: "chatID")
        mockChatterbox?.pendingControlMessage = boolMessage
        
        // now update it
        let modelChanged = BooleanControlViewModel(id: boolMessage.messageId, label: "", required: true, resultValue: true, messageDate: Date())
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
    
    func testDateRendersTextAndHasAuxiliary() {
        startConversation()

        let initialCount = controller?.controlCount()
        controller?.isBufferingEnabled = false
        
        let dateMessage = ExampleData.exampleDateControlMessage()
        
        controller?.chatterbox(mockChatterbox!, didReceiveControlMessage: dateMessage, forChat: "chatID")

        // make sure the text control is added
        XCTAssertEqual(initialCount! + 1, controller?.controlCount())
        XCTAssertEqual(ControlType.text, controller?.controlForIndex(1)?.controlModel?.type)
        
        let chatMessage = controller?.controlData[0]
        let controlModel = chatMessage?.controlModel as! TextControlViewModel
        XCTAssertEqual("date?", controlModel.value)
      
        // actual date picker is created in the ConversationViewController layer based on the underlying model
        // - this just tests that that logic is correct for getting the auxiliary model
        let auxiliaryModel = ChatMessageModel.auxiliaryModel(withMessage: dateMessage, theme: Theme(dictionary:[:]))
        XCTAssertNotNil(auxiliaryModel)
        XCTAssertTrue(auxiliaryModel!.isAuxiliary)
        XCTAssertEqual(auxiliaryModel?.controlModel?.type, .date)
        XCTAssertEqual(auxiliaryModel?.controlModel?.label, "date?")
    }
}

