//
//  AuthProvider.swift
//  SnowKangaroo
//
//  Created by Will Lisac on 2/22/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import Foundation

enum AuthProvider: String, Codable {
    case local
    case openID
}
