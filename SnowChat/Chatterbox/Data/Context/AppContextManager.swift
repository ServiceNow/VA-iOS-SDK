//
//  AppContextManager.swift
//  SnowChat
//
//  Created by Michael Borowiec on 3/2/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

class AppContextManager {
    
    private var handlers = [ContextHandler]()
    
    func registerHandlers(for request: ServerContextRequest) {
        request.predefinedContextItems.forEach({ contextItem in
            let handler = BaseContextHandler.handler(for: contextItem)
            handlers.append(handler)
        })
        
        // TODO: Add custom handler
    }
    
    // Fires authorization action on all predefined context variables
    func authorizeContextItems(for request: ServerContextRequest, completion: @escaping (ServerContextResponse) -> Swift.Void) {
        
        // use group dispatch to receive authorization from all context items
        var response = ServerContextResponse()
        let dispatchGroup = DispatchGroup()
        handlers.forEach { handler in
            dispatchGroup.enter()
            handler.authorize(completion: { authorized in
                switch handler.contextItem.type {
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
        handlers.forEach { handler in
            switch handler.contextItem.type {
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
            default:
                Logger.default.logDebug("No data to push for item: \(handler.contextItem.type)")
            }
        }
        
        completion(data)
    }
}
