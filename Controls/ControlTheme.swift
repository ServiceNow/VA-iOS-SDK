//
//  ControlTheme.swift
//  SnowChat
//
//  Created by Michael Borowiec on 3/19/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import UIKit

// Control should be feed in with object that conforms to this protocol

protocol ControlTheme {
    var backgroundColor: UIColor { get }
    var borderColor: UIColor { get }
    var fontColor: UIColor { get }
    
    var headerBackgroundColor: UIColor { get }
    var headerFontColor: UIColor { get }
}

// MARK: - Themable

protocol Themeable {
    func applyTheme(_ theme: ControlTheme)
}

extension Themeable where Self: ControlProtocol {
    func applyTheme(_ theme: ControlTheme) {
        viewController.view.backgroundColor = theme.backgroundColor
    }
}

extension Themeable where Self: PickerControlProtocol {
    func applyTheme(_ theme: ControlTheme) {
        viewController.view.backgroundColor = theme.backgroundColor
    }
}
