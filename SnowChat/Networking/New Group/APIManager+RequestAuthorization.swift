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
    
    func authorizedRESTRequest(with url: URL) -> URLRequest {
        let request = URLRequest(url: url)
        
        guard let authorizedRequest = (try? sessionManager.adapter?.adapt(request)) as? URLRequest else {
            return request
        }
        
        return authorizedRequest
    }
    
    func authorizedImageRequest(with url: URL) -> URLRequest {
        
        var urlRequest = authorizedRESTRequest(with: url)
        
        // for images, we clear the require-login header because we do not need
        // to restrict access to logged-in users, and because we likely
        // will not have a session to check if the user was logged-in as part
        // of the image request
        urlRequest.setValue(nil, forHTTPHeaderField: HTTPHeaderField.requireLoggedIn)
        
        return urlRequest
    }
}
