//
//  PickerTableViewCell.swift
//  SnowChat
//
//  Created by Michael Borowiec on 11/29/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import UIKit

protocol ConfigurablePickerCell: class {
    
    func configure(withModel model: SelectableItemViewModel)
}

class PickerTableViewCell: UITableViewCell, ConfigurablePickerCell {
    
    static let cellIdentifier = "PickerTableViewCellIdentifier"
    
    @IBOutlet weak var titleLabel: UILabel!
    
    // MARK: - ConfigurablePickerCell Protocol
    
    func configure(withModel model: SelectableItemViewModel) {
        titleLabel.text = model.displayValue
        titleLabel.textColor = UIColor.controlTextColor
    }
}
