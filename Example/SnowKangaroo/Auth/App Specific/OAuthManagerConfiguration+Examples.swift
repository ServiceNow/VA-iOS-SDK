//
//  OAuthManagerConfiguration+Examples.swift
//  SnowKangaroo
//
//  Created by Will Lisac on 2/16/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import Foundation

extension OAuthManagerConfiguration {

    static let oktaExample: OAuthManagerConfiguration = {
        // swiftlint:disable:next force_unwrapping
        let tokenURL = URL(string: "https://dev-446994.oktapreview.com/oauth2/default/v1/token")!
        
        return OAuthManagerConfiguration(tokenURL: tokenURL,
                                         clientId: "0oae1yyznkjC5ZR4B0h7",
                                         clientSecret: "SqcRccsZeiLhd0VtJNDk9zryWbZXwQrdJfQ7Colz",
                                         defaultScope: "openid offline_access profile",
                                         requireIdToken: true)
    }()

    static func serviceNowVirtualAgentExample(instanceURL: URL) -> OAuthManagerConfiguration {
        let tokenURL = instanceURL.appendingPathComponent("oauth_token.do")
        
        return OAuthManagerConfiguration(tokenURL: tokenURL,
                                         clientId: "2c403f19ac901300b303eef6c8b842d3",
                                         clientSecret: "H&g(T!4<6Y",
                                         defaultScope: nil,
                                         requireIdToken: false)
    }
    
}
