//
//  ContextMenuItem.swift
//  SnowChat
//
//  Created by Marc Attinasi on 1/25/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import Foundation

struct ContextMenuItem {
    
    enum Style {
        case `default`
        case cancel
    }
    
    let title: String
    let handler: (UIViewController, UIBarButtonItem) -> Void
    let style: Style

    init(withTitle title: String, style: ContextMenuItem.Style = .default, handler: @escaping(UIViewController, UIBarButtonItem) -> Void) {
        self.title = title
        self.handler = handler
        self.style = style
    }
}

protocol ContextItemProvider {
    func contextMenuItems() -> [ContextMenuItem]
}
