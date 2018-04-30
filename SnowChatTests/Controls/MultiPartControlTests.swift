//
//  MultiPartControlTests.swift
//  SnowChatTests
//
//  Created by Michael Borowiec on 4/30/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import XCTest
@testable import SnowChat

class MultiPartControlTests: XCTestCase {
    
    let theme = Theme()
    
    func testOutputHtmlControlModel() {
        let multiPartHtmlControlMessage = ExampleData.multiPartHtmlControlMessage()
        let chatMessageModel = ChatMessageModel.model(withMessage: multiPartHtmlControlMessage, theme: theme)
        
        XCTAssertNotNil(chatMessageModel?.controlModel)
        
        let controlModel = chatMessageModel!.controlModel
        XCTAssertTrue(controlModel?.type == .outputHtml)
        
        let htmlControlModel = controlModel as! OutputHtmlControlViewModel
        XCTAssertTrue(htmlControlModel.size?.width == UIViewNoIntrinsicMetric)
        XCTAssertTrue(htmlControlModel.size?.height == UIViewNoIntrinsicMetric)
    }
    
    func testOutputTextControlModel() {
        let multiPartOutputTextControlMessage = ExampleData.multiPartOutputTextControlMessage()
        let chatMessageModel = ChatMessageModel.model(withMessage: multiPartOutputTextControlMessage, theme: theme)
        
        XCTAssertNotNil(chatMessageModel?.controlModel)
        
        let controlModel = chatMessageModel!.controlModel
        XCTAssertTrue(controlModel?.type == .text)
        
        let textControlModel = controlModel as! TextControlViewModel
        XCTAssertTrue(textControlModel.value == "thing 1")
    }
    
    func testOutputImageControlModel() {
        let multiPartOutputImageControlMessage = ExampleData.multiPartOutputImageControlMessage()
        let chatMessageModel = ChatMessageModel.model(withMessage: multiPartOutputImageControlMessage, theme: theme)
        
        XCTAssertNotNil(chatMessageModel?.controlModel)
        
        let controlModel = chatMessageModel!.controlModel
        XCTAssertTrue(controlModel?.type == .outputImage)
        
        let imageControlModel = controlModel as! OutputImageViewModel
        XCTAssertTrue(imageControlModel.value.absoluteString == "https://images.pexels.com/photos/248797/pexels-photo-248797.jpeg%3Fauto=compress&cs=tinysrgb&dpr=2&h=750&w=1260")
    }
    
    func testOutputLinkControlModel() {
        let multiPartOutputLinkControlMessage = ExampleData.multiPartOutputLinkControlMessage()
        let chatMessageModel = ChatMessageModel.model(withMessage: multiPartOutputLinkControlMessage, theme: theme)
        
        XCTAssertNotNil(chatMessageModel?.controlModel)
        
        let controlModel = chatMessageModel!.controlModel
        XCTAssertTrue(controlModel?.type == .outputLink)
        
        let outputLinkControlModel = controlModel as! OutputLinkControlViewModel
        XCTAssertTrue(outputLinkControlModel.header == "blah")
        XCTAssertTrue(outputLinkControlModel.label == "https://google.com")
        XCTAssertTrue(outputLinkControlModel.value.absoluteString == "https://google.com")
    }
}
