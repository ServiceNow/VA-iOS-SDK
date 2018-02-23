//
//  OAuthManager+AuthProvider.swift
//  SnowKangaroo
//
//  Created by Will Lisac on 2/22/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import Foundation

extension OAuthManager {
    convenience init(authProvider: AuthProvider, instanceURL: URL) {
        switch authProvider {
        case .local:
            self.init(configuration: .serviceNowVirtualAgentExample(instanceURL: instanceURL))
        case .openID:
            self.init(configuration: .oktaExample)
        }
    }
}
