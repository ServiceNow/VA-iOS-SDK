//
//  HTTPHeaders+Auth.swift
//  SnowChat
//
//  Created by Will Lisac on 2/16/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import Foundation

enum HTTPHeaderField {
    
    static let userToken = "X-UserToken"
    static let userTokenRequest = "X-UserToken-Request"
    static let userTokenResponse = "X-UserToken-Response"
    
    static let authorizeByCookieFirst = "X-AuthorizeByCookieFirst"
    static let isLoggedIn = "X-Is-Logged-In"
    
    static let authorization = "Authorization"
    
    static let endUser = "X-End-User"
    
}
