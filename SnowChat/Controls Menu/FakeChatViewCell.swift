//
//  FakeChatViewCell.swift
//  SnowChat
//
//  Created by Michael Borowiec on 12/16/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import UIKit

class FakeChatViewCell: UITableViewCell {
    
    var messageView: UIView? {
        willSet {
            messageView?.removeFromSuperview()
        }
        
        didSet {
            guard let messageView = messageView else { return }
            messageView.translatesAutoresizingMaskIntoConstraints = false
            messageView.setContentHuggingPriority(.required, for: .vertical)
            contentView.addSubview(messageView)
            messageView.layer.borderWidth = 1
            messageView.layer.borderColor = UIColor.green.cgColor
            NSLayoutConstraint.activate([messageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                                         messageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                                         messageView.topAnchor.constraint(equalTo: contentView.topAnchor),
                                         messageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)])
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        messageView?.removeFromSuperview()
    }
}
