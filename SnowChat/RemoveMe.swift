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
        
        self.testAsync { (msg) in
            debugPrint(msg)
        }
    }
    
    public static func testAsync( responseHandler: @escaping (String) -> Void ) {
        debugPrint("Testing Async")
        
        let dataRequest = Alamofire.request("https://httpbin.org/get")
        dataRequest.responseData { response in
            debugPrint("All Response Info: \(response)")
            
            if let data = response.result.value, let utf8Text = String(data: data, encoding: .utf8) {
                responseHandler(utf8Text)
            }
        }
    }
    
}
