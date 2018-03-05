//
//  ContextData.swift
//  SnowChat
//
//  Created by Michael Borowiec on 3/1/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

struct ContextData: Codable {
    var location: LocationContextData?
    var appVersion: String?
    var deviceTimeZone: String?
    var deviceType: String?
    var mobileOS: String?
    
    init() {
        self.location = nil
        self.appVersion = nil
        self.deviceType = nil
        self.deviceTimeZone = nil
        self.mobileOS = nil
    }
    
    init(from decoder: Decoder) throws {
        self.init()
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: ContextItemType.self)
        try container.encodeIfPresent(location, forKey: .location)
        try container.encodeIfPresent(appVersion, forKey: .appVersion)
        try container.encodeIfPresent(deviceTimeZone, forKey: .deviceTimeZone)
        try container.encodeIfPresent(deviceType, forKey: .deviceType)
        try container.encodeIfPresent(mobileOS, forKey: .mobileOS)
    }
}

// MARK: Location

struct LocationContextData: Encodable {
    var latitude: Double?
    var longitude: Double?
    var address: String?
    
    private enum LocationCodingKeys: String, CodingKey {
        case latitude = "lat"
        case longitude = "lng"
        case address = "address"
    }
}
