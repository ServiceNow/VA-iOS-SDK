//
//  ChatDataController+ViewDataChangeListener.swift
//  SnowChat
//
//  Created by Marc Attinasi on 1/16/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import Foundation

enum ModelChangeType {
    case insert(index: Int, model: ChatMessageModel)
    case delete(index: Int)
    case update(index: Int, oldModel: ChatMessageModel, model: ChatMessageModel)
}

protocol ViewDataChangeListener: AnyObject {
    func controller(_ dataController: ChatDataController, didChangeModel changes: [ModelChangeType])
    func controller(_ dataController: ChatDataController, didReceiveMultiPartModel multiPartModel: [])
    func controllerDidLoadContent(_ dataController: ChatDataController)
}
