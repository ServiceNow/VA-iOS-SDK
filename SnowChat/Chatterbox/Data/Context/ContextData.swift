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
    var cameraPermission: Bool?
    var photoPermission: Bool?
    var userData: Codable?
    
    init() {
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: ContextItemType.self)
        self.location = try container.decodeIfPresent(LocationContextData.self, forKey: .location)
        self.appVersion = try container.decodeIfPresent(String.self, forKey: .appVersion)
        self.deviceTimeZone = try container.decodeIfPresent(String.self, forKey: .deviceTimeZone)
        self.deviceType = try container.decodeIfPresent(String.self, forKey: .deviceType)
        self.mobileOS = try container.decodeIfPresent(String.self, forKey: .mobileOS)
        self.photoPermission = try container.decodeIfPresent(Bool.self, forKey: .photoPermission)
        self.cameraPermission = try container.decodeIfPresent(Bool.self, forKey: .cameraPermission)
        // TODO: Do we need to decode userData? I dont think so..
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: ContextItemType.self)
        try container.encodeIfPresent(location, forKey: .location)
        try container.encodeIfPresent(appVersion, forKey: .appVersion)
        try container.encodeIfPresent(deviceTimeZone, forKey: .deviceTimeZone)
        try container.encodeIfPresent(deviceType, forKey: .deviceType)
        try container.encodeIfPresent(mobileOS, forKey: .mobileOS)
        try container.encodeIfPresent(cameraPermission, forKey: .cameraPermission)
        try container.encodeIfPresent(photoPermission, forKey: .photoPermission)
        try userData?.encode(to: encoder)
    }
}

// MARK: Location

struct LocationContextData: Codable {
    var latitude: Double?
    var longitude: Double?
    var address: String?
    
    private enum LocationCodingKeys: String, CodingKey {
        case latitude = "lat"
        case longitude = "lng"
        case address = "address"
    }
}
