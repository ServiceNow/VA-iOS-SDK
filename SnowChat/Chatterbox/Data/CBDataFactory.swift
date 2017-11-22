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
        
        if let jsonData = json.data(using: .utf8) {
            do {
                let uiMessage = try CBData.jsonDecoder.decode(ConsumerTextMessage.self, from: jsonData)
                let t = uiMessage.data.richControl.uiType
                
                switch t {
                case CBControlType.controlBoolean.rawValue:
                    return try CBData.jsonDecoder.decode(BooleanControlMessage.self, from: jsonData)
                default:
                    Logger.default.logError("Unrecognized UI Control: \(t)")
                }
                
//                if let dict = try JSONSerialization.jsonObject(with: jsonData, options: JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary {
//                    guard let t = dict["type"] as? String else {
//                        return data
//                    }
//
//                    switch t {
//                    case CBControlType.controlBoolean.rawValue:
//                        if let value = dict["value"] as? Int {
//                            data = CBBooleanData(withId: "foo", withValue: value == 0 ? false : true)
//                        }
//
//                    case CBControlType.controlDate.rawValue:
//                        if let value = dict["value"] as? TimeInterval {
//                            data = CBDateData(withId: "foo", withValue: Date(timeIntervalSinceReferenceDate: value))
//                        }
//
//                    case CBControlType.controlInput.rawValue:
//                        if let value = dict["value"] as? String {
//                            data = CBInputData(withId: "foo", withValue: value)
//                        }
//
//                    default:
//                        break
//                    }
//                }
            } catch let parseError {
                print(parseError)
            }
        }
        return CBControlDataUnknown()
    }
    
    static func channelEventFromJSON(_ json: String) -> CBChannelEventData {
         
        if let jsonData = json.data(using: .utf8) {
            do {
                let actionMessage = try CBData.jsonDecoder.decode(ActionMessage.self, from: jsonData)
                let t = actionMessage.data.actionMessage.type
                
                switch t {
                case CBChannelEvent.channelInit.rawValue:
                    return try CBData.jsonDecoder.decode(InitMessage.self, from: jsonData)
                default:
                    Logger.default.logError("Unrecognized ActionMessage type: \(t)")
                }
                
            } catch let decodeError {
                print(decodeError)
            }
        }
        
        return CBChannelEventUnknownData()
    }
}
