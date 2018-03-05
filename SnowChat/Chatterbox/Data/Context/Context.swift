//
//  Context.swift
//  SnowChat
//
//  Created by Michael Borowiec on 3/1/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

struct ContextHandshake: Codable {
    var serverContextRequest: ServerContextRequest?
    var serverContextResponse: ServerContextResponse?
    var consumerAccountId: String?
    var deviceId: String?
    var vendorId: String?
    
    // define the properties that we decode / encode (note JSON name mapping)
    private enum CodingKeys: String, CodingKey {
        case serverContextRequest = "serverContextReq"
        case serverContextResponse = "serverContextResp"
        case consumerAccountId = "consumerAcctId"
        case deviceId
        case vendorId
    }
}

struct ContextItem: Codable {
    let updateType: ContextItemUpdateType
    let frequency: ContextItemFrequency
    var type = ContextItemType.location
    
    enum ContextItemUpdateType: String, Codable, CodingKey {
        case push
    }
    
    enum ContextItemFrequency: String, Codable, CodingKey {
        case once = "once"
        case everyMinute = "every minute"
        case everyHour = "every hour"
        case everyDay = "every day"
    }
    
    // define the properties that we decode / encode (note JSON name mapping)
    private enum CodingKeys: String, CodingKey {
        case updateType
        case frequency = "updateFrequency"
    }
}

enum ContextItemType: String {
    case location
    case appVersion = "MobileAppVersion"
    case deviceTimeZone
    case deviceType = "DeviceType"
    case cameraPermission = "permissionToUseCamera"
    case photoPermission = "permissionToUsePhoto"
    case mobileOS = "MobileOS"
}

// Enable Codable functionality
extension ContextItemType: CodingKey {}

struct ServerContextRequest: Codable {
    var location: ContextItem?
    var appVersion: ContextItem?
    var deviceTimeZone: ContextItem?
    var deviceType: ContextItem?
    var cameraPermission: ContextItem?
    var photoPermission: ContextItem?
    var mobileOS: ContextItem?
    
    private(set) var predefinedContextItems = [ContextItem]()
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: ContextItemType.self)
        
        var contextItem = try container.decode(ContextItem.self, forKey: .location)
        self.location = contextItem
        predefinedContextItems.append(contextItem)
        
        contextItem = try container.decode(ContextItem.self, forKey: .appVersion)
        self.appVersion = contextItem
        self.appVersion?.type = .appVersion
        predefinedContextItems.append(contextItem)
        
        contextItem = try container.decode(ContextItem.self, forKey: .deviceTimeZone)
        self.deviceTimeZone = contextItem
        self.deviceTimeZone?.type = .deviceTimeZone
        predefinedContextItems.append(contextItem)
        
        contextItem = try container.decode(ContextItem.self, forKey: .deviceType)
        self.deviceType = contextItem
        self.deviceType?.type = .deviceType
        predefinedContextItems.append(contextItem)
        
        contextItem = try container.decode(ContextItem.self, forKey: .cameraPermission)
        self.cameraPermission = contextItem
        self.cameraPermission?.type = .cameraPermission
        predefinedContextItems.append(contextItem)
        
        contextItem = try container.decode(ContextItem.self, forKey: .photoPermission)
        self.photoPermission = contextItem
        self.photoPermission?.type = .photoPermission
        predefinedContextItems.append(contextItem)
        
        contextItem = try container.decode(ContextItem.self, forKey: .mobileOS)
        self.mobileOS = contextItem
        self.mobileOS?.type = .mobileOS
        predefinedContextItems.append(contextItem)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: ContextItemType.self)
        try container.encode(location, forKey: .location)
        try container.encode(appVersion, forKey: .appVersion)
        try container.encode(deviceTimeZone, forKey: .deviceTimeZone)
        try container.encode(deviceType, forKey: .deviceType)
        try container.encode(cameraPermission, forKey: .cameraPermission)
        try container.encode(photoPermission, forKey: .photoPermission)
        try container.encode(mobileOS, forKey: .mobileOS)
    }
}

struct ServerContextResponse: Codable {
    var location: Bool
    var appVersion: Bool
    var deviceTimeZone: Bool
    var deviceType: Bool
    var cameraPermission: Bool
    var photoPermission: Bool
    var mobileOS: Bool
    
    init(location: Bool, appVersion: Bool, deviceTimeZone: Bool, deviceType: Bool, cameraPermission: Bool, photoPermission: Bool, mobileOS: Bool) {
        self.location = location
        self.appVersion = appVersion
        self.deviceTimeZone = deviceTimeZone
        self.deviceType = deviceType
        self.cameraPermission = cameraPermission
        self.photoPermission = photoPermission
        self.mobileOS = mobileOS
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: ContextItemType.self)
        self.location = try container.decode(Bool.self, forKey: .location)
        self.appVersion = try container.decode(Bool.self, forKey: .appVersion)
        self.deviceTimeZone = try container.decode(Bool.self, forKey: .deviceTimeZone)
        self.deviceType = try container.decode(Bool.self, forKey: .deviceType)
        self.cameraPermission = try container.decode(Bool.self, forKey: .cameraPermission)
        self.photoPermission = try container.decode(Bool.self, forKey: .photoPermission)
        self.mobileOS = try container.decode(Bool.self, forKey: .mobileOS)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: ContextItemType.self)
        try container.encode(location, forKey: .location)
        try container.encode(appVersion, forKey: .appVersion)
        try container.encode(deviceTimeZone, forKey: .deviceTimeZone)
        try container.encode(deviceType, forKey: .deviceType)
        try container.encode(cameraPermission, forKey: .cameraPermission)
        try container.encode(photoPermission, forKey: .photoPermission)
        try container.encode(mobileOS, forKey: .mobileOS)
    }
}
