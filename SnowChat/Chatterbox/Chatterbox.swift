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

    var chatId: String {
        return sessionAPI?.chatId ?? "0"
    }
    
    var user: CBUser?
    var vendor: CBVendor?
    
    func initializeSession(forUser: CBUser, vendor: CBVendor,
                           success: @escaping (ContextualActionMessage) -> Void,
                           failure: @escaping (Error?) -> Void ) {
        self.user = forUser
        self.vendor = vendor
        
        initializeAMB { errorIn in
            if errorIn == nil {
                self.createChatSession { errorIn in
                    if errorIn == nil {
                        self.performChatHandshake { actionMessage in
                            success(actionMessage)
                            return
                        }
                        // TODO: how do we detect an error here? timeout?
                        // if the ChatServer doesn't send back anything to complete
                        // the handhake we will just sit here waiting...
                        
                    } else {
                        failure(errorIn)
                    }
                }
            } else {
                failure(errorIn)
            }
        }
        logger.logDebug("initializeAMB returning")
    }
    
    func startTopic(withName: String, completion: @escaping (StartedUserTopicMessage?) -> Void) throws {
        conversationContext.topicName = withName
        
        if let sessionId = session?.id, let conversationId = conversationContext.conversationId, let amb = ambClient {
            startUserTopicCompletionHandler = completion
            messageHandler = startTopicHandler
            
            let startTopic = StartTopicMessage(withSessionId: sessionId, withConversationId: conversationId)
            amb.publish(message: startTopic, toChannel: chatChannel)
        } else {
            throw ChatterboxError.invalidParameter(details: "Session must be initialized before startTopic is called")
        }
    }
    
    // MARK: internal properties and methods
    
    private struct ConversationContext {
        var topicName: String?
        var conversationId: String?
        var taskId: String?
    }
    private var conversationContext = ConversationContext()

    private let chatStore = ChatDataStore(storeId: "ChatterboxDataStore")
    private var session: CBSession?
    private var ambClient: AMBChatClient?
    private (set) var sessionAPI: SessionAPI?
    
    private var chatChannel: String {
        return "/cs/messages/\(chatId)"
    }

    private var messageHandler: ((String) -> Void)?
    private var handshakeCompletedHandler: ((ContextualActionMessage) -> Void)?
    private var startUserTopicCompletionHandler: ((StartedUserTopicMessage?) -> Void)?
    
    private let logger = Logger(forCategory: "Chatterbox", level: .Info)
    
    // MARK: Handshake / initialization methods
    
    private func initializeAMB(_ completion: @escaping (Error?) -> Void) {
        guard  let user = user, vendor != nil else {
            let error = ChatterboxError.invalidParameter(details: "User and Vendor must be initialized first")
            logger.logError(error.localizedDescription)
            completion(error)
            return
        }
        
        let url = CBData.config.url
        
        // swiftlint:disable:next force_unwrapping
        ambClient = AMBChatClient(withEndpoint: URL(string: url)!)
        ambClient?.login(userName: user.name, password: user.password ?? "", completion: { (error) in
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
            sessionService.chatSession(forSessionInfo: session) { session in
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
        ambClient?.subscribe(self, toChannel: chatChannel)
    }
    
    private func performChatHandshake(_ completion: @escaping (ContextualActionMessage) -> Void) {
        handshakeCompletedHandler = completion
        messageHandler = handshakeHandler
        
        subscribeChatChannel()

        if let sessionId = session?.id {
            ambClient?.publish(message: SystemTopicPickerMessage(forSession: sessionId),
                               toChannel: chatChannel)
        }
    }
    
    private func handshakeHandler(_ message: String) {
        let event = CBDataFactory.channelEventFromJSON(message)
        
        if event.eventType == .channelInit, let initEvent = event as? InitMessage {
            if initEvent.data.actionMessage.loginStage == MessageConstants.loginStart.rawValue {
                logger.logInfo("Handshake START message received")
                startUserSession(withInitEvent: initEvent)
            } else if initEvent.data.actionMessage.loginStage == MessageConstants.loginFinish.rawValue {
                logger.logInfo("Handshake FINISH message received: conversationID=\(conversationContext.conversationId ?? "nil")")
                
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
                logger.logFatal("Could not call user session completion handler: invalid message or no handler provided")
            }
        }
    }
    
    private func startUserSession(withInitEvent initEvent: InitMessage) {
        let initUserEvent = createUserSessionInitMessage(fromInitEvent: initEvent)
        ambClient?.publish(message: initUserEvent, toChannel: chatChannel)
    }
    
    private func createUserSessionInitMessage(fromInitEvent initEvent: InitMessage) -> InitMessage {
        var initUserEvent = initEvent
        
        initUserEvent.data.direction = MessageConstants.directionFromClient.rawValue
        initUserEvent.data.sendTime = Date()
        initUserEvent.data.actionMessage.loginStage = MessageConstants.loginUserSession.rawValue
        initUserEvent.data.actionMessage.userId = user?.id
        initUserEvent.data.actionMessage.contextHandshake.consumerAccountId = user?.consumerAccountId
        initUserEvent.data.actionMessage.contextHandshake.vendorId = vendor?.vendorId
        initUserEvent.data.actionMessage.contextHandshake.deviceId = deviceIdentifier()
        
        if let request = initUserEvent.data.actionMessage.contextHandshake.serverContextRequest {
            initUserEvent.data.actionMessage.contextHandshake.serverContextResponse = serverContextResponse(fromRequest: request)
        }
        return initUserEvent
    }
    
    // MARK: User Topic Methods
    
    private func startTopicHandler(_ message: String) {
        Logger.default.logDebug("startTopicHandler received: \(message)")
        
        let picker: CBControlData = CBDataFactory.controlFromJSON(message)
        
        if picker.controlType == .topicPicker {
            if let topicPicker = picker as? UserTopicPickerMessage {
                if topicPicker.data.direction == MessageConstants.directionFromServer.rawValue {
                    conversationContext.taskId = topicPicker.data.taskId
                    
                    var outgoingMessage = topicPicker
                    outgoingMessage.type = "consumerTextMessage"
                    outgoingMessage.data.direction = MessageConstants.directionFromClient.rawValue
                    outgoingMessage.data.richControl?.model = ControlMessage.ModelType(type:"field", name: "Topic")
                    outgoingMessage.data.richControl?.value = conversationContext.topicName
                    
                    messageHandler = startUserTopicHandshakeHandler
                    ambClient?.publish(message: outgoingMessage, toChannel: chatChannel)
                }
            }
        }
    }
    
    private func startUserTopicHandshakeHandler(_ message: String) {
        Logger.default.logDebug("startUserTopicHandshake received: \(message)")
        
        let actionMessage = CBDataFactory.channelEventFromJSON(message)
        
        if actionMessage.eventType == .startUserTopic {
            if let startUserTopic = actionMessage as? StartUserTopicMessage {
                
                // client and server messages are the same, so only look at server responses!
                if startUserTopic.data.direction == MessageConstants.directionFromServer.rawValue {
                    let startUserTopicReadyMessage = createStartTopicReadyMessage(startUserTopic: startUserTopic)
                    ambClient?.publish(message: startUserTopicReadyMessage, toChannel: chatChannel)
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
    
    private func createStartTopicReadyMessage(startUserTopic: StartUserTopicMessage) -> StartUserTopicMessage {
        var startUserTopicReady = startUserTopic
        startUserTopicReady.data.messageId = CBData.uuidString()
        startUserTopicReady.data.sendTime = Date()
        startUserTopicReady.data.direction = MessageConstants.directionFromClient.rawValue
        startUserTopicReady.data.actionMessage.ready = true
        return startUserTopicReady
    }
    
    private func userTopicMessageHandler(_ message: String) {
        Logger.default.logDebug("userTopicMessage received: \(message)")
        
        let control = CBDataFactory.controlFromJSON(message)
        
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
        ambClient?.unsubscribe(self, fromChannel: self.chatChannel)
    }
    
    // MARK: AMBListener protocol methods
    
    func client(_ client: AMBChatClient, didReceiveMessage message: String, fromChannel channel: String) {
        logger.logDebug(message)

        if let messageHandler = messageHandler {
            messageHandler(message)
        } else {
            logger.logError("No handler set in Chatterbox onMessage!")
        }
    }
}

private func serverContextResponse(fromRequest request: [String: ContextItem]) -> [String: Bool] {
    var response: [String: Bool] = [:]
    
    request.forEach { item in
        // say YES to all requests (for now)
        response[item.key] = true
    }
    return response
}
