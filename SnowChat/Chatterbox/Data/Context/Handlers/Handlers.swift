//
//  Handlers.swift
//  SnowChat
//
//  Created by Michael Borowiec on 3/5/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

// MARK: Location

class LocationContextHandler: ContextHandler, DataFetchable {
    
    func authorize(completion: @escaping (Bool) -> Void) {
        completion(true)
    }
    
    func fetchData(completion: @escaping (AnyObject?) -> Swift.Void) {
        
    }
}

// MARK: Camera

class CameraContextHandler: ContextHandler {
    
    func authorize(completion: @escaping (Bool) -> Void) {
        UserData.authorizeCamera { status in
            completion((status == .authorized))
        }
    }
}

// MARK: Photo

class PhotoContextHandler: ContextHandler {
    
    func authorize(completion: @escaping (Bool) -> Void) {
        UserData.authorizePhoto { status in
            completion((status == .authorized))
        }
    }
}

// MARK: AppVersion

class AppVersionContextHandler: ContextHandler, DataFetchable {
    
    func authorize(completion: @escaping (Bool) -> Void) {
        UserData.authorizePhoto { status in
            completion((status == .authorized))
        }
    }
    
    func fetchData(completion: @escaping (AnyObject?) -> Swift.Void) {
        
    }
}

// MARK: DeviceTimeZone

class DeviceTimeZoneContextHandler: ContextHandler, DataFetchable {
    
    func authorize(completion: @escaping (Bool) -> Void) {
        completion(true)
    }
    
    func fetchData(completion: @escaping (AnyObject?) -> Swift.Void) {
        
    }
}

// MARK: DeviceType

class DeviceTypeContextHandler: ContextHandler, DataFetchable {
    
    func authorize(completion: @escaping (Bool) -> Void) {
        completion(true)
    }
    
    func fetchData(completion: @escaping (AnyObject?) -> Swift.Void) {
        
    }
}

// MARK: MobileOS

class MobileOSContextHandler: ContextHandler, DataFetchable {
    
    func authorize(completion: @escaping (Bool) -> Void) {
        completion(true)
    }
    
    func fetchData(completion: @escaping (AnyObject?) -> Swift.Void) {
        
    }
}
