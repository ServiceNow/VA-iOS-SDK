//
//  ConversationViewCell.swift
//  SnowChat
//
//  Created by Michael Borowiec on 12/20/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

class ConversationViewCell: UITableViewCell {
    private(set) var messageViewController: ChatMessageViewController
    static let cellIdentifier = "ConversationViewCell"
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        messageViewController = ChatMessageViewController(nibName: "ChatMessageViewController", bundle: Bundle(for: type(of: self)))
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupMessageView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupMessageView() {
        let messageView: UIView = messageViewController.view
        messageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(messageView)
        NSLayoutConstraint.activate([messageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                                     messageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                                     messageView.topAnchor.constraint(equalTo: contentView.topAnchor),
                                     messageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)])
    }
    
    func configure(withChatMessageModel model: ChatMessageModel,
                   controlCache cache: ControlCache,
                   controlDelegate delegate: ControlDelegate,
                   resourceProvider provider: ControlResourceProvider) {
        messageViewController.configure(withChatMessageModel: model, controlCache: cache, controlDelegate: delegate, resourceProvider: provider)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        messageViewController.prepareForReuse()
    }
}
