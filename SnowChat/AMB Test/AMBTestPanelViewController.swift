//
//  AMBTestPanelViewController.swift
//  SnowChat
//
//  Created by Marc Attinasi on 11/27/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import UIKit

class AMBTestPanelViewController: UIViewController, AMBListener {

    @IBOutlet weak var chatId: UITextField!
    @IBOutlet weak var chatContent: UITextView!
    @IBAction func onChangeChatId(_ sender: Any) {
        if subscribed {
            unsubscribe()
        }
        subscribe()
    }

    var ambClient: AMBChatClient?
    var sessionAPI: SessionAPI?
    
    var id: String = UUID().uuidString
    var subscribed: Bool = false
    var subscribedChannel: String?
   
    var session: CBSession?
    
    let url = "https://snowchat.service-now.com"

    func chatChannel() -> String {
        if let chid = chatId.text {
            return "/cs/messages/\(chid)"
        } else {
            return "/cs/messages/"
        }
    }
    
    // MARK: LIFECYCLE METHODS
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initializeSessionAPI()
        initializeAMBChatClient()
        
        chatId.text = sessionAPI?.chatId ?? ""
        chatContent.text = "ChatID: \(sessionAPI?.chatId ?? "nil")\nSession: \(session?.id ?? "nil")"
    }

    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        if subscribed == true && subscribedChannel != nil {
            // swiftlint:disable:next force_unwrapping
            ambClient?.unsubscribe(fromChannel: subscribedChannel!, receiver: self)
            subscribed = false
            subscribedChannel = nil
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - AMB stuff
    
    private func initializeSessionAPI() {
        sessionAPI = SessionAPI()
        
        let user = CBUser(id: "9927", token: "938457hge98", name: "marc", consumerId: "marc.attinasi", consumerAccountId: "marc.attinasi@servicenow.com")
        let vendor = CBVendor(name: "ServiceNow", vendorId: "c2f0b8f187033200246ddd4c97cb0bb9", consumerId: "marc.attinasi", consumerAccountId: "marc.attinasi@servicenow.com")
        let session = CBSession(id: UUID().uuidString, user: user, vendor: vendor)
        
        self.session = sessionAPI?.getSession(sessionInfo: session)
    }
    
    private func initializeAMBChatClient() {
        // swiftlint:disable:next force_unwrapping
        ambClient = AMBChatClient(withEndpoint: URL(string: url)!)
        ambClient?.login(userName: "admin", password: "snow2004", completionHandler: { [weak self] (success) in
            if success {
                Logger.default.logDebug("Login succeeded")
            } else {
                Logger.default.logDebug("Login failed")
            }
        })
    }
    
    func subscribe() {
        self.ambClient?.subscribe(forChannel: self.chatChannel(), receiver: self)
        self.subscribed = true
        self.subscribedChannel = self.chatChannel()
    }
    
    func unsubscribe() {
        if subscribed && subscribedChannel != nil {
            // swiftlint:disable:next force_unwrapping
            ambClient?.unsubscribe(fromChannel: subscribedChannel!, receiver: self)
            subscribed = false
            subscribedChannel = nil
            chatContent.text = "Unsubscribed"
        }
    }
    
    func onMessage(_ message: String, fromChannel: String) {
        if let text = chatContent.text {
            chatContent.text = "\(text) \(message)"
        } else {
            chatContent.text = message
        }
        chatContent.scrollRangeToVisible(NSRange(location: chatContent.text.lengthOfBytes(using: .utf8) - 1, length: 1))
    }
}
