//
//  CBDataFactory.swift
//  SnowChat
//
//  Created by Marc Attinasi on 11/15/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import Foundation

class CBDataFactory {
    
    static func controlFromJSON(_ json: String) -> CBControlData {
        var data: CBControlData = CBControlDataUnknown()
        
        if let jsonData = json.data(using: .utf8) {
            do {
                if let dict = try JSONSerialization.jsonObject(with: jsonData, options: JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary {
                    guard let t = dict["type"] as? String else {
                        return data
                    }
                    
                    switch t {
                    case CBControlType.controlBoolean.rawValue:
                        if let value = dict["value"] as? Int {
                            data = CBBooleanData(withId: "foo", withValue: value == 0 ? false : true)
                        }
                    
                    case CBControlType.controlDate.rawValue:
                        if let value = dict["value"] as? TimeInterval {
                            data = CBDateData(withId: "foo", withValue: Date(timeIntervalSinceReferenceDate: value))
                        }
                        
                    case CBControlType.controlInput.rawValue:
                        if let value = dict["value"] as? String {
                            data = CBInputData(withId: "foo", withValue: value)
                        }

                    default:
                        break
                    }
                }
            } catch let parseError {
                print(parseError)
            }
        }
        return data
    }
    
    static func channelEventFromJSON(_ json: String) -> CBChannelEventData {
        var data: CBChannelEventData = CBChannelEventUnknownData()
        
        if let jsonData = json.data(using: .utf8) {
            do {
                if let dict = try JSONSerialization.jsonObject(with: jsonData, options: JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary {
                    guard let t = dict["type"] as? String else {
                        return data
                    }
                    
                    if let err = dict["error"] as? Int {
                        switch t {
                        case CBChannelEvent.channelOpen.rawValue:
                            data = CBChannelOpenData(error: err)
                        case CBChannelEvent.channelClose.rawValue:
                            data = CBChannelOpenData(error: err)
                        case CBChannelEvent.channelRefresh.rawValue:
                            data = CBChannelOpenData(error: err)
                        default:
                            break
                        }
                    }
                }
            } catch let parseError {
                print(parseError)
            }
        }
        
        return data
    }
}
