//
//  SelectableViewCell.swift
//  Controls
//
//  Created by Michael Borowiec on 11/10/17.
//  Copyright © 2017 ServiceNow, Inc. All rights reserved.
//

import UIKit

class SelectableViewCell: UITableViewCell, ConfigurablePickerCell {
    
    let itemTextColor = UIColor(red: 72 / 255, green: 159 / 255, blue: 250 / 255, alpha: 1)

    static let cellIdentifier = "SelectableViewCellIdentifier"
    
    private var selectableView: SelectableView!
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        guard let selectableView = SelectableView.fromNib() as? SelectableView else {
            fatalError("Couldn't load SelectableView from nib")
        }
        
        self.selectableView = selectableView
        setupSelectableView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupSelectableView() {
        selectableView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(selectableView)
        
        NSLayoutConstraint.activate([selectableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                                     selectableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                                     selectableView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
                                     selectableView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5)])
    }
    
    // MARK: - ConfigurablePickerCell Protocol
    
    func configure(withModel model: SelectableItemViewModel) {
        selectableView.titleLabel.text = model.displayValue
        selectableView.titleLabel.textColor = itemTextColor
    }
}
