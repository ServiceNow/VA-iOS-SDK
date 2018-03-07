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
    
    typealias CodingKeys = ContextItemType
    
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
}

struct ServerContextResponse: Codable {
    var location: Bool = false
    var appVersion: Bool = false
    var deviceTimeZone: Bool = false
    var deviceType: Bool = false
    var cameraPermission: Bool = false
    var photoPermission: Bool = false
    var mobileOS: Bool = false
    
    typealias CodingKeys = ContextItemType
}
