//
//  AppContextManager.swift
//  SnowChat
//
//  Created by Michael Borowiec on 3/2/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

class AppContextManager {
    
    enum ContextItemAuthorizationStatus {
        case authorized
        case denied
    }
    
    // Fires authorization action on all predefined context variables
    func authorizeContextItems(for request: ServerContextRequest, completion: @escaping (ServerContextResponse) -> Swift.Void) {
        // use group dispatch to receive authorization from all context items
//        let dispatchGroup = DispatchGroup()
//        request.predefinedContextItems.forEach({ item in
//
//        })
        
        let response = ServerContextResponse(location: true, appVersion: true, deviceTimeZone: true, deviceType: true, cameraPermission: true, photoPermission: true, mobileOS: true)
        completion(response)
    }
    
    func fetchContextData(completion: @escaping (ContextData) -> Swift.Void) {
        var data = ContextData()
        data.appVersion = "1.1"
        data.deviceTimeZone = "UTC"
        completion(data)
    }
}
