//
//  OAuthCredential.swift
//  SnowKangaroo
//
//  Created by Will Lisac on 2/7/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import Foundation

struct OAuthCredential: Codable {
    let accessToken: String
    let refreshToken: String?
    let tokenType: String
    let expiration: Date?
}

extension OAuthCredential {
    init?(dictionary: [String : Any]) {
        guard let accessToken = dictionary["access_token"] as? String,
            let tokenType = dictionary["token_type"] as? String else {
                return nil
        }
        
        let refreshToken = dictionary["refresh_token"] as? String
        
        let expiresIn = dictionary["expires_in"] as? TimeInterval
        let expiration = expiresIn.flatMap { Date(timeIntervalSinceNow: $0) }
        
        self.init(accessToken: accessToken, refreshToken: refreshToken, tokenType: tokenType, expiration: expiration)
    }
}
