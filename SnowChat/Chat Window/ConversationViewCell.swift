//
//  ConversationViewCell.swift
//  SnowChat
//
//  Created by Michael Borowiec on 12/20/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

class ConversationViewCell: UITableViewCell {
    
    static let cellIdentifier = "ConversationViewCell"
    
    var messageViewController: ChatMessageViewController? {
        didSet {
//            contentView.layer.borderWidth = 1
//            contentView.layer.borderColor = UIColor.green.cgColor
            messageView = messageViewController?.view
        }
    }
    
    var messageView: UIView? {
        didSet {
            // MessageView might have been reused in other cell, so if it was moved to a different parent, we shouldn't remove it
            if oldValue?.superview == contentView, oldValue != messageView {
                oldValue?.removeFromSuperview()
            }
            
            guard let messageView = messageView else {
                return
            }

            messageView.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(messageView)
            NSLayoutConstraint.activate([messageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                                         messageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                                         messageView.topAnchor.constraint(equalTo: contentView.topAnchor),
                                         messageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)])
            layoutIfNeeded()
        }
    }
}
