//
//  ChatDataController+ViewDataChangeListener.swift
//  SnowChat
//
//  Created by Marc Attinasi on 1/16/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import Foundation

struct ModelChangeInfo {
    enum ChangeType {
        case insert
        case delete
        case update
    }
    
    let kind: ChangeType
    let index: Int
    let model: ChatMessageModel?
    
    init(_ kind: ChangeType, atIndex index: Int, withModel model: ChatMessageModel? = nil) {
        self.kind = kind
        self.index = index
        self.model = model
    }
}

protocol ViewDataChangeListener {
    func controller(_ dataController: ChatDataController, didChangeData changes: [ModelChangeInfo])
    func controllerDidLoadContent(_ dataController: ChatDataController)
}
