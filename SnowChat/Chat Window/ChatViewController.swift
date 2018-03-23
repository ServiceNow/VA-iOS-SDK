//
//  ChatViewController.swift
//  SnowChat
//
//  Created by Will Lisac on 12/11/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import UIKit

public class ChatViewController: UIViewController {
    
    private let chatterbox: Chatterbox
    private var conversationViewController: ConversationViewController?
    private var banner: NotificationBanner?
    private var bannerConstraints = [NSLayoutConstraint]()
    
    // MARK: - Initialization
    
    internal init(chatterbox: Chatterbox) {
        self.chatterbox = chatterbox
        
        super.init(nibName: nil, bundle: nil)
        
        self.chatterbox.chatEventListeners.addListener(self)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - View Life Cycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        setupConversationViewController()
        setupContextMenu()
        setupNotificationBanner()
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        removeConversationViewController()
    }
    
    // MARK: - Setup
    
    private func setupConversationViewController() {
        let controller = ConversationViewController(chatterbox: chatterbox)
        
        controller.willMove(toParentViewController: self)
        addChildViewController(controller)
        controller.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        controller.view.frame = view.bounds
        view.addSubview(controller.view)
        controller.didMove(toParentViewController: self)
        
        conversationViewController = controller
    }
    
    private func removeConversationViewController() {
        guard let childViewController = conversationViewController else { return }
        
        childViewController.willMove(toParentViewController: nil)
        childViewController.view.removeFromSuperview()
        childViewController.removeFromParentViewController()
        conversationViewController = nil
    }
    
    private func setupContextMenu() {
        let image = UIImage(named: "menu", in: Bundle(for: type(of: self)), compatibleWith: nil)
        let contextMenu = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(contextMenuTapped(_:)))
        navigationItem.rightBarButtonItem = contextMenu
    }
    
    @objc func contextMenuTapped(_ sender:UIBarButtonItem!) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let contextItems = conversationViewController?.contextMenuItems()
        contextItems?.forEach({ item in
            let isCancel = item.style == .cancel
            let style: UIAlertActionStyle = isCancel ? .cancel : .default
            alertController.addAction(UIAlertAction(title: item.title, style: style) { action in
                item.handler(self, sender)
            })
        })
        
        alertController.popoverPresentationController?.barButtonItem = sender
        self.navigationController?.present(alertController, animated: true, completion: nil)
    }
    
    func setupNotificationBanner() {
        let banner = NotificationBanner()
        banner.translatesAutoresizingMaskIntoConstraints = false

        var offset: CGFloat = 0.0
        if let navigationController = navigationController {
            offset = navigationController.navigationBar.frame.size.height
            offset += navigationController.navigationBar.frame.origin.y
        }
        
        if #available(iOS 11, *) {
            let guide = view.safeAreaLayoutGuide
            bannerConstraints = [
                banner.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
                banner.topAnchor.constraint(equalTo: guide.topAnchor),
                banner.widthAnchor.constraint(equalTo: guide.widthAnchor),
                banner.heightAnchor.constraint(equalToConstant: 30)
            ]
        } else {
            bannerConstraints = [
                banner.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                banner.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor),
                banner.widthAnchor.constraint(equalTo: view.widthAnchor),
                banner.heightAnchor.constraint(equalToConstant: 30)
            ]
        }
        self.banner = banner
    }
}

extension ChatViewController: ChatEventListener {
    
    func chatterbox(_ chatterbox: Chatterbox, didStartTopic topicInfo: TopicInfo, forChat chatId: String) {
        Logger.default.logInfo("ChatEventListener.didStartTopic: \(topicInfo)")
    }
    
    func chatterbox(_ chatterbox: Chatterbox, didResumeTopic topicInfo: TopicInfo, forChat chatId: String) {
        Logger.default.logInfo("ChatEventListener.didResumeTopic: \(topicInfo)")
    }
    
    func chatterbox(_ chatterbox: Chatterbox, didFinishTopic topicInfo: TopicInfo, forChat chatId: String) {
        Logger.default.logInfo("ChatEventListener.didFinishTopic: \(topicInfo)")
    }

    func chatterbox(_ chatterbox: Chatterbox, willStartAgentChat agentInfo: AgentInfo, forChat chatId: String) {
        Logger.default.logInfo("ChatEventListener.willStartAgentChat: \(agentInfo)")
    }
    
    func chatterbox(_ chatterbox: Chatterbox, didStartAgentChat agentInfo: AgentInfo, forChat chatId: String) {
        Logger.default.logInfo("ChatEventListener.didStartAgentChat: \(agentInfo)")
    }

    func chatterbox(_ chatterbox: Chatterbox, didResumeAgentChat agentInfo: AgentInfo, forChat chatId: String) {
        Logger.default.logInfo("ChatEventListener.didResumeAgentChat: \(agentInfo)")
    }
    
    func chatterbox(_ chatterbox: Chatterbox, didFinishAgentChat agentInfo: AgentInfo, forChat chatId: String) {
        Logger.default.logInfo("ChatEventListener.didFinishAgentChat: \(agentInfo)")
    }
    
    func chatterbox(_ chatterbox: Chatterbox, didEstablishUserSession sessionId: String, forChat chatId: String ) {
        Logger.default.logInfo("ChatEventListener.didEstablishUserSession: \(sessionId)")
    }
    
    func chatterbox(_ chatterbox: Chatterbox, didReceiveTransportStatus transportStatus: TransportStatus, forChat chatId: String) {
        switch transportStatus {
        case .unreachable:
            showDisconnectedBanner()
        case .reachable:
            hideDisconnectedBanner()
        }
    }
    
    private func showDisconnectedBanner() {
        guard let banner = banner else { return }
        banner.text = NSLocalizedString("Disconnected...", comment: "Message in alert banner when network is disconnected")
        view.addSubview(banner)
        NSLayoutConstraint.activate(bannerConstraints)
    }
    
    private func hideDisconnectedBanner() {
        guard let banner = banner else { return }

        banner.text = NSLocalizedString("Reconnected", comment: "Message in alert banner when network is connected after being disconnected (briefly displayed)")
        banner.removeFromSuperview()
        NSLayoutConstraint.deactivate(bannerConstraints)
    }
}
