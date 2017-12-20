//
//  ConversationViewCell.swift
//  SnowChat
//
//  Created by Michael Borowiec on 12/20/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

class ConversationViewCell: UITableViewCell {
    
    static let cellIdentifier = "ConversationViewCell"
    
    var messageView: UIView? {
        willSet {
            messageView?.removeFromSuperview()
        }
        
        didSet {
            guard let messageView = messageView else { return }
            messageView.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(messageView)
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
