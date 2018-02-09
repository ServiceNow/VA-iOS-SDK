//
//  StartTopicDividerCell.swift
//  SnowChat
//
//  Created by Marc Attinasi on 2/8/18.
//  Copyright © 2018 ServiceNow. All rights reserved.
//

import Foundation

class StartTopicDividerCell: UITableViewCell, ControlPresentable {
    func addUIControl(_ control: ControlProtocol, at location: BubbleLocation) {
        
    }
    
    static let cellIdentifier = "StartTopicDividerCell"
    
    var model: StartTopicViewModel?
    
    func configure(with model: ControlViewModel) {
        self.model = model as? StartTopicViewModel
        
        addLabel()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.model = nil
    }
    
    // MARK: ControlPresentable
    
    func addLabel() {
        
        let labelView = UILabel()
        
        labelView.translatesAutoresizingMaskIntoConstraints = false
        labelView.backgroundColor = UIColor.controlHeaderBackgroundColor
        
        contentView.addSubview(labelView)
        NSLayoutConstraint.activate([labelView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 5.0),
                                     labelView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -5.0),
                                     labelView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10.0),
                                     labelView.heightAnchor.constraint(equalToConstant: 2.0),
                                     contentView.bottomAnchor.constraint(equalTo: labelView.bottomAnchor, constant: 10.0)])
        layoutIfNeeded()
    }
}
