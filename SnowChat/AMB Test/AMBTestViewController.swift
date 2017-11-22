//
//  AMBTestViewController.swift
//  SnowChat
//
//  Created by Will Lisac on 11/17/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import UIKit
import AMBClient

public class AMBTestViewController: UIViewController, AMBListener {
    var id: String = UUID().uuidString
    var subscription: NOWAMBSubscription?
    var ambClient: AMBChatClient?
    var chatChannel: String = { return "/cs/messages/\(AMBTestViewController.chatId)" }()
    
    static var chatId: String = "e804260e8073e0e80ce70e80b700e808" // ENTER VALID CHAT-ID HERE!!!
    
    // MARK: AMBListener protocol
    
    func onMessage(_ message: String, fromChannel: String) {
        Logger.default.logInfo("AMB Test-> \(message)")
    }
    
    // MARK: - View Life Cycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        initializeAMBChatClient()
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if subscription != nil {
            ambClient?.unsubscribe(fromChannel: chatChannel, receiver: self)
        }
    }
    
    private func initializeAMBChatClient() {
        // swiftlint:disable:next force_unwrapping
        ambClient = AMBChatClient(withEndpoint: URL(string: "https://snowchat.service-now.com")!)
        ambClient?.login(userName: "admin", password: "snow2004", completionHandler: { [weak self] (success) in
            if success {
                if let me = self {
                    me.ambClient?.subscribe(forChannel: me.chatChannel, receiver: me)
                } else {
                    Logger.default.logDebug("AMBTestViewController went away...")
                }
            } else {
                Logger.default.logDebug("Login failed")
            }
        })
    }
}
