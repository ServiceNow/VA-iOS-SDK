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
    
    var model: ChatMessageModel?
    var lineView: UIView?
    
    func configure(with model: ChatMessageModel) {
        self.model = model
        
        addViews()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.model = nil
    }
    
    // MARK: ControlPresentable
    
    func addViews() {
        
        if lineView == nil {
            lineView = UIView()
        }
        
        guard let lineView = self.lineView else { return }
        
        lineView.translatesAutoresizingMaskIntoConstraints = false
        lineView.backgroundColor = UIColor.controlHeaderBackgroundColor
        
        contentView.addSubview(lineView)
        NSLayoutConstraint.activate([lineView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 5.0),
                                     lineView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -5.0),
                                     lineView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10.0),
                                     lineView.heightAnchor.constraint(equalToConstant: 2.0),
                                     contentView.bottomAnchor.constraint(equalTo: lineView.bottomAnchor, constant: 10.0)])
        layoutIfNeeded()
    }
}
