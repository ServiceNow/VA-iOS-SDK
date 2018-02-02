//
//  LoggerTests.swift
//  SnowChatTests
//
//  Created by Marc Attinasi on 11/20/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import XCTest
@testable import SnowChat

class LoggerTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testDefaultLog() {
        XCTAssertEqual("com.servicenow.SnowChat", Logger.default.domain)
        XCTAssertEqual("default", Logger.default.category)
        
        Logger.default.logInfo("Info Log Message")
        Logger.default.logDebug("Debug Log Message")
        Logger.default.logError("Error Log Message")
        Logger.default.logFatal("Fatal Log Message")
        
        Logger.default.logLevel = .error
        Logger.default.logInfo("Info Log Message - should not see")
        Logger.default.logDebug("Debug Log Message - should not see")
        Logger.default.logError("Error Log Message")
        Logger.default.logFatal("Fatal Log Message")
    }
    
    func testCustomLogger() {
        let logger = Logger.logger(for: "TestCategory")
        XCTAssert(logger.category == "TestCategory")
        
        let logger2 = Logger.logger(for: "TestCategory")
        XCTAssert(logger.domain == logger2.domain)
        XCTAssert(logger.osLogger.description == logger2.osLogger.description)
        
        logger.logDebug("Test TestCategory Debug Log Message")
    }
}
