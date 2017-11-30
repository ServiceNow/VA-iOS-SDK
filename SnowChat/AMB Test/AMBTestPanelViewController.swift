//
//  AMBTestPanelViewController.swift
//  SnowChat
//
//  Created by Marc Attinasi on 11/27/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import UIKit

let consumerAccountId = UUID().uuidString
let consumerId = "marc.attinasi"

class AMBTestPanelViewController: UIViewController, AMBListener {

    static private var count: Int = 0
    let user = CBUser(id: "9927", token: "938457hge98", name: "marc", consumerId: consumerId, consumerAccountId: consumerAccountId)
    let vendor = CBVendor(name: "ServiceNow", vendorId: "c2f0b8f187033200246ddd4c97cb0bb9", consumerId: consumerId, consumerAccountId: consumerAccountId)

    @IBOutlet weak var chatId: UITextField!
    @IBOutlet weak var chatContent: UITextView!
    
    @IBAction func onChangeChatId(_ sender: Any) {
        if subscribed {
            unsubscribe()
        }
        subscribe()
    }
    
    @IBAction func onSignInAMB(_ sender: Any) {
        initializeAMBChatClient()
    }
    
    @IBAction func onGetSession(_ sender: Any) {
        initializeSessionAPI()
    }

    @IBAction func onTopicPicker(_ sender: Any) {
        if let sessionId = session?.id {
            let topicPickerMsg = TopicPickerMessage(forSession: sessionId, withValue: "system")
            
            nextHandler = { [weak self] message in
                let event = CBDataFactory.channelEventFromJSON(message)
                if event.eventType == .channelInit {
                    if let initEvent = event as? InitMessage {
                        let loginStage = initEvent.data.actionMessage.loginStage
                        self?.appendContent(message: "Init message received from ChatBot: loginStage = \(loginStage)")
                        if loginStage == "Start" {
                            self?.initUserSession(withInitEvent: initEvent)
                        } else if loginStage == "Finish" {
                            self?.chatContent.textColor = .green
                            self?.appendContent(message: "User Session initiated - handshake complete")
                            
                            // handshake done, setup handler for the topic selection
                            self?.nextHandler = { [weak self] message in
                                let choices: CBControlData = CBDataFactory.controlFromJSON(message)
                                if choices.controlType == .contextualActionMessage {
                                    if let topicChoices = choices as? ContextualActionMessage {
                                        if let options = topicChoices.data.richControl.uiMetadata?.inputControls[0].uiMetadata?.options {
                                            self?.appendContent(message: "What would you like to do?")
                                            for option in options {
                                                self?.appendContent(message: option.label)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            ambClient?.publish(channel: chatChannel(), message: topicPickerMsg)
        }
    }

    func initUserSession(withInitEvent initEvent: InitMessage) {
        var initUserEvent = InitMessage(clone: initEvent)
        
        initUserEvent.data.actionMessage.loginStage = "UserSession"
        initUserEvent.data.direction = "inbound"
        initUserEvent.data.actionMessage.userId = user.id
        initUserEvent.data.actionMessage.contextHandshake.consumerAccountId = user.consumerAccountId
        initUserEvent.data.actionMessage.contextHandshake.deviceId = "1234567890"
        initUserEvent.data.actionMessage.contextHandshake.vendorId = vendor.vendorId
        initUserEvent.data.sendTime = Date()
        
        if let req = initUserEvent.data.actionMessage.contextHandshake.serverContextRequest {
            initUserEvent.data.actionMessage.contextHandshake.serverContextResponse = serverContextResponse(request: req)
        }
        initUserEvent.data.actionMessage.loginStage = "UserSession"
        ambClient?.publish(channel: chatChannel(), message: initUserEvent)
    }
    
    func serverContextResponse(request: [String: ContextItem]) -> [String: Bool] {
        var resp: [String: Bool] = [:]
        for req in request {
            resp[req.key] = true
        }
        return resp
    }
    
    var ambClient: AMBChatClient?
    var sessionAPI: SessionAPI?
    
    var nextHandler: ((_: String) -> Void)?
    
    var id: String = UUID().uuidString
    var subscribed: Bool = false
    var subscribedChannel: String?
   
    var session: CBSession?
    
    let url = CBData.config.url

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

    // MARK: - AMB / Session stuff
    
    private func initializeSessionAPI() {
        sessionAPI = SessionAPI()
        
        let session = CBSession(id: UUID().uuidString, user: user, vendor: vendor)
        
        sessionAPI?.getSession(sessionInfo: session) { [weak self] session in
            if session == nil {
                Logger.default.logError("No session obtained in getSession!")
            } else {
                self?.session = session
                self?.appendContent(message: "Session created: \(session?.welcomeMessage ?? "no message")")
            }
        }
        
        chatId.text = sessionAPI?.chatId
    }
    
    private func initializeAMBChatClient() {
        // swiftlint:disable:next force_unwrapping
        ambClient = AMBChatClient(withEndpoint: URL(string: url)!)
        ambClient?.login(userName: "admin", password: "admin", completionHandler: { [weak self] (success) in
            if success {
                self?.appendContent(message: "Login succeeded")
            } else {
                self?.appendContent(message: "Login failed")
            }
        })
    }
    
    func subscribe() {
        self.ambClient?.subscribe(forChannel: self.chatChannel(), receiver: self)
        self.subscribed = true
        self.subscribedChannel = self.chatChannel()
        self.appendContent(message: "Subscribed to \(self.subscribedChannel.debugDescription)")
    }
    
    func unsubscribe() {
        if subscribed && subscribedChannel != nil {
            // swiftlint:disable:next force_unwrapping
            ambClient?.unsubscribe(fromChannel: subscribedChannel!, receiver: self)
            subscribed = false
            chatContent.text = "Unsubscribed from \(subscribedChannel.debugDescription)"
            subscribedChannel = nil
        }
    }
    
    func onMessage(_ message: String, fromChannel: String) {
        Logger.default.logDebug(message)
        
        appendContent(message: message)
        
        if let h = nextHandler {
            h(message)
        }
    }
    
    private func appendContent(message: String) {
        if let text = chatContent.text {
            chatContent.text = "\(text)\n***** \(AMBTestPanelViewController.count) *****\n\(message)"
        } else {
            chatContent.text = message
        }
        AMBTestPanelViewController.count += 1
        chatContent.scrollRangeToVisible(NSRange(location: chatContent.text.lengthOfBytes(using: .utf8) - 1, length: 1))
    }
}
