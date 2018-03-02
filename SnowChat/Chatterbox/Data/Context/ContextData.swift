//
//  ContextData.swift
//  SnowChat
//
//  Created by Michael Borowiec on 3/1/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

struct ContextData: Encodable {
    var location: LocationContextData?
    var appVersion: String?
    var deviceTimeZone: String?
    var deviceType: String?
    var mobileOS: String?
    
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
