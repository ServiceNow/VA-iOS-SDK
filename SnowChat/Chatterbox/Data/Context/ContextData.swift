//
//  ContextData.swift
//  SnowChat
//
//  Created by Michael Borowiec on 3/1/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

struct ContextData: Encodable {
    var location: ContextItem?
    var appVersion: ContextItem?
    var deviceTimeZone: ContextItem?
    var deviceType: ContextItem?
    var cameraPermission: ContextItem?
    var photoPermission: ContextItem?
    var mobileOS: ContextItem?
    
    func encode(to encoder: Encoder) throws {
        
    }
}

// MARK: Location

struct LocationContextData: Encodable {
    var latitude: Double?
    var longitude: Double?
    var address: String?
    
    private enum CodingKeys: String, CodingKey {
        case latitude = "lat"
        case longitude = "lng"
        case address = "address"
    }
}

enum AppVersion: String, Encodable {
    case value
}

enum DeviceTimeZone: String, Encodable {
    case value = "deviceTimeZone"
}
