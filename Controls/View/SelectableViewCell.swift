//
//  SelectableViewCell.swift
//  Controls
//
//  Created by Michael Borowiec on 11/10/17.
//  Copyright © 2017 ServiceNow, Inc. All rights reserved.
//

import UIKit

class SelectableViewCell: UITableViewCell {
    
    static let cellIdentifier = "SelectableViewCellIdentifier"
    
    private var selectableView: SelectableView!
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        if let selectableView = SelectableView.fromNib() as? SelectableView {
            self.selectableView = selectableView
            setupSelectableView()
        } else {
            fatalError("Couldn't load SelectableView from nib")
        }
    }
    
    private func setupSelectableView() {
        selectableView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(selectableView)
    }
    
    override func updateConstraints() {
        selectableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        selectableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        selectableView.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        selectableView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        super.updateConstraints()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configureWithTitle(_ title: String) {
        selectableView.titleLabel.text = title
    }
}
