//
//  PickerTableViewCell.swift
//  SnowChat
//
//  Created by Michael Borowiec on 11/29/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import UIKit

protocol ConfigurablePickerCell: AnyObject, ThemeableControl {
    
    func configure(withModel model: PickerItem)
}

class PickerTableViewCell: UITableViewCell, ConfigurablePickerCell {
    
    static let cellIdentifier = "PickerTableViewCellIdentifier"
    
    @IBOutlet weak var titleLabel: UILabel!
    
    // MARK: - ConfigurablePickerCell Protocol
    
    func configure(withModel model: PickerItem) {
        titleLabel.text = model.label
    }
    
    // MARK: - ThemeableControl
    
    func applyTheme(_ theme: ControlTheme?) {
        titleLabel.textColor = theme?.linkColor
        contentView.backgroundColor = theme?.buttonBackgroundColor
        
        let cellBackgroundView = UIView()
        selectedBackgroundView = cellBackgroundView
        cellBackgroundView.backgroundColor = theme?.selectedBackgroundColor
    }
}
