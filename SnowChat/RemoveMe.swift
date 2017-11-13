//
//  RemoveMe.swift
//  SnowChat
//
//  Created by Will Lisac on 11/12/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import Foundation
import Alamofire

public class RemoveMe {
    
    public static func test() {
        debugPrint("Testing")
        
        Alamofire.request("https://httpbin.org/get").responseData { response in
            debugPrint("All Response Info: \(response)")
            
            if let data = response.result.value, let utf8Text = String(data: data, encoding: .utf8) {
                print("Data: \(utf8Text)")
            }
        }
        
    }
    
}
