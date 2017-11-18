//
//  CBDataTests.swift
//  SnowChatTests
//
//  Created by Marc Attinasi on 11/15/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import XCTest
@testable import SnowChat

class TestControlData: CBControlData {
    let id: String
    let controlType: CBControlType
    
    init() {
        id = "123"
        controlType = .controlTypeUnknown
    }
}

class CBDataTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testControlDataInit() {
        let cd = TestControlData()
        XCTAssert(cd.id == "123")
        XCTAssert(cd.controlType == .controlTypeUnknown)
    }
    
    func testBooleanDataInit() {
        let bc = CBBooleanData(withId: "123", withValue: true)
        XCTAssert(bc.id == "123")
        XCTAssert(bc.controlType == .controlBoolean)
        XCTAssert(bc.value == true)
    }
    
    func testDateDataInit() {
        let date = Date()
        let bc = CBDateData(withId: "123", withValue: date)
        XCTAssert(bc.id == "123")
        XCTAssert(bc.controlType == .controlDate)
        XCTAssert(bc.value == date)
    }
    
    func testInputDataInit() {
        let input = "Where is my money?"
        let bc = CBInputData(withId: "123", withValue: input)
        XCTAssert(bc.id == "123")
        XCTAssert(bc.controlType == .controlInput)
        XCTAssert(bc.value == input)
    }
    
    func testChannelEvent() {
        let data = CBChannelRefreshData(error: 0, status: 100)
        XCTAssert(data.eventType == .channelRefresh)
        XCTAssert(data.error == 0)
        XCTAssert(data.status == 100)
    }
    
    func testBooleanFromJSON() {
        let json = "{\"type\":\"booleanControl\",\"value\":0}"
        let obj = CBDataFactory.controlFromJSON(json)
        XCTAssertNotNil(obj)
        XCTAssert(obj.controlType == .controlBoolean)
        let boolObj = obj as! CBBooleanData
        XCTAssert(boolObj.value == false)
    }
    
    func testDateFromJSON() {
        let date = Date()
        let json = "{\"type\":\"dateControl\",\"value\":\(date.timeIntervalSinceReferenceDate)}"
        let obj = CBDataFactory.controlFromJSON(json)
        XCTAssertNotNil(obj)
        XCTAssert(obj.controlType == .controlDate)
        let dateObj = obj as! CBDateData
        XCTAssert(dateObj.value == date)
    }
    
    func testInputFromJSON() {
        let val = "Are we not men?"
        let json = "{\"type\":\"inputControl\",\"value\":\"\(val)\"}"
        var obj = CBDataFactory.controlFromJSON(json)
        XCTAssertNotNil(obj)
        XCTAssert(obj.controlType == .controlInput)
        let inputObj = obj as! CBInputData
        XCTAssert(inputObj.value == val)
        
        let badJson = "{\"type\":\"inputControl\",\"value(*&\":false}"
        obj = CBDataFactory.controlFromJSON(badJson)
        XCTAssertNotNil(obj)
        XCTAssert(obj.controlType == .controlTypeUnknown)
        let unknownObj = obj as? CBControlDataUnknown
        XCTAssert(unknownObj != nil)
    }
    
    func testInvalidTypeFromJSON() {
        let val = "WTF?"
        let json = "{\"typo\":\"unknownControl\",\"value\":\"\(val)\"}"
        let obj = CBDataFactory.controlFromJSON(json)
        XCTAssertNotNil(obj)
        XCTAssert(obj.controlType == .controlTypeUnknown)
        let inputObj = obj as? CBControlDataUnknown
        XCTAssertNotNil(inputObj)
    }
    
}
