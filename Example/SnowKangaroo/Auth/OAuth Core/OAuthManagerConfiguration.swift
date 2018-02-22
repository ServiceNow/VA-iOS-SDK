//
//  OAuthManagerConfiguration.swift
//  SnowKangaroo
//
//  Created by Will Lisac on 2/16/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import Foundation

struct OAuthManagerConfiguration {
    let tokenURL: URL
    let clientId: String
    let clientSecret: String
    let defaultScope: String?
}
