//
//  Chatterbox.swift
//  SnowChat
//
//  Created by Marc Attinasi on 12/1/17.
//  Copyright © 2017 ServiceNow. All rights reserved.
//

import Foundation

enum ChatterboxError: Error {
    case invalidParameter(details: String)
    case invalidCredentials
    case unknown
}

class Chatterbox: AMBListener {
    let id = UUID().uuidString
    
    var user: CBUser?
    var vendor: CBVendor?
    
    var chatId: String {
        return sessionAPI?.chatId ?? "0"
    }
    
    // allow access to the session-manager for now (do we want to reflect relevant API's here?)
    var sessionAPI: SessionAPI? {
        return _sessionAPI
    }
    
    func initializeSession(forUser: CBUser, ofVendor: CBVendor,
                           onSuccess: @escaping (ContextualActionMessage) -> Void,
                           onError: @escaping (Error?) -> Void ) {
        user = forUser
        vendor = ofVendor
        
        initializeAMB { error in
            if error == nil {
                self.createChatSession { error in
                    if error == nil {
                        self.subscribeChatChannel()
                        self.performChatHandshake { actionMessage in
                            onSuccess(actionMessage)
                            return
                        }
                        // TODO: how do we detect an error here? timeout?
                        
                    } else {
                        onError(error)
                    }
                }
            } else {
                onError(error)
            }
        }
        logger.logDebug("initializeAMB returning")
    }
    
    // MARK: internal proerties and methods
    
    private var session: CBSession?
    private var _ambClient: AMBChatClient?
    private var _sessionAPI: SessionAPI?
    
    private var chatChannel: String {
        return "/cs/messages/\(chatId)"
    }

    private var messageHandler: ((String) -> Void)?
    private var handshakeCompletedHandler: ((ContextualActionMessage) -> Void)?

    private let logger = Logger(forCategory: "Chatterbox", atLevel: .Info)
    
    private func initializeAMB(_ completion: @escaping (Error?) -> Void) {
        guard  let user = user, vendor != nil else {
            let err = ChatterboxError.invalidParameter(details: "User and Vendor must be initialized first")
            logger.logError(err.localizedDescription)
            completion(err)
            return
        }
        
        let url = CBData.config.url
        
        // swiftlint:disable:next force_unwrapping
        _ambClient = AMBChatClient(withEndpoint: URL(string: url)!)
        _ambClient?.login(userName: user.name, password: user.password ?? "", completionHandler: { (error) in
            if error == nil {
                self.logger.logInfo("AMB Login succeeded")
            } else {
                self.logger.logInfo("AMB Login failed: \(error.debugDescription)")
            }
            completion(error)
        })
    }
    
    private func createChatSession(_ completion: @escaping (Error?) -> Void) {
        guard let user = user, let vendor = vendor else {
            logger.logError("User and Vendor must be initialized to create a chat session")
            return
        }
        
        _sessionAPI = SessionAPI()

        if let sessionService = _sessionAPI {
            let session = CBSession(id: UUID().uuidString, user: user, vendor: vendor)
            sessionService.getSession(sessionInfo: session) { session in
                if session == nil {
                    self.logger.logError("getSession failed!")
                } else {
                    self.session = session
                }
                completion(sessionService.lastError)
            }
        }
    }
    
    private func subscribeChatChannel() {
        _ambClient?.subscribe(forChannel: chatChannel, receiver: self)
    }
    
    private func performChatHandshake(_ completion: @escaping (ContextualActionMessage) -> Void) {
        handshakeCompletedHandler = completion
        messageHandler = handshakeHandler
        
        if let sessionId = session?.id {
            _ambClient?.publish(channel: chatChannel,
                                message: TopicPickerMessage(forSession: sessionId, withValue: "system"))
        }
    }
    
    private func handshakeHandler(_ message: String) {
        let event = CBDataFactory.channelEventFromJSON(message)
        
        if event.eventType == .channelInit {
            if let initEvent = event as? InitMessage {
                let loginStage = initEvent.data.actionMessage.loginStage
                if loginStage == "Start" {
                    self.initUserSession(withInitEvent: initEvent)
                } else if loginStage == "Finish" {
                    // handshake done, setup handler for the topic selection
                    self.messageHandler = self.userSessionHandler
                }
            }
        }
    }
    
    func userSessionHandler(_ message: String) {
        let choices: CBControlData = CBDataFactory.controlFromJSON(message)
        
        if choices.controlType == .contextualActionMessage {
            if let topicChoices = choices as? ContextualActionMessage, let completion = handshakeCompletedHandler {
                completion(topicChoices)
            } else {
                logger.logFatal("Could not call user session completion handler: invalid message or not handler provided")
            }
        }
    }
    
    private func initUserSession(withInitEvent initEvent: InitMessage) {
        var initUserEvent = initEvent
        
        initUserEvent.data.actionMessage.loginStage = "UserSession"
        initUserEvent.data.direction = "inbound"
        initUserEvent.data.actionMessage.userId = user?.id
        initUserEvent.data.actionMessage.contextHandshake.consumerAccountId = user?.consumerAccountId
        initUserEvent.data.actionMessage.contextHandshake.vendorId = vendor?.vendorId
        initUserEvent.data.actionMessage.contextHandshake.deviceId = getDeviceId()
        initUserEvent.data.sendTime = Date()
        
        if let req = initUserEvent.data.actionMessage.contextHandshake.serverContextRequest {
            initUserEvent.data.actionMessage.contextHandshake.serverContextResponse = serverContextResponse(request: req)
        }
        initUserEvent.data.actionMessage.loginStage = "UserSession"
        
        _ambClient?.publish(channel: chatChannel, message: initUserEvent)
    }
    
    private func unsubscribe() {
        _ambClient?.unsubscribe(fromChannel: self.chatChannel, receiver: self)
    }
    
    func onMessage(_ message: String, fromChannel: String) {
        logger.logDebug(message)

        if let h = messageHandler {
            h(message)
        } else {
            logger.logError("No handler set in Chatterbox onMessage!")
        }
    }
}

private func serverContextResponse(request: [String: ContextItem]) -> [String: Bool] {
    var response: [String: Bool] = [:]
    for req in request {
        response[req.key] = true
        // TODO: discriminate which requests we honor? What are these even used for?
    }
    return response
}
