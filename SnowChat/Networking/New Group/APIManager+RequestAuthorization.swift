//
//  APIManager+RequestAuthorization.swift
//  SnowChat
//
//  Created by Will Lisac on 2/22/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import Foundation
import Alamofire

extension APIManager {
    
    func authorizedWebViewInitialRequest(with url: URL) -> URLRequest {
        let request = URLRequest(url: url)
        
        guard let authorizedRequest = (try? sessionManager.adapter?.adapt(request)) as? URLRequest else {
            return request
        }
        
        return authorizedRequest
    }
    
}
