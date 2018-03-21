//
//  Handlers.swift
//  SnowChat
//
//  Created by Michael Borowiec on 3/5/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

class BaseContextHandler: NSObject, ContextHandler {
    
    var isAuthorized: Bool = false
    
    var contextItem: ContextItem?

    func authorize(completion: @escaping (Bool) -> Void) {
        isAuthorized = true
        completion(true)
    }
}

// MARK: Camera

class CameraContextHandler: BaseContextHandler {
    override func authorize(completion: @escaping (Bool) -> Void) {
        UserDataManager.authorizeCamera { [weak self] status in
            guard let strongSelf = self else { return }
            strongSelf.isAuthorized = (status == .authorized)
            completion(strongSelf.isAuthorized)
        }
    }
}

// MARK: Photo

class PhotoContextHandler: BaseContextHandler {
    override func authorize(completion: @escaping (Bool) -> Void) {
        UserDataManager.authorizePhoto { [weak self] status in
            guard let strongSelf = self else { return }
            strongSelf.isAuthorized = (status == .authorized)
            completion(strongSelf.isAuthorized)
        }
    }
}
