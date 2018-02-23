//
//  HTTPURLResponse+Auth.swift
//  SnowChat
//
//  Created by Will Lisac on 2/16/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import Foundation

extension HTTPURLResponse {
    
    private func value(forHTTPHeaderField field: String) -> String? {
        return allHeaderFields[field] as? String
    }
    
    var userTokenResponse: String? {
        guard let userTokenResponse = value(forHTTPHeaderField: HTTPHeaderField.userTokenResponse),
            !userTokenResponse.isEmpty else {
                return nil
        }
        return userTokenResponse
    }
    
    // We intentionally ignore X-UserToken-AllowResubmit and X-AutoResubmit
    // See PRB654843 for details
    // TODO: Should we try and find a way to honor these flags?
    var shouldResubmitUserToken: Bool {
        // Only resubmit if we're logged in
        guard let isLoggedInValue = value(forHTTPHeaderField: HTTPHeaderField.isLoggedIn),
            let isLoggedIn = Bool(isLoggedInValue), isLoggedIn else {
                return false
        }
        
        // Only resubmit if we have a new response token that's different from the request token
        guard let userTokenResponse = userTokenResponse else { return false }
        
        let userRequestToken = value(forHTTPHeaderField: HTTPHeaderField.userTokenRequest)
        
        let shouldResubmit = userTokenResponse != userRequestToken
        
        return shouldResubmit
    }
}
