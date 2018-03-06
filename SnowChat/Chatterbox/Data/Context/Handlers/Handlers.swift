//
//  Handlers.swift
//  SnowChat
//
//  Created by Michael Borowiec on 3/5/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

class BaseContextHandler: ContextHandler {
    
    var contextItem: ContextItem
    
    required init(contextItem: ContextItem) {
        self.contextItem = contextItem
    }
    
    func authorize(completion: @escaping (Bool) -> Void) {
        completion(true)
    }
    
    static func handler(for contextItem: ContextItem) -> ContextHandler {
        switch contextItem.type {
        case .location:
            return LocationContextHandler(contextItem: contextItem)
        case .cameraPermission:
            return CameraContextHandler(contextItem: contextItem)
        case .photoPermission:
            return PhotoContextHandler(contextItem: contextItem)
        case .appVersion:
            return AppVersionContextHandler(contextItem: contextItem)
        case .deviceType:
            return DeviceTypeContextHandler(contextItem: contextItem)
        case .deviceTimeZone:
            return DeviceTimeZoneContextHandler(contextItem: contextItem)
        case .mobileOS:
            return MobileOSContextHandler(contextItem: contextItem)
        }
    }
}

// MARK: Location

class LocationContextHandler: BaseContextHandler, DataFetchable {
    
    override func authorize(completion: @escaping (Bool) -> Void) {
        completion(false)
    }
}

// MARK: Camera

class CameraContextHandler: BaseContextHandler {
    override func authorize(completion: @escaping (Bool) -> Void) {
        UserData.authorizeCamera { status in
            completion((status == .authorized))
        }
    }
}

// MARK: Photo

class PhotoContextHandler: BaseContextHandler {
    override func authorize(completion: @escaping (Bool) -> Void) {
        UserData.authorizePhoto { status in
            completion((status == .authorized))
        }
    }
}

// MARK: AppVersion

class AppVersionContextHandler: BaseContextHandler, DataFetchable {
    override func authorize(completion: @escaping (Bool) -> Void) {
        UserData.authorizePhoto { status in
            completion((status == .authorized))
        }
    }
}

// MARK: DeviceTimeZone

class DeviceTimeZoneContextHandler: BaseContextHandler, DataFetchable {
}

// MARK: DeviceType

class DeviceTypeContextHandler: BaseContextHandler, DataFetchable {
}

// MARK: MobileOS

class MobileOSContextHandler: BaseContextHandler, DataFetchable {
}
