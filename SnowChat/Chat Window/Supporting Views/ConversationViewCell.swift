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
    private let longPressGestureRecognizer = UILongPressGestureRecognizer()
    
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
    
    private func configureGestureRecognizer() {
        longPressGestureRecognizer.addTarget(self, action: #selector(handleLongPress(_:)))
        messageViewController.bubbleView.addGestureRecognizer(longPressGestureRecognizer)
    }
    
    func configure(withChatMessageModel model: ChatMessageModel,
                   controlCache cache: ControlCache,
                   controlDelegate delegate: ControlDelegate,
                   resourceProvider provider: ControlResourceProvider) {
        messageViewController.configure(withChatMessageModel: model, controlCache: cache, controlDelegate: delegate, resourceProvider: provider)
        configureGestureRecognizer()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        messageViewController.prepareForReuse()
        messageViewController.bubbleView.removeGestureRecognizer(longPressGestureRecognizer)
    }
    
    // MARK: - Long Press gesture
    
    @objc private func handleLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        guard gestureRecognizer.state == .recognized else {
            return
        }
        
        if becomeFirstResponder() {
            let menu = UIMenuController.shared
            menu.setTargetRect(messageViewController.bubbleView.frame, in: contentView)
            menu.setMenuVisible(true, animated: true)
        }
    }
    
    // MARK: - Copy action
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        
        // Only allow copy if there is content to copy
        guard messageViewController.uiControl?.copyableContent != nil else {
            return false
        }
        
        return action == #selector(copy(_:))
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    override func copy(_ sender: Any?) {
        let copyableContent = messageViewController.uiControl?.copyableContent
        if let url = copyableContent as? URL {
            UIPasteboard.general.url = url
        } else if let string = copyableContent as? String {
            UIPasteboard.general.string = string
        } else if let image = copyableContent as? UIImage {
            UIPasteboard.general.image = image
        }
    }
}
