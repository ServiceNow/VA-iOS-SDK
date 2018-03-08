//
//  AppContextManager.swift
//  SnowChat
//
//  Created by Michael Borowiec on 3/2/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import CoreLocation

class AppContextManager {
    private let handlers: [ContextItemType : ContextHandler]
    
    init() {
        self.handlers = [.location : LocationContextHandler(),
                         .cameraPermission : CameraContextHandler(),
                         .photoPermission : PhotoContextHandler(),
                         .appVersion : BaseContextHandler(),
                         .deviceType : BaseContextHandler(),
                         .deviceTimeZone : BaseContextHandler(),
                         .mobileOS : BaseContextHandler()]
    }
    
    func setupHandlers(for request: ServerContextRequest) {
        request.predefinedContextItems.forEach({ contextItem in
            var handler = handlers[contextItem.type]
            handler?.contextItem = contextItem
        })
    }
    
    // Fires authorization action on all predefined context variables
    func authorizeContextItems(for request: ServerContextRequest, completion: @escaping (ServerContextResponse) -> Swift.Void) {
        // use group dispatch to receive authorization from all context items
        var response = ServerContextResponse()
        let dispatchGroup = DispatchGroup()
        handlers.forEach { (itemType, handler) in
            dispatchGroup.enter()
            handler.authorize(completion: { authorized in
                guard let contextItem = handler.contextItem else {
                    Logger.default.logError("Handler is missing ContextItem...something went terribly wrong")
                    dispatchGroup.leave()
                    return
                }
                
                switch contextItem.type {
                case .location:
                    response.location = authorized
                case .cameraPermission:
                    response.cameraPermission = authorized
                case .photoPermission:
                    response.photoPermission = authorized
                case .appVersion:
                    response.appVersion = authorized
                case .deviceTimeZone:
                    response.deviceTimeZone = authorized
                case .deviceType:
                    response.deviceType = authorized
                case .mobileOS:
                    response.mobileOS = authorized
                }
                
                dispatchGroup.leave()
            })
        }
        
        dispatchGroup.notify(queue: .main) {
            completion(response)
        }
    }
    
    func fetchContextData(with userData: Codable? = nil, completion: @escaping (ContextData) -> Swift.Void) {
        var data = ContextData()
        data.userData = userData
        handlers.forEach { (itemType, handler) in
            guard let contextItem = handler.contextItem else {
                Logger.default.logError("Handler is missing ContextItem...something went terribly wrong")
                return
            }
            
            switch contextItem.type {
            case .appVersion:
                if let dictionary = Bundle.main.infoDictionary,
                    let version = dictionary["CFBundleShortVersionString"] as? String,
                    let build = dictionary["CFBundleVersion"] as? String {
                    data.appVersion = "\(version)#\(build)"
                }
            case .deviceTimeZone:
                data.deviceTimeZone = TimeZone.current.identifier
            case .deviceType:
                data.deviceType = UIDevice.current.model
            case .mobileOS:
                data.mobileOS = ProcessInfo.processInfo.operatingSystemVersionString
            case .cameraPermission:
                data.cameraPermission = handler.isAuthorized
            case .photoPermission:
                data.photoPermission = handler.isAuthorized
            case .location:
                // TODO: needs more generic solution
                if let locationHandler = handler as? LocationContextHandler {
                    data.location = locationHandler.locationData
                }
            }
        }
        
        completion(data)
    }
}
