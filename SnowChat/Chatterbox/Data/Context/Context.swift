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
        contextItem.type = .appVersion
        self.appVersion = contextItem
        predefinedContextItems.append(contextItem)
        
        contextItem = try container.decode(ContextItem.self, forKey: .deviceTimeZone)
        contextItem.type = .deviceTimeZone
        self.deviceTimeZone = contextItem
        predefinedContextItems.append(contextItem)
        
        contextItem = try container.decode(ContextItem.self, forKey: .deviceType)
        contextItem.type = .deviceType
        self.deviceType = contextItem
        predefinedContextItems.append(contextItem)
        
        contextItem = try container.decode(ContextItem.self, forKey: .cameraPermission)
        contextItem.type = .cameraPermission
        self.cameraPermission = contextItem
        predefinedContextItems.append(contextItem)
        
        contextItem = try container.decode(ContextItem.self, forKey: .photoPermission)
        contextItem.type = .photoPermission
        self.photoPermission = contextItem
        predefinedContextItems.append(contextItem)
        
        contextItem = try container.decode(ContextItem.self, forKey: .mobileOS)
        contextItem.type = .mobileOS
        self.mobileOS = contextItem
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
    var location: Bool = false
    var appVersion: Bool = false
    var deviceTimeZone: Bool = false
    var deviceType: Bool = false
    var cameraPermission: Bool = false
    var photoPermission: Bool = false
    var mobileOS: Bool = false
    
    init() {}
    
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
