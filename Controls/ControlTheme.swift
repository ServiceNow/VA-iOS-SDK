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
    
    var dividerColor: UIColor { get }
}

// MARK: - ControlThemable
// discussion: originally it was Themeable but Chatbot application also should have protocol for theming and I thought Themeable would be more appropriate to use there
// If we ever decide to create actual framework out of Controls, we could revert it to Themeable name

protocol ControlThemeable {
    func applyTheme(_ theme: ControlTheme)
}

extension ControlThemeable where Self: ControlProtocol {
    func applyTheme(_ theme: ControlTheme) {
        viewController.view.backgroundColor = theme.backgroundColor
    }
}

extension ControlThemeable where Self: PickerControlProtocol {
    func applyTheme(_ theme: ControlTheme) {
        viewController.view.backgroundColor = theme.backgroundColor
    }
}
