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
                let dict = try JSONSerialization.jsonObject(with: jsonData, options: JSONSerialization.ReadingOptions.mutableContainers) as! NSDictionary
                let t = dict["type"] as! String
                
                switch t {
                case "booleanControl":
                    let value = dict["value"] as! Int
                    data = CBBooleanData(withId: "foo", withValue: value == 0 ? false : true)
                default:
                    break
                }
                
            } catch let parseError {
                print(parseError)
            }
        }
        return data
    }
    
    static func channelEventFromJSON(_ json: String) -> CBChannelEventData {
        let data: CBChannelEventData = CBChannelEventUnknownData()
        
        return data
    }
}
