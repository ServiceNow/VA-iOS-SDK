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
    
    func testOutputImageControlModel() {
        let multiPartOutputImageControlMessage = ExampleData.multiPartOutputImageControlMessage()
        let chatMessageModel = ChatMessageModel.model(withMessage: multiPartOutputImageControlMessage, theme: theme)
        
        XCTAssertNotNil(chatMessageModel?.controlModel)
        
        let controlModel = chatMessageModel!.controlModel
        XCTAssertTrue(controlModel?.type == .outputImage)
        
        let imageControlModel = controlModel as! OutputImageViewModel
        // TODO: to do!
    }
    
    func testOutputTextControlModel() {
        let multiPartOutputTextControlMessage = ExampleData.multiPartOutputTextControlMessage()
        let chatMessageModel = ChatMessageModel.model(withMessage: multiPartOutputTextControlMessage, theme: theme)
        
        XCTAssertNotNil(chatMessageModel?.controlModel)
        
        let controlModel = chatMessageModel!.controlModel
        XCTAssertTrue(controlModel?.type == .text)
        
        let imageControlModel = controlModel as! TextControlViewModel
        // TODO: to do!
    }
    
    func testOutputLinkControlModel() {
        let multiPartOutputLinkControlMessage = ExampleData.multiPartOutputLinkControlMessage()
        let chatMessageModel = ChatMessageModel.model(withMessage: multiPartOutputLinkControlMessage, theme: theme)
        
        XCTAssertNotNil(chatMessageModel?.controlModel)
        
        let controlModel = chatMessageModel!.controlModel
        XCTAssertTrue(controlModel?.type == .outputLink)
        
        let imageControlModel = controlModel as! OutputLinkControl
        // TODO: to do!
    }
}
