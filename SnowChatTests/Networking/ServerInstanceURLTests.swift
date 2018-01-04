//
//  ServerInstanceURLTests.swift
//  SnowChatTests
//
//  Created by Will Lisac on 1/4/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import XCTest
@testable import SnowChat

class ServerInstanceURLTests: XCTestCase {
    
    func testURLParsing() {
        XCTAssertNil(ServerInstance.instanceURL(fromUserInput: ""))
        
        XCTAssertEqual(ServerInstance.instanceURL(fromUserInput: "playground"),
                       URL(string: "https://playground.service-now.com"))
        
        XCTAssertEqual(ServerInstance.instanceURL(fromUserInput: "will.local:8080"),
                       URL(string: "http://will.local:8080"))
        
        XCTAssertEqual(ServerInstance.instanceURL(fromUserInput: "playground.service-now.com"),
                       URL(string: "https://playground.service-now.com"))
        
        XCTAssertEqual(ServerInstance.instanceURL(fromUserInput: "https://playground.service-now.com"),
                       URL(string: "https://playground.service-now.com"))
        
        XCTAssertEqual(ServerInstance.instanceURL(fromUserInput: "google.com"),
                       URL(string: "https://google.com"))
        
        XCTAssertEqual(ServerInstance.instanceURL(fromUserInput: "http://localhost:8080"),
                       URL(string: "http://localhost:8080"))
        
        XCTAssertEqual(ServerInstance.instanceURL(fromUserInput: "localhost:8080"),
                       URL(string: "http://localhost:8080"))
    }
    
}
