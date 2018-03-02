//
//  Context.swift
//  SnowChat
//
//  Created by Michael Borowiec on 3/1/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

struct ContextHandshake: Codable {
    var serverContextRequest: ServerContextRequest?
    var serverContextResponse: [String: Bool]? = [:]
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
    let type: ContextItemType
    let frequency: ContextItemFrequency
    
    enum ContextItemType: String, Codable, CodingKey {
        case Push = "push"
    }
    
    enum ContextItemFrequency: String, Codable, CodingKey {
        case once = "once"
        case everyMinute = "every minute"
    }
    
    // define the properties that we decode / encode (note JSON name mapping)
    private enum CodingKeys: String, CodingKey {
        case type = "updateType"
        case frequency = "updateFrequency"
    }
}

enum ServerContextRequestKeys: String, CodingKey {
    case location
    case appVersion = "MobileAppVersion"
    case deviceTimeZone
    case deviceType = "DeviceType"
    case cameraPermission = "permissionToUseCamera"
    case photoPermission = "permissionToUsePhoto"
    case mobileOS = "MobileOS"
}

struct ServerContextRequest: Codable {
    var location: ContextItem?
    var appVersion: ContextItem?
    var deviceTimeZone: ContextItem?
    var deviceType: ContextItem?
    var cameraPermission: ContextItem?
    var photoPermission: ContextItem?
    var mobileOS: ContextItem?
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: ServerContextRequestKeys.self)
        
        var contextItem = try container.decode(ContextItem.self, forKey: .location)
        self.location = contextItem
        
        contextItem = try container.decode(ContextItem.self, forKey: .appVersion)
        self.appVersion = contextItem
        
        contextItem = try container.decode(ContextItem.self, forKey: .deviceTimeZone)
        self.deviceTimeZone = contextItem
        
        contextItem = try container.decode(ContextItem.self, forKey: .deviceType)
        self.deviceType = contextItem
        
        contextItem = try container.decode(ContextItem.self, forKey: .cameraPermission)
        self.cameraPermission = contextItem
        
        contextItem = try container.decode(ContextItem.self, forKey: .photoPermission)
        self.photoPermission = contextItem
        
        contextItem = try container.decode(ContextItem.self, forKey: .mobileOS)
        self.mobileOS = contextItem
    }
    
    func encode(to encoder: Encoder) throws {
        
    }
}
