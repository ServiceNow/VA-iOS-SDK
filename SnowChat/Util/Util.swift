//
//  Util.swift
//  SnowChat
//
//  Created by Marc Attinasi on 12/4/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import Foundation

public func getDeviceId() -> String {
    let id = UIDevice.current.identifierForVendor ?? UUID()
    return id.uuidString
}
