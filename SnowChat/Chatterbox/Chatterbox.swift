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
    let id = CBData.uuidString()
    
    var user: CBUser?
    var vendor: CBVendor?
    
    var chatId: String {
        return sessionAPI?.chatId ?? "0"
    }
    
    func initializeSession(forUser: CBUser, ofVendor: CBVendor,
                           whenSuccess: @escaping (ContextualActionMessage) -> Void,
                           whenError: @escaping (Error?) -> Void ) {
        user = forUser
        vendor = ofVendor
        
        initializeAMB { error in
            if error == nil {
                self.createChatSession { error in
                    if error == nil {
                        self.subscribeChatChannel()
                        self.performChatHandshake { actionMessage in
                            whenSuccess(actionMessage)
                            return
                        }
                        // TODO: how do we detect an error here? timeout?
                        // if the ChatServer doesn't send back anything to complete
                        // the handhake we will just sit here waiting...
                        
                    } else {
                        whenError(error)
                    }
                }
            } else {
                whenError(error)
            }
        }
        logger.logDebug("initializeAMB returning")
    }
    
    func startTopic(name: String, completionHandler: @escaping (StartedUserTopicMessage?) -> Void) {
        conversationContext.topicName = name
        
        if let sessionId = session?.id, let convoId = conversationContext.conversationId {
            let startTopic = StartTopicMessage(withSessionId: sessionId, withConversationId: convoId)
            
            startUserTopicCompletionHandler = completionHandler
            messageHandler = startTopicHandler
            ambClient?.publish(channel: chatChannel, message: startTopic)
        }
    }
    
    // MARK: internal properties and methods
    
    private struct ConversationContext {
        var topicName: String?
        var conversationId: String?
        var taskId: String?
    }
    private var conversationContext = ConversationContext()

    private var session: CBSession?
    private var ambClient: AMBChatClient?
    private(set) var sessionAPI: SessionAPI?
    private let chatStore = ChatDataStore(storeId: "ChatterboxDataStore")
    
    private var chatChannel: String {
        return "/cs/messages/\(chatId)"
    }

    private var messageHandler: ((String) -> Void)?
    private var handshakeCompletedHandler: ((ContextualActionMessage) -> Void)?
    private var startUserTopicCompletionHandler: ((StartedUserTopicMessage?) -> Void)?
    
    private let logger = Logger(forCategory: "Chatterbox", atLevel: .Info)
    
    // MARK: Handshake / initialization methods
    
    private func initializeAMB(_ completion: @escaping (Error?) -> Void) {
        guard  let user = user, vendor != nil else {
            let err = ChatterboxError.invalidParameter(details: "User and Vendor must be initialized first")
            logger.logError(err.localizedDescription)
            completion(err)
            return
        }
        
        let url = CBData.config.url
        
        // swiftlint:disable:next force_unwrapping
        ambClient = AMBChatClient(withEndpoint: URL(string: url)!)
        ambClient?.login(userName: user.name, password: user.password ?? "", completionHandler: { (error) in
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
        
        sessionAPI = SessionAPI()

        if let sessionService = sessionAPI {
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
        ambClient?.subscribe(forChannel: chatChannel, receiver: self)
    }
    
    private func performChatHandshake(_ completion: @escaping (ContextualActionMessage) -> Void) {
        handshakeCompletedHandler = completion
        messageHandler = handshakeHandler
        
        if let sessionId = session?.id {
            ambClient?.publish(channel: chatChannel,
                                message: SystemTopicPickerMessage(forSession: sessionId, withValue: "system"))
        }
    }
    
    private func handshakeHandler(_ message: String) {
        let event = CBDataFactory.channelEventFromJSON(message)
        
        if event.eventType == .channelInit, let initEvent = event as? InitMessage {
            let loginStage = initEvent.data.actionMessage.loginStage
            if loginStage == "Start" {
                initUserSession(withInitEvent: initEvent)
            } else if loginStage == "Finish" {
                conversationContext.conversationId = initEvent.data.conversationId
                // handshake done, setup handler for the topic selection
                messageHandler = self.topicSelectionHandler
            }
        }
    }
    
    func topicSelectionHandler(_ message: String) {
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
        
        ambClient?.publish(channel: chatChannel, message: initUserEvent)
    }
    
    // MARK: User Topic Methods
    
    private func startTopicHandler(_ message: String) {
        Logger.default.logDebug("startTopicHandler received: \(message)")
        
        let picker: CBControlData = CBDataFactory.controlFromJSON(message)
        
        if picker.controlType == .topicPicker {
            if let topicPicker = picker as? UserTopicPickerMessage {
                if topicPicker.data.direction == "outbound" {
                    conversationContext.taskId = topicPicker.data.taskId
                    
                    var outgoingMessage = topicPicker
                    outgoingMessage.type = "consumerTextMessage"
                    outgoingMessage.data.direction = "inbound"
                    outgoingMessage.data.richControl?.model = ControlMessage.ModelType(type:"field", name: "Topic")
                    outgoingMessage.data.richControl?.value = conversationContext.topicName
                    
                    messageHandler = startUserTopicHandshake
                    ambClient?.publish(channel: chatChannel, message: outgoingMessage)
                }
            }
        }
    }
    
    private func startUserTopicHandshake(_ message: String) {
        Logger.default.logDebug("startUserTopicHandshake received: \(message)")
        
        let actionMessage = CBDataFactory.channelEventFromJSON(message)
        
        if actionMessage.eventType == .startUserTopic {
            if let startUserTopic = actionMessage as? StartUserTopicMessage {
                
                // client and server messages are the same, so only look at server responses
                if startUserTopic.data.direction == "outbound" {
                    // just turn the 'ready' property to true (and make it incoming) then publish it
                    var response = startUserTopic
                    response.data.messageId = UUID().uuidString
                    response.data.sendTime = Date()
                    response.data.direction = "inbound"
                    response.data.actionMessage.ready = true
                    ambClient?.publish(channel: chatChannel, message: response)
                }
            }
        } else if actionMessage.eventType == .startedUserTopic {
            if let startedUserTopic = actionMessage as? StartedUserTopicMessage {
                let actionMessage = startedUserTopic.data.actionMessage
                logger.logInfo("User Topic Started: \(actionMessage.topicName) - \(actionMessage.topicId) - \(actionMessage.ready ? "Ready" : "Not Ready")")
                
                startUserTopicCompletionHandler?(startedUserTopic)

                installTopicMessageHandler()
            }
        }
    }
    
    private func userTopicMessageHandler(_ message: String) {
        Logger.default.logDebug("startTopicHandler received: \(message)")
        
        let control: CBControlData = CBDataFactory.controlFromJSON(message)
        
        if control.controlType == .boolean {
            if let booleanControl = control as? BooleanControlMessage {
                chatStore.controlEvent(didReceiveBooleanControl: booleanControl)
            }
        }
    }
    
    private func clearMessageHandlers() {
        messageHandler = nil
        handshakeCompletedHandler = nil
        startUserTopicCompletionHandler = nil
    }
    
    private func installTopicMessageHandler() {
        clearMessageHandlers()
        
        messageHandler = userTopicMessageHandler
    }
    
    private func unsubscribe() {
        ambClient?.unsubscribe(fromChannel: self.chatChannel, receiver: self)
    }
    
    func onMessage(_ message: String, fromChannel: String) {
        logger.logDebug(message)

        if let messageHandler = messageHandler {
            messageHandler(message)
        } else {
            logger.logError("No handler set in Chatterbox onMessage!")
        }
    }
}

private func serverContextResponse(request: [String: ContextItem]) -> [String: Bool] {
    var response: [String: Bool] = [:]
    
    request.forEach { item in
        // say YES to all requests (for now)
        response[item.key] = true
    }
    return response
}
