//
//  ContextMenuItem.swift
//  SnowChat
//
//  Created by Marc Attinasi on 1/25/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import Foundation

struct ContextMenuItem {
    
    let title: String
    let handler: (UIViewController) -> Void
    
    init(withTitle title: String, handler: @escaping(UIViewController) -> Void) {
        self.title = title
        self.handler = handler
    }
}

protocol ContextItemProvider {
    func contextMenuItems() -> [ContextMenuItem]
}
