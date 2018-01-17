//
//  PickerHeaderFooterView.swift
//  SnowChat
//
//  Created by Michael Borowiec on 1/17/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import Foundation

// MARK: - Picker header view

class PickerHeaderView: UITableViewHeaderFooterView {
    var titleLabel: UILabel?
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setupTitleLabel()
    }
    
    private func setupTitleLabel() {
        contentView.backgroundColor = UIColor.controlHeaderBackgroundColor
        let titleLabel = UILabel()
        titleLabel.font = .preferredFont(forTextStyle: .title3)
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.numberOfLines = 0
        
        titleLabel.textColor = UIColor.controlHeaderTextColor
        titleLabel.backgroundColor = UIColor.controlHeaderBackgroundColor
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        NSLayoutConstraint.activate([titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
                                     titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
                                     titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
                                     titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10)])
        self.titleLabel = titleLabel
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Picker footer view

class PickerFooterView: UITableViewHeaderFooterView {
    var doneButton: UIButton?
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setupDoneButton()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupDoneButton() {
        contentView.backgroundColor = UIColor.controlHeaderBackgroundColor
        let doneButton = UIButton(type: .custom)
        let localizedTitle = NSLocalizedString("Done", comment: "Button title for mutliselect control done.")
        doneButton.setTitle(localizedTitle, for: .normal)
        doneButton.titleLabel?.font = .preferredFont(forTextStyle: .title3)
        doneButton.setTitleColor(UIColor.controlHeaderTextColor, for: .normal)
        doneButton.titleLabel?.adjustsFontSizeToFitWidth = true
        doneButton.backgroundColor = UIColor.controlHeaderBackgroundColor
        doneButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(doneButton)
        NSLayoutConstraint.activate([doneButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                                     doneButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                                     doneButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
                                     doneButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5)])
        self.doneButton = doneButton
    }
}
