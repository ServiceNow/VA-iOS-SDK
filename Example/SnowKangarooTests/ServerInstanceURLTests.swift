//
//  ServerInstanceURLTests.swift
//  SnowKangarooTests
//
//  Created by Will Lisac on 2/6/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import XCTest
@testable import SnowKangaroo

class ServerInstanceURLTests: XCTestCase {
    
    func testURLParsing() {

        XCTAssertNil(URL(serverInstanceString: ""))

        XCTAssertEqual(URL(serverInstanceString: "playground"),
                       URL(string: "https://playground.service-now.com"))

        XCTAssertEqual(URL(serverInstanceString: "will.local:8080"),
                       URL(string: "http://will.local:8080"))

        XCTAssertEqual(URL(serverInstanceString: "playground.service-now.com"),
                       URL(string: "https://playground.service-now.com"))

        XCTAssertEqual(URL(serverInstanceString: "https://playground.service-now.com"),
                       URL(string: "https://playground.service-now.com"))

        XCTAssertEqual(URL(serverInstanceString: "google.com"),
                       URL(string: "https://google.com"))
        
        XCTAssertEqual(URL(serverInstanceString: "http://localhost:8080"),
                       URL(string: "http://localhost:8080"))

        XCTAssertEqual(URL(serverInstanceString: "localhost:8080"),
                       URL(string: "http://localhost:8080"))
    }
    
}
