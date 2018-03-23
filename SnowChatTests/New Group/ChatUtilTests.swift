//
//  ChatUtilTests.swift
//  SnowChatTests
//
//  Created by Marc Attinasi on 3/22/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import XCTest

@testable import SnowChat

protocol TestListener: AnyObject {
    func increment()
}

class ChatUtilTests: XCTestCase {
    
    class TestListenerClass: TestListener {
        var count = 0
        
        func increment() {
            count += 1
        }
    }
    
    public func testListenerListExplicitRemove() {
        let listeners = ListenerList<AnyObject>()
        let listener1: TestListenerClass? = TestListenerClass()
        let listener2: TestListenerClass? = TestListenerClass()
        
        listeners.addListener(listener1!)
        XCTAssertEqual(1, listeners.count)
        listeners.addListener(listener2!)
        XCTAssertEqual(2, listeners.count)
        
        var count = 0
        listeners.forEach(withType: TestListener.self) { (listener) in
            count += 1
            listener.increment()
        }
        XCTAssertEqual(2, count)
        XCTAssertEqual(1, listener1?.count)
        XCTAssertEqual(1, listener2?.count)
        
        listeners.removeListener(listener1!)
        XCTAssertEqual(1, listeners.count)
        listeners.forEach(withType: TestListener.self) { (listener) in
            count += 1
            listener.increment()
        }
        XCTAssertEqual(3, count)
        XCTAssertEqual(1, listener1?.count)
        XCTAssertEqual(2, listener2?.count)
        
        listeners.removeListener(listener2!)
        XCTAssertEqual(0, listeners.count)
        listeners.forEach(withType: TestListener.self) { (listener) in
            count += 1
            listener.increment()
        }
        XCTAssertEqual(3, count)
        XCTAssertEqual(1, listener1?.count)
        XCTAssertEqual(2, listener2?.count)
    }
    
    public func testListenerListImplicitRemove() {
        let listeners = ListenerList<AnyObject>()
        var listener1: TestListenerClass? = TestListenerClass()
        var listener2: TestListenerClass? = TestListenerClass()

        listeners.addListener(listener1!)
        listeners.addListener(listener2!)
        XCTAssertEqual(2, listeners.count)
        
        var count = 0
        listeners.forEach(withType: TestListener.self) { (listener) in
            count += 1
            listener.increment()
        }
        XCTAssertEqual(2, count)
        XCTAssertEqual(1, listener1?.count)
        XCTAssertEqual(1, listener2?.count)
        
        listener1 = nil
        XCTAssertEqual(1, listeners.count)
        listeners.forEach(withType: TestListener.self) { (listener) in
            count += 1
            listener.increment()
        }
        XCTAssertEqual(3, count)
        XCTAssertEqual(2, listener2?.count)

        listener2 = nil
        XCTAssertEqual(0, listeners.count)
        listeners.forEach(withType: TestListener.self) { (listener) in
            count += 1
            listener.increment()
        }
        XCTAssertEqual(3, count)

    }
    
    public func testListenerInvalidRemove() {
        let listeners = ListenerList<AnyObject>()
        let listener1: TestListenerClass? = TestListenerClass()
        let listener2: TestListenerClass? = TestListenerClass()
        
        listeners.addListener(listener1!)
        XCTAssertEqual(1, listeners.count)
        
        listeners.removeListener(listener2!)
        XCTAssertEqual(1, listeners.count)
    }
}
